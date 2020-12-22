from flask import Flask
from config import config


def create_app(config_name: str):
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    return app