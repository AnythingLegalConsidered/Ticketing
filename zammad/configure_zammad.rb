#!/usr/bin/env ruby
# Script de configuration automatique de Zammad
# Ce script configure automatiquement Zammad via la console Rails

require 'yaml'

puts "=== Configuration automatique de Zammad ==="

# Attendre que Zammad soit prêt
puts "Attente de la disponibilité de Zammad..."
sleep 30

# Configuration du canal e-mail sortant (SMTP via MailHog)
puts "Configuration du canal e-mail sortant..."
system("cd /opt/zammad && bundle exec rails r \"Channel::Driver::Smtp.create_or_update(
  adapter: 'smtp',
  host: 'mailhog',
  port: 1025,
  user: nil,
  password: nil,
  ssl: false,
  start_tls: false,
  area: 'Email::Outbound'
)\"")

# Configuration de l'intégration LDAP
puts "Configuration de l'intégration LDAP..."
system("cd /opt/zammad && bundle exec rails r \"
ldap_source = LdapSource.create_or_update(
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
  unassigned_users: true
)

# Synchronisation des utilisateurs
ldap_source.sync
\"")

puts "Configuration Zammad terminée avec succès !"