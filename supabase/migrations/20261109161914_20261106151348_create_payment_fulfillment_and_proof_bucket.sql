CREATE OR REPLACE FUNCTION public.fulfill_payment_order(
  p_payment_order_id uuid,
  p_razorpay_payment_id text DEFAULT NULL,
  p_provider_response jsonb DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_order public.payment_orders%ROWTYPE;
  v_plan_price numeric;
  v_plan_name text;
  v_plan_billing text;
  v_monthly_credits integer;
  v_designer_sub_id uuid;
  v_ai_sub_id uuid;
  v_start timestamptz := now();
  v_end timestamptz := now() + interval '1 month';
BEGIN
  SELECT * INTO v_order FROM public.payment_orders WHERE id = p_payment_order_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment order not found.';
  END IF;

  IF v_order.status = 'paid' THEN
    RETURN;
  END IF;

  UPDATE public.payment_orders
  SET status = 'paid',
      razorpay_payment_id = COALESCE(p_razorpay_payment_id, razorpay_payment_id),
      paid_at = now(),
      updated_at = now(),
      metadata = CASE WHEN p_provider_response IS NULL THEN metadata
                      ELSE metadata || jsonb_build_object('provider_response', p_provider_response) END
  WHERE id = v_order.id;

  IF v_order.purpose = 'designer_subscription' THEN
    SELECT price, name, billing_period INTO v_plan_price, v_plan_name, v_plan_billing
    FROM public.subscription_plans WHERE id = v_order.reference_id;

    SELECT id INTO v_designer_sub_id FROM public.designer_subscriptions
    WHERE designer_id = v_order.designer_id LIMIT 1;

    IF v_designer_sub_id IS NULL THEN
      INSERT INTO public.designer_subscriptions
        (designer_id, subscription_plan_id, status, subscription_start_date, subscription_end_date,
         trial_start_date, trial_end_date, auto_renew)
      VALUES
        (v_order.designer_id, v_order.reference_id, 'active', v_start, v_end,
         v_start, v_start, true)
      RETURNING id INTO v_designer_sub_id;
    ELSE
      UPDATE public.designer_subscriptions
      SET subscription_plan_id = v_order.reference_id,
          status = 'active',
          subscription_start_date = v_start,
          subscription_end_date = v_end,
          updated_at = now()
      WHERE id = v_designer_sub_id;
    END IF;

    INSERT INTO public.subscription_payments
      (designer_subscription_id, amount, currency, payment_method, payment_gateway, transaction_id,
       payment_status, payment_date, billing_period_start, billing_period_end, metadata)
    VALUES
      (v_designer_sub_id, v_order.base_amount, v_order.currency,
       CASE WHEN v_order.method = 'upi' THEN 'upi' ELSE 'razorpay' END,
       v_order.method,
       COALESCE(p_razorpay_payment_id, v_order.upi_transaction_id, v_order.id::text),
       'completed', now(), v_start, v_end,
       jsonb_build_object('payment_order_id', v_order.id, 'plan_name', v_plan_name,
                          'billing_period', v_plan_billing, 'fee_amount', v_order.fee_amount,
                          'total_amount', v_order.total_amount));

  ELSIF v_order.purpose = 'ai_subscription' THEN
    SELECT monthly_credits INTO v_monthly_credits
    FROM public.ai_subscription_plans WHERE id = v_order.reference_id;

    SELECT id INTO v_ai_sub_id FROM public.designer_ai_subscriptions
    WHERE designer_id = v_order.designer_id LIMIT 1;

    IF v_ai_sub_id IS NULL THEN
      INSERT INTO public.designer_ai_subscriptions
        (designer_id, ai_plan_id, status, subscription_start_date, subscription_end_date, auto_renew, payment_provider)
      VALUES
        (v_order.designer_id, v_order.reference_id, 'active', v_start, v_end, true, v_order.method)
      RETURNING id INTO v_ai_sub_id;
    ELSE
      UPDATE public.designer_ai_subscriptions
      SET ai_plan_id = v_order.reference_id,
          status = 'active',
          subscription_start_date = v_start,
          subscription_end_date = v_end,
          payment_provider = v_order.method,
          updated_at = now()
      WHERE id = v_ai_sub_id;
    END IF;

    INSERT INTO public.ai_credit_periods
      (designer_id, ai_subscription_id, period_start, period_end,
       credits_granted, credits_reserved, credits_consumed, credits_refunded)
    VALUES
      (v_order.designer_id, v_ai_sub_id, v_start, v_end, COALESCE(v_monthly_credits, 0), 0, 0, 0);

  ELSIF v_order.purpose = 'wallpaper_order' THEN
    UPDATE public.wallpaper_orders
    SET payment_status = 'completed',
        payment_method = v_order.method
    WHERE id = v_order.reference_id;

  ELSIF v_order.purpose = 'quote_advance' THEN
    PERFORM public.record_quote_payment(
      v_order.reference_id,
      v_order.razorpay_order_id,
      COALESCE(p_razorpay_payment_id, v_order.razorpay_payment_id),
      v_order.base_amount,
      p_provider_response
    );
  END IF;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.fulfill_payment_order(uuid, text, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.fulfill_payment_order(uuid, text, jsonb) TO service_role;

INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-proofs', 'payment-proofs', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "users_upload_own_payment_proofs" ON storage.objects;
CREATE POLICY "users_upload_own_payment_proofs" ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'payment-proofs' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "users_read_own_payment_proofs" ON storage.objects;
CREATE POLICY "users_read_own_payment_proofs" ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'payment-proofs' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "admins_read_payment_proofs" ON storage.objects;
CREATE POLICY "admins_read_payment_proofs" ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'payment-proofs' AND public.is_active_admin());
