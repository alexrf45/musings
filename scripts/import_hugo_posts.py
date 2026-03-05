#!/usr/bin/env python3
"""One-time importer: sync all Hugo posts in app/content/ to the blog API.

Usage:
    API_SECRET_KEY=<key> python scripts/import_hugo_posts.py --url https://example.com
"""

import argparse
import os
import sys
from pathlib import Path

# Allow running from repo root without installing
sys.path.insert(0, str(Path(__file__).parent))

from sync_posts import parse_hugo_file, sign_and_post


def main():
    parser = argparse.ArgumentParser(description="Import all Hugo posts into the Flask blog API.")
    parser.add_argument("--url", required=True, help="Base URL of the blog (e.g. https://example.com)")
    parser.add_argument("--content-dir", default="app/content", help="Path to Hugo content directory")
    parser.add_argument("--dry-run", action="store_true", help="Parse files but do not POST")
    args = parser.parse_args()

    secret = os.environ.get("API_SECRET_KEY", "")
    if not secret and not args.dry_run:
        print("ERROR: API_SECRET_KEY not set", file=sys.stderr)
        sys.exit(1)

    content_dir = Path(args.content_dir)
    if not content_dir.exists():
        print(f"ERROR: content directory not found: {content_dir}", file=sys.stderr)
        sys.exit(1)

    posts = sorted(content_dir.glob("*.md"))
    if not posts:
        print(f"No .md files found in {content_dir}")
        return

    base_url = args.url.rstrip("/")
    api_url = f"{base_url}/api/v1/posts"
    errors = 0

    for md_file in posts:
        try:
            payload = parse_hugo_file(md_file)
        except Exception as e:
            print(f"SKIP {md_file.name}: parse error — {e}")
            errors += 1
            continue

        if args.dry_run:
            print(f"DRY-RUN {md_file.name}: slug={payload['slug']!r} title={payload['title']!r}")
            continue

        resp = sign_and_post(api_url, secret, payload)
        status = "OK" if resp.ok else "FAIL"
        print(f"[{status}] {md_file.name}: HTTP {resp.status_code} — {resp.text}")
        if not resp.ok:
            errors += 1

    if errors:
        print(f"\n{errors} error(s) occurred.", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"\nDone. Processed {len(posts)} file(s).")


if __name__ == "__main__":
    main()
