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

WORKSPACE="${SOLANA_WORKSPACE_DIR:-${HOME}/solana-workspace}"

if [[ "$WORKSPACE" != /* ]]; then
  echo "✗ SOLANA_WORKSPACE_DIR must be an absolute path. Current value: $WORKSPACE" >&2
  exit 1
fi

if [ ! -d "$WORKSPACE" ]; then
  echo "✗ Workspace directory not found: $WORKSPACE" >&2
  exit 1
fi

BACKUP_DIR="${REPO_ROOT}/backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/solana-workspace-backup-${TIMESTAMP}.tar.gz"

echo "Creating backup of ${WORKSPACE}..."
tar -czf "$BACKUP_FILE" -C "$WORKSPACE" .

echo "✓ Backup created: $BACKUP_FILE"
echo "Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"