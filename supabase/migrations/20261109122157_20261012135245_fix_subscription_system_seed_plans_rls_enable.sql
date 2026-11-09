/*
# Fix subscription system: seed plans, add RLS policies, enable management

Seeds the Professional Standard plan, enables the subscription management site setting, and adds RLS policies for subscription_plans, designer_subscriptions and designer_ai_subscriptions so designers can read and manage their own rows. Admins keep override access. No data is deleted.
*/

INSERT INTO subscription_plans (name, description, price, billing_period, features, max_projects, max_quotes, priority_support, is_active, sort_order)
VALUES (
  'Professional',
  'Full access to manual, template and modular quotation tools with priority support.',
  2000,
  'monthly',
  '["Up to 15 concurrent projects","60 quotes per quarter","Premium portfolio showcase","Priority email support","Analytics dashboard"]'::jsonb,
  15,
  60,
  true,
  true,
  1
)
ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description,
  price = EXCLUDED.price,
  billing_period = EXCLUDED.billing_period,
  features = EXCLUDED.features,
  max_projects = EXCLUDED.max_projects,
  max_quotes = EXCLUDED.max_quotes,
  priority_support = EXCLUDED.priority_support,
  is_active = EXCLUDED.is_active,
  sort_order = EXCLUDED.sort_order,
  updated_at = now();

UPDATE site_settings
SET is_active = true, updated_at = now()
WHERE setting_key = 'subscription_management_enabled';

INSERT INTO site_settings (setting_key, is_active)
SELECT 'subscription_management_enabled', true
WHERE NOT EXISTS (
  SELECT 1 FROM site_settings WHERE setting_key = 'subscription_management_enabled'
);

DROP POLICY IF EXISTS "authenticated read subscription plans" ON subscription_plans;
CREATE POLICY "authenticated read subscription plans"
ON subscription_plans FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "admins insert subscription plans" ON subscription_plans;
CREATE POLICY "admins insert subscription plans"
ON subscription_plans FOR INSERT
TO authenticated
WITH CHECK (is_active_admin());

DROP POLICY IF EXISTS "admins update subscription plans" ON subscription_plans;
CREATE POLICY "admins update subscription plans"
ON subscription_plans FOR UPDATE
TO authenticated
USING (is_active_admin())
WITH CHECK (is_active_admin());

DROP POLICY IF EXISTS "admins delete subscription plans" ON subscription_plans;
CREATE POLICY "admins delete subscription plans"
ON subscription_plans FOR DELETE
TO authenticated
USING (is_active_admin());

DROP POLICY IF EXISTS "designers read own subscription" ON designer_subscriptions;
CREATE POLICY "designers read own subscription"
ON designer_subscriptions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM designers d
    WHERE d.id = designer_subscriptions.designer_id
    AND d.user_id = auth.uid()
  ) OR is_active_admin()
);

DROP POLICY IF EXISTS "designers insert own subscription" ON designer_subscriptions;
CREATE POLICY "designers insert own subscription"
ON designer_subscriptions FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM designers d
    WHERE d.id = designer_subscriptions.designer_id
    AND d.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "designers update own subscription" ON designer_subscriptions;
CREATE POLICY "designers update own subscription"
ON designer_subscriptions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM designers d
    WHERE d.id = designer_subscriptions.designer_id
    AND d.user_id = auth.uid()
  ) OR is_active_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM designers d
    WHERE d.id = designer_subscriptions.designer_id
    AND d.user_id = auth.uid()
  ) OR is_active_admin()
);

DROP POLICY IF EXISTS "admins delete designer subscriptions" ON designer_subscriptions;
CREATE POLICY "admins delete designer subscriptions"
ON designer_subscriptions FOR DELETE
TO authenticated
USING (is_active_admin());

DROP POLICY IF EXISTS "designers insert own ai subscription" ON designer_ai_subscriptions;
CREATE POLICY "designers insert own ai subscription"
ON designer_ai_subscriptions FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM designers d
    WHERE d.id = designer_ai_subscriptions.designer_id
    AND d.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "designers update own ai subscription" ON designer_ai_subscriptions;
CREATE POLICY "designers update own ai subscription"
ON designer_ai_subscriptions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM designers d
    WHERE d.id = designer_ai_subscriptions.designer_id
    AND d.user_id = auth.uid()
  ) OR is_active_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM designers d
    WHERE d.id = designer_ai_subscriptions.designer_id
    AND d.user_id = auth.uid()
  ) OR is_active_admin()
);
