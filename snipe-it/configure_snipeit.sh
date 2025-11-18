#!/bin/bash
# Script de configuration automatique de Snipe-IT
# Ce script configure automatiquement Snipe-IT via les commandes artisan

set -e

echo "=== Configuration automatique de Snipe-IT ==="

# Attendre que Snipe-IT soit prêt
echo "Attente de la disponibilité de Snipe-IT..."
sleep 30

# Configuration du serveur SMTP (MailHog)
echo "Configuration du serveur SMTP..."
php artisan snipeit:email:test --server=mailhog --port=1025 --security=none --from=admin@projet.lan

# Configuration de l'intégration LDAP
echo "Configuration de l'intégration LDAP..."
php artisan snipeit:ldap:config --host=openldap --port=389 --basedn="dc=projet,dc=lan" --username="cn=admin,dc=projet,dc=lan" --password="$LDAP_ROOT_PASSWORD" --filter="(uid=%s)" --firstname=givenName --lastname=sn --email=mail --login=uid

# Synchronisation des utilisateurs LDAP
echo "Synchronisation des utilisateurs LDAP..."
php artisan snipeit:ldap:sync

echo "Configuration Snipe-IT terminée avec succès !"