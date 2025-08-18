#!/bin/bash

# =============================================================================
# DUPLICATES DETECTION VALIDATION SCRIPT
# 
# Purpose: Validate the duplicate detection test results
# This script verifies that the generated test files have the expected
# duplicate relationships for proper testing
# =============================================================================

set -e

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the base script for shared configurations
source "$SCRIPT_DIR/generate_mock_data.sh" --source-only

# Parse arguments
INPUT_DATE=""
DOCKER_CONTAINER="lotus-sftp-1"

for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        INPUT_DATE="$arg"
    elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        echo "Usage: $0 [YYYY-MM-DD]"
        echo "  YYYY-MM-DD: Target date for validation"
        exit 0
    fi
done

# Use current date if not provided
if [ -z "$INPUT_DATE" ]; then
    INPUT_DATE=$(date +%Y-%m-%d)
fi

# Generate date formats from input
DATE_PATTERN=$(parse_date "$INPUT_DATE" "+%Y%m%d")
TEST_DIR="$BASE_DIR/duplicates_test_$INPUT_DATE"

echo "=== DUPLICATES DETECTION VALIDATION ==="
echo "Date: $INPUT_DATE"
echo "Test directory: $TEST_DIR"
echo

# =============================================================================
# FUNCTION: Check if test files exist
# =============================================================================
check_test_files_exist() {
    echo "📂 Checking if test files exist..."
    
    if [ ! -d "$TEST_DIR" ]; then
        echo "❌ Test directory not found: $TEST_DIR"
        echo "💡 Run generate_duplicates_detection_test.sh first"
        return 1
    fi
    
    local missing_files=0
    
    # Check baseline files
    if [ ! -f "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
        echo "❌ Missing baseline file: TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        ((missing_files++))
    fi
    
    if [ ! -f "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
        echo "❌ Missing baseline file: TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        ((missing_files++))
    fi
    
    # Check exact duplicates
    if [ ! -f "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
        echo "❌ Missing duplicate file: TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        ((missing_files++))
    fi
    
    if [ ! -f "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
        echo "❌ Missing duplicate file: TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        ((missing_files++))
    fi
    
    # Check promotion duplicates
    for timestamp in 200000 200001 200002; do
        if [ ! -f "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
            echo "❌ Missing promotion duplicate: TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
            ((missing_files++))
        fi
    done
    
    # Check content hash duplicates
    for timestamp in 130000 130100; do
        if [ ! -f "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
            echo "❌ Missing content hash duplicate: TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
            ((missing_files++))
        fi
    done
    
    # Check cross-stage duplicates
    for dir in 1p_price soa_price rpm_processed; do
        if [ ! -f "$TEST_DIR/$dir/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
            echo "❌ Missing cross-stage duplicate: $dir/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
            ((missing_files++))
        fi
    done
    
    # Check filename duplicates with different content
    for dir in rpm_pending rpm_processed; do
        if [ ! -f "$TEST_DIR/$dir/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
            echo "❌ Missing filename duplicate: $dir/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
            ((missing_files++))
        fi
    done
    
    # Check large-scale duplicates
    for group in {1..3}; do
        for dup in {1..3}; do
            local timestamp="170${group}0${dup}"
            if [ ! -f "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
                echo "❌ Missing large-scale duplicate: TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
                ((missing_files++))
            fi
        done
    done
    
    # Check mixed format duplicates
    if [ ! -f "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
        echo "❌ Missing mixed format file: TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        ((missing_files++))
    fi
    
    if [ ! -f "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" ]; then
        echo "❌ Missing mixed format file: TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        ((missing_files++))
    fi
    
    if [ $missing_files -eq 0 ]; then
        echo "✅ All expected test files exist"
        return 0
    else
        echo "❌ Found $missing_files missing files"
        return 1
    fi
}

# =============================================================================
# FUNCTION: Validate file content duplicates using hash comparison
# =============================================================================
validate_content_duplicates() {
    echo "🔍 Validating content duplicates using hash comparison..."
    
    local validation_errors=0
    
    # Validate exact duplicates in 1P price directory
    echo "  Checking 1P price exact duplicates..."
    local hash1=$(md5sum "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    local hash2=$(md5sum "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    
    if [ "$hash1" = "$hash2" ]; then
        echo "    ✅ 1P price duplicates have identical content (hash: $hash1)"
    else
        echo "    ❌ 1P price files should be duplicates but have different hashes"
        echo "       File 1 hash: $hash1"
        echo "       File 2 hash: $hash2"
        ((validation_errors++))
    fi
    
    # Validate promotion triple duplicates
    echo "  Checking promotion triple duplicates..."
    local promo_hash1=$(md5sum "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    local promo_hash2=$(md5sum "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    local promo_hash3=$(md5sum "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    
    if [ "$promo_hash1" = "$promo_hash2" ] && [ "$promo_hash2" = "$promo_hash3" ]; then
        echo "    ✅ Promotion triple duplicates have identical content (hash: $promo_hash1)"
    else
        echo "    ❌ Promotion files should be triple duplicates but have different hashes"
        echo "       File 1 hash: $promo_hash1"
        echo "       File 2 hash: $promo_hash2"
        echo "       File 3 hash: $promo_hash3"
        ((validation_errors++))
    fi
    
    # Validate content hash duplicates
    echo "  Checking content hash duplicates..."
    local content_hash1=$(md5sum "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    local content_hash2=$(md5sum "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    
    if [ "$content_hash1" = "$content_hash2" ]; then
        echo "    ✅ Content hash duplicates have identical content (hash: $content_hash1)"
    else
        echo "    ❌ Content hash duplicates should have identical content but don't"
        echo "       File 1 hash: $content_hash1"
        echo "       File 2 hash: $content_hash2"
        ((validation_errors++))
    fi
    
    # Validate cross-stage duplicates
    echo "  Checking cross-stage duplicates..."
    local cross_hash1=$(md5sum "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    local cross_hash2=$(md5sum "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    local cross_hash3=$(md5sum "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    
    if [ "$cross_hash1" = "$cross_hash2" ] && [ "$cross_hash2" = "$cross_hash3" ]; then
        echo "    ✅ Cross-stage duplicates have identical content (hash: $cross_hash1)"
    else
        echo "    ❌ Cross-stage duplicates should have identical content but don't"
        echo "       1P hash: $cross_hash1"
        echo "       SOA hash: $cross_hash2"
        echo "       RPM hash: $cross_hash3"
        ((validation_errors++))
    fi
    
    # Validate filename duplicates have DIFFERENT content
    echo "  Checking filename duplicates with different content..."
    local filename_hash1=$(md5sum "$TEST_DIR/rpm_pending/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    local filename_hash2=$(md5sum "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    
    if [ "$filename_hash1" != "$filename_hash2" ]; then
        echo "    ✅ Filename duplicates have different content as expected"
        echo "       Pending hash: $filename_hash1"
        echo "       Processed hash: $filename_hash2"
    else
        echo "    ❌ Filename duplicates should have DIFFERENT content but are identical"
        echo "       Both files hash: $filename_hash1"
        ((validation_errors++))
    fi
    
    # Validate large-scale duplicate groups
    echo "  Checking large-scale duplicate groups..."
    for group in {1..3}; do
        echo "    Validating Group $group..."
        local group_hash1=$(md5sum "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}170${group}01.ods" | cut -d' ' -f1)
        local group_hash2=$(md5sum "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}170${group}02.ods" | cut -d' ' -f1)
        local group_hash3=$(md5sum "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}170${group}03.ods" | cut -d' ' -f1)
        
        if [ "$group_hash1" = "$group_hash2" ] && [ "$group_hash2" = "$group_hash3" ]; then
            echo "      ✅ Group $group duplicates have identical content (hash: $group_hash1)"
        else
            echo "      ❌ Group $group files should be duplicates but have different hashes"
            echo "         File 1 hash: $group_hash1"
            echo "         File 2 hash: $group_hash2"
            echo "         File 3 hash: $group_hash3"
            ((validation_errors++))
        fi
    done
    
    # Validate mixed format duplicates
    echo "  Checking mixed format duplicates..."
    local mixed_hash1=$(md5sum "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    local mixed_hash2=$(md5sum "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    
    if [ "$mixed_hash1" = "$mixed_hash2" ]; then
        echo "    ✅ Mixed format duplicates have identical content (hash: $mixed_hash1)"
    else
        echo "    ❌ Mixed format duplicates should have identical content but don't"
        echo "       ODS hash: $mixed_hash1"
        echo "       CSV hash: $mixed_hash2"
        ((validation_errors++))
    fi
    
    # Validate baseline files are NOT duplicates
    echo "  Checking baseline files are unique..."
    local baseline_hash1=$(md5sum "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    local baseline_hash2=$(md5sum "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    
    if [ "$baseline_hash1" != "$baseline_hash2" ]; then
        echo "    ✅ Baseline files have different content as expected"
    else
        echo "    ❌ Baseline files should be unique but have identical content"
        echo "       Both files hash: $baseline_hash1"
        ((validation_errors++))
    fi
    
    # Validate partial duplicates are NOT identical
    echo "  Checking partial duplicates are different..."
    local partial_hash1=$(md5sum "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    local partial_hash2=$(md5sum "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" | cut -d' ' -f1)
    
    if [ "$partial_hash1" != "$partial_hash2" ]; then
        echo "    ✅ Partial duplicate files have different content as expected"
    else
        echo "    ❌ Partial duplicate files should be different but are identical"
        echo "       Both files hash: $partial_hash1"
        ((validation_errors++))
    fi
    
    if [ $validation_errors -eq 0 ]; then
        echo "✅ All content validation tests passed"
        return 0
    else
        echo "❌ Found $validation_errors content validation errors"
        return 1
    fi
}

# =============================================================================
# FUNCTION: Check file sizes are reasonable
# =============================================================================
check_file_sizes() {
    echo "📏 Checking file sizes are reasonable for testing..."
    
    local size_errors=0
    
    # Function to check file size
    check_size() {
        local file="$1"
        local min_size="$2"  # in KB
        local max_size="$3"  # in KB
        
        if [ -f "$file" ]; then
            local size_kb=$(du -k "$file" | cut -f1)
            if [ $size_kb -ge $min_size ] && [ $size_kb -le $max_size ]; then
                echo "    ✅ $(basename "$file"): ${size_kb} KB (within expected range)"
            else
                echo "    ❌ $(basename "$file"): ${size_kb} KB (expected: ${min_size}-${max_size} KB)"
                ((size_errors++))
            fi
        else
            echo "    ❌ File not found: $(basename "$file")"
            ((size_errors++))
        fi
    }
    
    # Check large files (~2-3MB)
    echo "  Checking large files (expected ~2000-4000 KB)..."
    check_size "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" 1500 4500
    check_size "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" 1000 4000
    check_size "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" 800 3500
    check_size "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" 1000 4000
    check_size "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" 2000 5000
    check_size "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" 1500 4500
    
    # Check medium files (~1-2MB)
    echo "  Checking medium files (expected ~800-2500 KB)..."
    check_size "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" 800 2500
    check_size "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" 600 2000
    check_size "$TEST_DIR/rpm_pending/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" 600 2000
    
    if [ $size_errors -eq 0 ]; then
        echo "✅ All file sizes are within expected ranges"
        return 0
    else
        echo "❌ Found $size_errors file size issues"
        return 1
    fi
}

# =============================================================================
# FUNCTION: Generate validation report
# =============================================================================
generate_validation_report() {
    echo
    echo "=== VALIDATION REPORT ==="
    echo "Test Date: $INPUT_DATE"
    echo "Test Directory: $TEST_DIR"
    echo
    
    # Count files by directory
    echo "📊 File Count Summary:"
    for dir in 1p_price 1p_promotion soa_price soa_promotion rpm_processed rpm_pending; do
        if [ -d "$TEST_DIR/$dir" ]; then
            local count=$(find "$TEST_DIR/$dir" -name "*.ods" -o -name "*.csv" | wc -l)
            echo "  $dir: $count files"
        fi
    done
    
    echo
    echo "🔍 Expected Duplicate Groups:"
    echo "  • 1 pair: 1P price exact duplicates (2 files)"
    echo "  • 1 triple: SOA promotion duplicates (3 files)"
    echo "  • 1 pair: Content hash duplicates (2 files)"
    echo "  • 1 triple: Cross-stage duplicates (3 files)"
    echo "  • 1 pair: Filename duplicates with different content (2 files)"
    echo "  • 3 triples: Large-scale duplicate groups (9 files total)"
    echo "  • 1 pair: Mixed format duplicates (2 files)"
    echo
    echo "📊 Total files that should be flagged as duplicates: ~23 files"
    echo "📊 Total unique files (should NOT be flagged): ~4 files"
    echo
    
    echo "💡 To test the detect_duplicates task:"
    echo "  1. Run your DAG's detect_duplicates task"
    echo "  2. Check if it identifies the duplicate groups correctly"
    echo "  3. Verify it doesn't flag unique files as duplicates"
    echo "  4. Cross-reference results with this validation report"
    echo
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    echo "🚀 Starting Duplicates Detection Validation..."
    
    local all_checks_passed=1
    
    # Check if test files exist
    if ! check_test_files_exist; then
        all_checks_passed=0
    fi
    echo
    
    # Validate content duplicates
    if ! validate_content_duplicates; then
        all_checks_passed=0
    fi
    echo
    
    # Check file sizes
    if ! check_file_sizes; then
        all_checks_passed=0
    fi
    echo
    
    # Generate validation report
    generate_validation_report
    
    if [ $all_checks_passed -eq 1 ]; then
        echo "=== VALIDATION SUCCESSFUL ==="
        echo "✅ All validation checks passed"
        echo "🎯 Test files are ready for duplicate detection testing"
        echo "📋 Use this validation report to verify your detect_duplicates task results"
        exit 0
    else
        echo "=== VALIDATION FAILED ==="
        echo "❌ Some validation checks failed"
        echo "💡 Re-run generate_duplicates_detection_test.sh to fix the issues"
        exit 1
    fi
}

# Run main function
main "$@"
