#!/bin/bash

# =============================================================================
# BULK FILE NAMING REFACTOR SCRIPT - ADVANCED VERSION
# =============================================================================
# This script performs comprehensive refactoring of file naming patterns
# across ALL test files to match generate_mock_data.sh standards
#
# STANDARD FORMATS ENFORCED:
# - Price files: TH_PRCH_${DATE_PATTERN}${timestamp}.ods
# - Promotion files: TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods  
# - Feedback files: CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}.csv
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/bulk_backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${CYAN}=== BULK FILE NAMING REFACTOR SCRIPT ===${NC}"
echo -e "${YELLOW}📁 Working Directory: $SCRIPT_DIR${NC}"
echo -e "${YELLOW}💾 Backup Directory: $BACKUP_DIR${NC}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup file before modification
backup_file() {
    local file_path="$1"
    local backup_path="$BACKUP_DIR/$(basename "$file_path")"
    cp "$file_path" "$backup_path"
}

# Function to apply comprehensive file naming standardization
bulk_standardize_file_naming() {
    local script_file="$1"
    local temp_file="$script_file.tmp"
    
    echo -e "${YELLOW}🔧 Processing: $(basename "$script_file")${NC}"
    
    # Backup original file
    backup_file "$script_file"
    
    # Apply comprehensive transformations
    sed -E '
        # =============================================================================
        # SECTION 1: Fix TH_PRCH file extensions (.csv → .ods)
        # =============================================================================
        
        # Basic pattern: TH_PRCH_${DATE_PATTERN}anything.csv → TH_PRCH_${DATE_PATTERN}${timestamp}.ods
        s/TH_PRCH_\$\{DATE_PATTERN\}[^.]*\.csv/TH_PRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # Pattern with specific suffixes: TH_PRCH_${DATE_PATTERN}123456_SUFFIX.csv → TH_PRCH_${DATE_PATTERN}${timestamp}.ods
        s/TH_PRCH_\$\{DATE_PATTERN\}[0-9]{6}_[^.]*\.csv/TH_PRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # Pattern with timestamp and suffix: TH_PRCH_${DATE_PATTERN}${timestamp}_SUFFIX.csv → TH_PRCH_${DATE_PATTERN}${timestamp}.ods
        s/TH_PRCH_\$\{DATE_PATTERN\}\$\{timestamp\}_[^.]*\.csv/TH_PRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # =============================================================================
        # SECTION 2: Fix TH_PROMPRCH file extensions (.csv → .ods)
        # =============================================================================
        
        # Basic pattern: TH_PROMPRCH_${DATE_PATTERN}anything.csv → TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods
        s/TH_PROMPRCH_\$\{DATE_PATTERN\}[^.]*\.csv/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # Pattern with specific suffixes: TH_PROMPRCH_${DATE_PATTERN}123456_SUFFIX.csv → TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods
        s/TH_PROMPRCH_\$\{DATE_PATTERN\}[0-9]{6}_[^.]*\.csv/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # Pattern with timestamp and suffix: TH_PROMPRCH_${DATE_PATTERN}${timestamp}_SUFFIX.csv → TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods
        s/TH_PROMPRCH_\$\{DATE_PATTERN\}\$\{timestamp\}_[^.]*\.csv/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # =============================================================================
        # SECTION 3: Fix existing .ods files with inconsistent naming
        # =============================================================================
        
        # Standardize existing .ods files with numeric timestamps
        s/TH_PRCH_\$\{DATE_PATTERN\}[0-9]{6}\.ods/TH_PRCH_${DATE_PATTERN}${timestamp}.ods/g
        s/TH_PROMPRCH_\$\{DATE_PATTERN\}[0-9]{6}\.ods/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # Fix .ods files with suffixes
        s/TH_PRCH_\$\{DATE_PATTERN\}[0-9]{6}_[^.]*\.ods/TH_PRCH_${DATE_PATTERN}${timestamp}.ods/g
        s/TH_PROMPRCH_\$\{DATE_PATTERN\}[0-9]{6}_[^.]*\.ods/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods/g
        
        # =============================================================================
        # SECTION 4: Fix timestamp variable inconsistencies
        # =============================================================================
        
        # Standardize timestamp1, timestamp2, timestamp3 → timestamp
        s/timestamp1/timestamp/g
        s/timestamp2/timestamp/g  
        s/timestamp3/timestamp/g
        s/time_str1/time_str/g
        s/time_str2/time_str/g
        s/time_str3/time_str/g
        
        # =============================================================================
        # SECTION 5: Fix CP_PROMOTIONS_FEEDBACK patterns (.csv should remain .csv)
        # =============================================================================
        
        # Standardize feedback file naming (keep .csv extension)
        s/CP_PROMOTIONS_FEEDBACK_\$\{DATE_FORMAT\}_[0-9]{6}\.csv/CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}.csv/g
        
        # =============================================================================
        # SECTION 6: Fix file loop patterns in upload/transfer functions
        # =============================================================================
        
        # Fix patterns in for loops that mix .csv and .ods
        s/TH_PRCH_\$\{DATE_PATTERN\}\*\.csv \$[^/]*/TH_PRCH_${DATE_PATTERN}*.ods/g
        s/TH_PROMPRCH_\$\{DATE_PATTERN\}\*\.csv \$[^/]*/TH_PROMPRCH_${DATE_PATTERN}*.ods/g
        
        # Fix standalone loop patterns
        s/TH_PRCH_\$\{DATE_PATTERN\}\*\.csv/TH_PRCH_${DATE_PATTERN}*.ods/g
        s/TH_PROMPRCH_\$\{DATE_PATTERN\}\*\.csv/TH_PROMPRCH_${DATE_PATTERN}*.ods/g
        
        # =============================================================================
        # SECTION 7: Fix hardcoded filenames in strings and literals
        # =============================================================================
        
        # Fix hardcoded filenames with specific timestamps
        s/"TH_PRCH_\$\{DATE_PATTERN\}[0-9]{6}[^"]*\.csv"/"TH_PRCH_${DATE_PATTERN}${timestamp}.ods"/g
        s/"TH_PROMPRCH_\$\{DATE_PATTERN\}[0-9]{6}[^"]*\.csv"/"TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"/g
        
        # =============================================================================
        # SECTION 8: Fix filename variable declarations
        # =============================================================================
        
        # Fix variable assignments for filenames
        s/=[^"]*TH_PRCH_\$\{DATE_PATTERN\}[^"]*\.csv"/="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"/g
        s/=[^"]*TH_PROMPRCH_\$\{DATE_PATTERN\}[^"]*\.csv"/="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"/g
        
    ' "$script_file" > "$temp_file"
    
    # Move temp file back to original
    mv "$temp_file" "$script_file"
    
    echo -e "${GREEN}  ✅ Completed: $(basename "$script_file")${NC}"
}

# Get all .sh files in the directory
echo -e "${BLUE}🔍 Finding all .sh files to refactor...${NC}"
files_to_process=($(find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" -not -name "$(basename "$0")" -not -name "generate_mock_data.sh" -not -name "standardize_file_naming.sh" | sort))

echo -e "${CYAN}📊 Found ${#files_to_process[@]} files to process:${NC}"
for file in "${files_to_process[@]}"; do
    echo -e "${BLUE}  • $(basename "$file")${NC}"
done

echo ""
echo -e "${YELLOW}⚠️  This will modify ${#files_to_process[@]} files. Continue? (y/N)${NC}"
read -r confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Operation cancelled by user${NC}"
    exit 0
fi

echo -e "${GREEN}🚀 Starting bulk refactoring process...${NC}"
echo ""

# Process each file
processed_count=0
for file_path in "${files_to_process[@]}"; do
    if [ -f "$file_path" ]; then
        bulk_standardize_file_naming "$file_path"
        processed_count=$((processed_count + 1))
    else
        echo -e "${YELLOW}⚠️  File not found: $(basename "$file_path")${NC}"
    fi
done

echo ""
echo -e "${GREEN}🎉 Bulk refactoring completed successfully!${NC}"
echo -e "${CYAN}📊 Summary:${NC}"
echo -e "${CYAN}  💾 Backups stored in: $BACKUP_DIR${NC}"
echo -e "${CYAN}  📝 Files processed: $processed_count/${#files_to_process[@]}${NC}"

echo ""
echo -e "${YELLOW}📋 Refactoring changes applied:${NC}"
echo -e "${GREEN}  ✅ TH_PRCH_*.csv → TH_PRCH_\${DATE_PATTERN}\${timestamp}.ods${NC}"
echo -e "${GREEN}  ✅ TH_PROMPRCH_*.csv → TH_PROMPRCH_\${DATE_PATTERN}\${timestamp}.ods${NC}"
echo -e "${GREEN}  ✅ Inconsistent .ods file naming standardized${NC}"
echo -e "${GREEN}  ✅ Timestamp variables unified (timestamp1/2/3 → timestamp)${NC}"
echo -e "${GREEN}  ✅ File loop patterns standardized${NC}"
echo -e "${GREEN}  ✅ Hardcoded filenames updated${NC}"
echo -e "${GREEN}  ✅ CP_PROMOTIONS_FEEDBACK files kept as .csv (correct)${NC}"

echo ""
echo -e "${BLUE}🔍 Next steps:${NC}"
echo -e "${BLUE}  1. Review changes with: git diff${NC}"
echo -e "${BLUE}  2. Test a few modified scripts to ensure they work${NC}"
echo -e "${BLUE}  3. Run verification script: ./verify_naming_consistency.sh${NC}"
echo -e "${BLUE}  4. Commit changes if satisfied${NC}"
echo -e "${BLUE}  5. Remove backup directory: rm -rf $BACKUP_DIR${NC}"

# Create verification script
cat > "$SCRIPT_DIR/verify_naming_consistency.sh" << 'EOF'
#!/bin/bash

# Quick verification script to check naming consistency
echo "🔍 Verifying file naming consistency..."

# Check for remaining .csv patterns (should only be feedback files)
csv_violations=$(grep -r "TH_PRCH.*\.csv\|TH_PROMPRCH.*\.csv" . --include="*.sh" | grep -v "CP_PROMOTIONS_FEEDBACK" | wc -l)

if [ "$csv_violations" -eq 0 ]; then
    echo "✅ No .csv extension violations found for TH_PRCH/TH_PROMPRCH files"
else
    echo "❌ Found $csv_violations .csv extension violations:"
    grep -r "TH_PRCH.*\.csv\|TH_PROMPRCH.*\.csv" . --include="*.sh" | grep -v "CP_PROMOTIONS_FEEDBACK" | head -5
fi

# Check for consistent timestamp usage
inconsistent_timestamps=$(grep -r "timestamp[0-9]" . --include="*.sh" | wc -l)
if [ "$inconsistent_timestamps" -eq 0 ]; then
    echo "✅ All timestamp variables are consistent"
else
    echo "⚠️  Found $inconsistent_timestamps inconsistent timestamp variables"
fi

echo "🏁 Verification complete!"
EOF

chmod +x "$SCRIPT_DIR/verify_naming_consistency.sh"
echo -e "${GREEN}📋 Created verification script: verify_naming_consistency.sh${NC}"
