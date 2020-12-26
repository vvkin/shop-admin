from flask import redirect, render_template, request, url_for
from flask_paginate import Pagination
from app.admin import admin
from app.admin.forms import ProductCreationForm
from app.decorators import admin_required
from app.models import User, Supplier, Category, Product


@admin.route('/', methods=['GET', 'POST'])
@admin_required
def panel():
    return render_template('admin/panel.html')

@admin.route('/users')
@admin_required
def users():
    q = request.args.get('q')
    search = q is not None
    page = request.args.get('page', type=int, default=1)
    total, users = User.get_paginated_users(page=page)
    pagination = Pagination(page=page, total=total, search=search, css_framework='foundation', 
        per_page=User.per_page)
    return render_template('admin/users.html', users=users, pagination=pagination)

@admin.route('/users/add')
@admin_required
def user_add():
    return 'user_add'

@admin.route('/products')
@admin_required
def product_list():
    return render_template('admin/product_list.html')

@admin.route('/products/add', methods=['GET', 'POST'])
@admin_required
def product_add():
    form = ProductCreationForm()
    form.category_id.choices = Category.get_all_choices()
    form.supplier_id.choices = Supplier.get_all_choices()

    if form.validate_on_submit():
        Product.save_product(
            form.supplier_id.data,
            form.category_id.data,
            form.product_name.data,
            form.sku.data,
            form.unit_price.data,
            form.discount.data,
            form.units_in_stock.data,
            form.description.data
        )    
        Product.save_images(request.files.getlist('images'), form.sku.data)
        if form.save.data: return redirect(url_for('admin.panel'))
        else: return redirect(url_for('admin.product_add'))
    
    return render_template('admin/product_add.html', form=form)

@admin.route('/_products/all')
def product_all():
    products = Product.get_all()
    return products

@admin.route('/_products/by_price')
def products_by_price(data):
    products = Product.get_by_price_like(
        lower = data['lower'],
        higher = data['higher']
    )
    return products

@admin.route('/_products/by_name')
def product_by_name(data):
    products = Product.get_by_name_like(data['name'])
    return products

