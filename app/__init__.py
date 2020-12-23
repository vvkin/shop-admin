from flask import Flask
from flask_bootstrap import Bootstrap
from config import config
from app import db

bootstrap = Bootstrap()

def create_app(config_name: str) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    db.init_app(app)
    bootstrap.init_app(app)

    from .main import main
    app.register_blueprint(main)
    from .auth import auth
    app.register_blueprint(auth, url_prefix='/auth')

    return app