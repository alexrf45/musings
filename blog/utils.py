from flask import request


def is_htmx() -> bool:
    return request.headers.get("HX-Request") == "true"
