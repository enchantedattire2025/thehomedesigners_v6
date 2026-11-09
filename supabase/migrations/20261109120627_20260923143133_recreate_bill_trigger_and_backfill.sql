CREATE OR REPLACE FUNCTION create_bill_from_accepted_quote()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_bill_id uuid;
  v_bill_number text;
BEGIN
  IF NEW.customer_accepted = true AND (OLD.customer_accepted = false OR OLD.customer_accepted IS NULL) THEN
    IF EXISTS (SELECT 1 FROM project_bills WHERE quote_id = NEW.id) THEN
      RETURN NEW;
    END IF;

    v_bill_number := 'BILL-' || to_char(now(), 'YYYYMMDD') || '-' || substr(gen_random_uuid()::text, 1, 6);

    INSERT INTO project_bills (
      id, project_id, quote_id, designer_id, bill_number,
      subtotal, discount_amount, tax_rate, tax_amount, total_amount,
      status, notes
    ) VALUES (
      gen_random_uuid(), NEW.project_id, NEW.id, NEW.designer_id, v_bill_number,
      NEW.subtotal, NEW.discount_amount, NEW.tax_rate, NEW.tax_amount, NEW.total_amount,
      'draft', ''
    ) RETURNING id INTO v_bill_id;

    INSERT INTO bill_items (
      bill_id, item_type, name, description, number_of_units,
      quantity, unit, unit_price, discount_percent, amount,
      length, breadth
    )
    SELECT
      v_bill_id, item_type, name, description, number_of_units,
      quantity, unit, unit_price, discount_percent, amount,
      length, breadth
    FROM quote_items
    WHERE quote_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_create_bill_on_quote_acceptance ON designer_quotes;
CREATE TRIGGER trigger_create_bill_on_quote_acceptance
  AFTER UPDATE ON designer_quotes
  FOR EACH ROW
  EXECUTE FUNCTION create_bill_from_accepted_quote();

DO $$
DECLARE
  q RECORD;
  v_bill_id uuid;
  v_bill_number text;
BEGIN
  FOR q IN
    SELECT dq.id, dq.project_id, dq.designer_id, dq.subtotal, dq.discount_amount,
           dq.tax_rate, dq.tax_amount, dq.total_amount
    FROM designer_quotes dq
    WHERE dq.customer_accepted = true
      AND dq.status = 'accepted'
      AND NOT EXISTS (SELECT 1 FROM project_bills pb WHERE pb.quote_id = dq.id)
  LOOP
    v_bill_number := 'BILL-' || to_char(now(), 'YYYYMMDD') || '-' || substr(gen_random_uuid()::text, 1, 6);

    INSERT INTO project_bills (
      id, project_id, quote_id, designer_id, bill_number,
      subtotal, discount_amount, tax_rate, tax_amount, total_amount,
      status, notes
    ) VALUES (
      gen_random_uuid(), q.project_id, q.id, q.designer_id, v_bill_number,
      q.subtotal, q.discount_amount, q.tax_rate, q.tax_amount, q.total_amount,
      'draft', ''
    ) RETURNING id INTO v_bill_id;

    INSERT INTO bill_items (
      bill_id, item_type, name, description, number_of_units,
      quantity, unit, unit_price, discount_percent, amount,
      length, breadth
    )
    SELECT
      v_bill_id, item_type, name, description, number_of_units,
      quantity, unit, unit_price, discount_percent, amount,
      length, breadth
    FROM quote_items
    WHERE quote_id = q.id;
  END LOOP;
END;
$$;
