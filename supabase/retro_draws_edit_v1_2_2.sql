-- Oráculo Diosa Fortuna v1.2.2
-- Corrección administrativa de sorteos oficiales con bitácora.

create table if not exists public.retro_draw_changes (
  id uuid primary key default gen_random_uuid(),
  draw_id uuid not null references public.retro_draws(id),
  old_contest_number bigint not null,
  new_contest_number bigint not null,
  old_draw_date date not null,
  new_draw_date date not null,
  old_numbers integer[] not null,
  new_numbers integer[] not null,
  changed_by uuid not null references public.profiles(id),
  changed_at timestamptz not null default now()
);

alter table public.retro_draw_changes enable row level security;

drop policy if exists "Administradores consultan cambios Retro"
on public.retro_draw_changes;
create policy "Administradores consultan cambios Retro"
on public.retro_draw_changes for select to authenticated
using (public.is_admin());

create or replace function public.update_retro_official_draw(
  p_original_contest_number bigint,
  p_new_contest_number bigint,
  p_draw_date date,
  p_numbers integer[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_draw public.retro_draws%rowtype;
  v_numbers integer[];
begin
  if not public.is_admin() then
    raise exception 'Sólo un administrador puede corregir sorteos oficiales.';
  end if;

  select rd.* into v_draw
  from public.retro_draws as rd
  where rd.contest_number = p_original_contest_number
  for update;

  if v_draw.id is null then
    raise exception 'No se encontró el concurso que deseas corregir.';
  end if;
  if p_new_contest_number is null or p_new_contest_number <= 1661 then
    raise exception 'Sólo se pueden corregir concursos centralizados posteriores al 1661.';
  end if;
  if p_draw_date is null or p_draw_date > current_date then
    raise exception 'Fecha de sorteo inválida.';
  end if;
  if array_length(p_numbers, 1) <> 6 then
    raise exception 'Debes proporcionar seis números.';
  end if;

  select array_agg(n order by n) into v_numbers
  from (select distinct unnest(p_numbers) as n) as values_to_sort;

  if array_length(v_numbers, 1) <> 6
     or v_numbers[1] < 1 or v_numbers[6] > 39 then
    raise exception 'Los números deben ser distintos y estar entre 1 y 39.';
  end if;

  insert into public.retro_draw_changes (
    draw_id,
    old_contest_number,
    new_contest_number,
    old_draw_date,
    new_draw_date,
    old_numbers,
    new_numbers,
    changed_by
  ) values (
    v_draw.id,
    v_draw.contest_number,
    p_new_contest_number,
    v_draw.draw_date,
    p_draw_date,
    array[
      v_draw.n1::integer,v_draw.n2::integer,v_draw.n3::integer,
      v_draw.n4::integer,v_draw.n5::integer,v_draw.n6::integer
    ],
    v_numbers,
    auth.uid()
  );

  update public.retro_draws
  set contest_number = p_new_contest_number,
      draw_date = p_draw_date,
      n1 = v_numbers[1],
      n2 = v_numbers[2],
      n3 = v_numbers[3],
      n4 = v_numbers[4],
      n5 = v_numbers[5],
      n6 = v_numbers[6]
  where id = v_draw.id;

  return v_draw.id;
exception
  when unique_violation then
    raise exception 'Ese número de concurso o esa fecha pertenece a otro sorteo.';
end;
$$;

revoke all on function public.update_retro_official_draw(bigint,bigint,date,integer[])
from public;
grant execute on function public.update_retro_official_draw(bigint,bigint,date,integer[])
to authenticated;

comment on function public.update_retro_official_draw(bigint,bigint,date,integer[])
is 'Corrige un sorteo Retro oficial y conserva una bitácora del cambio.';
