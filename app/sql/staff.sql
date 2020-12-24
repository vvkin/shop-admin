CREATE OR REPLACE PROCEDURE save_user(
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
		
		COMMIT;
    END;
$$;