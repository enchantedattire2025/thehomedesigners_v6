/*
# Restore designer and customer RLS policies on designer_quotes and quote_items

1. designer_quotes: designers can view, create, update, and delete their own quotes. Customers can view quotes sent to their projects.
2. quote_items: designers can update and delete items belonging to their own quotes.

Each policy is dropped first if it already exists, so re-running is safe. No rows or columns are changed.
*/

DROP POLICY IF EXISTS "Designers can view their own quotes" ON designer_quotes;
CREATE POLICY "Designers can view their own quotes"
  ON designer_quotes FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM designers
      WHERE designers.id = designer_quotes.designer_id
      AND designers.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Customers can view quotes for their projects" ON designer_quotes;
CREATE POLICY "Customers can view quotes for their projects"
  ON designer_quotes FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM customers
      WHERE customers.id = designer_quotes.project_id
      AND customers.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Designers can insert their own quotes" ON designer_quotes;
CREATE POLICY "Designers can insert their own quotes"
  ON designer_quotes FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM designers
      WHERE designers.id = designer_quotes.designer_id
      AND designers.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Designers can update their own quotes" ON designer_quotes;
CREATE POLICY "Designers can update their own quotes"
  ON designer_quotes FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM designers
      WHERE designers.id = designer_quotes.designer_id
      AND designers.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM designers
      WHERE designers.id = designer_quotes.designer_id
      AND designers.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Designers can delete their own quotes" ON designer_quotes;
CREATE POLICY "Designers can delete their own quotes"
  ON designer_quotes FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM designers
      WHERE designers.id = designer_quotes.designer_id
      AND designers.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Designers can update their own quote items" ON quote_items;
CREATE POLICY "Designers can update their own quote items"
  ON quote_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM designer_quotes
      JOIN designers ON designers.id = designer_quotes.designer_id
      WHERE designer_quotes.id = quote_items.quote_id
      AND designers.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM designer_quotes
      JOIN designers ON designers.id = designer_quotes.designer_id
      WHERE designer_quotes.id = quote_items.quote_id
      AND designers.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Designers can delete their own quote items" ON quote_items;
CREATE POLICY "Designers can delete their own quote items"
  ON quote_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM designer_quotes
      JOIN designers ON designers.id = designer_quotes.designer_id
      WHERE designer_quotes.id = quote_items.quote_id
      AND designers.user_id = auth.uid()
    )
  );
