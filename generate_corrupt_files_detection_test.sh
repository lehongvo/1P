#!/bin/bash

# =============================================================================
# FOCUSED CORRUPTION DETECTION TEST SCRIPT
# 
# Purpose: Test ONLY detect_corrupt_files functionality
# Coverage: Core corruption scenarios without triggering other validation errors
# Schema: Files meet minimum requirements where possible, with intentional corruption
# Tasks Tested: ONLY detect_corrupt_files
# =============================================================================

set -e

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the base script for shared configurations
source "$SCRIPT_DIR/generate_mock_data.sh" --source-only

# Parse arguments
CLEAN_DOCKER=0
INPUT_DATE=""
PERFORMANCE_TEST=0
STRESS_TEST=0

for arg in "$@"; do
    if [[ "$arg" == "--clean" ]]; then
        CLEAN_DOCKER=1
    elif [[ "$arg" == "--performance" ]]; then
        PERFORMANCE_TEST=1
    elif [[ "$arg" == "--stress" ]]; then
        STRESS_TEST=1
    elif [[ "$arg" == "--source-only" ]]; then
        continue
    elif [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        INPUT_DATE="$arg"
        if ! parse_date "$INPUT_DATE" "+%Y-%m-%d" >/dev/null; then
            echo "❌ Error: Invalid date '$INPUT_DATE'"
            exit 1
        fi
    elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        echo "Usage: $0 [YYYY-MM-DD] [--clean] [--performance] [--stress]"
        echo "  YYYY-MM-DD: Target date for test files"
        echo "  --clean: Clean existing files before generating new ones"
        echo "  --performance: Run performance benchmarking tests"
        echo "  --stress: Run stress tests with large datasets"
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
TEST_DIR="$BASE_DIR/corrupt_files_test_$INPUT_DATE"
mkdir -p "$TEST_DIR"

echo "=== FOCUSED CORRUPTION DETECTION TEST ===" 
echo "Date: $INPUT_DATE (Today's files only - matching DAG filter)"
echo "Test directory: $TEST_DIR"
echo "Performance: $([[ $PERFORMANCE_TEST -eq 1 ]] && echo "ENABLED" || echo "DISABLED")"
echo "Stress test: $([[ $STRESS_TEST -eq 1 ]] && echo "ENABLED" || echo "DISABLED")"
echo "Testing ONLY detect_corrupt_files functionality"
echo "Files generated: Various corruption types (zero-size, too-small, too-large, unreadable)"
echo

# SFTP folder paths (from DAG variables - matching real paths)
SFTP_1P_PRICE="/home/demo/sftp/Data/ITSRPC/outgoing_ok/RPR/TH"
SFTP_1P_PROMOTION="/home/demo/sftp/Data/ITSPMT/outgoing_ok/PPR/TH"
SFTP_SOA_PRICE="/home/demo/soa/Data/ITSRPC/outgoing_ok/RPR/TH"
SFTP_SOA_PROMOTION="/home/demo/soa/Data/ITSPMT/outgoing_ok/PPR/TH"
SFTP_RPM_PROCESSED="/home/demo/sftp/rpm/processed"
SFTP_RPM_PENDING="/home/demo/sftp/rpm/pending"

# Schema compliance from UPLOAD_VALIDATION_CONFIG (DAG requirements)
PRICE_REQUIRED_FIELDS="item_id,price,start_date,end_date"
PROMOTION_REQUIRED_FIELDS="promotion_id,discount,start_date,end_date"
# Supported formats: [".csv", ".ods"]
# File size limits: min=1MB (1048576 bytes), max=100MB (104857600 bytes)
# Data types: {"item_id": "string", "price": "numeric", "start_date": "date", "end_date": "date", "discount": "numeric", "promotion_id": "string"}

MIN_FILE_SIZE=1048576      # 1MB in bytes
MAX_FILE_SIZE=104857600    # 100MB in bytes

# =============================================================================
# FUNCTION: Generate schema-compliant CSV content
# =============================================================================
generate_schema_compliant_content() {
    local content_type="$1"
    local row_count="$2"
    local file_suffix="$3"  # For unique content generation
    local output_file="$4"
    
    if [[ "$content_type" == "price" ]]; then
        echo "$PRICE_REQUIRED_FIELDS" > "$output_file"
        for row in $(seq 1 "$row_count"); do
            item_id="ITEM_${file_suffix}_$(printf '%08d' $row)"
            price=$(echo "scale=2; 100 + $row/100" | bc)
            start_date="$INPUT_DATE"
            end_date=$(date -d "$INPUT_DATE + $((row % 30 + 1)) days" +%Y-%m-%d)
            echo "$item_id,$price,$start_date,$end_date" >> "$output_file"
        done
    elif [[ "$content_type" == "promotion" ]]; then
        echo "$PROMOTION_REQUIRED_FIELDS" > "$output_file"
        for row in $(seq 1 "$row_count"); do
            promotion_id="PROMO_${file_suffix}_$(printf '%08d' $row)"
            discount=$(echo "scale=2; 0.$((row % 50 + 10))" | bc)
            start_date="$INPUT_DATE"
            end_date=$(date -d "$INPUT_DATE + $((row % 14 + 1)) days" +%Y-%m-%d)
            echo "$promotion_id,$discount,$start_date,$end_date" >> "$output_file"
        done
    fi
}

# =============================================================================
# FUNCTION: Generate CORRUPTION test files focusing on detect_corrupt_files ONLY
# =============================================================================
generate_corruption_test_scenarios() {
    echo "📁 Generating FOCUSED corruption detection test scenarios..."
    
    # Create local test directories
    mkdir -p "$TEST_DIR"/{1p_price,1p_promotion,soa_price,soa_promotion,rpm_processed,rpm_pending}
    
    # ==========================================================================
    # CORRUPTION TEST STRATEGY:
    # - Create files with specific corruption types
    # - Test all corruption detection scenarios
    # - Add some valid files to avoid 100% corruption rate
    # ==========================================================================
    
    echo "  Creating corruption scenarios for detect_corrupt_files testing..."
    
    # ==========================================================================
    # SCENARIO 1: ZERO-SIZE FILES (Completely corrupted)
    # ==========================================================================
    
    echo "  Creating zero-size files (corruption type: zero_size)..."
    
    # Zero-size price file
    timestamp_zero1="090000"  # 09:00:00
    touch "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_zero1}.ods"
    touch "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_zero1}.ods"
    touch "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_zero1}.ods"
    
    # Zero-size promotion file
    timestamp_zero2="091000"  # 09:10:00
    touch "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_zero2}.ods"
    touch "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_zero2}.ods"
    
    # ==========================================================================
    # SCENARIO 2: TOO-SMALL FILES (Below 1MB threshold)
    # ==========================================================================
    
    echo "  Creating too-small files (corruption type: too_small)..."
    
    # Too-small price file (500KB = 512000 bytes)
    timestamp_small1="100000"  # 10:00:00
    generate_schema_compliant_content "price" 500 "SMALL_1" "$TEST_DIR/temp_small_1.csv"
    # Pad to exactly 512KB (below 1MB threshold)
    head -c 512000 /dev/zero >> "$TEST_DIR/temp_small_1.csv"
    cp "$TEST_DIR/temp_small_1.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_small1}.ods"
    cp "$TEST_DIR/temp_small_1.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_small1}.ods"
    cp "$TEST_DIR/temp_small_1.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_small1}.ods"
    
    # Too-small promotion file (800KB = 819200 bytes)  
    timestamp_small2="101000"  # 10:10:00
    generate_schema_compliant_content "promotion" 300 "SMALL_2" "$TEST_DIR/temp_small_2.csv"
    # Pad to exactly 800KB (below 1MB threshold)
    head -c 819200 /dev/zero >> "$TEST_DIR/temp_small_2.csv"
    cp "$TEST_DIR/temp_small_2.csv" "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_small2}.ods"
    cp "$TEST_DIR/temp_small_2.csv" "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_small2}.ods"
    
    # ==========================================================================
    # SCENARIO 3: TOO-LARGE FILES (Above 100MB threshold)
    # ==========================================================================
    
    echo "  Creating too-large files (corruption type: too_large)..."
    
    # Too-large price file (120MB = 125829120 bytes)
    timestamp_large1="110000"  # 11:00:00  
    generate_schema_compliant_content "price" 1000 "LARGE_1" "$TEST_DIR/temp_large_1.csv"
    # Pad to exactly 120MB (above 100MB threshold)
    dd if=/dev/zero bs=1024 count=122880 >> "$TEST_DIR/temp_large_1.csv" 2>/dev/null
    cp "$TEST_DIR/temp_large_1.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_large1}.ods"
    cp "$TEST_DIR/temp_large_1.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_large1}.ods"
    cp "$TEST_DIR/temp_large_1.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_large1}.ods"
    
    # Too-large promotion file (150MB = 157286400 bytes)
    timestamp_large2="111000"  # 11:10:00
    generate_schema_compliant_content "promotion" 1000 "LARGE_2" "$TEST_DIR/temp_large_2.csv"
    # Pad to exactly 150MB (above 100MB threshold)
    dd if=/dev/zero bs=1024 count=153600 >> "$TEST_DIR/temp_large_2.csv" 2>/dev/null
    cp "$TEST_DIR/temp_large_2.csv" "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_large2}.ods"
    cp "$TEST_DIR/temp_large_2.csv" "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_large2}.ods"
    
    # ==========================================================================
    # SCENARIO 4: UNREADABLE FILES (Permission denied)
    # ==========================================================================
    
    echo "  Creating unreadable files (corruption type: unreadable)..."
    
    # Unreadable price file (will simulate permission errors)
    timestamp_unread1="120000"  # 12:00:00
    generate_schema_compliant_content "price" 10000 "UNREAD_1" "$TEST_DIR/temp_unread_1.csv"
    cp "$TEST_DIR/temp_unread_1.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_unread1}.ods"
    cp "$TEST_DIR/temp_unread_1.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_unread1}.ods"
    cp "$TEST_DIR/temp_unread_1.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_unread1}.ods"
    # Remove read permissions to simulate unreadable file
    chmod 000 "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_unread1}.ods"
    chmod 000 "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_unread1}.ods"
    chmod 000 "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_unread1}.ods"
    
    # ==========================================================================
    # SCENARIO 5: VALID FILES (Should NOT be flagged as corrupt) 
    # ==========================================================================
    
    echo "  Creating valid files (should pass corruption detection)..."
    
    # Valid price file (5MB - within 1MB-100MB range)
    timestamp_valid1="130000"  # 13:00:00
    generate_schema_compliant_content "price" 50000 "VALID_1" "$TEST_DIR/temp_valid_1.csv"
    cp "$TEST_DIR/temp_valid_1.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_valid1}.ods"
    cp "$TEST_DIR/temp_valid_1.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_valid1}.ods"
    cp "$TEST_DIR/temp_valid_1.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_valid1}.ods"
    
    # Valid promotion file (3MB - within 1MB-100MB range)
    timestamp_valid2="131000"  # 13:10:00
    generate_schema_compliant_content "promotion" 30000 "VALID_2" "$TEST_DIR/temp_valid_2.csv"
    cp "$TEST_DIR/temp_valid_2.csv" "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_valid2}.ods"
    cp "$TEST_DIR/temp_valid_2.csv" "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_valid2}.ods"
    
    # Valid mixed format files (CSV and ODS with same content - 4MB)
    timestamp_valid3="140000"  # 14:00:00
    generate_schema_compliant_content "price" 40000 "VALID_3" "$TEST_DIR/temp_valid_3.csv"
    cp "$TEST_DIR/temp_valid_3.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_valid3}.ods"
    cp "$TEST_DIR/temp_valid_3.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    cp "$TEST_DIR/temp_valid_3.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_valid3}.ods"
    cp "$TEST_DIR/temp_valid_3.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_valid3}.ods"
    
    # ==========================================================================
    # SCENARIO 6: EDGE CASES (Boundary conditions)
    # ==========================================================================
    
    echo "  Creating edge case files (boundary testing)..."
    
    # Exactly 1MB file (minimum threshold - should be valid)
    timestamp_edge1="150000"  # 15:00:00
    generate_schema_compliant_content "price" 1000 "EDGE_MIN" "$TEST_DIR/temp_edge_min.csv"
    # Pad to exactly 1MB (1048576 bytes)
    truncate -s 1048576 "$TEST_DIR/temp_edge_min.csv"
    cp "$TEST_DIR/temp_edge_min.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_edge1}.ods"
    cp "$TEST_DIR/temp_edge_min.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_edge1}.ods"
    cp "$TEST_DIR/temp_edge_min.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_edge1}.ods"
    
    # Exactly 100MB file (maximum threshold - should be valid)
    timestamp_edge2="151000"  # 15:10:00
    generate_schema_compliant_content "promotion" 1000 "EDGE_MAX" "$TEST_DIR/temp_edge_max.csv"
    # Pad to exactly 100MB (104857600 bytes)
    truncate -s 104857600 "$TEST_DIR/temp_edge_max.csv"
    cp "$TEST_DIR/temp_edge_max.csv" "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_edge2}.ods"
    cp "$TEST_DIR/temp_edge_max.csv" "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_edge2}.ods"
    
    # Just below 1MB (1048575 bytes - should be corrupt:too_small)
    timestamp_edge3="160000"  # 16:00:00
    generate_schema_compliant_content "price" 1000 "EDGE_BELOW" "$TEST_DIR/temp_edge_below.csv"
    # Pad to exactly 1 byte below 1MB
    truncate -s 1048575 "$TEST_DIR/temp_edge_below.csv"
    cp "$TEST_DIR/temp_edge_below.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_edge3}.ods"
    cp "$TEST_DIR/temp_edge_below.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_edge3}.ods"
    cp "$TEST_DIR/temp_edge_below.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_edge3}.ods"
    
    # Just above 100MB (104857601 bytes - should be corrupt:too_large)
    timestamp_edge4="161000"  # 16:10:00
    generate_schema_compliant_content "promotion" 1000 "EDGE_ABOVE" "$TEST_DIR/temp_edge_above.csv"
    # Pad to exactly 1 byte above 100MB
    truncate -s 104857601 "$TEST_DIR/temp_edge_above.csv"
    cp "$TEST_DIR/temp_edge_above.csv" "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_edge4}.ods"
    cp "$TEST_DIR/temp_edge_above.csv" "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp_edge4}.ods"
    
    # Clean up temporary files
    rm -f "$TEST_DIR"/temp_*.csv
    
    echo "✅ Focused corruption detection scenarios generated successfully"
    echo "   - Various corruption types: zero-size, too-small, too-large, unreadable"
    echo "   - Valid files to ensure balanced testing"
    echo "   - Edge cases for boundary condition testing"
}

# =============================================================================
# FUNCTION: Clean existing Docker files before uploading (if --clean flag is used)
# =============================================================================
clean_docker_files() {
    if [ $CLEAN_DOCKER -eq 1 ]; then
        echo "🧹 Cleaning existing Docker files..."
        
        # Check if Docker container exists
        if ! command -v docker &> /dev/null || ! docker ps | grep -q "$DOCKER_CONTAINER"; then
            echo "❌ Docker container '$DOCKER_CONTAINER' not found for cleaning"
            return 1
        fi
        
        # Clean directories in Docker container
        echo "  Removing files from Docker directories..."
        docker exec $DOCKER_CONTAINER find "$SFTP_1P_PRICE" -name "*.ods" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_1P_PRICE" -name "*.csv" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_1P_PROMOTION" -name "*.ods" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_1P_PROMOTION" -name "*.csv" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_SOA_PRICE" -name "*.ods" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_SOA_PROMOTION" -name "*.ods" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_RPM_PROCESSED" -name "*.ods" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_RPM_PROCESSED" -name "*.csv" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_RPM_PENDING" -name "*.ods" -delete 2>/dev/null || true
        
        echo "✅ Docker files cleaned"
    fi
}

# =============================================================================
# FUNCTION: Upload corruption test files to Docker container
# =============================================================================
upload_corruption_test_to_docker() {
    echo "🐳 Uploading corruption test data to Docker container..."
    
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
    
    # Function to upload files from local directory to Docker (batch upload)
    upload_files() {
        local local_dir="$1"
        local docker_path="$2"
        local description="$3"
        
        if [ -d "$TEST_DIR/$local_dir" ] && [ -n "$(ls -A "$TEST_DIR/$local_dir" 2>/dev/null)" ]; then
            echo "  Uploading $description files..."
            # Use batch copy for better performance and avoid hanging
            docker cp "$TEST_DIR/$local_dir/." "$DOCKER_CONTAINER:$docker_path/" 2>/dev/null || true
            local file_count=$(ls "$TEST_DIR/$local_dir"/*.ods "$TEST_DIR/$local_dir"/*.csv 2>/dev/null | wc -l)
            echo "    ✅ Successfully uploaded $file_count files to $description"
        fi
    }
    
    # Upload files to respective directories
    upload_files "1p_price" "$SFTP_1P_PRICE" "1P Price"
    upload_files "1p_promotion" "$SFTP_1P_PROMOTION" "1P Promotion"
    upload_files "soa_price" "$SFTP_SOA_PRICE" "SOA Price"
    upload_files "soa_promotion" "$SFTP_SOA_PROMOTION" "SOA Promotion"
    upload_files "rpm_processed" "$SFTP_RPM_PROCESSED" "RPM Processed"
    upload_files "rpm_pending" "$SFTP_RPM_PENDING" "RPM Pending"
    
    # Fix ownership and permissions (except for intentionally unreadable files)
    echo "  Fixing file ownership..."
    docker exec $DOCKER_CONTAINER chown -R demo:sftp-user-inventory \
        "$SFTP_1P_PRICE" "$SFTP_1P_PROMOTION" \
        "$SFTP_SOA_PRICE" "$SFTP_SOA_PROMOTION" \
        "$SFTP_RPM_PROCESSED" "$SFTP_RPM_PENDING" 2>/dev/null || true
    
    # Note: Unreadable files will maintain their 000 permissions to simulate access errors
    
    echo "✅ All corruption test data uploaded to Docker container"
}

# =============================================================================
# FUNCTION: Display expected test results
# =============================================================================
show_corruption_expected_results() {
    echo
    echo "=== FOCUSED CORRUPTION DETECTION TEST SUMMARY ==="
    echo
    echo "📊 Test Scenarios Generated (Date: $INPUT_DATE):"
    echo
    echo "  🎯 CORRUPTION TEST STRATEGY:"
    echo "     - Files with various corruption types to test detect_corrupt_files"
    echo "     - Mix of corrupt and valid files for balanced testing"
    echo "     - Edge cases for boundary condition validation"
    echo
    
    # Count files by corruption type
    local zero_size_files=2    # TH_PRCH_090000, TH_PROMPRCH_091000
    local too_small_files=2    # TH_PRCH_100000, TH_PROMPRCH_101000, TH_PRCH_160000 (edge case)
    local too_large_files=3    # TH_PRCH_110000, TH_PROMPRCH_111000, TH_PROMPRCH_161000 (edge case)
    local unreadable_files=1   # TH_PRCH_120000 (with permission 000)
    local valid_files=8        # Various valid files including edge cases
    
    echo "  ❌ CORRUPT FILES (Should be detected by detect_corrupt_files):"
    echo "     1. Zero-Size Files (corruption_type: zero_size):"
    echo "        - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (0 bytes)"
    echo "        - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (0 bytes)"
    echo
    echo "     2. Too-Small Files (corruption_type: too_small):"
    echo "        - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (512KB < 1MB)"
    echo "        - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (800KB < 1MB)"
    echo "        - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (1048575 bytes - 1 byte below 1MB)"
    echo
    echo "     3. Too-Large Files (corruption_type: too_large):"
    echo "        - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (120MB > 100MB)"
    echo "        - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (150MB > 100MB)"  
    echo "        - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (104857601 bytes - 1 byte above 100MB)"
    echo
    echo "     4. Unreadable Files (corruption_type: unreadable):"
    echo "        - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (permission 000)"
    echo
    echo "  ✅ VALID FILES (Should NOT be flagged as corrupt):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (5MB - valid size)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (3MB - valid size)"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (4MB)"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (exactly 1MB - boundary valid)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (exactly 100MB - boundary valid)"
    echo
    
    local total_corrupt=$((zero_size_files + too_small_files + too_large_files + unreadable_files))
    local total_files=$((total_corrupt + valid_files))
    
    echo "📈 EXPECTED CORRUPTION DETECTION RESULTS:"
    echo
    echo "  ❌ SHOULD BE DETECTED AS CORRUPT: $total_corrupt files"
    echo "     - $zero_size_files zero-size files"
    echo "     - $((too_small_files + 1)) too-small files (including edge case)"
    echo "     - $((too_large_files)) too-large files (including edge case)"
    echo "     - $unreadable_files unreadable files"
    echo
    echo "  ✅ SHOULD NOT BE DETECTED AS CORRUPT: $valid_files files"
    echo "     - Valid size files (1MB-100MB range)"
    echo "     - Boundary valid files (exactly 1MB and 100MB)"
    echo
    echo "📊 CORRUPTION RATE CALCULATION:"
    echo "   Expected corruption rate: $((total_corrupt * 100 / total_files))% ($total_corrupt corrupt out of $total_files total)"
    echo "   Expected success rate: $((valid_files * 100 / total_files))% ($valid_files valid out of $total_files total)"
    echo
    echo "📍 Files uploaded to Docker paths:"
    echo "   - 1P: $SFTP_1P_PRICE, $SFTP_1P_PROMOTION"
    echo "   - SOA: $SFTP_SOA_PRICE, $SFTP_SOA_PROMOTION" 
    echo "   - RPM: $SFTP_RPM_PROCESSED, $SFTP_RPM_PENDING"
    echo
    echo "🎯 VALIDATION SUCCESS CRITERIA:"
    echo "   ✓ detect_corrupt_files should identify $total_corrupt corrupt files"
    echo "   ✓ detect_corrupt_files should categorize corruption types correctly:"
    echo "     • zero_size: $zero_size_files files"
    echo "     • too_small: $((too_small_files + 1)) files"  
    echo "     • too_large: $too_large_files files"
    echo "     • unreadable: $unreadable_files files"
    echo "   ✓ detect_corrupt_files should NOT flag $valid_files valid files as corrupt"
    echo "   ✓ XCom output should have proper structure: price/promotion domains"
    echo "   ✓ Email integration should show $((total_corrupt * 100 / total_files))% corruption rate"
    echo "   ✓ Alert system should list all corrupt file paths correctly"
    echo
    echo "🚨 KEY DIFFERENCES FROM OTHER VALIDATION TASKS:"
    echo "   - This test focuses PURELY on file corruption detection"
    echo "   - Other validation tasks may show errors due to intentional corruption"
    echo "   - detect_corrupt_files should provide detailed corruption analysis"
    echo "   - File paths should be properly transformed for email alerts"
    echo
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    echo "🚀 Starting Corruption Detection Test Generation..."
    
    # Clean existing Docker files if requested
    clean_docker_files
    
    # Generate test files
    generate_corruption_test_scenarios
    
    # Upload to Docker container
    upload_corruption_test_to_docker
    
    # Show expected results
    show_corruption_expected_results
    
    echo "=== CORRUPTION DETECTION TEST COMPLETE ==="
    echo "✅ Test data ready for detect_corrupt_files task validation"
    echo "📂 Local test files: $TEST_DIR"
    echo "🐳 Docker container files uploaded successfully"
    echo
    echo "💡 Run the DAG's detect_corrupt_files task to validate these scenarios"
    echo "🔍 The task should detect various types of file corruption:"
    echo "   • Zero-size files (completely corrupted)"
    echo "   • Too-small files (below minimum 1MB)"
    echo "   • Too-large files (above maximum 100MB)"
    echo "   • Unreadable files (permission/access errors)"
    echo "   • Boundary condition files (edge cases)"
    echo
    echo "📧 Expected email alert should show:"
    echo "   • Total corrupt files count"
    echo "   • Corruption rate percentage"
    echo "   • List of corrupt file paths"
    echo "   • Corruption type categorization"
}

# Run main function
main "$@"
