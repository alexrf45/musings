#!/usr/bin/env python3
"""Sync a single Hugo markdown file to the blog API.

Usage:
    API_SECRET_KEY=<key> BLOG_URL=https://example.com python scripts/sync_posts.py path/to/post.md
"""

import hashlib
import hmac
import json
import os
import re
import sys
import time
from pathlib import Path

import requests
import yaml


def parse_hugo_file(path: Path) -> dict:
    """Parse YAML front matter and body from a Hugo markdown file."""
    text = path.read_text(encoding="utf-8")

    # Split on the YAML front matter delimiters
    match = re.match(r'^---\s*\n(.*?)\n---\s*\n(.*)', text, re.DOTALL)
    if not match:
        raise ValueError(f"No YAML front matter found in {path}")

    front_matter = yaml.safe_load(match.group(1))
    body = match.group(2).strip()

    title = front_matter.get("title", "")
    date = front_matter.get("date")
    draft = front_matter.get("draft", False)

    # Derive slug: prefer explicit 'id', then stem of filename
    slug = front_matter.get("id") or _slugify(path.stem)

    created_at = None
    if date:
        # Ensure ISO 8601 string
        created_at = date.isoformat() if hasattr(date, "isoformat") else str(date)

    return {
        "title": title,
        "slug": slug,
        "body": body,
        "published": not draft,
        "created_at": created_at,
    }


def _slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_]+", "-", text)
    text = re.sub(r"-{2,}", "-", text)
    return text


def sign_and_post(url: str, secret: str, payload: dict) -> requests.Response:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    ts = str(int(time.time()))
    sig = "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()

    headers = {
        "Authorization": f"Bearer {secret}",
        "X-Timestamp": ts,
        "X-Signature-256": sig,
        "Content-Type": "application/json",
    }
    return requests.post(url, data=body, headers=headers, timeout=30)


def sync_file(file_path: str) -> None:
    secret = os.environ.get("API_SECRET_KEY", "")
    if not secret:
        print("ERROR: API_SECRET_KEY not set", file=sys.stderr)
        sys.exit(1)

    base_url = os.environ.get("BLOG_URL", "").rstrip("/")
    if not base_url:
        print("ERROR: BLOG_URL not set", file=sys.stderr)
        sys.exit(1)

    path = Path(file_path)
    if not path.exists():
        print(f"ERROR: file not found: {file_path}", file=sys.stderr)
        sys.exit(1)

    payload = parse_hugo_file(path)
    url = f"{base_url}/api/v1/posts"

    resp = sign_and_post(url, secret, payload)
    print(f"{path.name}: HTTP {resp.status_code} — {resp.text}")

    if not resp.ok:
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file.md> [file.md ...]", file=sys.stderr)
        sys.exit(1)

    for arg in sys.argv[1:]:
        sync_file(arg)
