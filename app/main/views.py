from flask import render_template, url_for, redirect
from . import main
from .. import db


@main.route('/', methods=['GET', 'POST'])
def index():
    return render_template('home.html')
