from flask import current_app
from app.db import get_db
from typing import Dict

class Product:

    @staticmethod
    def get_product(pk: int):
        cursor = get_db().cursor()
        query = """SELECT * FROM products
            WHERE product_id = %s"""
        
        cursor.execute(query, (pk, ))
        product = cursor.fetchone()
        return product


        

