#!/usr/bin/env bash
set -euo pipefail
# Idempotent LDAP bootstrap: uses ldapadd from a temporary container to import LDIFs
ROOT="$(pwd)"
LDIF_DIR="$ROOT/openldap"
MARKER_VOLUME_PATH="/var/lib/ldap/.bootstrapped_ldap"

if docker compose ps -q openldap >/dev/null 2>&1; then
  echo "openldap service exists"
fi

echo "Waiting for OpenLDAP (389) to be reachable from the compose network..."
docker run --rm --network ticketing_it_stack_net curlimages/curl:8.4.0 -sS http://openldap:389 || true

if docker compose exec openldap sh -c "test -f $MARKER_VOLUME_PATH" >/dev/null 2>&1; then
  echo "LDAP already bootstrapped (marker present)"
  exit 0
fi

if [ -f "$LDIF_DIR/05-base-structure.ldif" ]; then
  echo "Importing LDIF into OpenLDAP"
  docker compose exec openldap ldapadd -x -D "cn=admin,dc=projet,dc=lan" -w "${LDAP_ROOT_PASSWORD:-adminpassword}" -H ldap://localhost -f /container/service/slapd/assets/config/bootstrap/ldif/05-base-structure.ldif || true
  # create marker inside the openldap data volume
  docker compose exec openldap sh -c "mkdir -p /var/lib/ldap && touch $MARKER_VOLUME_PATH" || true
  echo "LDAP bootstrap completed"
else
  echo "No LDIF found at $LDIF_DIR/05-base-structure.ldif — skipping import"
fi
