#!/bin/bash

# =============================================================================
# FIX ALL TEST FILE NAMES - BATCH UPDATE SCRIPT
# =============================================================================
#
# This script updates all test scripts to remove descriptive parts from 
# file names, keeping only the timestamp format like TH_PRCH_20250819051805.csv
#
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== FIXING ALL TEST FILE NAMES ===${NC}"
echo -e "${YELLOW}📊 Updating all test scripts to use correct file naming format${NC}"

# List of test files to update
TEST_FILES=(
    "generate_data_types_validation_test.sh"
    "generate_file_size_validation_test.sh"
    "generate_corrupt_files_test.sh"
    "generate_duplicates_test_files.sh"
    "generate_missing_files_test.sh"
    "generate_mismatches_test.sh"
    "generate_auto_correction_test.sh"
    "generate_auto_feedback_test.sh"
    "generate_flag_issues_test.sh"
    "generate_file_tracking_test.sh"
    "generate_fetch_1p_files_test.sh"
    "generate_fetch_soa_files_test.sh"
    "generate_fetch_rpm_files_test.sh"
)

# Function to fix file names in a script
fix_file_names() {
    local script_file="$1"
    local backup_file="${script_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    echo -e "${YELLOW}  Processing: $script_file${NC}"
    
    # Create backup
    cp "$script_file" "$backup_file"
    
    # Fix variable names that use these patterns
    sed -i 's/_[A-Z_]*_price="TH_PRCH_/_price="TH_PRCH_/g' "$script_file"
    sed -i 's/_[A-Z_]*_promo="TH_PROMPRCH_/_promo="TH_PROMPRCH_/g' "$script_file"
    
    # More specific patterns for common descriptive suffixes
    sed -i 's/_NON_NUMERIC_PRICE\.csv/.csv/g' "$script_file"
    sed -i 's/_INVALID_DATE\.csv/.csv/g' "$script_file"
    sed -i 's/_NEGATIVE_PRICE\.csv/.csv/g' "$script_file"
    sed -i 's/_EXTREME_PRICE\.csv/.csv/g' "$script_file"
    sed -i 's/_INVALID_ITEM_ID\.csv/.csv/g' "$script_file"
    sed -i 's/_INVALID_DISCOUNT\.csv/.csv/g' "$script_file"
    sed -i 's/_INVALID_PROMO_ID\.csv/.csv/g' "$script_file"
    sed -i 's/_INVALID_DATE_RANGE\.csv/.csv/g' "$script_file"
    sed -i 's/_OVERSIZED_FILE\.csv/.csv/g' "$script_file"
    sed -i 's/_UNDERSIZED_FILE\.csv/.csv/g' "$script_file"
    sed -i 's/_EMPTY_FILE\.csv/.csv/g' "$script_file"
    sed -i 's/_TRUNCATED_DATA\.csv/.csv/g' "$script_file"
    sed -i 's/_CORRUPTED_HEADER\.csv/.csv/g' "$script_file"
    sed -i 's/_BINARY_DATA\.csv/.csv/g' "$script_file"
    sed -i 's/_CORRUPTED_FOOTER\.csv/.csv/g' "$script_file"
    sed -i 's/_DUPLICATE_[0-9]*\.csv/.csv/g' "$script_file"
    sed -i 's/_DUPLICATE_CONTENT\.csv/.csv/g' "$script_file"
    sed -i 's/_DUPLICATE_FILENAME\.csv/.csv/g' "$script_file"
    sed -i 's/_PRICE_MISMATCH\.csv/.csv/g' "$script_file"
    sed -i 's/_DATE_MISMATCH\.csv/.csv/g' "$script_file"
    sed -i 's/_CONTENT_MISMATCH\.csv/.csv/g' "$script_file"
    sed -i 's/_CORRECTION_CANDIDATE\.csv/.csv/g' "$script_file"
    sed -i 's/_AUTO_CORRECTED\.csv/.csv/g' "$script_file"
    sed -i 's/_FAILED_CORRECTION\.csv/.csv/g' "$script_file"
    sed -i 's/_SUCCESS_FEEDBACK\.csv/.csv/g' "$script_file"
    sed -i 's/_FAILED_FEEDBACK\.csv/.csv/g' "$script_file"
    sed -i 's/_DELAYED_FEEDBACK\.csv/.csv/g' "$script_file"
    sed -i 's/_PROCESSING_ERROR\.csv/.csv/g' "$script_file"
    sed -i 's/_WARNING_FLAG\.csv/.csv/g' "$script_file"
    sed -i 's/_ERROR_FLAG\.csv/.csv/g' "$script_file"
    sed -i 's/_CRITICAL_FLAG\.csv/.csv/g' "$script_file"
    sed -i 's/_TRANSFER_FAIL\.csv/.csv/g' "$script_file"
    sed -i 's/_DATA_LOSS_RISK\.csv/.csv/g' "$script_file"
    sed -i 's/_VERY_OLD_DATA_LOSS_RISK\.csv/.csv/g' "$script_file"
    sed -i 's/_OLD_DATA_LOSS_RISK\.csv/.csv/g' "$script_file"
    sed -i 's/_FETCH_ERROR\.csv/.csv/g' "$script_file"
    sed -i 's/_CONNECTION_TIMEOUT\.csv/.csv/g' "$script_file"
    sed -i 's/_PERMISSION_DENIED\.csv/.csv/g' "$script_file"
    sed -i 's/_PATH_NOT_FOUND\.csv/.csv/g' "$script_file"
    
    # Also handle .ods files
    sed -i 's/_[A-Z_]*\.ods/.ods/g' "$script_file"
    
    echo -e "${GREEN}    ✅ Fixed file names in: $script_file${NC}"
    echo -e "${BLUE}    📦 Backup created: $backup_file${NC}"
}

# Update each test file
for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        fix_file_names "$test_file"
    else
        echo -e "${RED}    ❌ File not found: $test_file${NC}"
    fi
done

echo -e "${GREEN}🎉 All test file names have been fixed!${NC}"
echo -e "${YELLOW}💡 All files now use format: TH_PRCH_20250819051805.csv${NC}"
echo -e "${BLUE}📋 Backup files created with timestamp for safety${NC}"

echo -e "${YELLOW}🔍 Summary of changes:${NC}"
echo -e "  • Removed all descriptive suffixes from file names"
echo -e "  • Files now use only timestamp: TH_PRCH_\${DATE_PATTERN}\${timestamp}.csv"
echo -e "  • Same for promotion files: TH_PROMPRCH_\${DATE_PATTERN}\${timestamp}.csv"
echo -e "  • Backup files created for all modified scripts"
