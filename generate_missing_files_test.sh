#!/bin/bash

# =============================================================================
# MISSING FILES GENERATOR FOR TESTING MISSING FILE DETECTION
# =============================================================================
#
# This script generates missing file scenarios to test the
# detect_missing_files function in data processing pipelines
#
# USAGE:
#   ./generate_missing_files_test.sh [YYYY-MM-DD] [--clean]
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

# Create missing files directory
MISSING_DIR="$BASE_DIR/$DATE_DIR_FORMAT/missing_files"
mkdir -p "$MISSING_DIR"

echo -e "${BLUE}=== MISSING FILES GENERATOR FOR TESTING ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating missing file scenarios for testing missing file detection${NC}"

# =============================================================================
# FUNCTION: Generate Files for Transfer Failure Testing (exist in 1P only)
# =============================================================================
generate_transfer_failure_files() {
    echo -e "${RED}❌ Generating Files for Transfer Failure Testing...${NC}"
    
    # 1. Generate price files that will exist in 1P but NOT be transferred to SOA
    echo -e "${YELLOW}  1. Creating price files for transfer failure scenarios...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    transfer_fail_price1="TH_PRCH_${DATE_PATTERN}${timestamp1}.csv"
    transfer_fail_price_path1="$MISSING_DIR/$transfer_fail_price1"
    
    cat > "$transfer_fail_price_path1" << EOF
item_id,price,start_date,end_date
FAIL001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
FAIL002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
FAIL003,399.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $transfer_fail_price1 (will exist in 1P only - transfer failure)${NC}"
    
    timestamp2=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    transfer_fail_price2="TH_PRCH_${DATE_PATTERN}${timestamp2}.csv"
    transfer_fail_price_path2="$MISSING_DIR/$transfer_fail_price2"
    
    cat > "$transfer_fail_price_path2" << EOF
item_id,price,start_date,end_date
FAIL010,599.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
FAIL011,699.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
FAIL012,799.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
FAIL013,899.25,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $transfer_fail_price2 (will exist in 1P only - transfer failure)${NC}"
    
    # 2. Generate promotion files that will exist in 1P but NOT be transferred to SOA
    echo -e "${YELLOW}  2. Creating promotion files for transfer failure scenarios...${NC}"
    
    # Generate random discounts and dates for test data
    discounts=("5%" "10%" "15%" "20%" "25%" "30%" "35%" "40%" "50%")
    
    # Generate random end date (7-30 days from start date)
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    timestamp3=$(printf "%02d%02d%02d" $((7 + RANDOM % 6)) $((RANDOM % 60)) $((RANDOM % 60)))
    transfer_fail_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}.csv"
    transfer_fail_promo_path1="$MISSING_DIR/$transfer_fail_promo1"
    
    cat > "$transfer_fail_promo_path1" << EOF
promotion_id,discount,start_date,end_date
FAIL_PROMO001,25%,$INPUT_DATE,$end_date
FAIL_PROMO002,30%,$INPUT_DATE,$end_date
FAIL_PROMO003,35%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $transfer_fail_promo1 (will exist in 1P only - transfer failure)${NC}"
    
    echo -e "${GREEN}✅ Transfer failure files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Files for Data Loss Risk Testing (old files)
# =============================================================================
generate_data_loss_risk_files() {
    echo -e "${RED}🚨 Generating Files for Data Loss Risk Testing...${NC}"
    
    # 1. Generate old price files (simulate files from yesterday or older)
    echo -e "${YELLOW}  1. Creating old price files (>24 hours - data loss risk)...${NC}"
    
    # Create files with yesterday's date pattern
    if [ "$(detect_os)" = "macos" ]; then
        old_date=$(date -j -v-2d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
        old_date_pattern=$(date -j -v-2d -f "%Y-%m-%d" "$INPUT_DATE" +%Y%m%d)
    else
        old_date=$(date -d "$INPUT_DATE - 2 days" +%Y-%m-%d)
        old_date_pattern=$(date -d "$INPUT_DATE - 2 days" +%Y%m%d)
    fi
    
    timestamp1=$(printf "%02d%02d%02d" $((8 + RANDOM % 5)) $((RANDOM % 60)) $((RANDOM % 60)))
    old_price1="TH_PRCH_${old_date_pattern}${timestamp1}.csv"
    old_price_path1="$MISSING_DIR/$old_price1"
    
    cat > "$old_price_path1" << EOF
item_id,price,start_date,end_date
OLD001,199.50,$old_date,$(date -d "$old_date + 30 days" +%Y-%m-%d)
OLD002,299.75,$old_date,$(date -d "$old_date + 30 days" +%Y-%m-%d)
OLD003,399.00,$old_date,$(date -d "$old_date + 30 days" +%Y-%m-%d)
OLD004,499.25,$old_date,$(date -d "$old_date + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $old_price1 (old file from $old_date - data loss risk)${NC}"
    
    # Create files with even older date (3 days ago)
    if [ "$(detect_os)" = "macos" ]; then
        very_old_date=$(date -j -v-3d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
        very_old_date_pattern=$(date -j -v-3d -f "%Y-%m-%d" "$INPUT_DATE" +%Y%m%d)
    else
        very_old_date=$(date -d "$INPUT_DATE - 3 days" +%Y-%m-%d)
        very_old_date_pattern=$(date -d "$INPUT_DATE - 3 days" +%Y%m%d)
    fi
    
    timestamp2=$(printf "%02d%02d%02d" $((9 + RANDOM % 4)) $((RANDOM % 60)) $((RANDOM % 60)))
    very_old_price="TH_PRCH_${very_old_date_pattern}${timestamp2}_VERY.csv"
    very_old_price_path="$MISSING_DIR/$very_old_price"
    
    cat > "$very_old_price_path" << EOF
item_id,price,start_date,end_date
VERYOLD001,599.50,$very_old_date,$(date -d "$very_old_date + 30 days" +%Y-%m-%d)
VERYOLD002,699.75,$very_old_date,$(date -d "$very_old_date + 30 days" +%Y-%m-%d)
VERYOLD003,799.00,$very_old_date,$(date -d "$very_old_date + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $very_old_price (very old file from $very_old_date - high data loss risk)${NC}"
    
    # 2. Generate old promotion files
    echo -e "${YELLOW}  2. Creating old promotion files (>24 hours - data loss risk)...${NC}"
    
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        old_end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$old_date" +%Y-%m-%d)
    else
        old_end_date=$(date -d "$old_date + $days_to_add days" +%Y-%m-%d)
    fi
    
    timestamp3=$(printf "%02d%02d%02d" $((10 + RANDOM % 3)) $((RANDOM % 60)) $((RANDOM % 60)))
    old_promo="TH_PROMPRCH_${old_date_pattern}${timestamp3}.csv"
    old_promo_path="$MISSING_DIR/$old_promo"
    
    cat > "$old_promo_path" << EOF
promotion_id,discount,start_date,end_date
OLD_PROMO001,15%,$old_date,$old_end_date
OLD_PROMO002,20%,$old_date,$old_end_date
OLD_PROMO003,25%,$old_date,$old_end_date
OLD_PROMO004,30%,$old_date,$old_end_date
OLD_PROMO005,35%,$old_date,$old_end_date
EOF
    echo -e "${GREEN}    Generated: $old_promo (old promotion file from $old_date - data loss risk)${NC}"
    
    echo -e "${GREEN}✅ Data loss risk files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Orphaned Files (exist in SOA but not in 1P)
# =============================================================================
generate_orphaned_files_in_soa() {
    echo -e "${RED}👻 Generating Orphaned Files (exist in SOA but not in 1P source)...${NC}"
    
    # 1. Generate orphaned price files
    echo -e "${YELLOW}  1. Creating orphaned price files (SOA only)...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((11 + RANDOM % 2)) $((RANDOM % 60)) $((RANDOM % 60)))
    orphan_price1="TH_PRCH_${DATE_PATTERN}${timestamp1}_ORPHANED_SOA.csv"
    
    # Create temporary orphaned file (will be uploaded directly to SOA)
    temp_orphan_price1="/tmp/$orphan_price1"
    cat > "$temp_orphan_price1" << EOF
item_id,price,start_date,end_date
ORPHAN001,199.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
ORPHAN002,299.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
ORPHAN003,399.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $orphan_price1 (will be orphaned in SOA)${NC}"
    
    timestamp2=$(printf "%02d%02d%02d" $((12 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    orphan_price2="TH_PRCH_${DATE_PATTERN}${timestamp2}_ORPHANED_SOA.csv"
    
    # Create another temporary orphaned file
    temp_orphan_price2="/tmp/$orphan_price2"
    cat > "$temp_orphan_price2" << EOF
item_id,price,start_date,end_date
ORPHAN010,599.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
ORPHAN011,699.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
ORPHAN012,799.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
ORPHAN013,899.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
ORPHAN014,999.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $orphan_price2 (will be orphaned in SOA)${NC}"
    
    # 2. Generate orphaned promotion files
    echo -e "${YELLOW}  2. Creating orphaned promotion files (SOA only)...${NC}"
    
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    timestamp3=$(printf "%02d%02d%02d" $((13 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    orphan_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}_ORPHANED_SOA.csv"
    
    # Create temporary orphaned promotion file
    temp_orphan_promo="/tmp/$orphan_promo"
    cat > "$temp_orphan_promo" << EOF
promotion_id,discount,start_date,end_date
ORPHAN_PROMO001,40%,$INPUT_DATE,$end_date
ORPHAN_PROMO002,45%,$INPUT_DATE,$end_date
ORPHAN_PROMO003,50%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $orphan_promo (will be orphaned in SOA)${NC}"
    
    # Store orphan file paths for later upload
    ORPHAN_FILES=(
        "$temp_orphan_price1:$SFTP_SOA_PRICE"
        "$temp_orphan_price2:$SFTP_SOA_PRICE"
        "$temp_orphan_promo:$SFTP_SOA_PROMOTION"
    )
    
    echo -e "${GREEN}✅ Orphaned files generated (will be uploaded to SOA only)${NC}"
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
# FUNCTION: Upload files to create missing file scenarios
# =============================================================================
upload_files_for_missing_scenarios() {
    echo -e "${BLUE}🚀 Uploading files to create missing file scenarios...${NC}"
    
    # 1. Upload transfer failure files to 1P ONLY (not to SOA)
    echo -e "${YELLOW}📤 Uploading transfer failure files to 1P only...${NC}"
    for file in $MISSING_DIR/TH_PRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to 1P: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    for file in $MISSING_DIR/TH_PROMPRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to 1P: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # 2. Upload data loss risk files to 1P ONLY (simulate old files that haven't been processed)
    echo -e "${YELLOW}📤 Uploading data loss risk files to 1P only...${NC}"
    for file in $MISSING_DIR/TH_PRCH_*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded old file to 1P: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    for file in $MISSING_DIR/TH_PROMPRCH_*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded old file to 1P: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # 3. Upload orphaned files to SOA ONLY (not to 1P)
    echo -e "${YELLOW}📤 Uploading orphaned files to SOA only...${NC}"
    for orphan_entry in "${ORPHAN_FILES[@]}"; do
        file_path="${orphan_entry%:*}"
        destination="${orphan_entry#*:}"
        
        if [ -f "$file_path" ]; then
            if docker cp "$file_path" $DOCKER_CONTAINER:$destination/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded orphaned file to SOA: $(basename "$file_path")${NC}"
                rm -f "$file_path"  # Clean up temp file
            else
                echo -e "${RED}  Failed to upload orphaned file: $(basename "$file_path")${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ All missing file scenario files uploaded${NC}"
    
    # Fix ownership
    fix_ownership

    # Execute complete transfer pipeline (1P → SOA → RPM)
    execute_complete_transfer_pipeline
}

# =============================================================================
# FUNCTION: Create additional missing scenarios (partial transfers)
# =============================================================================
create_partial_transfer_scenarios() {
    echo -e "${BLUE}🔄 Creating partial transfer scenarios...${NC}"
    
    # Upload some normal files to create baseline for comparison
    echo -e "${YELLOW}📋 Creating baseline files for missing file comparison...${NC}"
    
    # Generate some normal files first
    timestamp1=$(printf "%02d%02d%02d" $((14 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    normal_price="TH_PRCH_${DATE_PATTERN}${timestamp1}_NORMAL_FOR.csv"
    normal_price_path="$MISSING_DIR/$normal_price"
    
    cat > "$normal_price_path" << EOF
item_id,price,start_date,end_date
NORMAL001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
NORMAL002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
NORMAL003,399.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    
    # Upload normal file to both 1P and SOA
    docker cp "$normal_price_path" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1
    docker cp "$normal_price_path" $DOCKER_CONTAINER:$SFTP_SOA_PRICE/ >/dev/null 2>&1
    echo -e "${GREEN}  Created baseline file: $normal_price (exists in both 1P and SOA)${NC}"
    
    # Create some files that exist in 1P and SOA but NOT in RPM (for RPM missing detection)
    timestamp2=$(printf "%02d%02d%02d" $((15 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    missing_rpm_price="TH_PRCH_${DATE_PATTERN}${timestamp2}_MISSING_FROM_RPM.csv"
    missing_rpm_price_path="$MISSING_DIR/$missing_rpm_price"
    
    cat > "$missing_rpm_price_path" << EOF
item_id,price,start_date,end_date
MISS_RPM001,499.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
MISS_RPM002,599.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    
    # Upload to 1P and SOA but NOT to RPM
    docker cp "$missing_rpm_price_path" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1
    docker cp "$missing_rpm_price_path" $DOCKER_CONTAINER:$SFTP_SOA_PRICE/ >/dev/null 2>&1
    echo -e "${GREEN}  Created RPM missing scenario: $missing_rpm_price (exists in 1P & SOA, missing from RPM)${NC}"
    
    echo -e "${GREEN}✅ Partial transfer scenarios created${NC}"
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
main_missing_files() {
    echo -e "${BLUE}🏁 Starting missing files generation process...${NC}"
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
    
    # Generate different types of missing file scenarios
    generate_transfer_failure_files
    generate_data_loss_risk_files
    generate_orphaned_files_in_soa
    
    # Upload files to create missing scenarios
    upload_files_for_missing_scenarios
    
    # Create additional partial transfer scenarios
    create_partial_transfer_scenarios
    
    echo -e "${GREEN}🎉 Missing files generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing missing file detection${NC}"
    echo -e "${BLUE}📋 Local data stored in: $MISSING_DIR/${NC}"
    echo -e "${BLUE}🔍 Missing file scenarios created:${NC}"
    echo -e "${BLUE}  • Transfer failures (exist in 1P, missing from SOA)${NC}"
    echo -e "${BLUE}  • Data loss risk (old files >24h not processed)${NC}"
    echo -e "${BLUE}  • Orphaned files (exist in SOA, not in 1P source)${NC}"
    echo -e "${BLUE}  • RPM missing files (exist in 1P & SOA, missing from RPM)${NC}"
    echo -e "${BLUE}  • Baseline files (exist in all stages for comparison)${NC}"
}

# Run main function if not sourced
main_missing_files "$@"

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
