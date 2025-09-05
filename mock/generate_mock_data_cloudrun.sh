#!/bin/bash

# =============================================================================
# MOCK DATA GENERATOR SCRIPT - CLOUD RUN VERSION
# =============================================================================
# This version is designed to run in Google Cloud Run environment
# without Docker dependencies

# Do not exit on first error; keep loop running on Cloud Run
set +e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INPUT_DATE=${INPUT_DATE:-$(date '+%Y-%m-%d')}
BASE_DIR=${BASE_DIR:-"/tmp/data"}
DATE_DIR_FORMAT="$INPUT_DATE"
DATE_PATTERN=$(echo "$INPUT_DATE" | tr -d '-')
TOTAL_FILES=1

# Database configuration
DB_HOST=${DB_HOST:-"34.142.150.197"}  # Use Cloud SQL IP address
DB_PORT=${DB_PORT:-"5432"}
DB_NAME=${DB_NAME:-"lotus_o2o"}
DB_USER=${DB_USER:-"lotus_user"}
DB_PASSWORD=${DB_PASSWORD:-"lotus_password"}

echo -e "${BLUE}=== MOCK DATA GENERATOR SCRIPT - CLOUD RUN VERSION ===${NC}"
echo -e "${GREEN}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${GREEN}📊 Generating $TOTAL_FILES files each for price, promotion, and feedback${NC}"

# =============================================================================
# FUNCTION: Check database connection
# =============================================================================
check_database_connection() {
    echo -e "${BLUE}🔍 Checking database connection...${NC}"
    
    if ! command -v psql &> /dev/null; then
        echo -e "${RED}❌ Error: psql command not found${NC}"
        exit 1
    fi
    
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &>/dev/null; then
        echo -e "${RED}❌ Error: Cannot connect to database${NC}"
        echo -e "${YELLOW}💡 Check database configuration: DB_HOST=$DB_HOST, DB_PORT=$DB_PORT, DB_NAME=$DB_NAME${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Database connection successful${NC}"
}

# =============================================================================
# FUNCTION: Check and create directories
# =============================================================================
check_and_create_directories() {
    echo -e "${BLUE}📁 Checking and creating local directories...${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    mkdir -p "$date_dir/price"
    mkdir -p "$date_dir/promotion"
    mkdir -p "$date_dir/feedback_price"
    mkdir -p "$date_dir/feedback_promotion"
    
    echo -e "${GREEN}✅ All directories created${NC}"
}

# =============================================================================
# FUNCTION: Ensure price table exists at startup (Cloud Run)
# =============================================================================
ensure_price_table_startup() {
    echo -e "${BLUE}🗄️  Ensuring price table exists...${NC}"
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        CREATE TABLE IF NOT EXISTS price (
            id SERIAL PRIMARY KEY,
            path_file TEXT NOT NULL,
            status INTEGER DEFAULT 4,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            item_code VARCHAR(50),
            action VARCHAR(50) DEFAULT ''
        );
        CREATE INDEX IF NOT EXISTS idx_price_status ON price(status);
        CREATE INDEX IF NOT EXISTS idx_price_created_at ON price(created_at);
        CREATE INDEX IF NOT EXISTS idx_price_item_code ON price(item_code);
    " &>/dev/null || true
}

# =============================================================================
# FUNCTION: Generate price files
# =============================================================================
generate_price_files() {
    echo -e "${BLUE}📊 Generating $TOTAL_FILES Price Files (.ods)...${NC}"

    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    local count=0

    for i in $(seq 1 $TOTAL_FILES); do
        # Randomized timestamp components (HHMMSS)
        local hour=$((5 + RANDOM % 8))
        local minute=$((RANDOM % 60))
        local second=$((RANDOM % 60))
        local hhmmss=$(printf "%02d%02d%02d" $hour $minute $second)

        local filename="TH_PRCH_${DATE_PATTERN}${hhmmss}.ods"
        local filepath="$date_dir/price/$filename"

        # Random price data
        local price1=$(echo "scale=2; $RANDOM/100" | bc 2>/dev/null || echo "$(($RANDOM%100)).$(($RANDOM%100))")
        local price2=$(echo "scale=2; $RANDOM/100" | bc 2>/dev/null || echo "$(($RANDOM%100)).$(($RANDOM%100))")
        local price3=$(echo "scale=2; $RANDOM/100" | bc 2>/dev/null || echo "$(($RANDOM%100)).$(($RANDOM%100))")

        # Item codes aligned with different-unit script
        local item1="ITEM${DATE_PATTERN}$((10#${hhmmss} - 2))"
        local item2="ITEM${DATE_PATTERN}$((10#${hhmmss} - 1))"
        local item3="ITEM${DATE_PATTERN}${hhmmss}"

        # Locations (all rows filled like different-unit version)
        local locations=("Bangkok" "Chiang Mai" "Phuket" "Pattaya" "Krabi" "Hua Hin" "Koh Samui" "Ayutthaya")
        local location1=${locations[$((RANDOM % ${#locations[@]}))]}
        local location2=${locations[$((RANDOM % ${#locations[@]}))]}
        local location3=${locations[$((RANDOM % ${#locations[@]}))]}

        # Types and Units (match different-unit: type2=2, type3=2; unit2=bottle, unit3=kg)
        local type1=$((RANDOM % 10 + 1))
        local type2=2
        local type3=2
        local units=("box" "g" "ml" "pcs" "liter" "pack")
        local unit1=${units[$((RANDOM % ${#units[@]}))]}
        local unit2="bottle"
        local unit3="kg"

        # Write file
        cat > "$filepath" << EOF
Price,Item,Store,Date,Batch,Location,Type,Unit
$price1,$item1,STORE01,$INPUT_DATE,$hhmmss,$location1,$type1,$unit1
$price2,$item2,STORE01,$INPUT_DATE,$hhmmss,$location2,$type2,$unit2
$price3,$item3,STORE02,$INPUT_DATE,$hhmmss,$location3,$type3,$unit3
EOF

        # Insert price record into DB immediately after creating file (third row's item)
        insert_single_price_record "$filepath" "$item3" "$hhmmss"

        ((count++))
    done

    echo -e "${GREEN}✅ Price files generated: $count files${NC}"
}

# =============================================================================
# FUNCTION: Shared insert helper to avoid duplication
# =============================================================================
_insert_price_row_core() {
    local docker_path="$1"
    local item_code="$2"
    local status_value="$3"

    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        INSERT INTO price (path_file, status, item_code, action)
        VALUES ('$docker_path', $status_value, '$item_code', '');
    " &>/dev/null || true
}

# =============================================================================
# FUNCTION: Insert price record for missing-location scenario (status 1/2)
# =============================================================================
insert_single_price_record_miss() {
    local file_path="$1"
    local item_code="$2"
    local file_timestamp="$3"

    local docker_path="/home/demo/sftp/rpm/processed/$(basename "$file_path")"

    # 90% status=1, 10% status=2
    local status_value=1
    local rand=$((RANDOM % 100 + 1))
    if [ $rand -le 10 ]; then status_value=2; fi

    _insert_price_row_core "$docker_path" "$item_code" "$status_value"
}

# =============================================================================
# FUNCTION: Insert price record for unit-variation scenario (status 1/3)
# =============================================================================
insert_single_price_record_unit() {
    local file_path="$1"
    local item_code="$2"
    local file_timestamp="$3"

    local docker_path="/home/demo/sftp/rpm/processed/$(basename "$file_path")"

    # 90% status=1, 10% status=3
    local status_value=1
    local rand=$((RANDOM % 100 + 1))
    if [ $rand -le 10 ]; then status_value=3; fi

    _insert_price_row_core "$docker_path" "$item_code" "$status_value"
}

# =============================================================================
# FUNCTION: Insert single price record (delegates to both variants)
# =============================================================================
insert_single_price_record() {
    local file_path="$1"
    local item_code="$2"
    local file_timestamp="$3"

    # Quick checks
    if ! command -v psql &> /dev/null; then
        return 0
    fi
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c 'SELECT 1;' &>/dev/null; then
        return 0
    fi

    # Ensure table exists (in case startup missed)
    ensure_price_table_startup

    # Delegate to both insert variants
    insert_single_price_record_miss "$file_path" "$item_code" "$file_timestamp"
    insert_single_price_record_unit "$file_path" "$item_code" "$file_timestamp"
}

# =============================================================================
# FUNCTION: Generate promotion files
# =============================================================================
generate_promotion_files() {
    echo -e "${BLUE}🎯 Generating $TOTAL_FILES Promotion Files (.ods)...${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    local count=0
    
    for i in $(seq 1 $TOTAL_FILES); do
        local timestamp=$(date '+%Y%m%d%H%M%S')
        local filename="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
        local filepath="$date_dir/promotion/$filename"
        
        # Create mock promotion data
        cat > "$filepath" << EOF
Header,Promotion ID,Item Code,Description,Discount,Timestamp
PROMO_${DATE_PATTERN}_${timestamp},PROMO${DATE_PATTERN}$((i + 200)),ITEM${DATE_PATTERN}$((i + 200)),Mock Promotion $i,$((10 + RANDOM % 50))%,$(date '+%Y-%m-%d %H:%M:%S')
EOF
        
        ((count++))
    done
    
    echo -e "${GREEN}✅ Promotion files generated: $count files${NC}"
}

# =============================================================================
# FUNCTION: Generate feedback price files
# =============================================================================
generate_feedback_price_files() {
    echo -e "${BLUE}💬 Generating $TOTAL_FILES Feedback Price Files (.csv)...${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    local count=0
    
    for i in $(seq 1 $TOTAL_FILES); do
        local timestamp=$(date '+%d%b%Y_%H%M%S')
        local filename="CP_PROMOTIONS_FEEDBACK_${timestamp}.csv"
        local filepath="$date_dir/feedback_price/$filename"
        
        # Create mock feedback data
        cat > "$filepath" << EOF
Header,Feedback ID,Item Code,Rating,Comment,Timestamp
FEEDBACK_PRICE_${DATE_PATTERN}_${timestamp},FB${DATE_PATTERN}$((i + 300)),ITEM${DATE_PATTERN}$((i + 300)),$((1 + RANDOM % 5)),Mock feedback for price $i,$(date '+%Y-%m-%d %H:%M:%S')
EOF
        
        ((count++))
    done
    
    echo -e "${GREEN}✅ Feedback price files generated: $count files${NC}"
}

# =============================================================================
# FUNCTION: Generate feedback promotion files
# =============================================================================
generate_feedback_promotion_files() {
    echo -e "${BLUE}🎪 Generating $TOTAL_FILES Feedback Promotion Files (.csv)...${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    local count=0
    
    for i in $(seq 1 $TOTAL_FILES); do
        local timestamp=$(date '+%d%b%Y_%H%M%S')
        local filename="CP_PROMOTIONS_FEEDBACK_${timestamp}.csv"
        local filepath="$date_dir/feedback_promotion/$filename"
        
        # Create mock feedback data
        cat > "$filepath" << EOF
Header,Feedback ID,Promotion ID,Rating,Comment,Timestamp
FEEDBACK_PROMO_${DATE_PATTERN}_${timestamp},FB${DATE_PATTERN}$((i + 400)),PROMO${DATE_PATTERN}$((i + 400)),$((1 + RANDOM % 5)),Mock feedback for promotion $i,$(date '+%Y-%m-%d %H:%M:%S')
EOF
        
        ((count++))
    done
    
    echo -e "${GREEN}✅ Feedback promotion files generated: $count files${NC}"
}

# =============================================================================
# FUNCTION: Insert promotion records into database
# =============================================================================
insert_promotion_records() {
    echo -e "${GREEN}📊 Inserting promotion records into database...${NC}"
    
    # Check database connection
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &>/dev/null; then
        echo -e "${RED}❌ Cannot connect to database${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📝 Inserting promotion records directly...${NC}"
    local promotion_count=0
    
    # Generate promotion records directly without reading files
    for i in $(seq 1 $TOTAL_FILES); do
        local timestamp=$(date '+%Y%m%d%H%M%S')
        # Use the SAME timestamp-based id for both fields
        local promotion_id="PROMO${timestamp}"
        sleep 1
        local timestamp1=$(date '+%Y%m%d%H%M%S')
        local item_code="ITEM${timestamp1}"
        local cloud_path="$BASE_DIR/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
        
        # Status probability configuration (50% success, 50% failure)
        local SUCCESS_RATE=50  # 50% chance for status 1 (success)
        local FAILURE_RATE=50  # 50% chance for status 4 (failure)
        
        local status_chance=$((RANDOM % 100))
        local status=1  # Default status
        if [ $status_chance -lt $FAILURE_RATE ]; then
            status=4  # 50% chance for status 4
        fi
        
        local start_time=$(date '+%Y-%m-%d %H:%M:%S')
        local days_to_add=$((1 + RANDOM % 7))
        local end_time=$(date -d "+${days_to_add} days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -v+${days_to_add}d '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')
        
        if [ $status -eq 4 ]; then
            PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
                INSERT INTO promotion (path_file, status, promotion_id, item_code, start_time, end_time, config_data)
                VALUES ('$cloud_path', $status, '$promotion_id', '$item_code', '$start_time', '$end_time', '{\"path\": \"$cloud_path\", \"status\": 1, \"updated_at\": \"$start_time\", \"created_at\": \"$start_time\", \"promotion_id\": \"$promotion_id\", \"item_code\": \"$item_code\"}');
            " &>/dev/null || true
        else
            PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
                INSERT INTO promotion (path_file, status, promotion_id, item_code, start_time, end_time)
                VALUES ('$cloud_path', $status, '$promotion_id', '$item_code', '$start_time', '$end_time');
            " &>/dev/null || true
        fi
        
        local insert_result=$?
        if [ $insert_result -eq 0 ]; then
            ((promotion_count++))
            if [ $status -eq 4 ]; then
                echo -e "${YELLOW}  📋 Config data JSON created for failed promotion: $promotion_id${NC}"
            fi
        fi
    done
    
    local total_promotions=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM promotion WHERE DATE(created_at) = '$INPUT_DATE';" 2>/dev/null | tr -d ' ' || echo "N/A")
    echo -e "${GREEN}✅ Promotion records inserted: $total_promotions records${NC}"
}

# =============================================================================
# FUNCTION: Generate statistics
# =============================================================================
generate_statistics() {
    echo -e "${BLUE}📊 Final Statistics for Date: $INPUT_DATE${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    
    echo -e "${BLUE}📁 Local Files Generated ($date_dir):${NC}"
    echo -e "  🔹 Price files:        $(find "$date_dir/price" -name "*.ods" 2>/dev/null | wc -l)"
    echo -e "  🔹 Promotion files:        $(find "$date_dir/promotion" -name "*.ods" 2>/dev/null | wc -l)"
    echo -e "  🔹 Feedback Price files:        $(find "$date_dir/feedback_price" -name "*.csv" 2>/dev/null | wc -l)"
    echo -e "  🔹 Feedback Promotion files:        $(find "$date_dir/feedback_promotion" -name "*.csv" 2>/dev/null | wc -l)"
    
    local total_files=$(find "$date_dir" -type f 2>/dev/null | wc -l)
    echo -e "  📊 Total: $total_files files"
}

# =============================================================================
# FUNCTION: Simple HTTP server for health checks
# =============================================================================
start_health_server() {
    echo -e "${BLUE}🏥 Starting health check server on port 8080...${NC}"
    
    # Create a simple HTTP response
    while true; do
        echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 45\r\n\r\n{\"status\":\"healthy\",\"service\":\"mock-data\"}" | nc -l -p 8080 -q 1
        sleep 1
    done &
    
    local health_pid=$!
    echo -e "${GREEN}✅ Health server started (PID: $health_pid)${NC}"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    
    echo -e "${GREEN}✅ Mock data generation completed successfully!${NC}"
    echo -e "${BLUE}🔄 Running in continuous mode...${NC}"
            
    # Start health server
    start_health_server
    
    # Check database connection
    check_database_connection
    
    # Create directories
    check_and_create_directories
    # Ensure required tables
    ensure_price_table_startup
    
    # Keep the service running
    while true; do
        sleep 10
        echo -e "${BLUE}🏁 Starting Cloud Run mock data generation process...${NC}"
        echo -e "${BLUE}📅 Processing date: $INPUT_DATE${NC}"
        echo -e "${BLUE}📂 Data structure: $BASE_DIR/$DATE_DIR_FORMAT/...${NC}"
        insert_promotion_records
        # Generate mock data
        generate_price_files
        generate_promotion_files
    
        generate_feedback_price_files
        generate_feedback_promotion_files
        
        # Generate statistics
        generate_statistics
        echo -e "${YELLOW}⏰ $(date): Mock data service is running...${NC}"
    done
}

# Run main function
main "$@"
