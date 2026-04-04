# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

A Hugo static blog ("luvandre" by Sean Fontaine) with a custom Gruvbox dark theme, deployed to Cloudflare Pages. Posts are Markdown files committed to the `hugo` branch — pushing triggers an automatic Cloudflare Pages build.

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
date: "YYYY-MM-DD"
draft: false
summary: "One-line description shown in the featured sidebar and post list"
tags: ["tag1", "tag2"]
---
```

New post archetype: `hugo new posts/my-post.md`

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
    ├── index.html           # home page: featured sidebar + paginated list
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
- **Featured post**: Most recent post shown as sticky sidebar on home page; `.Summary` from front matter

## Deployment

**Cloudflare Pages** — auto-deploys on push to `hugo` branch.

GitHub Actions workflow: `.github/workflows/deploy.yml`
- Requires secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`
- Build: `hugo --minify`, output: `public/`

## Infrastructure (`terraform/`)

Provisions Cloudflare Pages project and DNS via Terraform.

**Providers:** `1Password/onepassword`, `cloudflare/cloudflare`

**Resources:**
- `cloudflare_pages_project.luvandre` — Pages project connected to GitHub repo
- `cloudflare_pages_domain.luvandre` — custom domain attachment
- `cloudflare_dns_record.blog_pages` — proxied CNAME to `luvandre.pages.dev`

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # fill in values
terraform init
terraform apply
```

## Notes

- The `featured-excerpt` preview uses a pure CSS `:has()` hover reveal — no JS required
- `hugo server -D` shows draft posts locally; they won't appear on the live site
- Hugo's built-in `.ReadingTime` is used (words ÷ 212 WPM)
- No comments, no database, no server — pure static
