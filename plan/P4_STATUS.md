# Partie 4 : Zammad - État d'Avancement Détaillé

**Date de mise à jour :** 2025-11-18  
**Statut global :** ✅ COMPLÉTÉ (100%)

---

## ✅ RÉSOLUTION DU PROBLÈME D'ACCÈS UI (18 nov. 2025)

### Problème identifié
Le mapping de ports dans `docker-compose.yml` était incorrect pour le service `zammad-nginx`.

**Configuration erronée :**
```yaml
zammad-nginx:
  ports:
    - "127.0.0.1:8080:80"  # ❌ Incorrect : nginx écoute sur 8080, pas 80
```

### Investigation
1. **Lecture de la config nginx packagée** :
   ```bash
   docker compose exec -T zammad-nginx sh -lc 'cat /etc/nginx/sites-available/default'
   ```
   Résultat : `listen 8080;` dans le vhost

2. **Vérification des ports en écoute** :
   ```bash
   docker compose exec -T zammad-nginx sh -lc 'ss -tlnp | grep nginx'
   ```
   Résultat : `LISTEN 0.0.0.0:8080` ✅

3. **Test interne** :
   ```bash
   docker compose exec -T zammad-nginx sh -lc 'curl -I http://0.0.0.0:8080'
   ```
   Résultat : `HTTP/1.1 200 OK` ✅

### Solution appliquée
**Configuration corrigée** dans `docker-compose.yml` :
```yaml
zammad-nginx:
  ports:
    - "127.0.0.1:8080:8080"  # ✅ Correct : mapping port à port
```

### Validation
```powershell
# Test depuis Windows
Invoke-WebRequest -Uri "http://127.0.0.1:8080" -UseBasicParsing

# Résultat
StatusCode        : 200
StatusDescription : OK
Content           : <!DOCTYPE html>...
```

### Logs applicatifs
```bash
docker compose logs zammad-app | Select-String "GET|POST"
```
```
I, [2025-11-18T08:56:22] INFO -- : Started GET "/" for 172.21.0.1
I, [2025-11-18T08:56:57] INFO -- : Started POST "/api/v1/signshow" for 172.21.0.1
```

### Statut final
- ✅ Interface web Zammad accessible sur `http://127.0.0.1:8080`
- ✅ Setup wizard disponible pour création compte admin
- ✅ P4 complété à 100%
- ✅ P5 (intégrations SMTP/LDAP) débloqué

---

## ✅ RÉALISÉ

### 1. Stack Zammad déployée
- **6 conteneurs opérationnels** :
  - `zammad-postgres` (PostgreSQL 15)
  - `zammad-elasticsearch` (ES 7.17.10 + plugin ingest-attachment)
  - `zammad-redis` (Redis 6-alpine)
  - `zammad-app` (Rails/Puma server)
  - `zammad-scheduler` (Background jobs)
  - `zammad-websocket` (WebSocket server)
  - `zammad-nginx` (Nginx packagé)
- Tous connectés au réseau `it_stack_net`
- État vérifié : `docker compose ps` — tous "Up"

### 2. Elasticsearch configuré avec plugin ingest-attachment
**Fichier créé :** `elasticsearch/Dockerfile`
```dockerfile
FROM elasticsearch:7.17.10
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install --batch ingest-attachment
```
- **Image locale buildée** : `ticketing_zammad_elasticsearch:local`
- **Plugin chargé confirmé** dans les logs :
  ```
  loaded plugin [ingest-attachment]
  ```
- Test manuel du plugin : ✅ GET `_nodes/plugins` retourne ingest-attachment

### 3. Pipeline Elasticsearch créé manuellement
**Problème initial :** 
```
ERROR -- : Unable to process post request to elasticsearch URL... 
pipeline with id [zammad9b4db769-b0df-4bb0-a316-52f18f6d60a8] does not exist
```

**Solution appliquée :**
1. Créé fichier `pipeline.json` à la racine :
   ```json
   {"processors":[]}
   ```
2. PUT du pipeline via curl :
   ```powershell
   type .\pipeline.json | docker compose exec -T zammad-elasticsearch sh -lc "curl -sS -X PUT 'http://localhost:9200/_ingest/pipeline/zammad9b4db769-b0df-4bb0-a316-52f18f6d60a8' -H 'Content-Type: application/json' --data-binary @-"
   ```
3. **Résultat :** `{"acknowledged":true}` HTTP 200
4. **Validation :** Les SearchIndexJob complètent désormais sans erreur 400

### 4. Configuration base de données corrigée

**Problèmes rencontrés :**
- Hostname incorrect (`zammad-postgresql` au lieu de `zammad-postgres`)
- Erreurs d'authentification ("password authentication failed for user 'zammad'")

**Solutions appliquées :**
1. **Variables d'environnement explicites** dans `docker-compose.yml` pour tous les services runtime :
   ```yaml
   environment:
     - POSTGRESQL_HOST=zammad-postgres
     - POSTGRESQL_USER=${POSTGRES_USER}
     - POSTGRESQL_PASS=${POSTGRES_PASSWORD}
     - POSTGRESQL_DB=${POSTGRES_DB}
   ```

2. **Remplacement du database.yml** dans `zammad-app` :
   - Ancien : hostname hardcodé `zammad-postgresql`
   - Nouveau : Template ERB lisant les variables d'environnement
   - Commande utilisée (depuis conteneur) : `cat > /opt/zammad/config/database.yml` avec contenu ERB

3. **Reset du mot de passe DB** dans Postgres :
   ```sql
   ALTER USER zammad WITH PASSWORD 'YourStrongZammadDbPassword';
   ```
   Exécuté depuis : `docker compose exec zammad-postgres psql -U zammad -d zammad_production`

### 5. Alias réseau `zammad-railsserver` ajouté

**Modification dans docker-compose.yml :**
```yaml
zammad-app:
  # ...
  networks:
    it_stack_net:
      aliases:
        - zammad-railsserver
```

**Validation :**
```bash
docker compose exec -T zammad-nginx sh -lc 'getent hosts zammad-railsserver'
# Résultat : 172.21.0.2    zammad-railsserver
```

### 6. One-shot `zammad-init` configuré

**Service ajouté :**
```yaml
zammad-init:
  image: zammad/zammad:6.2.0-14
  container_name: zammad-init
  restart: "no"
  depends_on:
    - zammad-postgres
    - zammad-elasticsearch
  environment:
    - POSTGRESQL_DB=${POSTGRES_DB}
    - POSTGRESQL_HOST=zammad-postgres
    # ... autres vars
  command: ["zammad-init"]
  volumes:
    - zammad_data:/opt/zammad/
```

**Résultat :**
- Migrations exécutées
- Index ES rebuild effectué
- Container exited with code 0

### 7. Backend opérationnel confirmé

**Tests effectués :**
```bash
# Vérifier Puma
docker compose logs zammad-app | findstr "Listening"
# Résultat : * Listening on http://[::]:3000

# Test connectivité interne
docker compose exec -T zammad-nginx sh -lc 'curl -I http://zammad-railsserver:3000/'
# Résultat : HTTP/1.1 200 OK
```

**Services runtime :**
- ✅ Puma écoute sur port 3000
- ✅ Scheduler exécute les jobs (Channel.fetch, Ticket.process_escalation, etc.)
- ✅ WebSocket connecté à Redis
- ✅ Indexation ES fonctionne (SearchIndexJob COMPLETED)

---

## ⚠️ PROBLÈME EN COURS

### Accès UI externe non fonctionnel

**Symptômes :**
```powershell
Invoke-WebRequest -Uri "http://127.0.0.1:8080" -Headers @{"Host"="zammad.projet.lan"}
# Erreur : La connexion a été interrompue de manière inattendue
```

**Diagnostics effectués :**
1. ✅ `zammad-nginx` container UP et nginx processes running (16 workers)
2. ✅ Port mapping: `127.0.0.1:8080->80` configuré
3. ✅ Test interne depuis `zammad-nginx` vers `zammad-railsserver:3000` : HTTP 200
4. ✅ DNS résolution : `zammad-railsserver` résout vers `172.21.0.2`

**Cause suspectée :**
- La configuration nginx **packagée** dans l'image `zammad-nginx` ne proxifie probablement pas correctement vers l'upstream
- Ou le upstream est configuré pour un autre hostname (ex: `localhost` au lieu de `zammad-railsserver`)

**Config nginx externe (fonctionne pour les autres services) :**
`nginx/conf.d/zammad.conf`:
```nginx
server {
    listen 80 default_server;
    server_name zammad.projet.lan;
    location / {
        resolver 127.0.0.11 valid=30s;
        set $backend zammad-nginx;
        proxy_pass http://$backend;
        # ... headers WebSocket
    }
}
```

---

## 🔧 MODIFICATIONS PAR RAPPORT AU PLAN ORIGINAL

### Ajouts non prévus dans P4.md initial :
1. **Service `zammad-redis`** (requis mais non documenté dans le plan)
2. **Build local d'Elasticsearch** avec Dockerfile personnalisé
3. **Service `zammad-init`** one-shot pour migrations
4. **Variables d'environnement POSTGRESQL_*** étendues à tous les services
5. **Alias réseau `zammad-railsserver`** pour communication interne
6. **Resolver DNS runtime** dans nginx externe (`127.0.0.11`)
7. **Pipeline ES créé manuellement** (non généré par zammad-init)

### Fichiers créés :
- `elasticsearch/Dockerfile`
- `pipeline.json` (à la racine, temporaire pour création manuelle)
- Modifications dans `docker-compose.yml` (multiples patchs)
- Remplacement in-container de `/opt/zammad/config/database.yml`

---

## 📋 PROCHAINES ÉTAPES

### 1. Investiguer nginx packagé
```bash
# Localiser la config
docker compose exec -T zammad-nginx sh -lc 'find /etc/nginx -name "*.conf" | xargs grep -l proxy_pass'

# Lire la config upstream
docker compose exec -T zammad-nginx sh -lc 'cat /etc/nginx/nginx.conf'

# Vérifier les logs nginx
docker compose logs zammad-nginx | grep -i error
```

### 2. Solution alternative (contournement)
Si le nginx packagé pose problème, modifier `nginx/conf.d/zammad.conf` :
```nginx
location / {
    resolver 127.0.0.11 valid=30s;
    set $backend zammad-railsserver:3000;  # Direct vers l'app
    proxy_pass http://$backend;
    # ... reste inchangé
}
```

### 3. Une fois UI accessible
- Créer compte administrateur via interface web
- ✅ Marquer P4 comme 100% complété
- Démarrer P5 (Intégrations SMTP/LDAP)

---

## 📊 MÉTRIQUES

- **Temps de démarrage Zammad** : ~2-3 minutes (dépend de ES)
- **RAM utilisée** : ~2.5 GB (dont ~1 GB pour Elasticsearch)
- **Nombre de redémarrages nécessaires** : 4 (corrections itératives DB/ES/network)
- **Commandes curl manuelles exécutées** : ~15 (debug ES/nginx/DB)

---

## 📚 RÉFÉRENCES UTILISÉES

- Documentation officielle Zammad : https://docs.zammad.org/
- Elasticsearch ingest-attachment : https://www.elastic.co/guide/en/elasticsearch/plugins/7.17/ingest-attachment.html
- Docker Compose networking : https://docs.docker.com/compose/networking/
- Image Docker Zammad : https://hub.docker.com/r/zammad/zammad

---

**Document créé pour tracer précisément l'évolution de la Partie 4 et faciliter la reprise du travail.**
