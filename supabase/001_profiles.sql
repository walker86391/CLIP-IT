-- ===========================================================================
--  ClipIt — public.profiles setup
--
--  Run this ONCE in Supabase Studio → SQL Editor → New query → Run.
--  It is fully idempotent (every statement is IF EXISTS / IF NOT EXISTS safe),
--  so re-running it after a partial setup is fine and will repair things.
--
--  WHY THIS FILE EXISTS
--  --------------------
--  Signing up fails with Supabase's generic
--
--      "Database error saving new user"
--
--  whenever the row INSERT into auth.users is rejected. GoTrue wraps that
--  failure in a trigger on auth.users (normally handle_new_user) that
--  creates the matching public.profiles row. If that trigger throws, the
--  whole sign-up is rolled back and the app never gets past the error.
--
--  The two reasons the trigger throws are both fixed below:
--
--    1. public.profiles.date_of_birth is NOT NULL. The sign-up form asks
--       for a date of birth, so the column was created as required — but
--       the trigger fires the instant the auth user is created, BEFORE the
--       app ever gets a session to call updateProfile() with a date. The
--       trigger's INSERT has no date to supply, so it violates NOT NULL.
--    2. A column the trigger or the app writes does not exist on the
--       table (a half-finished setup), so the INSERT/UPDATE errors out
--       with "column profiles.x does not exist".
--
--  Section 3 (row level security) is separate on purpose — read its note.
-- ===========================================================================


-- ─── 1. The table and its columns ──────────────────────────────────────────
-- `create table if not exists` does NOT add columns to a table that already
-- exists, so the ALTERs below are what actually repair an existing table.
-- They are harmless on a fresh one.

create table if not exists public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  email         text,
  display_name  text,
  date_of_birth date,
  created_at    timestamptz not null default now()
);

alter table public.profiles add column if not exists email         text;
alter table public.profiles add column if not exists display_name  text;
alter table public.profiles add column if not exists date_of_birth date;
alter table public.profiles add column if not exists created_at    timestamptz
  not null default now();

-- THE key fix for sign-up. The date of birth is collected by the app AFTER
-- the account exists (it needs a session to save it), so it cannot be NOT
-- NULL at the moment the trigger creates the row.
alter table public.profiles alter column date_of_birth drop not null;
alter table public.profiles alter column display_name  drop not null;
alter table public.profiles alter column email         drop not null;


-- ─── 2. The sign-up trigger ────────────────────────────────────────────────
-- Dropped and recreated rather than updated, so that a previously broken
-- version can never keep shadowing this fix. It is marked `security definer`
-- because the trigger runs as the inserting role, and search_path is pinned
-- so it cannot be hijacked.

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Only columns that certainly exist are written, and every one of them has
  -- a value, so nothing here can fail on a NOT NULL constraint.
  -- display_name arrives in user metadata from the Flutter sign-up form; the
  -- date of birth does not, because it is written later via updateProfile().
  insert into public.profiles (id, email, display_name, created_at)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'display_name', ''),
    now()
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ─── 3. Row level security (OPTIONAL — read this before running) ───────────
--
--  At the moment of writing, public.profiles has RLS DISABLED, which means
--  ANYONE with the project's public anon key can read every row in it via
--  PostgREST. That is a real privacy leak for a table holding dates of
--  birth.
--
--  Enabling RLS and scoping every policy to auth.uid() = id closes it, and
--  is what the app expects: the Flutter client always sends the signed-in
--  user's JWT, so `auth.uid()` matches and its own row is readable/writable.
--
--  This section is safe to run — but if you would rather lock it down from
--  the Supabase dashboard later, select lines from here and run those.

-- alter table public.profiles enable row level security;

-- drop policy if exists "profiles_select_own" on public.profiles;
-- create policy "profiles_select_own" on public.profiles
--   for select using (auth.uid() = id);

-- drop policy if exists "profiles_insert_own" on public.profiles;
-- create policy "profiles_insert_own" on public.profiles
--   for insert with check (auth.uid() = id);

-- drop policy if exists "profiles_update_own" on public.profiles;
-- create policy "profiles_update_own" on public.profiles
--   for update using (auth.uid() = id) with check (auth.uid() = id);