#!/bin/bash

# =============================================================================
# INVALID FILE GENERATOR FOR TESTING VALIDATION FAILURES
# =============================================================================
#
# This script generates various types of invalid files to test the
# validate_file_format function in data processing pipelines
#
# USAGE:
#   ./generate_invalid_files.sh [YYYY-MM-DD] [--clean]
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

# Create invalid files directory
INVALID_DIR="$BASE_DIR/$DATE_DIR_FORMAT/invalid_files"
mkdir -p "$INVALID_DIR"

echo -e "${BLUE}=== INVALID FILE GENERATOR FOR TESTING ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating invalid files for testing validation failures${NC}"

# =============================================================================
# FUNCTION: Generate Invalid Price Files
# =============================================================================
generate_invalid_price_files() {
    echo -e "${RED}🛑 Generating Invalid Price Files...${NC}"
    
    # 1. Wrong File Extension (Not .ods or .csv)
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PRCH_${DATE_PATTERN}${timestamp}.txt"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
Price,Item,Store,Date,Batch
$RANDOM.50,ITEM00001,STORE01,$INPUT_DATE,$timestamp
$RANDOM.75,ITEM00002,STORE01,$INPUT_DATE,$timestamp
$RANDOM.99,ITEM00003,STORE02,$INPUT_DATE,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Wrong File Extension - .txt)${NC}"
    
    # 2. Missing Header File
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PRCH_${DATE_PATTERN}${timestamp}_NO_HEADER.ods"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
$RANDOM.50,ITEM00001,STORE01,$INPUT_DATE,$timestamp
$RANDOM.75,ITEM00002,STORE01,$INPUT_DATE,$timestamp
$RANDOM.99,ITEM00003,STORE02,$INPUT_DATE,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Missing Header)${NC}"
    
    # 2. Missing Required Column
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PRCH_${DATE_PATTERN}${timestamp}_MISSING_COLUMN.ods"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
Price,Item,Date,Batch
$RANDOM.50,ITEM00001,$INPUT_DATE,$timestamp
$RANDOM.75,ITEM00002,$INPUT_DATE,$timestamp
$RANDOM.99,ITEM00003,$INPUT_DATE,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Missing Store Column)${NC}"
    
    # 3. Invalid Data Type
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PRCH_${DATE_PATTERN}${timestamp}_INVALID_DATATYPE.ods"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
Price,Item,Store,Date,Batch
NOT_A_NUMBER,ITEM00001,STORE01,$INPUT_DATE,$timestamp
$RANDOM.75,ITEM00002,STORE01,$INPUT_DATE,$timestamp
$RANDOM.99,ITEM00003,STORE02,$INPUT_DATE,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Invalid Price Data Type)${NC}"
    
    # 4. Wrong Filename Format (Incorrect prefix)
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="WRONG_PREFIX_${DATE_PATTERN}${timestamp}.ods"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
Price,Item,Store,Date,Batch
$RANDOM.50,ITEM00001,STORE01,$INPUT_DATE,$timestamp
$RANDOM.75,ITEM00002,STORE01,$INPUT_DATE,$timestamp
$RANDOM.99,ITEM00003,STORE02,$INPUT_DATE,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Wrong Prefix - should be TH_PRCH)${NC}"
    
    # 5. Invalid Date Format in Content
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PRCH_${DATE_PATTERN}${timestamp}_INVALID_DATE.ods"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
Price,Item,Store,Date,Batch
$RANDOM.50,ITEM00001,STORE01,31/12/2025,$timestamp
$RANDOM.75,ITEM00002,STORE01,31/12/2025,$timestamp
$RANDOM.99,ITEM00003,STORE02,31/12/2025,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Invalid Date Format in Content)${NC}"
    
    # 6. Empty File
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PRCH_${DATE_PATTERN}${timestamp}_EMPTY.ods"
    file_path="$INVALID_DIR/$file_name"
    
    # Create empty file
    touch "$file_path"
    echo -e "${YELLOW}  Generated: $file_name (Empty File)${NC}"
    
    # 7. Oversized File (generating a file > 100MB if max_file_size_mb=100)
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PRCH_${DATE_PATTERN}${timestamp}_OVERSIZE.ods"
    file_path="$INVALID_DIR/$file_name"
    
    # Generate header
    echo "Price,Item,Store,Date,Batch" > "$file_path"
    
    # Create a 5MB file with repeated content for testing
    # Generating truly large file would be slow and wasteful, so this is just a simulation
    echo -e "${YELLOW}  Generating oversized file (may take a moment)...${NC}"
    for i in {1..50000}; do
        echo "$i.50,ITEM$i,STORE01,$INPUT_DATE,$timestamp" >> "$file_path"
    done
    
    # Add attribute to fake larger size for testing
    touch -a -m -t $(date +%Y%m%d%H%M.%S) "$file_path"
    echo -e "${YELLOW}  Generated: $file_name (Simulated Oversized File)${NC}"
    
    # 8. Binary/Corrupted File
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PRCH_${DATE_PATTERN}${timestamp}_BINARY.ods"
    file_path="$INVALID_DIR/$file_name"
    
    # Create binary/corrupted file
    head -c 1024 /dev/urandom > "$file_path"
    echo -e "${YELLOW}  Generated: $file_name (Binary/Corrupted File)${NC}"
    
    echo -e "${GREEN}✅ Invalid Price files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Invalid Promotion Files
# =============================================================================
generate_invalid_promotion_files() {
    echo -e "${RED}🛑 Generating Invalid Promotion Files (.ods)...${NC}"
    
    discounts=("5%" "10%" "15%" "20%" "25%" "30%" "35%" "40%" "50%")
    
    # 1. Missing Header File
    timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}_NO_HEADER.ods"
    file_path="$INVALID_DIR/$file_name"
    
    promo1="PROMO00001"
    promo2="PROMO00002"
    discount1=${discounts[$((RANDOM % ${#discounts[@]}))]}
    discount2=${discounts[$((RANDOM % ${#discounts[@]}))]}
    
    # Generate random end date (7-30 days from start date)
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    cat > "$file_path" << EOF
$promo1,ITEM00001,$discount1,$INPUT_DATE,$end_date,$timestamp
$promo2,ITEM00002,$discount2,$INPUT_DATE,$end_date,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Missing Header)${NC}"
    
    # 2. Missing Required Column
    timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}_MISSING_COLUMN.ods"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
PromoID,Item,Discount,EndDate,Batch
$promo1,ITEM00001,$discount1,$end_date,$timestamp
$promo2,ITEM00002,$discount2,$end_date,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Missing StartDate Column)${NC}"
    
    # 3. Invalid Discount Format
    timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}_INVALID_DISCOUNT.ods"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
PromoID,Item,Discount,StartDate,EndDate,Batch
$promo1,ITEM00001,INVALID_DISCOUNT,$INPUT_DATE,$end_date,$timestamp
$promo2,ITEM00002,$discount2,$INPUT_DATE,$end_date,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Invalid Discount Format)${NC}"
    
    # 4. EndDate Before StartDate
    timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}_INVALID_DATES.ods"
    file_path="$INVALID_DIR/$file_name"
    
    # Generate date before input date
    days_before=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        before_date=$(date -j -v-${days_before}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        before_date=$(date -d "$INPUT_DATE - $days_before days" +%Y-%m-%d)
    fi
    
    cat > "$file_path" << EOF
PromoID,Item,Discount,StartDate,EndDate,Batch
$promo1,ITEM00001,$discount1,$INPUT_DATE,$before_date,$timestamp
$promo2,ITEM00002,$discount2,$INPUT_DATE,$end_date,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (EndDate Before StartDate)${NC}"
    
    # 5. Wrong Filename Format
    timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="WRONG_PREFIX_PROMO_${DATE_PATTERN}${timestamp}.ods"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
PromoID,Item,Discount,StartDate,EndDate,Batch
$promo1,ITEM00001,$discount1,$INPUT_DATE,$end_date,$timestamp
$promo2,ITEM00002,$discount2,$INPUT_DATE,$end_date,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Wrong Prefix - should be TH_PROMPRCH)${NC}"
    
    # Adding wrong file extension case
    timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.doc"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
PromoID,Item,Discount,StartDate,EndDate,Batch
$promo1,ITEM00001,$discount1,$INPUT_DATE,$end_date,$timestamp
$promo2,ITEM00002,$discount2,$INPUT_DATE,$end_date,$timestamp
EOF
    echo -e "${YELLOW}  Generated: $file_name (Wrong File Extension - .doc)${NC}"
    
    # 6. Corrupted File Format (Binary Corruption Simulation)
    timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}_CORRUPTED.ods"
    file_path="$INVALID_DIR/$file_name"
    
    # Create valid content first
    cat > "$file_path" << EOF
PromoID,Item,Discount,StartDate,EndDate,Batch
$promo1,ITEM00001,$discount1,$INPUT_DATE,$end_date,$timestamp
$promo2,ITEM00002,$discount2,$INPUT_DATE,$end_date,$timestamp
EOF
    
    # Append some random binary data to simulate corruption
    dd if=/dev/urandom bs=512 count=1 >> "$file_path" 2>/dev/null
    echo -e "${YELLOW}  Generated: $file_name (Corrupted File Format)${NC}"
    
    echo -e "${GREEN}✅ Invalid Promotion files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Invalid Feedback Files
# =============================================================================
generate_invalid_feedback_files() {
    echo -e "${RED}🛑 Generating Invalid Feedback Files (.csv)...${NC}"
    
    # 1. Missing Header in Feedback Price File
    hour=$((5 + RANDOM % 8))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    
    time_str=$(printf "%02d%02d%02d" $hour $minute $second)
    file_name="CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}_NO_HEADER.csv"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
FB00001,SUCCESS,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $second)
FB00002,FAILED,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+15)))
FB00003,SUCCESS,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+30)))
EOF
    echo -e "${YELLOW}  Generated: $file_name (Missing Header)${NC}"
    
    # 2. Invalid Status Value
    hour=$((5 + RANDOM % 8))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    
    time_str=$(printf "%02d%02d%02d" $hour $minute $second)
    file_name="CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}_INVALID_STATUS.csv"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
feedback_id,status,processed_time
FB00001,UNKNOWN_STATUS,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $second)
FB00002,FAILED,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+15)))
FB00003,SUCCESS,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+30)))
EOF
    echo -e "${YELLOW}  Generated: $file_name (Invalid Status Value)${NC}"
    
    # 3. Invalid Date Format in Feedback
    hour=$((5 + RANDOM % 8))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    
    time_str=$(printf "%02d%02d%02d" $hour $minute $second)
    file_name="CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}_INVALID_DATE.csv"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
feedback_id,status,processed_time
FB00001,SUCCESS,31/12/2025 $(printf "%02d:%02d:%02d" $hour $minute $second)
FB00002,FAILED,31/12/2025 $(printf "%02d:%02d:%02d" $hour $minute $((second+15)))
FB00003,SUCCESS,31/12/2025 $(printf "%02d:%02d:%02d" $hour $minute $((second+30)))
EOF
    echo -e "${YELLOW}  Generated: $file_name (Invalid Date Format)${NC}"
    
    # 4. Mismatched Columns (Too Few)
    hour=$((6 + RANDOM % 7))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    
    time_str=$(printf "%02d%02d%02d" $hour $minute $second)
    file_name="CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}_MISMATCHED_COLUMNS.csv"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
feedback_id,status
FBP00001,SUCCESS
FBP00002,FAILED
FBP00003,SUCCESS
EOF
    echo -e "${YELLOW}  Generated: $file_name (Mismatched Columns)${NC}"
    
    # 5. Extra Invalid Columns (Too Many)
    hour=$((6 + RANDOM % 7))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    
    time_str=$(printf "%02d%02d%02d" $hour $minute $second)
    file_name="CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}_EXTRA_COLUMNS.csv"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
feedback_id,status,processed_time,extra_column1,extra_column2
FBP00001,SUCCESS,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $second),extra1,extra2
FBP00002,FAILED,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+15))),extra3,extra4
FBP00003,SUCCESS,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+30))),extra5,extra6
EOF
    echo -e "${YELLOW}  Generated: $file_name (Extra Invalid Columns)${NC}"
    
    # 6. Wrong File Extension
    hour=$((6 + RANDOM % 7))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    
    time_str=$(printf "%02d%02d%02d" $hour $minute $second)
    file_name="CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}_WRONG_EXT.txt"
    file_path="$INVALID_DIR/$file_name"
    
    cat > "$file_path" << EOF
feedback_id,status,processed_time
FBP00001,SUCCESS,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $second)
FBP00002,FAILED,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+15)))
FBP00003,SUCCESS,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+30)))
EOF
    echo -e "${YELLOW}  Generated: $file_name (Wrong File Extension)${NC}"
    
    echo -e "${GREEN}✅ Invalid Feedback files generated${NC}"
}

# =============================================================================
# FUNCTION: Clean Docker container directories
# =============================================================================
clean_docker_directories() {
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
# FUNCTION: Upload invalid files to Docker SFTP Container
# =============================================================================
upload_invalid_files_to_docker() {
    echo -e "${BLUE}🚀 Uploading invalid files to Docker SFTP Container...${NC}"
    
    # Create special directories for invalid files in Docker container
    local docker_dirs=(
        "$SFTP_1P_PRICE/invalid"
        "$SFTP_1P_PROMOTION/invalid"
        "${SFTP_1P_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE}/invalid"
        "${SFTP_1P_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE}/invalid"
    )
    
    for dir in "${docker_dirs[@]}"; do
        # Check if directory exists in Docker container
        if ! docker exec $DOCKER_CONTAINER test -d "$dir" 2>/dev/null; then
            echo -e "${YELLOW}  Creating Docker invalid dir: $dir${NC}"
            docker exec $DOCKER_CONTAINER mkdir -p "$dir"
        else
            echo -e "${GREEN}  Docker invalid dir exists: $dir${NC}"
        fi
    done
    
    # Upload Invalid Price Files → 1P/invalid
    echo -e "${YELLOW}📤 Uploading Invalid Price files...${NC}"
    for file in $INVALID_DIR/TH_PRCH_${DATE_PATTERN}*.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/invalid/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Invalid Promotion Files → 1P/invalid
    echo -e "${YELLOW}📤 Uploading Invalid Promotion files...${NC}"
    for file in $INVALID_DIR/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/invalid/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Invalid Feedback Files → 1P/invalid
    echo -e "${YELLOW}📤 Uploading Invalid Feedback files...${NC}"
    for file in $INVALID_DIR/CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:${SFTP_1P_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE}/invalid/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Wrong Prefix/Format Files
    echo -e "${YELLOW}📤 Uploading Wrong Format/Prefix files...${NC}"
    # Upload files with wrong prefix directly to main folders (not /invalid) to test validation
    for file in $INVALID_DIR/WRONG_PREFIX_*.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded wrong prefix file to main directory: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload files with wrong extension directly to main folders
    for file in $INVALID_DIR/TH_PRCH_*.txt $INVALID_DIR/TH_PROMPRCH_*.doc; do
        if [ -f "$file" ]; then
            target_dir=$SFTP_1P_PRICE
            if [[ "$file" == *"PROMPRCH"* ]]; then
                target_dir=$SFTP_1P_PROMOTION
            fi
            
            if docker cp "$file" $DOCKER_CONTAINER:$target_dir/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded wrong extension file to main directory: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done

    echo -e "${GREEN}✅ All invalid files uploaded to Docker container${NC}"
    
    # Fix ownership
    fix_ownership
}

# =============================================================================
# FUNCTION: Transfer Invalid Format Files from 1P → SOA → RPM
# =============================================================================
transfer_invalid_format_files() {
    echo -e "${BLUE}🚚 Transferring files with invalid formats from 1P → SOA → RPM...${NC}"
    
    # Transfer from 1P to SOA
    echo -e "${YELLOW}🔄 Syncing 1P → SOA (files with invalid formats)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        
        # Create directories in SOA
        mkdir -p $SFTP_SOA_PRICE/invalid
        mkdir -p $SFTP_SOA_PROMOTION/invalid
        
        # 1P → SOA price - invalid files
        for f in $SFTP_1P_PRICE/invalid/*.{txt,pdf,doc,xml,json,csv}; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                [ -f $SFTP_SOA_PRICE/invalid/\$base ] || cp \"\$f\" $SFTP_SOA_PRICE/invalid/
                echo '  Transferred: '\$base
            fi
        done
        
        # 1P → SOA promotion - invalid files
        for f in $SFTP_1P_PROMOTION/invalid/*.{txt,pdf,doc,xml,json,csv}; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                [ -f $SFTP_SOA_PROMOTION/invalid/\$base ] || cp \"\$f\" $SFTP_SOA_PROMOTION/invalid/
                echo '  Transferred: '\$base
            fi
        done
        
        # 1P → SOA - wrong extension files in main directories
        for f in $SFTP_1P_PRICE/*.{txt,pdf,doc,xml,json,wrong}; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                [ -f $SFTP_SOA_PRICE/\$base ] || cp \"\$f\" $SFTP_SOA_PRICE/
                echo '  Transferred wrong extension file: '\$base
            fi
        done
        
        for f in $SFTP_1P_PROMOTION/*.{txt,pdf,doc,xml,json,wrong}; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                [ -f $SFTP_SOA_PROMOTION/\$base ] || cp \"\$f\" $SFTP_SOA_PROMOTION/
                echo '  Transferred wrong extension file: '\$base
            fi
        done
    " || true

    # Transfer from SOA to RPM
    echo -e "${YELLOW}📦 Syncing SOA → RPM (files with invalid formats)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        
        # Create directories in RPM
        mkdir -p $SFTP_RPM_PROCESSED/invalid
        mkdir -p $SFTP_RPM_PENDING/invalid
        
        # SOA → RPM - invalid files
        for f in $SFTP_SOA_PRICE/invalid/*.{txt,pdf,doc,xml,json,csv}; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                [ -f $SFTP_RPM_PROCESSED/invalid/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/invalid/
                echo '  Transferred: '\$base
            fi
        done
        
        for f in $SFTP_SOA_PROMOTION/invalid/*.{txt,pdf,doc,xml,json,csv}; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                [ -f $SFTP_RPM_PROCESSED/invalid/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/invalid/
                echo '  Transferred: '\$base
            fi
        done
        
        # SOA → RPM - wrong extension files
        for f in $SFTP_SOA_PRICE/*.{txt,pdf,doc,xml,json,wrong}; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                [ -f $SFTP_RPM_PROCESSED/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/
                echo '  Transferred wrong extension file: '\$base
            fi
        done
        
        for f in $SFTP_SOA_PROMOTION/*.{txt,pdf,doc,xml,json,wrong}; do
            if [ -f \"\$f\" ]; then
                base=\$(basename \"\$f\")
                [ -f $SFTP_RPM_PROCESSED/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/
                echo '  Transferred wrong extension file: '\$base
            fi
        done
    " || true

    echo -e "${GREEN}✅ Transfer of files with invalid formats complete${NC}"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main_invalid_files() {
    echo -e "${BLUE}🏁 Starting invalid mock data generation process...${NC}"
    echo -e "${BLUE}📅 Processing date: $INPUT_DATE${NC}"
    
    # Check if Docker container is running
    if ! docker ps | grep -q $DOCKER_CONTAINER; then
        echo -e "${RED}❌ Error: Docker container '$DOCKER_CONTAINER' is not running${NC}"
        echo -e "${YELLOW}💡 Start container first: docker-compose up -d${NC}"
        exit 1
    fi
    
    # Clean Docker container directories if --clean flag was used
    if [ "$CLEAN_DOCKER" -eq 1 ]; then
        clean_docker_directories
    fi
    
    # Generate invalid files
    generate_invalid_price_files
    generate_invalid_promotion_files
    generate_invalid_feedback_files
    
    # Upload invalid files to Docker
    upload_invalid_files_to_docker
    
    # Transfer files through the pipeline (1P → SOA → RPM)
    transfer_invalid_format_files
    
    echo -e "${GREEN}🎉 Invalid mock data generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing validation failures${NC}"
    echo -e "${BLUE}📋 Local data stored in: $INVALID_DIR/${NC}"
}

# Run main function if not sourced
main_invalid_files "$@"
