DROP POLICY IF EXISTS "Public can read active designers" ON designers;
CREATE POLICY "Public can read active designers"
  ON designers FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

DROP POLICY IF EXISTS "Public can view completed projects" ON customers;
CREATE POLICY "Public can view completed projects"
  ON customers FOR SELECT
  TO anon, authenticated
  USING (assignment_status = 'completed');
