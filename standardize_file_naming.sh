#!/bin/bash

# =============================================================================
# FILE NAMING STANDARDIZATION SCRIPT
# =============================================================================
# This script standardizes all file naming patterns across test files to match
# the format used in generate_mock_data.sh
#
# STANDARD FORMATS:
# - Price files: TH_PRCH_YYYYMMDDHHMMSS.ods
# - Promotion files: TH_PROMPRCH_YYYYMMDDHHMMSS.ods  
# - Feedback files: CP_PROMOTIONS_FEEDBACK_DDMmmYYYY_HHMMSS.csv
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/naming_backups_$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}=== FILE NAMING STANDARDIZATION SCRIPT ===${NC}"
echo -e "${YELLOW}📁 Working Directory: $SCRIPT_DIR${NC}"
echo -e "${YELLOW}💾 Backup Directory: $BACKUP_DIR${NC}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup file before modification
backup_file() {
    local file_path="$1"
    local backup_path="$BACKUP_DIR/$(basename "$file_path")"
    cp "$file_path" "$backup_path"
    echo -e "${GREEN}  Backed up: $(basename "$file_path")${NC}"
}

# Function to standardize file naming in a script
standardize_file_naming() {
    local script_file="$1"
    local temp_file="$script_file.tmp"
    
    echo -e "${YELLOW}📝 Processing: $(basename "$script_file")${NC}"
    
    # Backup original file
    backup_file "$script_file"
    
    # Apply standardization transformations
    sed -E '
        # Fix TH_PRCH files - change .csv to .ods and standardize format
        s/TH_PRCH_\$\{DATE_PATTERN\}[^.]*\.csv/TH_PRCH_${DATE_PATTERN}${timestamp}.ods/g
        s/TH_PRCH_\$\{DATE_PATTERN\}([^.]*_[^.]*)?\.csv/TH_PRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # Fix TH_PROMPRCH files - change .csv to .ods and standardize format  
        s/TH_PROMPRCH_\$\{DATE_PATTERN\}[^.]*\.csv/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods/g
        s/TH_PROMPRCH_\$\{DATE_PATTERN\}([^.]*_[^.]*)?\.csv/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # Standardize existing .ods files to use consistent timestamp format
        s/TH_PRCH_\$\{DATE_PATTERN\}[0-9]{6}(_[^.]*)?\.ods/TH_PRCH_${DATE_PATTERN}${timestamp}.ods/g
        s/TH_PROMPRCH_\$\{DATE_PATTERN\}[0-9]{6}(_[^.]*)?\.ods/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # Keep feedback files as .csv but standardize format
        s/CP_PROMOTIONS_FEEDBACK_\$\{DATE_FORMAT\}_[0-9]{6}\.csv/CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}.csv/g
    ' "$script_file" > "$temp_file"
    
    # Move temp file back to original
    mv "$temp_file" "$script_file"
    
    echo -e "${GREEN}  ✅ Standardized: $(basename "$script_file")${NC}"
}

# List of files to process
files_to_process=(
    "$SCRIPT_DIR/generate_fetch_1p_files_test.sh"
    "$SCRIPT_DIR/generate_auto_feedback_test.sh"
    "$SCRIPT_DIR/generate_comprehensive_dag_tests.sh"
    "$SCRIPT_DIR/generate_corrupt_files_detection_test.sh"
    "$SCRIPT_DIR/generate_duplicates_detection_test.sh"
    "$SCRIPT_DIR/generate_fetch_rpm_files_test.sh"
    "$SCRIPT_DIR/generate_fetch_soa_files_test.sh"
    "$SCRIPT_DIR/generate_flag_issues_detection_test.sh"
    "$SCRIPT_DIR/generate_invalid_datatypes_test.sh"
    "$SCRIPT_DIR/generate_invalid_filesize_test.sh"
    "$SCRIPT_DIR/generate_invalid_format_test.sh"
    "$SCRIPT_DIR/generate_mismatches_detection_test.sh"
    "$SCRIPT_DIR/generate_missing_fields_test.sh"
    "$SCRIPT_DIR/generate_missing_files_detection_test.sh"
    "$SCRIPT_DIR/generate_auto_correction_test.sh"
    "$SCRIPT_DIR/generate_file_tracking_test.sh"
    "$SCRIPT_DIR/validate_duplicates_detection.sh"
)

echo -e "${BLUE}🚀 Starting standardization process...${NC}"

# Process each file
for file_path in "${files_to_process[@]}"; do
    if [ -f "$file_path" ]; then
        standardize_file_naming "$file_path"
    else
        echo -e "${YELLOW}⚠️  File not found: $(basename "$file_path")${NC}"
    fi
done

echo -e "${GREEN}🎉 Standardization completed!${NC}"
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "  💾 Backups stored in: $BACKUP_DIR"
echo -e "  📝 Files processed: ${#files_to_process[@]}"

echo -e "${YELLOW}📋 Next steps:${NC}"
echo -e "  1. Review changes with: git diff"
echo -e "  2. Test modified scripts"
echo -e "  3. Commit changes if satisfied"
echo -e "  4. Remove backup directory when confident: rm -rf $BACKUP_DIR"
