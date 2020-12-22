import os


class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'secret'

class DevelopmentConfig(Config):
    DEBUG = True
    DATABASE = os.environ.get('DEV_DATABASE')

class TestingConfig(Config):
    TESTING = True

config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
