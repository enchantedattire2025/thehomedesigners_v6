DO $$
DECLARE
  v_def text;
BEGIN
  v_def := pg_get_functiondef('public.decide_community_join_request(uuid, text, text)'::regprocedure);
  v_def := replace(v_def, 'section, width_unit, height_unit', 'section, pricing_mode, width_unit, height_unit');
  v_def := replace(v_def, 'i.section, i.width_unit, i.height_unit', 'i.section, i.pricing_mode, i.width_unit, i.height_unit');
  EXECUTE v_def;
END $$;
