from flask import render_template, url_for, redirect
from app.main import main
from app.models import Product


@main.route('/', methods=['GET', 'POST'])
def index():
    return render_template('home.html')

@main.route('/products/<int:pk>/', methods=['GET', 'POST'])
def product_detail(pk: int):
    product = Product.get_product(pk)
    return render_template('product_detail.html', product=product)

@main.route('/_products/filter/')
def product_list(data):
    pass
    

