#!/bin/bash

# =============================================================================
# CORRECTED INVALID DATA TYPES TEST GENERATOR
# =============================================================================
#
# This script generates files with EXACT field names from UPLOAD_VALIDATION_CONFIG
# to test validate_data_types_ops function properly.
#
# FIELD NAMES that will be validated:
# - item_id: string 
# - price: numeric (must be float)
# - start_date: date (must be YYYY-MM-DD, DD/MM/YYYY, or YYYYMMDD)
# - end_date: date (must be YYYY-MM-DD, DD/MM/YYYY, or YYYYMMDD)
# - discount: numeric (must be float) 
#
# USAGE:
#   ./generate_corrected_invalid_datatypes_test.sh [YYYY-MM-DD] [--clean]
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

# Parse arguments
CLEAN_DOCKER=0
INPUT_DATE=""

for arg in "$@"; do
    if [[ "$arg" == "--clean" ]]; then
        CLEAN_DOCKER=1
    elif [[ "$arg" == "--source-only" ]]; then
        continue
    elif [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        INPUT_DATE="$arg"
        if ! parse_date "$INPUT_DATE" "+%Y-%m-%d" >/dev/null; then
            echo -e "${RED}❌ Error: Invalid date '$INPUT_DATE'${NC}"
            exit 1
        fi
    elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        echo -e "${YELLOW}Usage: $0 [YYYY-MM-DD] [--clean]${NC}"
        exit 0
    fi
done

# Use current date if not provided
if [ -z "$INPUT_DATE" ]; then
    INPUT_DATE=$(date +%Y-%m-%d)
fi

# Generate date formats
DATE_PATTERN=$(parse_date "$INPUT_DATE" "+%Y%m%d")
DATE_DIR_FORMAT="$INPUT_DATE"

# Create test directory
CORRECTED_DIR="$BASE_DIR/$DATE_DIR_FORMAT/corrected_datatypes_test"
mkdir -p "$CORRECTED_DIR"

echo -e "${BLUE}=== CORRECTED INVALID DATA TYPES TEST GENERATOR ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}🎯 Focus: Testing validate_data_types_ops with EXACT field names${NC}"

# =============================================================================
# FUNCTION: Generate Invalid Data Types Files (Price Domain)
# =============================================================================
generate_invalid_price_datatypes() {
    echo -e "${RED}❌ Generating PRICE files with invalid data types...${NC}"
    
    # 1. Price file with invalid "price" field (numeric validation)
    echo -e "${YELLOW}  1. Creating price file with invalid numeric 'price' field...${NC}"
    
    hour=$((10 + RANDOM % 3))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    invalid_price_numeric="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    invalid_price_numeric_path="$CORRECTED_DIR/$invalid_price_numeric"
    
    # Use EXACT field names from config: item_id, price, start_date, end_date
    echo "item_id,price,start_date,end_date,store,batch,description" > "$invalid_price_numeric_path"
    end_date=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
    
    for row in $(seq 1 2000); do
        item_id="ITEM$(printf '%08d' $row)"
        store="STORE01"
        batch="BATCH_${timestamp}"
        description="Product Description $row"
        
        # Mix valid and invalid PRICE values (numeric validation)
        if [ $((row % 5)) -eq 0 ]; then
            price="INVALID_PRICE_TEXT"  # Invalid: text
        elif [ $((row % 7)) -eq 0 ]; then
            price=""                    # Invalid: empty
        elif [ $((row % 11)) -eq 0 ]; then
            price="$@#%^"              # Invalid: special chars
        elif [ $((row % 13)) -eq 0 ]; then
            price="TWENTY_DOLLARS"      # Invalid: text with meaning
        else
            price=$(echo "scale=2; 50 + $RANDOM/1000" | bc)  # Valid: numeric
        fi
        
        echo "$item_id,$price,$INPUT_DATE,$end_date,$store,$batch,$description" >> "$invalid_price_numeric_path"
    done
    echo -e "${RED}    Generated: $invalid_price_numeric (Invalid numeric 'price')${NC}"
    
    # 2. Price file with invalid "start_date" field (date validation)
    echo -e "${YELLOW}  2. Creating price file with invalid 'start_date' field...${NC}"
    
    sleep 1
    hour=$((11 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    invalid_start_date="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    invalid_start_date_path="$CORRECTED_DIR/$invalid_start_date"
    
    echo "item_id,price,start_date,end_date,store,batch,description" > "$invalid_start_date_path"
    
    for row in $(seq 1 2000); do
        item_id="ITEM$(printf '%08d' $row)"
        price=$(echo "scale=2; 50 + $RANDOM/1000" | bc)
        store="STORE01"
        batch="BATCH_${timestamp}"
        description="Product Description $row"
        end_date=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
        
        # Mix valid and invalid START_DATE values (date validation)
        if [ $((row % 5)) -eq 0 ]; then
            start_date="INVALID_START_DATE"     # Invalid: text
        elif [ $((row % 7)) -eq 0 ]; then
            start_date=""                       # Invalid: empty
        elif [ $((row % 11)) -eq 0 ]; then
            start_date="31-12-2025"            # Invalid: unsupported format
        elif [ $((row % 13)) -eq 0 ]; then
            start_date="2025-13-45"            # Invalid: impossible date
        else
            start_date="$INPUT_DATE"            # Valid: YYYY-MM-DD format
        fi
        
        echo "$item_id,$price,$start_date,$end_date,$store,$batch,$description" >> "$invalid_start_date_path"
    done
    echo -e "${RED}    Generated: $invalid_start_date (Invalid date 'start_date')${NC}"
    
    # 3. Price file with invalid "end_date" field (date validation)
    echo -e "${YELLOW}  3. Creating price file with invalid 'end_date' field...${NC}"
    
    sleep 1
    hour=$((12 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    invalid_end_date="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    invalid_end_date_path="$CORRECTED_DIR/$invalid_end_date"
    
    echo "item_id,price,start_date,end_date,store,batch,description" > "$invalid_end_date_path"
    
    for row in $(seq 1 2000); do
        item_id="ITEM$(printf '%08d' $row)"
        price=$(echo "scale=2; 50 + $RANDOM/1000" | bc)
        start_date="$INPUT_DATE"
        store="STORE01"
        batch="BATCH_${timestamp}"
        description="Product Description $row"
        
        # Mix valid and invalid END_DATE values (date validation)
        if [ $((row % 5)) -eq 0 ]; then
            end_date="INVALID_END_DATE"        # Invalid: text
        elif [ $((row % 7)) -eq 0 ]; then
            end_date=""                        # Invalid: empty
        elif [ $((row % 11)) -eq 0 ]; then
            end_date="99/99/9999"             # Invalid: impossible date
        elif [ $((row % 13)) -eq 0 ]; then
            end_date="2025.12.31"             # Invalid: unsupported format
        else
            end_date=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)  # Valid
        fi
        
        echo "$item_id,$price,$start_date,$end_date,$store,$batch,$description" >> "$invalid_end_date_path"
    done
    echo -e "${RED}    Generated: $invalid_end_date (Invalid date 'end_date')${NC}"
    
    echo -e "${GREEN}✅ Price files with invalid data types generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Invalid Data Types Files (Promotion Domain) 
# =============================================================================
generate_invalid_promotion_datatypes() {
    echo -e "${RED}❌ Generating PROMOTION files with invalid data types...${NC}"
    
    # 1. Promotion file with invalid "discount" field (numeric validation)
    echo -e "${YELLOW}  1. Creating promotion file with invalid numeric 'discount' field...${NC}"
    
    sleep 1
    hour=$((13 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    invalid_discount="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    invalid_discount_path="$CORRECTED_DIR/$invalid_discount"
    
    # Use EXACT field names for promotion: promotion_id, discount, start_date, end_date
    echo "promotion_id,discount,start_date,end_date,item_id,store,batch,description" > "$invalid_discount_path"
    end_date=$(date -d "$INPUT_DATE + 15 days" +%Y-%m-%d)
    
    for row in $(seq 1 2000); do
        promotion_id="PROMO$(printf '%08d' $row)"
        item_id="ITEM$(printf '%08d' $row)"
        store="STORE01"
        batch="BATCH_${timestamp}"
        description="Promotion Description $row"
        
        # Mix valid and invalid DISCOUNT values (numeric validation)
        if [ $((row % 5)) -eq 0 ]; then
            discount="FIFTY_PERCENT"           # Invalid: text
        elif [ $((row % 7)) -eq 0 ]; then
            discount=""                        # Invalid: empty
        elif [ $((row % 11)) -eq 0 ]; then
            discount="@#$%^"                  # Invalid: special chars
        elif [ $((row % 13)) -eq 0 ]; then
            discount="10%"                     # Invalid: text with % (not pure numeric)
        else
            discount="10"                      # Valid: numeric (no % symbol)
        fi
        
        echo "$promotion_id,$discount,$INPUT_DATE,$end_date,$item_id,$store,$batch,$description" >> "$invalid_discount_path"
    done
    echo -e "${RED}    Generated: $invalid_discount (Invalid numeric 'discount')${NC}"
    
    # 2. Promotion file with mixed invalid dates (start_date, end_date)
    echo -e "${YELLOW}  2. Creating promotion file with invalid dates...${NC}"
    
    sleep 1
    hour=$((14 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    invalid_promo_dates="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    invalid_promo_dates_path="$CORRECTED_DIR/$invalid_promo_dates"
    
    echo "promotion_id,discount,start_date,end_date,item_id,store,batch,description" > "$invalid_promo_dates_path"
    
    for row in $(seq 1 2000); do
        promotion_id="PROMO$(printf '%08d' $row)"
        discount="10"  # Valid discount
        item_id="ITEM$(printf '%08d' $row)"
        store="STORE01"
        batch="BATCH_${timestamp}"
        description="Promotion Description $row"
        
        # Mix valid and invalid DATE values
        case $((row % 10)) in
            0)
                # Invalid start_date
                start_date="INVALID_START"
                end_date=$(date -d "$INPUT_DATE + 15 days" +%Y-%m-%d)
                ;;
            1)
                # Invalid end_date
                start_date="$INPUT_DATE"
                end_date="INVALID_END"
                ;;
            2)
                # Both invalid
                start_date="99/99/9999"
                end_date="31-13-2025"
                ;;
            3)
                # Empty dates
                start_date=""
                end_date=""
                ;;
            4)
                # Wrong format dates
                start_date="2025.01.15"
                end_date="15-Jan-2025"
                ;;
            *)
                # Valid dates
                start_date="$INPUT_DATE"
                end_date=$(date -d "$INPUT_DATE + 15 days" +%Y-%m-%d)
                ;;
        esac
        
        echo "$promotion_id,$discount,$start_date,$end_date,$item_id,$store,$batch,$description" >> "$invalid_promo_dates_path"
    done
    echo -e "${RED}    Generated: $invalid_promo_dates (Invalid dates)${NC}"
    
    echo -e "${GREEN}✅ Promotion files with invalid data types generated${NC}"
}

# =============================================================================
# FUNCTION: Generate VALID files (All validations should PASS)
# =============================================================================
generate_valid_files_for_other_tests() {
    echo -e "${GREEN}✅ Generating VALID files (all data types correct)...${NC}"
    
    # Valid Price file with correct field names and data types
    echo -e "${YELLOW}  1. Creating valid price file (all data types correct)...${NC}"
    
    hour=$((16 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    valid_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    valid_price_path="$CORRECTED_DIR/$valid_price"
    
    # Exact field names with all data types valid
    echo "item_id,price,start_date,end_date,store,batch,description" > "$valid_price_path"
    end_date=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
    
    # Generate enough data for file size validation (>1MB)
    for row in $(seq 1 25000); do
        item_id="VALID_ITEM$(printf '%08d' $row)"           # Valid: string
        price=$(echo "scale=2; 50 + $RANDOM/1000" | bc)     # Valid: numeric
        start_date="$INPUT_DATE"                             # Valid: date (YYYY-MM-DD)
        end_date_val=$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)  # Valid: date
        store="STORE$(printf '%02d' $((RANDOM % 10 + 1)))"
        batch="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="VALID_PRODUCT_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        echo "$item_id,$price,$start_date,$end_date_val,$store,$batch,$description" >> "$valid_price_path"
    done
    echo -e "${GREEN}    Generated: $valid_price (All data types valid)${NC}"
    
    # Valid Promotion file with correct field names and data types
    echo -e "${YELLOW}  2. Creating valid promotion file (all data types correct)...${NC}"
    
    sleep 1
    hour=$((17 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    valid_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    valid_promo_path="$CORRECTED_DIR/$valid_promo"
    
    # Exact field names with all data types valid
    echo "promotion_id,discount,start_date,end_date,item_id,store,batch,description" > "$valid_promo_path"
    end_date=$(date -d "$INPUT_DATE + 15 days" +%Y-%m-%d)
    
    # Generate enough data for file size validation (>1MB)
    for row in $(seq 1 20000); do
        promotion_id="VALID_PROMO$(printf '%08d' $row)"     # Valid: string
        discount="10"                                        # Valid: numeric (no % symbol)
        start_date="$INPUT_DATE"                             # Valid: date (YYYY-MM-DD)
        end_date_val=$(date -d "$INPUT_DATE + 15 days" +%Y-%m-%d)  # Valid: date
        item_id="VALID_ITEM$(printf '%08d' $row)"
        store="STORE$(printf '%02d' $((RANDOM % 10 + 1)))"
        batch="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="VALID_PROMOTION_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE"
        echo "$promotion_id,$discount,$start_date,$end_date_val,$item_id,$store,$batch,$description" >> "$valid_promo_path"
    done
    echo -e "${GREEN}    Generated: $valid_promo (All data types valid)${NC}"
    
    echo -e "${GREEN}✅ Valid files generated${NC}"
}

# =============================================================================
# FUNCTION: Upload files to Docker
# =============================================================================
upload_files_to_docker() {
    echo -e "${GREEN}🚀 Uploading test files to Docker...${NC}"
    
    # Clean if requested
    if [ $CLEAN_DOCKER -eq 1 ]; then
        echo -e "${YELLOW}🧹 Cleaning existing files...${NC}"
        docker exec $DOCKER_CONTAINER rm -f $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}* >/dev/null 2>&1 || true
        docker exec $DOCKER_CONTAINER rm -f $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}* >/dev/null 2>&1 || true
    fi
    
    # Upload price files
    echo -e "${YELLOW}📤 Uploading price files...${NC}"
    for file in $CORRECTED_DIR/TH_PRCH_*; do
        if [ -f "$file" ]; then
            docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1
            filename=$(basename "$file")
            if [[ "$filename" == *"VALID_"* ]]; then
                echo -e "${GREEN}  ✓ $filename (Valid data types)${NC}"
            else
                echo -e "${RED}  ✗ $filename (Invalid data types)${NC}"
            fi
        fi
    done
    
    # Upload promotion files
    echo -e "${YELLOW}📤 Uploading promotion files...${NC}"
    for file in $CORRECTED_DIR/TH_PROMPRCH_*; do
        if [ -f "$file" ]; then
            docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1
            filename=$(basename "$file")
            if [[ "$filename" == *"VALID_"* ]]; then
                echo -e "${GREEN}  ✓ $filename (Valid data types)${NC}"
            else
                echo -e "${RED}  ✗ $filename (Invalid data types)${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ All files uploaded${NC}"
}

# =============================================================================
# FUNCTION: Fix ownership
# =============================================================================
fix_ownership() {
    echo -e "${BLUE}🔧 Fixing file ownership...${NC}"
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory $SFTP_1P_PRICE 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "chown -R demo:sftp-user-inventory $SFTP_1P_PROMOTION 2>/dev/null || true"
    echo -e "${GREEN}✅ Ownership fixed${NC}"
}

# =============================================================================
# FUNCTION: Show summary
# =============================================================================
show_test_summary() {
    echo -e "${BLUE}📋 CORRECTED DATA TYPES TEST SUMMARY${NC}"
    echo -e "${YELLOW}📅 Date: $INPUT_DATE${NC}"
    echo -e "${YELLOW}📁 Local path: $CORRECTED_DIR/${NC}"
    
    echo -e "${RED}❌ Files that SHOULD FAIL data types validation:${NC}"
    local fail_count=0
    for file in $CORRECTED_DIR/*.csv; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [[ "$filename" != *"VALID_"* ]]; then
                echo -e "${RED}  ✗ $filename${NC}"
                ((fail_count++))
            fi
        fi
    done
    
    echo -e "${GREEN}✅ Files that SHOULD PASS all validations:${NC}"
    local pass_count=0
    for file in $CORRECTED_DIR/*VALID_*.csv; do
        [ -f "$file" ] && echo -e "${GREEN}  ✓ $(basename "$file")${NC}" && ((pass_count++))
    done
    
    echo -e "${BLUE}📊 Total: $((fail_count + pass_count)) files generated${NC}"
    echo -e "${RED}   - $fail_count should fail data types validation${NC}"
    echo -e "${GREEN}   - $pass_count should pass all validations${NC}"
    
    echo -e "${YELLOW}🎯 FIELD NAMES USED (exact match with config):${NC}"
    echo -e "${BLUE}   Price files: item_id, price, start_date, end_date${NC}"
    echo -e "${BLUE}   Promotion files: promotion_id, discount, start_date, end_date${NC}"
    
    echo -e "${YELLOW}🔍 Expected violations for fields:${NC}"
    echo -e "${RED}   • price (numeric): text, empty, special chars${NC}"
    echo -e "${RED}   • start_date (date): invalid formats, impossible dates${NC}" 
    echo -e "${RED}   • end_date (date): invalid formats, impossible dates${NC}"
    echo -e "${RED}   • discount (numeric): text, empty, special chars${NC}"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
echo -e "${GREEN}🏁 Starting corrected invalid data types test generation...${NC}"

# Generate invalid data types files for price domain
generate_invalid_price_datatypes

# Generate invalid data types files for promotion domain  
generate_invalid_promotion_datatypes

# Generate valid files (will pass all validations)
generate_valid_files_for_other_tests

# Upload to Docker
upload_files_to_docker

# Fix ownership
fix_ownership

# Show summary
show_test_summary

echo -e "${GREEN}🎉 Corrected data types test completed!${NC}"
echo -e "${BLUE}💡 Ready to test validate_data_types_ops function with exact field names${NC}"
