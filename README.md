# My Docker Home Lab

This repository contains a modular Docker-based home lab infrastructure. It is split into multiple stacks for easier management, separation of concerns, and maintainability.

---

## Project Structure

```
docker/
├── .env.example           # Example environment variables
├── compose/
│   ├── media-stack.yml    # Media services: Jellyfin, Plex, Sonarr, Radarr, Bazarr, Lidarr, Prowlarr, Jellyseerr
│   ├── infra-stack.yml    # Infrastructure: Nginx, Portainer, Heimdall, Watchtower
│   ├── vpn-stack.yml      # VPN services: Wireguard, DuckDNS
│   ├── torrent-stack.yml  # Torrent services: Gluetun, qBittorrent
│   ├── pihole-stack.yml   # Pi-hole
├── secrets/               # Secrets for containers (e.g., db passwords)
│   └── db_password.txt
├── Makefile               # Helper commands to manage stacks
├── .gitignore
└── README.md
```

---

## Features

* Fully modular stacks:

  * Media Stack: Jellyfin, Plex, Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, Jellyseerr
  * Infra Stack: Nginx, Portainer, Heimdall, Watchtower
  * VPN Stack: Wireguard, DuckDNS
  * Torrent Stack: Gluetun, qBittorrent
  * Pi-hole Stack
* `.env` support for secrets and configuration
* Separate networks for isolation, with shared network for Nginx and media services
* Makefile for simplified commands (`make up`, `make down`, `make all`, etc.)
* Automatic removal of orphan containers

---

## Setup

### 1. Clone the repository

```bash
git clone <repo-url> docker-home-lab
cd docker-home-lab
```

### 2. Copy the example `.env`

```bash
cp .env.example .env
```

* Edit `.env` with your environment variables (API keys, etc.)

### 3. (Optional) Add secrets

* Place any secret files in `secrets/` and reference them in your Compose files

---

## Makefile Usage

### Start a single stack

```bash
make up p=media     # Starts the media stack
make up p=infra     # Starts infra stack (Nginx, Portainer, Heimdall)
```

### Stop a single stack

```bash
make down p=torrent
```

### Restart a stack

```bash
make restart p=pihole
```

### Bring up all stacks

```bash
make all
```

* Recommended order ensures Nginx can resolve media services:

  1. Pi-hole
  2. VPN
  3. Torrent
  4. Media (Jellyfin, Plex, etc.)
  5. Infra (Nginx, Portainer, Heimdall)
  6. Apps (if any)

### Stop all stacks

```bash
make down-all
```

---

## Networks

* `media_infra_net` (external network): shared between Nginx and all media services
* Each stack also has its own default network for isolation:

  * VPN: `vpn_default`
  * Pi-hole: `pihole_network`
  * Torrent: `torrent_default`
  * Infra: `infra_default`

---

## Notes

* Nginx must start after media services to resolve hostnames like `jellyfin`
* Healthchecks can be added for reliable startup
* Make sure the `.env` file exists in the project root; Compose uses it automatically
* Orphan containers can be removed using:

```bash
docker-compose -f compose/<stack>.yml down --remove-orphans
```

---

## Docker Version

* Tested with Docker 20.10+ and `docker-compose` v1.29+
* If using the new CLI:

```bash
docker compose -f compose/<stack>.yml up -d
```

---

## Recommendations

* Keep your media services and Nginx on the shared network (`media_infra_net`)
* Other stacks can remain isolated
* Use `.env` and `secrets/` to avoid committing sensitive data
* Use Makefile commands to simplify stack management

---

## References

* [Docker Compose Documentation](https://docs.docker.com/compose/)
* [Docker Networks](https://docs.docker.com/network/)
* [LinuxServer.io Nginx](https://docs.linuxserver.io/images/docker-nginx)

