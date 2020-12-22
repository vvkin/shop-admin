from flask import render_template, url_for, redirect
from app.db import get_db
from app.main import main


@main.route('/', methods=['GET', 'POST'])
def index():
    return render_template('home.html')
