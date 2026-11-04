# My Docker Home Lab

This repository contains a modular Docker-based home lab infrastructure. It is split into multiple stacks for easier management, separation of concerns, and maintainability.

---

## Project Structure

```
docker/
├── .env.example                  # Example environment variables
├── compose/
│   ├── apps-stack.yml            # Apps: n8n, Syncthing, your_spotify
│   ├── media-stack.yml           # Media services: Jellyfin, Plex, Sonarr, Radarr, Bazarr, Lidarr, Prowlarr, Jellyseerr, Alternatrr, Maintainerr, Kavita, Suwayomi
│   ├── infra-stack.yml           # Infrastructure: Traefik, Portainer, Homepage, Watchtower
│   ├── vpn-stack.yml             # VPN services: Wireguard, DuckDNS
│   ├── torrent-stack.yml         # Torrent services: Gluetun, qBittorrent, qbit-diskguard
│   ├── pihole-stack.yml          # Pi-hole
│   ├── immich-stack.yml          # Immich
│   ├── observability-stack.yml   # Grafana, Prometheus and cAdvisor
├── scripts/
│   └── qbit-diskguard.sh         # Stops torrent downloads when the disk is low
├── Makefile                      # Helper commands to manage stacks
├── .gitignore
└── README.md
```

---

## Features

* Fully modular stacks:

  * App Stack: n8n, Syncthing, your_spotify
  * Media Stack: Jellyfin, Plex, Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, Jellyseerr, Alternatrr, Maintainerr, Kavita, Suwayomi
  * Infra Stack: Traefik, Portainer, Homepage, Watchtower
  * VPN Stack: Wireguard, DuckDNS
  * Torrent Stack: Gluetun, qBittorrent, qbit-diskguard
  * Pi-hole Stack
  * Photos Stack: Immich
  * Observability: Grafana, Prometheus and cAdvisor
* `.env` support for secrets and configuration
* Separate networks for isolation, with shared network for traefik, apps and media services
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

### 3. Fetch the Traefik fail2ban plugin

```bash
git clone --depth 1 --branch v0.8.9 https://github.com/tomMoulard/fail2ban traefik/plugins-local/src/github.com/tomMoulard/fail2ban
```

* Traefik loads the plugin from disk instead of downloading it at startup, so the routers using fail2ban keep working after a boot without internet

---

## Makefile Usage

### Start a single stack

```bash
make up p=media     # Starts the media stack
make up p=infra     # Starts infra stack (Traefik, Portainer, Homepage)
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

* Recommended order ensures Traefik can resolve media services:

  1. Pi-hole
  2. VPN
  3. Torrent
  4. Media (Jellyfin, Plex, etc.)
  5. Apps (n8n, Syncthing, your_spotify)
  6. Photos (Immich)
  7. Infra (Traefik, Portainer, Homepage)
  8. Observability (Grafana, Prometheus, cAdvisor)

### Stop all stacks

```bash
make down-all
```

---

## Networks

* `media_infra_net`: shared between Traefik and the media services
* `apps_infra_net`: shared between Traefik and the apps
* Each stack also has its own default network for isolation:

  * VPN: `vpn_default`
  * Pi-hole: `pihole_pihole_network` (macvlan)
  * Torrent: `torrent_default`
  * Infra: `infra_default`
  * Observability: `observability_monitoring`

---

## Notes

* Traefik must start after media services to resolve hostnames like `jellyfin`
* Healthchecks can be added for reliable startup
* Make sure the `.env` file exists in the project root; Compose uses it automatically
* `qbit-diskguard` stops downloading torrents when the torrent disk has less than 10GB free, and starts them again above 15GB (set in `torrent-stack.yml`)
* Orphan containers can be removed using:

```bash
docker compose -f compose/<stack>.yml down --remove-orphans
```

---

## Docker Version

* Tested with Docker CE 29 and the `docker compose` v2 plugin, from Docker's official apt repository
* Debian's own `docker.io` package (20.10) is too old: it can't unpack some newer images (`invalid tar header`)

---

## Recommendations

* Keep your media services and Traefik on the shared network (`media_infra_net`)
* Other stacks can remain isolated
* Use `.env` to avoid committing sensitive data
* Use Makefile commands to simplify stack management

---

## References

* [Docker Compose Documentation](https://docs.docker.com/compose/)
* [Docker Networks](https://docs.docker.com/network/)
* [Traefik Documentation](https://doc.traefik.io/traefik/)

