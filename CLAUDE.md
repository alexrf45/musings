# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Flask blog ("Musings" by Sean Fontaine) with a PostgreSQL backend, served by Gunicorn inside a Docker container. Migrated from Hugo. CI/CD pushes a Docker image to Docker Hub on every push to `main`, with semantic versioning managed by release-please.

## Development Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

Always use the `.venv` virtualenv — never install packages system-wide.
Dependencies and tool config live in `pyproject.toml`. Runtime deps are under `[project.dependencies]`; dev/test deps under `[project.optional-dependencies] dev`.

### Environment variables (copy `.env.example` to `.env`)

```
APP_ENV=development
DATABASE_URL=postgresql://musings:musings@localhost:5432/musings
SECRET_KEY=...
ADMIN_USERNAME=admin
ADMIN_PASSWORD=...
```

### Slash commands

| Command         | Action                                      |
| --------------- | ------------------------------------------- |
| `/dev`          | Start full dev stack or Flask dev server    |
| `/test`         | Run pytest against local Postgres           |
| `/migrate`      | Generate and apply a DB migration           |
| `/docker-build` | Build Docker image locally                  |

### Notes

- Docker debugging: check port conflicts, Alpine package availability (edge/community), and binary renames in newer package versions.
- UI changes: test the full interaction flow (modals, alerts, delete buttons) after each change — HTMX integration can break existing patterns subtly.
- Git commits may require SSH signing via 1Password agent. If signing fails, inform the user — they need to authenticate manually.
- Tests: CI uses a real Postgres service container; locally requires Postgres running.

## Architecture

### Flask package structure (`blog/`)

```
blog/
├── __init__.py          # Application factory: create_app()
├── models.py            # Post, Comment (SQLAlchemy), AdminUser (Flask-Login)
├── auth/                # Blueprint: /login, /logout
│   ├── forms.py         # LoginForm
│   └── views.py
├── posts/               # Blueprint: public + admin post/comment routes
│   ├── forms.py         # PostForm, CommentForm
│   └── views.py
├── errors/              # Blueprint: 404, 403, 500 handlers
├── static/css/gruvbox.css   # Bootstrap 5 Gruvbox dark override
└── templates/
    ├── base.html        # Bootstrap 5 + Bootstrap Icons + Gruvbox CSS
    ├── index.html       # Paginated post list
    ├── post.html        # Post view + highlight.js + anonymous comment form
    ├── auth/login.html
    ├── partials/        # comment.html, comment_form.html, comment_posted.html
    ├── posts/           # Admin: create.html, edit.html, list_admin.html
    └── errors/          # 403.html, 404.html, 500.html
```

Other root-level files: `wsgi.py` (Gunicorn entry), `config.py` (Dev/Testing/Production configs), `migrations/` (Flask-Migrate/Alembic).
`blog/utils.py` — `is_htmx()` helper (checks `HX-Request` header); used in views to branch HTMX vs standard responses.

### Authentication

Single admin user — credentials from env vars (`ADMIN_USERNAME`, `ADMIN_PASSWORD`). No database user table. `AdminUser` is an in-memory `UserMixin` with `id = 1`. Flask-Login manages the session.

### Blueprints and URL map

| Blueprint | Prefix | Key routes                                                                                                                                                                                       |
| --------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `auth`    | `/`    | `GET/POST /login`, `GET /logout`                                                                                                                                                                 |
| `posts`   | `/`    | `GET /`, `GET/POST /post/<slug>`, `GET /admin/posts`, `GET/POST /admin/posts/create`, `GET/POST /admin/posts/<slug>/edit`, `POST /admin/posts/<slug>/delete`, `POST /admin/comments/<id>/delete` |
| `errors`  | —      | 403, 404, 500 handlers                                                                                                                                                                           |

### Key design decisions

- **Markdown storage**: post body stored as raw Markdown in Postgres; rendered to HTML at display time via `mistune` (registered as `| markdown` Jinja filter). Code blocks highlighted by highlight.js (Gruvbox Dark Medium theme) on the client.
- **Editor**: EasyMDE loaded from CDN on create/edit pages only; includes autosave and side-by-side preview.
- **No server-side sessions**: Flask-Login cookie sessions; no session DB.
- **CSRF**: Flask-WTF on all forms; `WTF_CSRF_ENABLED = False` in testing config only.
- **HTMX**: version **1.9.12** (pinned — 2.x was downgraded due to Bootstrap modal JS interference). `is_htmx()` in `blog/utils.py` detects HTMX requests. Delete flows use `hx-confirm` (native browser dialog) + server-side `HX-Redirect` header; no Bootstrap modals used for destructive actions.

### Build pipeline

Dockerfile: Python 3.13-slim, installs deps, copies `blog/`, `migrations/`, `wsgi.py`, `config.py`. Entrypoint runs `flask db upgrade` then starts Gunicorn (2 workers × 2 threads, port 8080), running as non-root `app` user.

| Workflow             | Trigger                  | Action                                   |
| -------------------- | ------------------------ | ---------------------------------------- |
| `ci.yml`             | push/PR to `main`        | ruff lint + pytest with Postgres service |
| `dev.yml`            | push to `dev`            | build + push `fonalex45/blog:dev`        |
| `release-please.yml` | push to `main`           | open/update release PR                   |
| `release.yml`        | GitHub Release published | test → push semver tags + `latest`       |

Semver managed by release-please; current version in `.github/release-please-manifest.json`. Start: `0.0.1-alpha`. Conventional commits drive version bumps.

## Infrastructure (`terraform/`)

Provisions a Hetzner Cloud server in Frankfurt, creates Cloudflare DNS records, and stores the SSH keypair in 1Password.

| Resource    | Spec                                                                           |
| ----------- | ------------------------------------------------------------------------------ |
| Server      | `cx22` — 2 vCPU AMD, 4 GB RAM, 40 GB root, Ubuntu 24.04, `fsn1`                |
| Volume      | 50 GB block storage mounted at `/opt/musings/data`                             |
| Firewall    | Inbound: 22 (SSH), 80 (HTTP), 443 (HTTPS), ICMP                                |
| DNS         | Cloudflare A + AAAA records (DNS-only, not proxied)                            |
| SSH keypair | ED25519 generated by Terraform; private key stored in 1Password, never on disk |

**Providers:** `hetznercloud/hcloud`, `hashicorp/tls`, `1Password/onepassword`, `cloudflare/cloudflare`

**Prerequisites:**

- A 1Password service account token with read/write access to your infra vault
- A Cloudflare API token (stored as the `credential` field of a 1Password item)
- The Cloudflare Zone ID for your domain

**First apply:**

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # fill in values
terraform init
terraform apply
```

After `apply`, the SSH private key is in 1Password under `${server_name}-ssh-key`. Use the 1Password SSH agent to connect — the key is never written to disk.

**cloud-init installs:** Docker Engine + docker-compose plugin, tmux, vim, fail2ban, ufw.
After `terraform apply`, the null_resource waits for cloud-init to finish, then mounts the volume.

## Production deployment (`deploy/`)

```
deploy/
├── docker-compose.yml       # db, app, traefik, watchtower
├── .env.enc                 # SOPS-encrypted env vars (committed to repo)
├── traefik/traefik.yml      # Traefik static config (ACME, entrypoints, providers)
└── scripts/init.sh          # first-run: decrypt secrets, prep dirs, start stack
```

**Services:**

- `db` — Postgres 17, data on `/opt/musings/data/postgres`
- `app` — `fonalex45/blog:latest`, proxied by Traefik on internal network
- `traefik` — terminates TLS via ACME (certs at `/opt/musings/data/traefik/acme.json`), logs to `/var/log/traefik/` for fail2ban, handles HTTP→HTTPS redirect
- `watchtower` — polls Docker Hub every 5 min, pulls new `app` image automatically, notifies Slack

**Deployment steps on the server:**

```bash
cd /opt/musings
git clone <repo> .
# Place age private key at /root/.config/sops/age/keys.txt
bash deploy/scripts/init.sh
```

The init script decrypts `deploy/.env.enc` (via SOPS + age), creates `/opt/musings/data/traefik/acme.json` (chmod 600), brings up the full stack, then shreds the plaintext `.env` on exit (even on failure). Traefik obtains the TLS certificate automatically via ACME HTTP-01 challenge.

**fail2ban jails configured on host (via cloud-init):**

| Jail              | Log                           | Trigger                 | Ban  |
| ----------------- | ----------------------------- | ----------------------- | ---- |
| `sshd`            | `/var/log/auth.log`           | 3 failed SSH auths      | 24 h |
| `musings-login`   | `/var/log/traefik/access.log` | 10 POST /login in 5 min | 24 h |
| `nginx-limit-req` | `/var/log/traefik/access.log` | 10 × 429 in 2 min       | 2 h  |
| `nginx-botsearch` | `/var/log/traefik/access.log` | 10 × 4xx in 5 min       | 1 h  |

Traefik applies rate limiting via middleware labels: 30 req/s (burst 60) globally, 5 req/min (burst 3) on `/login`.

**Manual steps on existing server (cloud-init already ran):**

```bash
sed -i 's|/var/log/nginx/access.log|/var/log/traefik/access.log|g' /etc/fail2ban/jail.local
systemctl restart fail2ban
mkdir -p /var/log/traefik
# Edit /etc/logrotate.d/nginx-docker: change path + replace postrotate with copytruncate
```

## Testing notes

- `conftest.py` app fixture is **session-scoped** but does NOT keep an `app_context` open between tests (opens context only for `db.create_all()` and `db.drop_all()`). This prevents `g`/Flask-Login state from bleeding between tests via a shared context.
- `sample_post` fixture creates and cleans up a test post within the session DB.
