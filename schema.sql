-- HandPicked Pros: database schema (Postgres / Supabase)
-- Run in the Supabase SQL editor.

create type user_role as enum ('employer', 'artisan', 'admin');
create type booking_status as enum ('requested', 'accepted', 'completed', 'declined');
create type license_status as enum ('pending', 'approved', 'rejected');

-- Supabase Auth stores passwords, so this table links to auth.users
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null,
  name text not null,
  email text not null unique,
  created_at timestamptz not null default now()
);

create table trades (
  id serial primary key,
  name text not null unique
);

create table artisan_profiles (
  user_id uuid primary key references profiles(id) on delete cascade,
  trade_id int not null references trades(id),
  bio text,
  years_experience int check (years_experience >= 0),
  hourly_rate numeric(8,2) check (hourly_rate >= 0),
  city text not null,
  state text not null,
  zip text not null,
  verified boolean not null default false,
  created_at timestamptz not null default now()
);

-- Search: trade + location
create index artisan_search_idx on artisan_profiles (trade_id, state, city);
create index artisan_zip_idx on artisan_profiles (zip);

create table licenses (
  id serial primary key,
  artisan_id uuid not null references artisan_profiles(user_id) on delete cascade,
  type text not null,
  number text not null,
  document_url text,
  status license_status not null default 'pending'
);

create table portfolio_photos (
  id serial primary key,
  artisan_id uuid not null references artisan_profiles(user_id) on delete cascade,
  image_url text not null
);

create table bookings (
  id serial primary key,
  employer_id uuid not null references profiles(id),
  artisan_id uuid not null references artisan_profiles(user_id),
  job_description text not null,
  job_date date,
  status booking_status not null default 'requested',
  created_at timestamptz not null default now()
);

-- One review per booking, and only after the job is completed
create table reviews (
  id serial primary key,
  booking_id int not null unique references bookings(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

create function check_booking_completed() returns trigger as $$
begin
  if (select status from bookings where id = new.booking_id) <> 'completed' then
    raise exception 'Reviews are only allowed on completed bookings';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger reviews_require_completed
  before insert on reviews
  for each row execute function check_booking_completed();

-- Search view: verified artisans with average rating
create view artisan_search as
select
  a.user_id, p.name, t.name as trade, a.city, a.state, a.zip,
  a.hourly_rate, a.years_experience,
  coalesce(avg(r.rating), 0)::numeric(3,2) as avg_rating,
  count(r.id) as review_count
from artisan_profiles a
join profiles p on p.id = a.user_id
join trades t on t.id = a.trade_id
left join bookings b on b.artisan_id = a.user_id
left join reviews r on r.booking_id = b.id
where a.verified = true
group by a.user_id, p.name, t.name, a.city, a.state, a.zip,
         a.hourly_rate, a.years_experience;

-- Row Level Security: on by default, so nothing is exposed until policies exist
alter table profiles enable row level security;
alter table trades enable row level security;
alter table artisan_profiles enable row level security;
alter table licenses enable row level security;
alter table portfolio_photos enable row level security;
alter table bookings enable row level security;
alter table reviews enable row level security;

-- Public can browse trades and verified artisans
create policy "trades are public" on trades for select using (true);
create policy "verified artisans are public" on artisan_profiles
  for select using (verified = true or auth.uid() = user_id);
