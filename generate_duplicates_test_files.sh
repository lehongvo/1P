#!/bin/bash

# =============================================================================
# DUPLICATE FILES GENERATOR FOR TESTING DUPLICATE DETECTION
# =============================================================================
#
# This script generates CSV files with duplicate scenarios to test the
# detect_duplicates_ops function in data processing pipelines
#
# USAGE:
#   ./generate_duplicates_test_files.sh [YYYY-MM-DD] [--clean]
#
# OPTIONS:
#   --clean   Clean all files from Docker container before uploading new files
#
# =============================================================================

# More tolerant error handling - continue on some errors
set -u  # Exit on undefined variables

# Import shared configuration from main script
source "$(dirname "$0")/generate_mock_data.sh" --source-only

# Add special flag to prevent main execution when sourced
if [ "${1:-}" == "--source-only" ]; then
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

# Create duplicates directory
DUPLICATES_DIR="$BASE_DIR/$DATE_DIR_FORMAT/duplicates"
mkdir -p "$DUPLICATES_DIR"

echo -e "${BLUE}=== DUPLICATE FILES GENERATOR FOR TESTING ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating files with duplicate scenarios for testing duplicate detection${NC}"

# =============================================================================
# FUNCTION: Generate Price Files with Duplicates
# =============================================================================
generate_price_files_with_duplicates() {
    echo -e "${RED}🔄 Generating Price Files with Duplicate Scenarios...${NC}"
    
    # 1. Generate files with duplicate entries within the same file (source duplicates)
    echo -e "${YELLOW}  1. Creating files with internal duplicates...${NC}"
    
    # File with duplicate rows
    timestamp1=$(printf "%02d%02d%02d" $((7 + RANDOM % 6)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name1="TH_PRCH_${DATE_PATTERN}${timestamp1}.csv"
    file_path1="$DUPLICATES_DIR/$file_name1"
    
    cat > "$file_path1" << EOF
item_id,price,start_date,end_date
ITEM00001,199.50,$INPUT_DATE,2025-09-17
ITEM00002,299.75,$INPUT_DATE,2025-09-17
ITEM00001,199.50,$INPUT_DATE,2025-09-17
ITEM00003,399.00,$INPUT_DATE,2025-09-17
ITEM00002,299.75,$INPUT_DATE,2025-09-17
ITEM00004,499.25,$INPUT_DATE,2025-09-17
ITEM00001,199.50,$INPUT_DATE,2025-09-17
EOF
    echo -e "${GREEN}    Generated: $file_name1 (contains duplicate rows)${NC}"
    
    # File with duplicate item_ids but different prices (partial duplicates)
    timestamp2=$(printf "%02d%02d%02d" $((8 + RANDOM % 5)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name2="TH_PRCH_${DATE_PATTERN}${timestamp2}.csv"
    file_path2="$DUPLICATES_DIR/$file_name2"
    
    cat > "$file_path2" << EOF
item_id,price,start_date,end_date
ITEM00001,199.50,$INPUT_DATE,2025-09-17
ITEM00002,299.75,$INPUT_DATE,2025-09-17
ITEM00001,209.50,$INPUT_DATE,2025-09-17
ITEM00003,399.00,$INPUT_DATE,2025-09-17
ITEM00002,309.75,$INPUT_DATE,2025-09-17
EOF
    echo -e "${GREEN}    Generated: $file_name2 (contains duplicate item_ids with different prices)${NC}"
    
    # 2. Generate files that will create cross-stage duplicates (exist in both 1P and SOA)
    echo -e "${YELLOW}  2. Creating files for cross-stage duplication...${NC}"
    
    timestamp3=$(printf "%02d%02d%02d" $((9 + RANDOM % 4)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name3="TH_PRCH_${DATE_PATTERN}${timestamp3}.csv"
    file_path3="$DUPLICATES_DIR/$file_name3"
    
    cat > "$file_path3" << EOF
item_id,price,start_date,end_date
ITEM00010,599.50,$INPUT_DATE,2025-09-17
ITEM00011,699.75,$INPUT_DATE,2025-09-17
ITEM00012,799.00,$INPUT_DATE,2025-09-17
EOF
    echo -e "${GREEN}    Generated: $file_name3 (for cross-stage duplication testing)${NC}"
    
    # 3. Generate files with many duplicates for stress testing
    echo -e "${YELLOW}  3. Creating files with multiple duplicate patterns...${NC}"
    
    timestamp4=$(printf "%02d%02d%02d" $((10 + RANDOM % 3)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name4="TH_PRCH_${DATE_PATTERN}${timestamp4}.csv"
    file_path4="$DUPLICATES_DIR/$file_name4"
    
    cat > "$file_path4" << EOF
item_id,price,start_date,end_date
ITEM00020,199.50,$INPUT_DATE,2025-09-17
ITEM00021,299.75,$INPUT_DATE,2025-09-17
ITEM00020,199.50,$INPUT_DATE,2025-09-17
ITEM00022,399.00,$INPUT_DATE,2025-09-17
ITEM00021,299.75,$INPUT_DATE,2025-09-17
ITEM00023,499.25,$INPUT_DATE,2025-09-17
ITEM00020,199.50,$INPUT_DATE,2025-09-17
ITEM00024,599.50,$INPUT_DATE,2025-09-17
ITEM00021,299.75,$INPUT_DATE,2025-09-17
ITEM00022,399.00,$INPUT_DATE,2025-09-17
EOF
    echo -e "${GREEN}    Generated: $file_name4 (contains multiple duplicate patterns)${NC}"
    
    echo -e "${GREEN}✅ Price files with duplicate scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Promotion Files with Duplicates
# =============================================================================
generate_promotion_files_with_duplicates() {
    echo -e "${RED}🔄 Generating Promotion Files with Duplicate Scenarios...${NC}"
    
    # Generate random discounts and dates for test data
    discounts=("5%" "10%" "15%" "20%" "25%" "30%" "35%" "40%" "50%")
    
    # Generate random end date (7-30 days from start date)
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    # 1. Generate files with duplicate entries within the same file
    echo -e "${YELLOW}  1. Creating files with internal duplicates...${NC}"
    
    # File with duplicate promotion entries
    timestamp1=$(printf "%02d%02d%02d" $((7 + RANDOM % 6)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name1="TH_PROMPRCH_${DATE_PATTERN}${timestamp1}.csv"
    file_path1="$DUPLICATES_DIR/$file_name1"
    
    cat > "$file_path1" << EOF
promotion_id,discount,start_date,end_date
PROMO00001,15%,$INPUT_DATE,$end_date
PROMO00002,20%,$INPUT_DATE,$end_date
PROMO00001,15%,$INPUT_DATE,$end_date
PROMO00003,25%,$INPUT_DATE,$end_date
PROMO00002,20%,$INPUT_DATE,$end_date
PROMO00004,30%,$INPUT_DATE,$end_date
PROMO00001,15%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $file_name1 (contains duplicate promotion entries)${NC}"
    
    # File with duplicate promotion_ids but different discounts
    timestamp2=$(printf "%02d%02d%02d" $((8 + RANDOM % 5)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name2="TH_PROMPRCH_${DATE_PATTERN}${timestamp2}.csv"
    file_path2="$DUPLICATES_DIR/$file_name2"
    
    cat > "$file_path2" << EOF
promotion_id,discount,start_date,end_date
PROMO00010,15%,$INPUT_DATE,$end_date
PROMO00011,20%,$INPUT_DATE,$end_date
PROMO00010,25%,$INPUT_DATE,$end_date
PROMO00012,30%,$INPUT_DATE,$end_date
PROMO00011,35%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $file_name2 (contains duplicate promotion_ids with different discounts)${NC}"
    
    # 2. Generate files for cross-stage duplication testing
    echo -e "${YELLOW}  2. Creating files for cross-stage duplication...${NC}"
    
    timestamp3=$(printf "%02d%02d%02d" $((9 + RANDOM % 4)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name3="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}.csv"
    file_path3="$DUPLICATES_DIR/$file_name3"
    
    cat > "$file_path3" << EOF
promotion_id,discount,start_date,end_date
PROMO00020,40%,$INPUT_DATE,$end_date
PROMO00021,45%,$INPUT_DATE,$end_date
PROMO00022,50%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $file_name3 (for cross-stage duplication testing)${NC}"
    
    # 3. Generate files with complex duplicate scenarios
    echo -e "${YELLOW}  3. Creating files with complex duplicate patterns...${NC}"
    
    timestamp4=$(printf "%02d%02d%02d" $((10 + RANDOM % 3)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name4="TH_PROMPRCH_${DATE_PATTERN}${timestamp4}.csv"
    file_path4="$DUPLICATES_DIR/$file_name4"
    
    cat > "$file_path4" << EOF
promotion_id,discount,start_date,end_date
PROMO00030,15%,$INPUT_DATE,$end_date
PROMO00031,20%,$INPUT_DATE,$end_date
PROMO00030,15%,$INPUT_DATE,$end_date
PROMO00032,25%,$INPUT_DATE,$end_date
PROMO00031,20%,$INPUT_DATE,$end_date
PROMO00033,30%,$INPUT_DATE,$end_date
PROMO00030,15%,$INPUT_DATE,$end_date
PROMO00034,35%,$INPUT_DATE,$end_date
PROMO00031,20%,$INPUT_DATE,$end_date
PROMO00032,25%,$INPUT_DATE,$end_date
PROMO00035,40%,$INPUT_DATE,$end_date
PROMO00030,15%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $file_name4 (contains complex duplicate patterns)${NC}"
    
    echo -e "${GREEN}✅ Promotion files with duplicate scenarios generated${NC}"
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
# FUNCTION: Upload duplicate files to Docker SFTP Container
# =============================================================================
upload_duplicate_files_to_docker() {
    echo -e "${BLUE}🚀 Uploading duplicate files to Docker SFTP Container...${NC}"
    
    # Upload Price Files with duplicates
    echo -e "${YELLOW}📤 Uploading Price files with duplicates...${NC}"
    for file in $DUPLICATES_DIR/TH_PRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Promotion Files with duplicates
    echo -e "${YELLOW}📤 Uploading Promotion files with duplicates...${NC}"
    for file in $DUPLICATES_DIR/TH_PROMPRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ All duplicate files uploaded to Docker container${NC}"
    
    # Fix ownership
    fix_ownership

    # Execute complete transfer pipeline (1P → SOA → RPM)
    execute_complete_transfer_pipeline
}

# =============================================================================
# FUNCTION: Create Cross-Stage Duplicates (1P → SOA)
# =============================================================================
create_cross_stage_duplicates() {
    echo -e "${BLUE}🔄 Creating cross-stage duplicates (1P → SOA)...${NC}"
    
    # Copy some files from 1P to SOA to simulate normal transfer
    echo -e "${YELLOW}📋 Copying files to SOA to create cross-stage duplicates...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        
        # Copy CROSS_STAGE files from 1P to SOA (this creates normal duplicates)
        for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.csv; do
            base=\$(basename \"\$f\")
            cp \"\$f\" $SFTP_SOA_PRICE/
            echo '  Copied to SOA: '\$base
        done
        
        for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.csv; do
            base=\$(basename \"\$f\")
            cp \"\$f\" $SFTP_SOA_PROMOTION/
            echo '  Copied to SOA: '\$base
        done
    " || true
    
    echo -e "${GREEN}✅ Cross-stage duplicates created${NC}"
}

# =============================================================================
# FUNCTION: Create Orphaned Files (exist in SOA but not in 1P source)
# =============================================================================
create_orphaned_files() {
    echo -e "${BLUE}👻 Creating orphaned files (exist in SOA but not in 1P)...${NC}"
    
    # Create orphaned price files
    timestamp1=$(printf "%02d%02d%02d" $((12 + RANDOM % 3)) $((RANDOM % 60)) $((RANDOM % 60)))
    orphan_price_file="TH_PRCH_${DATE_PATTERN}${timestamp1}.csv"
    
    # Calculate end date safely
    if command -v gdate >/dev/null 2>&1; then
        # macOS with GNU date installed
        end_date=$(gdate -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
    elif date --version >/dev/null 2>&1; then
        # GNU date (Linux)
        end_date=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
    else
        # BSD date (macOS default) - use a simple approach
        end_date=$(date -j -v+30d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d 2>/dev/null || echo "2025-09-17")
    fi
    
    # Create temporary orphaned file
    temp_orphan_price="/tmp/$orphan_price_file"
    cat > "$temp_orphan_price" << EOF
item_id,price,start_date,end_date
ORPHAN001,199.99,$INPUT_DATE,$end_date
ORPHAN002,299.99,$INPUT_DATE,$end_date
EOF
    
    # Upload directly to SOA (not to 1P) - use error handling
    if docker cp "$temp_orphan_price" $DOCKER_CONTAINER:$SFTP_SOA_PRICE/ >/dev/null 2>&1; then
        echo -e "${GREEN}  Created orphaned price file: $orphan_price_file${NC}"
    else
        echo -e "${YELLOW}  Warning: Could not upload orphaned price file (continuing...)${NC}"
    fi
    rm -f "$temp_orphan_price"
    
    # Create orphaned promotion files
    timestamp2=$(printf "%02d%02d%02d" $((13 + RANDOM % 2)) $((RANDOM % 60)) $((RANDOM % 60)))
    orphan_promo_file="TH_PROMPRCH_${DATE_PATTERN}${timestamp2}.csv"
    
    # Create temporary orphaned file
    temp_orphan_promo="/tmp/$orphan_promo_file"
    cat > "$temp_orphan_promo" << EOF
promotion_id,discount,start_date,end_date
ORPHAN_PROMO001,25%,$INPUT_DATE,$end_date
ORPHAN_PROMO002,30%,$INPUT_DATE,$end_date
EOF
    
    # Upload directly to SOA (not to 1P) - use error handling
    if docker cp "$temp_orphan_promo" $DOCKER_CONTAINER:$SFTP_SOA_PROMOTION/ >/dev/null 2>&1; then
        echo -e "${GREEN}  Created orphaned promotion file: $orphan_promo_file${NC}"
    else
        echo -e "${YELLOW}  Warning: Could not upload orphaned promotion file (continuing...)${NC}"
    fi
    rm -f "$temp_orphan_promo"
    
    echo -e "${GREEN}✅ Orphaned files created in SOA${NC}"
}

# =============================================================================
# FUNCTION: Transfer duplicate files through pipeline (1P → SOA → RPM)
# =============================================================================
transfer_duplicate_files() {
    echo -e "${BLUE}🚚 Transferring duplicate files from 1P → SOA → RPM...${NC}"
    
    # Transfer from 1P to SOA (some files)
    echo -e "${YELLOW}🔄 Syncing 1P → SOA (duplicate files)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        
        # 1P → SOA price (copy some duplicate files)
        for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*_DUPLICATE_*.csv; do
            base=\$(basename \"\$f\")
            [ -f $SFTP_SOA_PRICE/\$base ] || cp \"\$f\" $SFTP_SOA_PRICE/
            echo '  Transferred: '\$base
        done
        
        # 1P → SOA promotion (copy some duplicate files)
        for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*_DUPLICATE_*.csv; do
            base=\$(basename \"\$f\")
            [ -f $SFTP_SOA_PROMOTION/\$base ] || cp \"\$f\" $SFTP_SOA_PROMOTION/
            echo '  Transferred: '\$base
        done
    " || true

    # Transfer from SOA to RPM (some files)
    echo -e "${YELLOW}📦 Syncing SOA → RPM (duplicate files)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        
        # SOA → RPM price (copy some files to processed, some to pending)
        count=0
        for f in $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*.csv; do
            base=\$(basename \"\$f\")
            if [ \$((count % 2)) -eq 0 ]; then
                [ -f $SFTP_RPM_PROCESSED/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/
                echo '  Transferred to processed: '\$base
            else
                [ -f $SFTP_RPM_PENDING/\$base ] || cp \"\$f\" $SFTP_RPM_PENDING/
                echo '  Transferred to pending: '\$base
            fi
            count=\$((count + 1))
        done
        
        # SOA → RPM promotion (copy some files to processed, some to pending)
        count=0
        for f in $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.csv; do
            base=\$(basename \"\$f\")
            if [ \$((count % 2)) -eq 0 ]; then
                [ -f $SFTP_RPM_PROCESSED/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/
                echo '  Transferred to processed: '\$base
            else
                [ -f $SFTP_RPM_PENDING/\$base ] || cp \"\$f\" $SFTP_RPM_PENDING/
                echo '  Transferred to pending: '\$base
            fi
            count=\$((count + 1))
        done
    " || true

    echo -e "${GREEN}✅ Transfer of duplicate files complete${NC}"
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
main_duplicates() {
    echo -e "${BLUE}🏁 Starting duplicate files generation process...${NC}"
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
    
    # Generate files with duplicate scenarios
    generate_price_files_with_duplicates
    generate_promotion_files_with_duplicates
    
    # Upload files to Docker
    upload_duplicate_files_to_docker
    
    # Create cross-stage duplicates (1P -> SOA)
    create_cross_stage_duplicates
    
    # Create orphaned files (exist only in SOA)
    create_orphaned_files
    
    # Transfer files through the pipeline (1P → SOA → RPM)
    transfer_duplicate_files
    
    echo -e "${GREEN}🎉 Duplicate files generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing duplicate detection${NC}"
    echo -e "${BLUE}📋 Local data stored in: $DUPLICATES_DIR/${NC}"
    echo -e "${BLUE}🔍 Test scenarios created:${NC}"
    echo -e "${BLUE}  • Source duplicates (within same file)${NC}"
    echo -e "${BLUE}  • Cross-stage duplicates (1P ↔ SOA)${NC}"
    echo -e "${BLUE}  • Orphaned files (SOA only)${NC}"
    echo -e "${BLUE}  • Complex duplicate patterns${NC}"
}

# Run main function if not sourced
main_duplicates "$@"

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
