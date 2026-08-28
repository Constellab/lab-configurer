#!/usr/bin/env bash
# Init the local dev environment : create the external docker networks and the
# host folders backing the docker volumes of docker-compose.yml.
#
# The volumes are named volumes bound to a folder on the host, so the folders
# must exist before `docker compose up` (docker does not create them).
# Creating them here (and not letting docker do it) also means they belong to
# the current user, whose uid is 1000, like labuser inside the containers.
#
# The script is idempotent, it can be run again safely.
#
# Usage : bash init.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ----------------------------------------------------------------------------
# Networks
# ----------------------------------------------------------------------------
# Networks shared with the containers created by the lab manager, they are
# declared as external in the docker-compose file.
NETWORKS=(
  gencovery-network-dev
  gencovery-network-prod
)

for network in "${NETWORKS[@]}"; do
  if docker network inspect "${network}" >/dev/null 2>&1; then
    echo "Network ${network} already exists"
  else
    docker network create "${network}" >/dev/null
    echo "Network ${network} created"
  fi
done

# ----------------------------------------------------------------------------
# Volume folders
# ----------------------------------------------------------------------------
# Read DOCKER_VOLUMES_ROOT from .env, a variable already set in the shell wins
# over the .env value (same precedence as docker compose)
SHELL_VOLUMES_ROOT="${DOCKER_VOLUMES_ROOT:-}"
if [ -f "${SCRIPT_DIR}/.env" ]; then
  # shellcheck disable=SC1091
  set -a && source "${SCRIPT_DIR}/.env" && set +a
fi
DOCKER_VOLUMES_ROOT="${SHELL_VOLUMES_ROOT:-${DOCKER_VOLUMES_ROOT:-${HOME}/gencovery/dev-env-volumes}}"

# volume name -> folder under DOCKER_VOLUMES_ROOT, must match the volumes
# section of docker-compose.yml
VOLUMES=(
  "dev-env-app:dev-env/app"
  "dev-env-data:dev-env/data"
  "dev-env-vscode:dev-env/vscode"
  "dev-env-claude:dev-env/claude"
  "lab-manager-home:lab-manager/home"
  "lab-manager-config:lab-manager/config"
  "lab-manager-prod-db:lab-manager/prod-db"
  "lab-manager-dev-db:lab-manager/dev-db"
  "lab-manager-prod-lab:lab-manager/prod-lab"
  "lab-manager-prod-data:lab-manager/prod-data"
  "lab-manager-dev-lab:lab-manager/dev-lab"
  "lab-manager-dev-data:lab-manager/dev-data"
  "space-db:db/space"
  "community-db:db/community"
  "lab-db:db/lab"
)

STALE=()
for entry in "${VOLUMES[@]}"; do
  volume="${entry%%:*}"
  folder="${entry#*:}"

  mkdir -p "${DOCKER_VOLUMES_ROOT}/${folder}"

  # The host folder of a volume is set when the volume is created and is never
  # updated afterwards. So if DOCKER_VOLUMES_ROOT was modified, the existing
  # volumes still point to the previous folder, and docker compose asks to
  # recreate them on the next `up`.
  device="$(docker volume inspect "${volume}" --format '{{index .Options "device"}}' 2>/dev/null || true)"
  if [ -n "${device}" ] && [ "${device}" != "${DOCKER_VOLUMES_ROOT}/${folder}" ]; then
    STALE+=("${volume} (${device})")
  fi
done

echo "Volume folders ready in ${DOCKER_VOLUMES_ROOT}"

if [ "${#STALE[@]}" -gt 0 ]; then
  echo ""
  echo "WARNING: thoses volumes still point to another folder :" >&2
  for stale in "${STALE[@]}"; do
    echo "  - ${stale}" >&2
  done
  echo "docker compose will ask to recreate them, answer yes : the volume is recreated" >&2
  echo "but no data is lost, the data is in the host folder, not in the volume itself." >&2
  echo "The data of the previous folder is not moved, copy it manually if you need it." >&2
fi

if [ "$(id -u)" != "1000" ]; then
  echo ""
  echo "WARNING: your uid is $(id -u) but labuser uses uid 1000 in the containers." >&2
  echo "         You may hit permission issues in /lab, /data and /home/labuser." >&2
fi

echo ""
echo "Local dev environment initialized, you can now run : docker compose --env-file ./.env up -d"
