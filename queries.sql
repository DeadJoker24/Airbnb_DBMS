
SET search_path TO airbnb_system;

-- ---------------------------------------------------------
-- 1. Top 5 highest-rated listings (min. 2 reviews)
-- ---------------------------------------------------------
SELECT
    l.listing_id,
    p.title,
    p.city,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(r.review_id) AS review_count
FROM listing l
JOIN property p ON l.property_id = p.property_id
JOIN review r   ON r.listing_id = l.listing_id
GROUP BY l.listing_id, p.title, p.city
HAVING COUNT(r.review_id) >= 2
ORDER BY avg_rating DESC, review_count DESC
LIMIT 5;

-- ---------------------------------------------------------
-- 2. Total revenue generated per host
-- ---------------------------------------------------------
SELECT
    u.full_name AS host_name,
    h.user_id AS host_id,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    SUM(b.total_amount) AS total_revenue
FROM host h
JOIN users u    ON h.user_id = u.user_id
JOIN property p ON p.host_id = h.user_id
JOIN listing l  ON l.property_id = p.property_id
JOIN booking b  ON b.listing_id = l.listing_id
WHERE b.booking_status IN ('Confirmed', 'Completed')
GROUP BY u.full_name, h.user_id
ORDER BY total_revenue DESC;

-- ---------------------------------------------------------
-- 3. Occupancy rate per listing
--    (booked nights vs. days since listing was created)
-- ---------------------------------------------------------
SELECT
    l.listing_id,
    p.title,
    SUM(b.check_out_date - b.check_in_date) AS nights_booked,
    GREATEST(CURRENT_DATE - l.created_at::date, 1) AS days_listed,
    ROUND(
        100.0 * SUM(b.check_out_date - b.check_in_date)
        / GREATEST(CURRENT_DATE - l.created_at::date, 1), 2
    ) AS occupancy_pct
FROM listing l
JOIN property p ON l.property_id = p.property_id
LEFT JOIN booking b
    ON b.listing_id = l.listing_id
    AND b.booking_status IN ('Confirmed', 'Completed')
GROUP BY l.listing_id, p.title, l.created_at
ORDER BY occupancy_pct DESC NULLS LAST;

-- ---------------------------------------------------------
-- 4. Guests with the most cancellations
-- ---------------------------------------------------------
SELECT
    u.full_name AS guest_name,
    g.user_id AS guest_id,
    COUNT(c.cancellation_id) AS cancellations,
    SUM(c.refund_amount) AS total_refunded
FROM guest g
JOIN users u ON g.user_id = u.user_id
JOIN cancellation c ON c.cancelled_by = g.user_id
GROUP BY u.full_name, g.user_id
ORDER BY cancellations DESC;

-- ---------------------------------------------------------
-- 5. Most popular amenities among active listings
-- ---------------------------------------------------------
SELECT
    a.amenity_name,
    COUNT(la.listing_id) AS listing_count
FROM amenity a
JOIN listing_amenity la ON la.amenity_id = a.amenity_id
JOIN listing l ON l.listing_id = la.listing_id
WHERE l.availability_status = 'Available'
GROUP BY a.amenity_name
ORDER BY listing_count DESC;

-- ---------------------------------------------------------
-- 6. Monthly booking trend (bookings + revenue per month)
-- ---------------------------------------------------------
SELECT
    DATE_TRUNC('month', booking_date) AS month,
    COUNT(*) AS bookings,
    SUM(total_amount) AS revenue
FROM booking
WHERE booking_status IN ('Confirmed', 'Completed')
GROUP BY DATE_TRUNC('month', booking_date)
ORDER BY month;

-- ---------------------------------------------------------
-- 7. Cities with the highest average nightly price
-- ---------------------------------------------------------
SELECT
    p.city,
    COUNT(l.listing_id) AS listing_count,
    ROUND(AVG(l.price_per_night), 2) AS avg_price_per_night
FROM property p
JOIN listing l ON l.property_id = p.property_id
GROUP BY p.city
ORDER BY avg_price_per_night DESC;

-- ---------------------------------------------------------
-- 8. Payment status breakdown
--    (useful sanity check on payment pipeline health)
-- ---------------------------------------------------------
SELECT
    payment_status,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_amount
FROM payment
GROUP BY payment_status
ORDER BY total_amount DESC;

-- ---------------------------------------------------------
-- 9. Guests who never left a review after a completed stay
--    (candidates for a "leave a review" reminder campaign)
-- ---------------------------------------------------------
SELECT DISTINCT
    u.full_name AS guest_name,
    b.booking_id,
    b.check_out_date
FROM booking b
JOIN guest g ON g.user_id = b.guest_id
JOIN users u ON u.user_id = g.user_id
LEFT JOIN review r ON r.booking_id = b.booking_id
WHERE b.booking_status = 'Completed'
  AND r.review_id IS NULL
ORDER BY b.check_out_date DESC;

-- ---------------------------------------------------------
-- 10. Uses the active_listings_with_ratings view
--     (defined in Schema.sql) to find best value listings:
--     highly rated but below the average city price
-- ---------------------------------------------------------
SELECT
    v.title,
    v.city,
    v.price_per_night,
    v.avg_rating,
    v.review_count
FROM active_listings_with_ratings v
JOIN (
    SELECT city, AVG(price_per_night) AS avg_city_price
    FROM active_listings_with_ratings
    GROUP BY city
) city_avg ON v.city = city_avg.city
WHERE v.avg_rating >= 4.0
  AND v.price_per_night < city_avg.avg_city_price
ORDER BY v.avg_rating DESC;
