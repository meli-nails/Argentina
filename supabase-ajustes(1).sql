-- Meli Nails: correcciones complementarias para Supabase
-- Ejecutar en Supabase Dashboard > SQL Editor.
-- La regla de cancelación coincide con la política pública de 24 horas.

create or replace function public.cancel_booking_by_code(p_code text, p_reason text default '')
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_booking public.bookings%rowtype;
  v_client text;
  v_tz text;
begin
  if char_length(coalesce(p_code, '')) < 16 then return false; end if;

  update public.bookings b
  set status = 'cancelled',
      cancel_reason = left(btrim(coalesce(p_reason, '')), 300)
  where b.public_code = p_code
    and b.status in ('pending', 'confirmed')
    and b.starts_at > now() + interval '24 hours'
  returning * into v_booking;

  if not found then return false; end if;

  select c.full_name into v_client
  from public.clients c where c.id = v_booking.client_id;

  select s.timezone into v_tz
  from public.business_settings s where s.id = 1;

  insert into public.notifications (type, title, body, booking_id)
  values (
    'cancellation',
    'Turno cancelado por la clienta',
    v_client || ' canceló su turno del ' ||
      to_char(v_booking.starts_at at time zone v_tz, 'DD/MM "a las" HH24:MI') || '.',
    v_booking.id
  );

  return true;
end;
$$;

-- Índices para las claves foráneas señaladas por Supabase Performance Advisor.
create index if not exists bookings_design_id_idx on public.bookings (design_id);
create index if not exists bookings_service_id_idx on public.bookings (service_id);
create index if not exists notifications_booking_id_idx on public.notifications (booking_id);
create index if not exists waitlist_service_id_idx on public.waitlist (service_id);
