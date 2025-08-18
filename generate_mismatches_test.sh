#!/bin/bash

# =============================================================================
# MISMATCH FILES GENERATOR FOR TESTING MISMATCH DETECTION
# =============================================================================
#
# This script generates file mismatch scenarios to test the
# detect_mismatches function in data processing pipelines
#
# USAGE:
#   ./generate_mismatches_test.sh [YYYY-MM-DD] [--clean]
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

# Create mismatches directory
MISMATCHES_DIR="$BASE_DIR/$DATE_DIR_FORMAT/mismatches"
mkdir -p "$MISMATCHES_DIR"

echo -e "${BLUE}=== MISMATCH FILES GENERATOR FOR TESTING ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating file mismatch scenarios for testing mismatch detection${NC}"

# =============================================================================
# FUNCTION: Generate Files for Size Mismatch Testing
# =============================================================================
generate_size_mismatch_files() {
    echo -e "${RED}📏 Generating Files for Size Mismatch Testing...${NC}"
    
    # 1. Generate price files with different sizes (1P vs SOA)
    echo -e "${YELLOW}  1. Creating price files with size mismatches...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    size_mismatch_price1_1p="TH_PRCH_${DATE_PATTERN}${timestamp1}.csv"
    size_mismatch_price1_soa="TH_PRCH_${DATE_PATTERN}${timestamp1}.csv"
    
    # Create 1P version (smaller)
    cat > "$MISMATCHES_DIR/$size_mismatch_price1_1p" << EOF
item_id,price,start_date,end_date
SIZE001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
SIZE002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    
    # Create SOA version (larger - same content but with additional rows)
    cat > "$MISMATCHES_DIR/${size_mismatch_price1_soa}.soa" << EOF
item_id,price,start_date,end_date
SIZE001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
SIZE002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
SIZE003,399.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
SIZE004,499.25,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
SIZE005,599.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $size_mismatch_price1_1p (1P: $(stat -c%s "$MISMATCHES_DIR/$size_mismatch_price1_1p") bytes, SOA: $(stat -c%s "$MISMATCHES_DIR/${size_mismatch_price1_soa}.soa") bytes)${NC}"
    
    # Create another size mismatch pair
    timestamp2=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    size_mismatch_price2_1p="TH_PRCH_${DATE_PATTERN}${timestamp2}.csv"
    size_mismatch_price2_soa="TH_PRCH_${DATE_PATTERN}${timestamp2}.csv"
    
    # Create 1P version (larger with extra data)
    cat > "$MISMATCHES_DIR/$size_mismatch_price2_1p" << EOF
item_id,price,start_date,end_date,extra_column
BIG001,699.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),EXTRA_DATA_TO_MAKE_FILE_LARGER
BIG002,799.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),MORE_EXTRA_DATA_FOR_SIZE_DIFFERENCE
BIG003,899.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),ADDITIONAL_PADDING_DATA
BIG004,999.25,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),EVEN_MORE_PADDING_DATA_HERE
EOF
    
    # Create SOA version (smaller - less data)
    cat > "$MISMATCHES_DIR/${size_mismatch_price2_soa}.soa" << EOF
item_id,price,start_date,end_date
BIG001,699.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
BIG002,799.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $size_mismatch_price2_1p (1P: $(stat -c%s "$MISMATCHES_DIR/$size_mismatch_price2_1p") bytes, SOA: $(stat -c%s "$MISMATCHES_DIR/${size_mismatch_price2_soa}.soa") bytes)${NC}"
    
    # 2. Generate promotion files with size mismatches
    echo -e "${YELLOW}  2. Creating promotion files with size mismatches...${NC}"
    
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
    size_mismatch_promo1_1p="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}.csv"
    size_mismatch_promo1_soa="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}.csv"
    
    # Create 1P version (smaller)
    cat > "$MISMATCHES_DIR/$size_mismatch_promo1_1p" << EOF
promotion_id,discount,start_date,end_date
SIZE_PROMO001,25%,$INPUT_DATE,$end_date
SIZE_PROMO002,30%,$INPUT_DATE,$end_date
EOF
    
    # Create SOA version (larger - with additional promotions)
    cat > "$MISMATCHES_DIR/${size_mismatch_promo1_soa}.soa" << EOF
promotion_id,discount,start_date,end_date
SIZE_PROMO001,25%,$INPUT_DATE,$end_date
SIZE_PROMO002,30%,$INPUT_DATE,$end_date
SIZE_PROMO003,35%,$INPUT_DATE,$end_date
SIZE_PROMO004,40%,$INPUT_DATE,$end_date
SIZE_PROMO005,45%,$INPUT_DATE,$end_date
SIZE_PROMO006,50%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $size_mismatch_promo1_1p (1P: $(stat -c%s "$MISMATCHES_DIR/$size_mismatch_promo1_1p") bytes, SOA: $(stat -c%s "$MISMATCHES_DIR/${size_mismatch_promo1_soa}.soa") bytes)${NC}"
    
    echo -e "${GREEN}✅ Size mismatch files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Files for Time Mismatch Testing (>5 minutes difference)
# =============================================================================
generate_time_mismatch_files() {
    echo -e "${RED}🕐 Generating Files for Time Mismatch Testing...${NC}"
    
    # 1. Generate price files with time mismatches
    echo -e "${YELLOW}  1. Creating price files with time mismatches...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((8 + RANDOM % 5)) $((RANDOM % 60)) $((RANDOM % 60)))
    time_mismatch_price1="TH_PRCH_${DATE_PATTERN}${timestamp1}.csv"
    
    # Create file with same content for both 1P and SOA
    cat > "$MISMATCHES_DIR/$time_mismatch_price1" << EOF
item_id,price,start_date,end_date
TIME001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
TIME002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
TIME003,399.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    
    # Create SOA version (same content but will have different timestamp when uploaded)
    cp "$MISMATCHES_DIR/$time_mismatch_price1" "$MISMATCHES_DIR/${time_mismatch_price1}.soa"
    
    echo -e "${GREEN}    Generated: $time_mismatch_price1 (will have different modification times)${NC}"
    
    # Create another time mismatch file
    timestamp2=$(printf "%02d%02d%02d" $((9 + RANDOM % 4)) $((RANDOM % 60)) $((RANDOM % 60)))
    time_mismatch_price2="TH_PRCH_${DATE_PATTERN}${timestamp2}.csv"
    
    cat > "$MISMATCHES_DIR/$time_mismatch_price2" << EOF
item_id,price,start_date,end_date
TIME010,599.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
TIME011,699.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
TIME012,799.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
TIME013,899.25,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
TIME014,999.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    
    # Create SOA version
    cp "$MISMATCHES_DIR/$time_mismatch_price2" "$MISMATCHES_DIR/${time_mismatch_price2}.soa"
    echo -e "${GREEN}    Generated: $time_mismatch_price2 (will have different modification times)${NC}"
    
    # 2. Generate promotion files with time mismatches
    echo -e "${YELLOW}  2. Creating promotion files with time mismatches...${NC}"
    
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    timestamp3=$(printf "%02d%02d%02d" $((10 + RANDOM % 3)) $((RANDOM % 60)) $((RANDOM % 60)))
    time_mismatch_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}.csv"
    
    cat > "$MISMATCHES_DIR/$time_mismatch_promo1" << EOF
promotion_id,discount,start_date,end_date
TIME_PROMO001,15%,$INPUT_DATE,$end_date
TIME_PROMO002,20%,$INPUT_DATE,$end_date
TIME_PROMO003,25%,$INPUT_DATE,$end_date
TIME_PROMO004,30%,$INPUT_DATE,$end_date
EOF
    
    # Create SOA version
    cp "$MISMATCHES_DIR/$time_mismatch_promo1" "$MISMATCHES_DIR/${time_mismatch_promo1}.soa"
    echo -e "${GREEN}    Generated: $time_mismatch_promo1 (will have different modification times)${NC}"
    
    echo -e "${GREEN}✅ Time mismatch files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Files Missing from SOA (exist in 1P only)
# =============================================================================
generate_files_missing_from_soa() {
    echo -e "${RED}❌ Generating Files Missing from SOA...${NC}"
    
    # 1. Generate price files that exist in 1P but missing from SOA
    echo -e "${YELLOW}  1. Creating price files missing from SOA...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((11 + RANDOM % 2)) $((RANDOM % 60)) $((RANDOM % 60)))
    missing_soa_price1="TH_PRCH_${DATE_PATTERN}${timestamp1}_MISSING_FROM_SOA.csv"
    
    cat > "$MISMATCHES_DIR/$missing_soa_price1" << EOF
item_id,price,start_date,end_date
MISS_SOA001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
MISS_SOA002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
MISS_SOA003,399.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
MISS_SOA004,499.25,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $missing_soa_price1 (will exist in 1P only)${NC}"
    
    timestamp2=$(printf "%02d%02d%02d" $((12 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    missing_soa_price2="TH_PRCH_${DATE_PATTERN}${timestamp2}_MISSING_FROM_SOA.csv"
    
    cat > "$MISMATCHES_DIR/$missing_soa_price2" << EOF
item_id,price,start_date,end_date
MISS_SOA010,599.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
MISS_SOA011,699.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
MISS_SOA012,799.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $missing_soa_price2 (will exist in 1P only)${NC}"
    
    # 2. Generate promotion files that exist in 1P but missing from SOA
    echo -e "${YELLOW}  2. Creating promotion files missing from SOA...${NC}"
    
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    timestamp3=$(printf "%02d%02d%02d" $((13 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    missing_soa_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp3}_MISSING_FROM_SOA.csv"
    
    cat > "$MISMATCHES_DIR/$missing_soa_promo1" << EOF
promotion_id,discount,start_date,end_date
MISS_SOA_PROMO001,35%,$INPUT_DATE,$end_date
MISS_SOA_PROMO002,40%,$INPUT_DATE,$end_date
MISS_SOA_PROMO003,45%,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $missing_soa_promo1 (will exist in 1P only)${NC}"
    
    echo -e "${GREEN}✅ Files missing from SOA generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Files Missing from RPM (exist in 1P & SOA, missing from RPM)
# =============================================================================
generate_files_missing_from_rpm() {
    echo -e "${RED}❌ Generating Files Missing from RPM...${NC}"
    
    # 1. Generate price files that exist in 1P & SOA but missing from RPM
    echo -e "${YELLOW}  1. Creating price files missing from RPM...${NC}"
    
    timestamp1=$(printf "%02d%02d%02d" $((14 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    missing_rpm_price1="TH_PRCH_${DATE_PATTERN}${timestamp1}_MISSING_FROM_RPM.csv"
    
    cat > "$MISMATCHES_DIR/$missing_rpm_price1" << EOF
item_id,price,start_date,end_date
MISS_RPM001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
MISS_RPM002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
MISS_RPM003,399.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    
    # Create SOA version (same content)
    cp "$MISMATCHES_DIR/$missing_rpm_price1" "$MISMATCHES_DIR/${missing_rpm_price1}.soa"
    echo -e "${GREEN}    Generated: $missing_rpm_price1 (will exist in 1P & SOA, missing from RPM)${NC}"
    
    # 2. Generate promotion files that exist in 1P & SOA but missing from RPM
    echo -e "${YELLOW}  2. Creating promotion files missing from RPM...${NC}"
    
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    timestamp2=$(printf "%02d%02d%02d" $((15 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    missing_rpm_promo1="TH_PROMPRCH_${DATE_PATTERN}${timestamp2}_MISSING_FROM_RPM.csv"
    
    cat > "$MISMATCHES_DIR/$missing_rpm_promo1" << EOF
promotion_id,discount,start_date,end_date
MISS_RPM_PROMO001,25%,$INPUT_DATE,$end_date
MISS_RPM_PROMO002,30%,$INPUT_DATE,$end_date
EOF
    
    # Create SOA version (same content)
    cp "$MISMATCHES_DIR/$missing_rpm_promo1" "$MISMATCHES_DIR/${missing_rpm_promo1}.soa"
    echo -e "${GREEN}    Generated: $missing_rpm_promo1 (will exist in 1P & SOA, missing from RPM)${NC}"
    
    echo -e "${GREEN}✅ Files missing from RPM generated${NC}"
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
# FUNCTION: Upload files to create mismatch scenarios
# =============================================================================
upload_mismatch_files() {
    echo -e "${BLUE}🚀 Uploading files to create mismatch scenarios...${NC}"
    
    # 1. Upload size mismatch files
    echo -e "${YELLOW}📤 Uploading size mismatch files...${NC}"
    
    # Upload size mismatch files to 1P
    for file in $MISMATCHES_DIR/TH_PRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to 1P: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    for file in $MISMATCHES_DIR/TH_PROMPRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to 1P: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload size mismatch SOA versions (different sizes)
    for file in $MISMATCHES_DIR/*.soa; do
        if [ -f "$file" ]; then
            base_name=$(basename "$file" .soa)
            if [[ "$base_name" == *"PRCH"* ]]; then
                target_dir="$SFTP_SOA_PRICE"
            else
                target_dir="$SFTP_SOA_PROMOTION"
            fi
            
            if docker cp "$file" $DOCKER_CONTAINER:$target_dir/$base_name >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to SOA: $base_name (different size)${NC}"
            else
                echo -e "${RED}  Failed to upload: $base_name${NC}"
            fi
        fi
    done
    
    # 2. Upload time mismatch files (with intentional delay)
    echo -e "${YELLOW}📤 Uploading time mismatch files with delays...${NC}"
    
    # Upload to 1P first
    for file in $MISMATCHES_DIR/TH_PRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to 1P: $(basename "$file")${NC}"
            fi
        fi
    done
    
    for file in $MISMATCHES_DIR/TH_PROMPRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to 1P: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Wait to create time difference (simulate time mismatch >5 minutes)
    echo -e "${YELLOW}⏳ Waiting 2 seconds to create time difference...${NC}"
    sleep 2
    
    # Now upload to SOA (different timestamps)
    for file in $MISMATCHES_DIR/TH_PRCH_${DATE_PATTERN}*.csv.soa; do
        if [ -f "$file" ]; then
            base_name=$(basename "$file" .soa)
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_SOA_PRICE/$base_name >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to SOA: $base_name (different timestamp)${NC}"
            fi
        fi
    done
    
    for file in $MISMATCHES_DIR/TH_PROMPRCH_${DATE_PATTERN}*.csv.soa; do
        if [ -f "$file" ]; then
            base_name=$(basename "$file" .soa)
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_SOA_PROMOTION/$base_name >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to SOA: $base_name (different timestamp)${NC}"
            fi
        fi
    done
    
    # 3. Upload files missing from SOA (1P only)
    echo -e "${YELLOW}📤 Uploading files missing from SOA (1P only)...${NC}"
    for file in $MISMATCHES_DIR/TH_PRCH_${DATE_PATTERN}*_MISSING_FROM_SOA.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to 1P only: $(basename "$file")${NC}"
            fi
        fi
    done
    
    for file in $MISMATCHES_DIR/TH_PROMPRCH_${DATE_PATTERN}*_MISSING_FROM_SOA.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to 1P only: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # 4. Upload files missing from RPM (1P & SOA, but not RPM)
    echo -e "${YELLOW}📤 Uploading files missing from RPM (1P & SOA only)...${NC}"
    for file in $MISMATCHES_DIR/TH_PRCH_${DATE_PATTERN}*_MISSING_FROM_RPM.csv; do
        if [ -f "$file" ]; then
            # Upload to 1P
            docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1
            echo -e "${GREEN}  Uploaded to 1P: $(basename "$file")${NC}"
        fi
    done
    
    # Upload SOA versions for RPM missing files
    for file in $MISMATCHES_DIR/TH_PRCH_${DATE_PATTERN}*_MISSING_FROM_RPM.csv.soa; do
        if [ -f "$file" ]; then
            base_name=$(basename "$file" .soa)
            docker cp "$file" $DOCKER_CONTAINER:$SFTP_SOA_PRICE/$base_name >/dev/null 2>&1
            echo -e "${GREEN}  Uploaded to SOA: $base_name${NC}"
        fi
    done
    
    for file in $MISMATCHES_DIR/TH_PROMPRCH_${DATE_PATTERN}*_MISSING_FROM_RPM.csv; do
        if [ -f "$file" ]; then
            # Upload to 1P
            docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1
            echo -e "${GREEN}  Uploaded to 1P: $(basename "$file")${NC}"
        fi
    done
    
    # Upload SOA versions for promotion RPM missing files
    for file in $MISMATCHES_DIR/TH_PROMPRCH_${DATE_PATTERN}*_MISSING_FROM_RPM.csv.soa; do
        if [ -f "$file" ]; then
            base_name=$(basename "$file" .soa)
            docker cp "$file" $DOCKER_CONTAINER:$SFTP_SOA_PROMOTION/$base_name >/dev/null 2>&1
            echo -e "${GREEN}  Uploaded to SOA: $base_name${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ All mismatch scenario files uploaded${NC}"
    
    # Fix ownership
    fix_ownership

    # Execute complete transfer pipeline (1P → SOA → RPM)
    execute_complete_transfer_pipeline
}

# =============================================================================
# FUNCTION: Create additional mismatch scenarios
# =============================================================================
create_additional_mismatch_scenarios() {
    echo -e "${BLUE}🔄 Creating additional mismatch scenarios...${NC}"
    
    # Upload some files to RPM (processed and pending) to create baseline for comparison
    echo -e "${YELLOW}📋 Creating baseline files in RPM for mismatch comparison...${NC}"
    
    # Generate some normal files that exist in all stages for comparison
    timestamp1=$(printf "%02d%02d%02d" $((16 + RANDOM % 1)) $((RANDOM % 60)) $((RANDOM % 60)))
    baseline_price="TH_PRCH_${DATE_PATTERN}${timestamp1}_BASELINE_FOR.csv"
    baseline_price_path="$MISMATCHES_DIR/$baseline_price"
    
    cat > "$baseline_price_path" << EOF
item_id,price,start_date,end_date
BASELINE001,199.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
BASELINE002,299.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
BASELINE003,399.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    
    # Upload baseline file to all stages (1P, SOA, RPM)
    docker cp "$baseline_price_path" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1
    docker cp "$baseline_price_path" $DOCKER_CONTAINER:$SFTP_SOA_PRICE/ >/dev/null 2>&1
    docker cp "$baseline_price_path" $DOCKER_CONTAINER:$SFTP_RPM_PROCESSED/ >/dev/null 2>&1
    echo -e "${GREEN}  Created baseline file: $baseline_price (exists in 1P, SOA, and RPM)${NC}"
    
    echo -e "${GREEN}✅ Additional mismatch scenarios created${NC}"
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
main_mismatch_files() {
    echo -e "${BLUE}🏁 Starting mismatch files generation process...${NC}"
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
    
    # Generate different types of mismatch scenarios
    generate_size_mismatch_files
    generate_time_mismatch_files
    generate_files_missing_from_soa
    generate_files_missing_from_rpm
    
    # Upload files to create mismatch scenarios
    upload_mismatch_files
    
    # Create additional mismatch scenarios
    create_additional_mismatch_scenarios
    
    echo -e "${GREEN}🎉 Mismatch files generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing mismatch detection${NC}"
    echo -e "${BLUE}📋 Local data stored in: $MISMATCHES_DIR/${NC}"
    echo -e "${BLUE}🔍 Mismatch scenarios created:${NC}"
    echo -e "${BLUE}  • Size mismatches (1P vs SOA different file sizes)${NC}"
    echo -e "${BLUE}  • Time mismatches (>5 minutes timestamp difference)${NC}"
    echo -e "${BLUE}  • Files missing from SOA (exist in 1P only)${NC}"
    echo -e "${BLUE}  • Files missing from RPM (exist in 1P & SOA only)${NC}"
    echo -e "${BLUE}  • Baseline files (exist in all stages for comparison)${NC}"
}

# Run main function if not sourced
main_mismatch_files "$@"

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
