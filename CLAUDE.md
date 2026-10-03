# Project Overview

A Hugo static blog ("phr3d.net" by Sean Fontaine) using the [TeXify3](https://github.com/michaelneuper/hugo-texify3) theme (LaTeX-style, Gruvbox light/dark), deployed to Cloudflare Pages. Posts are Markdown files committed to the `main` branch — pushing triggers the GitHub Actions deploy.

## Development Setup

All tooling comes from the Nix flake: Hugo (extended), Dart Sass, Node, and Go.

```bash
nix develop                 # enter the dev shell
npm install                 # once: PostCSS deps used by the theme
hugo server -D              # dev server incl. drafts
hugo --minify               # production build -> public/
```

The theme is a Hugo module (`go.mod`), not a git submodule. Update it with `hugo mod get -u github.com/michaelneuper/hugo-texify3`.

## Content

Posts live in `content/posts/`, notes in `content/notes/`. Front matter format:

```yaml
---
title: "Post Title"
date: 2026-09-27T08:27:30Z
draft: false
tags: [tag1, tag2]
---
```

Other content:
- `content/_index.md` — home page: `{{< intro >}}` block (tagline, greeting, coffee button) and `{{< latest >}}`, beside the tag sidebar
- `content/search.md` — on-site search page (`layout: search`)
- `content/projects.md` — projects page (`layout: projects`); the list itself is `data/projects.toml`

## Architecture

```
hugo.toml                       # site config, menu, theme params, BMC widget
go.mod / go.sum                 # Hugo module import of hugo-texify3
package.json, postcss.config.js # PostCSS toolchain the theme's CSS pipeline requires
data/projects.toml              # repos listed on /projects/
assets/css/custom.css           # site CSS on top of the theme, fingerprinted; linked from partials/header.html
static/images/                  # logo + favicons (override the theme's same-named files)
layouts/
├── index.searchindex.json      # JSON search index (home output format "searchindex")
├── _default/
│   ├── list.html               # override: lists all regular pages (posts + notes)
│   ├── single.html             # override: notes get the post title/date/tags header
│   ├── search.html             # search page, client-side filter over search-index.json
│   └── projects.html           # projects page
├── shortcodes/
│   ├── intro.html              # home intro; style="terminal" (in use), "card", or "abstract"
│   ├── buymeacoffee.html       # Gruvbox Buy Me a Coffee button (wraps partials/buymeacoffee-button.html)
│   └── latest.html             # latest posts/notes list (home)
└── partials/
    ├── header.html             # override: logo, early dark-mode script (prevents light flash), site CSS link
    ├── footer.html             # override: copyright footer
    └── buymeacoffee-button.html # shared coffee button (intro + shortcode)
themes/musings/                 # legacy Bootstrap theme, no longer used
```

Theme overrides are copies of the upstream file with a minimal change and a `{{/* Override of ... */}}` header comment; re-check them when updating the theme.

## Design System

- **Colors**: Gruvbox via the theme's CSS variables (`--bg`, `--fg`, `--yellow`, ...); dark mode is the `darkmode` class on `<body>`
- **Typography**: theme's Latin Modern (LaTeX) fonts
- **Dark mode**: theme toggle + system preference, saved in `localStorage.darkMode`
- **Buy Me a Coffee**: floating widget in `[params.buymeacoffee]` (must load with `defer`, not `async`, because it only initialises on `DOMContentLoaded`), plus a Gruvbox-styled button on the home page via the `{{< buymeacoffee >}}` shortcode (URL in `params.buymeacoffeeURL`)

## Deployment

**GitHub Actions** (`.github/workflows/deploy.yml`) builds and deploys with wrangler:
- Push to `main` → production; pull requests → preview deployment on the PR branch
- Requires secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`
- Build: Hugo extended 0.164.0 + Go + Node (`npm ci`) + Dart Sass, `hugo --minify`, output: `public/`

The Cloudflare Pages project (Terraform) also has its own GitHub-connected build (`HUGO_VERSION` 0.148.0, no Dart Sass), which fails with this theme; the Actions deploy is the one that publishes.

## Infrastructure (`terraform/`)

Provisions Cloudflare Pages project and DNS via Terraform.

**Providers:** `1Password/onepassword`, `cloudflare/cloudflare`
