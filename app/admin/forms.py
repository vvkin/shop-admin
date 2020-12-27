from flask_wtf import FlaskForm
from wtforms import MultipleFileField, StringField, SelectField, TextAreaField \
    ,FloatField, SubmitField, IntegerField, ValidationError
from wtforms.validators import DataRequired, Length
from app.models import Product

class ProductCreationForm(FlaskForm):
    product_name = StringField('Product name', validators=[DataRequired(), Length(1, 40)])
    category_id = SelectField('Category', coerce=int, validators=[DataRequired()])
    supplier_id = SelectField('Supplier', coerce=int, validators=[DataRequired()])
    sku = StringField('SKU', validators=[DataRequired(), Length(1, 20)])
    unit_price = FloatField('Unit price', validators=[DataRequired()])
    discount = FloatField('Discount', default=0.0)
    units_in_stock = IntegerField('Units in stock')
    description = TextAreaField('Description')
    images = MultipleFileField('Add images')
    save = SubmitField('Save')
    save_and_continue = SubmitField('Save and add another')

    def validate_sku(self, field):
        if Product.get_by_sku(field.data.lower()):
            raise ValidationError('SKU has to be unique.')
    
    def validate_discount(self, field):
        if field.data < 0 or field.data > 1:
            raise ValidationError('Discount has to be from 0 to 1.')
    
    def validate_unit_price(self, field):
        if field.data < 0:
            raise ValidationError('Price has to be positive.')

class ProductFilterForm(FlaskForm):
    filter_mode = SelectField(
        'Filter by', choices= (
            (1, 'Name'),
            (2, 'Category')
        ), validators=[DataRequired()]
    )
    query = StringField('Query')
    reset = SubmitField('Reset')
    search = SubmitField('Search')

    def validate_query(self, field):
        if field and len(field.data) < 1 and self.search.data:
            raise ValidationError('Query has to include at leats one symbol.')

    
