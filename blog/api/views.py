import hashlib
import hmac
import time
from datetime import datetime, timezone

from flask import current_app, jsonify, request

from blog.api import api_bp
from blog.models import Post, db


def _verify_request():
    """Returns error response tuple, or None if all checks pass."""
    # 1. Bearer token
    auth = request.headers.get('Authorization', '')
    if not auth.startswith('Bearer '):
        return jsonify({'error': 'Unauthorized'}), 401
    token = auth[7:]
    secret = current_app.config.get('API_SECRET_KEY', '')
    if not secret or not hmac.compare_digest(token, secret):
        return jsonify({'error': 'Unauthorized'}), 401

    # 2. Timestamp replay protection (5-minute window)
    ts_header = request.headers.get('X-Timestamp', '')
    try:
        if abs(time.time() - int(ts_header)) > 300:
            return jsonify({'error': 'Request expired'}), 401
    except (ValueError, TypeError):
        return jsonify({'error': 'Missing or invalid timestamp'}), 401

    # 3. HMAC-SHA256 signature over raw body
    body = request.get_data()
    expected = 'sha256=' + hmac.new(
        secret.encode(), body, hashlib.sha256
    ).hexdigest()
    sig = request.headers.get('X-Signature-256', '')
    if not hmac.compare_digest(sig, expected):
        return jsonify({'error': 'Invalid signature'}), 401

    return None


@api_bp.route('/posts', methods=['POST'])
def upsert_post():
    err = _verify_request()
    if err:
        return err

    data = request.get_json(silent=True) or {}

    title = data.get('title', '').strip()
    body = data.get('body', '').strip()
    if not title or not body:
        return jsonify({'error': 'title and body are required'}), 400

    published = bool(data.get('published', True))
    created_at = data.get('created_at')

    slug = data.get('slug') or Post.make_slug(title)

    existing = Post.query.filter_by(slug=slug).first()
    if existing:
        existing.title = title
        existing.body = body
        existing.published = published
        existing.updated_at = datetime.now(timezone.utc)
        db.session.commit()
        return jsonify({'status': 'updated', 'slug': slug}), 200
    else:
        post = Post(title=title, slug=slug, body=body, published=published)
        if created_at:
            post.created_at = datetime.fromisoformat(created_at)
        db.session.add(post)
        db.session.commit()
        return jsonify({'status': 'created', 'slug': post.slug}), 201
