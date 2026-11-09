ALTER TABLE quote_items
  ADD COLUMN IF NOT EXISTS pricing_mode text NOT NULL DEFAULT 'standard';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'quote_items_pricing_mode_check'
  ) THEN
    ALTER TABLE quote_items
      ADD CONSTRAINT quote_items_pricing_mode_check
      CHECK (pricing_mode IN ('modular', 'standard'));
  END IF;
END $$;

UPDATE quote_items
SET pricing_mode = 'modular'
WHERE section = 'modular' AND pricing_mode <> 'modular';
