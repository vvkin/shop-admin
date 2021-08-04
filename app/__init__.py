from os import path

from flask import Flask
from flask_bootstrap import Bootstrap
from config import config
from app import db

bootstrap = Bootstrap()

def create_app(config_name: str) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    app.config['UPLOAD_PATH'] = path.join(app.root_path, 'static')
    
    db.init_app(app)
    bootstrap.init_app(app)

    from .main import main
    app.register_blueprint(main)
    from .auth import auth
    app.register_blueprint(auth, url_prefix='/auth')
    from .admin import admin
    app.register_blueprint(admin, url_prefix='/admin')

    return app