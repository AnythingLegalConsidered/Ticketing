#!/bin/bash
# Script maître de configuration automatique
# Configure automatiquement tous les services après déploiement

set -e

echo "=== Configuration automatique de la stack IT ==="
echo "Ce script va configurer automatiquement :"
echo "- Zammad (SMTP + LDAP)"
echo "- Snipe-IT (SMTP + LDAP)"
echo ""

# Attendre que tous les services soient démarrés
echo "Attente du démarrage complet des services..."
sleep 60

# Configuration de Zammad
echo "Configuration de Zammad..."
docker compose exec -T zammad-app ruby /configure_zammad.rb

# Configuration de Snipe-IT
echo "Configuration de Snipe-IT..."
docker compose exec -T snipe-it bash /configure_snipeit.sh

echo ""
echo "=== Configuration terminée avec succès ! ==="
echo "Vous pouvez maintenant accéder aux services :"
echo "- Zammad : http://zammad.projet.lan"
echo "- Snipe-IT : http://snipeit.projet.lan"
echo "- MailHog : http://mail.projet.lan"
echo ""
echo "Utilisateur de test : johndoe / password"