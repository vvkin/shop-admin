import os
from flask import redirect, render_template, request, url_for, current_app, jsonify, send_from_directory
from flask_paginate import Pagination
from app.admin import admin
from app.admin.forms import ProductForm, ProductFilterForm
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

@admin.route('/products', methods=['GET', 'POST'])
@admin_required
def product_list():
    form = ProductFilterForm()

    if form.validate_on_submit():
        if form.search.data or form.query.data:
            data = {'value': form.filter_mode.data, 'query': form.query.data}
            pagination, products = Product.get_paginated_by(data, request.args)
            return render_template('admin/product_list.html', form=form,
                products=products, pagination=pagination
            )
        elif form.reset.data: return redirect(url_for('admin.product_list'))
    elif request.args.get('page'): # just next page with the same data:
        data = {'value': Product.last_option, 'query': Product.last_query}
        pagination, products = Product.get_paginated_by(data, request.args)
        return render_template('admin/product_list.html', form=form,
                products=products, pagination=pagination
            )
    pagination, products = Product.get_paginated_by({'value': 0}, request.args)
    return render_template('admin/product_list.html', form=form, 
        products=products, pagination=pagination
    )

@admin.route('/products/add', methods=['GET', 'POST'])
@admin_required
def product_add():
    form = ProductForm()
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

@admin.route('/products/update/<int:pk>', methods=['GET', 'POST'])
@admin_required
def product_update(pk):
    form = ProductForm()
    form.category_id.choices = Category.get_all_choices()
    form.supplier_id.choices = Supplier.get_all_choices()

    if form.validate_on_submit():
        Product.update_product(
            pk,
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
        else: return redirect(url_for('admin.product_update', pk=pk))
    
    return render_template('admin/product_update.html', form=form, pk=pk)

@admin.route('/products/delete/<int:pk>')
@admin_required
def product_delete(pk):
    Product.delete(pk)
    return {'success': True}

@admin.route('/products/_get/<int:pk>')
@admin_required
def product_get(pk):
    response = Product.get_json(pk)
    return response

@admin.route('/products/images/_get/<int:pk>')
def product_images(pk):
    img_path = f'products/{pk}'
    path = os.path.join(current_app.root_path, current_app.config['UPLOAD_FOLDER'], img_path)
    images = os.listdir(path) if os.path.exists(path) else []
    encoded_images = [url_for('static', filename=os.path.join(img_path, img)) for img in images]
    return jsonify(images=encoded_images)
