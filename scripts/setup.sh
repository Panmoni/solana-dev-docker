#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_BIN="docker compose"
ENV_FILE="${REPO_ROOT}/.env"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

WORKSPACE="${SOLANA_WORKSPACE_DIR:-${HOME}/solana-workspace}"

log() {
  printf '→ %s\n' "$1"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "✗ Missing required command: $1" >&2
    exit 1
  fi
}

log "Performing pre-flight checks"
require_command docker
$COMPOSE_BIN version >/dev/null

if ! docker info >/dev/null 2>&1; then
  echo "✗ Docker daemon is not running or accessible." >&2
  exit 1
fi

if [[ "$WORKSPACE" != /* ]]; then
  echo "✗ SOLANA_WORKSPACE_DIR must be an absolute path. Current value: $WORKSPACE" >&2
  exit 1
fi

if [ ! -d "$WORKSPACE" ]; then
  mkdir -p "$WORKSPACE"
  log "Created workspace directory at $WORKSPACE"
else
  log "Workspace directory already exists"
fi

if [ ! -f "${REPO_ROOT}/.env" ] && [ -f "${REPO_ROOT}/env.example" ]; then
  cp "${REPO_ROOT}/env.example" "${REPO_ROOT}/.env"
  log "No .env found; copied defaults from env.example"
fi

log "Building Ubuntu 25.10 Solana workspace image"
(cd "$REPO_ROOT" && $COMPOSE_BIN build --pull solana-dev)

log "Starting container in background"
(cd "$REPO_ROOT" && $COMPOSE_BIN up -d solana-dev)

echo "✓ Container is ready."
echo ""
echo "Access the container with:"
echo "  docker compose exec solana-dev bash"
echo ""
echo "Your work persists at: $WORKSPACE"