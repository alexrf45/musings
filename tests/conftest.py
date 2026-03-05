import os

import pytest

os.environ.setdefault("APP_ENV", "testing")
os.environ.setdefault("ADMIN_USERNAME", "admin")
os.environ.setdefault("ADMIN_PASSWORD", "testpassword")
os.environ.setdefault("SECRET_KEY", "test-secret-key")
os.environ.setdefault("API_SECRET_KEY", "test-api-secret-key")

from blog import create_app, db  # noqa: E402


@pytest.fixture(scope="session")
def app():
    application = create_app("testing")
    with application.app_context():
        db.create_all()
    yield application
    with application.app_context():
        db.drop_all()


@pytest.fixture()
def client(app):
    with app.test_client() as c:
        yield c


@pytest.fixture()
def admin_client(app):
    """Test client pre-authenticated as admin."""
    with app.test_client() as c:
        c.post(
            "/login",
            data={"username": "admin", "password": "testpassword"},
            follow_redirects=True,
        )
        yield c


@pytest.fixture()
def sample_post(app):
    """Create a published post for use in tests."""
    from blog.models import Post

    with app.app_context():
        post = Post(
            title="Test Post",
            slug="test-post",
            body="# Hello\n\nThis is a **test** post.",
            published=True,
        )
        db.session.add(post)
        db.session.commit()
        yield post
        db.session.delete(post)
        db.session.commit()
