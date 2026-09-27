# Project Overview

A Hugo static blog ("phr3d.net" by Sean Fontaine) with a custom Gruvbox dark theme, deployed to Cloudflare Pages. Posts are Markdown files committed to the `main` branch — pushing triggers an automatic Cloudflare Pages build.

## Development Setup

Install Hugo (>= 0.120.0):

```bash
# macOS
brew install hugo

# Arch / Debian
sudo pacman -S hugo  # or apt install hugo
```

Run local dev server:

```bash
hugo server -D        # includes drafts
hugo server           # published posts only
```

Build for production:

```bash
hugo --minify
```

## Content

Posts live in `content/posts/` as Markdown files. Front matter format:

```yaml
---
title: "Post Title"
date: 2026-09-27T08:27:30Z
draft: false
tags: [tag1, tag2]
---
```

## Architecture

```
hugo.toml                    # site config (baseURL, theme, params)
archetypes/default.md        # new post template
content/posts/               # all post markdown files
static/                      # static assets (favicon, images)
themes/musings/
├── hugo.toml                # theme metadata
├── assets/css/gruvbox.css   # Gruvbox dark design system (Bootstrap 5 override)
└── layouts/
    ├── baseof.html          # base template: head, navbar, footer, scripts
    ├── index.html           # home page: paginated post list
    ├── _default/
    │   ├── list.html        # /posts/ section list
    │   └── single.html      # individual post + highlight.js
    ├── partials/
    │   ├── head.html        # meta, CDN links, fingerprinted CSS
    │   ├── header.html      # sticky navbar with Alpine.js theme toggle
    │   ├── footer.html
    │   ├── post-card.html   # reusable post card partial
    │   └── pagination.html
    └── taxonomy/list.html   # /tags/<tag>/ pages
```

## Design System

The `musings` theme mirrors the Flask blog's Gruvbox design exactly:

- **Colors**: Gruvbox dark palette (`--gb-*` CSS variables); light mode variant on `html[data-bs-theme="light"]`
- **Typography**: Georgia serif for post body; system-ui sans-serif for headings and UI
- **Framework**: Bootstrap 5.3.3 (CDN), Bootstrap Icons 1.11.3 (CDN)
- **Interactivity**: Alpine.js v3 (CDN, `defer`) for dark/light mode toggle
- **Code highlighting**: highlight.js 11.9.0 (CDN), Gruvbox theme, swaps on light mode toggle via MutationObserver

## Deployment

**Cloudflare Pages** — auto-deploys on push to `main` branch.

GitHub Actions workflow: `.github/workflows/deploy.yml`
- Requires secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`
- Build: `hugo --minify`, output: `public/`

## Infrastructure (`terraform/`)

Provisions Cloudflare Pages project and DNS via Terraform.

**Providers:** `1Password/onepassword`, `cloudflare/cloudflare`
