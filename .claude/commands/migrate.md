Generate and apply a Flask-Migrate (Alembic) database migration.

Ask the user for a short description of the schema change, then run:

```bash
flask db migrate -m "<description>"
flask db upgrade
```

Ensure the app's virtualenv is active (`source .venv/bin/activate`) and Postgres is running before executing.
