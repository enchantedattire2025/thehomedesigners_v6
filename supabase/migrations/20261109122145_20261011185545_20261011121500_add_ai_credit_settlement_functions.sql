/*
# Add AI credit settlement functions

Adds settle_ai_credit (converts one reservation into one consumed credit) and refund_ai_credit (releases one reservation after an eligible failed job). Both are idempotent through the ledger idempotency key and require the calling designer to own the job. Anonymous execution is revoked. No existing data is changed.
*/

CREATE OR REPLACE FUNCTION settle_ai_credit(p_job_id uuid, p_idempotency_key text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job ai_quotation_jobs%ROWTYPE;
  v_period ai_credit_periods%ROWTYPE;
BEGIN
  SELECT j.* INTO v_job
  FROM ai_quotation_jobs j
  JOIN designers d ON d.id = j.designer_id
  WHERE j.id = p_job_id AND d.user_id = auth.uid();
  IF v_job.id IS NULL THEN RAISE EXCEPTION 'Not authorized'; END IF;

  IF EXISTS (SELECT 1 FROM ai_credit_ledger WHERE idempotency_key = p_idempotency_key) THEN RETURN; END IF;
  SELECT * INTO v_period FROM ai_credit_periods WHERE id = v_job.credit_period_id FOR UPDATE;
  IF v_period.id IS NULL THEN RAISE EXCEPTION 'Credit period not found'; END IF;
  IF v_period.credits_reserved < 1 THEN RAISE EXCEPTION 'Credit reservation not found'; END IF;

  UPDATE ai_credit_periods SET credits_reserved = credits_reserved - 1, credits_consumed = credits_consumed + 1, updated_at = now() WHERE id = v_period.id;
  INSERT INTO ai_credit_ledger (designer_id, credit_period_id, job_id, event_type, amount, idempotency_key)
  VALUES (v_job.designer_id, v_period.id, p_job_id, 'consume', -1, p_idempotency_key);
END;
$$;

CREATE OR REPLACE FUNCTION refund_ai_credit(p_job_id uuid, p_idempotency_key text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_job ai_quotation_jobs%ROWTYPE;
  v_period ai_credit_periods%ROWTYPE;
BEGIN
  SELECT j.* INTO v_job
  FROM ai_quotation_jobs j
  JOIN designers d ON d.id = j.designer_id
  WHERE j.id = p_job_id AND d.user_id = auth.uid();
  IF v_job.id IS NULL THEN RAISE EXCEPTION 'Not authorized'; END IF;

  IF EXISTS (SELECT 1 FROM ai_credit_ledger WHERE idempotency_key = p_idempotency_key) THEN RETURN; END IF;
  SELECT * INTO v_period FROM ai_credit_periods WHERE id = v_job.credit_period_id FOR UPDATE;
  IF v_period.id IS NULL THEN RAISE EXCEPTION 'Credit period not found'; END IF;
  IF v_period.credits_reserved < 1 THEN RAISE EXCEPTION 'Credit reservation not found'; END IF;

  UPDATE ai_credit_periods SET credits_reserved = credits_reserved - 1, credits_refunded = credits_refunded + 1, updated_at = now() WHERE id = v_period.id;
  INSERT INTO ai_credit_ledger (designer_id, credit_period_id, job_id, event_type, amount, idempotency_key)
  VALUES (v_job.designer_id, v_period.id, p_job_id, 'refund', 1, p_idempotency_key);
END;
$$;

REVOKE ALL ON FUNCTION settle_ai_credit(uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION refund_ai_credit(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION settle_ai_credit(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION refund_ai_credit(uuid, text) TO authenticated;
