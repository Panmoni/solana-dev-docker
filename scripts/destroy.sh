#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"
COMPOSE_BIN="docker compose"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

VOLUME_NAME="${SOLANA_VOLUME_NAME:-solana-workspace}"
IMAGE_NAME="solana-dev-workspace:latest"
CONTAINER_NAME="solana-dev-container"

log() {
  printf '→ %s\n' "$1"
}

error() {
  printf '✗ %s\n' "$1" >&2
}

# Check if Docker is available
if ! command -v docker >/dev/null 2>&1; then
  error "Docker is not installed or not in PATH"
  exit 1
fi

if ! $COMPOSE_BIN version >/dev/null 2>&1; then
  error "Docker Compose is not available"
  exit 1
fi

echo "⚠️  WARNING: This will completely destroy your Solana development environment!"
echo ""
echo "This will remove:"
echo "  - Container: $CONTAINER_NAME"
echo "  - Volume: $VOLUME_NAME (ALL YOUR WORK WILL BE LOST!)"
echo "  - Image: $IMAGE_NAME"
echo "  - Network: solana-dev-docker_default"
echo ""
read -r -p "Are you absolutely sure? Type 'yes' to continue: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

log "Stopping and removing container..."
(cd "$REPO_ROOT" && $COMPOSE_BIN down -v 2>/dev/null || true)

log "Removing container if it still exists..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

log "Removing volume: $VOLUME_NAME"
docker volume rm "$VOLUME_NAME" 2>/dev/null || true

log "Removing image: $IMAGE_NAME"
docker rmi "$IMAGE_NAME" 2>/dev/null || true

log "Removing network if it exists..."
docker network rm solana-dev-docker_default 2>/dev/null || true

echo ""
echo "✓ Cleanup complete!"
echo ""
echo "To start fresh, run:"
echo "  ./scripts/setup.sh"

