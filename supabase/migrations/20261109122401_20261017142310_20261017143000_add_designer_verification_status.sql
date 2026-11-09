/*
# Add designer verification status field

1. Adds `verification_status` to `designers` with values pending, verified, or rejected. New records default to pending.
2. Existing designers whose legacy is_verified flag is true are marked verified; others stay pending.
3. Adds an index on verification_status.

Additive only. No rows are deleted and no policies or permissions are changed.
*/

ALTER TABLE public.designers
ADD COLUMN IF NOT EXISTS verification_status text NOT NULL DEFAULT 'pending';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'designers_verification_status_check'
      AND conrelid = 'public.designers'::regclass
  ) THEN
    ALTER TABLE public.designers
      ADD CONSTRAINT designers_verification_status_check
      CHECK (verification_status IN ('pending', 'verified', 'rejected'));
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'designers'
      AND column_name = 'is_verified'
  ) THEN
    UPDATE public.designers
    SET verification_status = CASE WHEN is_verified = true THEN 'verified' ELSE 'pending' END
    WHERE verification_status = 'pending';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_designers_verification_status
  ON public.designers (verification_status);
