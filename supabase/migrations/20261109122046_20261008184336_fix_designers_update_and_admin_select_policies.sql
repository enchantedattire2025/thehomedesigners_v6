/*
# Fix missing UPDATE and admin SELECT policies on designers table

The designers table had no UPDATE policy for admins, so approving a designer silently failed. This adds:
1. An UPDATE policy letting active admins update designer rows (verification approval/rejection).
2. An UPDATE policy letting verified designers edit their own row.
3. A SELECT policy letting active admins read all designers, including pending and rejected ones.

Security: admin policies use is_active_admin(). The designer UPDATE policy requires ownership and verification_status = 'verified'.
No data is changed, deleted, or dropped.
*/

DROP POLICY IF EXISTS "Admins can update designer verification status" ON public.designers;
CREATE POLICY "Admins can update designer verification status"
  ON public.designers
  FOR UPDATE
  TO authenticated
  USING (is_active_admin())
  WITH CHECK (is_active_admin());

DROP POLICY IF EXISTS "Verified designers can update own profile" ON public.designers;
CREATE POLICY "Verified designers can update own profile"
  ON public.designers
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    AND verification_status = 'verified'
  )
  WITH CHECK (
    user_id = auth.uid()
    AND verification_status = 'verified'
  );

DROP POLICY IF EXISTS "Admins can view all designers" ON public.designers;
CREATE POLICY "Admins can view all designers"
  ON public.designers
  FOR SELECT
  TO authenticated
  USING (is_active_admin());
