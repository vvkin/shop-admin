from flask import redirect, render_template, request
from flask_paginate import Pagination
from app.admin import admin
from app.decorators import admin_required
from app.models import User

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

@admin.route('/products/add')
@admin_required
def product_add():
    return 'product add'
