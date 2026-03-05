import hashlib
import hmac
import json
import time

import pytest

API_SECRET = "test-api-secret-key"
API_URL = "/api/v1/posts"


def _make_headers(payload_bytes, secret=API_SECRET, ts_offset=0):
    """Build the three auth headers for a valid request."""
    ts = str(int(time.time()) + ts_offset)
    sig = "sha256=" + hmac.new(
        secret.encode(), payload_bytes, hashlib.sha256
    ).hexdigest()
    return {
        "Authorization": f"Bearer {secret}",
        "X-Timestamp": ts,
        "X-Signature-256": sig,
        "Content-Type": "application/json",
    }


def _post(client, data, **header_overrides):
    payload = json.dumps(data).encode()
    headers = _make_headers(payload)
    headers.update(header_overrides)
    return client.post(API_URL, data=payload, headers=headers)


# ---------------------------------------------------------------------------
# Happy-path tests
# ---------------------------------------------------------------------------

def test_create_post(client, app):
    resp = _post(client, {"title": "API Test Post", "body": "Hello from API."})
    assert resp.status_code == 201
    body = resp.get_json()
    assert body["status"] == "created"
    slug = body["slug"]

    # Clean up
    from blog.models import Post, db
    with app.app_context():
        post = Post.query.filter_by(slug=slug).first()
        if post:
            db.session.delete(post)
            db.session.commit()


def test_upsert_post_updates_existing(client, app):
    from blog.models import Post, db

    with app.app_context():
        p = Post(title="Upsert Target", slug="upsert-target", body="Original body.", published=True)
        db.session.add(p)
        db.session.commit()

    try:
        resp = _post(client, {
            "title": "Upsert Target",
            "slug": "upsert-target",
            "body": "Updated body.",
        })
        assert resp.status_code == 200
        assert resp.get_json()["status"] == "updated"

        with app.app_context():
            post = Post.query.filter_by(slug="upsert-target").first()
            assert post.body == "Updated body."
    finally:
        with app.app_context():
            post = Post.query.filter_by(slug="upsert-target").first()
            if post:
                db.session.delete(post)
                db.session.commit()


def test_create_post_with_created_at(client, app):
    resp = _post(client, {
        "title": "Historical Post",
        "body": "Old content.",
        "created_at": "2020-01-01T00:00:00",
    })
    assert resp.status_code == 201
    slug = resp.get_json()["slug"]

    from blog.models import Post, db
    with app.app_context():
        post = Post.query.filter_by(slug=slug).first()
        assert post.created_at.year == 2020
        db.session.delete(post)
        db.session.commit()


# ---------------------------------------------------------------------------
# Validation tests
# ---------------------------------------------------------------------------

def test_missing_title_returns_400(client):
    resp = _post(client, {"body": "No title here."})
    assert resp.status_code == 400
    assert "title" in resp.get_json()["error"]


def test_missing_body_returns_400(client):
    resp = _post(client, {"title": "No body"})
    assert resp.status_code == 400


# ---------------------------------------------------------------------------
# Auth failure tests
# ---------------------------------------------------------------------------

def test_no_auth_header_returns_401(client):
    payload = json.dumps({"title": "X", "body": "Y"}).encode()
    ts = str(int(time.time()))
    sig = "sha256=" + hmac.new(API_SECRET.encode(), payload, hashlib.sha256).hexdigest()
    resp = client.post(API_URL, data=payload, headers={
        "X-Timestamp": ts,
        "X-Signature-256": sig,
        "Content-Type": "application/json",
    })
    assert resp.status_code == 401


def test_wrong_token_returns_401(client):
    resp = _post(
        client,
        {"title": "X", "body": "Y"},
        **{"Authorization": "Bearer wrong-token"},
    )
    assert resp.status_code == 401


def test_expired_timestamp_returns_401(client):
    payload = json.dumps({"title": "X", "body": "Y"}).encode()
    headers = _make_headers(payload, ts_offset=-400)  # 400 seconds in the past
    resp = client.post(API_URL, data=payload, headers=headers)
    assert resp.status_code == 401
    assert "expired" in resp.get_json()["error"]


def test_bad_signature_returns_401(client):
    payload = json.dumps({"title": "X", "body": "Y"}).encode()
    headers = _make_headers(payload)
    headers["X-Signature-256"] = "sha256=deadbeef"
    resp = client.post(API_URL, data=payload, headers=headers)
    assert resp.status_code == 401
    assert "signature" in resp.get_json()["error"]


def test_tampered_body_returns_401(client):
    """Signing one payload then sending a different one must fail."""
    original = json.dumps({"title": "Real", "body": "Real body."}).encode()
    headers = _make_headers(original)
    tampered = json.dumps({"title": "Tampered", "body": "Injected body."}).encode()
    resp = client.post(API_URL, data=tampered, headers=headers)
    assert resp.status_code == 401


def test_missing_timestamp_returns_401(client):
    payload = json.dumps({"title": "X", "body": "Y"}).encode()
    headers = _make_headers(payload)
    del headers["X-Timestamp"]
    resp = client.post(API_URL, data=payload, headers=headers)
    assert resp.status_code == 401
