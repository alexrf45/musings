#!/bin/bash
# Local Docker build and smoke test for the Flask blog

docker image rm blog:local 2>/dev/null || true

docker build -t blog:test ../.

docker run --name blog --rm -p 8080:8080 \
  -e SECRET_KEY=dev-local-secret \
  -e ADMIN_USERNAME=admin \
  -e ADMIN_PASSWORD=admin \
  -e DATABASE_URL=postgresql://musings:musings@host.docker.internal:5432/musings \
  -it blog:test
