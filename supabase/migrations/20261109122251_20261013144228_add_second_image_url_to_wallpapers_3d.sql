/*
# Add second image URL to wallpapers_3d

Adds an optional `second_image_url` text column to `wallpapers_3d` so each wallpaper can store a second image. Existing rows are unchanged; the column defaults to empty.
*/

ALTER TABLE wallpapers_3d
  ADD COLUMN IF NOT EXISTS second_image_url text;
