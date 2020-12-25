from flask import redirect, render_template
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
    users = User.get_all_users()
    return render_template('admin/users.html', users=users)

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
