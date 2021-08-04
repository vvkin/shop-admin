from flask import render_template, url_for, redirect
from app.main import main
from app.models import Product


@main.route('/', methods=['GET', 'POST'])
def index():
    return render_template('index.html')

@main.route('/products/<int:pk>/', methods=['GET', 'POST'])
def product_detail(pk: int):
    product = Product.get_product(pk)
    return render_template('product_detail.html', product=product)

@main.route('/products', methods=['GET', 'POST'])
def product_list():
    products = Product.get_all_products()
    return render_template('product_list.html', products=products)
