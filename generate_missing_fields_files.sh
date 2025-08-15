#!/bin/bash

# =============================================================================
# MISSING FIELDS FILE GENERATOR FOR TESTING VALIDATION FAILURES
# =============================================================================
#
# This script generates CSV files with missing required fields to test the
# validate_required_fields_ops function in data processing pipelines
#
# USAGE:
#   ./generate_missing_fields_files.sh [YYYY-MM-DD] [--clean]
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

# Create missing fields directory
MISSING_FIELDS_DIR="$BASE_DIR/$DATE_DIR_FORMAT/missing_fields"
mkdir -p "$MISSING_FIELDS_DIR"

echo -e "${BLUE}=== MISSING FIELDS FILE GENERATOR FOR TESTING ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating files with missing required fields for testing validation${NC}"

# =============================================================================
# FUNCTION: Generate Price Files with Missing Fields
# =============================================================================
generate_price_files_with_missing_fields() {
    echo -e "${RED}🛑 Generating Price Files with Missing Fields...${NC}"
    
    # Define different combinations of missing fields
    # Required fields for price are: item_id, price, start_date, end_date
    local price_file_variants=(
        "price,start_date,end_date"                # Missing item_id
        "item_id,start_date,end_date"              # Missing price
        "item_id,price,end_date"                   # Missing start_date
        "item_id,price,start_date"                 # Missing end_date
        "start_date,end_date"                      # Missing item_id, price
        "item_id,price"                            # Missing start_date, end_date
        "price,end_date"                           # Missing item_id, start_date
        "item_id"                                  # Missing most fields
        "price"                                    # Only one field present
        ""                                         # Empty header
    )
    
    # Generate a file for each variant
    for (( i=0; i<${#price_file_variants[@]}; i++ )); do
        timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
        file_name="TH_PRCH_${DATE_PATTERN}${timestamp}_MISSING_FIELD_$i.csv"
        file_path="$MISSING_FIELDS_DIR/$file_name"
        
        # Create the file with the variant header
        header="${price_file_variants[$i]}"
        echo "$header" > "$file_path"
        
        # Add some sample data based on which fields are present
        if [[ "$header" == *"item_id"* && "$header" == *"price"* && "$header" == *"start_date"* && "$header" == *"end_date"* ]]; then
            # All fields present - just for reference, this shouldn't happen in this function
            echo "ITEM00001,$RANDOM.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
            echo "ITEM00002,$RANDOM.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
        elif [[ "$header" == *"price"* && "$header" == *"start_date"* && "$header" == *"end_date"* ]]; then
            # Missing item_id
            echo "$RANDOM.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
            echo "$RANDOM.75,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
        elif [[ "$header" == *"item_id"* && "$header" == *"start_date"* && "$header" == *"end_date"* ]]; then
            # Missing price
            echo "ITEM00001,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
            echo "ITEM00002,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
        elif [[ "$header" == *"item_id"* && "$header" == *"price"* && "$header" == *"end_date"* ]]; then
            # Missing start_date
            echo "ITEM00001,$RANDOM.50,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
            echo "ITEM00002,$RANDOM.75,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
        elif [[ "$header" == *"item_id"* && "$header" == *"price"* && "$header" == *"start_date"* ]]; then
            # Missing end_date
            echo "ITEM00001,$RANDOM.50,$INPUT_DATE" >> "$file_path"
            echo "ITEM00002,$RANDOM.75,$INPUT_DATE" >> "$file_path"
        elif [[ "$header" == *"start_date"* && "$header" == *"end_date"* ]]; then
            # Missing item_id, price
            echo "$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
            echo "$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
        elif [[ "$header" == *"item_id"* && "$header" == *"price"* ]]; then
            # Missing start_date, end_date
            echo "ITEM00001,$RANDOM.50" >> "$file_path"
            echo "ITEM00002,$RANDOM.75" >> "$file_path"
        elif [[ "$header" == *"price"* && "$header" == *"end_date"* ]]; then
            # Missing item_id, start_date
            echo "$RANDOM.50,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
            echo "$RANDOM.75,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
        elif [[ "$header" == *"item_id"* ]]; then
            # Missing most fields
            echo "ITEM00001" >> "$file_path"
            echo "ITEM00002" >> "$file_path"
        elif [[ "$header" == *"price"* ]]; then
            # Only one field present
            echo "$RANDOM.50" >> "$file_path"
            echo "$RANDOM.75" >> "$file_path"
        fi
        # Empty header case - file has already been created with just an empty line
        
        echo -e "${YELLOW}  Generated: $file_name${NC}"
    done
    
    echo -e "${GREEN}✅ Price files with missing fields generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Promotion Files with Missing Fields
# =============================================================================
generate_promotion_files_with_missing_fields() {
    echo -e "${RED}🛑 Generating Promotion Files with Missing Fields...${NC}"
    
    # Define different combinations of missing fields
    # Required fields for promotion are: promotion_id, discount, start_date, end_date
    local promo_file_variants=(
        "discount,start_date,end_date"              # Missing promotion_id
        "promotion_id,start_date,end_date"          # Missing discount
        "promotion_id,discount,end_date"            # Missing start_date
        "promotion_id,discount,start_date"          # Missing end_date
        "start_date,end_date"                       # Missing promotion_id, discount
        "promotion_id,discount"                     # Missing start_date, end_date
        "discount,end_date"                         # Missing promotion_id, start_date
        "promotion_id"                              # Missing most fields
        "discount"                                  # Only one field present
        ""                                          # Empty header
    )
    
    # Generate random discounts and dates for test data
    discounts=("5%" "10%" "15%" "20%" "25%" "30%" "35%" "40%" "50%")
    
    # Generate random end date (7-30 days from start date)
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    # Generate a file for each variant
    for (( i=0; i<${#promo_file_variants[@]}; i++ )); do
        timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
        file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}_MISSING_FIELD_$i.csv"
        file_path="$MISSING_FIELDS_DIR/$file_name"
        
        # Create the file with the variant header
        header="${promo_file_variants[$i]}"
        echo "$header" > "$file_path"
        
        # Random promo data for testing
        promo1="PROMO00001"
        promo2="PROMO00002"
        discount1=${discounts[$((RANDOM % ${#discounts[@]}))]}
        discount2=${discounts[$((RANDOM % ${#discounts[@]}))]}
        
        # Add sample data based on which fields are present
        if [[ "$header" == *"promotion_id"* && "$header" == *"discount"* && "$header" == *"start_date"* && "$header" == *"end_date"* ]]; then
            # All fields present - just for reference, shouldn't happen in this function
            echo "$promo1,$discount1,$INPUT_DATE,$end_date" >> "$file_path"
            echo "$promo2,$discount2,$INPUT_DATE,$end_date" >> "$file_path"
        elif [[ "$header" == *"discount"* && "$header" == *"start_date"* && "$header" == *"end_date"* ]]; then
            # Missing promotion_id
            echo "$discount1,$INPUT_DATE,$end_date" >> "$file_path"
            echo "$discount2,$INPUT_DATE,$end_date" >> "$file_path"
        elif [[ "$header" == *"promotion_id"* && "$header" == *"start_date"* && "$header" == *"end_date"* ]]; then
            # Missing discount
            echo "$promo1,$INPUT_DATE,$end_date" >> "$file_path"
            echo "$promo2,$INPUT_DATE,$end_date" >> "$file_path"
        elif [[ "$header" == *"promotion_id"* && "$header" == *"discount"* && "$header" == *"end_date"* ]]; then
            # Missing start_date
            echo "$promo1,$discount1,$end_date" >> "$file_path"
            echo "$promo2,$discount2,$end_date" >> "$file_path"
        elif [[ "$header" == *"promotion_id"* && "$header" == *"discount"* && "$header" == *"start_date"* ]]; then
            # Missing end_date
            echo "$promo1,$discount1,$INPUT_DATE" >> "$file_path"
            echo "$promo2,$discount2,$INPUT_DATE" >> "$file_path"
        elif [[ "$header" == *"start_date"* && "$header" == *"end_date"* ]]; then
            # Missing promotion_id, discount
            echo "$INPUT_DATE,$end_date" >> "$file_path"
            echo "$INPUT_DATE,$end_date" >> "$file_path"
        elif [[ "$header" == *"promotion_id"* && "$header" == *"discount"* ]]; then
            # Missing start_date, end_date
            echo "$promo1,$discount1" >> "$file_path"
            echo "$promo2,$discount2" >> "$file_path"
        elif [[ "$header" == *"discount"* && "$header" == *"end_date"* ]]; then
            # Missing promotion_id, start_date
            echo "$discount1,$end_date" >> "$file_path"
            echo "$discount2,$end_date" >> "$file_path"
        elif [[ "$header" == *"promotion_id"* ]]; then
            # Missing most fields
            echo "$promo1" >> "$file_path"
            echo "$promo2" >> "$file_path"
        elif [[ "$header" == *"discount"* ]]; then
            # Only one field present
            echo "$discount1" >> "$file_path"
            echo "$discount2" >> "$file_path"
        fi
        # Empty header case - file has already been created with just an empty line
        
        echo -e "${YELLOW}  Generated: $file_name${NC}"
    done
    
    echo -e "${GREEN}✅ Promotion files with missing fields generated${NC}"
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
# FUNCTION: Upload files with missing fields to Docker SFTP Container
# =============================================================================
upload_missing_fields_files_to_docker() {
    echo -e "${BLUE}🚀 Uploading files with missing fields to Docker SFTP Container...${NC}"
    
    # Upload Price Files with missing fields
    echo -e "${YELLOW}📤 Uploading Price files with missing fields...${NC}"
    for file in $MISSING_FIELDS_DIR/TH_PRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Promotion Files with missing fields
    echo -e "${YELLOW}📤 Uploading Promotion files with missing fields...${NC}"
    for file in $MISSING_FIELDS_DIR/TH_PROMPRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ All files with missing fields uploaded to Docker container${NC}"
    
    # Fix ownership
    fix_ownership
}

# =============================================================================
# FUNCTION: Transfer Missing Fields Files from 1P → SOA → RPM
# =============================================================================
transfer_missing_fields_files() {
    echo -e "${BLUE}🚚 Transferring files with missing fields from 1P → SOA → RPM...${NC}"
    
    # Transfer from 1P to SOA
    echo -e "${YELLOW}🔄 Syncing 1P → SOA (price, promotion with missing fields)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        
        # 1P → SOA price
        for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*_MISSING_FIELD_*.csv; do
            base=\$(basename \"\$f\")
            [ -f $SFTP_SOA_PRICE/\$base ] || cp \"\$f\" $SFTP_SOA_PRICE/
            echo '  Transferred: '\$base
        done
        
        # 1P → SOA promotion
        for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*_MISSING_FIELD_*.csv; do
            base=\$(basename \"\$f\")
            [ -f $SFTP_SOA_PROMOTION/\$base ] || cp \"\$f\" $SFTP_SOA_PROMOTION/
            echo '  Transferred: '\$base
        done
    " || true

    # Transfer from SOA to RPM
    echo -e "${YELLOW}📦 Syncing SOA → RPM (files with missing fields)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        
        # SOA → RPM price
        for f in $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*_MISSING_FIELD_*.csv; do
            base=\$(basename \"\$f\")
            [ -f $SFTP_RPM_PROCESSED/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/
            echo '  Transferred: '\$base
        done
        
        # SOA → RPM promotion
        for f in $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*_MISSING_FIELD_*.csv; do
            base=\$(basename \"\$f\")
            [ -f $SFTP_RPM_PROCESSED/\$base ] || cp \"\$f\" $SFTP_RPM_PROCESSED/
            echo '  Transferred: '\$base
        done
    " || true

    echo -e "${GREEN}✅ Transfer of files with missing fields complete${NC}"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main_missing_fields() {
    echo -e "${BLUE}🏁 Starting missing fields file generation process...${NC}"
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
    
    # Generate files with missing fields
    generate_price_files_with_missing_fields
    generate_promotion_files_with_missing_fields
    
    # Upload files to Docker
    upload_missing_fields_files_to_docker
    
    # Transfer files through the pipeline (1P → SOA → RPM)
    transfer_missing_fields_files
    
    echo -e "${GREEN}🎉 Missing fields file generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing required fields validation${NC}"
    echo -e "${BLUE}📋 Local data stored in: $MISSING_FIELDS_DIR/${NC}"
}

# Run main function if not sourced
main_missing_fields "$@"
