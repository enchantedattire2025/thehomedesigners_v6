/*
# Create AI quotation assistant foundation

Adds the AI quotation add-on: plans, per-designer AI subscriptions, monthly credit periods and an immutable credit ledger, AI quotation jobs with rooms and items, and an admin-only AI configuration row. A private ai-floor-plans storage bucket is created with owner-folder policies.

Security: RLS is enabled on every new table. Designers reach only their own rows. Plan and configuration management is limited to active admins. Credit balances and job state are changed only by server-side functions. No existing tables are modified.
*/

CREATE TABLE IF NOT EXISTS ai_subscription_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text NOT NULL DEFAULT '',
  price numeric(12,2) NOT NULL CHECK (price >= 0),
  billing_period text NOT NULL DEFAULT 'monthly' CHECK (billing_period = 'monthly'),
  monthly_credits integer NOT NULL CHECK (monthly_credits > 0),
  features jsonb NOT NULL DEFAULT '[]'::jsonb,
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS designer_ai_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  designer_id uuid NOT NULL REFERENCES designers(id) ON DELETE CASCADE,
  ai_plan_id uuid NOT NULL REFERENCES ai_subscription_plans(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('trial','active','expired','cancelled','suspended')),
  subscription_start_date timestamptz,
  subscription_end_date timestamptz,
  auto_renew boolean NOT NULL DEFAULT true,
  payment_provider text,
  provider_subscription_id text,
  cancelled_at timestamptz,
  cancellation_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS one_current_ai_subscription_per_designer
  ON designer_ai_subscriptions (designer_id)
  WHERE status IN ('trial','active');

CREATE TABLE IF NOT EXISTS ai_credit_periods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  designer_id uuid NOT NULL REFERENCES designers(id) ON DELETE CASCADE,
  ai_subscription_id uuid NOT NULL REFERENCES designer_ai_subscriptions(id) ON DELETE CASCADE,
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  credits_granted integer NOT NULL CHECK (credits_granted >= 0),
  credits_reserved integer NOT NULL DEFAULT 0 CHECK (credits_reserved >= 0),
  credits_consumed integer NOT NULL DEFAULT 0 CHECK (credits_consumed >= 0),
  credits_refunded integer NOT NULL DEFAULT 0 CHECK (credits_refunded >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (designer_id, period_start)
);

CREATE TABLE IF NOT EXISTS ai_quotation_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  designer_id uuid NOT NULL REFERENCES designers(id) ON DELETE CASCADE,
  project_id uuid NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  credit_period_id uuid REFERENCES ai_credit_periods(id) ON DELETE SET NULL,
  source_file_path text NOT NULL,
  source_file_type text NOT NULL CHECK (source_file_type IN ('application/pdf','image/jpeg','image/png')),
  source_file_size bigint NOT NULL CHECK (source_file_size > 0 AND source_file_size <= 10485760),
  requirements_text text NOT NULL DEFAULT '',
  transcript text,
  pricing_profile text,
  status text NOT NULL DEFAULT 'uploaded' CHECK (status IN ('uploaded','requirements_ready','queued','analyzing_plan','understanding_requirements','matching_catalogue','calculating','review_ready','failed','cancelled','converted')),
  error_code text,
  error_message text,
  model_config jsonb NOT NULL DEFAULT '{}'::jsonb,
  provider_usage jsonb NOT NULL DEFAULT '{}'::jsonb,
  assumptions jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE IF NOT EXISTS ai_quotation_rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES ai_quotation_jobs(id) ON DELETE CASCADE,
  name text NOT NULL,
  width numeric(10,2),
  height numeric(10,2),
  unit text NOT NULL DEFAULT 'feet',
  confidence numeric(5,4) CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1)),
  source_note text,
  display_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ai_quotation_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES ai_quotation_jobs(id) ON DELETE CASCADE,
  room_id uuid REFERENCES ai_quotation_rooms(id) ON DELETE CASCADE,
  material_id uuid REFERENCES designer_material_prices(id) ON DELETE SET NULL,
  item_type text NOT NULL CHECK (item_type IN ('material','labor','service','other','component')),
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  quantity numeric(12,2) NOT NULL CHECK (quantity >= 0),
  unit text NOT NULL,
  unit_price numeric(12,2) NOT NULL CHECK (unit_price >= 0),
  number_of_units numeric(12,2) NOT NULL DEFAULT 1 CHECK (number_of_units > 0),
  discount_percent numeric(5,2) NOT NULL DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
  width numeric(12,2),
  height numeric(12,2),
  depth numeric(12,2),
  width_unit text,
  height_unit text,
  depth_unit text,
  per_sqft_rate numeric(12,2),
  confidence numeric(5,4) CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1)),
  assumption text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ai_credit_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  designer_id uuid NOT NULL REFERENCES designers(id) ON DELETE CASCADE,
  credit_period_id uuid NOT NULL REFERENCES ai_credit_periods(id) ON DELETE CASCADE,
  job_id uuid REFERENCES ai_quotation_jobs(id) ON DELETE SET NULL,
  event_type text NOT NULL CHECK (event_type IN ('grant','reserve','consume','refund','top_up','adjustment')),
  amount integer NOT NULL,
  idempotency_key text NOT NULL UNIQUE,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ai_configuration (
  id boolean PRIMARY KEY DEFAULT true CHECK (id),
  vision_model text NOT NULL DEFAULT '',
  text_model text NOT NULL DEFAULT '',
  transcription_model text NOT NULL DEFAULT '',
  routing_rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  max_file_size_bytes bigint NOT NULL DEFAULT 10485760,
  is_enabled boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id)
);

INSERT INTO ai_subscription_plans (name, description, price, monthly_credits, features, sort_order)
VALUES
  ('AI Starter', 'For occasional AI-assisted quotations.', 999, 10, '["10 AI quotation credits per month"]'::jsonb, 1),
  ('AI Professional', 'For designers creating quotations every week.', 2499, 40, '["40 AI quotation credits per month"]'::jsonb, 2),
  ('AI Business', 'For high-volume design practices.', 4999, 100, '["100 AI quotation credits per month"]'::jsonb, 3)
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description, price = EXCLUDED.price, monthly_credits = EXCLUDED.monthly_credits, features = EXCLUDED.features, updated_at = now();

INSERT INTO ai_configuration (id) VALUES (true) ON CONFLICT (id) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_ai_subscriptions_designer ON designer_ai_subscriptions (designer_id, status);
CREATE INDEX IF NOT EXISTS idx_ai_credit_periods_designer_period ON ai_credit_periods (designer_id, period_start DESC);
CREATE INDEX IF NOT EXISTS idx_ai_jobs_designer_created ON ai_quotation_jobs (designer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_jobs_status ON ai_quotation_jobs (status);
CREATE INDEX IF NOT EXISTS idx_ai_rooms_job ON ai_quotation_rooms (job_id, display_order);
CREATE INDEX IF NOT EXISTS idx_ai_items_job_room ON ai_quotation_items (job_id, room_id);
CREATE INDEX IF NOT EXISTS idx_ai_ledger_designer_created ON ai_credit_ledger (designer_id, created_at DESC);

ALTER TABLE ai_subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE designer_ai_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_credit_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_credit_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_quotation_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_quotation_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_quotation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_configuration ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "active designers read ai plans" ON ai_subscription_plans;
CREATE POLICY "active designers read ai plans" ON ai_subscription_plans FOR SELECT TO authenticated USING (is_active OR is_active_admin());
DROP POLICY IF EXISTS "admins insert ai plans" ON ai_subscription_plans;
CREATE POLICY "admins insert ai plans" ON ai_subscription_plans FOR INSERT TO authenticated WITH CHECK (is_active_admin());
DROP POLICY IF EXISTS "admins update ai plans" ON ai_subscription_plans;
CREATE POLICY "admins update ai plans" ON ai_subscription_plans FOR UPDATE TO authenticated USING (is_active_admin()) WITH CHECK (is_active_admin());
DROP POLICY IF EXISTS "admins delete ai plans" ON ai_subscription_plans;
CREATE POLICY "admins delete ai plans" ON ai_subscription_plans FOR DELETE TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "designers read own ai subscription" ON designer_ai_subscriptions;
CREATE POLICY "designers read own ai subscription" ON designer_ai_subscriptions FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM designers d WHERE d.id = designer_ai_subscriptions.designer_id AND d.user_id = auth.uid()) OR is_active_admin());
DROP POLICY IF EXISTS "admins insert ai subscription" ON designer_ai_subscriptions;
CREATE POLICY "admins insert ai subscription" ON designer_ai_subscriptions FOR INSERT TO authenticated WITH CHECK (is_active_admin());
DROP POLICY IF EXISTS "admins update ai subscription" ON designer_ai_subscriptions;
CREATE POLICY "admins update ai subscription" ON designer_ai_subscriptions FOR UPDATE TO authenticated USING (is_active_admin()) WITH CHECK (is_active_admin());
DROP POLICY IF EXISTS "admins delete ai subscription" ON designer_ai_subscriptions;
CREATE POLICY "admins delete ai subscription" ON designer_ai_subscriptions FOR DELETE TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "designers read own ai periods" ON ai_credit_periods;
CREATE POLICY "designers read own ai periods" ON ai_credit_periods FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM designers d WHERE d.id = ai_credit_periods.designer_id AND d.user_id = auth.uid()) OR is_active_admin());
DROP POLICY IF EXISTS "admins insert ai periods" ON ai_credit_periods;
CREATE POLICY "admins insert ai periods" ON ai_credit_periods FOR INSERT TO authenticated WITH CHECK (is_active_admin());
DROP POLICY IF EXISTS "admins update ai periods" ON ai_credit_periods;
CREATE POLICY "admins update ai periods" ON ai_credit_periods FOR UPDATE TO authenticated USING (is_active_admin()) WITH CHECK (is_active_admin());
DROP POLICY IF EXISTS "admins delete ai periods" ON ai_credit_periods;
CREATE POLICY "admins delete ai periods" ON ai_credit_periods FOR DELETE TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "designers read own ai ledger" ON ai_credit_ledger;
CREATE POLICY "designers read own ai ledger" ON ai_credit_ledger FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM designers d WHERE d.id = ai_credit_ledger.designer_id AND d.user_id = auth.uid()) OR is_active_admin());
DROP POLICY IF EXISTS "admins insert ai ledger" ON ai_credit_ledger;
CREATE POLICY "admins insert ai ledger" ON ai_credit_ledger FOR INSERT TO authenticated WITH CHECK (is_active_admin());
DROP POLICY IF EXISTS "admins update ai ledger" ON ai_credit_ledger;
CREATE POLICY "admins update ai ledger" ON ai_credit_ledger FOR UPDATE TO authenticated USING (is_active_admin()) WITH CHECK (is_active_admin());
DROP POLICY IF EXISTS "admins delete ai ledger" ON ai_credit_ledger;
CREATE POLICY "admins delete ai ledger" ON ai_credit_ledger FOR DELETE TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "designers read own ai jobs" ON ai_quotation_jobs;
CREATE POLICY "designers read own ai jobs" ON ai_quotation_jobs FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM designers d WHERE d.id = ai_quotation_jobs.designer_id AND d.user_id = auth.uid()) OR is_active_admin());
DROP POLICY IF EXISTS "designers insert own ai jobs" ON ai_quotation_jobs;
CREATE POLICY "designers insert own ai jobs" ON ai_quotation_jobs FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM designers d WHERE d.id = ai_quotation_jobs.designer_id AND d.user_id = auth.uid()));
DROP POLICY IF EXISTS "designers update own ai jobs" ON ai_quotation_jobs;
CREATE POLICY "designers update own ai jobs" ON ai_quotation_jobs FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM designers d WHERE d.id = ai_quotation_jobs.designer_id AND d.user_id = auth.uid()) OR is_active_admin()) WITH CHECK (EXISTS (SELECT 1 FROM designers d WHERE d.id = ai_quotation_jobs.designer_id AND d.user_id = auth.uid()) OR is_active_admin());
DROP POLICY IF EXISTS "designers delete own ai jobs" ON ai_quotation_jobs;
CREATE POLICY "designers delete own ai jobs" ON ai_quotation_jobs FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM designers d WHERE d.id = ai_quotation_jobs.designer_id AND d.user_id = auth.uid()) OR is_active_admin());

DROP POLICY IF EXISTS "designers read own ai rooms" ON ai_quotation_rooms;
CREATE POLICY "designers read own ai rooms" ON ai_quotation_rooms FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM ai_quotation_jobs j JOIN designers d ON d.id = j.designer_id WHERE j.id = ai_quotation_rooms.job_id AND d.user_id = auth.uid()) OR is_active_admin());
DROP POLICY IF EXISTS "designers insert own ai rooms" ON ai_quotation_rooms;
CREATE POLICY "designers insert own ai rooms" ON ai_quotation_rooms FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM ai_quotation_jobs j JOIN designers d ON d.id = j.designer_id WHERE j.id = ai_quotation_rooms.job_id AND d.user_id = auth.uid()));
DROP POLICY IF EXISTS "designers update own ai rooms" ON ai_quotation_rooms;
CREATE POLICY "designers update own ai rooms" ON ai_quotation_rooms FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM ai_quotation_jobs j JOIN designers d ON d.id = j.designer_id WHERE j.id = ai_quotation_rooms.job_id AND d.user_id = auth.uid()) OR is_active_admin()) WITH CHECK (EXISTS (SELECT 1 FROM ai_quotation_jobs j JOIN designers d ON d.id = j.designer_id WHERE j.id = ai_quotation_rooms.job_id AND d.user_id = auth.uid()) OR is_active_admin());
DROP POLICY IF EXISTS "designers delete own ai rooms" ON ai_quotation_rooms;
CREATE POLICY "designers delete own ai rooms" ON ai_quotation_rooms FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM ai_quotation_jobs j JOIN designers d ON d.id = j.designer_id WHERE j.id = ai_quotation_rooms.job_id AND d.user_id = auth.uid()) OR is_active_admin());

DROP POLICY IF EXISTS "designers read own ai items" ON ai_quotation_items;
CREATE POLICY "designers read own ai items" ON ai_quotation_items FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM ai_quotation_jobs j JOIN designers d ON d.id = j.designer_id WHERE j.id = ai_quotation_items.job_id AND d.user_id = auth.uid()) OR is_active_admin());
DROP POLICY IF EXISTS "designers insert own ai items" ON ai_quotation_items;
CREATE POLICY "designers insert own ai items" ON ai_quotation_items FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM ai_quotation_jobs j JOIN designers d ON d.id = j.designer_id WHERE j.id = ai_quotation_items.job_id AND d.user_id = auth.uid()));
DROP POLICY IF EXISTS "designers update own ai items" ON ai_quotation_items;
CREATE POLICY "designers update own ai items" ON ai_quotation_items FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM ai_quotation_jobs j JOIN designers d ON d.id = j.designer_id WHERE j.id = ai_quotation_items.job_id AND d.user_id = auth.uid()) OR is_active_admin()) WITH CHECK (EXISTS (SELECT 1 FROM ai_quotation_jobs j JOIN designers d ON d.id = j.designer_id WHERE j.id = ai_quotation_items.job_id AND d.user_id = auth.uid()) OR is_active_admin());
DROP POLICY IF EXISTS "designers delete own ai items" ON ai_quotation_items;
CREATE POLICY "designers delete own ai items" ON ai_quotation_items FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM ai_quotation_jobs j JOIN designers d ON d.id = j.designer_id WHERE j.id = ai_quotation_items.job_id AND d.user_id = auth.uid()) OR is_active_admin());

DROP POLICY IF EXISTS "admins read ai configuration" ON ai_configuration;
CREATE POLICY "admins read ai configuration" ON ai_configuration FOR SELECT TO authenticated USING (is_active_admin());
DROP POLICY IF EXISTS "admins insert ai configuration" ON ai_configuration;
CREATE POLICY "admins insert ai configuration" ON ai_configuration FOR INSERT TO authenticated WITH CHECK (is_active_admin());
DROP POLICY IF EXISTS "admins update ai configuration" ON ai_configuration;
CREATE POLICY "admins update ai configuration" ON ai_configuration FOR UPDATE TO authenticated USING (is_active_admin()) WITH CHECK (is_active_admin());
DROP POLICY IF EXISTS "admins delete ai configuration" ON ai_configuration;
CREATE POLICY "admins delete ai configuration" ON ai_configuration FOR DELETE TO authenticated USING (is_active_admin());

CREATE OR REPLACE FUNCTION reserve_ai_credit(p_designer_id uuid, p_job_id uuid, p_idempotency_key text)
RETURNS TABLE(credit_period_id uuid, ledger_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_period ai_credit_periods%ROWTYPE;
  v_subscription designer_ai_subscriptions%ROWTYPE;
  v_standard designer_subscriptions%ROWTYPE;
  v_ledger_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT EXISTS (SELECT 1 FROM designers WHERE id = p_designer_id AND user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT * INTO v_standard FROM designer_subscriptions WHERE designer_id = p_designer_id AND status IN ('active','trial') AND (subscription_end_date IS NULL OR subscription_end_date > now()) LIMIT 1;
  IF v_standard.id IS NULL THEN RAISE EXCEPTION 'STANDARD_SUBSCRIPTION_REQUIRED'; END IF;

  SELECT * INTO v_subscription FROM designer_ai_subscriptions WHERE designer_id = p_designer_id AND status IN ('active','trial') AND (subscription_end_date IS NULL OR subscription_end_date > now()) LIMIT 1;
  IF v_subscription.id IS NULL THEN RAISE EXCEPTION 'AI_SUBSCRIPTION_REQUIRED'; END IF;

  SELECT * INTO v_period FROM ai_credit_periods WHERE designer_id = p_designer_id AND period_start <= now() AND period_end > now() FOR UPDATE;
  IF v_period.id IS NULL THEN
    INSERT INTO ai_credit_periods (designer_id, ai_subscription_id, period_start, period_end, credits_granted)
    SELECT p_designer_id, v_subscription.id, date_trunc('month', now()), date_trunc('month', now()) + interval '1 month', monthly_credits
    FROM ai_subscription_plans WHERE id = v_subscription.ai_plan_id
    RETURNING * INTO v_period;
  END IF;

  IF EXISTS (SELECT 1 FROM ai_credit_ledger WHERE idempotency_key = p_idempotency_key) THEN
    SELECT id INTO v_ledger_id FROM ai_credit_ledger WHERE idempotency_key = p_idempotency_key;
    RETURN QUERY SELECT v_period.id, v_ledger_id;
    RETURN;
  END IF;

  IF v_period.credits_granted - v_period.credits_reserved - v_period.credits_consumed + v_period.credits_refunded < 1 THEN
    RAISE EXCEPTION 'AI_CREDITS_EXHAUSTED';
  END IF;

  UPDATE ai_credit_periods SET credits_reserved = credits_reserved + 1, updated_at = now() WHERE id = v_period.id;
  INSERT INTO ai_credit_ledger (designer_id, credit_period_id, job_id, event_type, amount, idempotency_key)
  VALUES (p_designer_id, v_period.id, p_job_id, 'reserve', -1, p_idempotency_key)
  RETURNING id INTO v_ledger_id;
  RETURN QUERY SELECT v_period.id, v_ledger_id;
END;
$$;

REVOKE ALL ON FUNCTION reserve_ai_credit(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION reserve_ai_credit(uuid, uuid, text) TO authenticated;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('ai-floor-plans', 'ai-floor-plans', false, 10485760, ARRAY['application/pdf','image/jpeg','image/png'])
ON CONFLICT (id) DO UPDATE SET public = false, file_size_limit = 10485760, allowed_mime_types = ARRAY['application/pdf','image/jpeg','image/png'];

DROP POLICY IF EXISTS "designers upload own ai floor plans" ON storage.objects;
CREATE POLICY "designers upload own ai floor plans" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'ai-floor-plans' AND (storage.foldername(name))[1] = (SELECT id::text FROM designers WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "designers read own ai floor plans" ON storage.objects;
CREATE POLICY "designers read own ai floor plans" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'ai-floor-plans' AND (storage.foldername(name))[1] = (SELECT id::text FROM designers WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "designers update own ai floor plans" ON storage.objects;
CREATE POLICY "designers update own ai floor plans" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'ai-floor-plans' AND (storage.foldername(name))[1] = (SELECT id::text FROM designers WHERE user_id = auth.uid())) WITH CHECK (bucket_id = 'ai-floor-plans' AND (storage.foldername(name))[1] = (SELECT id::text FROM designers WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "designers delete own ai floor plans" ON storage.objects;
CREATE POLICY "designers delete own ai floor plans" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'ai-floor-plans' AND (storage.foldername(name))[1] = (SELECT id::text FROM designers WHERE user_id = auth.uid()));
