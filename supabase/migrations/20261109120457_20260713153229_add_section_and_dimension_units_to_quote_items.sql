/*
  # Add Section + Per-Dimension Units to quote_items

  ## Summary
  Extends quote_items to support two distinct sections in a quotation:
  - "On-Site Work" — existing behavior (materials selected from material list).
  - "Modular Work" — custom items (e.g. kitchen lower cabinets) described by
    width x height x depth, each in a chosen unit (mm / inch / feet), and
    priced per square foot.

  ## Notes
  - All new columns are nullable (except section, which defaults to 'on_site')
    so existing on-site rows remain valid without changes.
  - No existing columns are dropped or type-changed — no data loss.
*/

ALTER TABLE quote_items
  ADD COLUMN IF NOT EXISTS section text NOT NULL DEFAULT 'on_site';

ALTER TABLE quote_items
  ADD COLUMN IF NOT EXISTS width_unit text;

ALTER TABLE quote_items
  ADD COLUMN IF NOT EXISTS height_unit text;

ALTER TABLE quote_items
  ADD COLUMN IF NOT EXISTS depth_unit text;

ALTER TABLE quote_items
  ADD COLUMN IF NOT EXISTS area_sqft numeric(12,2);

ALTER TABLE quote_items
  ADD COLUMN IF NOT EXISTS per_sqft_rate numeric(12,2);
