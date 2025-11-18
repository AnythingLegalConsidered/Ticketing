#!/usr/bin/env ruby
# Script de configuration automatique de Zammad
# Utilise l'API Rails actuelle de Zammad

require 'yaml'

puts "=== Configuration automatique de Zammad ==="

# Attendre que Zammad soit prêt
puts "Attente de la disponibilité de Zammad..."
sleep 30

# Configuration du canal e-mail sortant (SMTP via MailHog)
puts "Configuration du canal e-mail sortant..."
system("cd /opt/zammad && bundle exec rails r \"
# Créer un canal email sortant
channel = Channel.create(
  area: 'Email::Outbound',
  options: {
    adapter: 'smtp',
    host: 'mailhog',
    port: 1025,
    user: '',
    password: '',
    ssl: false,
    start_tls: false
  },
  active: true
)
puts 'Canal email sortant créé'
\"")

# Configuration de l'intégration LDAP
puts "Configuration de l'intégration LDAP..."
system("cd /opt/zammad && bundle exec rails r \"
# Créer la source LDAP
ldap_source = LdapSource.create(
  name: 'OpenLDAP',
  host: 'openldap',
  port: 389,
  ssl: false,
  base_dn: 'dc=projet,dc=lan',
  bind_user: 'cn=admin,dc=projet,dc=lan',
  bind_pw: ENV['LDAP_ROOT_PASSWORD'],
  user_filter: '(uid=%{login})',
  user_uid: 'uid',
  user_attributes: {
    firstname: 'givenName',
    lastname: 'sn',
    email: 'mail',
    login: 'uid'
  },
  group_filter: '(memberUid=%{login})',
  group_uid: 'cn',
  unassigned_users: true,
  active: true
)

# Synchronisation des utilisateurs
puts 'Synchronisation LDAP...'
ldap_source.sync
puts 'LDAP configuré et synchronisé'
\"")

# Créer un utilisateur admin automatiquement
puts "Création d'un utilisateur administrateur..."
system("cd /opt/zammad && bundle exec rails r \"
# Créer un utilisateur admin
admin = User.create(
  login: 'admin',
  firstname: 'Admin',
  lastname: 'User',
  email: 'admin@projet.lan',
  password: 'admin123',
  active: true,
  roles: Role.where(name: 'Admin')
)
puts 'Utilisateur admin créé: admin@projet.lan / admin123'
\"")

puts "Configuration Zammad terminée avec succès !"