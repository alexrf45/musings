from flask import render_template

from blog.errors import errors


@errors.app_errorhandler(404)
def not_found(e):
    return render_template("errors/404.html"), 404


@errors.app_errorhandler(500)
def internal_error(e):
    return render_template("errors/500.html"), 500


@errors.app_errorhandler(403)
def forbidden(e):
    return render_template("errors/403.html"), 403
