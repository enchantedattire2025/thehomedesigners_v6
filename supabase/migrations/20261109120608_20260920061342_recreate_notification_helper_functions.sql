CREATE OR REPLACE FUNCTION create_notification(
  p_user_id uuid,
  p_user_type text,
  p_title text,
  p_message text,
  p_type text,
  p_reference_id uuid DEFAULT NULL,
  p_reference_type text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_notification_id uuid;
BEGIN
  INSERT INTO notifications (
    user_id,
    user_type,
    title,
    message,
    type,
    reference_id,
    reference_type
  ) VALUES (
    p_user_id,
    p_user_type,
    p_title,
    p_message,
    p_type,
    p_reference_id,
    p_reference_type
  )
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$;

CREATE OR REPLACE FUNCTION queue_email_notification(
  p_recipient_email text,
  p_recipient_name text,
  p_subject text,
  p_body text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_email_id uuid;
BEGIN
  INSERT INTO email_notifications (
    recipient_email,
    recipient_name,
    subject,
    body,
    status
  ) VALUES (
    p_recipient_email,
    p_recipient_name,
    p_subject,
    p_body,
    'pending'
  )
  RETURNING id INTO v_email_id;

  RETURN v_email_id;
END;
$$;
