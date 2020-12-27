import os
import shutil
import json
from flask import current_app, jsonify
from flask_paginate import Pagination
from typing import List, Tuple
from psycopg2.extras import RealDictCursor, DictCursor
from werkzeug.utils import secure_filename
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
    per_page = 3
    last_query = ''
    last_option = ''

    @staticmethod
    def get_all() -> DictCursor:
        query = 'SELECT * FROM v_products_all'
        products = PgAPI.execute_dict_query(query)
        return products

    @staticmethod
    def get_by_sku(sku: str) -> DictCursor:
        query = 'SELECT * FROM products WHERE sku = %s'
        product = PgAPI.execute_query(query, (sku, ))
        return product[0] if product else None
    
    @staticmethod
    def get_by_pk(pk: int):
        query = 'SELECT * FROM products WHERE product_id=%s'
        product = PgAPI.execute_query(query, (pk, ))
        return product[0] if product else None

    @staticmethod
    def get_json(pk: int):
        product = Product.get_by_pk(pk)
        pairs = zip(
            [
                'category_id', 'supplier_id', 'product_name',
                'sku', 'description', 'unit_price', 
                'discount', 'units_in_stock', 'pictures'
            ],
            product[1:9] + (product[-1], )
        )
        data = dict(pairs)
        response = json.dumps(data, ensure_ascii=False, default=str)
        return response
    
    @staticmethod
    def get_by_name_like(name: str) -> DictCursor:
        query = 'SELECT * FROM get_products_by_name(%s)'
        products = PgAPI.execute_dict_query(query, name)
        return products
    
    @staticmethod
    def get_by_category_like(category: str) -> DictCursor:
        query = 'SELECT * FROM get_products_by_category(%s)'
        products = PgAPI.execute_dict_query(query, category)
        return products
    
    @staticmethod
    def get_by_price_like(lower: float, higher: float) -> DictCursor:
        query = 'SELECT * FROM get_products_by_price(%s, %s)'
        products = PgAPI.execute_dict_query(query, lower, higher)
        return products
    
    @staticmethod
    def paginate_queryset(query_set, page) -> Tuple[int, DictCursor]:
        total = len(query_set)
        offset = (page - 1) * Product.per_page
        query_set = query_set[offset: offset + Product.per_page]
        return total, query_set
        
    @staticmethod
    def get_paginated_by(data, request_args):
        q = request_args.get('q')
        search = q is not None
        page = request_args.get('page', type=int, default=1)
        value = int(data['value'])
        Product.last_option = value

        print(value)

        if not value: products = Product.get_all()
        else:
            query = data['query']
            Product.last_query = query
            if value == 1:
                products = Product.get_by_name_like(query)
            else: products = Product.get_by_category_like(query)

        total, query_set = Product.paginate_queryset(products, page)
        pagination = pagination = Pagination(page=page, total=total, search=search, 
            css_framework='foundation', per_page=Product.per_page)
        
        return pagination, query_set

    @staticmethod
    def save_product(*product_data) -> None:
        query = """
            CALL create_product(
                %s, %s, %s::varchar(40), %s::varchar(20), 
                %s::numeric(15, 6), %s::real, %s, %s::text
            );
        """
        PgAPI.execute_call(query, *product_data)
    
    @staticmethod
    def update_product(*product_data) -> None:
        query = """
            CALL update_product(
                %s, %s, %s, %s::varchar(40), %s::varchar(20), 
                %s::numeric(15, 6), %s::real, %s, %s::text
            );
        """
        PgAPI.execute_call(query, *product_data)
    
    @staticmethod
    def delete(pk: int) -> None:
        query = 'DELETE FROM products WHERE product_id=%s'
        PgAPI.execute_call(query, pk)
    
    @staticmethod
    def rm_dir_content(directory: str) -> None:
        for file in os.listdir(directory):
            os.remove(os.path.join(directory, file))
    
    @staticmethod
    def save_images(images, sku: str) -> None:
        if not images[0].filename: return

        product = Product.get_by_sku(sku)
        images_directory = product[-1] # img directory
        app_path = current_app.config['UPLOAD_FOLDER']
        dir_path = os.path.join(current_app.root_path, app_path, images_directory)

        if os.path.exists(dir_path):
            Product.rm_dir_content(dir_path)
        else: os.mkdir(dir_path)

        for image in images:
            file_name = secure_filename(image.filename)
            image.save(os.path.join(dir_path, file_name))

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

