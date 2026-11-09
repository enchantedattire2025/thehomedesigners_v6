CREATE OR REPLACE FUNCTION notify_on_quotation_rejected()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_designer_email text;
  v_designer_name text;
  v_customer_name text;
  v_project_name text;
  v_customer_id uuid;
  v_designer_user_id uuid;
BEGIN
  IF NEW.status = 'rejected' AND (OLD.status IS NULL OR OLD.status != 'rejected') THEN

    SELECT c.user_id, c.project_name
    INTO v_customer_id, v_project_name
    FROM customers c
    WHERE c.id = NEW.project_id;

    SELECT COALESCE(raw_user_meta_data->>'full_name', email)
    INTO v_customer_name
    FROM auth.users
    WHERE id = v_customer_id;

    SELECT d.user_id, d.email, d.name
    INTO v_designer_user_id, v_designer_email, v_designer_name
    FROM designers d
    WHERE d.id = NEW.designer_id;

    PERFORM create_notification(
      v_designer_user_id,
      'designer',
      'Quotation Rejected',
      v_customer_name || ' has rejected your quotation for project "' || v_project_name || '".' ||
      COALESCE(' Customer feedback: ' || NEW.customer_feedback, ''),
      'quotation_rejected',
      NEW.id,
      'quotation'
    );

    PERFORM queue_email_notification(
      v_designer_email,
      v_designer_name,
      'Quotation Rejected - ' || v_project_name,
      'Dear ' || v_designer_name || ',

' || v_customer_name || ' has rejected your quotation for the project "' || v_project_name || '".

' || COALESCE('Customer feedback: ' || NEW.customer_feedback, 'No feedback was provided.') || '

You can review the quotation details and submit a revised quote if needed.

Best regards,
The Home Designers Team'
    );

  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_notify_on_quotation_rejected ON designer_quotes;
CREATE TRIGGER trigger_notify_on_quotation_rejected
AFTER UPDATE ON designer_quotes
FOR EACH ROW
EXECUTE FUNCTION notify_on_quotation_rejected();
