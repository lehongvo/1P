#!/bin/bash

# =============================================================================
# FINAL CLEANUP FOR ALL TEST FILES
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== FINAL CLEANUP FOR ALL TEST FILES ===${NC}"
echo -e "${YELLOW}📊 Removing ALL descriptive suffixes from file names${NC}"

# Comprehensive list of ALL possible suffixes to remove
PATTERNS=(
    "_TOO_SMALL"
    "_TOO_LARGE"
    "_HUGE"
    "_TINY"
    "_LARGE"
    "_SMALL"
    "_MEDIUM"
    "_EXTREMELY_LARGE"
    "_EXTREMELY_SMALL"
    "_VERY_LARGE"
    "_VERY_SMALL"
    "_GIGANTIC"
    "_MINIMAL"
    "_REGULAR"
    "_STANDARD"
    "_MAXIMUM"
    "_MINIMUM"
    "_NORMAL"
    "_ABNORMAL"
    "_WRONG_HEADERS"
    "_MALFORMED_HEADERS"
    "_INCONSISTENT_COLUMNS"
    "_SEMICOLON_DELIMITER"
    "_TAB_DELIMITER"
    "_MIXED_DELIMITER"
    "_WINDOWS_CRLF"
    "_BOM_ISSUE"
    "_VALID_FILE"
    "_VALID_COMPARISON"
    "_COMPARISON"
    "_REFERENCE"
    "_BASELINE"
    "_SAMPLE"
    "_EXAMPLE"
    "_DEMO"
    "_TEST"
    "_DEBUG"
    "_TEMP"
    "_TMP"
    "_BACKUP"
    "_COPY"
    "_DUPLICATE"
    "_ORIGINAL"
    "_MODIFIED"
    "_UPDATED"
    "_NEW"
    "_OLD"
    "_LATEST"
    "_FINAL"
    "_COMPLETE"
    "_PARTIAL"
    "_FULL"
    "_EMPTY"
    "_BLANK"
    "_NULL"
    "_VOID"
    "_MISSING"
    "_PRESENT"
    "_AVAILABLE"
    "_UNAVAILABLE"
    "_ACTIVE"
    "_INACTIVE"
    "_ENABLED"
    "_DISABLED"
    "_VALID"
    "_INVALID"
    "_CORRECT"
    "_INCORRECT"
    "_PROPER"
    "_IMPROPER"
    "_GOOD"
    "_BAD"
    "_SUCCESS"
    "_FAILURE"
    "_PASSED"
    "_FAILED"
    "_OK"
    "_ERROR"
    "_WARNING"
    "_INFO"
    "_DEBUG"
    "_TRACE"
    "_FATAL"
    "_CRITICAL"
    "_MAJOR"
    "_MINOR"
    "_LOW"
    "_MEDIUM"
    "_HIGH"
    "_URGENT"
    "_IMMEDIATE"
)

# Function to clean a file
clean_file() {
    local script_file="$1"
    echo -e "${YELLOW}  Processing: $script_file${NC}"
    
    # Create backup if not already exists
    if [ ! -f "${script_file}.backup.final" ]; then
        cp "$script_file" "${script_file}.backup.final"
    fi
    
    # Apply all pattern cleanups
    for pattern in "${PATTERNS[@]}"; do
        sed -i "s/${pattern}\\.csv/.csv/g" "$script_file"
        sed -i "s/${pattern}\\.ods/.ods/g" "$script_file"
    done
    
    # Also clean any remaining _[WORD]_[WORD] patterns
    sed -i 's/_[A-Z][A-Z_]*[A-Z]\\.csv/.csv/g' "$script_file"
    sed -i 's/_[A-Z][A-Z_]*[A-Z]\\.ods/.ods/g' "$script_file"
    
    # Clean variable names with descriptive suffixes
    sed -i 's/[a-z_]*_[A-Z_]*_price="/price="/g' "$script_file"
    sed -i 's/[a-z_]*_[A-Z_]*_promo="/promo="/g' "$script_file"
    sed -i 's/[a-z_]*_[A-Z_]*_file="/file="/g' "$script_file"
    
    echo -e "${GREEN}    ✅ Cleaned: $script_file${NC}"
}

# Process all test files
for file in generate_*_test*.sh; do
    if [ -f "$file" ]; then
        clean_file "$file"
    fi
done

echo -e "${GREEN}🎉 Final cleanup completed!${NC}"
echo -e "${YELLOW}💡 All files now use clean format: TH_PRCH_20250819051805.csv${NC}"
echo -e "${BLUE}📦 Final backup files created${NC}"
