/*
# Separate quote item pricing mode from room section

1. Modified Tables
- `quote_items`
  - New column `pricing_mode` (text, not null, default 'standard'). Values:
    - 'modular' = priced as width x height x depth x rate per sq.ft
    - 'standard' = priced as quantity x unit rate
  - Existing rows whose section was the legacy value 'modular' are marked 'modular'.

2. Why
- Until now the pricing mode was stored in the `section` column, which also holds the room name. Choosing dimension pricing moved an item out of its room.
- `section` now only holds the room name; `pricing_mode` holds how the item is priced.

3. Security
- No change to row level security or grants. The new column is covered by the existing table grants and policies.

4. Notes
- Legacy rows with section 'modular' keep that section value because their original room name was not stored.
*/

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
