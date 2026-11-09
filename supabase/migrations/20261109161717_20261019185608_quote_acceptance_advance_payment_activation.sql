CREATE TABLE IF NOT EXISTS public.quote_advance_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id uuid NOT NULL REFERENCES public.designer_quotes(id) ON DELETE CASCADE,
  project_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  designer_id uuid REFERENCES public.designers(id) ON DELETE SET NULL,
  customer_user_id uuid,
  razorpay_order_id text UNIQUE,
  razorpay_payment_id text,
  amount numeric NOT NULL,
  currency text NOT NULL DEFAULT 'INR',
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paid','failed','cancelled')),
  provider_response jsonb,
  failure_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  paid_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_quote_advance_payments_quote_id ON public.quote_advance_payments(quote_id);
CREATE INDEX IF NOT EXISTS idx_quote_advance_payments_project_id ON public.quote_advance_payments(project_id);
CREATE INDEX IF NOT EXISTS idx_quote_advance_payments_designer_id ON public.quote_advance_payments(designer_id);
CREATE INDEX IF NOT EXISTS idx_quote_advance_payments_status ON public.quote_advance_payments(status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_quote_advance_payments_razorpay_payment_id ON public.quote_advance_payments(razorpay_payment_id) WHERE razorpay_payment_id IS NOT NULL;

ALTER TABLE public.quote_advance_payments ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.quote_advance_payments FROM PUBLIC, anon;
GRANT SELECT ON public.quote_advance_payments TO authenticated;
GRANT ALL ON public.quote_advance_payments TO service_role;

DROP POLICY IF EXISTS "Customers can read own project advance payments" ON public.quote_advance_payments;
CREATE POLICY "Customers can read own project advance payments" ON public.quote_advance_payments FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.customers c WHERE c.id = quote_advance_payments.project_id AND c.user_id = auth.uid()));

DROP POLICY IF EXISTS "Designers can read advance payments for their quotes" ON public.quote_advance_payments;
CREATE POLICY "Designers can read advance payments for their quotes" ON public.quote_advance_payments FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.designers d WHERE d.id = quote_advance_payments.designer_id AND d.user_id = auth.uid()));

DROP POLICY IF EXISTS "Admins can read all advance payments" ON public.quote_advance_payments;
CREATE POLICY "Admins can read all advance payments" ON public.quote_advance_payments FOR SELECT TO authenticated
  USING (public.is_active_admin());

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='customers' AND column_name='accepted_quote_id') THEN
    ALTER TABLE public.customers ADD COLUMN accepted_quote_id uuid REFERENCES public.designer_quotes(id) ON DELETE SET NULL;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='customers' AND column_name='activation_status') THEN
    ALTER TABLE public.customers ADD COLUMN activation_status text NOT NULL DEFAULT 'quoting'
      CHECK (activation_status IN ('quoting','awaiting_advance','active','on_hold','completed'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_customers_activation_status ON public.customers(activation_status);
CREATE INDEX IF NOT EXISTS idx_customers_accepted_quote_id ON public.customers(accepted_quote_id);

UPDATE public.customers
SET activation_status = CASE
  WHEN assignment_status = 'completed' THEN 'completed'
  WHEN accepted_quote_id IS NOT NULL THEN 'awaiting_advance'
  ELSE 'quoting'
END
WHERE activation_status IS NULL OR activation_status = 'quoting';

INSERT INTO public.site_settings (setting_key, video_url, video_title, is_active)
VALUES
  ('advance_payment_percent', '10', 'Advance payment percentage charged on quote acceptance', true),
  ('advance_payment_min_amount', '0', 'Minimum advance amount in rupees (0 = no minimum)', true),
  ('advance_payment_terms', '10% advance payment is required to confirm the designer and start the project. The remaining balance is due per the agreed milestone schedule.', 'Terms shown to the homeowner at checkout', true)
ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION public.get_advance_payment_config()
RETURNS TABLE(percent numeric, min_amount numeric, terms text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_percent_text text;
  v_min_text text;
  v_terms text;
  v_percent numeric;
  v_min numeric;
BEGIN
  SELECT video_url INTO v_percent_text FROM public.site_settings WHERE setting_key = 'advance_payment_percent' AND is_active = true LIMIT 1;
  SELECT video_url INTO v_min_text FROM public.site_settings WHERE setting_key = 'advance_payment_min_amount' AND is_active = true LIMIT 1;
  SELECT video_url INTO v_terms FROM public.site_settings WHERE setting_key = 'advance_payment_terms' AND is_active = true LIMIT 1;

  BEGIN
    v_percent := COALESCE(NULLIF(v_percent_text,'')::numeric, 10);
  EXCEPTION WHEN OTHERS THEN v_percent := 10; END;
  BEGIN
    v_min := COALESCE(NULLIF(v_min_text,'')::numeric, 0);
  EXCEPTION WHEN OTHERS THEN v_min := 0; END;

  IF v_percent < 0 THEN v_percent := 0; END IF;
  IF v_percent > 100 THEN v_percent := 100; END IF;

  RETURN QUERY SELECT v_percent, v_min, COALESCE(v_terms, '');
END;
$function$;

CREATE OR REPLACE FUNCTION public.accept_quote(p_quote_id uuid, p_feedback text DEFAULT NULL)
RETURNS TABLE(success boolean, project_id uuid, designer_id uuid, advance_amount numeric, accepted_quote_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_quote public.designer_quotes%ROWTYPE;
  v_project public.customers%ROWTYPE;
  v_advance_percent numeric;
  v_advance_min numeric;
  v_advance numeric;
  v_terms text;
  v_designer_user_id uuid;
  v_customer_name text;
  v_competing public.designer_quotes%ROWTYPE;
  v_competing_designer_user_id uuid;
BEGIN
  SELECT q.* INTO v_quote FROM public.designer_quotes q WHERE q.id = p_quote_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Quote not found.';
  END IF;

  SELECT c.* INTO v_project FROM public.customers c WHERE c.id = v_quote.project_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Project for this quote not found.';
  END IF;

  IF v_project.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'You are not authorized to accept a quote for this project.';
  END IF;

  IF v_project.accepted_quote_id IS NOT NULL THEN
    RAISE EXCEPTION 'A quotation has already been accepted for this project.';
  END IF;

  IF v_quote.status NOT IN ('sent','draft') OR v_quote.customer_accepted = true THEN
    RAISE EXCEPTION 'This quotation is not in a state that can be accepted (current status: %).', v_quote.status;
  END IF;

  SELECT cfg.percent, cfg.min_amount, cfg.terms INTO v_advance_percent, v_advance_min, v_terms FROM public.get_advance_payment_config() cfg;
  v_advance := ROUND((v_quote.total_amount * v_advance_percent) / 100.0, 2);
  IF v_advance < v_advance_min THEN
    v_advance := v_advance_min;
  END IF;

  UPDATE public.designer_quotes dq
  SET status = 'accepted',
      customer_accepted = true,
      acceptance_date = now(),
      customer_feedback = COALESCE(p_feedback, 'Quote accepted'),
      confirmation_amount = v_advance,
      updated_at = now()
  WHERE dq.id = p_quote_id;

  UPDATE public.customers cu
  SET accepted_quote_id = p_quote_id,
      assigned_designer_id = v_quote.designer_id,
      assignment_status = 'assigned',
      activation_status = 'awaiting_advance',
      updated_at = now()
  WHERE cu.id = v_project.id;

  INSERT INTO public.quote_acceptance_history (quote_id, previous_status, new_status, changed_by, changed_by_type, feedback)
  VALUES (p_quote_id, v_quote.status, 'accepted', auth.uid(), 'customer', COALESCE(p_feedback, 'Quote accepted'));

  FOR v_competing IN
    SELECT q.* FROM public.designer_quotes q
    WHERE q.project_id = v_project.id AND q.id <> p_quote_id AND q.status IN ('sent','draft','changes_requested')
  LOOP
    UPDATE public.designer_quotes dq
    SET status = 'rejected',
        rejection_reason = 'ANOTHER_DESIGNER_SELECTED',
        rejection_comments = 'Another designer was selected for this project.',
        customer_accepted = false,
        updated_at = now()
    WHERE dq.id = v_competing.id;

    INSERT INTO public.quote_acceptance_history (quote_id, previous_status, new_status, changed_by, changed_by_type, feedback)
    VALUES (v_competing.id, v_competing.status, 'rejected', auth.uid(), 'customer', 'Closed automatically: another designer was selected.');

    SELECT d.user_id INTO v_competing_designer_user_id FROM public.designers d WHERE d.id = v_competing.designer_id;
    IF v_competing_designer_user_id IS NOT NULL THEN
      PERFORM public.create_notification(
        v_competing_designer_user_id, 'designer', 'Quotation Not Selected',
        COALESCE(v_project.project_name, 'A project') || ': the homeowner selected another designer. Your quotation is preserved for reference.',
        'quotation_not_selected', v_competing.id, 'quotation');
    END IF;
  END LOOP;

  UPDATE public.project_assignments pa
  SET status = 'closed', updated_at = now(), responded_at = COALESCE(pa.responded_at, now())
  WHERE pa.project_id = v_project.id AND pa.designer_id IS DISTINCT FROM v_quote.designer_id AND pa.status IN ('pending','accepted');

  SELECT d.user_id INTO v_designer_user_id FROM public.designers d WHERE d.id = v_quote.designer_id;
  SELECT COALESCE(u.raw_user_meta_data->>'full_name', u.email) INTO v_customer_name FROM auth.users u WHERE u.id = v_project.user_id;

  IF v_designer_user_id IS NOT NULL THEN
    PERFORM public.create_notification(
      v_designer_user_id, 'designer', 'Quotation Accepted',
      COALESCE(v_customer_name, 'A homeowner') || ' has accepted your quotation for "' || COALESCE(v_project.project_name,'') || '". An advance payment of ' || v_advance::text || ' is now pending to activate the project.',
      'quotation_accepted', p_quote_id, 'quotation');
  END IF;

  RETURN QUERY SELECT true, v_project.id, v_quote.designer_id, v_advance, p_quote_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.record_quote_payment(
  p_quote_id uuid,
  p_razorpay_order_id text DEFAULT NULL,
  p_razorpay_payment_id text DEFAULT NULL,
  p_amount numeric DEFAULT NULL,
  p_provider_response jsonb DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_quote public.designer_quotes%ROWTYPE;
  v_project public.customers%ROWTYPE;
  v_payment public.quote_advance_payments%ROWTYPE;
  v_designer_user_id uuid;
  v_customer_name text;
BEGIN
  SELECT q.* INTO v_quote FROM public.designer_quotes q WHERE q.id = p_quote_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Quote not found.';
  END IF;

  SELECT p.* INTO v_payment FROM public.quote_advance_payments p WHERE p.quote_id = p_quote_id AND p.status = 'paid' LIMIT 1;
  IF FOUND THEN
    RETURN;
  END IF;

  SELECT c.* INTO v_project FROM public.customers c WHERE c.id = v_quote.project_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Project for this quote not found.';
  END IF;

  IF v_project.accepted_quote_id IS DISTINCT FROM p_quote_id THEN
    RAISE EXCEPTION 'This quotation is not the accepted quotation for its project and cannot be paid.';
  END IF;

  v_payment := NULL;
  IF p_razorpay_order_id IS NOT NULL THEN
    SELECT p.* INTO v_payment FROM public.quote_advance_payments p WHERE p.razorpay_order_id = p_razorpay_order_id LIMIT 1;
  END IF;

  IF v_payment.id IS NOT NULL THEN
    UPDATE public.quote_advance_payments qap
    SET status = 'paid',
        razorpay_payment_id = COALESCE(p_razorpay_payment_id, qap.razorpay_payment_id),
        provider_response = COALESCE(p_provider_response, qap.provider_response),
        amount = COALESCE(p_amount, qap.amount),
        paid_at = now(),
        updated_at = now()
    WHERE qap.id = v_payment.id;
  ELSE
    INSERT INTO public.quote_advance_payments
      (quote_id, project_id, designer_id, customer_user_id, razorpay_order_id, razorpay_payment_id, amount, status, provider_response, paid_at)
    VALUES
      (p_quote_id, v_quote.project_id, v_quote.designer_id, v_project.user_id, p_razorpay_order_id, p_razorpay_payment_id,
       COALESCE(p_amount, v_quote.confirmation_amount), 'paid', p_provider_response, now());
  END IF;

  UPDATE public.designer_quotes dq
  SET payment_status = 'verified',
      razorpay_order_id = COALESCE(p_razorpay_order_id, dq.razorpay_order_id),
      razorpay_payment_id = COALESCE(p_razorpay_payment_id, dq.razorpay_payment_id),
      confirmation_amount = COALESCE(p_amount, dq.confirmation_amount),
      updated_at = now()
  WHERE dq.id = p_quote_id;

  UPDATE public.customers cu
  SET activation_status = 'active',
      assignment_status = 'assigned',
      assigned_designer_id = v_quote.designer_id,
      work_begin_date = COALESCE(cu.work_begin_date, now()),
      updated_at = now()
  WHERE cu.id = v_project.id;

  SELECT d.user_id INTO v_designer_user_id FROM public.designers d WHERE d.id = v_quote.designer_id;
  SELECT COALESCE(u.raw_user_meta_data->>'full_name', u.email) INTO v_customer_name FROM auth.users u WHERE u.id = v_project.user_id;

  IF v_designer_user_id IS NOT NULL THEN
    PERFORM public.create_notification(
      v_designer_user_id, 'designer', 'Advance Payment Verified - Project Activated',
      COALESCE(v_customer_name, 'The homeowner') || ' has made the advance payment for "' || COALESCE(v_project.project_name,'') || '". The project is now active.',
      'project_activated', p_quote_id, 'quotation');
  END IF;

  IF v_project.user_id IS NOT NULL THEN
    PERFORM public.create_notification(
      v_project.user_id, 'customer', 'Payment Confirmed - Project Activated',
      'Your advance payment has been verified. The project "' || COALESCE(v_project.project_name,'') || '" is now active and the designer''s contact details are unlocked.',
      'project_activated', p_quote_id, 'quotation');
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_quote_acceptance(p_quote_id uuid, p_reason text DEFAULT NULL)
RETURNS TABLE(success boolean, project_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_quote public.designer_quotes%ROWTYPE;
  v_project public.customers%ROWTYPE;
  v_designer_user_id uuid;
BEGIN
  SELECT q.* INTO v_quote FROM public.designer_quotes q WHERE q.id = p_quote_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Quote not found.';
  END IF;

  SELECT c.* INTO v_project FROM public.customers c WHERE c.id = v_quote.project_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Project not found.';
  END IF;

  IF v_project.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'You are not authorized to cancel this quotation.';
  END IF;

  IF v_project.accepted_quote_id IS DISTINCT FROM p_quote_id THEN
    RAISE EXCEPTION 'This quotation is not the currently accepted quotation.';
  END IF;

  IF v_project.activation_status NOT IN ('awaiting_advance','on_hold') THEN
    RAISE EXCEPTION 'Cannot cancel an accepted quotation after the advance payment has been verified. Use the project cancellation workflow instead.';
  END IF;

  UPDATE public.customers cu
  SET accepted_quote_id = NULL,
      assigned_designer_id = NULL,
      assignment_status = 'unassigned',
      activation_status = 'quoting',
      updated_at = now()
  WHERE cu.id = v_project.id;

  UPDATE public.designer_quotes dq
  SET status = 'sent',
      customer_accepted = false,
      customer_feedback = COALESCE(p_reason, 'Acceptance cancelled by homeowner'),
      updated_at = now()
  WHERE dq.id = p_quote_id;

  INSERT INTO public.quote_acceptance_history (quote_id, previous_status, new_status, changed_by, changed_by_type, feedback)
  VALUES (p_quote_id, 'accepted', 'sent', auth.uid(), 'customer', COALESCE(p_reason, 'Acceptance cancelled by homeowner'));

  SELECT d.user_id INTO v_designer_user_id FROM public.designers d WHERE d.id = v_quote.designer_id;
  IF v_designer_user_id IS NOT NULL THEN
    PERFORM public.create_notification(
      v_designer_user_id, 'designer', 'Quotation Acceptance Cancelled',
      'The homeowner cancelled the acceptance of your quotation for "' || COALESCE(v_project.project_name,'') || '". No advance payment was collected.',
      'quotation_acceptance_cancelled', p_quote_id, 'quotation');
  END IF;

  RETURN QUERY SELECT true, v_project.id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.reopen_project_for_quotes(p_project_id uuid)
RETURNS TABLE(success boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_project public.customers%ROWTYPE;
  v_quote public.designer_quotes%ROWTYPE;
BEGIN
  SELECT c.* INTO v_project FROM public.customers c WHERE c.id = p_project_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Project not found.';
  END IF;

  IF v_project.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'You are not authorized to reopen this project.';
  END IF;

  IF v_project.activation_status <> 'quoting' THEN
    RAISE EXCEPTION 'Project is not in a quoting state and cannot be reopened for new quotations.';
  END IF;

  FOR v_quote IN
    SELECT q.* FROM public.designer_quotes q
    WHERE q.project_id = p_project_id AND q.status = 'rejected' AND q.rejection_reason = 'ANOTHER_DESIGNER_SELECTED'
  LOOP
    UPDATE public.designer_quotes dq
    SET status = 'sent', rejection_reason = NULL, rejection_comments = NULL, customer_accepted = false, updated_at = now()
    WHERE dq.id = v_quote.id;

    INSERT INTO public.quote_acceptance_history (quote_id, previous_status, new_status, changed_by, changed_by_type, feedback)
    VALUES (v_quote.id, 'rejected', 'sent', auth.uid(), 'customer', 'Reopened for consideration after cancellation.');
  END LOOP;

  UPDATE public.project_assignments pa
  SET status = 'pending', updated_at = now()
  WHERE pa.project_id = p_project_id
    AND pa.status = 'closed'
    AND NOT EXISTS (
      SELECT 1 FROM public.designer_quotes q
      WHERE q.project_id = p_project_id AND q.designer_id = pa.designer_id AND q.status IN ('sent','accepted')
    );

  PERFORM public.create_notification(
    v_project.user_id, 'customer', 'Project Reopened for Quotations',
    'Your project "' || COALESCE(v_project.project_name,'') || '" is open for quotations again. Previously closed quotes have been restored for your review.',
    'project_reopened', p_project_id, 'project');

  RETURN QUERY SELECT true;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_payment_failure(p_quote_id uuid, p_razorpay_order_id text, p_status text, p_failure_reason text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_payment public.quote_advance_payments%ROWTYPE;
  v_project public.customers%ROWTYPE;
  v_quote_project_id uuid;
BEGIN
  IF p_status NOT IN ('failed','cancelled') THEN
    RAISE EXCEPTION 'p_status must be ''failed'' or ''cancelled''.';
  END IF;

  SELECT q.project_id INTO v_quote_project_id FROM public.designer_quotes q WHERE q.id = p_quote_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Quote not found.';
  END IF;

  SELECT p.* INTO v_payment FROM public.quote_advance_payments p WHERE p.razorpay_order_id = p_razorpay_order_id LIMIT 1;

  IF NOT FOUND THEN
    INSERT INTO public.quote_advance_payments (quote_id, project_id, designer_id, customer_user_id, razorpay_order_id, amount, status, failure_reason)
    SELECT p_quote_id, q.project_id, q.designer_id, c.user_id, p_razorpay_order_id, COALESCE(q.confirmation_amount, 0), p_status, p_failure_reason
    FROM public.designer_quotes q
    JOIN public.customers c ON c.id = q.project_id
    WHERE q.id = p_quote_id;
  ELSE
    IF v_payment.status = 'paid' THEN
      RETURN;
    END IF;

    UPDATE public.quote_advance_payments qap
    SET status = p_status, failure_reason = p_failure_reason, updated_at = now()
    WHERE qap.id = v_payment.id;
  END IF;

  SELECT c.* INTO v_project FROM public.customers c WHERE c.id = v_quote_project_id FOR UPDATE;
  IF FOUND AND v_project.activation_status = 'awaiting_advance' THEN
    UPDATE public.customers cu SET activation_status = 'on_hold', updated_at = now() WHERE cu.id = v_project.id;
  END IF;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.accept_quote(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_quote_payment(uuid, text, text, numeric, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_quote_acceptance(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reopen_project_for_quotes(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_payment_failure(uuid, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_advance_payment_config() TO authenticated;
