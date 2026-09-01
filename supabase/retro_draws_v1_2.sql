-- Oráculo Diosa Fortuna v1.2.0 - Histórico oficial central de Melate Retro

create table if not exists public.retro_draws (
  id uuid primary key default gen_random_uuid(),
  contest_number bigint not null unique check (contest_number > 0),
  draw_date date not null unique,
  n1 smallint not null check (n1 between 1 and 39),
  n2 smallint not null check (n2 between 1 and 39),
  n3 smallint not null check (n3 between 1 and 39),
  n4 smallint not null check (n4 between 1 and 39),
  n5 smallint not null check (n5 between 1 and 39),
  n6 smallint not null check (n6 between 1 and 39),
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  constraint retro_draws_sorted_unique check (
    n1 < n2 and n2 < n3 and n3 < n4 and n4 < n5 and n5 < n6
  )
);

alter table public.retro_draws enable row level security;

drop policy if exists "Usuarios activos consultan sorteos Retro" on public.retro_draws;
create policy "Usuarios activos consultan sorteos Retro"
on public.retro_draws for select to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.active = true
  )
);

drop policy if exists "Administradores gestionan sorteos Retro" on public.retro_draws;
create policy "Administradores gestionan sorteos Retro"
on public.retro_draws for all to authenticated
using (public.is_admin())
with check (public.is_admin());

create or replace function public.add_retro_official_draw(
  p_contest_number bigint,
  p_draw_date date,
  p_numbers integer[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_numbers integer[];
  v_id uuid;
begin
  if not public.is_admin() then
    raise exception 'Sólo un administrador puede registrar sorteos oficiales.';
  end if;
  if p_contest_number is null or p_contest_number <= 0 then
    raise exception 'Número de concurso inválido.';
  end if;
  if p_draw_date is null or p_draw_date > current_date then
    raise exception 'Fecha de sorteo inválida.';
  end if;
  if array_length(p_numbers, 1) <> 6 then
    raise exception 'Debes proporcionar seis números.';
  end if;

  select array_agg(n order by n) into v_numbers
  from (select distinct unnest(p_numbers) as n) s;

  if array_length(v_numbers, 1) <> 6
     or v_numbers[1] < 1 or v_numbers[6] > 39 then
    raise exception 'Los números deben ser distintos y estar entre 1 y 39.';
  end if;

  insert into public.retro_draws (
    contest_number, draw_date, n1, n2, n3, n4, n5, n6, created_by
  ) values (
    p_contest_number, p_draw_date,
    v_numbers[1], v_numbers[2], v_numbers[3],
    v_numbers[4], v_numbers[5], v_numbers[6], auth.uid()
  ) returning id into v_id;
  return v_id;
exception
  when unique_violation then
    raise exception 'Ese número de concurso o esa fecha ya fue registrado.';
end;
$$;

revoke all on function public.add_retro_official_draw(bigint,date,integer[]) from public;
grant execute on function public.add_retro_official_draw(bigint,date,integer[]) to authenticated;
