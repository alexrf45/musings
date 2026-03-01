from flask_wtf import FlaskForm
from wtforms import BooleanField, StringField, TextAreaField
from wtforms.validators import DataRequired, Length


class PostForm(FlaskForm):
    title = StringField(
        "Title",
        validators=[DataRequired(), Length(min=1, max=200)],
    )
    body = TextAreaField("Body", validators=[DataRequired()])
    published = BooleanField("Published", default=True)


class CommentForm(FlaskForm):
    author_name = StringField(
        "Name",
        validators=[DataRequired(), Length(min=1, max=100)],
    )
    body = TextAreaField("Comment", validators=[DataRequired(), Length(min=1, max=2000)])
