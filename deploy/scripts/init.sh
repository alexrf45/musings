#!/bin/bash
# First-run initialisation: decrypt secrets and start the stack.
# Traefik handles ACME cert issuance automatically on first start.
#
# Prerequisites:
#   - repo cloned to /opt/musings
#   - age private key at /root/.config/sops/age/keys.txt
#   - DNS already pointing at this server
#
# Usage: bash /opt/musings/deploy/scripts/init.sh

set -euo pipefail

DEPLOY_DIR="/opt/musings/deploy"
ENV_ENC="${DEPLOY_DIR}/.env.enc"
ENV_PLAIN="${DEPLOY_DIR}/.env"
SOPS_KEY="/root/.config/sops/age/keys.txt"
ACME_JSON="/opt/musings/data/traefik/acme.json"
COMPOSE="docker compose --env-file ${ENV_PLAIN} -f ${DEPLOY_DIR}/docker-compose.yml"

# ── Preflight checks ───────────────────────────────────────────────────────────
if [ ! -f "${ENV_ENC}" ]; then
  echo "ERROR: ${ENV_ENC} not found. Did you clone the repo?" >&2
  exit 1
fi

if [ ! -f "${SOPS_KEY}" ]; then
  echo "ERROR: age key not found at ${SOPS_KEY}" >&2
  exit 1
fi

# ── Decrypt secrets ────────────────────────────────────────────────────────────
echo "→ Decrypting secrets..."
SOPS_AGE_KEY_FILE="${SOPS_KEY}" sops --decrypt --input-type dotenv --output-type dotenv "${ENV_ENC}" > "${ENV_PLAIN}"
chmod 600 "${ENV_PLAIN}"

# Shred plaintext on exit — even if a later step fails.
trap 'shred -u "${ENV_PLAIN}" 2>/dev/null || true && echo "→ Plaintext .env shredded."' EXIT

# ── Prepare Traefik data directories ──────────────────────────────────────────
echo "→ Preparing directories..."
mkdir -p /opt/musings/data/traefik /var/log/traefik

if [ ! -f "${ACME_JSON}" ]; then
  touch "${ACME_JSON}"
fi
chmod 600 "${ACME_JSON}"

# ── Start the stack ────────────────────────────────────────────────────────────
echo "→ Starting stack..."
${COMPOSE} up -d

echo ""
echo "✓ Stack is up. Traefik will obtain the TLS certificate automatically."
echo "  Watch progress: docker compose logs -f traefik"
echo "  Watchtower will auto-update fonalex45/blog every 5 minutes."
