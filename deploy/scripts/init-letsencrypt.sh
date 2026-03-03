#!/bin/bash
# First-run initialisation: decrypt secrets, obtain Let's Encrypt certificate, start stack.
# Run ONCE after deploying the stack, with DNS already pointing at the server.
#
# Prerequisites:
#   - deploy folder contents copied to /opt/musings (docker-compose.yml, .env.enc, nginx/, etc.)
#   - age private key at /root/.config/sops/age/keys.txt
#
# Usage: bash /opt/musings/scripts/init-letsencrypt.sh blog.fr3d.dev admin@fr3d.dev

set -euo pipefail

DOMAIN="${1:?Usage: $0 <domain> <email>}"
EMAIL="${2:?Usage: $0 <domain> <email>}"

DEPLOY_DIR="/opt/musings"
ENV_ENC="${DEPLOY_DIR}/.env.enc"
ENV_PLAIN="${DEPLOY_DIR}/.env"
SOPS_KEY="/root/.config/sops/age/keys.txt"
CERTS_DIR="/opt/musings/data/certbot-certs"
NGINX_CONF="${DEPLOY_DIR}/nginx/blog.conf"
COMPOSE="docker compose --env-file ${ENV_PLAIN} -f ${DEPLOY_DIR}/docker-compose.yml"

# ── Decrypt secrets ────────────────────────────────────────────────────────────
if [ ! -f "${ENV_ENC}" ]; then
  echo "ERROR: ${ENV_ENC} not found. Did you commit the encrypted env file?" >&2
  exit 1
fi

if [ ! -f "${SOPS_KEY}" ]; then
  echo "ERROR: age key not found at ${SOPS_KEY}" >&2
  exit 1
fi

echo "→ Decrypting secrets..."
SOPS_AGE_KEY_FILE="${SOPS_KEY}" sops --decrypt "${ENV_ENC}" > "${ENV_PLAIN}"
chmod 600 "${ENV_PLAIN}"

# Shred plaintext on exit — even if a later step fails.
trap 'shred -u "${ENV_PLAIN}" 2>/dev/null || true && echo "→ Plaintext .env shredded."' EXIT

# ── Patch nginx config with the real domain ────────────────────────────────────
sed -i "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g" "${NGINX_CONF}"
echo "→ Domain set to: ${DOMAIN}"

# ── Start nginx (HTTP only is enough for ACME challenge) ──────────────────────
echo "→ Starting nginx..."
${COMPOSE} up -d nginx

for i in $(seq 1 15); do
  if ${COMPOSE} exec nginx nginx -t &>/dev/null; then break; fi
  sleep 2
done

# ── Obtain initial certificate ─────────────────────────────────────────────────
echo "→ Requesting certificate for ${DOMAIN}..."
${COMPOSE} run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email "${EMAIL}" \
  --agree-tos \
  --no-eff-email \
  --force-renewal \
  -d "${DOMAIN}"

echo "→ Certificate obtained."

# ── Generate DH parameters (2048-bit) for stronger TLS ────────────────────────
if [ ! -f "${CERTS_DIR}/ssl-dhparams.pem" ]; then
  echo "→ Generating DH parameters (this takes a minute)..."
  openssl dhparam -out "${CERTS_DIR}/ssl-dhparams.pem" 2048
fi

# ── Bring up the full stack ────────────────────────────────────────────────────
echo "→ Starting full stack..."
${COMPOSE} up -d

echo ""
echo "✓ Done. ${DOMAIN} is live."
echo "  Certbot will auto-renew every 12 hours."
echo "  Watchtower will auto-update fonalex45/blog every 5 minutes."
