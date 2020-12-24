from flask import redirect, render_template
from app.admin import admin
from app.decorators import admin_required

@admin.route('/', methods=['GET', 'POST'])
@admin_required
def admin_panel():
    return 'hi, admin!'