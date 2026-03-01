def test_login_page_loads(client):
    response = client.get("/login")
    assert response.status_code == 200
    assert b"Login" in response.data


def test_login_wrong_password(client):
    response = client.post(
        "/login",
        data={"username": "admin", "password": "wrongpassword"},
        follow_redirects=True,
    )
    assert response.status_code == 200
    assert b"Invalid username or password" in response.data


def test_login_success(client):
    response = client.post(
        "/login",
        data={"username": "admin", "password": "testpassword"},
        follow_redirects=True,
    )
    assert response.status_code == 200


def test_admin_list_requires_login(client):
    response = client.get("/admin/posts", follow_redirects=False)
    assert response.status_code == 302
    assert "/login" in response.headers["Location"]


def test_admin_list_accessible_when_logged_in(admin_client):
    response = admin_client.get("/admin/posts")
    assert response.status_code == 200


def test_create_post_requires_login(client):
    response = client.get("/admin/posts/create", follow_redirects=False)
    assert response.status_code == 302
    assert "/login" in response.headers["Location"]


def test_logout(admin_client):
    response = admin_client.get("/logout", follow_redirects=True)
    assert response.status_code == 200
    # After logout, admin routes redirect to login
    response = admin_client.get("/admin/posts", follow_redirects=False)
    assert response.status_code == 302
