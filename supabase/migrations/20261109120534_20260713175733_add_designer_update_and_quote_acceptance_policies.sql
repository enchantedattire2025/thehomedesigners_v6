-- Add missing designer UPDATE policy and has_accepted_quote helper on customers

CREATE OR REPLACE FUNCTION has_accepted_quote(p_project_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
  v_has_quote boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM designer_quotes
    WHERE project_id = p_project_id
      AND customer_accepted = true
      AND status = 'accepted'
  ) INTO v_has_quote;

  RETURN v_has_quote;
END;
$$;
GRANT EXECUTE ON FUNCTION has_accepted_quote(uuid) TO authenticated;

DROP POLICY IF EXISTS "Customers can update own projects" ON customers;
DROP POLICY IF EXISTS "Customers can update own projects before quote acceptance" ON customers;
CREATE POLICY "Customers can update own projects before quote acceptance"
  ON customers FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = user_id
    AND NOT has_accepted_quote(id)
  )
  WITH CHECK (
    auth.uid() = user_id
    AND NOT has_accepted_quote(id)
  );

DROP POLICY IF EXISTS "Designers can update assigned projects" ON customers;
DROP POLICY IF EXISTS "Designers can update assigned project status" ON customers;
CREATE POLICY "Designers can update assigned projects"
  ON customers FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM designers
      WHERE designers.user_id = auth.uid()
        AND designers.id = customers.assigned_designer_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM designers
      WHERE designers.user_id = auth.uid()
        AND designers.id = customers.assigned_designer_id
    )
  );

CREATE INDEX IF NOT EXISTS idx_designer_quotes_project_accepted
  ON designer_quotes(project_id, customer_accepted, status)
  WHERE customer_accepted = true;
