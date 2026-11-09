/*
# Create audit logs table and enable admin read access on monitoring tables

1. Creates the `audit_logs` table for recording authorized administrative interventions.
2. Enables RLS on `audit_logs`: admins can read and insert, designers can read logs where they are the target.
3. Adds admin SELECT-only policies on monitoring tables (projects, quotes, earnings, subscriptions, AI quotation tables).

Security: no admin INSERT/UPDATE/DELETE on monitoring tables. No existing designer or customer policies are modified. Nothing is deleted.
*/

CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action text NOT NULL,
  target_type text NOT NULL,
  target_id uuid,
  target_user_id uuid,
  details jsonb DEFAULT '{}'::jsonb,
  ip_address text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT ON audit_logs TO authenticated;

DROP POLICY IF EXISTS "admins read audit logs" ON audit_logs;
CREATE POLICY "admins read audit logs"
ON audit_logs FOR SELECT
TO authenticated
USING (is_active_admin());

DROP POLICY IF EXISTS "admins insert audit logs" ON audit_logs;
CREATE POLICY "admins insert audit logs"
ON audit_logs FOR INSERT
TO authenticated
WITH CHECK (is_active_admin());

DROP POLICY IF EXISTS "designers read own audit logs" ON audit_logs;
CREATE POLICY "designers read own audit logs"
ON audit_logs FOR SELECT
TO authenticated
USING (target_user_id = auth.uid());

DROP POLICY IF EXISTS "admins read projects" ON design_projects;
CREATE POLICY "admins read projects" ON design_projects FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read quotes" ON designer_quotes;
CREATE POLICY "admins read quotes" ON designer_quotes FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read quote items" ON quote_items;
CREATE POLICY "admins read quote items" ON quote_items FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read project assignments" ON project_assignments;
CREATE POLICY "admins read project assignments" ON project_assignments FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read project activities" ON project_activities;
CREATE POLICY "admins read project activities" ON project_activities FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read project updates" ON project_updates;
CREATE POLICY "admins read project updates" ON project_updates FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read project versions" ON project_versions;
CREATE POLICY "admins read project versions" ON project_versions FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read project images" ON project_images;
CREATE POLICY "admins read project images" ON project_images FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read earnings" ON designer_projects_earnings;
CREATE POLICY "admins read earnings" ON designer_projects_earnings FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read subscription payments" ON subscription_payments;
CREATE POLICY "admins read subscription payments" ON subscription_payments FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read usage tracking" ON subscription_usage_tracking;
CREATE POLICY "admins read usage tracking" ON subscription_usage_tracking FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read ai quotation rooms" ON ai_quotation_rooms;
CREATE POLICY "admins read ai quotation rooms" ON ai_quotation_rooms FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read ai quotation items" ON ai_quotation_items;
CREATE POLICY "admins read ai quotation items" ON ai_quotation_items FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read ai quotation jobs" ON ai_quotation_jobs;
CREATE POLICY "admins read ai quotation jobs" ON ai_quotation_jobs FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read ai credit periods" ON ai_credit_periods;
CREATE POLICY "admins read ai credit periods" ON ai_credit_periods FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read designer ai subscriptions" ON designer_ai_subscriptions;
CREATE POLICY "admins read designer ai subscriptions" ON designer_ai_subscriptions FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read designer subscriptions" ON designer_subscriptions;
CREATE POLICY "admins read designer subscriptions" ON designer_subscriptions FOR SELECT TO authenticated USING (is_active_admin());

DROP POLICY IF EXISTS "admins read quote acceptance history" ON quote_acceptance_history;
CREATE POLICY "admins read quote acceptance history" ON quote_acceptance_history FOR SELECT TO authenticated USING (is_active_admin());

CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_target_user_id ON audit_logs (target_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs (action);
