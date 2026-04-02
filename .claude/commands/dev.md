Start the full local dev stack (db + app with hot reload at http://localhost:8080).

```bash
docker compose up -d
```

To rebuild after dependency or config changes:
```bash
docker compose build && docker compose up -d
```

To tail app logs:
```bash
docker compose logs app -f
```

Alternatively, run the Flask dev server directly (Postgres only via Docker):
```bash
docker compose up db -d
source .venv/bin/activate
APP_ENV=development flask run --debug --port 5000
```

Or use the tmuxp session:
```bash
tmuxp load development/dev-tmuxp.yaml
```
