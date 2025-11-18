# Makefile pour simplifier la gestion de la stack IT
.PHONY: help up down logs clean configure build restart status

# Variables
COMPOSE_FILE := docker-compose.yml
PROJECT_NAME := ticketing-stack

# Couleurs pour les messages
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Afficher cette aide
	@echo "$(GREEN)=== Infrastructure IT Conteneurisée ===$(NC)"
	@echo "Commandes disponibles :"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

up: ## Démarrer tous les services
	@echo "$(GREEN)🚀 Démarrage de la stack IT...$(NC)"
	docker compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)✅ Stack démarrée !$(NC)"
	@echo "$(YELLOW)💡 Pensez à exécuter 'make configure' pour configurer automatiquement$(NC)"

down: ## Arrêter tous les services
	@echo "$(YELLOW)🛑 Arrêt de la stack IT...$(NC)"
	docker compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✅ Stack arrêtée$(NC)"

logs: ## Afficher les logs de tous les services
	docker compose -f $(COMPOSE_FILE) logs -f

logs-%: ## Afficher les logs d'un service spécifique (ex: make logs-zammad-app)
	docker compose -f $(COMPOSE_FILE) logs -f $*

status: ## Afficher l'état des conteneurs
	@echo "$(GREEN)📊 État des services :$(NC)"
	docker compose -f $(COMPOSE_FILE) ps

clean: ## Supprimer tous les conteneurs et volumes (ATTENTION: données perdues)
	@echo "$(RED)⚠️  ATTENTION: Cette commande supprime TOUTES les données !$(NC)"
	@read -p "Êtes-vous sûr ? (tapez 'yes' pour confirmer): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(YELLOW)🧹 Nettoyage complet...$(NC)"; \
		docker compose -f $(COMPOSE_FILE) down -v --remove-orphans; \
		docker system prune -f; \
		echo "$(GREEN)✅ Nettoyage terminé$(NC)"; \
	else \
		echo "$(YELLOW)Opération annulée$(NC)"; \
	fi

configure: ## Configurer automatiquement les services (SMTP + LDAP)
	@echo "$(GREEN)⚙️  Configuration automatique en cours...$(NC)"
	./configure.sh

build: ## Rebuild les images personnalisées
	@echo "$(GREEN)🔨 Rebuild des images...$(NC)"
	docker compose -f $(COMPOSE_FILE) build --no-cache
	@echo "$(GREEN)✅ Images rebuildées$(NC)"

restart: ## Redémarrer tous les services
	@echo "$(YELLOW)🔄 Redémarrage de la stack...$(NC)"
	docker compose -f $(COMPOSE_FILE) restart
	@echo "$(GREEN)✅ Stack redémarrée$(NC)"

restart-%: ## Redémarrer un service spécifique (ex: make restart-nginx)
	docker compose -f $(COMPOSE_FILE) restart $*

shell-%: ## Ouvrir un shell dans un conteneur (ex: make shell-zammad-app)
	docker compose -f $(COMPOSE_FILE) exec $* bash

setup: ## Setup complet (build + up + configure)
	@echo "$(GREEN)🚀 Setup complet de la stack IT...$(NC)"
	make build
	make up
	@echo "$(YELLOW)⏳ Attente du démarrage complet (60s)...$(NC)"
	sleep 60
	make configure
	@echo "$(GREEN)✅ Setup terminé !$(NC)"
	@echo "$(YELLOW)🌐 Services accessibles :$(NC)"
	@echo "  - Zammad: http://zammad.projet.lan"
	@echo "  - Snipe-IT: http://snipeit.projet.lan"
	@echo "  - MailHog: http://mail.projet.lan"
	@echo "  - Utilisateur test: johndoe / password"