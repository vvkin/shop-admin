from flask import current_app
from typing import List, Tuple
from psycopg2.extras import RealDictCursor, DictCursor
from werkzeug.security import check_password_hash, generate_password_hash
from app.db import get_db


class PgAPI:
    @staticmethod
    def execute_query(query: str, *args):
        cursor = get_db().cursor()
        cursor.execute(query, args)
        return cursor.fetchall()
    
    @staticmethod
    def execute_dict_query(query: str, *args):
        cursor = get_db().cursor(cursor_factory=DictCursor)
        cursor.execute(query, args)
        return cursor.fetchall()
    
    @staticmethod
    def execute_rdict_query(query: str, *args):
        cursor = get_db().cursor(cursor_factory=RealDictCursor)
        cursor.execute(query, args)
        return cursor.fetchall()
    
    @staticmethod
    def execute_call(query: str, *args):
        print(args)
        cursor = get_db().cursor()
        cursor.execute(query, args)

class Supplier:
    @staticmethod
    def get_all_choices() -> List[Tuple[int, str]]:
        query = 'SELECT * FROM v_suppliers_names_all'
        suppliers = PgAPI.execute_query(query)
        return [(el[0], el[1]) for el in suppliers]

class Category:
    @staticmethod
    def get_all_choices() -> List[Tuple[int, str]]:
        query = 'SELECT * FROM v_categories_names_all'
        categories = PgAPI.execute_query(query)
        return [(el[0], el[1]) for el in categories]

class Product:
    @staticmethod
    def get_by_sku(sku: str) -> DictCursor:
        query = 'SELECT * FROM products WHERE sku = %s'
        product = PgAPI.execute_query(query, (sku, ))
        return product[0] if product else None
    
    @staticmethod
    def save_product(*product_data) -> None:
        query = """
            CALL create_product(
                %s, %s, %s::varchar(40), %s::varchar(20), 
                %s::numeric(15, 6), %s::real, %s, %s::text
            );
        """
        PgAPI.execute_call(query, *product_data)

class User:
    per_page = 10

    @staticmethod
    def get_by_email(email: str) -> RealDictCursor:
        query = 'SELECT * FROM users WHERE email = %s'
        user = PgAPI.execute_rdict_query(query, email)
        return user[0] if user else None
    
    @staticmethod
    def is_valid_login(email: str, password: str) -> bool:
        user = User.get_by_email(email)
        return user and user['password'] == password 

    @staticmethod
    def save_user(*user_data: List[str]) -> None:
        query = 'CALL create_user(%s, %s, %s, %s, %s)'
        PgAPI.execute_call(query, *user_data)
    
    @staticmethod
    def get_all_users():
        query = 'SELECT * FROM v_all_users'
        return PgAPI.execute_query(query)
    
    @staticmethod
    def get_paginated_users(page: int) -> Tuple[int, DictCursor]:
        offset = (page - 1) * User.per_page
        query = 'SELECT * FROM get_paginated_users(%s, %s)'
        query_set = PgAPI.execute_dict_query(query, User.per_page, offset)
        total_count = PgAPI.execute_query('SELECT count(*) FROM users')[0][0]
        return (total_count, query_set)

