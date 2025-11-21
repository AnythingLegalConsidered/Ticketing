# Guide de Configuration Manuelle

Ce guide détaille les étapes pas-à-pas pour configurer les services après le déploiement de la stack via `make setup`.

---

## 1. Snipe-IT (Gestion de Parc)

### A. Assistant d'Installation (Premier accès)
1. Accédez à **http://localhost:8081**.
2. **Pre-Flight Check** : Tous les indicateurs devraient être verts. Cliquez sur **Next: Create Database Tables**.
3. **Create User** :
   - **Site Name** : `Ticketing LAN`
   - **Default Currency** : `EUR`
   - **Admin User** : Créez votre compte administrateur local (ce sera le "Super Admin").
4. Une fois terminé, connectez-vous avec ce compte.

### B. Configuration LDAP
Pour permettre aux utilisateurs (Techs, Clients) de se connecter :

1. Allez dans **Settings (roue dentée en haut à droite) > LDAP**.
2. Remplissez les champs suivants :
   - **LDAP Integration** : `Enabled`
   - **LDAP Password Sync** : `Yes` (Permet aux utilisateurs de se loguer avec leur mdp LDAP)
   - **Active Directory** : `No` (Nous utilisons OpenLDAP)
   - **LDAP Server** : `ldap://openldap`
   - **Use TLS** : `No`
   - **LDAP Bind Username** : `cn=admin,dc=ticketing,dc=lan`
   - **LDAP Bind Password** : `YourStrongLdapPassword` (ou voir variable `LDAP_ROOT_PASSWORD` dans `.env`)
   - **Base Bind DN** : `dc=ticketing,dc=lan`
   - **LDAP Filter** : `&(objectClass=inetOrgPerson)`
   - **Username Field** : `uid`
   - **Last Name** : `sn`
   - **First Name** : `givenName`
   - **Email** : `mail`
3. Cliquez sur **Save**.
4. Testez la connexion avec le bouton **Test LDAP Connection** (Doit afficher "It worked!").
5. Pour importer les utilisateurs immédiatement :
   - Allez dans **People** (menu gauche).
   - Cliquez sur le bouton **LDAP Sync**.
   - Cliquez sur **Synchronize**.

---

## 2. Zammad (Ticketing)

### A. Connexion Initiale
1. Accédez à **http://localhost:8080**.
2. Connectez-vous avec le compte administrateur pré-créé par le script :
   - **Email** : `admin@ticketing.lan`
   - **Mot de passe** : `admin123`

### B. Intégration LDAP
1. Allez dans **Système (icône engrenage en bas à gauche) > Intégrations > LDAP**.
2. Cliquez sur **Configurer**.
3. **Serveur** :
   - **Hôte** : `openldap`
   - **Utilisateur** : `cn=admin,dc=ticketing,dc=lan`
   - **Mot de passe** : `YourStrongLdapPassword`
4. Cliquez sur **Continuer**. Zammad va détecter automatiquement la Base DN (`dc=ticketing,dc=lan`).
5. **Mappage des Attributs** :
   - Vérifiez que **Login** est mappé sur `uid`.
   - Vérifiez que **Prénom** est mappé sur `givenName`.
   - Vérifiez que **Nom** est mappé sur `sn`.
   - Vérifiez que **Email** est mappé sur `mail`.
6. **Mappage des Rôles** (Optionnel mais recommandé) :
   - Vous pouvez mapper le groupe LDAP `cn=admin,ou=groups,dc=ticketing,dc=lan` vers le rôle Zammad `Admin`.
   - Vous pouvez mapper `cn=techN1...` vers `Agent`.
7. Cliquez sur **Continuer** puis lancez la synchronisation.

### C. Configuration Email (SMTP sortant)
Pour que Zammad envoie des notifications :

1. Allez dans **Système > Canaux > Email > Comptes**.
2. Configurez le serveur sortant (SMTP) :
   - **Hôte** : `mailhog`
   - **Port** : `1025`
   - **Utilisateur** : (Laisser vide)
   - **Mot de passe** : (Laisser vide)
3. Zammad enverra désormais les notifications via MailHog.
4. Vous pouvez voir les emails envoyés sur **http://localhost:8085**.

---

## 3. Uptime Kuma (Monitoring)

### A. Création de compte
1. Accédez à **http://localhost:8083**.
2. Créez votre compte administrateur local (ex: `admin` / `password`).

### B. Ajouter des Sondes (Monitors)
Comme Uptime Kuma est dans le même réseau Docker (`it_stack_net`), il peut contacter les autres conteneurs directement par leur nom.

**1. Monitorer Zammad :**
- Cliquez sur **Add New Monitor**.
- **Monitor Type** : `HTTP(s)`
- **Friendly Name** : `Zammad Internal`
- **URL** : `http://zammad-nginx:8080` (On tape sur le port interne du conteneur Nginx de Zammad)
- **Heartbeat Interval** : `60` (secondes)
- Cliquez sur **Save**.

**2. Monitorer Snipe-IT :**
- **Monitor Type** : `HTTP(s)`
- **Friendly Name** : `Snipe-IT Internal`
- **URL** : `http://snipe-it:80`
- Cliquez sur **Save**.

**3. Monitorer l'Annuaire LDAP :**
- **Monitor Type** : `TCP Port`
- **Friendly Name** : `OpenLDAP`
- **Hostname** : `openldap`
- **Port** : `389`
- Cliquez sur **Save**.

---

## 4. Dozzle (Logs)

1. Accédez à **http://localhost:8084**.
2. Aucune configuration n'est nécessaire.
3. Cliquez sur un conteneur à gauche (ex: `zammad-app`) pour voir ses logs en temps réel.
