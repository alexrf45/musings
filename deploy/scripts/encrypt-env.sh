#!/usr/bin/env bash
# Generates an age keypair and encrypts deploy/.env → deploy/.env.enc
# Run from the repo root or from anywhere — paths are resolved from script location.
#
# Prerequisites: age-keygen, sops
#   age:  https://github.com/FiloSottile/age
#   sops: https://github.com/getsops/sops

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_PLAIN="${REPO_ROOT}/deploy/.env"
ENV_ENC="${REPO_ROOT}/deploy/.env.enc"
AGE_KEY_DIR="${HOME}/.config/sops/age"
AGE_KEY_FILE="${AGE_KEY_DIR}/keys.txt"
SOPS_YAML="${REPO_ROOT}/.sops.yaml"

# ── Dependency check ──────────────────────────────────────────────────────────
for cmd in age-keygen sops; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' not found." >&2
    echo "  age:  https://github.com/FiloSottile/age" >&2
    echo "  sops: https://github.com/getsops/sops" >&2
    exit 1
  fi
done

# ── Check source .env exists ──────────────────────────────────────────────────
if [ ! -f "$ENV_PLAIN" ]; then
  echo "ERROR: ${ENV_PLAIN} not found." >&2
  exit 1
fi

# ── Generate age key if one doesn't already exist ────────────────────────────
mkdir -p "$AGE_KEY_DIR"
chmod 700 "$AGE_KEY_DIR"

if [ -f "$AGE_KEY_FILE" ]; then
  echo "→ Using existing age key at ${AGE_KEY_FILE}"
else
  echo "→ Generating new age keypair..."
  age-keygen -o "$AGE_KEY_FILE"
  chmod 600 "$AGE_KEY_FILE"
  echo "→ Key saved to ${AGE_KEY_FILE}"
fi

# ── Extract public key from key file ─────────────────────────────────────────
AGE_PUBKEY=$(grep '^# public key:' "$AGE_KEY_FILE" | awk '{print $NF}')
if [ -z "$AGE_PUBKEY" ]; then
  echo "ERROR: Could not extract public key from ${AGE_KEY_FILE}" >&2
  exit 1
fi
echo "→ Age public key: ${AGE_PUBKEY}"

# ── Write .sops.yaml ──────────────────────────────────────────────────────────
cat > "$SOPS_YAML" <<EOF
creation_rules:
  - path_regex: deploy/\.env(\.enc)?$
    age: ${AGE_PUBKEY}
EOF
echo "→ Written ${SOPS_YAML}"

# ── Encrypt deploy/.env → deploy/.env.enc ────────────────────────────────────
echo "→ Encrypting ${ENV_PLAIN} ..."
SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" sops \
  --encrypt \
  --input-type dotenv \
  --output-type dotenv \
  --age "$AGE_PUBKEY" \
  "$ENV_PLAIN" > "$ENV_ENC"

echo ""
echo "✓ Done."
echo ""
echo "  Encrypted : deploy/.env.enc   ← commit this"
echo "  SOPS rules: .sops.yaml        ← commit this"
echo "  Key file  : ${AGE_KEY_FILE}   ← keep secret, back it up!"
echo ""
echo "Next steps:"
echo "  1. git add deploy/.env.enc .sops.yaml && git commit"
echo "  2. Ensure deploy/.env is in .gitignore (never commit plaintext)"
echo "  3. On the server, copy the private key to /root/.config/sops/age/keys.txt"
