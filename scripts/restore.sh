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

echo "WARNING: This will overwrite ${WORKSPACE}"
read -r -p "Continue? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Restore cancelled"
  exit 0
fi

echo "Restoring from $BACKUP_FILE..."
rm -rf "$WORKSPACE"
mkdir -p "$WORKSPACE"
tar -xzf "$BACKUP_FILE" -C "$WORKSPACE"
echo "✓ Restore complete"