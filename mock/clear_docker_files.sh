#!/bin/bash

# =============================================================================
# CLEAR ALL FILES IN DOCKER SFTP/SAO/RPM DIRECTORIES
#
# Usage:
#   ./clear_docker_files.sh                 # Clear all files (safe: keep folders)
#   ./clear_docker_files.sh --hard          # Clear files and remove empty subfolders
#   ./clear_docker_files.sh --container NAME
#   ./clear_docker_files.sh -h|--help
#
# Notes:
# - Default container: lotus-sftp-1
# - Only deletes files inside known SFTP/SAO/RPM paths
# - --hard also cleans up empty subdirectories
# =============================================================================

set -euo pipefail

# Default configuration (can be overridden by --container)
DOCKER_CONTAINER="lotus-sftp-1"
HARD_DELETE=0

print_help() {
    cat <<EOF
Usage: $0 [--hard] [--container NAME]

Options:
  --hard                 Remove empty subdirectories after deleting files
  --container NAME       Docker container name (default: lotus-sftp-1)
  -h, --help             Show this help

This script clears ALL files inside the following directories in the Docker container:
  - /home/demo/sftp/Data/ITSRPC/outgoing_ok/RPR/TH
  - /home/demo/sftp/Data/ITSPMT/outgoing_ok/PPR/TH
  - /home/demo/sftp/Data/ITSRPC/incoming/RPR/TH/ok/**
  - /home/demo/sftp/Data/ITSPMT/incoming/PPR/TH/ok/**
  - /home/demo/soa/Data/ITSRPC/outgoing_ok/RPR/TH
  - /home/demo/soa/Data/ITSPMT/outgoing_ok/PPR/TH
  - /home/demo/soa/Data/ITSRPC/incoming/RPR/TH/ok/**
  - /home/demo/soa/Data/ITSPMT/incoming/PPR/TH/ok/**
  - /home/demo/sftp/rpm/processed
  - /home/demo/sftp/rpm/pending

Use --hard to also remove now-empty subdirectories under the feedback paths.
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --hard)
            HARD_DELETE=1
            shift
            ;;
        --container)
            DOCKER_CONTAINER=${2:-}
            if [[ -z "${DOCKER_CONTAINER}" ]]; then
                echo "Error: --container requires a value" >&2
                exit 1
            fi
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            print_help
            exit 1
            ;;
    esac
done

echo "[info] Target container: ${DOCKER_CONTAINER}"
echo "[info] Mode: delete files$( [[ ${HARD_DELETE} -eq 1 ]] && echo ", remove empty subfolders" )"

# Validate container is running
if ! docker ps --format '{{.Names}}' | grep -qx "${DOCKER_CONTAINER}"; then
    echo "[error] Docker container '${DOCKER_CONTAINER}' is not running" >&2
    echo "[hint] Start it first, e.g., docker compose up -d" >&2
    exit 1
fi

# Execute cleanup inside container
echo "[info] Executing cleanup inside container..."
docker exec -e HARD_DELETE="${HARD_DELETE}" "${DOCKER_CONTAINER}" bash -lc '
    set -e
    shopt -s nullglob

    declare -a CLEAN_DIRS=(
        "/home/demo/sftp/Data/ITSRPC/outgoing_ok/RPR/TH"
        "/home/demo/sftp/Data/ITSPMT/outgoing_ok/PPR/TH"
        "/home/demo/sftp/Data/ITSRPC/incoming/RPR/TH/ok"
        "/home/demo/sftp/Data/ITSPMT/incoming/PPR/TH/ok"
        "/home/demo/soa/Data/ITSRPC/outgoing_ok/RPR/TH"
        "/home/demo/soa/Data/ITSPMT/outgoing_ok/PPR/TH"
        "/home/demo/soa/Data/ITSRPC/incoming/RPR/TH/ok"
        "/home/demo/soa/Data/ITSPMT/incoming/PPR/TH/ok"
        "/home/demo/sftp/rpm/processed"
        "/home/demo/sftp/rpm/pending"
    )

    echo "[container] Cleaning files in known directories..."
    for dir in "${CLEAN_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            echo "  - $dir"
            # Delete all files under the target directory (recursively)
            find "$dir" -type f -print -delete || true

            # Optionally remove empty subdirectories
            if [[ "${HARD_DELETE}" == "1" ]]; then
                find "$dir" -type d -empty -print -delete || true
            fi
        fi
    done

    echo "[container] Cleanup completed."
'

echo "[done] All files cleared inside '${DOCKER_CONTAINER}'."