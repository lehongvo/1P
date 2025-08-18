#!/bin/bash

# =============================================================================
# AUTO-CORRECTION FILES GENERATOR FOR TESTING AUTO-CORRECTION AND RE-UPLOAD
# =============================================================================
#
# This script generates correctable error scenarios to test the
# auto_correct_and_reupload_ops function in data processing pipelines
#
# USAGE:
#   ./generate_auto_correction_test.sh [YYYY-MM-DD] [--clean]
#
# OPTIONS:
#   --clean   Clean all files from Docker container before uploading new files
#
# =============================================================================

set -e  # Exit on any error

# Import shared configuration from main script
source "$(dirname "$0")/generate_mock_data.sh" --source-only

# Add special flag to prevent main execution when sourced
if [ "${1}" == "--source-only" ]; then
    return 0
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments - handle date parameter and --clean flag
CLEAN_DOCKER=0
INPUT_DATE=""

# Process arguments
for arg in "$@"; do
    if [[ "$arg" == "--clean" ]]; then
        CLEAN_DOCKER=1
    elif [[ "$arg" == "--source-only" ]]; then
        # Skip source-only flag (handled earlier in the script)
        continue
    elif [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        INPUT_DATE="$arg"
        # Validate date exists
        if ! parse_date "$INPUT_DATE" "+%Y-%m-%d" >/dev/null; then
            echo -e "${RED}❌ Error: Invalid date '$INPUT_DATE'${NC}"
            exit 1
        fi
    elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        echo -e "${YELLOW}Usage: $0 [YYYY-MM-DD] [--clean]${NC}"
        echo -e "${YELLOW}  --clean: Remove existing files from Docker container first${NC}"
        exit 0
    else
        echo -e "${RED}❌ Error: Invalid argument '$arg'${NC}"
        echo -e "${YELLOW}Usage: $0 [YYYY-MM-DD] [--clean]${NC}"
        echo -e "${YELLOW}  --clean: Remove existing files from Docker container first${NC}"
        exit 1
    fi
done

# If no date was provided, use current date
if [ -z "$INPUT_DATE" ]; then
    INPUT_DATE=$(date +%Y-%m-%d)
fi

# Debug output
echo -e "${BLUE}DEBUG: Processing with date: $INPUT_DATE${NC}"
echo -e "${BLUE}DEBUG: Clean flag: $CLEAN_DOCKER${NC}"

# Generate date formats from input
DATE_PATTERN=$(parse_date "$INPUT_DATE" "+%Y%m%d")
DATE_FORMAT=$(parse_date "$INPUT_DATE" "+%d%b%Y")
DATE_DIR_FORMAT="$INPUT_DATE"

# Create auto-correction directory
AUTO_CORRECTION_DIR="$BASE_DIR/$DATE_DIR_FORMAT/auto_correction"
mkdir -p "$AUTO_CORRECTION_DIR"

echo -e "${BLUE}=== AUTO-CORRECTION FILES GENERATOR FOR TESTING ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating correctable error scenarios for testing auto-correction${NC}"

# =============================================================================
# FUNCTION: Generate Files with Missing Required Fields (Correctable)
# =============================================================================
generate_missing_required_fields_correctable() {
    echo -e "${RED}🔧 Generating Files with Missing Required Fields (Auto-Correctable)...${NC}"
    
    # 1. Generate price files missing required fields (can add default values)
    echo -e "${YELLOW}  1. Creating price files with missing required fields...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    missing_fields_price1="TH_PRCH_${DATE_PATTERN}${timestamp1}_MISSING_FIELDS_CORRECTABLE.csv"
    missing_fields_price_path1="$AUTO_CORRECTION_DIR/$missing_fields_price1"
    
    # Missing end_date field (can be auto-corrected by adding default value)
    cat > "$missing_fields_price_path1" << EOF
item_id,price,start_date
CORRECT001,199.50,$INPUT_DATE
CORRECT002,299.75,$INPUT_DATE
CORRECT003,399.00,$INPUT_DATE
CORRECT004,499.25,$INPUT_DATE
EOF
    echo -e "${GREEN}    Generated: $missing_fields_price1 (missing end_date - can auto-add default)${NC}"
    
    timestamp2=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    missing_fields_price2="TH_PRCH_${DATE_PATTERN}${timestamp2}_MISSING_FIELDS_CORRECTABLE.csv"
    missing_fields_price_path2="$AUTO_CORRECTION_DIR/$missing_fields_price2"
    
    # Missing start_date field (can be auto-corrected)
    cat > "$missing_fields_price_path2" << EOF
item_id,price,end_date
CORRECT010,599.50,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
CORRECT011,699.75,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
CORRECT012,799.00,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $missing_fields_price2 (missing start_date - can auto-add current date)${NC}"
    
    # 2. Generate promotion files missing required fields (correctable)
    echo -e "${YELLOW}  2. Creating promotion files with missing required fields...${NC}"
    
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    timestamp3=$(printf "%02d%02d%02d" $((7 + RANDOM % 6)) $((RANDOM % 60)) $((RANDOM % 60)))
    missing_fields_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}_MISSING_FIELDS_CORRECTABLE.csv"
    missing_fields_promo_path1="$AUTO_CORRECTION_DIR/$missing_fields_promo1"
    
    # Missing end_date field (can be auto-corrected)
    cat > "$missing_fields_promo_path1" << EOF
promotion_id,discount,start_date
CORRECT_PROMO001,25%,$INPUT_DATE
CORRECT_PROMO002,30%,$INPUT_DATE
CORRECT_PROMO003,35%,$INPUT_DATE
EOF
    echo -e "${GREEN}    Generated: $missing_fields_promo1 (missing end_date - can auto-add default)${NC}"
    
    echo -e "${GREEN}✅ Missing required fields (correctable) files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Files with Data Type Mismatches (Correctable)
# =============================================================================
generate_data_type_mismatch_correctable() {
    echo -e "${RED}🔧 Generating Files with Data Type Mismatches (Auto-Correctable)...${NC}"
    
    # 1. Generate price files with data type issues that can be corrected
    echo -e "${YELLOW}  1. Creating price files with correctable data type issues...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((8 + RANDOM % 5)) $((RANDOM % 60)) $((RANDOM % 60)))
    data_type_price1="TH_PRCH_${DATE_PATTERN}${timestamp1}_DATA_TYPE_CORRECTABLE.csv"
    data_type_price_path1="$AUTO_CORRECTION_DIR/$data_type_price1"
    
    # Price field has string values that can be converted to numeric
    cat > "$data_type_price_path1" << EOF
item_id,price,start_date,end_date
TYPE001,"199.50",$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
TYPE002,"299.75",$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
TYPE003,"399.00",$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
TYPE004,"499.25",$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $data_type_price1 (price in quotes - can auto-convert to numeric)${NC}"
    
    timestamp2=$(printf "%02d%02d%02d" $((9 + RANDOM % 4)) $((RANDOM % 60)) $((RANDOM % 60)))
    data_type_price2="TH_PRCH_${DATE_PATTERN}${timestamp2}_DATA_TYPE_CORRECTABLE.csv"
    data_type_price_path2="$AUTO_CORRECTION_DIR/$data_type_price2"
    
    # Date fields in different format that can be standardized
    cat > "$data_type_price_path2" << EOF
item_id,price,start_date,end_date
TYPE010,599.50,$(date -d "$INPUT_DATE" +%d/%m/%Y),$(date -d "$INPUT_DATE + 30 days" +%d/%m/%Y)
TYPE011,699.75,$(date -d "$INPUT_DATE" +%d/%m/%Y),$(date -d "$INPUT_DATE + 30 days" +%d/%m/%Y)
TYPE012,799.00,$(date -d "$INPUT_DATE" +%d/%m/%Y),$(date -d "$INPUT_DATE + 30 days" +%d/%m/%Y)
EOF
    echo -e "${GREEN}    Generated: $data_type_price2 (dates in DD/MM/YYYY format - can auto-convert to YYYY-MM-DD)${NC}"
    
    # 2. Generate promotion files with correctable data type issues
    echo -e "${YELLOW}  2. Creating promotion files with correctable data type issues...${NC}"
    
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date_dd_mm=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%d/%m/%Y)
        start_date_dd_mm=$(date -j -f "%Y-%m-%d" "$INPUT_DATE" +%d/%m/%Y)
    else
        end_date_dd_mm=$(date -d "$INPUT_DATE + $days_to_add days" +%d/%m/%Y)
        start_date_dd_mm=$(date -d "$INPUT_DATE" +%d/%m/%Y)
    fi
    
    timestamp3=$(printf "%02d%02d%02d" $((10 + RANDOM % 3)) $((RANDOM % 60)) $((RANDOM % 60)))
    data_type_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}_DATA_TYPE_CORRECTABLE.csv"
    data_type_promo_path1="$AUTO_CORRECTION_DIR/$data_type_promo1"
    
    # Discount values without % symbol (can be auto-corrected)
    cat > "$data_type_promo_path1" << EOF
promotion_id,discount,start_date,end_date
TYPE_PROMO001,25,$INPUT_DATE,$end_date
TYPE_PROMO002,30,$INPUT_DATE,$end_date
TYPE_PROMO003,35,$INPUT_DATE,$end_date
TYPE_PROMO004,40,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $data_type_promo1 (discount without % - can auto-add % symbol)${NC}"
    
    echo -e "${GREEN}✅ Data type mismatch (correctable) files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Files with Format Issues (Correctable)
# =============================================================================
generate_format_issues_correctable() {
    echo -e "${RED}🔧 Generating Files with Format Issues (Auto-Correctable)...${NC}"
    
    # 1. Generate files with correctable format issues
    echo -e "${YELLOW}  1. Creating files with correctable format issues...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((11 + RANDOM % 2)) $((RANDOM % 60)) $((RANDOM % 60)))
    format_issue_price1="TH_PRCH_${DATE_PATTERN}${timestamp1}_FORMAT_CORRECTABLE.csv"
    format_issue_price_path1="$AUTO_CORRECTION_DIR/$format_issue_price1"
    
    # File with extra spaces and inconsistent formatting (can be cleaned up)
    cat > "$format_issue_price_path1" << EOF
  item_id  ,  price  ,  start_date  ,  end_date  
FORMAT001  ,  199.50  ,  $INPUT_DATE  ,  $(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)  
  FORMAT002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
FORMAT003   ,   399.00   ,   $INPUT_DATE   ,   $(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)   
EOF
    echo -e "${GREEN}    Generated: $format_issue_price1 (extra spaces - can auto-trim)${NC}"
    
    timestamp2=$(printf "%02d%02d%02d" $((12 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    format_issue_price2="TH_PRCH_${DATE_PATTERN}${timestamp2}_FORMAT_CORRECTABLE.csv"
    format_issue_price_path2="$AUTO_CORRECTION_DIR/$format_issue_price2"
    
    # File with mixed case headers (can be standardized)
    cat > "$format_issue_price_path2" << EOF
Item_ID,Price,Start_Date,End_Date
FORMAT010,599.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
FORMAT011,699.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
FORMAT012,799.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $format_issue_price2 (mixed case headers - can auto-standardize)${NC}"
    
    # 2. Generate promotion files with correctable format issues
    echo -e "${YELLOW}  2. Creating promotion files with correctable format issues...${NC}"
    
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    timestamp3=$(printf "%02d%02d%02d" $((13 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    format_issue_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}_FORMAT_CORRECTABLE.csv"
    format_issue_promo_path1="$AUTO_CORRECTION_DIR/$format_issue_promo1"
    
    # File with trailing commas and empty fields (can be cleaned)
    cat > "$format_issue_promo_path1" << EOF
promotion_id,discount,start_date,end_date,
FORMAT_PROMO001,25%,$INPUT_DATE,$end_date,
FORMAT_PROMO002,30%,$INPUT_DATE,$end_date,
FORMAT_PROMO003,35%,$INPUT_DATE,$end_date,
EOF
    echo -e "${GREEN}    Generated: $format_issue_promo1 (trailing commas - can auto-remove)${NC}"
    
    echo -e "${GREEN}✅ Format issues (correctable) files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Files with Size Issues (Correctable)
# =============================================================================
generate_size_issues_correctable() {
    echo -e "${RED}🔧 Generating Files with Size Issues (Auto-Correctable)...${NC}"
    
    # 1. Generate files that are too large but can be split
    echo -e "${YELLOW}  1. Creating large files that can be split...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((14 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    large_file_price="TH_PRCH_${DATE_PATTERN}${timestamp1}_LARGE_SPLITTABLE.csv"
    large_file_price_path="$AUTO_CORRECTION_DIR/$large_file_price"
    
    # Create a large file with many rows (can be split into smaller files)
    echo "item_id,price,start_date,end_date" > "$large_file_price_path"
    
    # Generate many rows to make file large but splittable
    for i in {1..5000}; do
        echo "LARGE_SPLIT_$(printf "%05d" $i),$(( RANDOM % 1000 + 100 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$large_file_price_path"
    done
    
    echo -e "${GREEN}    Generated: $large_file_price ($(( $(stat -c%s "$large_file_price_path") / 1024 ))KB - large but splittable)${NC}"
    
    # 2. Generate files that are too small but can be combined
    echo -e "${YELLOW}  2. Creating small files that can be combined or skipped...${NC}"
    
    timestamp2=$(printf "%02d%02d%02d" $((15 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    small_file_price="TH_PRCH_${DATE_PATTERN}${timestamp2}_SMALL_SKIPPABLE.csv"
    small_file_price_path="$AUTO_CORRECTION_DIR/$small_file_price"
    
    # Create a very small file that can be skipped if too small
    cat > "$small_file_price_path" << EOF
item_id,price,start_date,end_date
SMALL001,99.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 1 day" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $small_file_price ($(stat -c%s "$small_file_price_path") bytes - small but can be skipped)${NC}"
    
    echo -e "${GREEN}✅ Size issues (correctable) files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Files with Duplicate Issues (Correctable)
# =============================================================================
generate_duplicate_issues_correctable() {
    echo -e "${RED}🔧 Generating Files with Duplicate Issues (Auto-Correctable)...${NC}"
    
    # 1. Generate files with duplicate rows that can be removed
    echo -e "${YELLOW}  1. Creating files with removable duplicates...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((16 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    duplicate_price1="TH_PRCH_${DATE_PATTERN}${timestamp1}_DUPLICATE_REMOVABLE.csv"
    duplicate_price_path1="$AUTO_CORRECTION_DIR/$duplicate_price1"
    
    # File with exact duplicate rows (can be auto-removed)
    cat > "$duplicate_price_path1" << EOF
item_id,price,start_date,end_date
DUP001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
DUP002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
DUP001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
DUP003,399.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
DUP002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
DUP004,499.25,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $duplicate_price1 (contains exact duplicates - can auto-remove)${NC}"
    
    # 2. Generate promotion files with correctable duplicates
    echo -e "${YELLOW}  2. Creating promotion files with removable duplicates...${NC}"
    
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    timestamp2=$(printf "%02d%02d%02d" $((17 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    duplicate_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp2}_DUPLICATE_REMOVABLE.csv"
    duplicate_promo_path1="$AUTO_CORRECTION_DIR/$duplicate_promo1"
    
    # File with duplicate promotion entries (can be auto-removed)
    cat > "$duplicate_promo_path1" << EOF
promotion_id,discount,start_date,end_date
DUP_PROMO001,25%,$INPUT_DATE,$end_date
DUP_PROMO002,30%,$INPUT_DATE,$end_date
DUP_PROMO001,25%,$INPUT_DATE,$end_date
DUP_PROMO003,35%,$INPUT_DATE,$end_date
DUP_PROMO002,30%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $duplicate_promo1 (contains duplicate promotions - can auto-remove)${NC}"
    
    echo -e "${GREEN}✅ Duplicate issues (correctable) files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Files with Transfer Retry Issues (Correctable)
# =============================================================================
generate_transfer_retry_correctable() {
    echo -e "${RED}🔧 Generating Files with Transfer Retry Issues (Auto-Correctable)...${NC}"
    
    # 1. Generate files that failed transfer but can be retried
    echo -e "${YELLOW}  1. Creating files for transfer retry scenarios...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((18 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    retry_price1="TH_PRCH_${DATE_PATTERN}${timestamp1}_TRANSFER_RETRY.csv"
    retry_price_path1="$AUTO_CORRECTION_DIR/$retry_price1"
    
    # Normal file that can be retried for transfer
    cat > "$retry_price_path1" << EOF
item_id,price,start_date,end_date
RETRY001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
RETRY002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
RETRY003,399.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
RETRY004,499.25,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
RETRY005,599.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $retry_price1 (transfer failed - can auto-retry)${NC}"
    
    timestamp2=$(printf "%02d%02d%02d" $((19 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    retry_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp2}_TRANSFER_RETRY.csv"
    retry_promo_path1="$AUTO_CORRECTION_DIR/$retry_promo1"
    
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    # Normal promotion file that can be retried for transfer
    cat > "$retry_promo_path1" << EOF
promotion_id,discount,start_date,end_date
RETRY_PROMO001,15%,$INPUT_DATE,$end_date
RETRY_PROMO002,20%,$INPUT_DATE,$end_date
RETRY_PROMO003,25%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $retry_promo1 (transfer failed - can auto-retry)${NC}"
    
    echo -e "${GREEN}✅ Transfer retry (correctable) files generated${NC}"
}

# =============================================================================
# FUNCTION: Clean Docker container directories
# =============================================================================
clean_docker_test_files() {
    echo -e "${BLUE}🧹 Cleaning existing files from Docker container...${NC}"
    
    # Define directories to clean
    local docker_dirs=(
        "$SFTP_1P_PRICE"
        "$SFTP_1P_PROMOTION"
        "${SFTP_1P_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE}"
        "${SFTP_1P_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE}"
        "$SFTP_SOA_PRICE"
        "$SFTP_SOA_PROMOTION"
        "${SFTP_SOA_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE}"
        "${SFTP_SOA_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE}"
        "$SFTP_RPM_PROCESSED"
        "$SFTP_RPM_PENDING"
    )
    
    for dir in "${docker_dirs[@]}"; do
        echo -e "${YELLOW}  Cleaning files in: $dir${NC}"
        # Remove all files but keep directory structure
        docker exec $DOCKER_CONTAINER bash -c "rm -f $dir/*.ods $dir/*.csv $dir/invalid/*.ods $dir/invalid/*.csv 2>/dev/null || true"
    done
    
    echo -e "${GREEN}✅ Docker container directories cleaned${NC}"
}

# =============================================================================
# FUNCTION: Upload auto-correction test files
# =============================================================================
upload_auto_correction_files() {
    echo -e "${BLUE}🚀 Uploading auto-correction test files...${NC}"
    
    # Upload all auto-correction test files to 1P
    echo -e "${YELLOW}📤 Uploading correctable error files to 1P...${NC}"
    for file in $AUTO_CORRECTION_DIR/TH_PRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    for file in $AUTO_CORRECTION_DIR/TH_PROMPRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ All auto-correction test files uploaded to 1P${NC}"
    
    # Fix ownership
    fix_ownership

    # Execute complete transfer pipeline (1P → SOA → RPM)
    execute_complete_transfer_pipeline
}

# =============================================================================
# FUNCTION: Simulate partial corrections and re-uploads
# =============================================================================
simulate_partial_corrections() {
    echo -e "${BLUE}🔄 Simulating partial corrections and re-uploads...${NC}"
    
    # Some files will be "corrected" and moved to SOA
    echo -e "${YELLOW}📋 Simulating successful auto-corrections (1P -> SOA)...${NC}"
    
    # Move correctable files to SOA (simulate successful auto-correction)
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        
        # Move some correctable files to SOA (simulate successful correction)
        count=0
        for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*_CORRECTABLE.csv; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                cp \"\$f\" $SFTP_SOA_PRICE/
                echo '  Corrected and moved to SOA: '\$base
                count=\$((count + 1))
                # Only move some files to simulate partial success
                if [ \$count -ge 3 ]; then break; fi
            fi
        done
        
        count=0
        for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*_CORRECTABLE.csv; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                cp \"\$f\" $SFTP_SOA_PROMOTION/
                echo '  Corrected and moved to SOA: '\$base
                count=\$((count + 1))
                # Only move some files to simulate partial success
                if [ \$count -ge 2 ]; then break; fi
            fi
        done
    " || true
    
    # Some files will be moved to RPM (simulate complete processing)
    echo -e "${YELLOW}📦 Simulating complete processing (SOA -> RPM)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        
        # Move some corrected files from SOA to RPM
        count=0
        for f in $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*_CORRECTABLE.csv; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                if [ \$((count % 2)) -eq 0 ]; then
                    cp \"\$f\" $SFTP_RPM_PROCESSED/
                    echo '  Processed to RPM: '\$base
                else
                    cp \"\$f\" $SFTP_RPM_PENDING/
                    echo '  Pending in RPM: '\$base
                fi
                count=\$((count + 1))
                # Process some but not all
                if [ \$count -ge 2 ]; then break; fi
            fi
        done
    " || true
    
    echo -e "${GREEN}✅ Partial correction simulation completed${NC}"
}

# =============================================================================

# =============================================================================
# FUNCTION: Transfer files from 1P to SOA
# =============================================================================
transfer_1p_to_soa() {
    echo -e "${BLUE}🔄 Transferring files from 1P → SOA...${NC}"
    
    # Transfer price files
    echo -e "${YELLOW}📤 Transferring price files (1P → SOA)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.csv $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                if [ ! -f $SFTP_SOA_PRICE/\$base ]; then
                    cp \"\$f\" $SFTP_SOA_PRICE/
                    echo \"  Transferred: \$base\"
                fi
            fi
        done
    " || true
    
    # Transfer promotion files
    echo -e "${YELLOW}📤 Transferring promotion files (1P → SOA)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.csv $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                if [ ! -f $SFTP_SOA_PROMOTION/\$base ]; then
                    cp \"\$f\" $SFTP_SOA_PROMOTION/
                    echo \"  Transferred: \$base\"
                fi
            fi
        done
    " || true
    
    echo -e "${GREEN}✅ 1P → SOA transfer completed${NC}"
}

# =============================================================================
# FUNCTION: Transfer files from SOA to RPM
# =============================================================================
transfer_soa_to_rpm() {
    echo -e "${BLUE}📦 Transferring files from SOA → RPM...${NC}"
    
    # Transfer price files to processed
    echo -e "${YELLOW}📤 Transferring price files (SOA → RPM processed)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        for f in $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*.csv $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                if [ ! -f $SFTP_RPM_PROCESSED/\$base ]; then
                    cp \"\$f\" $SFTP_RPM_PROCESSED/
                    echo \"  Transferred: \$base\"
                fi
            fi
        done
    " || true
    
    # Transfer promotion files to processed
    echo -e "${YELLOW}📤 Transferring promotion files (SOA → RPM processed)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        for f in $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.csv $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                if [ ! -f $SFTP_RPM_PROCESSED/\$base ]; then
                    cp \"\$f\" $SFTP_RPM_PROCESSED/
                    echo \"  Transferred: \$base\"
                fi
            fi
        done
    " || true
    
    echo -e "${GREEN}✅ SOA → RPM transfer completed${NC}"
}

# =============================================================================
# FUNCTION: Complete transfer pipeline (1P → SOA → RPM)
# =============================================================================
execute_complete_transfer_pipeline() {
    echo -e "${BLUE}🚀 Executing complete transfer pipeline (1P → SOA → RPM)...${NC}"
    
    # Step 1: 1P → SOA
    transfer_1p_to_soa
    
    # Small delay between transfers
    sleep 2
    
    # Step 2: SOA → RPM
    transfer_soa_to_rpm
    
    echo -e "${GREEN}✅ Complete transfer pipeline executed successfully${NC}"
}


# =============================================================================
# FUNCTION: Fix file ownership in Docker container
# =============================================================================
fix_ownership() {
    echo -e "${BLUE}🔧 Fixing file ownership in Docker container...${NC}"
    
    # 1P
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_1P_PRICE 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_1P_PROMOTION 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow ${SFTP_1P_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE} 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow ${SFTP_1P_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE} 2>/dev/null || true"

    # SOA
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_SOA_PRICE 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_SOA_PROMOTION 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow ${SFTP_SOA_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE} 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow ${SFTP_SOA_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE} 2>/dev/null || true"

    # RPM
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_RPM_PROCESSED 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R airflow:airflow $SFTP_RPM_ARCHIVE 2>/dev/null || true"

    echo -e "${GREEN}✅ File ownership fixed${NC}"
}

# MAIN EXECUTION
# =============================================================================
main_auto_correction() {
    echo -e "${BLUE}🏁 Starting auto-correction files generation process...${NC}"
    echo -e "${BLUE}📅 Processing date: $INPUT_DATE${NC}"
    
    # Check if Docker container is running
    if ! docker ps | grep -q $DOCKER_CONTAINER; then
        echo -e "${RED}❌ Error: Docker container '$DOCKER_CONTAINER' is not running${NC}"
        echo -e "${YELLOW}💡 Start container first: docker-compose up -d${NC}"
        exit 1
    fi
    
    # Clean Docker container directories if --clean flag was used
    if [ "$CLEAN_DOCKER" -eq 1 ]; then
        clean_docker_test_files
    fi
    
    # Generate different types of correctable error scenarios
    generate_missing_required_fields_correctable
    generate_data_type_mismatch_correctable
    generate_format_issues_correctable
    generate_size_issues_correctable
    generate_duplicate_issues_correctable
    generate_transfer_retry_correctable
    
    # Upload files to test auto-correction
    upload_auto_correction_files
    
    # Simulate partial corrections and processing
    simulate_partial_corrections
    
    echo -e "${GREEN}🎉 Auto-correction files generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing auto-correction and re-upload functionality${NC}"
    echo -e "${BLUE}📋 Local data stored in: $AUTO_CORRECTION_DIR/${NC}"
    echo -e "${BLUE}🔧 Auto-correctable scenarios created:${NC}"
    echo -e "${BLUE}  • Missing required fields (can add default values)${NC}"
    echo -e "${BLUE}  • Data type mismatches (can convert formats)${NC}"
    echo -e "${BLUE}  • Format issues (can clean up formatting)${NC}"
    echo -e "${BLUE}  • Size issues (can split large files / skip small ones)${NC}"
    echo -e "${BLUE}  • Duplicate entries (can remove exact duplicates)${NC}"
    echo -e "${BLUE}  • Transfer failures (can retry transfers)${NC}"
    echo -e "${BLUE}📊 Simulation includes:${NC}"
    echo -e "${BLUE}  • Partial successful corrections${NC}"
    echo -e "${BLUE}  • Files moved through pipeline (1P -> SOA -> RPM)${NC}"
    echo -e "${BLUE}  • Some files remaining uncorrected for testing${NC}"
}

# Run main function if not sourced
main_auto_correction "$@"

# =============================================================================
# FUNCTION: 10-minute transfer loop (1P → SOA → RPM)
# =============================================================================
start_transfer_loop() {
    local interval_seconds=10
    echo -e "${BLUE}⏱️ Starting transfer loop: every 10 minutes (includes directory checks)${NC}"
    # Randomized clear cadence: clear every N cycles, where N ∈ [1,10]
    local cycles_since_clear=0
    local clear_threshold=$((1 + RANDOM % 10))
    echo -e "${YELLOW}🧽 Will clear Docker files every ${clear_threshold} cycle(s) (randomized 1-10)${NC}"
    # Resolve clear script absolute path once
    local script_dir
    script_dir=$(cd "$(dirname "$0")" && pwd)
    local clear_script="${script_dir}/clear_docker_files.sh"
    if [ ! -x "$clear_script" ]; then
        echo -e "${RED}❌ Warning: clear script not executable or not found at: $clear_script${NC}"
        echo -e "${YELLOW}💡 Ensure the script exists and is executable: chmod +x clear_docker_files.sh${NC}"
    fi
    while true; do
        echo -e "${YELLOW}⏰ Starting new cycle at $(date)${NC}"
        
        # Clear current local date directory before each cycle
        local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
        if [ -d "$date_dir" ]; then
            echo -e "${YELLOW}🗑️ Clearing local date directory: $date_dir${NC}"
            rm -rf "$date_dir"
        fi
        # Ensure directories exist each cycle (Step 1)
        check_and_create_directories

        # Generate and upload fresh data each cycle
        echo -e "${YELLOW}🧪 Generating new mock data for this cycle (TOTAL_FILES per type: $TOTAL_FILES)...${NC}"
        generate_price_files
        generate_promotion_files
        generate_feedback_price_files
        generate_feedback_promotion_files
        upload_to_docker
        fix_ownership

        echo -e "${YELLOW}🔄 Syncing 1P → SOA (price, promotion)...${NC}"
        docker exec $DOCKER_CONTAINER bash -lc "
            shopt -s nullglob
            # 1P → SOA price
            for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
                base=\$(basename \"\$f\")
                [ -f $SFTP_SOA_PRICE/\$base ] || cp \"\$f\" $SFTP_SOA_PRICE/
            done
            # 1P → SOA promotion
            for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
                base=\$(basename \"\$f\")
                [ -f $SFTP_SOA_PROMOTION/\$base ] || cp \"\$f\" $SFTP_SOA_PROMOTION/
            done
        " > /dev/null 2>&1 || true

        echo -e "${YELLOW}🧩 Enriching within SOA (SOA → SOA noop step)...${NC}"
        # No-op enrichment placeholder. Extend here if enrichment logic is needed.

        echo -e "${YELLOW}📦 Syncing SOA → RPM (processed only)...${NC}"
        docker exec $DOCKER_CONTAINER bash -lc "
            shopt -s nullglob
            # SOA → RPM price
            for f in $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
                base=\$(basename \"\$f\")
                [ -f $SFTP_RPM_PROCESSED/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/
            done
            # SOA → RPM promotion
            for f in $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
                base=\$(basename \"\$f\")
                [ -f $SFTP_RPM_PROCESSED/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/
            done
        " > /dev/null 2>&1 || true

        echo -e "${GREEN}✅ Cycle completed. Waiting 10 minutes until next cycle...${NC}"
        echo -e "${BLUE}⏰ Next cycle will start at $(date -d "+10 minutes" 2>/dev/null || date -v+10M 2>/dev/null || echo "in 10 minutes")${NC}"
        
        # Increment cycle counter and clear when threshold reached
        cycles_since_clear=$((cycles_since_clear + 1))
        if [ "$cycles_since_clear" -ge "$clear_threshold" ]; then
            echo -e "${YELLOW}🧽 Reached clear threshold (${clear_threshold}). Clearing Docker files now...${NC}"
            if [ -x "$clear_script" ]; then
                "$clear_script" --container "$DOCKER_CONTAINER" || echo -e "${RED}❌ Clear script failed${NC}"
            else
                echo -e "${RED}❌ Skip clearing: clear script not available${NC}"
            fi
            cycles_since_clear=0
            clear_threshold=$((1 + RANDOM % 10))
            echo -e "${YELLOW}🎲 Next clear will happen after ${clear_threshold} cycle(s)${NC}"
        else
            echo -e "${BLUE}ℹ️ Cycles since last clear: ${cycles_since_clear}/${clear_threshold}${NC}"
        fi

        sleep "$interval_seconds"
    done
}
