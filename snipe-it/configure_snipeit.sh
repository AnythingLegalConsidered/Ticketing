#!/bin/bash
# Script de configuration automatique de Snipe-IT
# Ce script configure automatiquement Snipe-IT via les commandes artisan et DB

set -e

echo "=== Configuration automatique de Snipe-IT ==="

# Attendre que Snipe-IT soit prêt
echo "Attente de la disponibilité de Snipe-IT..."
sleep 30

# Créer un utilisateur administrateur automatiquement
echo "Création de l'utilisateur administrateur..."
php artisan snipeit:create-admin --first_name=Admin --last_name=User --email=admin@projet.lan --username=admin --password=admin123

# Configuration SMTP via base de données (plus fiable que les commandes artisan)
echo "Configuration du serveur SMTP via base de données..."
php artisan tinker --execute="
\$settings = [
    'site_name' => 'Snipe-IT Lab',
    'email_domain' => 'projet.lan',
    'email_from_name' => 'Snipe-IT',
    'email_from_addr' => 'noreply@projet.lan',
    'mail_driver' => 'smtp',
    'mail_host' => 'mailhog',
    'mail_port' => '1025',
    'mail_username' => null,
    'mail_password' => null,
    'mail_encryption' => null,
];

foreach (\$settings as \$key => \$value) {
    \App\Models\Setting::updateOrCreate(['key' => \$key], ['value' => \$value]);
}

echo 'SMTP configuré avec succès';
"

# Configuration de l'intégration LDAP
echo "Configuration de l'intégration LDAP..."
php artisan snipeit:ldap:config --host=openldap --port=389 --basedn="dc=projet,dc=lan" --username="cn=admin,dc=projet,dc=lan" --password="$LDAP_ROOT_PASSWORD" --filter="(uid=%s)" --firstname=givenName --lastname=sn --email=mail --login=uid

# Synchronisation des utilisateurs LDAP
echo "Synchronisation des utilisateurs LDAP..."
php artisan snipeit:ldap:sync

echo "Configuration Snipe-IT terminée avec succès !"
echo "Admin créé : admin@projet.lan / admin123"