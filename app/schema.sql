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

-- TRIGGERS
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

CREATE OR REPLACE FUNCTION set_order_discount()
RETURNS trigger AS $$
DECLARE 
    total_price double precision;
    order_discount double precision := 0;
BEGIN
    SELECT sum(od.quantity * p.unit_price * (1 - od.discount))
    INTO total_price
    FROM order_details od
	  JOIN products p USING (product_id)
    WHERE od.order_id = NEW.order_id;
	
	SELECT CASE
		WHEN total_price > 15000 THEN 0.1
		WHEN total_price > 8000 THEN 0.05
		WHEN total_price > 4000 THEN 0.03
	END INTO order_discount;
	
    UPDATE order_details
    SET discount = order_discount
    WHERE order_id = NEW.order_id;

    NEW.discount = order_discount;
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_set_order_discount BEFORE INSERT ON
    order_details FOR EACH ROW EXECUTE PROCEDURE set_order_discount();

-- trigger to archive deleted users
CREATE TABLE users_archive(
	LIKE users,
	deletion_datetime timestamp with time zone,
    deleted_by name
);

CREATE OR REPLACE FUNCTION archive_deleted_user()
RETURNS trigger AS $$
BEGIN
	INSERT INTO users_archive
	SELECT OLD.*,
	       current_timestamp AS deletetion_datetime, 
	       current_user AS deleted_by;
    RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_archive_deleted_user AFTER DELETE ON
    users FOR EACH ROW EXECUTE PROCEDURE archive_deleted_user();

-- VIEWS
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

CREATE OR REPLACE VIEW get_all_created_users AS
	SELECT *
	FROM users
	UNION
	SELECT user_id,
		   customer_id,
		   email,
		   password,
		   birth_date,
		   entered_date,
		   is_admin
	FROM users_archive;
    
-- FUNCTIONS AND PROCEDURES
-- stored procedures
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

-- table functions
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

CREATE OR REPLACE FUNCTION get_product_properties(_product_id int)
RETURNS TABLE (
	product_name varchar(60),
	property_name varchar(40),
	property_value varchar(40)
) AS $$
	SELECT product_name,
	       property_name,
		   property_value
	FROM products
	  JOIN product_properties USING (product_id)
	  JOIN properties USING (property_id)
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

-- scalar functions
CREATE OR REPLACE FUNCTION get_total_order_price(_order_id int)
RETURNS double precision AS
$$
	SELECT od.quantity * p.unit_price * (1 - od.discount)
	FROM order_details od
	JOIN products p USING (product_id)
	WHERE order_id = _order_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_product_properties(_product_id int)
RETURNS TABLE (
	product_name varchar(60),
	property_name varchar(40),
	property_value varchar(40)
) AS $$
	SELECT product_name,
	       property_name,
		   property_value
	FROM products
	  JOIN product_properties USING (product_id)
	  JOIN properties USING (property_id)
	WHERE product_id = _product_id
$$ LANGUAGE SQL;

-- FILL TABLES
INSERT INTO users (email, password, is_admin)
VALUES ('admin@admin.admin', '2562admin', TRUE),
       ('admin1@admin.admin', 'admin1', TRUE),
       ('admin2@admin.admin', 'admin2', TRUE);

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
	'Гіпсокартон вогнестійкий Knauf має високі пожежно-технічні характеристики. Використовується для монтажу в приміщеннях з підвищеними протипожежними нормами.'
),
(
	1, 6, 'Гіпсокартон вологостійкий 1200х3000х12.5 мм',
	'HGB78I-OP', 177.0, 0.0, 13, 4.8, 
	'Вологостійкий гіпсокартон виробництва компанії Keresit, якість та надійність якого підтверджена часом. Застосовується для облаштування легких міжкімнатних перегородок, підвісних стель, облицювання стін і вогнезахисту конструкцій в будівлях і приміщеннях за умов підвищеної вологості.'
),
(
	3, 5, 'Шпатлівка ЯПВ Фініш ИР-24 1,5 кг', 
	'IOC75W-JH', 45.30, 0.1, 150, 3.8, 
	'Готова для використання шпаклівка найвищої якості, особливо рекомендується для завершального, фінішного вирівнювання стін і стель вручну і машинним способом. Під час застосування зберігає постійну консистенцію, завдяки чому може застосовуватися тривалий час. Невитрачена маса в щільно закритій упаковці зберігає придатність до подальшого застосування. Після висихання виключно легко шліфується, зберігаючи хороші показники за міцністю. Залишає білосніжні і ідеально гладкі поверхні під фарбування.'
),
(
	3, 2, 'Клей для блоків Polimin ПБ-55 25 кг',
	'EHC12P-GO', 86.40, 0.0, 171, 5.0, 
	'Якісна суміш, що застосовується для тонкошарова кладки (товщина шару від 3 мм) внутрішніх і зовнішніх стін блоками з пористих бетонів (газосилікатний бетон, пінобетон), керамзитобетону, а також із силікатних блоків і цегли. Застосовується для приклеювання теплоізоляційних панелей з ніздрюватих бетонів до бетонних і цегляних основ.'
),
(
	8, 3, 'Цегла вібропресована червона', 
	'RHG80L-MN', 6.50, 0.0, 2589, 4.4, 
	'Кожен хто будує будинок, хоче щоб він був не тільки надійним, але красивим і неповторним. Здійснити всі свої найсміливіші бажання і політ фантазії як у рядового забудовника, так і у досвідчених архітекторів, дизайнерів і будівельників допоможе дана цегла. В асортименті компанії велика різноманітність розмірів форм і фактур: вузький, кутовий, модульний, широкий, зі скошеним кутом.'
),
(
	8, 7, 'Плитка тротуарна TT1 1000х500х60мм', 
	'BIB61W-JM', 145.0, 0.05, 587, 4.9, 
	'Плитка тротуарна ТТ-1 використовується для облагороджування територій біля будинку, гаража, доріжок в саду та інших об''єктів. За своєю формою дуже унікальна, зрізана по краях та має товщину 6 сантиметрів (6 см). Дана плитка є хорошою заміною аналогам розміру 500х1000х45 мм. Підвищена товщина сприяє тому, що матеріал впевнено утримує значі навантаження.'
),
(
	8, 7, 'Тротуарна плитка "Цегла" вібропресована', 
	'UNO87N-LK', 212.43, 0.0, 233, 4.5, 
	'Наша тротуарна плитка це якісний ущільнений бетон, а отже міцна і морозостійка плитка, зносостійкий лицьовий шар якої на основі кварцового піску.'
),
(
	18, 9, 'Лінолеум на тканинній основі "Алекс"', 
	'LBH12I-JC', 65.0, 0.0, 58, 4.65, 
	'Лінолеум від провідного виробника України на тканнний основі має приємну текстуру та високу теплоутримувальну здатність, випускається в кількох кольорах, тому підійде для будь-якого інтер''єру кімнати.'
),
(
	18, 11, 'Лінолеум IDEAL Ultra CRACKED2', 
	'ORO09G-AL', 300.0, 0.0, 13, 4.9, 
	'Це найтовстіший лінолеум, теплозберігальна здатність якого просто вражає. Товщина 4.3мм дає можливість укладати лінолеум на цементну стяжку, тоді як велика товщина дозволяє зберігати в 3 рази більше тепла, а також надає шумоізоляцію, яка є найкращою серед аналогів.Також товщина допомагає виправити дрібні нерівності підлоги, це можуть бути дрібні нерівності стяжки, нерівний старий паркет, дошки, плитка і т.д. Утеплювач виготовлений на поліестровій основі, що робить його стійким до вологи.'
),
(
	9, 10, 'Бітумна черепиця Бардолін TOP Сота коричнева 3 кв.м', 
	'ARK54O-PI', 333.0, 0.0, 120, 5.0, 
	'Бітумна черепиця від вітчизняного виробника вирізняється серед аналогів вдалим поєднанням зовнішнього вигляду та надійності. Є чудовим вибором для виконання покрівельних робіт для приватних будинків, адже є простою у застосуванні та володіє невеликою вагою, що значно спрощує робочий процес.'
),
(
	9, 10, 'Металочерепиця матова PSM 1180x1200 мм RAL 7024 графітова', 
	'EAX19L-OH', 336.0, 0.0, 54, 4.2, 
	'Металочерепиця є довговічним і міцним покрівельним матеріалом, на який нанесено зображення класичної керамічної черепиці. Листи зроблені з оцинкованої сталі, відрізняються стійкістю до корозії та зовнішніх чинників. Металочерепиця має легку вагу і може укладатися на різні типи дахів, які мають кут нахилу не менш 10 градусів. Також підходить для монтажу поверх старого покрівельного покриття, при цьому зберігаючи первинний архітектурний вигляд будівлі.'
);

INSERT INTO properties (property_name)
VALUES ('Вага'),
       ('Ширина'),
       ('Довжина'),
       ('Об''єм'),
	   ('Площа'),
	   ('Товщина'),
	   ('Країна-виробник'),
	   ('Тип хвилі'),
	   ('Колір'),
	   ('Тип покриття'),
	   ('Матеріал'),
	   ('Морозостійкість'),
	   ('Основа'),
	   ('Тип шпатлівки'),
	   ('Область застосування'),
	   ('Висота')
;

INSERT INTO category_properties (category_id, property_id)
VALUES (1, 2), (1, 3), (1, 6), (1, 7), (1, 9),
	   (3, 1), (3, 7), (3, 13), (3, 14), (3, 15),
	   (8, 1), (8, 2), (8, 3), (8, 7), (8, 16),
	   (9, 5), (9, 6), (9, 7), (9, 8), (9, 9), (9, 10),
	   (18, 5), (18, 6), (18, 7), (18, 9), (18, 10)
;

INSERT INTO product_properties (product_id, property_id, property_value)
VALUES (1, 2, '1200мм'), (1, 3, '2500мм'), (1, 5, '12.5мм'), (1, 7, 'Україна'), (1, 9, 'Червоний'),
       (3, 1, '1.5кг'), (3, 7, 'Україна'), (3, 13, 'Акрилова'), (3, 14, 'Фінішна'), (3, 15, 'Для внутрішніх робіт'),
	   (6, 1, '0.058т'), (6, 2, '500мм'), (6, 3, '1000мм'), (6, 7, 'Україна'), (6, 16, '60мм')
;

INSERT INTO payments (credit_card, is_paid, paid_at)
VALUES ('371125686988680', TRUE, '2020-11-15 06:39:05.842674'),
       ('5257871557145417', FALSE, NULL),
	   ('378950035683242', FALSE, NULL),
	   ('342289832131102', TRUE, '2020-12-08 05:03:08.718769'),
	   ('6011880760337625', TRUE, '2020-12-27 20:30:47.690493'),
	   ('4716804456438508', TRUE, '2020-11-02 08:41:33.16295'),
	   ('347650633744507', FALSE, NULL),
	   ('5268783742020354', TRUE, '2020-11-23 13:53:45.798445'),
	   ('4929150790485208', TRUE, '2020-12-17 19:56:46.975609'),
	   ('4024007139784499', FALSE, NULL)
;

INSERT INTO orders (customer_id, payment_id, created_at)
VALUES (8, 1, '2020-11-15 04:32:05.853342'),
       (1, 2, '2020-11-03 22:30:34.626239'),
	   (4, 3, '2020-12-16 03:54:40.451208'),
	   (7, 4, '2020-12-08 05:02:04.345789'),
	   (3, 5, '2020-12-27 20:27:34.131678'),
	   (1, 6, '2020-11-02 07:34:21.357065'),
	   (6, 7, '2019-12-26 04:59:25.311378'),
	   (11, 8, '2020-11-23 11:31:56.487346'),
	   (13, 9, '2020-12-17 19:31:09.302784'),
	   (7, 10, '2029-12-13 13:58:32.981193')
;

INSERT INTO order_details (order_id, product_id, quantity, discount)
VALUES (1, 2, 10, 0.1),
       (2, 7, 72, 0.15),
	   (3, 3, 1, 0.0),
	   (4, 2, 31, 0.0),
	   (5, 8, 12, 0.0),
	   (6, 4, 2, 0.05),
	   (7, 5, 678, 0.1),
	   (8, 9, 13, 0.0),
	   (9, 1, 7, 0.0),
	   (10, 10, 43, 0.0)
;

-- CREATE read only employee, who is able to use all tables but cannot to change database schema
CREATE USER shop_manager WITH PASSWORD 'hard_to_guess_password';
GRANT CONNECT ON DATABASE pyshop TO shop_manager;

REVOKE ALL PRIVILEGES ON SCHEMA public FROM shop_manager;
GRANT USAGE ON SCHEMA public TO shop_manager;
GRANT SELECT, INSERT, DELETE, UPDATE ON ALL TABLES IN SCHEMA public TO shop_manager;
