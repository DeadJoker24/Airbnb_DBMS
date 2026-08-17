
# Airbnb DBMS

A PostgreSQL database design that models the core of an Airbnb-style booking
platform: users (guests, hosts, admins), properties, listings, bookings,
payments, reviews, and cancellations.

## Entity-Relationship Overview

```
users ─┬── guest ──┬── booking ──┬── payment
       │           │             ├── review
       │           │             └── cancellation
       ├── host ──── property ──── listing ──── listing_amenity ── amenity
       └── admin ─── (approves bookings)
```

- `users` is the base identity table. `guest`, `host`, and `admin` each extend
  it via a 1-to-1 relationship on `user_id` (role subtype pattern).
- A `host` owns one or more `property` rows; each `property` can have one or
  more `listing` rows (e.g. re-listed at a different price/season).
- A `listing` can have many `amenity` rows through the `listing_amenity`
  junction table (many-to-many).
- A `guest` makes a `booking` against a `listing`. Each booking can produce
  one `payment`, one `review`, and — if cancelled — one `cancellation` record.

## Files

| File             | Purpose                                                        |
|------------------|-----------------------------------------------------------------|
| `Schema.sql`     | Creates the schema, all 12 tables, indexes, a view, and a trigger |
| `Insert_data.sql`| Seeds ~650 rows of realistic sample data across all tables     |
| `queries.sql`    | 10 analytical queries demonstrating joins, aggregation, and business logic |

## Setup

Requires PostgreSQL 13+.

```bash
createdb airbnb_test
psql -d airbnb_test -f Schema.sql
psql -d airbnb_test -f Insert_data.sql
psql -d airbnb_test -f queries.sql
```

All three files have been tested end-to-end against a real PostgreSQL 16
instance and run cleanly with no errors.

## Design Notes

- **Table naming**: the base identity table is called `users`, not `User` —
  `USER` is a reserved keyword in PostgreSQL and would need to be quoted on
  every reference.
- **Constraints**: `CHECK` constraints enforce valid ranges and enums at the
  database level (ratings 1–5, positive prices, valid status values,
  checkout date after check-in date, etc.) instead of relying on application
  code to catch bad data.
- **Indexes**: added on foreign key columns used in joins (`host_id`,
  `property_id`, `guest_id`, `listing_id`, `booking_id`) and on columns
  commonly filtered on (`city`, `availability_status`, booking date range),
  since primary/unique keys are indexed automatically but foreign keys are
  not by default in PostgreSQL.
- **View**: `active_listings_with_ratings` joins listing, property, host, and
  review data into a single denormalized read model — useful for a listing
  search/browse page without repeating that join everywhere.
- **Trigger**: `trg_mark_listing_booked` automatically flips a listing's
  `availability_status` to `'Booked'` whenever a new confirmed booking is
  inserted for it, so availability doesn't have to be managed manually in
  application code.

## Example queries included

1. Top 5 highest-rated listings (minimum 2 reviews)
2. Total revenue generated per host
3. Occupancy rate per listing
4. Guests with the most cancellations
5. Most popular amenities among active listings
6. Monthly booking trend (volume + revenue)
7. Cities with the highest average nightly price
8. Payment status breakdown
9. Completed bookings with no review yet (reminder-campaign candidates)
10. Best-value listings: highly rated but priced below their city's average

## Possible next steps

- Add a `wishlist` / `saved_listings` table (guest ↔ listing many-to-many)
- Add a `message` table for guest-host communication
- Partition `booking` by year once data volume grows
- Add role-based row-level security so guests can only see their own bookings
