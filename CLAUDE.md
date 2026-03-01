# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Flask blog ("Musings" by Sean Fontaine) with a PostgreSQL backend, served by Gunicorn inside a Docker container. Migrated from Hugo. CI/CD pushes a Docker image to Docker Hub on every push to `main`, with semantic versioning managed by release-please.

## Development Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Always use the `.venv` virtualenv — never install packages system-wide.

### Environment variables (copy `.env.example` to `.env`)

```bash
APP_ENV=development
DATABASE_URL=postgresql://musings:musings@localhost:5432/musings
SECRET_KEY=...
ADMIN_USERNAME=admin
ADMIN_PASSWORD=...
```

### Run locally (Flask dev server + Postgres via Docker Compose)

```bash
# Start Postgres only
docker compose up db

# In another terminal
source .venv/bin/activate
APP_ENV=development flask run --debug --port 5000
```

Or use the tmuxp session:
```bash
tmuxp load development/dev-tmuxp.yaml
```

### Database migrations

```bash
flask db migrate -m "describe the change"   # generate migration
flask db upgrade                             # apply migrations
```

### Run tests

```bash
APP_ENV=testing DATABASE_URL=postgresql://musings:musings@localhost:5432/test_musings \
  SECRET_KEY=test ADMIN_USERNAME=admin ADMIN_PASSWORD=testpassword \
  pytest tests/ -v
```

Tests use SQLite by default if DATABASE_URL falls back to the testing config default. The CI workflow spins up a real Postgres service container.

### Local Docker build

```bash
bash development/build.sh
```

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
    ├── posts/           # Admin: create.html, edit.html, list_admin.html
    └── errors/          # 403.html, 404.html, 500.html
```

Other root-level files: `wsgi.py` (Gunicorn entry), `config.py` (Dev/Testing/Production configs), `migrations/` (Flask-Migrate/Alembic).

### Authentication

Single admin user — credentials from env vars (`ADMIN_USERNAME`, `ADMIN_PASSWORD`). No database user table. `AdminUser` is an in-memory `UserMixin` with `id = 1`. Flask-Login manages the session.

### Blueprints and URL map

| Blueprint | Prefix | Key routes |
|-----------|--------|-----------|
| `auth`    | `/`    | `GET/POST /login`, `GET /logout` |
| `posts`   | `/`    | `GET /`, `GET/POST /post/<slug>`, `GET /admin/posts`, `GET/POST /admin/posts/create`, `GET/POST /admin/posts/<slug>/edit`, `POST /admin/posts/<slug>/delete`, `POST /admin/comments/<id>/delete` |
| `errors`  | —      | 403, 404, 500 handlers |

### Key design decisions

- **Markdown storage**: post body stored as raw Markdown in Postgres; rendered to HTML at display time via `mistune` (registered as `| markdown` Jinja filter). Code blocks highlighted by highlight.js (Gruvbox Dark Medium theme) on the client.
- **Editor**: EasyMDE loaded from CDN on create/edit pages only; includes autosave and side-by-side preview.
- **No server-side sessions**: Flask-Login cookie sessions; no session DB.
- **CSRF**: Flask-WTF on all forms; `WTF_CSRF_ENABLED = False` in testing config only.

### Build pipeline

Dockerfile: Python 3.13-slim, installs deps, copies `blog/`, `migrations/`, `wsgi.py`, `config.py`. Entrypoint runs `flask db upgrade` then starts Gunicorn (2 workers × 2 threads, port 8080), running as non-root `app` user.

| Workflow | Trigger | Action |
|----------|---------|--------|
| `ci.yml` | push/PR to `main` | ruff lint + pytest with Postgres service |
| `dev.yml` | push to `dev` | build + push `fonalex45/blog:dev` |
| `release-please.yml` | push to `main` | open/update release PR |
| `release.yml` | GitHub Release published | test → push semver tags + `latest` |

Semver managed by release-please; current version in `.github/release-please-manifest.json`. Start: `0.0.1-alpha`. Conventional commits drive version bumps.

### Nginx (`nginx/`)

Existing nginx config (unchanged) used in local Docker dev (non-TLS, port 8080).

## Infrastructure (`terraform/`)

Provisions a Hetzner Cloud server in Frankfurt, creates Cloudflare DNS records, and stores the SSH keypair in 1Password.

| Resource | Spec |
|---|---|
| Server | `cx22` — 2 vCPU AMD, 4 GB RAM, 40 GB root, Ubuntu 24.04, `fsn1` |
| Volume | 50 GB block storage mounted at `/opt/musings/data` |
| Firewall | Inbound: 22 (SSH), 80 (HTTP), 443 (HTTPS), ICMP |
| DNS | Cloudflare A + AAAA records (DNS-only, not proxied) |
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
├── docker-compose.yml          # db, app, nginx, certbot, watchtower
├── .env.enc                    # SOPS-encrypted env vars (committed to repo)
├── .env.example                # reference for required env vars
├── nginx/blog.conf             # nginx site config (domain templated by init script)
└── scripts/init-letsencrypt.sh # first-run: decrypt secrets, obtain cert, start stack
```

**Services:**
- `db` — Postgres 17, data on `/opt/musings/data/postgres`
- `app` — `fonalex45/blog:latest`, proxied by nginx on internal network
- `nginx` — terminates TLS (certs at `/opt/musings/data/certbot-certs`), logs to `/var/log/nginx/` for fail2ban
- `certbot` — auto-renews cert every 12 h via webroot challenge
- `watchtower` — polls Docker Hub every 5 min, pulls new `app` image automatically, notifies Slack

**Deployment steps on the server:**
```bash
cd /opt/musings
git clone <repo> .
# Place age private key at /root/.config/sops/age/keys.txt
bash deploy/scripts/init-letsencrypt.sh blog.fr3d.dev admin@fr3d.dev
```

The init script decrypts `deploy/.env.enc` (via SOPS + age), patches the nginx config, obtains the Let's Encrypt certificate, generates DH params, brings up the full stack, then shreds the plaintext `.env` on exit (even on failure).

**fail2ban jails configured on host (via cloud-init):**

| Jail | Log | Trigger | Ban |
|---|---|---|---|
| `sshd` | `/var/log/auth.log` | 3 failed SSH auths | 24 h |
| `musings-login` | `/var/log/nginx/access.log` | 10 POST /login in 5 min | 24 h |
| `nginx-limit-req` | `/var/log/nginx/access.log` | 10 × 429 in 2 min | 2 h |
| `nginx-botsearch` | `/var/log/nginx/access.log` | 10 × 4xx in 5 min | 1 h |

nginx also applies `limit_req zone=login burst=3` on `/login` (5 req/min) and `zone=global burst=60` globally, so rate-limiting fires before fail2ban as a first layer.

## Testing notes

- `conftest.py` app fixture is **session-scoped** but does NOT keep an `app_context` open between tests (opens context only for `db.create_all()` and `db.drop_all()`). This prevents `g`/Flask-Login state from bleeding between tests via a shared context.
- `sample_post` fixture creates and cleans up a test post within the session DB.
