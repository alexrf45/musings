from flask import Blueprint

auth = Blueprint("auth", __name__, url_prefix="/")

from blog.auth import views  # noqa: E402, F401
