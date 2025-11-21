#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  set -a
  source "$ENV_FILE"
  set +a
fi

VOLUME_NAME="${SOLANA_VOLUME_NAME:-solana-workspace}"

if [ -z "${1:-}" ]; then
  echo "Usage: ./scripts/restore.sh <backup-file.tar.gz>"
  echo ""
  echo "Available backups:"
  ls -lh "${REPO_ROOT}/backups/"*.tar.gz 2>/dev/null || echo "No backups found in ${REPO_ROOT}/backups"
  exit 1
fi

BACKUP_FILE="$1"
if [ ! -f "$BACKUP_FILE" ] && [ -f "${REPO_ROOT}/$BACKUP_FILE" ]; then
  BACKUP_FILE="${REPO_ROOT}/$BACKUP_FILE"
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file not found: $BACKUP_FILE" >&2
  exit 1
fi

# Ensure volume exists (create if needed)
if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
  echo "Creating Docker volume: $VOLUME_NAME"
  docker volume create "$VOLUME_NAME"
fi

echo "WARNING: This will overwrite all data in Docker volume: $VOLUME_NAME"
read -r -p "Continue? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Restore cancelled"
  exit 0
fi

echo "Restoring from $BACKUP_FILE to volume $VOLUME_NAME..."
# Use a temporary container to restore the volume
# First, clear the volume
docker run --rm \
  -v "$VOLUME_NAME":/workspace \
  ubuntu:25.10 \
  sh -c "rm -rf /workspace/* /workspace/.* 2>/dev/null || true"

# Then extract the backup
docker run --rm \
  -v "$VOLUME_NAME":/workspace \
  -v "$(dirname "$BACKUP_FILE")":/backup:ro \
  ubuntu:25.10 \
  tar -xzf "/backup/$(basename "$BACKUP_FILE")" -C /workspace

echo "✓ Restore complete"
