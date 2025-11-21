# 📘 Guide de Configuration Post-Déploiement

Ce guide détaille les étapes manuelles nécessaires une fois la stack Docker lancée (`make setup`).

**Informations de base :**
*   **Domaine local :** `*.lvh.me` (pointe vers 127.0.0.1)
*   **Mot de passe Admin par défaut :** `admin123`
*   **Mot de passe LDAP racine :** `YourStrongLdapPassword` (ou voir `.env`)

---

## 1. Snipe-IT (Gestion de Parc)

### A. Assistant d'Installation
1. Accédez à **http://snipeit.lvh.me/setup**.
2. **Pre-Flight Check** : Tout doit être vert. Cliquez sur **Next: Create Database Tables**.
3. **Create User** :
   - **Site Name** : `Ticketing LAN`
   - **Default Currency** : `EUR`
   - **Admin User** : Créez un administrateur local de secours.
4. Une fois terminé, connectez-vous avec ce compte.

### B. Configuration LDAP
1. Allez dans **Settings (roue dentée) > LDAP**.
2. Remplissez ainsi :
   - **LDAP Integration** : `Enabled`
   - **LDAP Password Sync** : `Yes`
   - **Active Directory** : `No`
   - **LDAP Server** : `ldap://openldap` (Protocole standard interne)
   - **Use TLS** : `No`
   - **LDAP Bind Username** : `cn=admin,dc=ticketing,dc=local`
   - **LDAP Bind Password** : `YourStrongLdapPassword`
   - **Base Bind DN** : `dc=ticketing,dc=local`
   - **LDAP Filter** : `&(objectClass=inetOrgPerson)`
   - **Username Field** : `uid`
   - **Last Name** : `sn`
   - **First Name** : `givenName`
   - **Email** : `mail`
3. Cliquez sur **Save** puis **Test LDAP Connection** (Doit afficher "It worked!").
4. Allez dans **People > LDAP Sync > Synchronize** pour importer les utilisateurs.

---

## 2. Zammad (Ticketing)

### A. Connexion et Organisation
1. Accédez à **http://zammad.lvh.me**.
2. Connectez-vous :
   - **Email** : `admin@ticketing.local`
   - **Mot de passe** : `admin123`
3. **Assistant de configuration** :
   - À l'étape "Organisation", nommez-la **Ticketing**.
   - Si vous avez déjà passé cette étape : Allez dans *Gestion > Organisations > Projet LAN*, renommez-le et sauvegardez.

### B. Intégration LDAP (Configuration Correcte)
1. Allez dans **Système (engrenage) > Intégrations > LDAP > Configurer**.
2. **Étape 1 : Serveur**
   - **Hôte** : `openldap`
   - **SSL/STARTTLS** : `Non` (Important !)
   - **Vérification SSL** : `Non`
   - **Actif** : `Oui`
   - Cliquez sur **Connecter**.
3. **Étape 2 : Authentification**
   - **Utilisateur** : `cn=admin,dc=ticketing,dc=local`
   - **Mot de passe** : `YourStrongLdapPassword`
   - Cliquez sur **Continuer** (La Base DN `dc=ticketing,dc=local` doit être détectée).
4. **Étape 3 : Mappage (Cartographie)**
   - **Login** : Remplacez `samaccountname` par **`uid`**.
   - **Prénom/Nom/Email** : Laissez par défaut (`givenname`, `sn`, `mail`).
   - **Rôles** :
     - Ajoutez une règle : Groupe LDAP `cn=techs...` ⮕ Rôle Zammad `Agent`.
   - **Expert (Filtre)** :
     - Remplacez `(objectClass=posixaccount)` par **`(objectClass=inetOrgPerson)`**.
     - Option "Utilisateurs sans groupes..." : Mettre sur **Attribuer des rôles d'inscription** (pour créer les clients).
5. Lancez la synchronisation.

### C. Configuration Email (SMTP sortant)
1. Allez dans **Système > Canaux > Email > Comptes**.
2. Configurez le SMTP sortant :
   - **Hôte** : `mailhog`
   - **Port** : `1025`

---

## 3. Uptime Kuma (Monitoring)

### A. Création de compte
1. Accédez à **http://uptime.lvh.me**.
2. Créez votre compte administrateur local (ex: `admin` / `admin123`).

### B. Ajouter des Sondes (Réseau Interne Docker)
Nous utilisons les noms de conteneurs internes pour une fiabilité maximale.

**1. Monitorer Zammad**
- **Type** : `HTTP(s)`
- **Nom** : `Zammad Internal`
- **URL** : `http://zammad-nginx:8080`
  - *Note : On tape sur le serveur Nginx dédié à Zammad.*
- **Sauvegarder**.

**2. Monitorer Snipe-IT (Configuration Spéciale)**
- **Type** : `HTTP(s)`
- **Nom** : `Snipe-IT Internal`
- **URL** : `http://nginx`
  - *Note : Le conteneur nommé "nginx" est le serveur web frontal de Snipe-IT.*
- **Avancé > Mots-clés** :
  - Ajoutez le mot : `Snipe-IT` (ou `Login`).
  - *Cela garantit que c'est bien l'application qui répond et pas juste une page blanche Nginx.*
- **Sauvegarder**.

**3. Monitorer l'Annuaire LDAP**
- **Type** : `Port TCP`
- **Nom** : `OpenLDAP`
- **Hostname** : `openldap`
- **Port** : `389`
- **Sauvegarder**.

---

## 4. Dozzle (Logs)
- Accédez à **http://dozzle.lvh.me** pour visualiser les logs de tous les conteneurs en temps réel (utile pour le débogage).