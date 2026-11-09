CREATE TABLE IF NOT EXISTS community_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_customer_id uuid NOT NULL UNIQUE REFERENCES customers(id),
  designer_id uuid NOT NULL REFERENCES designers(id),
  is_open boolean NOT NULL DEFAULT true,
  max_participants integer NOT NULL DEFAULT 5 CHECK (max_participants BETWEEN 1 AND 5),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS community_join_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_project_id uuid NOT NULL REFERENCES community_projects(id),
  requester_user_id uuid NOT NULL,
  requester_customer_id uuid NOT NULL REFERENCES customers(id),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','accepted')),
  new_customer_id uuid REFERENCES customers(id),
  cloned_quote_id uuid REFERENCES designer_quotes(id),
  rejection_reason text,
  requested_at timestamptz NOT NULL DEFAULT now(),
  decided_at timestamptz,
  accepted_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS community_join_requests_one_active
  ON community_join_requests (community_project_id, requester_user_id)
  WHERE status IN ('pending','approved','accepted');

CREATE INDEX IF NOT EXISTS community_join_requests_cloned_quote_idx ON community_join_requests (cloned_quote_id);

CREATE TABLE IF NOT EXISTS community_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_project_id uuid NOT NULL REFERENCES community_projects(id),
  customer_id uuid NOT NULL UNIQUE REFERENCES customers(id),
  homeowner_user_id uuid NOT NULL,
  role text NOT NULL CHECK (role IN ('original','joined')),
  status text NOT NULL CHECK (status IN ('reserved','confirmed')),
  join_request_id uuid REFERENCES community_join_requests(id),
  joined_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS community_participants_project_idx ON community_participants (community_project_id, joined_at);

CREATE TABLE IF NOT EXISTS community_referral_rewards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  join_request_id uuid NOT NULL REFERENCES community_join_requests(id),
  beneficiary_customer_id uuid NOT NULL REFERENCES customers(id),
  beneficiary_user_id uuid NOT NULL,
  reward_percent numeric(5,2) NOT NULL DEFAULT 3,
  base_amount numeric(12,2) NOT NULL,
  reward_amount numeric(12,2) NOT NULL,
  status text NOT NULL DEFAULT 'earned' CHECK (status IN ('earned','applied','reversed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (join_request_id, beneficiary_customer_id)
);

CREATE INDEX IF NOT EXISTS community_referral_rewards_beneficiary_idx ON community_referral_rewards (beneficiary_user_id);

ALTER TABLE community_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_referral_rewards ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON community_projects, community_join_requests, community_participants, community_referral_rewards FROM PUBLIC, anon;
GRANT SELECT ON community_projects, community_join_requests, community_participants, community_referral_rewards TO authenticated;
GRANT ALL ON community_projects, community_join_requests, community_participants, community_referral_rewards TO service_role;

DROP POLICY IF EXISTS "designer_select_own_community_projects" ON community_projects;
CREATE POLICY "designer_select_own_community_projects" ON community_projects FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM designers d WHERE d.id = community_projects.designer_id AND d.user_id = auth.uid()));

DROP POLICY IF EXISTS "participant_select_community_projects" ON community_projects;
CREATE POLICY "participant_select_community_projects" ON community_projects FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM community_participants p WHERE p.community_project_id = community_projects.id AND p.homeowner_user_id = auth.uid()));

DROP POLICY IF EXISTS "requester_select_own_join_requests" ON community_join_requests;
CREATE POLICY "requester_select_own_join_requests" ON community_join_requests FOR SELECT TO authenticated
  USING (requester_user_id = auth.uid());

DROP POLICY IF EXISTS "designer_select_join_requests" ON community_join_requests;
CREATE POLICY "designer_select_join_requests" ON community_join_requests FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM community_projects cp JOIN designers d ON d.id = cp.designer_id WHERE cp.id = community_join_requests.community_project_id AND d.user_id = auth.uid()));

DROP POLICY IF EXISTS "select_own_participation" ON community_participants;
CREATE POLICY "select_own_participation" ON community_participants FOR SELECT TO authenticated
  USING (homeowner_user_id = auth.uid());

DROP POLICY IF EXISTS "designer_select_participants" ON community_participants;
CREATE POLICY "designer_select_participants" ON community_participants FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM community_projects cp JOIN designers d ON d.id = cp.designer_id WHERE cp.id = community_participants.community_project_id AND d.user_id = auth.uid()));

DROP POLICY IF EXISTS "beneficiary_select_own_rewards" ON community_referral_rewards;
CREATE POLICY "beneficiary_select_own_rewards" ON community_referral_rewards FOR SELECT TO authenticated
  USING (beneficiary_user_id = auth.uid());

CREATE OR REPLACE FUNCTION community_on_quote_accepted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_req public.community_join_requests%ROWTYPE;
  v_joiner_joined_at timestamptz;
  v_designer_user_id uuid;
  v_reward public.community_referral_rewards%ROWTYPE;
  v_email text;
  v_name text;
  v_project_name text;
BEGIN
  SELECT r.* INTO v_req
  FROM public.community_join_requests r
  WHERE r.cloned_quote_id = NEW.id AND r.status = 'approved'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  UPDATE public.community_join_requests
  SET status = 'accepted', accepted_at = now(), updated_at = now()
  WHERE id = v_req.id;

  UPDATE public.community_participants
  SET status = 'confirmed'
  WHERE join_request_id = v_req.id
  RETURNING joined_at INTO v_joiner_joined_at;

  FOR v_reward IN
    WITH inserted AS (
      INSERT INTO public.community_referral_rewards
        (join_request_id, beneficiary_customer_id, beneficiary_user_id, base_amount, reward_amount)
      SELECT v_req.id, p.customer_id, p.homeowner_user_id, q.total_amount, ROUND(q.total_amount * 3 / 100.0, 2)
      FROM public.community_participants p
      JOIN public.customers c ON c.id = p.customer_id
      JOIN public.designer_quotes q ON q.id = c.accepted_quote_id
      WHERE p.community_project_id = v_req.community_project_id
        AND p.status = 'confirmed'
        AND p.join_request_id IS DISTINCT FROM v_req.id
        AND p.joined_at < v_joiner_joined_at
      ON CONFLICT (join_request_id, beneficiary_customer_id) DO NOTHING
      RETURNING *
    )
    SELECT * FROM inserted
  LOOP
    PERFORM public.create_notification(
      v_reward.beneficiary_user_id,
      'customer',
      'Community referral reward earned',
      'A new homeowner has joined and accepted their quotation. Your 3% referral reward of ' || v_reward.reward_amount::text || ' has been recorded.',
      'community_reward_earned',
      v_reward.id,
      'community_referral_reward'
    );

    SELECT c.email, c.name INTO v_email, v_name
    FROM public.customers c WHERE c.id = v_reward.beneficiary_customer_id;

    IF v_email IS NOT NULL THEN
      PERFORM public.queue_email_notification(
        v_email,
        v_name,
        'Your referral reward has been recorded',
        'Hello ' || COALESCE(v_name, '') || ',' || E'\n\n' ||
        'A new homeowner has joined your community project and accepted their quotation. ' ||
        'A 3% referral reward of ' || v_reward.reward_amount::text || ' has been recorded against your project. ' ||
        'Your own quotation is unchanged.'
      );
    END IF;
  END LOOP;

  SELECT d.user_id, COALESCE(c.project_name, 'A community project') INTO v_designer_user_id, v_project_name
  FROM public.community_projects cp
  JOIN public.designers d ON d.id = cp.designer_id
  JOIN public.customers c ON c.id = cp.source_customer_id
  WHERE cp.id = v_req.community_project_id;

  IF v_designer_user_id IS NOT NULL THEN
    PERFORM public.create_notification(
      v_designer_user_id,
      'designer',
      'Community join accepted',
      'A homeowner accepted the quotation for a community join to "' || v_project_name || '".',
      'community_join_accepted',
      v_req.id,
      'community_join_request'
    );
  END IF;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION community_on_quote_accepted() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trigger_community_on_quote_accepted ON designer_quotes;
CREATE TRIGGER trigger_community_on_quote_accepted
  AFTER UPDATE OF customer_accepted ON designer_quotes
  FOR EACH ROW
  WHEN (NEW.customer_accepted = true AND OLD.customer_accepted IS DISTINCT FROM true)
  EXECUTE FUNCTION community_on_quote_accepted();

CREATE OR REPLACE FUNCTION set_community_listing(p_customer_id uuid, p_is_open boolean, p_max_participants integer DEFAULT 5)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_designer_id uuid;
  v_customer public.customers%ROWTYPE;
  v_cp_id uuid;
  v_active integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Please sign in.';
  END IF;

  SELECT d.id INTO v_designer_id FROM public.designers d WHERE d.user_id = auth.uid();
  IF v_designer_id IS NULL THEN
    RAISE EXCEPTION 'Only designers can share projects to the community.';
  END IF;

  IF p_max_participants IS NULL OR p_max_participants < 1 OR p_max_participants > 5 THEN
    RAISE EXCEPTION 'Maximum homeowners must be between 1 and 5.';
  END IF;

  SELECT c.* INTO v_customer FROM public.customers c WHERE c.id = p_customer_id;
  IF NOT FOUND OR v_customer.assigned_designer_id IS DISTINCT FROM v_designer_id THEN
    RAISE EXCEPTION 'You can only share projects you are delivering.';
  END IF;

  IF v_customer.accepted_quote_id IS NULL OR v_customer.activation_status <> 'active' OR v_customer.assignment_status = 'completed' THEN
    RAISE EXCEPTION 'Only active projects with an accepted and paid quotation can be shared.';
  END IF;

  SELECT cp.id INTO v_cp_id FROM public.community_projects cp WHERE cp.source_customer_id = p_customer_id;

  IF v_cp_id IS NOT NULL THEN
    SELECT count(*) INTO v_active FROM public.community_participants p
    WHERE p.community_project_id = v_cp_id AND p.status IN ('reserved','confirmed');
    IF p_max_participants < v_active THEN
      RAISE EXCEPTION 'Maximum homeowners cannot be below the % already in this project.', v_active;
    END IF;
  END IF;

  INSERT INTO public.community_projects (source_customer_id, designer_id, is_open, max_participants)
  VALUES (p_customer_id, v_designer_id, p_is_open, p_max_participants)
  ON CONFLICT (source_customer_id) DO UPDATE
  SET is_open = EXCLUDED.is_open,
      max_participants = EXCLUDED.max_participants,
      updated_at = now()
  RETURNING id INTO v_cp_id;

  INSERT INTO public.community_participants (community_project_id, customer_id, homeowner_user_id, role, status, joined_at)
  VALUES (v_cp_id, v_customer.id, v_customer.user_id, 'original', 'confirmed', now())
  ON CONFLICT (customer_id) DO NOTHING;

  RETURN v_cp_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION set_community_listing(uuid, boolean, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION set_community_listing(uuid, boolean, integer) TO authenticated;

CREATE OR REPLACE FUNCTION request_community_join(p_community_project_id uuid, p_requester_customer_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cp public.community_projects%ROWTYPE;
  v_source public.customers%ROWTYPE;
  v_requester public.customers%ROWTYPE;
  v_designer_user_id uuid;
  v_designer_email text;
  v_designer_name text;
  v_active integer;
  v_request_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Please sign in to join a project.';
  END IF;

  SELECT cp.* INTO v_cp FROM public.community_projects cp WHERE cp.id = p_community_project_id;
  IF NOT FOUND OR NOT v_cp.is_open THEN
    RAISE EXCEPTION 'This project is not accepting new homeowners.';
  END IF;

  SELECT c.* INTO v_source FROM public.customers c WHERE c.id = v_cp.source_customer_id;
  IF v_source.activation_status <> 'active' OR v_source.assignment_status = 'completed' THEN
    RAISE EXCEPTION 'This project is no longer open for joining.';
  END IF;

  IF v_source.user_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot join your own project.';
  END IF;

  SELECT c.* INTO v_requester FROM public.customers c
  WHERE c.id = p_requester_customer_id AND c.user_id = auth.uid();
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Choose one of your own projects to join with.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.community_join_requests r
    WHERE r.community_project_id = v_cp.id
      AND r.requester_user_id = auth.uid()
      AND r.status IN ('pending','approved','accepted')
  ) THEN
    RAISE EXCEPTION 'You already have an active request for this project.';
  END IF;

  SELECT count(*) INTO v_active FROM public.community_participants p
  WHERE p.community_project_id = v_cp.id AND p.status IN ('reserved','confirmed');
  IF v_active >= v_cp.max_participants THEN
    RAISE EXCEPTION 'This project has no open spots left.';
  END IF;

  INSERT INTO public.community_join_requests (community_project_id, requester_user_id, requester_customer_id)
  VALUES (v_cp.id, auth.uid(), v_requester.id)
  RETURNING id INTO v_request_id;

  SELECT d.user_id, d.email, d.name INTO v_designer_user_id, v_designer_email, v_designer_name
  FROM public.designers d WHERE d.id = v_cp.designer_id;

  IF v_designer_user_id IS NOT NULL THEN
    PERFORM public.create_notification(
      v_designer_user_id,
      'designer',
      'New community join request',
      'A homeowner has requested to join "' || v_source.project_name || '". Review it in your Community Join Requests section.',
      'community_join_request',
      v_request_id,
      'community_join_request'
    );
  END IF;

  IF v_designer_email IS NOT NULL THEN
    PERFORM public.queue_email_notification(
      v_designer_email,
      v_designer_name,
      'New community join request for ' || v_source.project_name,
      'Hello ' || COALESCE(v_designer_name, '') || ',' || E'\n\n' ||
      'A homeowner has requested to join your project "' || v_source.project_name || '". ' ||
      'Sign in to your dashboard to approve or reject the request.'
    );
  END IF;

  RETURN v_request_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION request_community_join(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION request_community_join(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION decide_community_join_request(p_request_id uuid, p_decision text, p_reason text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_designer_id uuid;
  v_req public.community_join_requests%ROWTYPE;
  v_cp public.community_projects%ROWTYPE;
  v_source public.customers%ROWTYPE;
  v_requester public.customers%ROWTYPE;
  v_src_quote public.designer_quotes%ROWTYPE;
  v_new_customer_id uuid;
  v_new_quote_id uuid;
  v_comm_discount numeric;
  v_new_discount numeric;
  v_new_net numeric;
  v_new_tax numeric;
  v_active integer;
  v_requester_email text;
  v_requester_name text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Please sign in.';
  END IF;

  SELECT d.id INTO v_designer_id FROM public.designers d WHERE d.user_id = auth.uid();
  IF v_designer_id IS NULL THEN
    RAISE EXCEPTION 'Only designers can decide join requests.';
  END IF;

  IF p_decision NOT IN ('approve','reject') THEN
    RAISE EXCEPTION 'Decision must be approve or reject.';
  END IF;

  SELECT r.* INTO v_req FROM public.community_join_requests r WHERE r.id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Join request not found.';
  END IF;

  SELECT cp.* INTO v_cp FROM public.community_projects cp WHERE cp.id = v_req.community_project_id FOR UPDATE;
  IF v_cp.designer_id IS DISTINCT FROM v_designer_id THEN
    RAISE EXCEPTION 'You are not authorized to decide this request.';
  END IF;

  IF v_req.status <> 'pending' THEN
    RAISE EXCEPTION 'This request has already been decided (current status: %).', v_req.status;
  END IF;

  SELECT c.* INTO v_requester FROM public.customers c WHERE c.id = v_req.requester_customer_id;
  v_requester_email := COALESCE(v_requester.email, '');
  v_requester_name := v_requester.name;

  IF p_decision = 'reject' THEN
    UPDATE public.community_join_requests
    SET status = 'rejected', rejection_reason = p_reason, decided_at = now(), updated_at = now()
    WHERE id = v_req.id;

    PERFORM public.create_notification(
      v_req.requester_user_id,
      'customer',
      'Join request not approved',
      'The designer did not approve your request to join a community project.' ||
        CASE WHEN p_reason IS NOT NULL AND p_reason <> '' THEN ' Reason: ' || p_reason ELSE '' END,
      'community_join_rejected',
      v_req.id,
      'community_join_request'
    );

    IF v_requester_email <> '' THEN
      PERFORM public.queue_email_notification(
        v_requester_email,
        v_requester_name,
        'Your community join request was not approved',
        'Hello ' || COALESCE(v_requester_name, '') || ',' || E'\n\n' ||
        'The designer was unable to approve your request to join a community project.' ||
        CASE WHEN p_reason IS NOT NULL AND p_reason <> '' THEN ' Reason: ' || p_reason || '.' ELSE '' END
      );
    END IF;

    RETURN jsonb_build_object('status', 'rejected');
  END IF;

  SELECT c.* INTO v_source FROM public.customers c WHERE c.id = v_cp.source_customer_id;
  IF NOT v_cp.is_open OR v_source.activation_status <> 'active' OR v_source.accepted_quote_id IS NULL THEN
    RAISE EXCEPTION 'This project is no longer open for joining.';
  END IF;

  SELECT count(*) INTO v_active FROM public.community_participants p
  WHERE p.community_project_id = v_cp.id AND p.status IN ('reserved','confirmed');
  IF v_active >= v_cp.max_participants THEN
    RAISE EXCEPTION 'No open spots remain in this project.';
  END IF;

  SELECT q.* INTO v_src_quote FROM public.designer_quotes q WHERE q.id = v_source.accepted_quote_id;

  v_comm_discount := ROUND((v_src_quote.subtotal - v_src_quote.discount_amount) * 3 / 100.0, 2);
  v_new_discount := v_src_quote.discount_amount + v_comm_discount;
  v_new_net := v_src_quote.subtotal - v_new_discount;
  v_new_tax := ROUND(v_new_net * v_src_quote.tax_rate / 100.0, 2);

  INSERT INTO public.customers (
    user_id, name, email, phone, location, project_name, property_type, project_area,
    budget_range, timeline, requirements, preferred_designer, layout_image_url,
    inspiration_links, room_types, special_requirements, status, assignment_status,
    activation_status, address, challenges_solutions, project_timeline_details,
    materials_cost_breakdown
  ) VALUES (
    v_requester.user_id, v_requester.name, v_requester.email, v_requester.phone, v_requester.location,
    v_requester.project_name, v_requester.property_type, v_requester.project_area,
    v_requester.budget_range, v_requester.timeline, v_requester.requirements, v_requester.preferred_designer,
    v_requester.layout_image_url, v_requester.inspiration_links, v_requester.room_types,
    v_requester.special_requirements, 'pending', 'unassigned', 'quoting', v_requester.address,
    v_requester.challenges_solutions, v_requester.project_timeline_details, v_requester.materials_cost_breakdown
  )
  RETURNING id INTO v_new_customer_id;

  INSERT INTO public.designer_quotes (
    designer_id, project_id, quote_number, title, description, subtotal, discount_amount,
    tax_rate, tax_amount, total_amount, status, valid_until, terms_and_conditions,
    customer_accepted, payment_status, version_number, revision_round
  ) VALUES (
    v_cp.designer_id, v_new_customer_id,
    'QT-' || to_char(now(), 'YYMMDD') || '-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)),
    v_src_quote.title, v_src_quote.description, v_src_quote.subtotal, v_new_discount,
    v_src_quote.tax_rate, v_new_tax, v_new_net + v_new_tax, 'sent', v_src_quote.valid_until,
    v_src_quote.terms_and_conditions, false, 'pending', 1, 0
  )
  RETURNING id INTO v_new_quote_id;

  INSERT INTO public.quote_items (
    quote_id, material_id, item_type, name, description, quantity, unit, unit_price,
    discount_percent, amount, length, breadth, number_of_units, width, height, depth,
    section, width_unit, height_unit, depth_unit, area_sqft, per_sqft_rate, image_url
  )
  SELECT
    v_new_quote_id, i.material_id, i.item_type, i.name, i.description, i.quantity, i.unit, i.unit_price,
    i.discount_percent, i.amount, i.length, i.breadth, i.number_of_units, i.width, i.height, i.depth,
    i.section, i.width_unit, i.height_unit, i.depth_unit, i.area_sqft, i.per_sqft_rate, i.image_url
  FROM public.quote_items i
  WHERE i.quote_id = v_src_quote.id;

  INSERT INTO public.community_participants (
    community_project_id, customer_id, homeowner_user_id, role, status, join_request_id, joined_at
  ) VALUES (
    v_cp.id, v_new_customer_id, v_req.requester_user_id, 'joined', 'reserved', v_req.id, now()
  );

  UPDATE public.community_join_requests
  SET status = 'approved',
      new_customer_id = v_new_customer_id,
      cloned_quote_id = v_new_quote_id,
      decided_at = now(),
      updated_at = now()
  WHERE id = v_req.id;

  PERFORM public.create_notification(
    v_req.requester_user_id,
    'customer',
    'Join request approved',
    'Your request to join a community project was approved. Your quotation is ready to review and accept.',
    'community_join_approved',
    v_new_quote_id,
    'quotation'
  );

  IF v_requester_email <> '' THEN
    PERFORM public.queue_email_notification(
      v_requester_email,
      v_requester_name,
      'Your community join request was approved',
      'Hello ' || COALESCE(v_requester_name, '') || ',' || E'\n\n' ||
      'Your request to join a community project was approved. Sign in to review and accept your quotation.'
    );
  END IF;

  RETURN jsonb_build_object(
    'status', 'approved',
    'new_customer_id', v_new_customer_id,
    'quote_id', v_new_quote_id
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION decide_community_join_request(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION decide_community_join_request(uuid, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION get_community_listings()
RETURNS TABLE (
  community_project_id uuid,
  project_name text,
  township text,
  property_type text,
  project_area text,
  budget_range text,
  timeline text,
  designer_id uuid,
  designer_name text,
  project_value numeric,
  max_participants integer,
  participant_count integer,
  my_status text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    cp.id,
    c.project_name,
    c.location,
    c.property_type,
    c.project_area,
    c.budget_range,
    c.timeline,
    d.id,
    d.name,
    q.total_amount,
    cp.max_participants,
    (SELECT count(*)::integer FROM public.community_participants p
      WHERE p.community_project_id = cp.id AND p.status IN ('reserved','confirmed')),
    CASE
      WHEN auth.uid() IS NULL THEN NULL
      WHEN c.user_id = auth.uid() THEN 'owner'
      ELSE (SELECT r.status FROM public.community_join_requests r
             WHERE r.community_project_id = cp.id
               AND r.requester_user_id = auth.uid()
               AND r.status IN ('pending','approved','accepted')
             ORDER BY r.requested_at DESC LIMIT 1)
    END
  FROM public.community_projects cp
  JOIN public.customers c ON c.id = cp.source_customer_id
  JOIN public.designers d ON d.id = cp.designer_id
  LEFT JOIN public.designer_quotes q ON q.id = c.accepted_quote_id
  WHERE cp.is_open
    AND c.activation_status = 'active'
    AND c.assignment_status <> 'completed'
  ORDER BY cp.created_at DESC;
$$;

REVOKE EXECUTE ON FUNCTION get_community_listings() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_community_listings() TO anon, authenticated;

CREATE OR REPLACE FUNCTION get_designer_community_overview()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_designer_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Please sign in.';
  END IF;

  SELECT d.id INTO v_designer_id FROM public.designers d WHERE d.user_id = auth.uid();
  IF v_designer_id IS NULL THEN
    RAISE EXCEPTION 'Only designers can view community requests.';
  END IF;

  RETURN jsonb_build_object(
    'projects', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'customer_id', c.id,
        'project_name', c.project_name,
        'township', c.location,
        'community_project_id', cp.id,
        'is_open', COALESCE(cp.is_open, false),
        'max_participants', COALESCE(cp.max_participants, 5),
        'participant_count', (SELECT count(*) FROM public.community_participants p
                               WHERE p.community_project_id = cp.id AND p.status IN ('reserved','confirmed'))
      ) ORDER BY c.updated_at DESC)
      FROM public.customers c
      LEFT JOIN public.community_projects cp ON cp.source_customer_id = c.id
      WHERE c.assigned_designer_id = v_designer_id
        AND c.accepted_quote_id IS NOT NULL
        AND c.activation_status = 'active'
        AND c.assignment_status <> 'completed'
    ), '[]'::jsonb),
    'requests', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', r.id,
        'status', r.status,
        'requested_at', r.requested_at,
        'decided_at', r.decided_at,
        'rejection_reason', r.rejection_reason,
        'source_project_name', src.project_name,
        'requester_name', req.name,
        'requester_project_name', req.project_name,
        'township', req.location,
        'property_type', req.property_type,
        'project_area', req.project_area,
        'budget_range', req.budget_range,
        'requirements', req.requirements
      ) ORDER BY r.requested_at DESC)
      FROM public.community_join_requests r
      JOIN public.community_projects cp ON cp.id = r.community_project_id
      JOIN public.customers src ON src.id = cp.source_customer_id
      JOIN public.customers req ON req.id = r.requester_customer_id
      WHERE cp.designer_id = v_designer_id
    ), '[]'::jsonb)
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION get_designer_community_overview() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_designer_community_overview() TO authenticated;

CREATE OR REPLACE FUNCTION get_my_community_activity()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Please sign in.';
  END IF;

  RETURN jsonb_build_object(
    'requests', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', r.id,
        'status', r.status,
        'requested_at', r.requested_at,
        'source_project_name', src.project_name,
        'designer_name', d.name,
        'my_project_name', req.project_name,
        'new_customer_id', r.new_customer_id,
        'cloned_quote_id', r.cloned_quote_id,
        'rejection_reason', r.rejection_reason
      ) ORDER BY r.requested_at DESC)
      FROM public.community_join_requests r
      JOIN public.community_projects cp ON cp.id = r.community_project_id
      JOIN public.customers src ON src.id = cp.source_customer_id
      JOIN public.designers d ON d.id = cp.designer_id
      JOIN public.customers req ON req.id = r.requester_customer_id
      WHERE r.requester_user_id = auth.uid()
    ), '[]'::jsonb),
    'rewards', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', w.id,
        'reward_percent', w.reward_percent,
        'base_amount', w.base_amount,
        'reward_amount', w.reward_amount,
        'status', w.status,
        'created_at', w.created_at
      ) ORDER BY w.created_at DESC)
      FROM public.community_referral_rewards w
      WHERE w.beneficiary_user_id = auth.uid()
    ), '[]'::jsonb)
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION get_my_community_activity() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_my_community_activity() TO authenticated;
