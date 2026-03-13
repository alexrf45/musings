import os
import re
from datetime import datetime, timezone

from flask_login import UserMixin

from blog import db, login_manager

# ---------------------------------------------------------------------------
# Admin (single user, credentials from environment)
# ---------------------------------------------------------------------------

class AdminUser(UserMixin):
    """Singleton admin user; credentials come from environment variables."""

    id = 1

    def check_password(self, password: str) -> bool:
        return password == os.environ.get("ADMIN_PASSWORD", "changeme")

    @property
    def username(self) -> str:
        return os.environ.get("ADMIN_USERNAME", "admin")


@login_manager.user_loader
def load_user(user_id: str):
    if int(user_id) == AdminUser.id:
        return AdminUser()
    return None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _now() -> datetime:
    return datetime.now(timezone.utc)


def _slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_]+", "-", text)
    text = re.sub(r"-{2,}", "-", text)
    return text


# ---------------------------------------------------------------------------
# Database models
# ---------------------------------------------------------------------------

class Post(db.Model):
    __tablename__ = "posts"

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    slug = db.Column(db.String(220), unique=True, nullable=False, index=True)
    body = db.Column(db.Text, nullable=False)
    published = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=_now, nullable=False)
    updated_at = db.Column(
        db.DateTime(timezone=True), default=_now, onupdate=_now, nullable=False
    )

    comments = db.relationship(
        "Comment",
        back_populates="post",
        lazy="dynamic",
        cascade="all, delete-orphan",
        order_by="Comment.created_at.asc()",
    )

    @classmethod
    def make_slug(cls, title: str) -> str:
        base = _slugify(title)
        slug = base
        n = 1
        while cls.query.filter_by(slug=slug).first():
            slug = f"{base}-{n}"
            n += 1
        return slug

    def __repr__(self) -> str:
        return f"<Post {self.slug!r}>"


class Comment(db.Model):
    __tablename__ = "comments"

    id = db.Column(db.Integer, primary_key=True)
    post_id = db.Column(
        db.Integer, db.ForeignKey("posts.id", ondelete="CASCADE"), nullable=False
    )
    author_name = db.Column(db.String(100), nullable=False)
    body = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime(timezone=True), default=_now, nullable=False)

    post = db.relationship("Post", back_populates="comments")

    def __repr__(self) -> str:
        return f"<Comment {self.id} by {self.author_name!r}>"
