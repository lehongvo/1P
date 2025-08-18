#!/bin/bash

# Simple file size validation test script - generates only 3-4 files for quick testing
# Tests the _validate_file_size function with minimal file generation

set -e

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the base script for shared functions and configurations (source-only mode)
source "$SCRIPT_DIR/generate_mock_data.sh" --source-only

# Handle arguments - date and clean flag
CLEAN_MODE=false
DATE_PROVIDED=false

# Check for clean flag
if [[ "$*" == *"--clean"* ]]; then
    CLEAN_MODE=true
fi

# Override the date if provided (and it's not just --clean)
if [ $# -ge 1 ] && [ "$1" != "--clean" ]; then
    DATE="$1"
    DATE_PROVIDED=true
fi

# If no date was provided but we're in any mode, use current date
if [ "$DATE_PROVIDED" = false ]; then
    DATE=$(date +%Y-%m-%d)
fi

# Create test directory
TEST_DIR="$BASE_DIR/filesize_test_$DATE"
mkdir -p "$TEST_DIR"

echo "=== Simple File Size Validation Test ==="
echo "Date: $DATE"
echo "Test directory: $TEST_DIR"
echo "Generating 4 test files (1 too small, 1 too large, 2 valid)..."
echo

# File counters
FILES_CREATED=0
SMALL_FILES=0
LARGE_FILES=0
VALID_FILES=0

# Function to create a small file (< 1MB)
create_small_file() {
    local filename="$1"
    local domain="$2"
    
    echo "Creating small file: $filename (target: ~500KB)"
    
    # Create header based on domain
    if [ "$domain" = "price" ]; then
        echo "item_id,price,start_date,end_date" > "$filename"
    else
        echo "item_id,discount,start_date,end_date" > "$filename"
    fi
    
    # Add about 8000 rows (approximately 500KB)
    for i in {1..8000}; do
        if [ "$domain" = "price" ]; then
            echo "ITEM_${i},$(( (RANDOM % 10000) + 100 )).$(( RANDOM % 100 )),2025-01-01,2025-12-31"
        else
            echo "ITEM_${i},0.$(( RANDOM % 50 + 10 )),2025-01-01,2025-12-31"
        fi
    done >> "$filename"
    
    SMALL_FILES=$((SMALL_FILES + 1))
    FILES_CREATED=$((FILES_CREATED + 1))
}

# Function to create a large file (> 100MB)
create_large_file() {
    local filename="$1"
    local domain="$2"
    
    echo "Creating large file: $filename (target: ~150MB to ensure > 100MB)"
    
    # Create header based on domain
    if [ "$domain" = "price" ]; then
        echo "item_id,price,start_date,end_date,description,batch_id,additional_data" > "$filename"
    else
        echo "item_id,discount,start_date,end_date,description,batch_id,additional_data" > "$filename"
    fi
    
    # Add about 3.5 million rows with longer data (approximately 150MB+)
    echo "  Generating 3.5M rows (this may take 60-90 seconds)..."
    for i in {1..3500000}; do
        if [ "$domain" = "price" ]; then
            echo "ITEM_${i},$(( (RANDOM % 10000) + 100 )).$(( RANDOM % 100 )),2025-01-01,2025-12-31,LONG_PRODUCT_DESCRIPTION_FOR_ITEM_${i}_WITH_EXTRA_DATA_TO_INCREASE_FILE_SIZE,BATCH_$(printf '%08d' $i),ADDITIONAL_DATA_FIELD_FOR_TESTING_LARGE_FILE_GENERATION_$(printf '%08d' $i)"
        else
            echo "ITEM_${i},0.$(( RANDOM % 50 + 10 )),2025-01-01,2025-12-31,LONG_PROMOTION_DESCRIPTION_FOR_ITEM_${i}_WITH_EXTRA_DATA_TO_INCREASE_FILE_SIZE,BATCH_$(printf '%08d' $i),ADDITIONAL_DATA_FIELD_FOR_TESTING_LARGE_FILE_GENERATION_$(printf '%08d' $i)"
        fi
        
        # Progress indicator every 250k rows
        if [ $((i % 250000)) -eq 0 ]; then
            echo "    Progress: ${i}/3500000 rows..."
        fi
    done >> "$filename"
    
    LARGE_FILES=$((LARGE_FILES + 1))
    FILES_CREATED=$((FILES_CREATED + 1))
}

# Function to create a valid-sized file (1MB - 100MB)
create_valid_file() {
    local filename="$1"
    local domain="$2"
    local target_mb="$3"
    
    echo "Creating valid file: $filename (target: ~${target_mb}MB)"
    
    # Create header based on domain
    if [ "$domain" = "price" ]; then
        echo "item_id,price,start_date,end_date" > "$filename"
    else
        echo "item_id,discount,start_date,end_date" > "$filename"
    fi
    
    # Calculate rows needed (approximately 50 bytes per row)
    local rows_needed=$((target_mb * 1024 * 1024 / 50))
    
    echo "  Generating ${rows_needed} rows..."
    for i in $(seq 1 $rows_needed); do
        if [ "$domain" = "price" ]; then
            echo "ITEM_${i},$(( (RANDOM % 10000) + 100 )).$(( RANDOM % 100 )),2025-01-01,2025-12-31"
        else
            echo "ITEM_${i},0.$(( RANDOM % 50 + 10 )),2025-01-01,2025-12-31"
        fi
        
        # Progress indicator
        if [ $((i % 50000)) -eq 0 ]; then
            echo "    Progress: ${i}/${rows_needed} rows..."
        fi
    done >> "$filename"
    
    VALID_FILES=$((VALID_FILES + 1))
    FILES_CREATED=$((FILES_CREATED + 1))
}

# Generate the 4 test files
echo "1. Generating small file (< 1MB)..."
create_small_file "$TEST_DIR/price_small_${DATE}.csv" "price"

echo
echo "2. Generating large file (> 100MB)..."
create_large_file "$TEST_DIR/promotion_large_${DATE}.csv" "promotion"

echo
echo "3. Generating valid file #1 (~5MB)..."
create_valid_file "$TEST_DIR/price_valid_${DATE}.csv" "price" 5

echo
echo "4. Generating valid file #2 (~10MB)..."
create_valid_file "$TEST_DIR/promotion_valid_${DATE}.csv" "promotion" 10

echo
echo "=== File Generation Complete ==="
echo

# Show file sizes
echo "Generated files and their sizes:"
ls -lh "$TEST_DIR"/*.csv | awk '{print $9, $5}'
echo

# Upload to Docker container (1P directories) if it exists
DOCKER_CONTAINER="lotus-sftp-1"
if command -v docker &> /dev/null && docker ps | grep -q "$DOCKER_CONTAINER"; then
    echo "Uploading files to Docker SFTP container (1P directories)..."
    
    # 1P folder mappings (same as generate_mock_data.sh)
    SFTP_1P_PRICE="/home/demo/sftp/Data/ITSRPC/outgoing_ok/RPR/TH"
    SFTP_1P_PROMOTION="/home/demo/sftp/Data/ITSPMT/outgoing_ok/PPR/TH"
    
    # Create 1P directories in Docker container
    echo "  Creating 1P directories in container..."
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_1P_PRICE" "$SFTP_1P_PROMOTION" >/dev/null 2>&1 || true
    
    # Ensure top-level symlinks exist
    docker exec $DOCKER_CONTAINER bash -lc '
        mkdir -p /home/demo/sftp || true
        if [ ! -e /sftp ]; then ln -s /home/demo/sftp /sftp; fi
    ' >/dev/null 2>&1 || true
    
    # Upload price files to 1P price directory
    echo "  Uploading price files to 1P..."
    for file in "$TEST_DIR"/price_*.csv; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            echo "    Uploading $filename to 1P Price directory..."
            if docker cp "$file" "$DOCKER_CONTAINER:$SFTP_1P_PRICE/$filename" >/dev/null 2>&1; then
                echo "      ✅ Success: $filename"
            else
                echo "      ❌ Failed: $filename"
            fi
        fi
    done
    
    # Upload promotion files to 1P promotion directory
    echo "  Uploading promotion files to 1P..."
    for file in "$TEST_DIR"/promotion_*.csv; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            echo "    Uploading $filename to 1P Promotion directory..."
            if docker cp "$file" "$DOCKER_CONTAINER:$SFTP_1P_PROMOTION/$filename" >/dev/null 2>&1; then
                echo "      ✅ Success: $filename"
            else
                echo "      ❌ Failed: $filename"
            fi
        fi
    done
    
    # Fix ownership for 1P directories
    echo "  Fixing file ownership in 1P directories..."
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory $SFTP_1P_PRICE $SFTP_1P_PROMOTION 2>/dev/null || true"
    
    echo "✅ Files uploaded to 1P directories in Docker SFTP container"
    echo "   📊 Price files → $SFTP_1P_PRICE"
    echo "   🎯 Promotion files → $SFTP_1P_PROMOTION"
else
    echo "Docker container '$DOCKER_CONTAINER' not found. Files remain in local directory only."
fi

echo
echo "=== Test Summary ==="
echo "Total files created: $FILES_CREATED"
echo "  - Small files (< 1MB): $SMALL_FILES - Expected to FAIL file size validation"
echo "  - Large files (> 100MB): $LARGE_FILES - Expected to FAIL file size validation"
echo "  - Valid files (1MB-100MB): $VALID_FILES - Expected to PASS file size validation"
echo
echo "Test files location: $TEST_DIR"
echo
echo "Expected validation results:"
echo "  - price_small_${DATE}.csv: FAIL (too small)"
echo "  - promotion_large_${DATE}.csv: FAIL (too large)"
echo "  - price_valid_${DATE}.csv: PASS (valid size)"
echo "  - promotion_valid_${DATE}.csv: PASS (valid size)"
echo

if [ "$CLEAN_MODE" = true ]; then
    echo "Cleaning up local test directory..."
    rm -rf "$TEST_DIR"
    echo "Local files cleaned up."
else
    echo "Run with --clean flag to remove local test files after generation."
fi

echo "=== File Size Validation Test Complete ==="
