#!/bin/bash

# =============================================================================
# MOCK DATA GENERATOR SCRIPT - ENHANCED VERSION
# 
# NEW FEATURES:
# ✅ Dynamic date support - accepts date parameter or uses current date
# ✅ Auto directory creation - checks and creates date-based folder structure  
# ✅ File existence check - skips existing files to avoid overwriting
# ✅ Enhanced error handling and user guidance
# ✅ Flexible date format handling (YYYY-MM-DD input format)
# ✅ Feedback directories support for complete DAG testing
# ✅ Improved Docker container validation
#
# USAGE:
#   ./generate_mock_data.sh              # Uses current date
#   ./generate_mock_data.sh 2025-07-31   # Uses specific date
#   ./generate_mock_data.sh --help       # Shows usage help
#
# Generates files for any specified date or current date
# Automatically checks and creates directories by date
# Automatically uploads to Docker SFTP container
# =============================================================================

set -e  # Exit on any error

# Default Configuration
BASE_DIR="data/mock_1p"
DOCKER_CONTAINER="lotus-sftp-1"
TOTAL_FILES=1

# SFTP/SOA/RPM folder mappings
# 1P folders (under /home/demo)
SFTP_1P_PRICE="/home/demo/sftp/Data/ITSRPC/outgoing_ok/RPR/TH"
SFTP_1P_PROMOTION="/home/demo/sftp/Data/ITSPMT/outgoing_ok/PPR/TH"
SFTP_1P_FEEDBACK_PRICE="/home/demo/sftp/Data/ITSRPC/incoming/RPR/TH/ok/:DATETIME"
SFTP_1P_FEEDBACK_PROMOTION="/home/demo/sftp/Data/ITSPMT/incoming/PPR/TH/ok/:DATETIME"

# SOA folders (under /home/demo)
SFTP_SOA_PRICE="/home/demo/soa/Data/ITSRPC/outgoing_ok/RPR/TH"
SFTP_SOA_PROMOTION="/home/demo/soa/Data/ITSPMT/outgoing_ok/PPR/TH"
SFTP_SOA_FEEDBACK_PRICE="/home/demo/soa/Data/ITSRPC/incoming/RPR/TH/ok/:DATETIME"
SFTP_SOA_FEEDBACK_PROMOTION="/home/demo/soa/Data/ITSPMT/incoming/PPR/TH/ok/:DATETIME"

# RPM folders (under /home/demo)
SFTP_RPM_PROCESSED="/home/demo/sftp/rpm/processed"
SFTP_RPM_PENDING="/home/demo/sftp/rpm/pending"

# =============================================================================
# CROSS-PLATFORM DATE HANDLING (Linux & macOS compatible)
# =============================================================================
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

# Function to parse date cross-platform
parse_date() {
    local input_date="$1"
    local format="$2"
    local os_type=$(detect_os)
    
    if [ "$os_type" = "macos" ]; then
        # macOS date command
        date -j -f "%Y-%m-%d" "$input_date" "$format" 2>/dev/null
    else
        # Linux date command
        date -d "$input_date" "$format" 2>/dev/null
    fi
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Show usage information first
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo -e "${YELLOW}Usage: $0 [YYYY-MM-DD]${NC}"
    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  $0                # Use current date"
    echo -e "  $0 2025-07-31     # Use specific date"
    echo -e "  $0 --watch        # Run transfer loop (2-minute interval) after upload"
    echo -e "  $0 2025-07-31 --watch  # Generate for date and run transfer loop"
    echo -e "  $0 2025-08-15     # Use future date"
    echo -e ""
    echo -e "${BLUE}This script generates mock data for DAG testing:${NC}"
    echo -e "  📊 Price files (.ods) - for price validation"
    echo -e "  🎯 Promotion files (.ods) - for promotion validation"
    echo -e "  💬 Feedback files (.csv) - for feedback validation"
    echo -e "  🐳 Uploads to Docker SFTP container automatically"
    exit 0
fi

# Date handling - accept parameter or use current date; parse optional --watch
WATCH_MODE=0
if [ "$1" = "--watch" ] || [ "$1" = "-w" ] || [ "$2" = "--watch" ] || [ "$2" = "-w" ]; then
    WATCH_MODE=1
fi

# Date handling
if [ -n "$1" ]; then
    # Skip processing if this is a source-only invocation
    if [ "$1" = "--source-only" ]; then
        INPUT_DATE=$(date +%Y-%m-%d)  # Use current date as default when sourced
    # Parse input date (format: YYYY-MM-DD)
    elif [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
        INPUT_DATE=$(date +%Y-%m-%d)
    else
        INPUT_DATE="$1"
    fi
    
    # Only validate date format if we're not being sourced
    if [ "$1" != "--source-only" ] && [[ ! "$INPUT_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "❌ Error: Date format should be YYYY-MM-DD (e.g., 2025-07-31)"
        exit 1
    fi
    
    # Validate date exists
    if ! parse_date "$INPUT_DATE" "+%Y-%m-%d" >/dev/null; then
        echo "❌ Error: Invalid date '$INPUT_DATE'"
        exit 1
    fi
else
    # Use current date
    INPUT_DATE=$(date +%Y-%m-%d)
fi

# Generate date formats from input
DATE_PATTERN=$(parse_date "$INPUT_DATE" "+%Y%m%d")
DATE_FORMAT=$(parse_date "$INPUT_DATE" "+%d%b%Y")
DATE_DIR_FORMAT="$INPUT_DATE"

echo -e "${BLUE}=== MOCK DATA GENERATOR SCRIPT - ENHANCED ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating $TOTAL_FILES files each for price, promotion, and feedback${NC}"

# =============================================================================
# FUNCTION: Check and create directories
# =============================================================================
check_and_create_directories() {
    echo -e "${BLUE}📁 Checking and creating local directories...${NC}"
    
    # Create local directories with date structure
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    
    # Check and create base date directory
    if [ ! -d "$date_dir" ]; then
        echo -e "${YELLOW}  Creating directory: $date_dir${NC}"
        mkdir -p "$date_dir"
    else
        echo -e "${GREEN}  Directory exists: $date_dir${NC}"
    fi
    
    # Create subdirectories for each file type (UPDATED - added feedback directories)
    local subdirs=("price" "promotion" "feedback_price" "feedback_promotion")
    for subdir in "${subdirs[@]}"; do
        local full_path="$date_dir/$subdir"
        if [ ! -d "$full_path" ]; then
            echo -e "${YELLOW}  Creating: $full_path${NC}"
            mkdir -p "$full_path"
        else
            echo -e "${GREEN}  Exists: $full_path${NC}"
        fi
    done
    
    echo -e "${BLUE}🐳 Checking and creating Docker container directories...${NC}"

    # Ensure top-level symlinks so both /sftp and /home/demo/sftp work (same for /soa)
    docker exec $DOCKER_CONTAINER bash -lc '
        set -e
        mkdir -p /home/demo/sftp /home/demo/soa /home/demo/sftp/rpm || true
        if [ ! -e /sftp ]; then ln -s /home/demo/sftp /sftp; fi
        if [ ! -e /soa ]; then ln -s /home/demo/soa /soa; fi
    ' >/dev/null 2>&1 || true
    
    # Check and create Docker directories (1P, SOA, RPM)
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
        # Check if directory exists in Docker container
        if ! docker exec $DOCKER_CONTAINER test -d "$dir" 2>/dev/null; then
            echo -e "${YELLOW}  Creating Docker dir: $dir${NC}"
            docker exec $DOCKER_CONTAINER mkdir -p "$dir"
        else
            echo -e "${GREEN}  Docker dir exists: $dir${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ All directories checked and created${NC}"
}

# =============================================================================
# FUNCTION: Generate Price Files (.ods)
# =============================================================================
generate_price_files() {
    echo -e "${GREEN}📊 Generating $TOTAL_FILES Price Files (.ods)...${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    
    for i in $(seq 1 $TOTAL_FILES); do
        # Generate random timestamp for realistic file naming
        hour=$((5 + RANDOM % 8))      # Random hour between 05-12
        minute=$((RANDOM % 60))       # Random minute
        second=$((RANDOM % 60))       # Random second
        timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
        
        file_name="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        file_path="$date_dir/price/$file_name"
        
        # Skip if file already exists
        if [ -f "$file_path" ]; then
            if [ $((i % 20)) -eq 0 ]; then
                echo -e "${BLUE}  File exists: $file_name (skipping)${NC}"
            fi
            continue
        fi
        
        # Generate random price data
        price1=$(echo "scale=2; $RANDOM/100" | bc)
        price2=$(echo "scale=2; $RANDOM/100" | bc)
        price3=$(echo "scale=2; $RANDOM/100" | bc)
        
        item1="ITEM$(printf '%05d' $((i*3-2)))"
        item2="ITEM$(printf '%05d' $((i*3-1)))"
        item3="ITEM$(printf '%05d' $((i*3)))"
        
        cat > "$file_path" << EOF
Price,Item,Store,Date,Batch
$price1,$item1,STORE01,$INPUT_DATE,$timestamp
$price2,$item2,STORE01,$INPUT_DATE,$timestamp
$price3,$item3,STORE02,$INPUT_DATE,$timestamp
EOF
        
        if [ $((i % 20)) -eq 0 ]; then
            echo -e "${YELLOW}  Generated $i/$TOTAL_FILES price files...${NC}"
        fi
        
        # Small delay to ensure unique timestamps
        sleep 0.1
    done
    echo -e "${GREEN}✅ Price files generated: $TOTAL_FILES files${NC}"
}

# =============================================================================
# FUNCTION: Generate Promotion Files (.ods)
# =============================================================================
generate_promotion_files() {
    echo -e "${GREEN}🎯 Generating $TOTAL_FILES Promotion Files (.ods)...${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    discounts=("5%" "10%" "15%" "20%" "25%" "30%" "35%" "40%" "50%")
    
    for i in $(seq 1 $TOTAL_FILES); do
        # Generate random timestamp for realistic file naming
        hour=$((6 + RANDOM % 7))      # Random hour between 06-12
        minute=$((RANDOM % 60))       # Random minute
        second=$((RANDOM % 60))       # Random second
        timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
        
        file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
        file_path="$date_dir/promotion/$file_name"
        
        # Skip if file already exists
        if [ -f "$file_path" ]; then
            if [ $((i % 20)) -eq 0 ]; then
                echo -e "${BLUE}  File exists: $file_name (skipping)${NC}"
            fi
            continue
        fi
        
        # Generate random promotion data
        promo1="PROMO$(printf '%05d' $((i*2-1)))"
        promo2="PROMO$(printf '%05d' $((i*2)))"
        
        item1="ITEM$(printf '%05d' $((i*2-1)))"
        item2="ITEM$(printf '%05d' $((i*2)))"
        
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
PromoID,Item,Discount,StartDate,EndDate,Batch
$promo1,$item1,$discount1,$INPUT_DATE,$end_date,$timestamp
$promo2,$item2,$discount2,$INPUT_DATE,$end_date,$timestamp
EOF
        
        if [ $((i % 20)) -eq 0 ]; then
            echo -e "${YELLOW}  Generated $i/$TOTAL_FILES promotion files...${NC}"
        fi
        
        # Small delay to ensure unique timestamps
        sleep 0.1
    done
    echo -e "${GREEN}✅ Promotion files generated: $TOTAL_FILES files${NC}"
}

# =============================================================================
# FUNCTION: Generate Feedback Price Files (.csv)
# =============================================================================
generate_feedback_price_files() {
    echo -e "${GREEN}💬 Generating $TOTAL_FILES Feedback Price Files (.csv)...${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    
    # Generate varied timestamps (some with delays, some without)
    for i in $(seq 1 $TOTAL_FILES); do
        # Create varied timestamps
        hour=$((5 + RANDOM % 8))  # Random hour between 05-12
        minute=$((RANDOM % 60))   # Random minute
        second=$(((RANDOM % 60)))  # Random second
        
        time_str=$(printf "%02d%02d%02d" $hour $minute $second)
        file_name="CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}.csv"
        file_path="$date_dir/feedback_price/$file_name"
        
        # Skip if file already exists
        if [ -f "$file_path" ]; then
            if [ $((i % 20)) -eq 0 ]; then
                echo -e "${BLUE}  File exists: $file_name (skipping)${NC}"
            fi
            continue
        fi
        
        # Generate feedback data
        fb_id1="FB$(printf '%05d' $((i*3-2)))"
        fb_id2="FB$(printf '%05d' $((i*3-1)))"
        fb_id3="FB$(printf '%05d' $((i*3)))"
        
        statuses=("SUCCESS" "SUCCESS" "SUCCESS" "DELAYED" "FAILED")
        status1=${statuses[$((RANDOM % ${#statuses[@]}))]}
        status2=${statuses[$((RANDOM % ${#statuses[@]}))]}
        status3=${statuses[$((RANDOM % ${#statuses[@]}))]}
        
        cat > "$file_path" << EOF
feedback_id,status,processed_time
$fb_id1,$status1,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $second)
$fb_id2,$status2,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+15)))
$fb_id3,$status3,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+30)))
EOF
        
        if [ $((i % 20)) -eq 0 ]; then
            echo -e "${YELLOW}  Generated $i/$TOTAL_FILES feedback price files...${NC}"
        fi
    done
    echo -e "${GREEN}✅ Feedback price files generated: $TOTAL_FILES files${NC}"
}

# =============================================================================
# FUNCTION: Generate Feedback Promotion Files (.csv)
# =============================================================================
generate_feedback_promotion_files() {
    echo -e "${GREEN}🎪 Generating $TOTAL_FILES Feedback Promotion Files (.csv)...${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    
    for i in $(seq 1 $TOTAL_FILES); do
        # Create varied timestamps
        hour=$((6 + RANDOM % 7))  # Random hour between 06-12
        minute=$((RANDOM % 60))   # Random minute  
        second=$(((RANDOM % 60))) # Random second
        
        time_str=$(printf "%02d%02d%02d" $hour $minute $second)
        file_name="CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}_${time_str}.csv"
        file_path="$date_dir/feedback_promotion/$file_name"
        
        # Skip if file already exists
        if [ -f "$file_path" ]; then
            if [ $((i % 20)) -eq 0 ]; then
                echo -e "${BLUE}  File exists: $file_name (skipping)${NC}"
            fi
            continue
        fi
        
        # Generate feedback data
        fb_id1="FBP$(printf '%05d' $((i*3-2)))"
        fb_id2="FBP$(printf '%05d' $((i*3-1)))"
        fb_id3="FBP$(printf '%05d' $((i*3)))"
        
        statuses=("SUCCESS" "SUCCESS" "SUCCESS" "DELAYED" "FAILED")
        status1=${statuses[$((RANDOM % ${#statuses[@]}))]}
        status2=${statuses[$((RANDOM % ${#statuses[@]}))]}
        status3=${statuses[$((RANDOM % ${#statuses[@]}))]}
        
        cat > "$file_path" << EOF
feedback_id,status,processed_time
$fb_id1,$status1,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $second)
$fb_id2,$status2,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+15)))
$fb_id3,$status3,$INPUT_DATE $(printf "%02d:%02d:%02d" $hour $minute $((second+30)))
EOF
        
        if [ $((i % 20)) -eq 0 ]; then
            echo -e "${YELLOW}  Generated $i/$TOTAL_FILES feedback promotion files...${NC}"
        fi
    done
    echo -e "${GREEN}✅ Feedback promotion files generated: $TOTAL_FILES files${NC}"
}

# =============================================================================
# FUNCTION: Upload files to Docker SFTP Container
# =============================================================================
upload_to_docker() {
    echo -e "${BLUE}🚀 Uploading files to Docker SFTP Container...${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    
    # Upload Price Files → 1P
    echo -e "${YELLOW}📤 Uploading Price files...${NC}"
    for file in $date_dir/price/TH_PRCH_${DATE_PATTERN}*.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Promotion Files → 1P
    echo -e "${YELLOW}📤 Uploading Promotion files...${NC}"
    for file in $date_dir/promotion/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Feedback Price Files → 1P
    echo -e "${YELLOW}📤 Uploading Feedback Price files...${NC}"
    for file in $date_dir/feedback_price/CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:${SFTP_1P_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE}/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Feedback Promotion Files → 1P
    echo -e "${YELLOW}📤 Uploading Feedback Promotion files...${NC}"
    for file in $date_dir/feedback_promotion/CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:${SFTP_1P_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE}/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done

    echo -e "${GREEN}✅ All files uploaded to Docker container${NC}"
}

# =============================================================================
# FUNCTION: Fix file ownership in Docker container
# =============================================================================
fix_ownership() {
    echo -e "${BLUE}🔧 Fixing file ownership in Docker container...${NC}"
    
    # 1P
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory $SFTP_1P_PRICE 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory $SFTP_1P_PROMOTION 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory ${SFTP_1P_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE} 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory ${SFTP_1P_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE} 2>/dev/null || true"

    # SOA
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory $SFTP_SOA_PRICE 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory $SFTP_SOA_PROMOTION 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory ${SFTP_SOA_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE} 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory ${SFTP_SOA_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE} 2>/dev/null || true"

    # RPM
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory $SFTP_RPM_PROCESSED 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory $SFTP_RPM_PENDING 2>/dev/null || true"

    echo -e "${GREEN}✅ File ownership fixed${NC}"
}

# =============================================================================
# FUNCTION: Show final statistics
# =============================================================================
show_statistics() {
    echo -e "${BLUE}📊 Final Statistics for Date: $INPUT_DATE${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    
    # Count files in local directories
    price_local=$(find $date_dir/price -name "TH_PRCH_${DATE_PATTERN}*.ods" 2>/dev/null | wc -l)
    promotion_local=$(find $date_dir/promotion -name "TH_PROMPRCH_${DATE_PATTERN}*.ods" 2>/dev/null | wc -l)
    feedback_price_local=$(find $date_dir/feedback_price -name "CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}*.csv" 2>/dev/null | wc -l)
    feedback_promotion_local=$(find $date_dir/feedback_promotion -name "CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}*.csv" 2>/dev/null | wc -l)
    
    echo -e "${GREEN}📁 Local Files Generated ($date_dir):${NC}"
    echo -e "  🔹 Price files: $price_local"
    echo -e "  🔹 Promotion files: $promotion_local"
    echo -e "  🔹 Feedback Price files: $feedback_price_local"
    echo -e "  🔹 Feedback Promotion files: $feedback_promotion_local"
    echo -e "  📊 Total: $((price_local + promotion_local + feedback_price_local + feedback_promotion_local)) files"
    
    # Count files in Docker container (1P paths)
    echo -e "${GREEN}🐳 Docker Container Files:${NC}"
    docker_price=$(docker exec $DOCKER_CONTAINER bash -c "ls -1 $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.ods 2>/dev/null | wc -l" || echo "0")
    docker_promotion=$(docker exec $DOCKER_CONTAINER bash -c "ls -1 $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods 2>/dev/null | wc -l" || echo "0")
    docker_feedback_price=$(docker exec $DOCKER_CONTAINER bash -c "ls -1 ${SFTP_1P_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE}/CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}*.csv 2>/dev/null | wc -l" || echo "0")
    docker_feedback_promotion=$(docker exec $DOCKER_CONTAINER bash -c "ls -1 ${SFTP_1P_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE}/CP_PROMOTIONS_FEEDBACK_${DATE_FORMAT}*.csv 2>/dev/null | wc -l" || echo "0")
    
    echo -e "  🔹 Price files: $(echo $docker_price | tr -d ' \r')"
    echo -e "  🔹 Promotion files: $(echo $docker_promotion | tr -d ' \r')"
    echo -e "  🔹 Feedback Price files: $(echo $docker_feedback_price | tr -d ' \r')"
    echo -e "  🔹 Feedback Promotion files: $(echo $docker_feedback_promotion | tr -d ' \r')"
}

# =============================================================================
# FUNCTION: 2-minute transfer loop (1P → SOA → RPM)
# =============================================================================
start_transfer_loop() {
    local interval_seconds=10
    echo -e "${BLUE}⏱️ Starting transfer loop: every 2 minutes (includes directory checks)${NC}"
    while true; do
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
        " >/dev/null 2>&1 || true

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
        " >/dev/null 2>&1 || true

        sleep "$interval_seconds"
    done
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    echo -e "${BLUE}🏁 Starting enhanced mock data generation process...${NC}"
    echo -e "${BLUE}📅 Processing date: $INPUT_DATE${NC}"
    echo -e "${BLUE}📂 Data structure: $BASE_DIR/$DATE_DIR_FORMAT/...${NC}"
    
    # Check if Docker container is running
    if ! docker ps | grep -q $DOCKER_CONTAINER; then
        echo -e "${RED}❌ Error: Docker container '$DOCKER_CONTAINER' is not running${NC}"
        echo -e "${YELLOW}💡 Start container first: docker-compose up -d${NC}"
        exit 1
    fi
    
    # Check if bc command is available (needed for price calculations)
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}❌ Error: 'bc' command not found. Please install bc package${NC}"
        echo -e "${YELLOW}💡 Install with: sudo apt install bc${NC}"
        exit 1
    fi
    
    # Check and create directories
    check_and_create_directories
    
    # Generate all files
    generate_price_files
    generate_promotion_files
    generate_feedback_price_files
    generate_feedback_promotion_files
    
    # Upload to Docker (→ 1P paths)
    upload_to_docker
    
    # Fix ownership
    fix_ownership
    
    # Show statistics
    show_statistics

    # Optional: start transfer loop (1P → SOA → RPM)
    if [ "$WATCH_MODE" -eq 1 ]; then
        start_transfer_loop
    fi

    echo -e "${GREEN}🎉 Mock data generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Ready for DAG testing with $(($TOTAL_FILES * 4)) total files for date $INPUT_DATE${NC}"
    echo -e "${BLUE}📋 Local data stored in: $BASE_DIR/$DATE_DIR_FORMAT/${NC}"
    echo -e "${BLUE}🚀 Files uploaded to Docker SFTP container for DAG testing${NC}"
}

# Check if being sourced by another script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Run main function only if not being sourced
    if [ "${1}" != "--source-only" ]; then
        main "$@"
    fi
fi 