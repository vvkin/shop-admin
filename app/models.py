from flask import current_app
from typing import List
from psycopg2.extras import RealDictCursor
from werkzeug.security import check_password_hash, generate_password_hash
from app.db import get_db


class Product:

    @staticmethod
    def get_product(pk: int):
        cursor = get_db().cursor(cursor_factory=RealDictCursor)
        product_query = """
            SELECT product_name,
                   sku,
                   p.description,
                   p.unit_price,
                   p.units_in_stock,
                   p.rating,
                   p.pictures_directory,
                   c.category_name
            FROM products p
              JOIN categories c USING (category_id)
            WHERE product_id = %s
        """

        properties_query = """
            SELECT p.property_name, pp.property_value
            FROM product_properties pp
                JOIN properties p USING (property_id)
            WHERE product_id = %s
        """
        
        cursor.execute(product_query, (pk, ))
        product = cursor.fetchone()
        cursor.execute(properties_query, (pk, ))
        properties = cursor.fetchall()

        return {
            'product': product,
            'properties': properties
        }
    
    @staticmethod
    def get_all_products():
        cursor = get_db().cursor()
        cursor.execute('SELECT * FROM products')
        query_set = cursor.fetchall()
        return query_set
        
    @staticmethod
    def get_products_by_category(category_name: str):
        cursor = get_db.cursor()
        query = """
            SELECT *
            FROM products p
            WHERE EXISTS (
                SELECT 1
                FROM categories c
                WHERE c.category_id = p.category_id
                  AND c.category_name = %s
            )
        """
        cursor.execute(query, (category_name, ))
        query_set = cursor.fetchall()
        return query_set
    
    @staticmethod
    def set_product(data):
        cursor = get_db.cursor()
        query = """
            INSERT INTO products
        """

        cursor.execute(query, **data)

class User:
    @staticmethod
    def get_by_email(email: str) -> RealDictCursor:
        cursor = get_db().cursor(cursor_factory=RealDictCursor)
        query = 'SELECT * FROM users WHERE email = %s'
        cursor.execute(query, (email, ))
        return cursor.fetchone()
    
    @staticmethod
    def is_valid_login(email: str, password: str) -> bool:
        user = User.get_by_email(email)
        return check_password_hash(user['password'], password)

    @staticmethod
    def save_user(*user_data: List[str]) -> None:
        cursor = get_db().cursor()
        query = 'CALL save_user(%s, %s, %s, %s, %s)'
        cursor.execute(query, user_data)





        

