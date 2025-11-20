#!/usr/bin/env ruby
# Script de configuration automatique de Zammad (Ruby)
# Configure SMTP, LDAP, crée un admin et définit les paramètres système
# Exécuté automatiquement lors de la configuration de l'infrastructure

require 'yaml'
require 'json'
require 'net/ldap'



puts "=== Configuration automatique de Zammad ==="

# Attendre que Zammad soit prêt
puts "Attente de la disponibilité de Zammad..."
sleep 5

# Utiliser auto_wizard pour l'initialisation
puts "Vérification si le système est déjà initialisé..."

# Toujours s'assurer que l'organisation et l'admin existent, même si init_done est true
puts "Vérification/Création de l'organisation 'Projet LAN'..."
# Définir l'utilisateur système pour les actions de création
UserInfo.current_user_id = 1

org = Organization.find_or_create_by(name: 'Projet LAN')

puts "Vérification/Création de l'utilisateur Admin..."
admin_role = Role.find_by(name: 'Admin')
agent_role = Role.find_by(name: 'Agent')

user = User.find_or_create_by(email: 'admin@projet.lan')
user.update!(
  firstname: 'Admin',
  lastname: 'User',
  login: 'admin@projet.lan',
  password: 'admin123',
  active: true,
  organization: org,
  roles: [admin_role, agent_role].compact
)
puts "Utilisateur Admin assuré."

if Setting.get('system_init_done')
  puts "Système déjà marqué comme initialisé."
else
  puts "Marquage du système comme initialisé..."
  Setting.set('timezone_default', 'Europe/Paris')
  Setting.set('system_init_done', true)
end

puts "Configuration Zammad terminée avec succès !"
