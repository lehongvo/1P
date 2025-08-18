#!/bin/bash

# =============================================================================
# CORRUPT FILES GENERATOR FOR TESTING CORRUPTION DETECTION
# =============================================================================
#
# This script generates files with corruption issues to test the
# detect_corrupt_files function in data processing pipelines
#
# USAGE:
#   ./generate_corrupt_files_test.sh [YYYY-MM-DD] [--clean]
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

# Create corrupt files directory
CORRUPT_DIR="$BASE_DIR/$DATE_DIR_FORMAT/corrupt_files"
mkdir -p "$CORRUPT_DIR"

echo -e "${BLUE}=== CORRUPT FILES GENERATOR FOR TESTING ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating files with corruption issues for testing corruption detection${NC}"

# =============================================================================
# FUNCTION: Generate Price Files with Corruption Issues
# =============================================================================
generate_corrupt_price_files() {
    echo -e "${RED}💀 Generating Price Files with Corruption Issues...${NC}"
    
    # 1. Generate zero-size files
    echo -e "${YELLOW}  1. Creating zero-size files...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    zero_file1="TH_PRCH_${DATE_PATTERN}${timestamp1}.csv"
    zero_path1="$CORRUPT_DIR/$zero_file1"
    
    # Create completely empty file (zero bytes)
    touch "$zero_path1"
    echo -e "${GREEN}    Generated: $zero_file1 (0 bytes - zero size)${NC}"
    
    timestamp2=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    zero_file2="TH_PRCH_${DATE_PATTERN}${timestamp2}.csv"
    zero_path2="$CORRUPT_DIR/$zero_file2"
    
    # Another zero-size file
    > "$zero_path2"  # Alternative way to create zero-size file
    echo -e "${GREEN}    Generated: $zero_file2 (0 bytes - zero size)${NC}"
    
    # 2. Generate files that are too small (< 1MB default minimum)
    echo -e "${YELLOW}  2. Creating files that are too small...${NC}"
    
    timestamp3=$(printf "%02d%02d%02d" $((7 + RANDOM % 6)) $((RANDOM % 60)) $((RANDOM % 60)))
    small_file1="TH_PRCH_${DATE_PATTERN}${timestamp3}.csv"
    small_path1="$CORRUPT_DIR/$small_file1"
    
    # Create file with just header and one tiny row (very small)
    cat > "$small_path1" << EOF
item_id,price,start_date,end_date
TINY01,1.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 1 day" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $small_file1 ($(stat -c%s "$small_path1") bytes - too small)${NC}"
    
    timestamp4=$(printf "%02d%02d%02d" $((8 + RANDOM % 5)) $((RANDOM % 60)) $((RANDOM % 60)))
    small_file2="TH_PRCH_${DATE_PATTERN}${timestamp4}.csv"
    small_path2="$CORRUPT_DIR/$small_file2"
    
    # Create file with just header (extremely small)
    echo "item_id,price,start_date,end_date" > "$small_path2"
    echo -e "${GREEN}    Generated: $small_file2 ($(stat -c%s "$small_path2") bytes - too small)${NC}"
    
    # 3. Generate files that are too large (> 100MB default maximum)
    echo -e "${YELLOW}  3. Creating files that are too large...${NC}"
    
    timestamp5=$(printf "%02d%02d%02d" $((9 + RANDOM % 4)) $((RANDOM % 60)) $((RANDOM % 60)))
    large_file1="TH_PRCH_${DATE_PATTERN}${timestamp5}.csv"
    large_path1="$CORRUPT_DIR/$large_file1"
    
    # Create a large file by repeating data (simulate large file)
    # Note: We'll create a smaller version for testing but indicate it represents a large file
    echo "item_id,price,start_date,end_date" > "$large_path1"
    
    # Generate many rows to make file large (simulating 100MB+ file)
    for i in {1..10000}; do
        echo "LARGE_ITEM_$(printf "%05d" $i),$(( RANDOM % 1000 + 100 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$large_path1"
    done
    
    # Add more data to exceed size limits
    for i in {1..5000}; do
        echo "EXTRA_LARGE_ITEM_$(printf "%05d" $i),$(( RANDOM % 1000 + 100 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),EXTRA_COLUMN_WITH_LOTS_OF_DATA_TO_MAKE_FILE_LARGER_THAN_EXPECTED_LIMITS,MORE_PADDING_DATA_HERE,AND_EVEN_MORE_PADDING_TO_INCREASE_SIZE" >> "$large_path1"
    done
    
    echo -e "${GREEN}    Generated: $large_file1 ($(( $(stat -c%s "$large_path1") / 1024 / 1024 ))MB - potentially too large)${NC}"
    
    # 4. Generate unreadable/corrupted files
    echo -e "${YELLOW}  4. Creating unreadable/corrupted files...${NC}"
    
    timestamp6=$(printf "%02d%02d%02d" $((10 + RANDOM % 3)) $((RANDOM % 60)) $((RANDOM % 60)))
    corrupt_file1="TH_PRCH_${DATE_PATTERN}${timestamp6}_UNREADABLE.csv"
    corrupt_path1="$CORRUPT_DIR/$corrupt_file1"
    
    # Create file with binary/invalid data that looks like CSV but isn't readable
    echo "item_id,price,start_date,end_date" > "$corrupt_path1"
    # Add some binary data mixed with text
    echo -e "CORRUPT01,\x00\x01\x02\xFF\xFE,invalid_date,\x80\x81" >> "$corrupt_path1"
    echo -e "CORRUPT02,\x00\x00\x00\x00,\x00\x00\x00\x00,\x00\x00\x00\x00" >> "$corrupt_path1"
    echo "CORRUPT03,price_with_invalid_characters_êþÿÿ,2024-13-45,2024-15-99" >> "$corrupt_path1"
    echo -e "${GREEN}    Generated: $corrupt_file1 (contains binary/invalid data)${NC}"
    
    timestamp7=$(printf "%02d%02d%02d" $((11 + RANDOM % 2)) $((RANDOM % 60)) $((RANDOM % 60)))
    corrupt_file2="TH_PRCH_${DATE_PATTERN}${timestamp7}_TRUNCATED.csv"
    corrupt_path2="$CORRUPT_DIR/$corrupt_file2"
    
    # Create file that appears to be truncated mid-record
    cat > "$corrupt_path2" << EOF
item_id,price,start_date,end_date
ITEM001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
ITEM002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
ITEM003,399.00,$INPUT_DATE
EOF
    # Note: Last line is intentionally incomplete (truncated)
    echo -e "${GREEN}    Generated: $corrupt_file2 (truncated/incomplete data)${NC}"
    
    # 5. Generate files with encoding issues
    echo -e "${YELLOW}  5. Creating files with encoding issues...${NC}"
    
    timestamp8=$(printf "%02d%02d%02d" $((12 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    encoding_file="TH_PRCH_${DATE_PATTERN}${timestamp8}_BAD_ENCODING.csv"
    encoding_path="$CORRUPT_DIR/$encoding_file"
    
    # Create file with invalid UTF-8 encoding
    echo "item_id,price,start_date,end_date" > "$encoding_path"
    echo "ENCODING01,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$encoding_path"
    # Add some non-UTF8 bytes
    printf "ENCODING02,299.75,\xff\xfe\x00\x00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)\n" >> "$encoding_path"
    echo -e "${GREEN}    Generated: $encoding_file (invalid UTF-8 encoding)${NC}"
    
    echo -e "${GREEN}✅ Price files with corruption issues generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Promotion Files with Corruption Issues
# =============================================================================
generate_corrupt_promotion_files() {
    echo -e "${RED}💀 Generating Promotion Files with Corruption Issues...${NC}"
    
    # Generate random discounts and dates for test data
    discounts=("5%" "10%" "15%" "20%" "25%" "30%" "35%" "40%" "50%")
    
    # Generate random end date (7-30 days from start date)
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    # 1. Generate zero-size promotion files
    echo -e "${YELLOW}  1. Creating zero-size promotion files...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    zero_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp1}.csv"
    zero_promo_path1="$CORRUPT_DIR/$zero_promo1"
    
    # Create completely empty file
    touch "$zero_promo_path1"
    echo -e "${GREEN}    Generated: $zero_promo1 (0 bytes - zero size)${NC}"
    
    # 2. Generate promotion files that are too small
    echo -e "${YELLOW}  2. Creating promotion files that are too small...${NC}"
    
    timestamp2=$(printf "%02d%02d%02d" $((7 + RANDOM % 6)) $((RANDOM % 60)) $((RANDOM % 60)))
    small_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp2}.csv"
    small_promo_path1="$CORRUPT_DIR/$small_promo1"
    
    # Create very small promotion file
    cat > "$small_promo_path1" << EOF
promotion_id,discount,start_date,end_date
TINY_PROMO01,5%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $small_promo1 ($(stat -c%s "$small_promo_path1") bytes - too small)${NC}"
    
    # 3. Generate large promotion files
    echo -e "${YELLOW}  3. Creating promotion files that are too large...${NC}"
    
    timestamp3=$(printf "%02d%02d%02d" $((9 + RANDOM % 4)) $((RANDOM % 60)) $((RANDOM % 60)))
    large_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}.csv"
    large_promo_path1="$CORRUPT_DIR/$large_promo1"
    
    # Create a large promotion file
    echo "promotion_id,discount,start_date,end_date" > "$large_promo_path1"
    
    # Generate many promotion rows to make file large
    for i in {1..8000}; do
        discount_idx=$((RANDOM % ${#discounts[@]}))
        discount=${discounts[$discount_idx]}
        echo "LARGE_PROMO_$(printf "%05d" $i),$discount,$INPUT_DATE,$end_date" >> "$large_promo_path1"
    done
    
    # Add extra data to make it even larger
    for i in {1..3000}; do
        echo "EXTRA_LARGE_PROMO_$(printf "%05d" $i),50%,$INPUT_DATE,$end_date,EXTRA_PADDING_DATA_TO_MAKE_FILE_LARGER_AND_EXCEED_SIZE_LIMITS,MORE_DATA_HERE,ADDITIONAL_COLUMNS_FOR_SIZE" >> "$large_promo_path1"
    done
    
    echo -e "${GREEN}    Generated: $large_promo1 ($(( $(stat -c%s "$large_promo_path1") / 1024 / 1024 ))MB - potentially too large)${NC}"
    
    # 4. Generate unreadable/corrupted promotion files
    echo -e "${YELLOW}  4. Creating unreadable/corrupted promotion files...${NC}"
    
    timestamp4=$(printf "%02d%02d%02d" $((10 + RANDOM % 3)) $((RANDOM % 60)) $((RANDOM % 60)))
    corrupt_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp4}_UNREADABLE.csv"
    corrupt_promo_path1="$CORRUPT_DIR/$corrupt_promo1"
    
    # Create corrupted promotion file
    echo "promotion_id,discount,start_date,end_date" > "$corrupt_promo_path1"
    # Add binary data and invalid entries
    echo -e "CORRUPT_PROMO01,\x00\x01\xFF%,invalid_date,\x80\x81" >> "$corrupt_promo_path1"
    echo -e "CORRUPT_PROMO02,\x00\x00%,\x00\x00,\x00\x00" >> "$corrupt_promo_path1"
    echo "CORRUPT_PROMO03,999999%,2024-99-99,2024-13-45" >> "$corrupt_promo_path1"
    echo -e "${GREEN}    Generated: $corrupt_promo1 (contains corrupted data)${NC}"
    
    timestamp5=$(printf "%02d%02d%02d" $((11 + RANDOM % 2)) $((RANDOM % 60)) $((RANDOM % 60)))
    truncated_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp5}_TRUNCATED.csv"
    truncated_promo_path="$CORRUPT_DIR/$truncated_promo"
    
    # Create truncated promotion file
    cat > "$truncated_promo_path" << EOF
promotion_id,discount,start_date,end_date
PROMO001,15%,$INPUT_DATE,$end_date
PROMO002,20%,$INPUT_DATE,$end_date
PROMO003,25%,$INPUT_DATE
EOF
    # Last line intentionally incomplete
    echo -e "${GREEN}    Generated: $truncated_promo (truncated data)${NC}"
    
    # 5. Generate files with permission issues (simulate unreadable)
    echo -e "${YELLOW}  5. Creating files with access issues...${NC}"
    
    timestamp6=$(printf "%02d%02d%02d" $((12 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    permission_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp6}.csv"
    permission_promo_path="$CORRUPT_DIR/$permission_promo"
    
    # Create file and then remove read permissions (simulate permission issues)
    cat > "$permission_promo_path" << EOF
promotion_id,discount,start_date,end_date
PERM_PROMO01,25%,$INPUT_DATE,$end_date
PERM_PROMO02,30%,$INPUT_DATE,$end_date
EOF
    
    # Note: We won't actually remove permissions as it might cause issues
    # This file represents a scenario where permissions would prevent reading
    echo -e "${GREEN}    Generated: $permission_promo (simulated permission issues)${NC}"
    
    echo -e "${GREEN}✅ Promotion files with corruption issues generated${NC}"
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
# FUNCTION: Upload corrupt files to Docker SFTP Container
# =============================================================================
upload_corrupt_files_to_docker() {
    echo -e "${BLUE}🚀 Uploading corrupt files to Docker SFTP Container...${NC}"
    
    # Upload corrupted Price Files
    echo -e "${YELLOW}📤 Uploading corrupted Price files...${NC}"
    for file in $CORRUPT_DIR/TH_PRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload corrupted Promotion Files
    echo -e "${YELLOW}📤 Uploading corrupted Promotion files...${NC}"
    for file in $CORRUPT_DIR/TH_PROMPRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ All corrupt files uploaded to Docker container${NC}"
    
    # Fix ownership
    fix_ownership

    # Execute complete transfer pipeline (1P → SOA → RPM)
    execute_complete_transfer_pipeline
}

# =============================================================================
# FUNCTION: Transfer some corrupt files through pipeline (for testing)
# =============================================================================
transfer_corrupt_files() {
    echo -e "${BLUE}🚚 Transferring some corrupt files through pipeline for testing...${NC}"
    
    # Transfer some corrupt files to SOA (simulate partial transfer)
    echo -e "${YELLOW}🔄 Syncing some corrupt files to SOA...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        
        # Transfer only some corrupt files to SOA (not all, to test missing scenarios)
        count=0
        for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.csv $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*_UNREADABLE.csv; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                cp \"\$f\" $SFTP_SOA_PRICE/
                echo '  Transferred corrupt price file: '\$base
                count=\$((count + 1))
                # Only transfer a few corrupt files
                if [ \$count -ge 2 ]; then break; fi
            fi
        done
        
        count=0
        for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.csv $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*_UNREADABLE.csv; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                cp \"\$f\" $SFTP_SOA_PROMOTION/
                echo '  Transferred corrupt promotion file: '\$base
                count=\$((count + 1))
                # Only transfer a few corrupt files
                if [ \$count -ge 2 ]; then break; fi
            fi
        done
    " || true

    echo -e "${GREEN}✅ Some corrupt files transferred to SOA for testing${NC}"
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
main_corrupt_files() {
    echo -e "${BLUE}🏁 Starting corrupt files generation process...${NC}"
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
    
    # Generate files with corruption issues
    generate_corrupt_price_files
    generate_corrupt_promotion_files
    
    # Upload corrupt files to Docker
    upload_corrupt_files_to_docker
    
    # Transfer some corrupt files through the pipeline for testing
    transfer_corrupt_files
    
    echo -e "${GREEN}🎉 Corrupt files generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing corruption detection${NC}"
    echo -e "${BLUE}📋 Local data stored in: $CORRUPT_DIR/${NC}"
    echo -e "${BLUE}🔍 Corruption scenarios created:${NC}"
    echo -e "${BLUE}  • Zero-size files (0 bytes)${NC}"
    echo -e "${BLUE}  • Files too small (< minimum size)${NC}"
    echo -e "${BLUE}  • Files too large (> maximum size)${NC}"
    echo -e "${BLUE}  • Unreadable/corrupted files${NC}"
    echo -e "${BLUE}  • Files with encoding issues${NC}"
    echo -e "${BLUE}  • Truncated/incomplete files${NC}"
}

# Run main function if not sourced
main_corrupt_files "$@"

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
