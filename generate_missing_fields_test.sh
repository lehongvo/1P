#!/bin/bash

# =============================================================================
# MISSING FIELDS TEST GENERATOR
# =============================================================================
#
# This script generates files with missing required fields to test the
# validate_required_fields function in data processing pipelines
#
# USAGE:
#   ./generate_missing_fields_test.sh [YYYY-MM-DD] [--clean]
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

# Create missing fields test directory
MISSING_FIELDS_DIR="$BASE_DIR/$DATE_DIR_FORMAT/missing_fields_test"
mkdir -p "$MISSING_FIELDS_DIR"

echo -e "${BLUE}=== MISSING FIELDS TEST GENERATOR ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating files with missing fields for testing validation${NC}"

# =============================================================================
# FUNCTION: Start the test generation process
# =============================================================================
start_test_generation() {
    echo -e "${GREEN}🏁 Starting missing fields test generation...${NC}"
    echo -e "${BLUE}📅 Processing date: $INPUT_DATE${NC}"
    
    # Generate price files with missing fields
    generate_price_missing_fields
    
    # Generate promotion files with missing fields
    generate_promotion_missing_fields
    
    # Generate valid files for comparison
    generate_valid_files_for_comparison
    
    # Upload files to Docker container
    upload_to_docker_container
    
    # Fix file ownership in Docker
    fix_ownership
    
    # Execute complete transfer pipeline (1P → SOA → RPM)
    execute_complete_transfer_pipeline
    
    # Show completion message
    echo_completion_message
}

# =============================================================================
# FUNCTION: Generate Price Files with Missing Fields
# =============================================================================
generate_price_missing_fields() {
    echo -e "${RED}❌ Generating Price Files with Missing Fields...${NC}"
    
    # 1. Generate files missing item_id field
    echo -e "${YELLOW}  1. Creating price files missing item_id...${NC}"
    
    # Generate file 1 - missing item_id
    hour=$((5 + RANDOM % 8))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    missing_item_id_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    missing_item_id_price_path="$MISSING_FIELDS_DIR/$missing_item_id_price"
    
    # Create file without item_id column (missing item_id field) - match original format 
    echo "Price,Store,Date,Batch,Description" > "$missing_item_id_price_path"
    
    # Generate enough rows to ensure file size > 1MB to pass validation
    end_date_30=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
    for row in $(seq 1 25000); do
        price=$(echo "scale=2; $RANDOM/100 + 10" | bc)
        store_id="STORE$(printf '%02d' $((RANDOM % 10 + 1)))"
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="PRODUCT_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        echo "$price,$store_id,$INPUT_DATE,$batch_id,$description" >> "$missing_item_id_price_path"
    done
    echo -e "${GREEN}    Generated: $missing_item_id_price${NC}"
    
    # 2. Generate files missing price field
    echo -e "${YELLOW}  2. Creating price files missing price field...${NC}"
    
    # Generate file 2 - missing price
    sleep 1
    hour=$((6 + RANDOM % 7))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    missing_price_field="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    missing_price_field_path="$MISSING_FIELDS_DIR/$missing_price_field"
    
    # Create file without price column (missing price field) - match original format
    echo "Item,Store,Date,Batch,Description" > "$missing_price_field_path"
    
    # Generate enough rows to ensure file size > 1MB to pass validation
    end_date_30=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
    for row in $(seq 1 25000); do
        item_id="ITEM$(printf '%08d' $row)"
        store_id="STORE$(printf '%02d' $((RANDOM % 10 + 1)))"
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="PRODUCT_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        echo "$item_id,$store_id,$INPUT_DATE,$batch_id,$description" >> "$missing_price_field_path"
    done
    echo -e "${GREEN}    Generated: $missing_price_field${NC}"
    
    # 3. Generate files missing start_date field
    echo -e "${YELLOW}  3. Creating price files missing start_date...${NC}"
    
    # Generate file 3 - missing start_date
    sleep 1
    hour=$((7 + RANDOM % 6))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    missing_start_date_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    missing_start_date_price_path="$MISSING_FIELDS_DIR/$missing_start_date_price"
    
    # Create file without start_date column (missing start_date field) - match original format
    echo "Price,Item,Store,Batch,Description" > "$missing_start_date_price_path"
    
    # Generate enough rows to ensure file size > 1MB to pass validation
    end_date_30=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
    for row in $(seq 1 25000); do
        price=$(echo "scale=2; $RANDOM/100 + 10" | bc)
        item_id="ITEM$(printf '%08d' $row)"
        store_id="STORE$(printf '%02d' $((RANDOM % 10 + 1)))"
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="PRODUCT_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        echo "$price,$item_id,$store_id,$batch_id,$description" >> "$missing_start_date_price_path"
    done
    echo -e "${GREEN}    Generated: $missing_start_date_price${NC}"
    
    # 4. Generate files missing end_date field
    echo -e "${YELLOW}  4. Creating price files missing end_date...${NC}"
    
    # Generate file 4 - missing end_date
    sleep 1
    hour=$((8 + RANDOM % 5))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    missing_end_date_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    missing_end_date_price_path="$MISSING_FIELDS_DIR/$missing_end_date_price"
    
    # Create file without end_date column (missing end_date field) - match original format
    echo "Price,Item,Store,Date,Batch,Description" > "$missing_end_date_price_path"
    
    # Generate enough rows to ensure file size > 1MB to pass validation
    for row in $(seq 1 25000); do
        price=$(echo "scale=2; $RANDOM/100 + 10" | bc)
        item_id="ITEM$(printf '%08d' $row)"
        store_id="STORE$(printf '%02d' $((RANDOM % 10 + 1)))"
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="PRODUCT_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        echo "$price,$item_id,$store_id,$INPUT_DATE,$batch_id,$description" >> "$missing_end_date_price_path"
    done
    echo -e "${GREEN}    Generated: $missing_end_date_price${NC}"
    
    # 5. Generate files with empty required field values
    echo -e "${YELLOW}  5. Creating price files with empty required values...${NC}"
    
    # Generate file 5 - empty values
    sleep 1
    hour=$((9 + RANDOM % 4))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    empty_values_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    empty_values_price_path="$MISSING_FIELDS_DIR/$empty_values_price"
    
    # Create file with empty required field values - match original format
    echo "Price,Item,Store,Date,Batch,Description" > "$empty_values_price_path"
    
    # Generate enough rows to ensure file size > 1MB with some empty values for testing
    end_date_30=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
    for row in $(seq 1 25000); do
        price=$(echo "scale=2; $RANDOM/100 + 10" | bc)
        item_id="ITEM$(printf '%08d' $row)"
        store_id="STORE$(printf '%02d' $((RANDOM % 10 + 1)))"
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="PRODUCT_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        
        # Randomly make some fields empty (5% of rows for testing)
        if [ $((RANDOM % 20)) -eq 0 ]; then
            case $((RANDOM % 3)) in
                0) echo ",$item_id,$store_id,$INPUT_DATE,$batch_id,$description" >> "$empty_values_price_path" ;;  # Empty Price
                1) echo "$price,,$store_id,$INPUT_DATE,$batch_id,$description" >> "$empty_values_price_path" ;;  # Empty Item
                2) echo "$price,$item_id,$store_id,,$batch_id,$description" >> "$empty_values_price_path" ;;  # Empty Date
            esac
        else
            echo "$price,$item_id,$store_id,$INPUT_DATE,$batch_id,$description" >> "$empty_values_price_path"
        fi
    done
    echo -e "${GREEN}    Generated: $empty_values_price${NC}"
    
    echo -e "${GREEN}✅ Price files with missing fields generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Promotion Files with Missing Fields
# =============================================================================
generate_promotion_missing_fields() {
    echo -e "${RED}❌ Generating Promotion Files with Missing Fields...${NC}"
    
    days_to_add=$((7 + RANDOM % 24))
    end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    
    # 1. Generate promotion files missing promotion_id field
    echo -e "${YELLOW}  1. Creating promotion files missing promotion_id...${NC}"
    
    # Generate file 1 - missing promotion_id
    hour=$((10 + RANDOM % 3))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    missing_promo_id="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    missing_promo_id_path="$MISSING_FIELDS_DIR/$missing_promo_id"
    
    # Create file without promotion_id column (missing PromoID field) - match original format
    echo "Item,Discount,StartDate,EndDate,Batch,Description" > "$missing_promo_id_path"
    
    # Generate enough rows to ensure file size > 1MB to pass validation
    discounts=("5%" "10%" "15%" "20%" "25%" "30%" "35%" "40%" "50%")
    for row in $(seq 1 20000); do
        item_id="ITEM$(printf '%08d' $row)"
        discount_idx=$((RANDOM % ${#discounts[@]}))
        discount=${discounts[$discount_idx]}
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="PROMOTION_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        echo "$item_id,$discount,$INPUT_DATE,$end_date,$batch_id,$description" >> "$missing_promo_id_path"
    done
    echo -e "${GREEN}    Generated: $missing_promo_id${NC}"
    
    # 2. Generate promotion files missing discount field
    echo -e "${YELLOW}  2. Creating promotion files missing discount field...${NC}"
    
    # Generate file 2 - missing discount
    sleep 1
    hour=$((11 + RANDOM % 3))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    missing_discount="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    missing_discount_path="$MISSING_FIELDS_DIR/$missing_discount"
    
    # Create file without discount column (missing Discount field) - match original format
    echo "PromoID,Item,StartDate,EndDate,Batch,Description" > "$missing_discount_path"
    
    # Generate enough rows to ensure file size > 1MB to pass validation
    for row in $(seq 1 20000); do
        promo_id="PROMO$(printf '%08d' $row)"
        item_id="ITEM$(printf '%08d' $row)"
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="PROMOTION_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        echo "$promo_id,$item_id,$INPUT_DATE,$end_date,$batch_id,$description" >> "$missing_discount_path"
    done
    echo -e "${GREEN}    Generated: $missing_discount${NC}"
    
    # 3. Generate promotion files with multiple missing fields
    echo -e "${YELLOW}  3. Creating promotion files with multiple missing fields...${NC}"
    
    # Generate file 3 - multiple missing fields
    sleep 1
    hour=$((12 + RANDOM % 3))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    multiple_missing="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    multiple_missing_path="$MISSING_FIELDS_DIR/$multiple_missing"
    
    # Create file with multiple missing fields - match original format (only PromoID column)
    echo "PromoID" > "$multiple_missing_path"
    
    # Generate enough rows to ensure file size > 1MB to pass validation
    for row in $(seq 1 25000); do
        promo_id="PROMO$(printf '%08d' $row)"
        echo "$promo_id" >> "$multiple_missing_path"
    done
    echo -e "${GREEN}    Generated: $multiple_missing${NC}"
    
    # 4. Generate promotion files with empty required values
    echo -e "${YELLOW}  4. Creating promotion files with empty required values...${NC}"
    
    # Generate file 4 - empty values
    sleep 1
    hour=$((13 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    empty_values_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    empty_values_promo_path="$MISSING_FIELDS_DIR/$empty_values_promo"
    
    # Create file with empty required values - match original format
    echo "PromoID,Item,Discount,StartDate,EndDate,Batch,Description" > "$empty_values_promo_path"
    
    # Generate enough rows to ensure file size > 1MB with some empty values for testing
    discounts=("5%" "10%" "15%" "20%" "25%" "30%" "35%" "40%" "50%")
    for row in $(seq 1 20000); do
        promo_id="PROMO$(printf '%08d' $row)"
        item_id="ITEM$(printf '%08d' $row)"
        discount_idx=$((RANDOM % ${#discounts[@]}))
        discount=${discounts[$discount_idx]}
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="PROMOTION_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        
        # Randomly make some fields empty (5% of rows for testing)
        if [ $((RANDOM % 20)) -eq 0 ]; then
            case $((RANDOM % 3)) in
                0) echo ",$item_id,$discount,$INPUT_DATE,$end_date,$batch_id,$description" >> "$empty_values_promo_path" ;;  # Empty PromoID
                1) echo "$promo_id,,$discount,$INPUT_DATE,$end_date,$batch_id,$description" >> "$empty_values_promo_path" ;;  # Empty Item
                2) echo "$promo_id,$item_id,,$INPUT_DATE,$end_date,$batch_id,$description" >> "$empty_values_promo_path" ;;  # Empty Discount
            esac
        else
            echo "$promo_id,$item_id,$discount,$INPUT_DATE,$end_date,$batch_id,$description" >> "$empty_values_promo_path"
        fi
    done
    echo -e "${GREEN}    Generated: $empty_values_promo${NC}"
    
    echo -e "${GREEN}✅ Promotion files with missing fields generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Valid Files for Comparison
# =============================================================================
generate_valid_files_for_comparison() {
    echo -e "${GREEN}✅ Generating Valid Files for Comparison...${NC}"
    
    # 1. Generate valid price file
    echo -e "${YELLOW}  1. Creating valid price file for comparison...${NC}"
    
    # Generate valid price file
    hour=$((14 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    valid_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    valid_price_path="$MISSING_FIELDS_DIR/$valid_price"
    
    # Create valid file with all required fields - match original format
    echo "Price,Item,Store,Date,Batch,Description" > "$valid_price_path"
    
    # Generate enough rows to ensure file size > 1MB to pass validation
    valid_end_date=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
    for row in $(seq 1 25000); do
        price=$(echo "scale=2; $RANDOM/100 + 10" | bc)
        item_id="VALID_ITEM$(printf '%08d' $row)"
        store_id="STORE$(printf '%02d' $((RANDOM % 10 + 1)))"
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="PRODUCT_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        echo "$price,$item_id,$store_id,$INPUT_DATE,$batch_id,$description" >> "$valid_price_path"
    done
    echo -e "${GREEN}    Generated: $valid_price${NC}"
    
    # 2. Generate valid promotion file
    echo -e "${YELLOW}  2. Creating valid promotion file for comparison...${NC}"
    
    # Generate valid promotion file
    days_to_add=$((7 + RANDOM % 24))
    end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    
    sleep 1
    hour=$((15 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    valid_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    valid_promo_path="$MISSING_FIELDS_DIR/$valid_promo"
    
    # Create valid file with all required fields - match original format
    echo "PromoID,Item,Discount,StartDate,EndDate,Batch,Description" > "$valid_promo_path"
    
    # Generate enough rows to ensure file size > 1MB to pass validation
    discounts=("5%" "10%" "15%" "20%" "25%" "30%" "35%" "40%" "50%")
    for row in $(seq 1 20000); do
        promo_id="VALID_PROMO$(printf '%08d' $row)"
        item_id="ITEM$(printf '%08d' $row)"
        discount_idx=$((RANDOM % ${#discounts[@]}))
        discount=${discounts[$discount_idx]}
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="PROMOTION_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        echo "$promo_id,$item_id,$discount,$INPUT_DATE,$end_date,$batch_id,$description" >> "$valid_promo_path"
    done
    echo -e "${GREEN}    Generated: $valid_promo${NC}"
    
    echo -e "${GREEN}✅ Valid comparison files generated${NC}"
    
    # Show file summary instead of size validation
    show_file_summary
}

# =============================================================================
# FUNCTION: Show File Summary
# =============================================================================
show_file_summary() {
    echo -e "${BLUE}📋 Test files summary:${NC}"
    
    local file_count=0
    for file in $MISSING_FIELDS_DIR/*.csv; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            file_count=$((file_count + 1))
            echo -e "${GREEN}  ✓ $filename${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Generated $file_count test files for validate_required_fields testing${NC}"
    echo -e "${BLUE}💡 Files are small and focused on missing fields validation only${NC}"
}

# =============================================================================
# FUNCTION: Upload test files to Docker container
# =============================================================================
upload_to_docker_container() {
    echo -e "${GREEN}🚀 Uploading missing fields test files...${NC}"
    
    # Clean existing files if requested
    if [ $CLEAN_DOCKER -eq 1 ]; then
        echo -e "${YELLOW}🧹 Cleaning existing files from Docker container...${NC}"
        docker exec $DOCKER_CONTAINER rm -f $SFTP_1P_PRICE/TH_PRCH_*.ods >/dev/null 2>&1 || true
        docker exec $DOCKER_CONTAINER rm -f $SFTP_1P_PROMOTION/TH_PROMPRCH_*.ods >/dev/null 2>&1 || true
        echo -e "${GREEN}✅ Cleaned existing files${NC}"
    fi
    
    # Upload Price Files to 1P
    echo -e "${YELLOW}📤 Uploading Price files with missing fields...${NC}"
    for file in $MISSING_FIELDS_DIR/TH_PRCH_*.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Promotion Files to 1P
    echo -e "${YELLOW}📤 Uploading Promotion files with missing fields...${NC}"
    for file in $MISSING_FIELDS_DIR/TH_PROMPRCH_*.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ All missing fields test files uploaded${NC}"
}


# =============================================================================
# FUNCTION: Display completion message
# =============================================================================
echo_completion_message() {
    echo -e "${GREEN}🎉 Missing fields test generation completed!${NC}"
    echo -e "${BLUE}💡 Files ready for testing missing fields validation${NC}"
    echo -e "${YELLOW}📋 Local data stored in: $MISSING_FIELDS_DIR/${NC}"
    
    echo -e "${BLUE}🔍 Missing fields test scenarios created:${NC}"
    echo -e "  • Missing item_id field"
    echo -e "  • Missing price field"
    echo -e "  • Missing start_date field"
    echo -e "  • Missing end_date field"
    echo -e "  • Missing promotion_id field"
    echo -e "  • Missing discount field"
    echo -e "  • Empty required field values"
    echo -e "  • Valid files for comparison"
}

# =============================================================================
# FUNCTION: Transfer files from 1P to SOA
# =============================================================================
transfer_1p_to_soa() {
    echo -e "${BLUE}🔄 Transferring files from 1P → SOA...${NC}"
    
    # Transfer price files
    echo -e "${YELLOW}📤 Transferring price files (1P → SOA)...${NC}"
    docker exec $DOCKER_CONTAINER bash -lc "
        shopt -s nullglob
        for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}${timestamp}.ods $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
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
        for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
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
        for f in $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}${timestamp}.ods $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
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
        for f in $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
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

# Start the test generation process
start_test_generation






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
