#!/bin/bash
set -e

echo "=== Démarrage du conteneur de configuration ==="

# Installation des dépendances
echo "Installation des outils nécessaires..."
apt-get update && apt-get install -y curl ldap-utils postgresql-client mariadb-client docker.io

# 1. Configuration LDAP
echo "--- Étape 1 : Configuration LDAP ---"
/scripts/populate_ldap.sh

# 2. Configuration Zammad
echo "--- Étape 2 : Configuration Zammad ---"
# On attend que Zammad soit prêt (déjà géré par depends_on, mais double sécurité)
until curl -s -f http://zammad-app:3000/ > /dev/null; do
    echo "En attente de Zammad..."
    sleep 5
done

# Vérifier si Zammad est déjà configuré
echo "Vérification de l'état de Zammad..."
if curl -s http://zammad-app:3000/ | grep -q "login"; then
    echo "Zammad semble déjà configuré, passage à l'étape suivante..."
fi

echo "Lancement du script de configuration Ruby pour Zammad..."
docker exec zammad-app bundle exec rails r /configure_zammad.rb

echo "=== Configuration terminée avec succès ! ==="
