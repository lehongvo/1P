#!/bin/bash

# =============================================================================
# INVALID SIZE FILE GENERATOR FOR TESTING FILE SIZE VALIDATION
# =============================================================================
#
# This script generates CSV files with different sizes to test the
# file size validation logic in your pipeline (min/max size).
#
# USAGE:
#   ./generate_invalid_size_files.sh [YYYY-MM-DD] [--clean]
#
# OPTIONS:
#   --clean   Clean all files from Docker container before uploading new files
#
# =============================================================================

set -e

# Import shared configuration from main script
source "$(dirname "$0")/generate_mock_data.sh" --source-only

if [ "${1}" == "--source-only" ]; then
    return 0
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CLEAN_DOCKER=0
INPUT_DATE=""

for arg in "$@"; do
    if [[ "$arg" == "--clean" ]]; then
        CLEAN_DOCKER=1
    elif [[ "$arg" == "--source-only" ]]; then
        continue
    elif [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        INPUT_DATE="$arg"
        if ! parse_date "$INPUT_DATE" "+%Y-%m-%d" >/dev/null; then
            echo -e "${RED}❌ Error: Invalid date '$INPUT_DATE'${NC}"
            exit 1
        fi
    elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        echo -e "${YELLOW}Usage: $0 [YYYY-MM-DD] [--clean]${NC}"
        exit 0
    else
        echo -e "${RED}❌ Error: Invalid argument '$arg'${NC}"
        exit 1
    fi
done

if [ -z "$INPUT_DATE" ]; then
    INPUT_DATE=$(date +%Y-%m-%d)
fi

DATE_PATTERN=$(parse_date "$INPUT_DATE" "+%Y%m%d")
DATE_DIR_FORMAT="$INPUT_DATE"
INVALID_SIZE_DIR="$BASE_DIR/$DATE_DIR_FORMAT/invalid_size"
mkdir -p "$INVALID_SIZE_DIR"

echo -e "${BLUE}=== INVALID SIZE FILE GENERATOR FOR TESTING ===${NC}"

# Generate small file (<1MB)
small_file="$INVALID_SIZE_DIR/TH_PRCH_${DATE_PATTERN}_SMALL.csv"
echo "item_id,price,start_date,end_date" > "$small_file"
head -c 500000 /dev/urandom | base64 >> "$small_file"
echo -e "${YELLOW}  Generated: $(basename "$small_file") (<1MB)${NC}"

# Generate valid file (~2MB)
valid_file="$INVALID_SIZE_DIR/TH_PRCH_${DATE_PATTERN}_VALID.csv"
echo "item_id,price,start_date,end_date" > "$valid_file"
head -c 2000000 /dev/urandom | base64 >> "$valid_file"
echo -e "${YELLOW}  Generated: $(basename "$valid_file") (~2MB)${NC}"

# Generate large file (>100MB)
large_file="$INVALID_SIZE_DIR/TH_PRCH_${DATE_PATTERN}_LARGE.csv"
echo "item_id,price,start_date,end_date" > "$large_file"
head -c 101000000 /dev/urandom | base64 >> "$large_file"
echo -e "${YELLOW}  Generated: $(basename "$large_file") (>100MB)${NC}"

echo -e "${GREEN}✅ All test files for file size validation generated${NC}"

# Upload files to Docker
for file in $INVALID_SIZE_DIR/*.csv; do
    if [ -f "$file" ]; then
        if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
            echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
        else
            echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
        fi
    fi
done

echo -e "${GREEN}✅ All files uploaded to Docker container${NC}"