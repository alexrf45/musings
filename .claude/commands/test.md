Run the test suite against a local Postgres instance.

```bash
APP_ENV=testing DATABASE_URL=postgresql://musings:musings@localhost:5432/test_musings \
  SECRET_KEY=test ADMIN_USERNAME=admin ADMIN_PASSWORD=testpassword \
  pytest tests/ -v
```

If Postgres isn't running, start it first with `docker compose up db -d`.
