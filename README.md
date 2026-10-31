# HandPicked Pros

A directory where employers browse and book skilled tradespeople (plumbers, electricians, welders, and more), then leave a review of the service delivered.

## How it works

1. Employer searches by trade and location (state, city, or area).
2. Employer opens an artisan's profile and sends a booking request.
3. Artisan accepts or declines.
4. After the job, the employer marks it complete.
5. The employer can then leave one review for that booking.

Payment happens directly between employer and artisan in version 1.

## Planned stack

- Next.js, React, Tailwind CSS
- Supabase (Postgres, Auth, Storage)
- Vercel (hosting)
- Resend (email notifications)

## Database

Run `schema.sql` in the Supabase SQL editor. Row Level Security is enabled on every table; add policies for bookings, reviews, licenses, and photos before going live.

## Roadmap

- [ ] Homepage with trade and location search
- [ ] Artisan profile page
- [ ] Booking request flow
- [ ] Reviews
- [ ] Admin license verification
- [ ] Radius search (PostGIS)
- [ ] Online payments
