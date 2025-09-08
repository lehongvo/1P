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

# SFTP target (GCE VM)
SFTP_HOST=${SFTP_HOST:-"35.240.183.156"}
SFTP_PORT=${SFTP_PORT:-"2222"}
SFTP_USER=${SFTP_USER:-"demo"}
SFTP_PASS=${SFTP_PASS:-"demo"}
SFTP_REMOTE_BASE=${SFTP_REMOTE_BASE:-"/sftp/rpm/processed"}

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
        ALTER TABLE price ADD COLUMN IF NOT EXISTS item VARCHAR(50);
        ALTER TABLE price ADD COLUMN IF NOT EXISTS price_change_display_id VARCHAR(100);
        CREATE INDEX IF NOT EXISTS idx_price_item ON price(item);
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
        # Upload to SFTP
        upload_to_sftp "$filepath"

        ((count++))
    done

    echo -e "${GREEN}✅ Price files generated: $count files${NC}"
}

# =============================================================================
# FUNCTION: Upload file to SFTP server
# =============================================================================
upload_to_sftp() {
    local local_path="$1"
    local remote_file_name=$(basename "$local_path")
    local remote_dir="$SFTP_REMOTE_BASE"
    
    echo -e "${BLUE}🔄 Starting SFTP upload for: $remote_file_name${NC}"
    echo -e "${BLUE}   Local path: $local_path${NC}"
    echo -e "${BLUE}   Remote dir: $remote_dir${NC}"
    echo -e "${BLUE}   SFTP server: $SFTP_HOST:$SFTP_PORT${NC}"
    echo -e "${BLUE}   SFTP user: $SFTP_USER${NC}"
    
    # Check if local file exists
    if [ ! -f "$local_path" ]; then
        echo -e "${RED}❌ Local file not found: $local_path${NC}"
        return 1
    fi
    
    # Check file size
    local file_size=$(stat -c%s "$local_path" 2>/dev/null || stat -f%z "$local_path" 2>/dev/null || echo "unknown")
    echo -e "${BLUE}   File size: $file_size bytes${NC}"
    
    # Install sshpass if not available
    if ! command -v sshpass &> /dev/null; then
        echo -e "${YELLOW}📦 Installing sshpass...${NC}"
        apt-get update -y >/dev/null 2>&1 || true
        apt-get install -y sshpass >/dev/null 2>&1 || true
    fi
    
    # Test SFTP connection first
    echo -e "${YELLOW}🔍 Testing SFTP connection...${NC}"
    local test_output
    test_output=$(sshpass -p "$SFTP_PASS" sftp -P "$SFTP_PORT" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$SFTP_USER@$SFTP_HOST" <<EOF 2>&1
pwd
ls -la
quit
EOF
)
    local test_exit_code=$?
    echo -e "${BLUE}📋 SFTP connection test output: $test_output${NC}"
    echo -e "${BLUE}📋 SFTP connection test exit code: $test_exit_code${NC}"
    
    if [ $test_exit_code -ne 0 ]; then
        echo -e "${RED}❌ SFTP connection test failed${NC}"
        return 1
    fi
    
    # Create remote dir and upload file
    set +e
    local sftp_output
    echo -e "${YELLOW}📡 Executing SFTP upload commands...${NC}"
    sftp_output=$(sshpass -p "$SFTP_PASS" sftp -P "$SFTP_PORT" -o StrictHostKeyChecking=no "$SFTP_USER@$SFTP_HOST" <<EOF 2>&1
cd $remote_dir
put "$local_path" "$remote_file_name"
ls -la "$remote_file_name"
quit
EOF
)
    local exit_code=$?
    echo -e "${BLUE}📋 SFTP upload output: $sftp_output${NC}"
    echo -e "${BLUE}📋 SFTP upload exit code: $exit_code${NC}"
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✅ SFTP upload success: $remote_dir/$remote_file_name${NC}"
        return 0
    else
        echo -e "${RED}❌ SFTP upload failed (exit code: $exit_code): $sftp_output${NC}"
        return 1
    fi
    set -e
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

    local docker_path="/sftp/rpm/processed/$(basename "$file_path")"

    # Skip if duplicate path already exists
    local exists_miss
    echo -e "${BLUE}🔎 Checking duplicate (miss) for: $docker_path${NC}"
    exists_miss=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(1) FROM price WHERE path_file='$docker_path';" 2>/dev/null | tr -d ' ')
    echo -e "${BLUE}   Existing rows count: ${exists_miss:-0}${NC}"
    if [ "${exists_miss:-0}" != "0" ]; then
        echo -e "${YELLOW}  ⚠️ Skip duplicate price path (miss): $docker_path${NC}"
        return 0
    fi

    # 50% status=1, 50% status=2
    local status_value=1
    local rand=$((RANDOM % 100))
    if [ $rand -lt 50 ]; then status_value=2; fi

    # Random price_change_display_id
    local display_texts=("PRICE_UPDATE_001" "DISCOUNT_APPLIED" "SEASONAL_CHANGE" "BULK_PRICING" "PROMO_ACTIVE" "MARKET_ADJUSTMENT" "INVENTORY_CLEAR" "NEW_PRODUCT_LAUNCH")
    local price_change_display_id=${display_texts[$((RANDOM % ${#display_texts[@]}))]}

    # Insert with extended fields (item, price_change_display_id)
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        INSERT INTO price (path_file, status, item, action, price_change_display_id)
        VALUES ('$docker_path', $status_value, '$item_code', '', '$price_change_display_id');
    " &>/dev/null || true
}

# =============================================================================
# FUNCTION: Insert price record for unit-variation scenario (status 1/3)
# =============================================================================
insert_single_price_record_unit() {
    local file_path="$1"
    local item_code="$2"
    local file_timestamp="$3"

    local docker_path="/sftp/rpm/processed/$(basename "$file_path")"

    # Allow one additional row for the same path with status=3.
    # Skip only if a status=3 row already exists for this path.
    local exists_unit
    echo -e "${BLUE}🔎 Checking existing status=3 (unit) for: $docker_path${NC}"
    exists_unit=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(1) FROM price WHERE path_file='$docker_path' AND status=3;" 2>/dev/null | tr -d ' ')
    echo -e "${BLUE}   Existing status=3 rows: ${exists_unit:-0}${NC}"
    if [ "${exists_unit:-0}" != "0" ]; then
        echo -e "${YELLOW}  ⚠️ Skip duplicate status=3 for path (unit): $docker_path${NC}"
        return 0
    fi

    # 50% status=1, 50% status=3
    local status_value=1
    local rand=$((RANDOM % 100))
    if [ $rand -lt 50 ]; then status_value=3; fi

    # Random price_change_display_id
    local display_texts=("PRICE_UPDATE_001" "DISCOUNT_APPLIED" "SEASONAL_CHANGE" "BULK_PRICING" "PROMO_ACTIVE" "MARKET_ADJUSTMENT" "INVENTORY_CLEAR" "NEW_PRODUCT_LAUNCH")
    local price_change_display_id=${display_texts[$((RANDOM % ${#display_texts[@]}))]}

    # Insert with extended fields (item, price_change_display_id)
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        INSERT INTO price (path_file, status, item, action, price_change_display_id)
        VALUES ('$docker_path', $status_value, '$item_code', '', '$price_change_display_id');
    " &>/dev/null || true
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

    # Delegate to both insert variants with randomized delay and refreshed timestamp
    insert_single_price_record_miss "$file_path" "$item_code" "$file_timestamp"
    # Random gap between 1-10 seconds
    local gap_seconds=$((1 + RANDOM % 10))
    echo -e "${YELLOW}⏳ Waiting ${gap_seconds}s before second price insert...${NC}"
    sleep "$gap_seconds"
    # Refresh timestamp for the second insert to make created_at different
    local file_timestamp2=$(date '+%H%M%S')
    insert_single_price_record_unit "$file_path" "$item_code" "$file_timestamp2"
}

# =============================================================================
# FUNCTION: Generate promotion files
# =============================================================================
generate_promotion_files() {
    echo -e "${BLUE}🎯 Generating $TOTAL_FILES Promotion Files (.ods)...${NC}"
    
    local date_dir="$BASE_DIR/$DATE_DIR_FORMAT"
    local count=0
    local upload_success=0
    local upload_failed=0
    
    for i in $(seq 1 $TOTAL_FILES); do
        # Use high-resolution time (HHMMSS) so we don't duplicate the YYYYMMDD part
        local timestamp=$(date '+%H%M%S')
        local millis=$(date '+%3N' 2>/dev/null || printf "000")
        local rand_suffix=$(printf "%04d" $((RANDOM % 10000)))
        local unique_suffix="${timestamp}${millis}${rand_suffix}"
        local filename="TH_PROMPRCH_${DATE_PATTERN}${unique_suffix}.ods"
        local filepath="$date_dir/promotion/$filename"
        
        # Create mock promotion data
        echo -e "${YELLOW}📝 Creating promotion file: $filename${NC}"
        cat > "$filepath" << EOF
Header,Promotion ID,Item Code,Description,Discount,Timestamp
PROMO_${DATE_PATTERN}_${unique_suffix},PROMO${DATE_PATTERN}_${unique_suffix},ITEM${DATE_PATTERN}_${unique_suffix},Mock Promotion $i,$((RANDOM % 71))%,$(date '+%Y-%m-%d %H:%M:%S')
EOF
        
        # Verify file was created
        if [ -f "$filepath" ]; then
            local file_size=$(stat -c%s "$filepath" 2>/dev/null || stat -f%z "$filepath" 2>/dev/null || echo "unknown")
            echo -e "${GREEN}  ✅ File created successfully: $filename (size: $file_size bytes)${NC}"
        else
            echo -e "${RED}  ❌ Failed to create file: $filename${NC}"
            continue
        fi
        
        echo -e "${YELLOW}📤 Uploading promotion file to SFTP: $filename${NC}"
        # Upload to SFTP
        if upload_to_sftp "$filepath"; then
            ((upload_success++))
            echo -e "${GREEN}  ✅ Upload successful: $filename${NC}"
            
            # Insert promotion record into database after successful upload
            insert_single_promotion_record "$filepath" "$filename"
        else
            ((upload_failed++))
            echo -e "${RED}  ❌ Upload failed: $filename${NC}"
        fi
        
        ((count++))
    done
    
    echo -e "${GREEN}✅ Promotion files generated: $count files (Upload: $upload_success success, $upload_failed failed)${NC}"
}


# =============================================================================
# FUNCTION: Insert single promotion record into database
# =============================================================================
insert_single_promotion_record() {
    local file_path="$1"
    local filename="$2"
    
    # Quick checks
    if ! command -v psql &> /dev/null; then
        echo -e "${YELLOW}  ⚠️ psql not available, skipping DB insert${NC}"
        return 0
    fi
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c 'SELECT 1;' &>/dev/null; then
        echo -e "${YELLOW}  ⚠️ Database connection failed, skipping DB insert${NC}"
        return 0
    fi
    
    local cloud_path="/sftp/rpm/processed/$filename"
    
    # Extract promotion and item codes from file content
    local promotion_id=$(head -2 "$file_path" | tail -1 | cut -d',' -f2)
    local item_code=$(head -2 "$file_path" | tail -1 | cut -d',' -f3)
    local discount_value=$(head -2 "$file_path" | tail -1 | cut -d',' -f5 | tr -d '%')
    
    echo -e "${BLUE}  📊 Inserting promotion record: $filename${NC}"
    echo -e "${BLUE}     Promotion ID: $promotion_id${NC}"
    echo -e "${BLUE}     Item Code: $item_code${NC}"
    echo -e "${BLUE}     Cloud Path: $cloud_path${NC}"
    
    # Exact 50/50 status selection using a single random bit
    local status
    if [ $((RANDOM & 1)) -eq 0 ]; then
        status=1
    else
        status=4
    fi
    
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')
    local days_to_add=$((1 + RANDOM % 7))
    local end_time=$(date -d "+${days_to_add} days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -v+${days_to_add}d '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${BLUE}     Status: $status (1=success, 4=failure)${NC}"
    echo -e "${BLUE}     Start Time: $start_time${NC}"
    echo -e "${BLUE}     End Time: $end_time${NC}"
    
    if [ $status -eq 4 ]; then
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
            INSERT INTO promotion (path_file, status, promotion_id, item_code, start_time, end_time, config_data)
            VALUES (
                '$cloud_path',
                $status,
                '$promotion_id',
                '$item_code',
                '$start_time',
                '$end_time',
                json_build_object(
                    'path', '$cloud_path',
                    'status', $status,
                    'updated_at', '$start_time',
                    'created_at', '$start_time',
                    'promotion_id', '$promotion_id',
                    'item_code', '$item_code',
                    'discount', $discount_value
                )
            );
        " &>/dev/null || true
        echo -e "${YELLOW}  📋 Config data JSON created for failed promotion: $promotion_id${NC}"
    else
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
            INSERT INTO promotion (path_file, status, promotion_id, item_code, start_time, end_time)
            VALUES ('$cloud_path', $status, '$promotion_id', '$item_code', '$start_time', '$end_time');
        " &>/dev/null || true
        echo -e "${GREEN}  ✅ Promotion record inserted: $filename${NC}"
    fi
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
    
    local total_files=$(find "$date_dir" -type f 2>/dev/null | wc -l)
    echo -e "  📊 Total: $total_files files"
    
    # Database statistics
    if command -v psql &> /dev/null && PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &>/dev/null; then
        local price_count=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM price WHERE DATE(created_at) = '$INPUT_DATE';" 2>/dev/null | tr -d ' ' || echo "N/A")
        local promotion_count=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM promotion WHERE DATE(created_at) = '$INPUT_DATE';" 2>/dev/null | tr -d ' ' || echo "N/A")
        echo -e "${BLUE}🗄️ Database Records for $INPUT_DATE:${NC}"
        echo -e "  🔹 Price records: $price_count"
        echo -e "  🔹 Promotion records: $promotion_count"
    fi
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
        sleep 30
        echo -e "${BLUE}🏁 Starting Cloud Run mock data generation process...${NC}"
        echo -e "${BLUE}📅 Processing date: $INPUT_DATE${NC}"
        echo -e "${BLUE}📂 Data structure: $BASE_DIR/$DATE_DIR_FORMAT/...${NC}"
        
        # Generate mock data files (DB records are inserted automatically)
        generate_price_files
        generate_promotion_files
        
        # Generate statistics
        generate_statistics
        echo -e "${YELLOW}⏰ $(date): Mock data service is running...${NC}"
    done
}

# Run main function
main "$@"
