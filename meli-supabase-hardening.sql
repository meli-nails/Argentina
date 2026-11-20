-- Meli Nails: database hardening applied to project vfkalbukfiyprugqepcy
-- Safe to keep as a record of the changes. The statements below reflect the final state.

-- Replace broad admin ALL policies with command-specific policies.
DROP POLICY IF EXISTS services_admin_all ON public.services;
DROP POLICY IF EXISTS designs_admin_all ON public.designs;
DROP POLICY IF EXISTS reviews_admin_all ON public.reviews;
DROP POLICY IF EXISTS hours_admin_all ON public.working_hours;

DROP POLICY IF EXISTS services_public_read ON public.services;
CREATE POLICY services_public_read ON public.services
  FOR SELECT TO anon, authenticated
  USING ((is_active AND NOT is_sample) OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS designs_public_read ON public.designs;
CREATE POLICY designs_public_read ON public.designs
  FOR SELECT TO anon, authenticated
  USING ((is_available AND NOT is_sample) OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS reviews_public_read ON public.reviews;
CREATE POLICY reviews_public_read ON public.reviews
  FOR SELECT TO anon, authenticated
  USING (is_published OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS services_admin_insert ON public.services;
DROP POLICY IF EXISTS services_admin_update ON public.services;
DROP POLICY IF EXISTS services_admin_delete ON public.services;
CREATE POLICY services_admin_insert ON public.services FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY services_admin_update ON public.services FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY services_admin_delete ON public.services FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS designs_admin_insert ON public.designs;
DROP POLICY IF EXISTS designs_admin_update ON public.designs;
DROP POLICY IF EXISTS designs_admin_delete ON public.designs;
CREATE POLICY designs_admin_insert ON public.designs FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY designs_admin_update ON public.designs FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY designs_admin_delete ON public.designs FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS reviews_admin_insert ON public.reviews;
DROP POLICY IF EXISTS reviews_admin_update ON public.reviews;
DROP POLICY IF EXISTS reviews_admin_delete ON public.reviews;
CREATE POLICY reviews_admin_insert ON public.reviews FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY reviews_admin_update ON public.reviews FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY reviews_admin_delete ON public.reviews FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS hours_admin_insert ON public.working_hours;
DROP POLICY IF EXISTS hours_admin_update ON public.working_hours;
DROP POLICY IF EXISTS hours_admin_delete ON public.working_hours;
CREATE POLICY hours_admin_insert ON public.working_hours FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY hours_admin_update ON public.working_hours FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin())) WITH CHECK ((SELECT public.is_admin()));
CREATE POLICY hours_admin_delete ON public.working_hours FOR DELETE TO authenticated
  USING ((SELECT public.is_admin()));

-- Remove anonymous access to unused endpoints until the UI implements them.
REVOKE EXECUTE ON FUNCTION public.cancel_booking_by_code(text,text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_booking_by_code(text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.join_waitlist(text,text,uuid,date,text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.submit_review(text,integer,text) FROM anon, authenticated;

-- Only active, non-sample services and designs can be used for public bookings.
CREATE OR REPLACE FUNCTION public.create_booking_request(
  p_service_id uuid, p_design_id uuid, p_starts_at timestamptz,
  p_name text, p_phone text, p_notes text DEFAULT ''
)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE
  s public.business_settings%rowtype;
  v_service public.services%rowtype;
  v_design public.designs%rowtype;
  v_name text := btrim(coalesce(p_name, ''));
  v_phone text := regexp_replace(coalesce(p_phone, ''), chr(92) || 'D', '', 'g');
  v_notes text := btrim(coalesce(p_notes, ''));
  v_date date;
  v_client uuid;
  v_price numeric(12,2);
  v_deposit numeric(12,2);
  v_code text;
BEGIN
  IF char_length(v_name) < 2 OR char_length(v_name) > 80 THEN RAISE EXCEPTION 'INVALID_NAME'; END IF;
  IF char_length(v_phone) < 8 OR char_length(v_phone) > 15 THEN RAISE EXCEPTION 'INVALID_PHONE'; END IF;
  IF char_length(v_notes) > 500 THEN RAISE EXCEPTION 'INVALID_NOTES'; END IF;
  IF p_starts_at IS NULL THEN RAISE EXCEPTION 'SLOT_UNAVAILABLE'; END IF;

  SELECT * INTO s FROM public.business_settings bs WHERE bs.id = 1;
  IF NOT FOUND THEN RAISE EXCEPTION 'BUSINESS_NOT_CONFIGURED'; END IF;

  SELECT * INTO v_service FROM public.services sv
  WHERE sv.id = p_service_id AND sv.is_active AND NOT sv.is_sample;
  IF NOT FOUND THEN RAISE EXCEPTION 'SERVICE_UNAVAILABLE'; END IF;

  IF p_design_id IS NOT NULL THEN
    SELECT * INTO v_design FROM public.designs d
    WHERE d.id = p_design_id AND d.is_available AND NOT d.is_sample;
    IF NOT FOUND THEN RAISE EXCEPTION 'DESIGN_UNAVAILABLE'; END IF;
  END IF;

  IF (SELECT count(*) FROM public.bookings b
      WHERE b.source='web' AND b.created_at > now()-interval '10 minutes') >= 15 THEN
    RAISE EXCEPTION 'RATE_LIMITED';
  END IF;
  IF (SELECT count(*) FROM public.bookings b JOIN public.clients c ON c.id=b.client_id
      WHERE c.phone=v_phone AND b.status='pending') >= 3 THEN
    RAISE EXCEPTION 'TOO_MANY_PENDING';
  END IF;

  v_date := (p_starts_at AT TIME ZONE s.timezone)::date;
  IF NOT EXISTS (SELECT 1 FROM public.get_available_slots(p_service_id,v_date) g
                 WHERE g.starts_at=p_starts_at) THEN
    RAISE EXCEPTION 'SLOT_UNAVAILABLE';
  END IF;

  INSERT INTO public.clients(full_name,phone) VALUES(v_name,v_phone)
  ON CONFLICT(phone) DO UPDATE SET phone=excluded.phone
  RETURNING id INTO v_client;

  v_price := v_service.price + coalesce(v_design.extra_price,0);
  v_deposit := round(v_price*s.deposit_percent/100.0);
  BEGIN
    INSERT INTO public.bookings(client_id,service_id,design_id,service_name,design_name,
      starts_at,duration_min,status,price,deposit_amount,client_notes,source)
    VALUES(v_client,v_service.id,v_design.id,v_service.name,v_design.name,p_starts_at,
      v_service.duration_min,'pending',v_price,v_deposit,v_notes,'web')
    RETURNING public_code INTO v_code;
  EXCEPTION WHEN exclusion_violation THEN
    RAISE EXCEPTION 'SLOT_UNAVAILABLE';
  END;
  RETURN v_code;
END
$function$;

REVOKE EXECUTE ON FUNCTION public.create_booking_request(uuid,uuid,timestamptz,text,text,text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.create_booking_request(uuid,uuid,timestamptz,text,text,text) TO anon;
