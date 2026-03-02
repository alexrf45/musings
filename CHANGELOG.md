# Changelog

## [1.0.0-alpha](https://github.com/alexrf45/musings/compare/v0.0.1-alpha...v1.0.0-alpha) (2026-03-02)


### ⚠ BREAKING CHANGES

* **app:** jkjk I just need the image tag to be bumped to generate a new Docker build
* nginx:stable-alpine

### Features

* **app:** gh action error ([3c05733](https://github.com/alexrf45/musings/commit/3c05733387c24bd274e5bf6a3deddcd33d5f1d54))
* back to regular nginx image ([990e062](https://github.com/alexrf45/musings/commit/990e062a0bee9199d6a35f7e1334ee37c5b72cbb))
* **content:** hugo update to 0.139.0-r4 ([cbd6eda](https://github.com/alexrf45/musings/commit/cbd6eda5b8980708adb90c872ad93f90d773fdc6))
* **hugo:** Home Lab git repo link update ([7e94752](https://github.com/alexrf45/musings/commit/7e94752353443bc89653805d022896aa6f4c1403))
* **infra:** Cloudflare DNS, 1Password SSH key, merged init script ([a3f2735](https://github.com/alexrf45/musings/commit/a3f2735274ab28d3f4cefac04958c17fd9b65bf4))
* **post:** New poem: Sandstorm ([9a401db](https://github.com/alexrf45/musings/commit/9a401db449af5e7fc5e777788f041391dcf77806))


### Bug Fixes

* **article:** modified article ([e1795be](https://github.com/alexrf45/musings/commit/e1795be0d1ec783f6719c7bbcbfd161b7ae68054))
* **configs:** nginx config folder ([6636eb2](https://github.com/alexrf45/musings/commit/6636eb25a870fb24c53463fb5ea1a4d3707efad4))
* **dockerfile:** Dockerfile Port Expose changes ([861dfb7](https://github.com/alexrf45/musings/commit/861dfb7a1ae7780a2c8a103a26d056e0e1c063b5))
* **hugo:** incorrect path for writing ([79b7f35](https://github.com/alexrf45/musings/commit/79b7f352d8b949731744571ada9cd0b29676d3d5))
* **hugo:** main page card path issue ([f7610b9](https://github.com/alexrf45/musings/commit/f7610b988ac878dae6f57a24ba40d49d85d12b69))
* **networking:** container port mismatch ([67116c4](https://github.com/alexrf45/musings/commit/67116c48204609a1d095b92e3de3a1710635034b))
* **nginx:** added nginx config files ([e51f0c5](https://github.com/alexrf45/musings/commit/e51f0c5c4f797ecef8b4c24f243fa4ae76c90f9c))

## 0.0.1-alpha (initial)

Initial alpha release — Flask blog migrated from Hugo.

### Features

- Admin-only post management with Markdown editor (EasyMDE)
- Anonymous comments (name + text, no login required)
- PostgreSQL backend via SQLAlchemy + Flask-Migrate
- Gruvbox dark color scheme over Bootstrap 5
- Syntax highlighting via highlight.js (Gruvbox Dark Medium)
- Semantic versioning with release-please automation
