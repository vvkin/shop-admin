import functools
from flask import g, redirect, url_for


def login_required(view):
    @functools.wraps(view)
    def wrapped_view(**kwargs):
        if not g.current_user:
            return redirect(url_for('auth.login'))
        return view(**kwargs)
    return wrapped_view

def admin_required(view):
    @functools.wraps(view)
    def wrapped_view(**kwargs):
        if not g.current_user or not g.current_user['is_admin']:
            return redirect(url_for('main.index'))
        return view(**kwargs)
    return wrapped_view
