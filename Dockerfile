FROM python:3.13-slim AS base

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  FLASK_APP=wsgi:app

# Install dependencies first for layer caching.
# Stub blog/__init__.py lets setuptools discover the package
# without copying the full source yet.
COPY pyproject.toml .
RUN mkdir -p blog && touch blog/__init__.py
RUN pip install --no-cache-dir .

COPY blog/        blog/
COPY migrations/  migrations/
COPY wsgi.py      wsgi.py
COPY entrypoint.sh entrypoint.sh

RUN addgroup --gid 1001 --system app && \
  adduser  --uid 1001 --system --gid 1001 --no-create-home app && \
  chown -R app:app /app && \
  chmod +x /app/entrypoint.sh

USER app

EXPOSE 8080/tcp

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/')" || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
