from blog.models import Comment, Post


def test_index_loads(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Musings" in response.data


def test_index_shows_published_posts(client, sample_post, app):
    response = client.get("/")
    assert response.status_code == 200
    with app.app_context():
        post = Post.query.filter_by(slug="test-post").first()
        assert post.title.encode() in response.data


def test_view_post(client, sample_post, app):
    response = client.get("/post/test-post")
    assert response.status_code == 200
    assert b"Test Post" in response.data


def test_view_nonexistent_post_returns_404(client):
    response = client.get("/post/does-not-exist")
    assert response.status_code == 404


def test_submit_comment(client, sample_post, app):
    response = client.post(
        "/post/test-post",
        data={"author_name": "Alice", "body": "Great post!", "csrf_token": ""},
        follow_redirects=True,
    )
    # CSRF is disabled in testing config
    assert response.status_code == 200
    with app.app_context():
        post = Post.query.filter_by(slug="test-post").first()
        comment = Comment.query.filter_by(post_id=post.id).first()
        assert comment is not None
        assert comment.author_name == "Alice"
        # cleanup
        Comment.query.filter_by(post_id=post.id).delete()
        from blog import db
        db.session.commit()


def test_draft_post_hidden_from_public(client, app):
    from blog import db

    with app.app_context():
        draft = Post(title="Secret", slug="secret-draft", body="shh", published=False)
        db.session.add(draft)
        db.session.commit()

    response = client.get("/post/secret-draft")
    assert response.status_code == 404

    with app.app_context():
        Post.query.filter_by(slug="secret-draft").delete()
        db.session.commit()


def test_admin_can_view_draft(admin_client, app):
    from blog import db

    with app.app_context():
        draft = Post(
            title="Admin Draft", slug="admin-draft", body="visible to admin", published=False
        )
        db.session.add(draft)
        db.session.commit()

    response = admin_client.get("/post/admin-draft")
    assert response.status_code == 200

    with app.app_context():
        Post.query.filter_by(slug="admin-draft").delete()
        db.session.commit()
