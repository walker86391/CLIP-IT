-- ===========================================================================
--  ClipIt — public.secret_admin_codes & Verification RPC
--
--  Run this in Supabase Studio → SQL Editor → New query → Run.
--  Fully idempotent (IF EXISTS / IF NOT EXISTS safe).
--
--  PURPOSE:
--  --------
--  1. Stores secret admin access codes with creation and expiration timestamps.
--  2. Provides `verify_secret_admin_code(input_code text)`:
--     - Alternate login route on auth tab 3 ("Secret Code").
--     - If expired: returns status 'expired' with message:
--       "Code expired. Sign up / login now"
--     - If valid: returns status 'valid' with role 'admin' and access granted.
--  3. Provides `create_secret_admin_code` for generating new codes.
--  4. Provides `list_secret_admin_codes` for admin viewing.
-- ===========================================================================


-- ─── 1. Table: public.secret_admin_codes ───────────────────────────────────

create table if not exists public.secret_admin_codes (
  id          uuid primary key default gen_random_uuid(),
  code        text unique not null,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null,
  is_active   boolean not null default true,
  created_by  text default 'walker86391@gmail.com',
  note        text default 'Admin access code'
);

-- Index for instant lookups
create index if not exists idx_secret_admin_codes_code
  on public.secret_admin_codes (lower(code));


-- ─── 2. RPC: verify_secret_admin_code ──────────────────────────────────────

create or replace function public.verify_secret_admin_code(input_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  found_row public.secret_admin_codes%rowtype;
  clean_code text;
begin
  clean_code := trim(input_code);

  if clean_code is null or clean_code = '' then
    return jsonb_build_object(
      'success', false,
      'status', 'empty',
      'message', 'Please enter a secret code'
    );
  end if;

  select * into found_row
  from public.secret_admin_codes
  where lower(code) = lower(clean_code);

  if not found then
    return jsonb_build_object(
      'success', false,
      'status', 'invalid',
      'message', 'Invalid secret code'
    );
  end if;

  if not found_row.is_active then
    return jsonb_build_object(
      'success', false,
      'status', 'revoked',
      'message', 'This code has been deactivated'
    );
  end if;

  if found_row.expires_at < now() then
    return jsonb_build_object(
      'success', false,
      'status', 'expired',
      'message', 'Code expired. Sign up / login now'
    );
  end if;

  -- Code is active and valid: grant admin access
  return jsonb_build_object(
    'success', true,
    'status', 'valid',
    'message', 'Admin access granted',
    'email', coalesce(found_row.created_by, 'walker86391@gmail.com'),
    'role', 'admin',
    'expires_at', found_row.expires_at
  );
end;
$$;

-- Allow anon and authenticated users to call the verification function
grant execute on function public.verify_secret_admin_code(text) to anon, authenticated;


-- ─── 3. RPC: create_secret_admin_code ──────────────────────────────────────

create or replace function public.create_secret_admin_code(
  new_code text,
  valid_duration_hours int default 24,
  creator_email text default 'walker86391@gmail.com',
  code_note text default 'Admin access code'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  exp_time timestamptz;
  clean_code text;
begin
  clean_code := trim(new_code);
  exp_time := now() + (coalesce(valid_duration_hours, 24) || ' hours')::interval;

  insert into public.secret_admin_codes (code, expires_at, created_by, is_active, note)
  values (clean_code, exp_time, creator_email, true, code_note)
  on conflict (code) do update
    set expires_at = exp_time,
        is_active = true,
        created_at = now(),
        note = excluded.note;

  return jsonb_build_object(
    'success', true,
    'code', clean_code,
    'expires_at', exp_time
  );
end;
$$;

grant execute on function public.create_secret_admin_code(text, int, text, text) to authenticated, anon;


-- ─── 4. RPC: list_secret_admin_codes ───────────────────────────────────────

create or replace function public.list_secret_admin_codes()
returns table (
  id uuid,
  code text,
  is_active boolean,
  created_at timestamptz,
  expires_at timestamptz,
  created_by text,
  note text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select s.id, s.code, s.is_active, s.created_at, s.expires_at, s.created_by, s.note
  from public.secret_admin_codes s
  order by s.created_at desc;
end;
$$;

grant execute on function public.list_secret_admin_codes() to authenticated, anon;


-- ─── 5. Row Level Security ─────────────────────────────────────────────────

alter table public.secret_admin_codes enable row level security;

-- Direct table reads restricted; all verification and generation occurs via
-- the SECURITY DEFINER functions above.
drop policy if exists "secret_codes_admin_select" on public.secret_admin_codes;
create policy "secret_codes_admin_select" on public.secret_admin_codes
  for select using (
    auth.jwt() ->> 'email' = 'walker86391@gmail.com'
  );


-- ─── 6. Initial Seed Codes (Idempotent) ────────────────────────────────────

-- 1. Active Admin Code (valid for 30 days)
insert into public.secret_admin_codes (code, expires_at, created_by, note)
values (
  'ADMIN-2026-CLIPIT',
  now() + interval '30 days',
  'walker86391@gmail.com',
  'Primary 30-day admin access code'
)
on conflict (code) do nothing;

-- 2. Expired Test Code (expired 1 day ago) for verifying the expired UI prompt
insert into public.secret_admin_codes (code, expires_at, created_by, note)
values (
  'EXPIRED-TEST',
  now() - interval '1 day',
  'walker86391@gmail.com',
  'Test expired code'
)
on conflict (code) do nothing;
