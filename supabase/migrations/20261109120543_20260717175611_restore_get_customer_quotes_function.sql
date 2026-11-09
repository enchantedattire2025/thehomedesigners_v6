DROP FUNCTION IF EXISTS get_customer_quotes(uuid);

CREATE FUNCTION get_customer_quotes(customer_user_id uuid DEFAULT auth.uid())
RETURNS TABLE (
  id uuid,
  designer_id uuid,
  project_id uuid,
  quote_number text,
  title text,
  description text,
  subtotal numeric,
  discount_amount numeric,
  tax_rate numeric,
  tax_amount numeric,
  total_amount numeric,
  status text,
  valid_until date,
  terms_and_conditions text,
  notes text,
  created_at timestamptz,
  updated_at timestamptz,
  customer_accepted boolean,
  acceptance_date timestamptz,
  customer_feedback text,
  notification_sent boolean,
  quotation_file_url text,
  payment_receipt_url text,
  design_image_url text,
  customer_name text,
  customer_email text,
  customer_phone text,
  project_name text,
  assigned_designer_id uuid,
  designer_name text,
  designer_email text,
  designer_phone text,
  designer_profile_image text,
  designer_specialization text,
  items json
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT
    q.id,
    q.designer_id,
    q.project_id,
    q.quote_number,
    q.title,
    q.description,
    q.subtotal,
    q.discount_amount,
    q.tax_rate,
    q.tax_amount,
    q.total_amount,
    q.status,
    q.valid_until,
    q.terms_and_conditions,
    q.notes,
    q.created_at,
    q.updated_at,
    q.customer_accepted,
    q.acceptance_date,
    q.customer_feedback,
    q.notification_sent,
    q.quotation_file_url,
    q.payment_receipt_url,
    q.design_image_url,
    c.name as customer_name,
    c.email as customer_email,
    c.phone as customer_phone,
    c.project_name,
    c.assigned_designer_id,
    d.name as designer_name,
    d.email as designer_email,
    d.phone as designer_phone,
    d.profile_image as designer_profile_image,
    d.specialization as designer_specialization,
    (
      SELECT json_agg(i.*)
      FROM quote_items i
      WHERE i.quote_id = q.id
    ) as items
  FROM designer_quotes q
  JOIN customers c ON c.id = q.project_id
  JOIN designers d ON d.id = q.designer_id
  WHERE c.user_id = customer_user_id
  ORDER BY q.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_customer_quotes(uuid) TO authenticated;
