CREATE TABLE categories (
		category_id serial PRIMARY KEY,
		category_name varchar(40) NOT NULL
);

CREATE TABLE suppliers (
		supplier_id serial PRIMARY KEY,
		company_name varchar(60) NOT NULL,
		contact_name varchar(30) NOT NULL,
		phone varchar(24) NOT NULL,
		email varchar(255) NOT NULL,
		address varchar(60) NOT NULL,
		website_url varchar(100),
		is_building_contractor boolean DEFAULT FALSE
);

CREATE TABLE products (
		product_id serial PRIMARY KEY,
		category_id int REFERENCES categories (category_id),
		supplier_id int REFERENCES suppliers  (supplier_id),
		product_name varchar(40) NOT NULL,
		sku varchar(20) UNIQUE NOT NULL,
		description text,
		unit_price numeric(15, 6) NOT NULL,
		discount real DEFAULT 0,
		units_in_stock int DEFAULT 0,
		rating real DEFAULT 0,
		pictures_directory varchar(255)
);

CREATE TABLE properties (
		property_id serial PRIMARY KEY,
		property_name varchar(40) NOT NULL
);

CREATE TABLE category_properties (
		category_id int REFERENCES categories (category_id),
		property_id int REFERENCES properties (property_id)
);

CREATE TABLE product_properties (
		product_id int REFERENCES products (product_id),
		property_id int REFERENCES properties (property_id),
		property_value varchar(40) 
);

CREATE TABLE customers (
		customer_id serial PRIMARY KEY,
		first_name varchar(60) NOT NULL,
		last_name varchar(60) NOT NULL,
		phone varchar(24)
);

CREATE TABLE users (
		user_id serial PRIMARY KEY,
		customer_id int REFERENCES customers (customer_id),
		email varchar(255) NOT NULL,
		password varchar(128) NOT NULL,
		birth_date date,
		entered_date date, -- TO DO: add trigger for default now()
		is_admin boolean DEFAULT FALSE
);

CREATE TABLE payments (
		payment_id serial PRIMARY KEY,
		by_cash boolean DEFAULT FALSE,
		credit_card varchar(20),
		is_paid boolean DEFAULT FALSE,
		paid_at timestamp
);

CREATE TABLE orders (
		order_id serial PRIMARY KEY,
		customer_id int REFERENCES customers (customer_id),
		payment_id int REFERENCES payments (payment_id),
		created_at timestamp
);

CREATE TABLE order_details (
		order_id int REFERENCES orders (order_id),
		product_id int REFERENCES products (product_id),
		quantity int NOT NULL,
		discount real DEFAULT 0
);

-- Fill tables

INSERT INTO categories (category_name)
	VALUES ('A'), ('B'), ('C')
;

INSERT INTO suppliers (
	company_name, contact_name, phone,
	email, address, website_url, is_building_contractor
)
VALUES ('A', 'A', 'A', 'A', 'A', 'A', FALSE),
	   ('A', 'A', 'A', 'A', 'A', 'A', FALSE),
	   ('A', 'A', 'A', 'A', 'A', 'A', FALSE)
;

INSERT INTO products (
	category_id, supplier_id, product_name, sku,
	description, unit_price, discount,
	units_in_stock, rating, pictures_directory
)
VALUES (1, 1, 'A', 'A', '...', 100, 0, 0, 1, 'a'),
	   (1, 1, 'A', 'B', '...', 100, 0, 0, 1, 'a'),
	   (1, 1, 'A', 'C', '...', 100, 0, 0, 1, 'a')
;



