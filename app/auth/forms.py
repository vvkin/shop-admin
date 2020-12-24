from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, ValidationError
from wtforms.validators import DataRequired, Email, Regexp, EqualTo, Length
from app.models import User
import phonenumbers


class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired(), Length(5)])
    submit = SubmitField('Log in')

class RegistrationForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email(), Length(1, 255)])
    first_name = StringField('First Name', validators=[DataRequired(), Length(1, 60)])
    second_name = StringField('Second Name', validators=[DataRequired(), Length(1, 60)])
    phone = StringField('Mobile Phone', validators=[DataRequired(), Length(1, 24)])
    password = PasswordField('Password', validators=[Length(5),
        DataRequired(), EqualTo('password2', message='Passwords must match.')])
    password2 = PasswordField('Confirm password', validators=[Length(5), DataRequired()])
    submit = SubmitField('Register')

    def validate_email(self, field):
        if User.get_by_email(field.data.lower()):
            raise ValidationError('Email already registered.')
    
    def validate_phone(self, phone):
        try:
            phone_number = phonenumbers.parse(phone.data)
            if not phonenumbers.is_valid_number(phone_number):
                raise ValueError()
        except (phonenumbers.phonenumberutil.NumberParseException, ValueError):
            raise ValidationError('Invalid phone number')

