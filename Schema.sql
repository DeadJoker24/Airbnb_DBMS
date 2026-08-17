-- =========================================================
-- Airbnb DBMS - Schema
-- =========================================================

CREATE SCHEMA IF NOT EXISTS airbnb_system;
SET search_path TO airbnb_system;

-- ---------------------------------------------------------
-- 1. users  (base identity table for guests, hosts, admins)
--    NOTE: renamed from "User" -> "users" because USER is a
--    reserved word in PostgreSQL and would need to be quoted
--    every single time it's referenced.
-- ---------------------------------------------------------
CREATE TABLE users (
    user_id     BIGINT PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(150) UNIQUE NOT NULL,
    phone       VARCHAR(20),
    password    VARCHAR(255) NOT NULL,
    gender      VARCHAR(10)  CHECK (gender IN ('Male', 'Female', 'Other')),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status      VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Suspended', 'Deactivated'))
);

-- ---------------------------------------------------------
-- 2. guest
-- ---------------------------------------------------------
CREATE TABLE guest (
    user_id             BIGINT PRIMARY KEY,
    loyalty_points      INT DEFAULT 0 CHECK (loyalty_points >= 0),
    travel_preferences  TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- 3. host
-- ---------------------------------------------------------
CREATE TABLE host (
    user_id             BIGINT PRIMARY KEY,
    host_since          DATE,
    host_rating         DECIMAL(2,1) CHECK (host_rating BETWEEN 0 AND 5),
    verification_status VARCHAR(20) DEFAULT 'Pending'
                         CHECK (verification_status IN ('Pending', 'Verified', 'Rejected')),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- 4. admin
-- ---------------------------------------------------------
CREATE TABLE admin (
    user_id      BIGINT PRIMARY KEY,
    role         VARCHAR(50),
    access_level INT CHECK (access_level BETWEEN 1 AND 5),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- 5. property
-- ---------------------------------------------------------
CREATE TABLE property (
    property_id  BIGINT PRIMARY KEY,
    host_id      BIGINT NOT NULL,
    title        VARCHAR(150) NOT NULL,
    description  TEXT,
    property_type VARCHAR(50),
    country      VARCHAR(50),
    city         VARCHAR(50),
    state        VARCHAR(50),
    pincode      VARCHAR(10),
    latitude     DECIMAL(9,6),
    longitude    DECIMAL(9,6),
    FOREIGN KEY (host_id) REFERENCES host(user_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- 6. listing
--    NOTE: "max guests" / "no_of guests" had a literal space
--    in the original column name, which is invalid unless
--    quoted everywhere. Fixed to max_guests / no_of_guests.
-- ---------------------------------------------------------
CREATE TABLE listing (
    listing_id           BIGINT PRIMARY KEY,
    property_id          BIGINT NOT NULL,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    availability_status  VARCHAR(20) DEFAULT 'Available'
                          CHECK (availability_status IN ('Available', 'Booked', 'Unavailable', 'Inactive')),
    price_per_night      DECIMAL(10,2) NOT NULL CHECK (price_per_night > 0),
    max_guests           INT CHECK (max_guests > 0),
    bedrooms             INT CHECK (bedrooms >= 0),
    bathrooms            INT CHECK (bathrooms >= 0),
    house_rules          TEXT,
    FOREIGN KEY (property_id) REFERENCES property(property_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- 7. amenity
-- ---------------------------------------------------------
CREATE TABLE amenity (
    amenity_id   BIGINT PRIMARY KEY,
    amenity_name VARCHAR(100) NOT NULL,
    description  TEXT
);

-- ---------------------------------------------------------
-- 8. listing_amenity  (junction table, many-to-many)
-- ---------------------------------------------------------
CREATE TABLE listing_amenity (
    listing_id BIGINT,
    amenity_id BIGINT,
    PRIMARY KEY (listing_id, amenity_id),
    FOREIGN KEY (listing_id) REFERENCES listing(listing_id) ON DELETE CASCADE,
    FOREIGN KEY (amenity_id) REFERENCES amenity(amenity_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- 9. booking
-- ---------------------------------------------------------
CREATE TABLE booking (
    booking_id      BIGINT PRIMARY KEY,
    guest_id        BIGINT NOT NULL,
    listing_id      BIGINT NOT NULL,
    check_in_date   DATE NOT NULL,
    check_out_date  DATE NOT NULL,
    booking_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    no_of_guests    INT CHECK (no_of_guests > 0),
    booking_status  VARCHAR(20) DEFAULT 'Confirmed'
                     CHECK (booking_status IN ('Confirmed', 'Cancelled', 'Completed', 'Pending')),
    total_amount    DECIMAL(10,2) CHECK (total_amount >= 0),
    admin_id        BIGINT,
    FOREIGN KEY (guest_id)   REFERENCES guest(user_id),
    FOREIGN KEY (listing_id) REFERENCES listing(listing_id),
    FOREIGN KEY (admin_id)   REFERENCES admin(user_id),
    CHECK (check_out_date > check_in_date)
);

-- ---------------------------------------------------------
-- 10. payment
-- ---------------------------------------------------------
CREATE TABLE payment (
    payment_id      BIGINT PRIMARY KEY,
    booking_id      BIGINT NOT NULL,
    amount          DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    payment_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method  VARCHAR(50),
    payment_status  VARCHAR(20) DEFAULT 'Pending'
                     CHECK (payment_status IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    transaction_ref VARCHAR(100) UNIQUE,
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE
);

-- ---------------------------------------------------------
-- 11. review
-- ---------------------------------------------------------
CREATE TABLE review (
    review_id    BIGINT PRIMARY KEY,
    booking_id   BIGINT NOT NULL,
    guest_id     BIGINT NOT NULL,
    listing_id   BIGINT NOT NULL,
    rating       INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment      TEXT,
    review_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES booking(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (guest_id)   REFERENCES guest(user_id),
    FOREIGN KEY (listing_id) REFERENCES listing(listing_id)
);

-- ---------------------------------------------------------
-- 12. cancellation
-- ---------------------------------------------------------
CREATE TABLE cancellation (
    cancellation_id   BIGINT PRIMARY KEY,
    booking_id        BIGINT NOT NULL UNIQUE,
    cancelled_by      BIGINT NOT NULL,
    cancellation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    refund_amount     DECIMAL(10,2) CHECK (refund_amount >= 0),
    reason            TEXT,
    FOREIGN KEY (booking_id)   REFERENCES booking(booking_id) ON DELETE CASCADE,
    FOREIGN KEY (cancelled_by) REFERENCES users(user_id)
);

-- =========================================================
-- Indexes
-- Primary/unique keys already get an index automatically.
-- These target the columns that get filtered/joined on most
-- (foreign keys used in JOINs, and common lookup columns).
-- =========================================================
CREATE INDEX idx_property_host_id       ON property(host_id);
CREATE INDEX idx_property_city          ON property(city);
CREATE INDEX idx_listing_property_id    ON listing(property_id);
CREATE INDEX idx_listing_availability   ON listing(availability_status);
CREATE INDEX idx_booking_guest_id       ON booking(guest_id);
CREATE INDEX idx_booking_listing_id     ON booking(listing_id);
CREATE INDEX idx_booking_dates          ON booking(check_in_date, check_out_date);
CREATE INDEX idx_payment_booking_id     ON payment(booking_id);
CREATE INDEX idx_review_listing_id      ON review(listing_id);

-- =========================================================
-- View: active listings with host + average rating
-- Demonstrates a reusable, denormalized read model on top
-- of the normalized schema.
-- =========================================================
CREATE OR REPLACE VIEW active_listings_with_ratings AS
SELECT
    l.listing_id,
    p.title,
    p.city,
    p.country,
    l.price_per_night,
    l.max_guests,
    u.full_name AS host_name,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(r.review_id) AS review_count
FROM listing l
JOIN property p ON l.property_id = p.property_id
JOIN host h      ON p.host_id = h.user_id
JOIN users u      ON h.user_id = u.user_id
LEFT JOIN review r ON r.listing_id = l.listing_id
WHERE l.availability_status = 'Available'
GROUP BY l.listing_id, p.title, p.city, p.country, l.price_per_night, l.max_guests, u.full_name;

-- =========================================================
-- Trigger: automatically mark a listing "Booked" whenever
-- a new confirmed booking is inserted for it.
-- =========================================================
CREATE OR REPLACE FUNCTION mark_listing_booked()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.booking_status = 'Confirmed' THEN
        UPDATE listing
        SET availability_status = 'Booked'
        WHERE listing_id = NEW.listing_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mark_listing_booked
AFTER INSERT ON booking
FOR EACH ROW
EXECUTE FUNCTION mark_listing_booked();
