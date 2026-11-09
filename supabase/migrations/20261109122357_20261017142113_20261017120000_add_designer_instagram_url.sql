/*
# Add designer Instagram URL field

Adds an optional `instagram_url` text column to `designers` so the public social wall can show each verified designer's Instagram profile link. Existing designer rows are unchanged. No policies or permissions are modified.
*/

ALTER TABLE public.designers
ADD COLUMN IF NOT EXISTS instagram_url text;
