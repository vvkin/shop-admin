from flask import Flask
from config import config
from app import db


def create_app(config_name: str) -> Flask:
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    db.init_app(app)

    from .main import main
    app.register_blueprint(main)

    return app