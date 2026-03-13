import os

import mistune
from flask import Flask
from flask_login import LoginManager
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy
from flask_wtf.csrf import CSRFProtect

from blog.config import config

db = SQLAlchemy()
migrate = Migrate()
login_manager = LoginManager()
csrf = CSRFProtect()
login_manager.login_view = "auth.login"
login_manager.login_message = "Please log in to access this page."
login_manager.login_message_category = "warning"

_md = mistune.create_markdown(
    plugins=["strikethrough", "table", "url"],
    escape=True,
)


def create_app(config_name: str | None = None) -> Flask:
    if config_name is None:
        config_name = os.environ.get("APP_ENV", "default")

    app = Flask(__name__)
    app.config.from_object(config[config_name])

    db.init_app(app)
    migrate.init_app(app, db)
    login_manager.init_app(app)
    csrf.init_app(app)

    # Jinja filter: {{ post.body | markdown | safe }}
    app.jinja_env.filters["markdown"] = _md

    from blog.api import api_bp
    from blog.auth import auth as auth_blueprint
    from blog.errors import errors as errors_blueprint
    from blog.posts import posts as posts_blueprint

    app.register_blueprint(auth_blueprint)
    app.register_blueprint(posts_blueprint)
    app.register_blueprint(errors_blueprint)
    app.register_blueprint(api_bp)
    csrf.exempt(api_bp)

    with app.app_context():
        # Import models so Flask-Migrate can detect them
        from blog import models  # noqa: F401

    return app
