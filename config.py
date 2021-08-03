import os

POSTGRES_HOST = os.environ.get('POSTGRES_HOST')
POSTGRES_DB= os.environ.get('POSTGRES_DB')

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'secret'

class DevelopmentConfig(Config):
    DEBUG = True
    DATABASE = {
        'host': POSTGRES_HOST,
        'dbname': POSTGRES_DB,
        'user': os.environ.get('PYSHOP_USER'),
        'password': os.environ.get('PYSHOP_PASSWORD'),
    }
    ADMIN_DATABASE = {
        'host': POSTGRES_HOST,
        'dbname': POSTGRES_DB,
        'user': os.environ.get('POSTGRES_USER'),
        'password': os.environ.get('POSTGRES_PASSWORD'),
    }

class TestingConfig(Config):
    TESTING = True

config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
