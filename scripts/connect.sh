#!/bin/bash
# Connect to the Solana dev container from anywhere

CONTAINER_NAME="solana-dev-container"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✗ Container ${CONTAINER_NAME} is not running." >&2
    echo "  Start it with: cd /path/to/solana-dev-docker && ./scripts/setup.sh" >&2
    exit 1
fi

docker exec -it "${CONTAINER_NAME}" bash

