CREATE SCHEMA Airbnb_system;

SET search_path TO Airbnb_system ;;

1. User
CREATE TABLE User (
user_id BIGINT PRIMARY KEY,
full_name VARCHAR(100) NOT NULL,
email VARCHAR(150) UNIQUE NOT NULL,
phone VARCHAR(20),
password VARCHAR(255) NOT NULL,
gender VARCHAR(10),
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
status VARCHAR(20)
):

2. Guest
CREATE TABLE Guest (
user_id BIGINT PRIMARY KEY,
loyalty_points INT,
travel_preferences TEXT,
FOREIGN KEY (user_id) REFERENCES User(user_id)

);

3. Host
CREATE TABLE Host (
user_id BIGINT PRIMARY KEY,
host_since DATE,
host_rating DECIMAL(2,1),
verification_status VARCHAR(20),
FOREIGN KEY (user_id) REFERENCES User(user_id)
):

4. Admin
CREATE TABLE Admin (
user_id BIGINT PRIMARY KEY,
role VARCHAR(50),
access_level INT,
FOREIGN KEY (user_id) REFERENCES User(user_id)
):

5. Property
CREATE TABLE Property (
property_id BIGINT PRIMARY KEY,
host_id BIGINT NOT NULL,
title VARCHAR(150) NOT NULL,
description TEXT,
property_type VARCHAR(50),
country VARCHAR(50),
city VARCHAR(50),
state VARCHAR(50),
pincode VARCHAR(10),
latitude DECIMAL(9,6),
longitude DECIMAL(9,6),
FOREIGN KEY (host_id) REFERENCES Host(user_id)
);

6. Listing
CREATE TABLE Listing (
listing_id BIGINT PRIMARY KEY,
property_id BIGINT NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
availability_status VARCHAR(20),
price_per_night DECIMAL(10,2),
max guests INT,
bedrooms INT,
bathrooms INT,
house_rules TEXT,
FOREIGN KEY (property_id) REFERENCES Property(property_id)
):

7. Amenity
CREATE TABLE Amenity (
amenity_id BIGINT PRIMARY KEY,
amenity_name VARCHAR(100) NOT NULL,
description TEXT
):

8. Listing_Amenity
CREATE TABLE Listing_Amenity (
listing_id BIGINT,
amenity_id BIGINT,
PRIMARY KEY (listing_id, amenity_id),
FOREIGN KEY (listing_id) REFERENCES Listing(listing_id),
FOREIGN KEY (amenity_id) REFERENCES Amenity(amenity_id)

9. Booking
CREATE TABLE Booking (
booking_id BIGINT PRIMARY KEY,
guest_id BIGINT NOT NULL,
listing_id BIGINT NOT NULL,
check_in_date DATE NOT NULL,
check_out_date DATE NOT NULL,
booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
no_of guests INT,
booking_status VARCHAR(20),
total_amount DECIMAL(10,2),
admin_id BIGINT,
FOREIGN KEY (guest_id) REFERENCES Guest(user_id),
FOREIGN KEY (listing_id) REFERENCES Listing(listing_id),
FOREIGN KEY (admin_id) REFERENCES Admin(user_id)
):

10. Payment
CREATE TABLE Payment (
payment_id BIGINT PRIMARY KEY,
booking_id BIGINT NOT NULL,
amount DECIMAL(10,2) NOT NULL,
payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
payment_method VARCHAR(50),
payment_status VARCHAR(20),
transaction_ref VARCHAR(100) UNIQUE,
FOREIGN KEY (booking_id) REFERENCES Booking(booking_id)

):

11. Review
CREATE TABLE Review (
review_id BIGINT PRIMARY KEY,
booking_id BIGINT NOT NULL,
guest_id BIGINT NOT NULL,
listing_id BIGINT NOT NULL,
rating INT,
comment TEXT,
review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
FOREIGN KEY (guest_id) REFERENCES Guest(user_id),
FOREIGN KEY (listing_id) REFERENCES Listing(listing_id)

):

12. Cancellation
CREATE TABLE Cancellation (
cancellation_id BIGINT PRIMARY KEY,
booking_id BIGINT NOT NULL UNIQUE,
cancelled_by BIGINT NOT NULL,
cancellation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
refund_amount DECIMAL(10,2),
reason TEXT,
FOREIGN KEY (booking_id) REFERENCES Booking(booking_id),
FOREIGN KEY (cancelled_by) REFERENCES User(user_id)

)
