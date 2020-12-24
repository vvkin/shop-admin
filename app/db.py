import psycopg2
import click
import os
from flask import current_app, g
from flask.cli import with_appcontext


def get_db():
    if 'db' not in g:
        g.db = psycopg2.connect(current_app.config['DATABASE'])
        g.db.autocommit = True
    return g.db

def close_db(e=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()

def init_db():
    cursor = get_db().cursor()
    sql_dir = os.path.join(current_app.root_path, 'sql')
    for file_name in os.listdir(sql_dir):
        fhand = open(os.path.join(sql_dir, file_name),'r')
        cursor.execute(fhand.read())
        fhand.close()

def init_app(app):
    app.teardown_appcontext(close_db)
    app.cli.add_command(init_db_command)

@click.command('init-db')
@with_appcontext
def init_db_command():
    init_db()
    click.echo('Initialized the database.')
