# Infrastructure de Ticketing Conteneurisée
**Statut :** Opérationnel

## 🎯 Objectif du Projet
Ce projet déploie une infrastructure IT complète conteneurisée pour la gestion des tickets et de l'inventaire IT. Il utilise **Docker Compose** pour orchestrer plusieurs services open-source interconnectés.

L'infrastructure est déployée automatiquement, mais l'affinage des applications (LDAP, SMTP, etc.) se fait via des interfaces graphiques pour répondre aux objectifs pédagogiques et mieux comprendre les outils.

### Services Déployés
*   **Zammad :** Système de ticketing et support client.
*   **Snipe-IT :** Gestion d'inventaire IT (ITAM).
*   **OpenLDAP :** Annuaire centralisé (pré-rempli avec utilisateurs/groupes).
*   **phpLDAPadmin :** Interface web pour la gestion OpenLDAP (création visuelle d'utilisateurs).
*   **Uptime Kuma :** Monitoring d'infrastructure.
*   **Dozzle :** Visualisation des logs en temps réel.
*   **MailHog :** Serveur de test email (piège SMTP).
*   **Nginx :** Proxy inverse pour un accès unifié via sous-domaines.

> ⚠️ **Note :** Strictement limité à un environnement de test/lab (données jetables, mots de passe non-sécurisés).

---

## 🏗️ Architecture

L'infrastructure est organisée en couches fonctionnelles, accessibles via des sous-domaines sur le port 80.

```mermaid
graph TD
    User((Utilisateur / Navigateur)) --> Nginx[Proxy Inverse Nginx]

    subgraph "Applications"
    Nginx --> Zammad
    Nginx --> SnipeIT[Snipe-IT]
    end

    subgraph "Gestion & Monitoring"
    Nginx --> Kuma[Uptime Kuma]
    Nginx --> PLA[phpLDAPadmin]
    Nginx --> Dozzle
    Nginx --> MailHog
    end

    subgraph "Données & Backend"
    Zammad & SnipeIT --> LDAP[OpenLDAP]
    Zammad & SnipeIT --> MailHog
    Zammad --> DB_Z[PostgreSQL + Elastic + Redis]
    SnipeIT --> DB_S[MySQL]
    PLA --> LDAP
    end
```

*(Si le diagramme ci-dessus ne s'affiche pas, voici la vue texte :)*

*   **Point d'entrée :** Nginx (Proxy Inverse) gère le routage via sous-domaines (zammad.lvh.me, snipeit.lvh.me, etc.).
*   **Couche Application :** Zammad (Ticketing), Snipe-IT (Inventaire).
*   **Couche Gestion :** phpLDAPadmin (Interface Annuaire), Dozzle (Logs), Uptime Kuma (Monitoring).
*   **Services Backend :** OpenLDAP (Auth), PostgreSQL/MySQL (Bases de données), Elasticsearch, Redis.

---

## 📋 Prérequis
*   **Git :** Pour cloner le dépôt.
*   **Docker :** Version 20.10+ avec Docker Compose V2.
*   **Navigateur Web :** Pour accéder aux interfaces.
*   **Ressources :** Au moins **6 GB RAM** recommandés (Elasticsearch + Zammad sont gourmands en ressources).

---

## 🚀 Installation et Déploiement

### 1. Cloner le dépôt
```bash
git clone https://github.com/AnythingLegalConsidered/Ticketing
cd Ticketing
```

### 2. Configurer l'environnement
Copier le fichier d'exemple et modifier les variables si nécessaire (domaine, mots de passe) :
```bash
cp .env.example .env
```

### 3. Configuration DNS
**Aucune configuration requise !** Les services sont accessibles via les sous-domaines lvh.me (résolvent automatiquement vers 127.0.0.1).

### 4. Démarrer la stack
```bash
make setup
# OU manuellement :
# docker compose up -d
```

### 5. Initialisation
*   **Automatique :** Le conteneur de setup va peupler OpenLDAP avec des données de test et créer l'utilisateur Admin initial pour Zammad.
*   **Étapes Manuelles (Requises) :**
    *   **Snipe-IT :** Aller sur `http://snipeit.lvh.me/setup` et compléter l'assistant d'installation.
    *   **Zammad :** Se connecter, puis configurer les intégrations **LDAP** et **SMTP** dans les paramètres en utilisant les identifiants ci-dessous.
    *   **Uptime Kuma :** Créer votre compte administrateur et configurer les sondes.

---

## 🌐 Accès aux Services

| Service | URL | Identifiants / Statut |
| :--- | :--- | :--- |
| **Zammad** | `http://zammad.lvh.me` | **Login :** `admin@ticketing.local` <br> **Pass :** `admin123` |
| **Snipe-IT** | `http://snipeit.lvh.me` | **Statut :** Compléter l'Assistant <br> **DB :** `snipeit` / `snipeit` / `snipeit_password` |
| **phpLDAPadmin** | `http://ldap.lvh.me` | **Login :** `cn=admin,dc=ticketing,dc=local` <br> **Pass :** (Voir `.env`) |
| **Uptime Kuma** | `http://uptime.lvh.me` | **Statut :** Créer compte admin |
| **Dozzle** | `http://dozzle.lvh.me` | **Statut :** Accès libre |
| **MailHog** | `http://mailhog.lvh.me` | **Statut :** Accès libre |

### 👥 Gestion des Utilisateurs LDAP
Les utilisateurs sont pré-remplis, mais vous pouvez les gérer via **phpLDAPadmin** :
1.  Aller sur `http://ldap.lvh.me`.
2.  Se connecter avec le DN Admin.
3.  **Créer de nouveaux utilisateurs manuellement** via l'interface graphique (Créer une entrée enfant -> Compte utilisateur générique).

**Utilisateurs de Test par Défaut :**
*   **Tech N1 :** chris.letech
*   **Tech N2 :** robert.lemodo
*   **Tech N3 :** bob.ladmin
*   **Clients :** jean.user
*   **Mot de passe par défaut :** `password`

---

## 🛠️ Commandes Utiles

### Via Makefile (Recommandé)
```bash
make setup       # 🚀 Configuration complète (build + up + logs setup)
make up          # Démarrer l'infrastructure
make down        # Arrêter l'infrastructure
make status      # Vérifier le statut des conteneurs
make logs        # Voir les logs de tous les services
make clean       # ⚠️ Nettoyage complet (supprime conteneurs ET volumes)
```

### Via Docker Compose
```bash
docker compose up -d                 # Démarrer
docker compose logs -f [service]     # Logs
docker compose restart [service]     # Redémarrer une app spécifique
docker compose down -v               # Tout supprimer
```

---

## 📁 Structure du Projet

```text
.
├── Makefile                   # Raccourcis de gestion
├── docker-compose.yml         # Fichier d'orchestration principal
├── .env                       # Configuration centralisée
├── README.md                  # Documentation (Anglais)
├── README.fr.md               # Documentation (Français)
│
├── elasticsearch/             # Configuration ES personnalisée
├── nginx/
│   └── conf.d/                # Configs Proxy Inverse (Vhosts)
├── openldap/
│   └── Dockerfile             # Image LDAP personnalisée
├── scripts/                   # Scripts d'initialisation (bootstrap LDAP, etc.)
└── zammad/                    # Scripts spécifiques Zammad
```

---

## 🔧 Personnalisation
**Variables d'Environnement (.env) :**
*   `DOMAIN=ticketing.local` : Domaine de base.
*   `LDAP_ROOT_PASSWORD` : Mot de passe pour `cn=admin`.
*   `POSTGRES_PASSWORD` / `MYSQL_PASSWORD` : Mots de passe DB.

**Ajouter des Utilisateurs :**
Vous pouvez ajouter des utilisateurs dans `openldap/add-entries.ldif` avant le build, ou simplement utiliser **phpLDAPadmin** après le déploiement.

---

## 📊 Statut du Projet
*   ✅ **Infrastructure :** Déployée et fonctionnelle.
*   ✅ **Monitoring :** Uptime Kuma et Dozzle intégrés.
*   ✅ **LDAP :** Peupler automatiquement + gestion GUI ajoutée.
*   🔄 **Configuration :** Configuration manuelle via GUI requise pour Zammad/Snipe-IT (Objectif pédagogique).

---

## 📄 Licence
Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.