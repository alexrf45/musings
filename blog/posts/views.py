from flask import abort, flash, make_response, redirect, render_template, request, url_for
from flask_login import current_user, login_required

from blog import db
from blog.models import Comment, Post
from blog.posts import posts
from blog.posts.forms import CommentForm, PostForm
from blog.utils import is_htmx

# ---------------------------------------------------------------------------
# Public routes
# ---------------------------------------------------------------------------

@posts.route("/")
def index():
    page = request.args.get("page", 1, type=int)
    per_page = 20
    featured = (
        Post.query.filter_by(published=True, featured=True)
        .order_by(Post.created_at.desc())
        .first()
    )
    pagination = (
        Post.query.filter_by(published=True)
        .order_by(Post.created_at.desc())
        .paginate(page=page, per_page=per_page, error_out=False)
    )
    return render_template("index.html", pagination=pagination, featured=featured)


@posts.route("/post/<slug>", methods=["GET", "POST"])
def view_post(slug: str):
    post = Post.query.filter_by(slug=slug).first_or_404()
    if not post.published and not current_user.is_authenticated:
        abort(404)

    form = CommentForm()
    if form.validate_on_submit():
        comment = Comment(
            post_id=post.id,
            author_name=form.author_name.data.strip(),
            body=form.body.data.strip(),
        )
        db.session.add(comment)
        db.session.commit()

        if is_htmx():
            return render_template(
                "partials/comment_posted.html",
                comment=comment,
                post=post,
                form=CommentForm(),
                comment_count=post.comments.count(),
            )

        flash("Your comment has been posted.", "success")
        return redirect(url_for("posts.view_post", slug=slug) + "#comments")

    # Validation failed on an HTMX POST — return form partial with errors
    if is_htmx():
        return render_template(
            "partials/comment_form.html",
            form=form,
            post=post,
        )

    comments = post.comments.order_by(Comment.created_at.asc()).all()
    return render_template("post.html", post=post, form=form, comments=comments)


# ---------------------------------------------------------------------------
# Admin routes
# ---------------------------------------------------------------------------

@posts.route("/admin/posts")
@login_required
def admin_list():
    all_posts = Post.query.order_by(Post.created_at.desc()).all()
    return render_template("posts/list_admin.html", posts=all_posts)


@posts.route("/admin/posts/create", methods=["GET", "POST"])
@login_required
def create_post():
    form = PostForm()
    if form.validate_on_submit():
        slug = Post.make_slug(form.title.data)
        post = Post(
            title=form.title.data.strip(),
            slug=slug,
            body=form.body.data,
            published=form.published.data,
            featured=form.featured.data,
        )
        db.session.add(post)
        db.session.commit()
        flash(f'"{post.title}" created.', "success")
        return redirect(url_for("posts.view_post", slug=post.slug))
    return render_template("posts/create.html", form=form)


@posts.route("/admin/posts/<slug>/edit", methods=["GET", "POST"])
@login_required
def edit_post(slug: str):
    post = Post.query.filter_by(slug=slug).first_or_404()
    form = PostForm(obj=post)
    if form.validate_on_submit():
        post.title = form.title.data.strip()
        post.body = form.body.data
        post.published = form.published.data
        post.featured = form.featured.data
        db.session.commit()
        flash(f'"{post.title}" updated.', "success")
        return redirect(url_for("posts.view_post", slug=post.slug))
    return render_template("posts/edit.html", form=form, post=post)


@posts.route("/admin/posts/<slug>/delete", methods=["POST"])
@login_required
def delete_post(slug: str):
    post = Post.query.filter_by(slug=slug).first_or_404()
    title = post.title
    db.session.delete(post)
    db.session.commit()
    flash(f'"{title}" deleted.', "info")
    if is_htmx():
        response = make_response("", 204)
        response.headers["HX-Redirect"] = url_for("posts.admin_list")
        return response
    return redirect(url_for("posts.admin_list"))


@posts.route("/admin/comments/<int:comment_id>/delete", methods=["POST"])
@login_required
def delete_comment(comment_id: int):
    comment = Comment.query.get_or_404(comment_id)
    slug = comment.post.slug
    db.session.delete(comment)
    db.session.commit()

    if is_htmx():
        return "", 200

    flash("Comment deleted.", "info")
    return redirect(url_for("posts.view_post", slug=slug) + "#comments")
