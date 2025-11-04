# Makefile for Docker stacks
# Usage:
#   make up p=media      # bring up a single project
#   make down p=torrent  # stop a single project
#   make all             # bring up all projects
#   make down-all        # stop all projects

SHELL := /bin/bash
DC=docker-compose        # change to 'docker compose' if you upgrade Docker CLI
COMPOSE_DIR=compose

# Compose files
MEDIA_FILE=$(COMPOSE_DIR)/media-stack.yml
INFRA_FILE=$(COMPOSE_DIR)/infra-stack.yml
APPS_FILE=$(COMPOSE_DIR)/apps-stack.yml
TORRENT_FILE=$(COMPOSE_DIR)/torrent-stack.yml
PIHOLE_FILE=$(COMPOSE_DIR)/pihole-stack.yml
VPN_FILE=$(COMPOSE_DIR)/vpn-stack.yml

.PHONY: up down restart all down-all

# ==== Bring up a single project ====
up:
	@case "$(p)" in \
		media) FILE=$(MEDIA_FILE) ;; \
		infra) FILE=$(INFRA_FILE) ;; \
		apps) FILE=$(APPS_FILE) ;; \
		torrent) FILE=$(TORRENT_FILE) ;; \
		pihole) FILE=$(PIHOLE_FILE) ;; \
		vpn) FILE=$(VPN_FILE) ;; \
		*) echo "Error: unknown project '$(p)'. Available: media, infra, apps, torrent, pihole, vpn"; exit 1 ;; \
	esac; \
	echo "Bringing up project $(p)..."; \
	$(DC) --env-file .env -p $(p) -f $$FILE up -d --remove-orphans

# ==== Stop a single project ====
down:
	@case "$(p)" in \
		media) FILE=$(MEDIA_FILE) ;; \
		infra) FILE=$(INFRA_FILE) ;; \
		apps) FILE=$(APPS_FILE) ;; \
		torrent) FILE=$(TORRENT_FILE) ;; \
		pihole) FILE=$(PIHOLE_FILE) ;; \
		vpn) FILE=$(VPN_FILE) ;; \
		*) echo "Error: unknown project '$(p)'. Available: media, infra, apps, torrent, pihole, vpn"; exit 1 ;; \
	esac; \
	echo "Stopping project $(p)..."; \
	$(DC) --env-file .env -p $(p) -f $$FILE down

# ==== Restart a single project ====
restart: down up

# ==== Bring up all projects in recommended order ====
all:
	$(MAKE) up p=pihole
	$(MAKE) up p=vpn
	$(MAKE) up p=torrent
	$(MAKE) up p=media
	$(MAKE) up p=infra
	$(MAKE) up p=apps

# ==== Stop all projects in reverse order ====
down-all:
	$(MAKE) down p=apps
	$(MAKE) down p=infra
	$(MAKE) down p=media
	$(MAKE) down p=torrent
	$(MAKE) down p=vpn
	$(MAKE) down p=pihole

