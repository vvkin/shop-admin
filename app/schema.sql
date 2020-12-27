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
		product_name varchar(60) NOT NULL,
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

-- views
CREATE OR REPLACE VIEW v_suppliers_names_all AS
	SELECT supplier_id, company_name
	FROM suppliers;

CREATE OR REPLACE VIEW v_categories_names_all AS
	SELECT category_id, category_name
	FROM categories;

CREATE OR REPLACE VIEW v_products_all AS 
	SELECT product_id, 
		   product_name,
		   sku,
		   description,
		   category_name, 
		   concat(
			   company_name, '(', 
			   contact_name, ', ',
			   phone, ', ',
			   email, ')'
		   ) AS supplier_name,
		   unit_price, 
		   discount,
		   units_in_stock
	FROM products
	  JOIN categories USING (category_id)
	  JOIN suppliers USING (supplier_id);

-- help functions
CREATE OR REPLACE PROCEDURE create_user(
    _email varchar(255),
    _phone varchar(24),
    _first_name varchar(60),
    _last_name varchar(60),
    _password varchar(255)
)
LANGUAGE plpgsql
AS $$
DECLARE _customer_id int;
    BEGIN 
        INSERT INTO customers (first_name, last_name, phone)
        VALUES (_first_name, _last_name, _phone)
        RETURNING customer_id INTO _customer_id;

        INSERT INTO users (customer_id, email, password)
        VAlUES (_customer_id, _email, _password);
    END;
$$;

CREATE OR REPLACE PROCEDURE create_product(
	_supplier_id int,
	_category_id int,
	_product_name varchar(40),
	_sku varchar(20),
	_unit_price numeric(15, 6),
	_discount real,
	_units_in_stock int,
	_description text
)
AS $$
	INSERT INTO products (
		supplier_id, category_id, product_name, 
		sku, unit_price, discount, 
		units_in_stock, description
	)
	VALUES ($1, $2, $3, $4, $5, $6, $7, $8);
$$ LANGUAGE SQL;

CREATE OR REPLACE PROCEDURE update_product(
	_product_id int,
	_supplier_id int,
	_category_id int,
	_product_name varchar(40),
	_sku varchar(20),
	_unit_price numeric(15, 6),
	_discount real,
	_units_in_stock int,
	_description text
)
AS $$
	UPDATE products SET
		supplier_id    = $2,
		category_id    = $3,
		product_name   = $4,
		sku            = $5,
		unit_price     = $6,
		discount       = $7,
		units_in_stock = $8,
		description    = $9
	WHERE product_id = _product_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_paginated_users(_limit int, _offset int)
RETURNS TABLE (
    user_id int,
    first_name varchar(60),
    last_name varchar(60),
    email varchar(255),
    phone varchar(24),
    birth_date date,
    entered_date date,
    is_admin boolean
) AS $$
    SELECT user_id, 
		   first_name, last_name,
           email, phone,
           birth_date, entered_date, 
		   is_admin
    FROM users LEFT JOIN 
	  customers USING (customer_id)
	ORDER BY user_id
	LIMIT _limit
	OFFSET _offset
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_products_by_price(numeric(15, 6), numeric(15, 6))
RETURNS TABLE (LIKE v_products_all)
AS $$
	SELECT * FROM v_products_all
	WHERE unit_price BETWEEN $1 AND $2;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_products_by_category(varchar(40))
RETURNS TABLE (LIKE v_products_all)
AS $$
	SELECT * FROM v_products_all
	WHERE lower(category_name) LIKE concat(lower($1), '%');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_products_by_name(varchar(40))
RETURNS TABLE (LIKE v_products_all)
AS $$
	SELECT * FROM v_products_all
	WHERE lower(product_name) LIKE concat(lower($1), '%');
$$ LANGUAGE SQL;

-- triggers
CREATE OR REPLACE FUNCTION set_entered_date()
RETURNS trigger AS $$
BEGIN
    NEW.entered_date := current_date;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_set_entered_date BEFORE INSERT
    ON users FOR EACH ROW EXECUTE PROCEDURE set_entered_date();

CREATE OR REPLACE FUNCTION set_pictures_directory()
RETURNS trigger AS $$
BEGIN
	NEW.pictures_directory = concat('products/', NEW.product_id);
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_set_pictures_directory BEFORE INSERT
	ON products FOR EACH ROW EXECUTE PROCEDURE set_pictures_directory();

-- fill admins
INSERT INTO users (email, password, is_admin)
VALUES ('admin@admin.admin', 'admin', TRUE),
       ('admin1@admin.admin', 'admin1', TRUE),
       ('admin2@admin.admin', 'admin2', TRUE);

-- fill common users
CALL create_user('petropetrov@gmail.com', '+380000000000', 'Петро', 'Петров', 'petro123');
CALL create_user('vasilkravchina@gmail.com', '+380000000001', 'Василь', 'Кравчина', 'vasil123');
CALL create_user('ivangaydamaka@gmail.com', '+380000000002', 'Іван', 'Гайдамака', 'ivan123');
CALL create_user('dmytropolischuk@gmail.com', '+380000000003', 'Дмитро', 'Поліщук', 'dmytro123');
CALL create_user('denysshevchenko@gmail.com', '+380000000004', 'Денис', 'Шевченко', 'denys123');
CALL create_user('victorfranko@gmail.com', '+380000000005', 'Віктор', 'Франко', 'victor123');
CALL create_user('yevhentolochko@gmail.com', '+380000000006', 'Євген', 'Толочко', 'yevhen123');
CALL create_user('danylobezruchko@gmail.com', '+380000000007', 'Данило', 'Безручко', 'danylo123');
CALL create_user('anastasiabohdanets@gmail.com', '+380000000008', 'Анастасія', 'Богданець', 'anastasia123');
CALL create_user('yuliakushnir@gmail.com', '+380000000009', 'Юлія', 'Кушнір', 'yulia123');
CALL create_user('olenafedorovych@gmail.com', '+380000000010', 'Олена', 'Федорович', 'olena123');
CALL create_user('darialeskovets@gmail.com', '+380000000011', 'Дарія', 'Лесковець', 'petro123');
CALL create_user('angelinapakhniuk@gmail.com', '+380000000012', 'Ангеліна', 'Пахнюк', 'angelina123');

-- fill categories
INSERT INTO categories (category_name)
VALUES ('Гіпсокартон'),
       ('Профіль для гіпсокартона'),
       ('Будівельні суміші'),
       ('Клеєві суміші'),
       ('Утеплювач'),
       ('Пиломатеріали'),
       ('Будівельна хімія'),
       ('Кладочні матеріали'),
       ('Покрівельні матеріали'),
       ('Лакофарбові матеріали'),
       ('Фасадні матеріали'),
       ('Кріплення'),
       ('Металічні сітки'),
       ('Двір і город'),
       ('Електрика'),
       ('Отоплення і водопровід'),
       ('Вікна і двері'),
       ('Лінолеум'),
       ('Каналізація')
;

-- fill suppliers
INSERT INTO suppliers (
	company_name, contact_name, phone,
	email, address, 
	website_url, is_building_contractor
)
VALUES 
(
	'УкрБуд', 'Богданець Іван Сергійович', '+380501234973',
	'ukbud@bud.com', 'м. Київ, проспект Степана Бандери, 27',
	'ukrbud.com.ua', FALSE
),
(
	'УкрТон', 'Лозовий Олексій Семенович', '+380662340113',
	'ukrton@gmail.com', 'м. Рівне, вул. Київська, 81',
	'ukrton.com.ua', TRUE
),
(
	'АртБудПостач', 'Шевченко Олена Олександрівна', '+380667869814',
	'artbud@ukr.net', 'м. Київ, вул. Вадима Гетьмана, 13',
	'artbugpostach.com.ua', FALSE
),
(
	'БЕТЦЕМ-А', 'Сокіл Петро Геннадійович', '+380959647374',
	'betcema@ukr.net', 'м. Чернігів, вул. Гайдамацька, 123',
	'betcema.com', FALSE
),
(
	'ЯПВ', 'Шрам Ілля Миколайович', '+380914519426',
	'yapvbud@ukr.net', 'м. Київ, вул. Софіївська, 54',
	'yapv.com', FALSE
),
(
	'Kerezit', 'Герман Марта Альбертівна', '+380664823810',
	'kerezitcomp@gmail.com', 'м. Луцьк, вул. Петра Маха, 65',
	'kerezit.com', TRUE
),
(
	'ISOOM', 'Ковальский Євген Михайлович', '+380664503798',
	'isoom@ukr.net', 'м. Київ, вул. Володимирська, 171',
	'isoom.com.ua', FALSE
),
(
	'ОВБМУ', 'Кушнір Володимир Дмитрович', '+380665674651',
	'unionmbm@gmail.com', 'м. Черкаси, вул. Незалежності, 34',
	NULL, FALSE
),
(
	'МеталХол', 'Близнюк Денис Аркадійович', '+380669341430',
	'metalhol@ukr.net', 'м. Херсон, вул. Василя Стуса, 12',
	'methlhol.com.ua', TRUE
),
(
	'ЄвроПокрівля', 'Вронський Микола Євгенович', '+380957099745',
	'eupokrivlya@gmail.com', 'м. Київ, вул. Велика Васильківська, 87',
	'eupokrivlya.com.ua', FALSE
),
(
	'ТехноЗахід', 'Смеречук Олексій Олексійович', '+380509873241',
	'techwest@tu.kyiv.ua', 'м. Київ, проспект Визволителів, 78',
	'techwest.com', TRUE
);

INSERT INTO products (
	category_id, supplier_id, product_name, 
	sku, unit_price, discount,
	units_in_stock, rating, description
)
VALUES (
	1, 1, 'Гіпсокартон вогнестійкий Knauf 12,5*2500*1200 мм', 
	'URB06W-IN', 115.0, 0.0, 87, 4.7,
	'Гіпсокартон вогнестійкий Knauf має високі пожежно-технічні характеристики. 
	Використовується для монтажу в приміщеннях з підвищеними протипожежними нормами.'
),
(
	1, 6, 'Гіпсокартон вологостійкий 1200х3000х12.5 мм',
	'HGB78I-OP', 177.0, 0.0, 13, 4.8, 
	'Вологостійкий гіпсокартон виробництва компанії Keresit, якість 
	та надійність якого підтверджена часом. Застосовується для облаштування
	легких міжкімнатних перегородок, підвісних стель, облицювання стін 
	і вогнезахисту конструкцій в будівлях і приміщеннях за умов підвищеної
	вологості.'
),
(
	3, 5, 'Шпатлівка ЯПВ Фініш ИР-24 1,5 кг', 
	'IOC75W-JH', 45.30, 0.1, 150, 3.8, 
	'Готова для використання шпаклівка найвищої якості, 
	особливо рекомендується для завершального,
	фінішного вирівнювання стін і стель вручну 
	і машинним способом. Під час застосування зберігає 
	постійну консистенцію, завдяки чому може застосовуватися 
	тривалий час. Невитрачена маса в щільно закритій упаковці 
	зберігає придатність до подальшого застосування. Після висихання 
	виключно легко шліфується, зберігаючи хороші показники за міцністю. 
	Залишає білосніжні і ідеально гладкі поверхні під фарбування'
),
(
	3, 2, 'Клей для блоків Polimin ПБ-55 25 кг', 
	'EHC12P-GO', 86.40, 0.0, 171, 5.0, 
	'Якісна суміш, що застосовується для тонкошарова кладки (товщина шару від 3 мм) 
	внутрішніх і зовнішніх стін блоками з пористих бетонів (газосилікатний бетон, пінобетон), 
	керамзитобетону, а також із силікатних блоків і цегли. Застосовується для 
	приклеювання теплоізоляційних панелей з ніздрюватих бетонів до бетонних і 
	цегляних основ.'
);/*
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
),
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
),
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
),
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
),
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
),
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
),
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
),
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
),
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
),
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
),
(
	1, 1, 'Гіпсокартон Саундлайн ГКЛА лист 2000х1200х12.5 мм', 
	'URB06W-IN', 229.0, 0.0, 87, 4.5, ''
);
*/