#!/bin/sh
DOMAIN="${DOMAIN:-projet.lan}"
BASE_DN=$(echo "$DOMAIN" | awk -F. '{for(i=1;i<=NF;i++){printf "dc=%s%s",$i,(i<NF?",":"")}}')
echo "Waiting for LDAP at ldap://openldap (base=$BASE_DN)"
until ldapsearch -x -H ldap://openldap -b "$BASE_DN" -s base >/dev/null 2>&1; do
  sleep 1
done

echo "LDAP is up, importing LDIF"
ldapadd -x -H ldap://openldap -D "cn=admin,$BASE_DN" -w "${LDAP_ROOT_PASSWORD}" -f /ldifs/05-base-structure.ldif || true

echo "Bootstrap finished"
