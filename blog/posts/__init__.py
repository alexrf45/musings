from flask import Blueprint

posts = Blueprint("posts", __name__)

from blog.posts import views  # noqa: E402, F401
