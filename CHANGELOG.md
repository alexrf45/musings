# Changelog

## [3.1.0-alpha](https://github.com/alexrf45/musings/compare/v3.0.0-alpha...v3.1.0-alpha) (2026-03-15)


### Features

* dark/light mode, sticky featured poem sidebar, reworked CI pipeline ([85a051a](https://github.com/alexrf45/musings/commit/85a051ad44c0e7c145be48fbcbc9d70b55182d70))


### Bug Fixes

* **ci:** chain semver Docker push directly off release-please outputs ([cb538b8](https://github.com/alexrf45/musings/commit/cb538b8d773961b60633c485ddc508e7c29c21da))

## [3.0.0-alpha](https://github.com/alexrf45/musings/compare/v2.0.0-alpha...v3.0.0-alpha) (2026-03-13)


### ⚠ BREAKING CHANGES

* **app:** jkjk I just need the image tag to be bumped to generate a new Docker build
* nginx:stable-alpine

### Features

* **api:** add POST /api/v1/posts endpoint for Hugo→Flask sync ([81319ef](https://github.com/alexrf45/musings/commit/81319ef9e7505d0310e2e6419ea8dbfb405f5deb))
* **app:** gh action error ([3c05733](https://github.com/alexrf45/musings/commit/3c05733387c24bd274e5bf6a3deddcd33d5f1d54))
* back to regular nginx image ([990e062](https://github.com/alexrf45/musings/commit/990e062a0bee9199d6a35f7e1334ee37c5b72cbb))
* **content:** hugo update to 0.139.0-r4 ([cbd6eda](https://github.com/alexrf45/musings/commit/cbd6eda5b8980708adb90c872ad93f90d773fdc6))
* **hugo:** Home Lab git repo link update ([7e94752](https://github.com/alexrf45/musings/commit/7e94752353443bc89653805d022896aa6f4c1403))
* **infra:** Cloudflare DNS, 1Password SSH key, merged init script ([a3f2735](https://github.com/alexrf45/musings/commit/a3f2735274ab28d3f4cefac04958c17fd9b65bf4))
* **luvandre:** rebrand, featured poems, Alpine.js reactive UI ([c881b36](https://github.com/alexrf45/musings/commit/c881b368b0539ecd59428647466103ef6e3f909a))
* **post:** New poem: Sandstorm ([9a401db](https://github.com/alexrf45/musings/commit/9a401db449af5e7fc5e777788f041391dcf77806))


### Bug Fixes

* **article:** modified article ([e1795be](https://github.com/alexrf45/musings/commit/e1795be0d1ec783f6719c7bbcbfd161b7ae68054))
* **button fix:** htmx template rendering issues ([792bc65](https://github.com/alexrf45/musings/commit/792bc6589394b82c98b0bc0fe217b862f2cd51f4))
* **configs:** nginx config folder ([6636eb2](https://github.com/alexrf45/musings/commit/6636eb25a870fb24c53463fb5ea1a4d3707efad4))
* **deploy:** add watchtower scope label to app service ([28a3371](https://github.com/alexrf45/musings/commit/28a33717be217a67d6d0b7933660c6cfeb581b11))
* **deploy:** fix SOPS dotenv format and nginx bootstrap for cert issuance ([b22be61](https://github.com/alexrf45/musings/commit/b22be61f1c0f9c6ebe800fd187147dcfae0fca2c))
* **deploy:** pin proxy network name to avoid Compose project prefix ([8a8298e](https://github.com/alexrf45/musings/commit/8a8298ed7dd2c66d285cbcbdc070b880eb08a8d1))
* **dockerfile:** Dockerfile Port Expose changes ([861dfb7](https://github.com/alexrf45/musings/commit/861dfb7a1ae7780a2c8a103a26d056e0e1c063b5))
* **hugo:** incorrect path for writing ([79b7f35](https://github.com/alexrf45/musings/commit/79b7f352d8b949731744571ada9cd0b29676d3d5))
* **hugo:** main page card path issue ([f7610b9](https://github.com/alexrf45/musings/commit/f7610b988ac878dae6f57a24ba40d49d85d12b69))
* **networking:** container port mismatch ([67116c4](https://github.com/alexrf45/musings/commit/67116c48204609a1d095b92e3de3a1710635034b))
* **nginx:** added nginx config files ([e51f0c5](https://github.com/alexrf45/musings/commit/e51f0c5c4f797ecef8b4c24f243fa4ae76c90f9c))
* no more hugo ([ee49525](https://github.com/alexrf45/musings/commit/ee49525843e964cb89d3b768ff4ae45bf2c8eab9))
* ruff lint — wrap long import and sort import block in views.py ([66d999b](https://github.com/alexrf45/musings/commit/66d999b38aa6450c4ab2cffc82a2d9413489a4f7))
* **tests:** update brand assertion from Musings to luvandre ([5dc8147](https://github.com/alexrf45/musings/commit/5dc814792584ddf040bfe4e979ea70fc98b7f820))

## [1.1.1-alpha](https://github.com/alexrf45/musings/compare/v1.1.0-alpha...v1.1.1-alpha) (2026-03-08)


### Bug Fixes

* no more hugo ([ee49525](https://github.com/alexrf45/musings/commit/ee49525843e964cb89d3b768ff4ae45bf2c8eab9))

## [1.1.0-alpha](https://github.com/alexrf45/musings/compare/v1.0.0-alpha...v1.1.0-alpha) (2026-03-05)


### Features

* **api:** add POST /api/v1/posts endpoint for Hugo→Flask sync ([81319ef](https://github.com/alexrf45/musings/commit/81319ef9e7505d0310e2e6419ea8dbfb405f5deb))


### Bug Fixes

* **deploy:** add watchtower scope label to app service ([28a3371](https://github.com/alexrf45/musings/commit/28a33717be217a67d6d0b7933660c6cfeb581b11))
* **deploy:** fix SOPS dotenv format and nginx bootstrap for cert issuance ([b22be61](https://github.com/alexrf45/musings/commit/b22be61f1c0f9c6ebe800fd187147dcfae0fca2c))
* **deploy:** pin proxy network name to avoid Compose project prefix ([8a8298e](https://github.com/alexrf45/musings/commit/8a8298ed7dd2c66d285cbcbdc070b880eb08a8d1))

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
