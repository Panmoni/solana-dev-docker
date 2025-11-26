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

# Check if volume exists
if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
  echo "✗ Docker volume not found: $VOLUME_NAME" >&2
  echo "Make sure the container has been started at least once." >&2
  exit 1
fi

BACKUP_DIR="${REPO_ROOT}/backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/solana-workspace-backup-${TIMESTAMP}.tar.gz"

echo "Creating backup of Docker volume: $VOLUME_NAME"
# Use a temporary container to backup the volume
docker run --rm \
  -v "$VOLUME_NAME":/workspace:ro \
  -v "$BACKUP_DIR":/backup \
  ubuntu:25.10 \
  tar -czf "/backup/$(basename "$BACKUP_FILE")" -C /workspace .

echo "✓ Backup created: $BACKUP_FILE"
echo "Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"
