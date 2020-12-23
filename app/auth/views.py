from flask import session, g, request, redirect, render_template
from app.auth import auth
from app.decorators import login_required
from app.models import User
from app.auth.forms import LoginForm, RegistrationForm


@auth.route('/register', methods=['GET', 'POST'])
def register():
    form = RegistrationForm()
    if form.validate_on_submit():
        User.save_user(
            email=form.email.data.lower(),
            username=form.username.data,
            password=form.password.data
        )
        return redirect(url_for('auth.login'))
    return render_template('auth/register.html', form=form)

@auth.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        email = form.email.data.lower()
        if User.is_valid_login(email, form.password.data):
            session['user_email'] = email
            return redirect(url_for('main.index'))
        flash('Invalid email or password.')
    return render_template('auth/login.html', form=form)

@auth.route('/logout')
@login_required
def logout():
    session.pop('user_email')
    flash('You have been successfully logged out', category='success')
    return redirect(url_for('main.index'))

@auth.before_app_request
def load_logged_in_user():
    user_email = session.get('user_email')
    if user_email is None:
        g.current_user = None
    else: g.current_user = User.get_by_email(user_email)
