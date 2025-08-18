#!/bin/bash

# =============================================================================
# MISSING FILES DETECTION TEST SCRIPT
# 
# Purpose: Test the detect_missing task from CLUSTER 4: MONITORING & RECONCILIATION
# Task ID: detect_missing
# Function: _detect_missing
# 
# This script generates test scenarios to validate detection of missing files
# across different stages (1P → SOA → RPM) in the data pipeline
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
TEST_DIR="$BASE_DIR/missing_files_test_$INPUT_DATE"
mkdir -p "$TEST_DIR"

echo "=== MISSING FILES DETECTION TEST ===" 
echo "Date: $INPUT_DATE"
echo "Test directory: $TEST_DIR"
echo "Testing missing file detection across 1P → SOA → RPM pipeline"
echo

# 1P, SOA, RPM folder paths
SFTP_1P_PRICE="/home/demo/sftp/Data/ITSRPC/outgoing_ok/RPR/TH"
SFTP_1P_PROMOTION="/home/demo/sftp/Data/ITSPMT/outgoing_ok/PPR/TH"
SFTP_SOA_PRICE="/home/demo/soa/Data/ITSRPC/outgoing_ok/RPR/TH"
SFTP_SOA_PROMOTION="/home/demo/soa/Data/ITSPMT/outgoing_ok/PPR/TH"
SFTP_RPM_PROCESSED="/home/demo/sftp/rpm/processed"
SFTP_RPM_PENDING="/home/demo/sftp/rpm/pending"

# =============================================================================
# FUNCTION: Generate test files with various missing file scenarios
# =============================================================================
generate_missing_files_test_scenarios() {
    echo "📁 Generating test files with missing file scenarios..."
    
    # Create local test directories
    mkdir -p "$TEST_DIR"/{1p_price,1p_promotion,soa_price,soa_promotion,rpm_processed,rpm_pending}
    
    # ==========================================================================
    # Scenario 1: Expected files with complete pipeline (BASELINE - should NOT be flagged as missing)
    # ==========================================================================
    echo "  Creating baseline files (complete pipeline)..."
    
    # Generate realistic timestamps
    local base_hour=10
    local base_minute=0
    local base_second=0
    
    # Price file - complete pipeline
    local complete_timestamp=$(printf "%02d%02d%02d" $base_hour $base_minute $base_second)
    for stage in "1p_price" "soa_price" "rpm_processed"; do
        echo "Price,Item,Store,Date,Batch,Description" > "$TEST_DIR/$stage/TH_PRCH_${DATE_PATTERN}${complete_timestamp}.ods"
        echo "100.00,ITEM_COMPLETE,STORE01,$INPUT_DATE,BATCH_COMPLETE,Complete pipeline test data" >> "$TEST_DIR/$stage/TH_PRCH_${DATE_PATTERN}${complete_timestamp}.ods"
    done
    
    # Promotion file - complete pipeline
    for stage in "1p_promotion" "soa_promotion" "rpm_processed"; do
        echo "PromoID,Item,Discount,StartDate,EndDate,Batch,Description" > "$TEST_DIR/$stage/TH_PROMPRCH_${DATE_PATTERN}${complete_timestamp}.ods"
        echo "PROMO_COMPLETE,ITEM_COMPLETE,0.15,$INPUT_DATE,2025-12-31,BATCH_COMPLETE,Complete promotion pipeline test" >> "$TEST_DIR/$stage/TH_PROMPRCH_${DATE_PATTERN}${complete_timestamp}.ods"
    done
    
    # ==========================================================================
    # Scenario 2: Files missing in SOA stage (1P uploaded but SOA transfer failed)
    # ==========================================================================
    echo "  Creating files missing in SOA stage..."
    
    # Price file exists in 1P only
    local missing_soa_timestamp=$(printf "%02d%02d%02d" $((base_hour + 1)) $base_minute $base_second)
    echo "Price,Item,Store,Date,Batch,Description" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${missing_soa_timestamp}.ods"
    echo "200.00,ITEM_SOA_MISSING,STORE01,$INPUT_DATE,BATCH_SOA_MISSING,File missing in SOA stage" >> "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${missing_soa_timestamp}.ods"
    
    # Promotion file exists in 1P only
    local missing_soa_promo_timestamp=$(printf "%02d%02d%02d" $((base_hour + 1)) $((base_minute + 1)) $base_second)
    echo "PromoID,Item,Discount,StartDate,EndDate,Batch,Description" > "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${missing_soa_promo_timestamp}.ods"
    echo "PROMO_SOA_MISSING,ITEM_SOA_MISSING,0.25,$INPUT_DATE,2025-12-31,BATCH_SOA_MISSING,Promotion missing in SOA" >> "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${missing_soa_promo_timestamp}.ods"
    
    # ==========================================================================
    # Scenario 3: Files missing in RPM stage (1P → SOA OK, but SOA → RPM failed)
    # ==========================================================================
    echo "  Creating files missing in RPM stage..."
    
    # Price file exists in 1P and SOA but missing in RPM
    local missing_rpm_timestamp=$(printf "%02d%02d%02d" $((base_hour + 2)) $base_minute $base_second)
    for stage in "1p_price" "soa_price"; do
        echo "Price,Item,Store,Date,Batch,Description" > "$TEST_DIR/$stage/TH_PRCH_${DATE_PATTERN}${missing_rpm_timestamp}.ods"
        echo "300.00,ITEM_RPM_MISSING,STORE01,$INPUT_DATE,BATCH_RPM_MISSING,File missing in RPM stage" >> "$TEST_DIR/$stage/TH_PRCH_${DATE_PATTERN}${missing_rpm_timestamp}.ods"
    done
    
    # Promotion file exists in 1P and SOA but missing in RPM
    local missing_rpm_promo_timestamp=$(printf "%02d%02d%02d" $((base_hour + 2)) $((base_minute + 1)) $base_second)
    for stage in "1p_promotion" "soa_promotion"; do
        echo "PromoID,Item,Discount,StartDate,EndDate,Batch,Description" > "$TEST_DIR/$stage/TH_PROMPRCH_${DATE_PATTERN}${missing_rpm_promo_timestamp}.ods"
        echo "PROMO_RPM_MISSING,ITEM_RPM_MISSING,0.35,$INPUT_DATE,2025-12-31,BATCH_RPM_MISSING,Promotion missing in RPM" >> "$TEST_DIR/$stage/TH_PROMPRCH_${DATE_PATTERN}${missing_rpm_promo_timestamp}.ods"
    done
    
    # ==========================================================================
    # Scenario 4: Files completely missing from pipeline (expected but not uploaded)
    # ==========================================================================
    echo "  Creating scenario for completely missing files..."
    # Note: These files are referenced in expected file lists but don't exist anywhere
    # The DAG should detect these as "expected but missing from all stages"
    
    # Create a manifest file that lists expected files (simulates expected file list)
    cat > "$TEST_DIR/expected_files_manifest.txt" << EOF
# Expected files for $DATE that should exist but are missing everywhere
TH_PRCH_${DATE_PATTERN}${timestamp}.ods
TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods
TH_PRCH_${DATE_PATTERN}${timestamp}.ods
TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods
EOF
    
    # ==========================================================================
    # Scenario 5: Time-dependent missing files (files expected at specific times)
    # ==========================================================================
    echo "  Creating time-dependent missing file scenarios..."
    
    # Morning batch files (should exist by 9 AM) - Missing
    # Usually these are daily batch files that should be generated automatically
    
    # Evening batch files (should exist by 6 PM) - Present
    echo "item_id,price,date,batch_time" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo "ITEM_EVENING,500.00,$DATE,18:00:00" >> "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Copy to SOA and RPM as well (complete pipeline)
    cp "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" "$TEST_DIR/soa_price/"
    cp "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" "$TEST_DIR/rpm_processed/"
    
    # ==========================================================================
    # Scenario 6: Feedback files missing (for feedback validation)
    # ==========================================================================
    echo "  Creating feedback files scenarios..."
    
    # Create feedback directories
    mkdir -p "$TEST_DIR"/{1p_feedback_price,1p_feedback_promotion,soa_feedback_price,soa_feedback_promotion}
    
    # Normal feedback file (exists)
    echo "feedback_id,status,processed_time" > "$TEST_DIR/1p_feedback_price/CP_FEEDBACK_${DATE_FORMAT}_120000.csv"
    echo "FB001,SUCCESS,$DATE 12:00:00" >> "$TEST_DIR/1p_feedback_price/CP_FEEDBACK_${DATE_FORMAT}_120000.csv"
    
    # Missing feedback for a processed file (feedback expected but missing)
    # This simulates when a file was processed but no feedback was received
    
    echo "✅ Test files generated with various missing file scenarios"
}

# =============================================================================
# FUNCTION: Upload test files to Docker container
# =============================================================================
upload_missing_files_test_to_docker() {
    echo "🐳 Uploading missing files test data to Docker container..."
    
    # Check if Docker container exists
    if ! command -v docker &> /dev/null || ! docker ps | grep -q "$DOCKER_CONTAINER"; then
        echo "❌ Docker container '$DOCKER_CONTAINER' not found"
        return 1
    fi
    
    # Create directories in Docker container
    echo "  Creating directories in container..."
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_1P_PRICE" "$SFTP_1P_PROMOTION" >/dev/null 2>&1 || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_SOA_PRICE" "$SFTP_SOA_PROMOTION" >/dev/null 2>&1 || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_RPM_PROCESSED" "$SFTP_RPM_PENDING" >/dev/null 2>&1 || true
    
    # Create feedback directories
    docker exec $DOCKER_CONTAINER mkdir -p "/home/demo/sftp/Data/ITSRPC/incoming/RPR/TH/ok/$DATE" >/dev/null 2>&1 || true
    docker exec $DOCKER_CONTAINER mkdir -p "/home/demo/sftp/Data/ITSPMT/incoming/PPR/TH/ok/$DATE" >/dev/null 2>&1 || true
    docker exec $DOCKER_CONTAINER mkdir -p "/home/demo/soa/Data/ITSRPC/incoming/RPR/TH/ok/$DATE" >/dev/null 2>&1 || true
    docker exec $DOCKER_CONTAINER mkdir -p "/home/demo/soa/Data/ITSPMT/incoming/PPR/TH/ok/$DATE" >/dev/null 2>&1 || true
    
    # Function to upload files from local directory to Docker
    upload_files() {
        local local_dir="$1"
        local docker_path="$2"
        local description="$3"
        
        if [ -d "$TEST_DIR/$local_dir" ] && [ -n "$(ls -A "$TEST_DIR/$local_dir" 2>/dev/null)" ]; then
            echo "  Uploading $description files..."
            for file in "$TEST_DIR/$local_dir"/*; do
                if [ -f "$file" ]; then
                    docker cp "$file" "$DOCKER_CONTAINER:$docker_path/" >/dev/null 2>&1
                    echo "    ✅ $(basename "$file")"
                fi
            done
        fi
    }
    
    # Upload files to respective directories
    upload_files "1p_price" "$SFTP_1P_PRICE" "1P Price"
    upload_files "1p_promotion" "$SFTP_1P_PROMOTION" "1P Promotion"
    upload_files "soa_price" "$SFTP_SOA_PRICE" "SOA Price"
    upload_files "soa_promotion" "$SFTP_SOA_PROMOTION" "SOA Promotion"
    upload_files "rpm_processed" "$SFTP_RPM_PROCESSED" "RPM Processed"
    upload_files "rpm_pending" "$SFTP_RPM_PENDING" "RPM Pending"
    
    # Upload feedback files
    upload_files "1p_feedback_price" "/home/demo/sftp/Data/ITSRPC/incoming/RPR/TH/ok/$DATE" "1P Feedback Price"
    upload_files "1p_feedback_promotion" "/home/demo/sftp/Data/ITSPMT/incoming/PPR/TH/ok/$DATE" "1P Feedback Promotion"
    upload_files "soa_feedback_price" "/home/demo/soa/Data/ITSRPC/incoming/RPR/TH/ok/$DATE" "SOA Feedback Price"
    upload_files "soa_feedback_promotion" "/home/demo/soa/Data/ITSPMT/incoming/PPR/TH/ok/$DATE" "SOA Feedback Promotion"
    
    # Upload expected files manifest to a reference location
    if [ -f "$TEST_DIR/expected_files_manifest.txt" ]; then
        docker cp "$TEST_DIR/expected_files_manifest.txt" "$DOCKER_CONTAINER:/tmp/expected_files_manifest_$DATE.txt" >/dev/null 2>&1
        echo "  ✅ Expected files manifest uploaded"
    fi
    
    # Fix ownership
    echo "  Fixing file ownership..."
    docker exec $DOCKER_CONTAINER chown -R demo:sftp-user-inventory \
        "$SFTP_1P_PRICE" "$SFTP_1P_PROMOTION" \
        "$SFTP_SOA_PRICE" "$SFTP_SOA_PROMOTION" \
        "$SFTP_RPM_PROCESSED" "$SFTP_RPM_PENDING" 2>/dev/null || true
    
    echo "✅ All missing files test data uploaded to Docker container"
}

# =============================================================================
# FUNCTION: Display expected test results
# =============================================================================
show_missing_files_expected_results() {
    echo
    echo "=== EXPECTED MISSING FILES DETECTION RESULTS ==="
    echo
    echo "📊 Test Scenarios Generated:"
    echo
    echo "  1. ✅ COMPLETE PIPELINE (should NOT be flagged as missing):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (1P ✅, SOA ✅, RPM ✅)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (1P ✅, SOA ✅, RPM ✅)"
    echo
    echo "  2. ❌ MISSING IN SOA (should DETECT as missing):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (1P ✅, SOA ❌, RPM ❌)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (1P ✅, SOA ❌, RPM ❌)"
    echo
    echo "  3. ❌ MISSING IN RPM (should DETECT as missing):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (1P ✅, SOA ✅, RPM ❌)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (1P ✅, SOA ✅, RPM ❌)"
    echo
    echo "  4. ❌ COMPLETELY MISSING (should DETECT as never uploaded):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (1P ❌, SOA ❌, RPM ❌)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (1P ❌, SOA ❌, RPM ❌)"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (1P ❌, SOA ❌, RPM ❌)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (1P ❌, SOA ❌, RPM ❌)"
    echo
    echo "  5. ⏰ TIME-DEPENDENT (missing expected batch files):"
    echo "     - Morning batch files (9 AM expected): MISSING - should be flagged"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods: PRESENT - should NOT be flagged"
    echo
    echo "  6. 📬 FEEDBACK FILES:"
    echo "     - CP_FEEDBACK_${DATE_FORMAT}_120000.csv: PRESENT - should NOT be flagged as missing"
    echo "     - Missing feedback for processed files: should be DETECTED"
    echo
    echo "🔍 The detect_missing task should identify:"
    echo "   - 2 files missing in SOA stage"
    echo "   - 2 files missing in RPM stage" 
    echo "   - 4 files completely missing from pipeline"
    echo "   - Time-dependent missing files"
    echo "   - Missing feedback files"
    echo
    echo "📍 Files location in Docker:"
    echo "   - Expected files manifest: /tmp/expected_files_manifest_$DATE.txt"
    echo "   - 1P: $SFTP_1P_PRICE, $SFTP_1P_PROMOTION"
    echo "   - SOA: $SFTP_SOA_PRICE, $SFTP_SOA_PROMOTION"
    echo "   - RPM: $SFTP_RPM_PROCESSED, $SFTP_RPM_PENDING"
    echo
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    echo "🚀 Starting Missing Files Detection Test Generation..."
    
    # Generate test files
    generate_missing_files_test_scenarios
    
    # Upload to Docker container
    upload_missing_files_test_to_docker
    
    # Show expected results
    show_missing_files_expected_results
    
    echo "=== MISSING FILES DETECTION TEST COMPLETE ==="
    echo "✅ Test data ready for detect_missing task validation"
    echo "📂 Local test files: $TEST_DIR"
    echo "🐳 Docker container files uploaded successfully"
    echo
    echo "💡 Run the DAG's detect_missing task to validate these scenarios"
}

# Run main function
main "$@"
