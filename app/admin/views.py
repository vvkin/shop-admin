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
def products():
    return 'products here'

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
        if form.save.data: return redirect(url_for('admin.panel'))
        else: return redirect(url_for('admin.product_add'))
    return render_template('admin/product_add.html', form=form)
