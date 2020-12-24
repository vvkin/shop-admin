from flask import redirect, render_template
from app.admin import admin
from app.decorators import admin_required
from app.models import User

@admin.route('/', methods=['GET', 'POST'])
@admin_required
def panel():
    return 'hi, admin!'

@admin.route('/users')
@admin_required
def users():
    users = User.get_all_users()
    return render_template('admin/users.html', users=users)
