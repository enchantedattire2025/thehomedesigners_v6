/*
# Create accepted-quote designer contact function

Adds get_accepted_quote_designer_contact, a server-side function that returns a designer's name, phone, email, location, profile image, and specialization only when the calling customer owns the quote, the quote is accepted, and the customer has accepted it. Anonymous callers cannot run it. No tables are changed.
*/

CREATE OR REPLACE FUNCTION get_accepted_quote_designer_contact(p_quote_id uuid)
RETURNS TABLE(
  designer_name text,
  designer_phone text,
  designer_email text,
  designer_location text,
  designer_profile_image text,
  designer_specialization text
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.name,
    d.phone,
    d.email,
    d.location,
    d.profile_image,
    d.specialization
  FROM designer_quotes q
  JOIN designers d ON d.id = q.designer_id
  JOIN customers c ON c.id = q.project_id
  WHERE q.id = p_quote_id
    AND c.user_id = auth.uid()
    AND q.status = 'accepted'
    AND q.customer_accepted = true;
END;
$$;

REVOKE EXECUTE ON FUNCTION get_accepted_quote_designer_contact(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_accepted_quote_designer_contact(uuid) TO authenticated;
