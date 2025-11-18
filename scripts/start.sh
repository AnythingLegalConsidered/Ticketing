#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    echo "Created .env from .env.example (edit values as needed in .env)"
  else
    echo "No .env or .env.example found. Please create .env." >&2
    exit 1
  fi
fi

echo "Starting docker compose services..."
docker compose up -d

echo "Running LDAP bootstrap (idempotent)"
./scripts/bootstrap-ldap.sh || true

echo "Running Snipe‑IT bootstrap (idempotent)"
./scripts/bootstrap-snipeit.sh || true

echo "All bootstraps attempted."
echo "Visit http://snipeit.projet.lan (add hosts entry or use localhost with Host header)."
#!/usr/bin/env sh
set -e
cd "$(dirname "$0")/.."

echo "Starting docker compose stack (background)..."
docker compose up -d

echo "Running ldap-bootstrap (one-shot)..."
docker compose run --rm ldap-bootstrap

echo "Showing ldap-bootstrap logs (tail 200)..."
docker compose logs --no-color --tail=200 ldap-bootstrap

echo "Done."
