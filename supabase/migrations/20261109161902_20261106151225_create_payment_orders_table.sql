CREATE TABLE IF NOT EXISTS public.payment_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purpose text NOT NULL CHECK (purpose IN ('designer_subscription','ai_subscription','wallpaper_order','quote_advance')),
  reference_id uuid NOT NULL,
  payer_user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  designer_id uuid,
  base_amount numeric(12,2) NOT NULL CHECK (base_amount > 0),
  fee_amount numeric(12,2) NOT NULL DEFAULT 0 CHECK (fee_amount >= 0),
  total_amount numeric(12,2) NOT NULL CHECK (total_amount > 0),
  currency text NOT NULL DEFAULT 'INR',
  method text NOT NULL CHECK (method IN ('razorpay','upi')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','awaiting_review','paid','rejected','failed')),
  razorpay_order_id text UNIQUE,
  razorpay_payment_id text UNIQUE,
  upi_transaction_id text,
  upi_screenshot_path text,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  review_note text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  paid_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS payment_orders_active_upi_txn_idx
  ON public.payment_orders (upi_transaction_id)
  WHERE method = 'upi' AND status <> 'rejected' AND upi_transaction_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS payment_orders_payer_idx ON public.payment_orders (payer_user_id);
CREATE INDEX IF NOT EXISTS payment_orders_status_idx ON public.payment_orders (status, created_at DESC);
CREATE INDEX IF NOT EXISTS payment_orders_reference_idx ON public.payment_orders (purpose, reference_id);

ALTER TABLE public.payment_orders ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.payment_orders FROM PUBLIC, anon;
GRANT SELECT ON public.payment_orders TO authenticated;
GRANT ALL ON public.payment_orders TO service_role;

DROP POLICY IF EXISTS "select_own_payment_orders" ON public.payment_orders;
CREATE POLICY "select_own_payment_orders" ON public.payment_orders FOR SELECT
  TO authenticated USING (auth.uid() = payer_user_id);

DROP POLICY IF EXISTS "admin_select_payment_orders" ON public.payment_orders;
CREATE POLICY "admin_select_payment_orders" ON public.payment_orders FOR SELECT
  TO authenticated USING (public.is_active_admin());
