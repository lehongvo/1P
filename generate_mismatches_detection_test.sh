#!/bin/bash

# =============================================================================
# MISMATCHES DETECTION TEST SCRIPT
# 
# Purpose: Test the detect_mismatches task from CLUSTER 4: MONITORING & RECONCILIATION
# Task ID: detect_mismatches
# Function: _detect_mismatches
# 
# This script generates test scenarios to validate file matching detection
# between 1P, SOA, and RPM stages in the data pipeline
# =============================================================================

set -e

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the base script for shared configurations
source "$SCRIPT_DIR/generate_mock_data.sh" --source-only

# Parse arguments
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
            echo "❌ Error: Invalid date '$INPUT_DATE'"
            exit 1
        fi
    elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        echo "Usage: $0 [YYYY-MM-DD] [--clean]"
        echo "  YYYY-MM-DD: Target date for test files"
        echo "  --clean: Clean existing files before generating new ones"
        exit 0
    fi
done

# Use current date if not provided
if [ -z "$INPUT_DATE" ]; then
    INPUT_DATE=$(date +%Y-%m-%d)
fi

# Docker container configuration
DOCKER_CONTAINER="lotus-sftp-1"

# Generate date formats from input (matching generate_mock_data.sh)
DATE_PATTERN=$(parse_date "$INPUT_DATE" "+%Y%m%d")
DATE_FORMAT=$(parse_date "$INPUT_DATE" "+%d%b%Y")
DATE_DIR_FORMAT="$INPUT_DATE"

# Test directory
TEST_DIR="$BASE_DIR/mismatches_test_$INPUT_DATE"
mkdir -p "$TEST_DIR"

echo "=== MISMATCHES DETECTION TEST ===" 
echo "Date: $INPUT_DATE"
echo "Test directory: $TEST_DIR"
echo "Testing file matching between 1P → SOA → RPM stages"
echo

# 1P, SOA, RPM folder paths (from generate_mock_data.sh)
SFTP_1P_PRICE="/home/demo/sftp/Data/ITSRPC/outgoing_ok/RPR/TH"
SFTP_1P_PROMOTION="/home/demo/sftp/Data/ITSPMT/outgoing_ok/PPR/TH"
SFTP_SOA_PRICE="/home/demo/soa/Data/ITSRPC/outgoing_ok/RPR/TH"
SFTP_SOA_PROMOTION="/home/demo/soa/Data/ITSPMT/outgoing_ok/PPR/TH"
SFTP_RPM_PROCESSED="/home/demo/sftp/rpm/processed"
SFTP_RPM_PENDING="/home/demo/sftp/rpm/pending"

# =============================================================================
# FUNCTION: Generate test files with different mismatch scenarios
# =============================================================================
generate_mismatch_test_files() {
    echo "📁 Generating test files with mismatch scenarios..."
    
    # Create local test files first
    mkdir -p "$TEST_DIR"/{1p_price,1p_promotion,soa_price,soa_promotion,rpm_processed,rpm_pending}
    
    # Generate timestamps for realistic file naming (matching generate_mock_data.sh)
    local base_hour=12
    local base_minute=0
    local base_second=0
    
    # Scenario 1: Files that match across all stages (GOOD)
    echo "  Creating matching files across all stages..."
    local match_timestamp=$(printf "%02d%02d%02d" $((base_hour)) $((base_minute)) $((base_second)))
    
    for stage_dir in "$TEST_DIR"/{1p_price,soa_price,rpm_processed}; do
        echo "Price,Item,Store,Date,Batch,Description" > "$stage_dir/TH_PRCH_${DATE_PATTERN}${match_timestamp}.ods"
        echo "100.50,ITEM001,STORE01,$INPUT_DATE,BATCH_MATCH,Matching file test data" >> "$stage_dir/TH_PRCH_${DATE_PATTERN}${match_timestamp}.ods"
    done
    
    for stage_dir in "$TEST_DIR"/{1p_promotion,soa_promotion,rpm_processed}; do
        echo "PromoID,Item,Discount,StartDate,EndDate,Batch,Description" > "$stage_dir/TH_PROMPRCH_${DATE_PATTERN}${match_timestamp}.ods"
        echo "PROMO001,ITEM001,0.20,$INPUT_DATE,2025-12-31,BATCH_MATCH,Matching promotion test data" >> "$stage_dir/TH_PROMPRCH_${DATE_PATTERN}${match_timestamp}.ods"
    done
    
    # Scenario 2: Files missing in SOA (1P → SOA mismatch)
    echo "  Creating files missing in SOA stage..."
    local missing_soa_timestamp=$(printf "%02d%02d%02d" $((base_hour + 1)) $((base_minute)) $((base_second)))
    
    echo "Price,Item,Store,Date,Batch,Description" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${missing_soa_timestamp}.ods"
    echo "200.00,ITEM002,STORE01,$INPUT_DATE,BATCH_SOA_MISSING,File missing in SOA stage" >> "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${missing_soa_timestamp}.ods"
    
    # Scenario 3: Files missing in RPM (SOA → RPM mismatch)
    echo "  Creating files missing in RPM stage..."
    local missing_rpm_timestamp=$(printf "%02d%02d%02d" $((base_hour + 2)) $((base_minute)) $((base_second)))
    
    for stage_dir in "$TEST_DIR"/{1p_price,soa_price}; do
        echo "Price,Item,Store,Date,Batch,Description" > "$stage_dir/TH_PRCH_${DATE_PATTERN}${missing_rpm_timestamp}.ods"
        echo "300.00,ITEM003,STORE01,$INPUT_DATE,BATCH_RPM_MISSING,File missing in RPM stage" >> "$stage_dir/TH_PRCH_${DATE_PATTERN}${missing_rpm_timestamp}.ods"
    done
    
    # Scenario 4: Files only in RPM (orphaned files)
    echo "  Creating orphaned files in RPM..."
    local orphaned_timestamp=$(printf "%02d%02d%02d" $((base_hour + 3)) $((base_minute)) $((base_second)))
    
    echo "Price,Item,Store,Date,Batch,Description" > "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${orphaned_timestamp}.ods"
    echo "400.00,ITEM004,STORE01,$INPUT_DATE,BATCH_ORPHANED,Orphaned file in RPM only" >> "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${orphaned_timestamp}.ods"
    
    # Scenario 5: Size mismatches (same filename, different content)
    echo "  Creating size mismatch scenarios..."
    local size_mismatch_timestamp=$(printf "%02d%02d%02d" $((base_hour + 4)) $((base_minute)) $((base_second)))
    
    # Small version in 1P
    echo "Price,Item" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${size_mismatch_timestamp}.ods"
    echo "500.00,ITEM005" >> "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${size_mismatch_timestamp}.ods"
    
    # Large version in SOA (more data)
    echo "Price,Item,Store,Date,Batch,Description,Extended" > "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${size_mismatch_timestamp}.ods"
    echo "500.00,ITEM005,STORE01,$INPUT_DATE,BATCH001,Extended description,Extra data" >> "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${size_mismatch_timestamp}.ods"
    echo "600.00,ITEM006,STORE01,$INPUT_DATE,BATCH001,Additional item,More data" >> "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${size_mismatch_timestamp}.ods"
    
    # Medium version in RPM
    echo "Price,Item,Store,Date" > "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${size_mismatch_timestamp}.ods"
    echo "500.00,ITEM005,STORE01,$INPUT_DATE" >> "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${size_mismatch_timestamp}.ods"
    
    echo "✅ Test files generated with various mismatch scenarios"
}

# =============================================================================
# FUNCTION: Upload test files to Docker container
# =============================================================================
upload_test_files_to_docker() {
    echo "🐳 Uploading test files to Docker container..."
    
    # Check if Docker container exists
    if ! command -v docker &> /dev/null || ! docker ps | grep -q "$DOCKER_CONTAINER"; then
        echo "❌ Docker container '$DOCKER_CONTAINER' not found"
        return 1
    fi
    
    # Clean existing files if requested
    if [ $CLEAN_DOCKER -eq 1 ]; then
        echo "🧹 Cleaning existing files..."
        docker exec $DOCKER_CONTAINER rm -f $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}* >/dev/null 2>&1 || true
        docker exec $DOCKER_CONTAINER rm -f $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}* >/dev/null 2>&1 || true
        docker exec $DOCKER_CONTAINER rm -f $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}* >/dev/null 2>&1 || true
        docker exec $DOCKER_CONTAINER rm -f $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}* >/dev/null 2>&1 || true
        docker exec $DOCKER_CONTAINER rm -f $SFTP_RPM_PROCESSED/TH_PRCH_${DATE_PATTERN}* >/dev/null 2>&1 || true
        docker exec $DOCKER_CONTAINER rm -f $SFTP_RPM_PROCESSED/TH_PROMPRCH_${DATE_PATTERN}* >/dev/null 2>&1 || true
        docker exec $DOCKER_CONTAINER rm -f $SFTP_RPM_PENDING/TH_PRCH_${DATE_PATTERN}* >/dev/null 2>&1 || true
        docker exec $DOCKER_CONTAINER rm -f $SFTP_RPM_PENDING/TH_PROMPRCH_${DATE_PATTERN}* >/dev/null 2>&1 || true
    fi
    
    # Create directories in Docker container
    echo "  Creating directories in container..."
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_1P_PRICE" "$SFTP_1P_PROMOTION" >/dev/null 2>&1 || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_SOA_PRICE" "$SFTP_SOA_PROMOTION" >/dev/null 2>&1 || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_RPM_PROCESSED" "$SFTP_RPM_PENDING" >/dev/null 2>&1 || true
    
    # Upload files to respective directories
    echo "  Uploading 1P Price files..."
    for file in "$TEST_DIR/1p_price"/*.ods; do
        if [ -f "$file" ]; then
            docker cp "$file" "$DOCKER_CONTAINER:$SFTP_1P_PRICE/" >/dev/null 2>&1
            echo "    ✅ $(basename "$file")"
        fi
    done
    
    echo "  Uploading 1P Promotion files..."
    for file in "$TEST_DIR/1p_promotion"/*.ods; do
        if [ -f "$file" ]; then
            docker cp "$file" "$DOCKER_CONTAINER:$SFTP_1P_PROMOTION/" >/dev/null 2>&1
            echo "    ✅ $(basename "$file")"
        fi
    done
    
    echo "  Uploading SOA Price files..."
    for file in "$TEST_DIR/soa_price"/*.ods; do
        if [ -f "$file" ]; then
            docker cp "$file" "$DOCKER_CONTAINER:$SFTP_SOA_PRICE/" >/dev/null 2>&1
            echo "    ✅ $(basename "$file")"
        fi
    done
    
    echo "  Uploading SOA Promotion files..."  
    for file in "$TEST_DIR/soa_promotion"/*.ods; do
        if [ -f "$file" ]; then
            docker cp "$file" "$DOCKER_CONTAINER:$SFTP_SOA_PROMOTION/" >/dev/null 2>&1
            echo "    ✅ $(basename "$file")"
        fi
    done
    
    echo "  Uploading RPM Processed files..."
    for file in "$TEST_DIR/rpm_processed"/*.ods; do
        if [ -f "$file" ]; then
            docker cp "$file" "$DOCKER_CONTAINER:$SFTP_RPM_PROCESSED/" >/dev/null 2>&1
            echo "    ✅ $(basename "$file")"
        fi
    done
    
    echo "  Uploading RPM Pending files..."
    for file in "$TEST_DIR/rpm_pending"/*.ods; do
        if [ -f "$file" ]; then
            docker cp "$file" "$DOCKER_CONTAINER:$SFTP_RPM_PENDING/" >/dev/null 2>&1
            echo "    ✅ $(basename "$file")"
        fi
    done
    
    # Fix ownership
    echo "  Fixing file ownership..."
    docker exec $DOCKER_CONTAINER chown -R demo:sftp-user-inventory \
        "$SFTP_1P_PRICE" "$SFTP_1P_PROMOTION" \
        "$SFTP_SOA_PRICE" "$SFTP_SOA_PROMOTION" \
        "$SFTP_RPM_PROCESSED" "$SFTP_RPM_PENDING" 2>/dev/null || true
    
    echo "✅ All test files uploaded to Docker container"
}

# =============================================================================
# FUNCTION: Display expected test results
# =============================================================================
show_expected_results() {
    echo
    echo "=== EXPECTED MISMATCH DETECTION RESULTS ==="
    echo
    echo "📊 Test Scenarios Generated:"
    echo "  1. ✅ MATCHING FILES (should PASS):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (exists in 1P, SOA, RPM)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (exists in 1P, SOA, RPM)"
    echo
    echo "  2. ❌ MISSING IN SOA (should DETECT mismatch):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (1P ✅, SOA ❌, RPM ❌)"
    echo
    echo "  3. ❌ MISSING IN RPM (should DETECT mismatch):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (1P ✅, SOA ✅, RPM ❌)"
    echo
    echo "  4. ❌ ORPHANED IN RPM (should DETECT mismatch):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (1P ❌, SOA ❌, RPM ✅)"
    echo
    echo "  5. ❌ SIZE MISMATCH (should DETECT mismatch):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (different sizes across stages)"
    echo
    echo "🔍 The detect_mismatches task should identify 4 mismatch scenarios"
    echo "📍 Files location in Docker:"
    echo "   - 1P: $SFTP_1P_PRICE, $SFTP_1P_PROMOTION"
    echo "   - SOA: $SFTP_SOA_PRICE, $SFTP_SOA_PROMOTION"
    echo "   - RPM: $SFTP_RPM_PROCESSED, $SFTP_RPM_PENDING"
    echo
    echo "🎯 Note: Files follow generate_mock_data.sh naming convention:"
    echo "   - TH_PRCH_${DATE_PATTERN}HHMMSS.ods (Price files)"
    echo "   - TH_PROMPRCH_${DATE_PATTERN}HHMMSS.ods (Promotion files)"
    echo
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    echo "🚀 Starting Mismatches Detection Test Generation..."
    
    # Generate test files
    generate_mismatch_test_files
    
    # Upload to Docker container
    upload_test_files_to_docker
    
    # Show expected results
    show_expected_results
    
    echo "=== MISMATCHES DETECTION TEST COMPLETE ==="
    echo "✅ Test data ready for detect_mismatches task validation"
    echo "📂 Local test files: $TEST_DIR"
    echo "🐳 Docker container files uploaded successfully"
    echo
    echo "💡 Run the DAG's detect_mismatches task to validate these scenarios"
}

# Run main function
main "$@"
