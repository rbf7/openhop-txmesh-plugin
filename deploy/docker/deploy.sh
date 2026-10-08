#!/usr/bin/env bash
# Build and (re)deploy openhop-txmesh on the NAS from your fork.
# Run it ON the NAS:  ./deploy.sh        (first run creates templates and stops)
#
# Overridable: BASE, REPO_URL, BRANCH
set -euo pipefail

BASE="${BASE:-/volume1/docker/openhop-txmesh}"
REPO_URL="${REPO_URL:-https://github.com/rbf7/openhop-txmesh-plugin.git}"
BRANCH="${BRANCH:-main}"
CONTAINER_UID=15889            # must match the user in the Dockerfile

REPO="$BASE/repo"
SRC="$REPO/deploy/docker"
COMPOSE="$SRC/docker-compose.txmesh.yml"

log() { printf '\n==> %s\n' "$*"; }

command -v docker >/dev/null || { echo "docker not found" >&2; exit 1; }
command -v git    >/dev/null || { echo "git not found" >&2; exit 1; }

log "Directories under $BASE"
mkdir -p "$BASE/config" "$BASE/data"

log "Fetching $REPO_URL ($BRANCH)"
if [ -d "$REPO/.git" ]; then
  git -C "$REPO" fetch --prune origin
  git -C "$REPO" checkout "$BRANCH"
  git -C "$REPO" reset --hard "origin/$BRANCH"
else
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO"
fi

# Templates are copied only if missing, so your edits survive redeploys.
[ -f "$BASE/config/config.json" ] || cp "$SRC/config.json" "$BASE/config/config.json"
[ -f "$BASE/txmesh.env" ]         || cp "$SRC/env.example" "$BASE/txmesh.env"
chmod 600 "$BASE/txmesh.env"       # secrets; docker reads it as root
# The container runs as a non-root user, so the config dir must be world-readable.
# config.json holds nothing private (credentials are in txmesh.env).
chmod 755 "$BASE/config"
chmod 644 "$BASE/config/config.json"
chown -R "$CONTAINER_UID" "$BASE/data" 2>/dev/null \
  || echo "note: could not chown $BASE/data; run as root if the container can't write /data"

# Every one of these must be present in txmesh.env and not a YOUR-... placeholder.
# This also catches an older txmesh.env that predates a newly required variable.
missing=""
for key in OPENHOP_TXMESH_USERNAME OPENHOP_TXMESH_PASSWORD OPENHOP_TXMESH_NODE_NAME \
           OPENHOP_TXMESH_COMPANION_HOST TXMESH_NETWORK TXMESH_IP; do
  value="$(sed -n "s/^${key}=//p" "$BASE/txmesh.env" | tail -n1)"
  case "$value" in
    ""|YOUR-*) missing="$missing $key" ;;
  esac
done

if [ -n "$missing" ]; then
  cat <<MSG

Not deploying yet. Set these in $BASE/txmesh.env:
 $missing
(see $SRC/env.example for the full list), then run ./deploy.sh again.
Optional: $BASE/config/config.json (channels to join).
MSG
  exit 1
fi

log "Building image and starting the container"
# --env-file feeds the ${...} values in the compose file (IP, network, TZ).
BASE="$BASE" docker compose --env-file "$BASE/txmesh.env" -f "$COMPOSE" up -d --build

log "Last log lines"
sleep 5
docker logs --tail 30 openhop-txmesh 2>&1 || true
