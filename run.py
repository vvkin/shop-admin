import os
from app import create_app

if __name__ == '__main__':
    app = create_app(os.environ.get('APP_CONFIG') or 'default')
    app.run()