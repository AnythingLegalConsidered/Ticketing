#!/usr/bin/env bash
set -euo pipefail
# Idempotent Snipe‑IT bootstrap: generate APP_KEY, run migrations
ROOT="$(pwd)"
ENVFILE="$ROOT/.env"
MARKER_FILE_IN_VOLUME="/var/lib/snipeit/.bootstrapped_snipeit"

if [ ! -f "$ENVFILE" ]; then
  if [ -f "$ROOT/.env.example" ]; then
    cp "$ROOT/.env.example" "$ENVFILE"
    echo "Copied .env.example -> .env"
  else
    echo ".env missing and no .env.example found" >&2
    exit 1
  fi
fi

. "$ENVFILE" || true

echo "Checking SNIPEIT_APP_KEY in .env"
APPKEY_LINE=$(grep -n '^SNIPEIT_APP_KEY=' "$ENVFILE" || true)
APPKEY_VALUE=""
if [ -n "$APPKEY_LINE" ]; then
  APPKEY_VALUE=$(grep '^SNIPEIT_APP_KEY=' "$ENVFILE" | cut -d'=' -f2-)
fi

if [ -z "$APPKEY_VALUE" ]; then
  echo "No APP_KEY found — generating with snipe image"
  KEY=$(docker run --rm snipe/snipe-it:v6.3.3 php artisan key:generate --force --show)
  # ensure we replace any existing line
  if grep -q '^SNIPEIT_APP_KEY=' "$ENVFILE"; then
    sed -i "s|^SNIPEIT_APP_KEY=.*|SNIPEIT_APP_KEY=${KEY}|" "$ENVFILE"
  else
    echo "SNIPEIT_APP_KEY=${KEY}" >> "$ENVFILE"
  fi
  echo "Wrote APP_KEY to .env"
  echo "Recreating snipe-it service to pick up APP_KEY"
  docker compose up -d --force-recreate snipe-it
fi

echo "Waiting for Snipe‑IT /setup to be available through proxy..."
docker run --rm --network ticketing_it_stack_net curlimages/curl:8.4.0 -sS -o /dev/null -w "%{http_code}" -H "Host: snipeit.projet.lan" http://snipe-it/setup | grep -q "200" || true

echo "Running migrations inside snipe-it (idempotent)"
docker compose exec snipe-it php artisan migrate --force || true

# create marker file in the data volume so we don't rerun
docker compose exec snipe-it sh -c "mkdir -p /var/lib/snipeit && touch $MARKER_FILE_IN_VOLUME" || true

echo "Snipe‑IT bootstrap finished. Create admin via the UI: http://snipeit.projet.lan/setup/user"
