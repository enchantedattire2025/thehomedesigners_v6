-- Restore customers RLS policies (policy section only)
-- Helper functions are defined by a later migration (20260717185308) and already exist live.

DROP POLICY IF EXISTS "Customers can read own projects" ON customers;
CREATE POLICY "Customers can read own projects"
  ON customers FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Customers can insert own projects" ON customers;
CREATE POLICY "Customers can insert own projects"
  ON customers FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Customers can update own projects" ON customers;
CREATE POLICY "Customers can update own projects"
  ON customers FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Customers can delete own projects" ON customers;
CREATE POLICY "Customers can delete own projects"
  ON customers FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Designers can view assigned projects" ON customers;
CREATE POLICY "Designers can view assigned projects"
  ON customers FOR SELECT
  TO authenticated
  USING (is_assigned_designer(id));

DROP POLICY IF EXISTS "Designers can view customer projects" ON customers;
CREATE POLICY "Designers can view customer projects"
  ON customers FOR SELECT
  TO authenticated
  USING (has_project_share_access(id));

DROP POLICY IF EXISTS "Admins can view all customers" ON customers;
CREATE POLICY "Admins can view all customers"
  ON customers FOR SELECT
  TO authenticated
  USING (is_active_admin());
