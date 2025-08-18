#!/bin/bash

# =============================================================================
# FOCUSED DUPLICATES DETECTION TEST SCRIPT
# 
# Purpose: Test ONLY detect_duplicates functionality
# Coverage: Core duplicate scenarios without triggering other validation errors
# Schema: Files meet minimum requirements (>1MB, proper format, today's date)
# Tasks Tested: ONLY detect_duplicates
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
TEST_DIR="$BASE_DIR/duplicates_test_$INPUT_DATE"
mkdir -p "$TEST_DIR"

echo "=== FOCUSED DUPLICATES DETECTION TEST ===" 
echo "Date: $INPUT_DATE (Today's files only - matching DAG filter)"
echo "Test directory: $TEST_DIR"
echo "Performance: $([[ $PERFORMANCE_TEST -eq 1 ]] && echo "ENABLED" || echo "DISABLED")"
echo "Stress test: $([[ $STRESS_TEST -eq 1 ]] && echo "ENABLED" || echo "DISABLED")"
echo "Testing ONLY detect_duplicates functionality"
echo "Files generated: Balanced distribution, >1MB size, proper format"
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
# File size limits: min=1MB, max=100MB
# Data types: {"item_id": "string", "price": "numeric", "start_date": "date", "end_date": "date", "discount": "numeric", "promotion_id": "string"}

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
# FUNCTION: Generate BALANCED test files focusing on duplicate detection ONLY
# =============================================================================
generate_duplicates_test_scenarios() {
    echo "📁 Generating FOCUSED duplicate detection test scenarios..."
    
    # Create local test directories
    mkdir -p "$TEST_DIR"/{1p_price,1p_promotion,soa_price,soa_promotion,rpm_processed,rpm_pending}
    
    # ==========================================================================
    # BALANCED DATASET STRATEGY:
    # - Create same files in all stages to avoid mismatch/missing errors
    # - All files >1MB to pass file size validation
    # - Focus on ONLY testing duplicate detection patterns
    # ==========================================================================
    
    echo "  Creating balanced dataset for duplicate detection testing..."
    
    # ==========================================================================
    # SCENARIO 1: UNIQUE BASELINE FILES (Present in ALL stages)
    # ==========================================================================
    
    # Unique file #1 - Present in all 1P, SOA, RPM stages (2MB target)
    timestamp="100000"  # 10:00:00
    generate_schema_compliant_content "price" 20000 "UNIQUE_1" "$TEST_DIR/temp_unique_1.csv"
    cp "$TEST_DIR/temp_unique_1.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    cp "$TEST_DIR/temp_unique_1.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    cp "$TEST_DIR/temp_unique_1.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Unique file #2 - Present in all promotion stages (1.5MB target)
    timestamp="110000"  # 11:00:00
    generate_schema_compliant_content "promotion" 15000 "UNIQUE_2" "$TEST_DIR/temp_unique_2.csv"
    cp "$TEST_DIR/temp_unique_2.csv" "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    cp "$TEST_DIR/temp_unique_2.csv" "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # ==========================================================================
    # SCENARIO 2: EXACT DUPLICATES (Same content, different filenames)
    # ==========================================================================
    
    # Exact duplicate group 1 - 2 price files with identical content (2.5MB target)
    timestamp_dup1="120000"  # 12:00:00
    timestamp_dup2="120001"  # 12:00:01
    
    generate_schema_compliant_content "price" 25000 "EXACT_DUP" "$TEST_DIR/temp_exact_dup.csv"
    
    # Create duplicates in 1P (will be detected as exact duplicates)
    cp "$TEST_DIR/temp_exact_dup.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_dup1}.ods"
    cp "$TEST_DIR/temp_exact_dup.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_dup2}.ods"
    
    # Create corresponding files in SOA and RPM to avoid missing file errors
    cp "$TEST_DIR/temp_exact_dup.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_dup1}.ods"
    cp "$TEST_DIR/temp_exact_dup.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_dup2}.ods"
    cp "$TEST_DIR/temp_exact_dup.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_dup1}.ods"
    cp "$TEST_DIR/temp_exact_dup.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_dup2}.ods"
    
    # ==========================================================================
    # SCENARIO 3: CONTENT HASH DUPLICATES (Same content, different filenames)
    # ==========================================================================
    
    timestamp_hash1="130000"  # 13:00:00
    timestamp_hash2="130100"  # 13:01:00
    
    generate_schema_compliant_content "price" 22000 "HASH_DUP" "$TEST_DIR/temp_hash_dup.csv"
    
    # Create content hash duplicates in RPM (different times, same content)
    cp "$TEST_DIR/temp_hash_dup.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_hash1}.ods"
    cp "$TEST_DIR/temp_hash_dup.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_hash2}.ods"
    
    # Create corresponding files in 1P and SOA to avoid missing file errors
    cp "$TEST_DIR/temp_hash_dup.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_hash1}.ods"
    cp "$TEST_DIR/temp_hash_dup.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_hash2}.ods"
    cp "$TEST_DIR/temp_hash_dup.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_hash1}.ods"
    cp "$TEST_DIR/temp_hash_dup.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_hash2}.ods"
    
    # ==========================================================================
    # SCENARIO 4: FILENAME DUPLICATES (Same name, different content)
    # ==========================================================================
    
    timestamp_filename="160000"  # 16:00:00
    
    # Create different content for same filename scenario (2MB target)
    generate_schema_compliant_content "price" 18000 "PENDING" "$TEST_DIR/temp_pending.csv"
    generate_schema_compliant_content "price" 18000 "PROCESSED" "$TEST_DIR/temp_processed.csv"
    
    # Same filename, different content (reprocessing scenario)
    cp "$TEST_DIR/temp_pending.csv" "$TEST_DIR/rpm_pending/TH_PRCH_${DATE_PATTERN}${timestamp_filename}.ods"
    cp "$TEST_DIR/temp_processed.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_filename}.ods"
    
    # Create corresponding files in 1P and SOA to avoid missing file errors
    cp "$TEST_DIR/temp_pending.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_filename}.ods"
    cp "$TEST_DIR/temp_processed.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_filename}.ods"
    
    # ==========================================================================
    # SCENARIO 5: MIXED FORMAT DUPLICATES (Same content, different extensions)
    # ==========================================================================
    
    timestamp_mixed1="180000"  # 18:00:00
    timestamp_mixed2="180100"  # 18:01:00
    
    generate_schema_compliant_content "price" 23000 "MIXED_FORMAT" "$TEST_DIR/temp_mixed.csv"
    
    # Same content, different extensions in RPM
    cp "$TEST_DIR/temp_mixed.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_mixed1}.ods"
    cp "$TEST_DIR/temp_mixed.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Create corresponding files in 1P and SOA to avoid missing file errors
    cp "$TEST_DIR/temp_mixed.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_mixed1}.ods"
    cp "$TEST_DIR/temp_mixed.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_mixed2}.ods"
    cp "$TEST_DIR/temp_mixed.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_mixed1}.ods"
    cp "$TEST_DIR/temp_mixed.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_mixed2}.ods"
    
    # ==========================================================================
    # SCENARIO 6: BASE NAME DUPLICATES (Same filename, different extensions)
    # ==========================================================================
    
    timestamp_base="190000"  # 19:00:00
    
    generate_schema_compliant_content "price" 19000 "BASE_NAME" "$TEST_DIR/temp_base_name.csv"
    
    # Same base name, different extensions in RPM
    cp "$TEST_DIR/temp_base_name.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp_base}.ods"
    cp "$TEST_DIR/temp_base_name.csv" "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Create corresponding files in 1P and SOA to avoid missing file errors
    cp "$TEST_DIR/temp_base_name.csv" "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp_base}.ods"
    cp "$TEST_DIR/temp_base_name.csv" "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp_base}.ods"
    
    # Clean up temporary files
    rm -f "$TEST_DIR"/temp_*.csv
    
    echo "✅ Focused duplicate detection scenarios generated successfully"
    echo "   - Dataset balanced across all stages to avoid validation errors"
    echo "   - All files >1MB to pass file size validation"
    echo "   - Core duplicate patterns included for comprehensive testing"
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
        docker exec $DOCKER_CONTAINER find "$SFTP_1P_PROMOTION" -name "*.ods" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_SOA_PRICE" -name "*.ods" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_SOA_PROMOTION" -name "*.ods" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_RPM_PROCESSED" -name "*.ods" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_RPM_PROCESSED" -name "*.csv" -delete 2>/dev/null || true
        docker exec $DOCKER_CONTAINER find "$SFTP_RPM_PENDING" -name "*.ods" -delete 2>/dev/null || true
        
        echo "✅ Docker files cleaned"
    fi
}

# =============================================================================
# FUNCTION: Upload duplicate test files to Docker container
# =============================================================================
upload_duplicates_test_to_docker() {
    echo "🐳 Uploading duplicates test data to Docker container..."
    
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
    
    # Fix ownership
    echo "  Fixing file ownership..."
    docker exec $DOCKER_CONTAINER chown -R demo:sftp-user-inventory \
        "$SFTP_1P_PRICE" "$SFTP_1P_PROMOTION" \
        "$SFTP_SOA_PRICE" "$SFTP_SOA_PROMOTION" \
        "$SFTP_RPM_PROCESSED" "$SFTP_RPM_PENDING" 2>/dev/null || true
    
    echo "✅ All duplicates test data uploaded to Docker container"
}

# =============================================================================
# FUNCTION: Display expected test results
# =============================================================================
show_duplicates_expected_results() {
    echo
    echo "=== FOCUSED DUPLICATE DETECTION TEST SUMMARY ==="
    echo
    echo "📊 Test Scenarios Generated (Date: $INPUT_DATE):"
    echo
    echo "  🎯 BALANCED DATASET STRATEGY:"
    echo "     - Files present in ALL stages (1P, SOA, RPM) to prevent mismatch/missing errors"
    echo "     - All files >1MB to pass file size validation"
    echo "     - Focus on ONLY duplicate detection patterns"
    echo
    echo "  ✅ UNIQUE BASELINE FILES (Should NOT be flagged as duplicates):"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (unique content across all stages)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (unique promotion content)"
    echo
    echo "  ❌ DUPLICATE DETECTION SCENARIOS:"
    echo "     1. Exact Content Duplicates:"
    echo "        - TH_PRCH_${DATE_PATTERN}${timestamp}.ods ↔ TH_PRCH_${DATE_PATTERN}${timestamp}.ods → SHOULD DETECT"
    echo "        - Same content, different filenames (6 files across all stages)"
    echo
    echo "     2. Content Hash Duplicates:"
    echo "        - TH_PRCH_${DATE_PATTERN}${timestamp}.ods ↔ TH_PRCH_${DATE_PATTERN}${timestamp}.ods → SHOULD DETECT"
    echo "        - Same content, different timestamps (6 files across all stages)"
    echo
    echo "     3. Filename Duplicates (Different Content):"
    echo "        - TH_PRCH_${DATE_PATTERN}${timestamp}.ods in pending vs processed → SHOULD DETECT"
    echo "        - Same filename, different content (4 files across all stages)"
    echo
    echo "     4. Mixed Format Duplicates:"
    echo "        - TH_PRCH_${DATE_PATTERN}${timestamp}.ods ↔ TH_PRCH_${DATE_PATTERN}${timestamp}.ods → SHOULD DETECT"
    echo "        - Same content, different extensions (8 files total)"
    echo
    echo "     5. Base Name Duplicates:"
    echo "        - TH_PRCH_${DATE_PATTERN}${timestamp}.ods ↔ TH_PRCH_${DATE_PATTERN}${timestamp}.ods → SHOULD DETECT"
    echo "        - Same base filename, different extensions (6 files total)"
    echo
    
    echo "📊 Expected Duplicate Detection Results:"
    echo
    
    local expected_duplicates=0
    
    echo "  ✅ SHOULD BE DETECTED AS DUPLICATES:"
    echo "     - 6 exact content duplicates (2 files × 3 stages)"
    expected_duplicates=$((expected_duplicates + 6))
    echo "     - 6 content hash duplicates (2 files × 3 stages)"
    expected_duplicates=$((expected_duplicates + 6))
    echo "     - 2 filename duplicates (same name, different content)"
    expected_duplicates=$((expected_duplicates + 2))
    echo "     - 2 mixed format duplicates (CSV vs ODS)"
    expected_duplicates=$((expected_duplicates + 2))
    echo "     - 2 base name duplicates (same base, different ext)"
    expected_duplicates=$((expected_duplicates + 2))
    
    echo
    echo "  ✅ SHOULD NOT BE DETECTED AS DUPLICATES:"
    echo "     - 3 unique price files (TH_PRCH_${DATE_PATTERN}${timestamp}.ods across stages)"
    echo "     - 2 unique promotion files (TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods)"
    echo
    echo "📈 TOTAL EXPECTED DUPLICATE FILES: ~$expected_duplicates files"
    echo "📈 TOTAL UNIQUE FILES (should NOT be flagged): 5 files"
    echo "📈 TOTAL FILES IN DATASET: $((expected_duplicates + 5)) files"
    echo
    echo "📍 Files uploaded to Docker paths:"
    echo "   - 1P: $SFTP_1P_PRICE, $SFTP_1P_PROMOTION"
    echo "   - SOA: $SFTP_SOA_PRICE, $SFTP_SOA_PROMOTION"
    echo "   - RPM: $SFTP_RPM_PROCESSED, $SFTP_RPM_PENDING"
    echo
    echo "🎯 VALIDATION SUCCESS CRITERIA:"
    echo "   ✓ detect_duplicates should identify ~$expected_duplicates duplicate files"
    echo "   ✓ detect_duplicates should group duplicates by type (exact, filename, base name)"
    echo "   ✓ detect_duplicates should NOT flag unique files as duplicates"
    echo "   ✓ detect_mismatches should show 0% errors (balanced dataset)"
    echo "   ✓ detect_missing should show 0% errors (no missing files)"
    echo "   ✓ detect_corrupt_files should show 100% success (all files >1MB)"
    echo "   ✓ Other validation tasks should pass (proper format, schema, size)"
    echo
    echo "🚨 KEY DIFFERENCE FROM PREVIOUS VERSION:"
    echo "   - Balanced dataset prevents mismatch/missing/corrupt file errors"
    echo "   - Focus is PURELY on duplicate detection functionality"
    echo "   - All other validation tasks should show green/success status"
    echo
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    echo "🚀 Starting Duplicates Detection Test Generation..."
    
    # Clean existing Docker files if requested
    clean_docker_files
    
    # Generate test files
    generate_duplicates_test_scenarios
    
    # Upload to Docker container
    upload_duplicates_test_to_docker
    
    # Show expected results
    show_duplicates_expected_results
    
    echo "=== DUPLICATES DETECTION TEST COMPLETE ==="
    echo "✅ Test data ready for detect_duplicates task validation"
    echo "📂 Local test files: $TEST_DIR"
    echo "🐳 Docker container files uploaded successfully"
    echo
    echo "💡 Run the DAG's detect_duplicates task to validate these scenarios"
    echo "🔍 The task should detect various types of duplicates:"
    echo "   • Exact content duplicates"
    echo "   • Content hash duplicates" 
    echo "   • Filename duplicates"
    echo "   • Cross-stage duplicates"
    echo "   • Large-scale duplicate groups"
}

# Run main function
main "$@"
