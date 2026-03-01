import os

from flask import flash, redirect, render_template, request, url_for
from flask_login import current_user, login_required, login_user, logout_user

from blog.auth import auth
from blog.auth.forms import LoginForm
from blog.models import AdminUser


@auth.route("/login", methods=["GET", "POST"])
def login():
    if current_user.is_authenticated:
        return redirect(url_for("posts.index"))

    form = LoginForm()
    if form.validate_on_submit():
        admin = AdminUser()
        if (
            form.username.data == os.environ.get("ADMIN_USERNAME", "admin")
            and admin.check_password(form.password.data)
        ):
            login_user(admin, remember=False)
            next_page = request.args.get("next")
            return redirect(next_page or url_for("posts.admin_list"))
        flash("Invalid username or password.", "danger")

    return render_template("auth/login.html", form=form)


@auth.route("/logout")
@login_required
def logout():
    logout_user()
    flash("You have been logged out.", "info")
    return redirect(url_for("posts.index"))
