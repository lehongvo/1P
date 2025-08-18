#!/bin/bash

# =============================================================================
# SIMPLE INVALID FORMAT TEST GENERATOR
# =============================================================================
#
# This script generates ONLY files with invalid formats to test the
# validate_file_format_ops function. All other validations should pass.
#
# FOCUS: Only test file extension and UTF-8 encoding validation
#
# USAGE:
#   ./generate_simple_invalid_format_test.sh [YYYY-MM-DD] [--clean]
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
SIMPLE_FORMAT_DIR="$BASE_DIR/$DATE_DIR_FORMAT/simple_format_test"
mkdir -p "$SIMPLE_FORMAT_DIR"

echo -e "${BLUE}=== SIMPLE INVALID FORMAT TEST GENERATOR ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}🎯 Focus: ONLY testing validate_file_format_ops${NC}"

# =============================================================================
# FUNCTION: Generate Invalid Format Files (Simple Version)
# =============================================================================
generate_simple_invalid_format_files() {
    echo -e "${RED}❌ Generating files with INVALID FORMATS only...${NC}"
    
    # 1. Generate .txt files (Invalid extension)
    echo -e "${YELLOW}  1. Creating .txt files (invalid extension)...${NC}"
    
    # TXT Price file
    hour=$((10 + RANDOM % 3))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    txt_price="TH_PRCH_${DATE_PATTERN}${timestamp}.txt"
    txt_price_path="$SIMPLE_FORMAT_DIR/$txt_price"
    
    # Create proper CSV content with .txt extension - will fail extension validation
    echo "Price,Item,Store,Date,Batch,Description" > "$txt_price_path"
    for row in $(seq 1 2000); do
        price=$(echo "scale=2; 50 + $RANDOM/1000" | bc)
        item_id="ITEM$(printf '%08d' $row)"
        store_id="STORE01"
        batch_id="BATCH_${timestamp}"
        description="Product Description $row"
        echo "$price,$item_id,$store_id,$INPUT_DATE,$batch_id,$description" >> "$txt_price_path"
    done
    echo -e "${RED}    Generated: $txt_price (Extension Error)${NC}"
    
    # TXT Promotion file
    sleep 1
    hour=$((11 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    txt_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.txt"
    txt_promo_path="$SIMPLE_FORMAT_DIR/$txt_promo"
    
    end_date=$(date -d "$INPUT_DATE + 15 days" +%Y-%m-%d)
    echo "PromoID,Item,Discount,StartDate,EndDate,Batch,Description" > "$txt_promo_path"
    for row in $(seq 1 2000); do
        promo_id="PROMO$(printf '%08d' $row)"
        item_id="ITEM$(printf '%08d' $row)"
        discount="10%"
        batch_id="BATCH_${timestamp}"
        description="Promotion Description $row"
        echo "$promo_id,$item_id,$discount,$INPUT_DATE,$end_date,$batch_id,$description" >> "$txt_promo_path"
    done
    echo -e "${RED}    Generated: $txt_promo (Extension Error)${NC}"
    
    # 2. Generate .doc files (Invalid extension)
    echo -e "${YELLOW}  2. Creating .doc files (invalid extension)...${NC}"
    
    # DOC Price file
    sleep 1
    hour=$((12 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    doc_price="TH_PRCH_${DATE_PATTERN}${timestamp}.doc"
    doc_price_path="$SIMPLE_FORMAT_DIR/$doc_price"
    
    echo "Price,Item,Store,Date,Batch,Description" > "$doc_price_path"
    for row in $(seq 1 2000); do
        price=$(echo "scale=2; 50 + $RANDOM/1000" | bc)
        item_id="ITEM$(printf '%08d' $row)"
        store_id="STORE01"
        batch_id="BATCH_${timestamp}"
        description="Product Description $row"
        echo "$price,$item_id,$store_id,$INPUT_DATE,$batch_id,$description" >> "$doc_price_path"
    done
    echo -e "${RED}    Generated: $doc_price (Extension Error)${NC}"
    
    # DOC Promotion file
    sleep 1
    hour=$((13 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    doc_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.doc"
    doc_promo_path="$SIMPLE_FORMAT_DIR/$doc_promo"
    
    echo "PromoID,Item,Discount,StartDate,EndDate,Batch,Description" > "$doc_promo_path"
    for row in $(seq 1 2000); do
        promo_id="PROMO$(printf '%08d' $row)"
        item_id="ITEM$(printf '%08d' $row)"
        discount="10%"
        batch_id="BATCH_${timestamp}"
        description="Promotion Description $row"
        echo "$promo_id,$item_id,$discount,$INPUT_DATE,$end_date,$batch_id,$description" >> "$doc_promo_path"
    done
    echo -e "${RED}    Generated: $doc_promo (Extension Error)${NC}"
    
    # 3. Generate Non-UTF8 encoded files (Invalid encoding)
    echo -e "${YELLOW}  3. Creating non-UTF8 files (encoding error)...${NC}"
    
    # Non-UTF8 Price file
    sleep 1
    hour=$((14 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    nonutf8_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    nonutf8_price_path="$SIMPLE_FORMAT_DIR/$nonutf8_price"
    
    # Create temp file first
    temp_file="${nonutf8_price_path}.tmp"
    echo "Price,Item,Store,Date,Batch,Description" > "$temp_file"
    for row in $(seq 1 2000); do
        price=$(echo "scale=2; 50 + $RANDOM/1000" | bc)
        item_id="ITEM$(printf '%08d' $row)"
        store_id="STORE01"
        batch_id="BATCH_${timestamp}"
        # Add special characters that will cause UTF-8 issues
        description="Prodüct Déscriptiön $row with ñón-UTF8 çhars €£¥"
        echo "$price,$item_id,$store_id,$INPUT_DATE,$batch_id,$description" >> "$temp_file"
    done
    
    # Convert to non-UTF8 or add invalid bytes
    if command -v iconv >/dev/null 2>&1; then
        iconv -f UTF-8 -t ISO-8859-1 "$temp_file" > "$nonutf8_price_path" 2>/dev/null || {
            cp "$temp_file" "$nonutf8_price_path"
            printf '\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89' >> "$nonutf8_price_path"
        }
    else
        cp "$temp_file" "$nonutf8_price_path"
        printf '\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89' >> "$nonutf8_price_path"
    fi
    rm -f "$temp_file"
    echo -e "${RED}    Generated: $nonutf8_price (UTF-8 Error)${NC}"
    
    # Non-UTF8 Promotion file
    sleep 1
    hour=$((15 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    nonutf8_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    nonutf8_promo_path="$SIMPLE_FORMAT_DIR/$nonutf8_promo"
    
    temp_file="${nonutf8_promo_path}.tmp"
    echo "PromoID,Item,Discount,StartDate,EndDate,Batch,Description" > "$temp_file"
    for row in $(seq 1 2000); do
        promo_id="PROMO$(printf '%08d' $row)"
        item_id="ITEM$(printf '%08d' $row)"
        discount="10%"
        batch_id="BATCH_${timestamp}"
        description="Promötiön Déscriptiön $row with ñón-UTF8 çhars €£¥"
        echo "$promo_id,$item_id,$discount,$INPUT_DATE,$end_date,$batch_id,$description" >> "$temp_file"
    done
    
    if command -v iconv >/dev/null 2>&1; then
        iconv -f UTF-8 -t ISO-8859-1 "$temp_file" > "$nonutf8_promo_path" 2>/dev/null || {
            cp "$temp_file" "$nonutf8_promo_path"
            printf '\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89' >> "$nonutf8_promo_path"
        }
    else
        cp "$temp_file" "$nonutf8_promo_path"
        printf '\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89' >> "$nonutf8_promo_path"
    fi
    rm -f "$temp_file"
    echo -e "${RED}    Generated: $nonutf8_promo (UTF-8 Error)${NC}"
    
    echo -e "${GREEN}✅ Invalid format files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate VALID files (All other validations should PASS)
# =============================================================================
generate_valid_files_for_other_tests() {
    echo -e "${GREEN}✅ Generating VALID files (other validations should pass)...${NC}"
    
    # Valid Price file - LARGE enough for file size validation
    echo -e "${YELLOW}  1. Creating valid price file (all validations pass)...${NC}"
    
    hour=$((16 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    valid_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    valid_price_path="$SIMPLE_FORMAT_DIR/$valid_price"
    
    # Proper CSV header matching original format
    echo "Price,Item,Store,Date,Batch,Description" > "$valid_price_path"
    
    # Generate enough data to ensure file > 1MB (for file size validation to pass)
    for row in $(seq 1 25000); do
        price=$(echo "scale=2; 50 + $RANDOM/1000" | bc)
        item_id="VALID_ITEM$(printf '%08d' $row)"
        store_id="STORE$(printf '%02d' $((RANDOM % 10 + 1)))"
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="VALID_PRODUCT_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE_FOR_VALIDATION"
        echo "$price,$item_id,$store_id,$INPUT_DATE,$batch_id,$description" >> "$valid_price_path"
    done
    echo -e "${GREEN}    Generated: $valid_price (All validations should pass)${NC}"
    
    # Valid Promotion file - LARGE enough for file size validation
    echo -e "${YELLOW}  2. Creating valid promotion file (all validations pass)...${NC}"
    
    sleep 1
    hour=$((17 + RANDOM % 2))
    minute=$((RANDOM % 60))
    second=$((RANDOM % 60))
    timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
    valid_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    valid_promo_path="$SIMPLE_FORMAT_DIR/$valid_promo"
    
    end_date=$(date -d "$INPUT_DATE + 15 days" +%Y-%m-%d)
    echo "PromoID,Item,Discount,StartDate,EndDate,Batch,Description" > "$valid_promo_path"
    
    # Generate enough data for file size validation
    for row in $(seq 1 20000); do
        promo_id="VALID_PROMO$(printf '%08d' $row)"
        item_id="VALID_ITEM$(printf '%08d' $row)"
        discount="10%"
        batch_id="BATCH_${timestamp}_$(printf '%04d' $row)"
        description="VALID_PROMOTION_DESCRIPTION_$(printf '%08d' $row)_WITH_ADDITIONAL_DATA_TO_INCREASE_FILE_SIZE_FOR_VALIDATION"
        echo "$promo_id,$item_id,$discount,$INPUT_DATE,$end_date,$batch_id,$description" >> "$valid_promo_path"
    done
    echo -e "${GREEN}    Generated: $valid_promo (All validations should pass)${NC}"
    
    echo -e "${GREEN}✅ Valid files for other tests generated${NC}"
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
    for file in $SIMPLE_FORMAT_DIR/TH_PRCH_*; do
        if [ -f "$file" ]; then
            docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1
            filename=$(basename "$file")
            if [[ "$filename" == *"VALID_"* ]]; then
                echo -e "${GREEN}  ✓ $filename (Should pass all validations)${NC}"
            else
                echo -e "${RED}  ✗ $filename (Should fail format validation)${NC}"
            fi
        fi
    done
    
    # Upload promotion files
    echo -e "${YELLOW}📤 Uploading promotion files...${NC}"
    for file in $SIMPLE_FORMAT_DIR/TH_PROMPRCH_*; do
        if [ -f "$file" ]; then
            docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1
            filename=$(basename "$file")
            if [[ "$filename" == *"VALID_"* ]]; then
                echo -e "${GREEN}  ✓ $filename (Should pass all validations)${NC}"
            else
                echo -e "${RED}  ✗ $filename (Should fail format validation)${NC}"
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
    echo -e "${BLUE}📋 SIMPLE FORMAT TEST SUMMARY${NC}"
    echo -e "${YELLOW}📅 Date: $INPUT_DATE${NC}"
    echo -e "${YELLOW}📁 Local path: $SIMPLE_FORMAT_DIR/${NC}"
    
    echo -e "${RED}❌ Files that SHOULD FAIL format validation:${NC}"
    local fail_count=0
    for file in $SIMPLE_FORMAT_DIR/*.{txt,doc}; do
        [ -f "$file" ] && echo -e "${RED}  ✗ $(basename "$file")${NC}" && ((fail_count++))
    done
    for file in $SIMPLE_FORMAT_DIR/*.csv; do
        [ -f "$file" ] && [[ "$(basename "$file")" != *"VALID_"* ]] && echo -e "${RED}  ✗ $(basename "$file") (Non-UTF8)${NC}" && ((fail_count++))
    done
    
    echo -e "${GREEN}✅ Files that SHOULD PASS all validations:${NC}"
    local pass_count=0
    for file in $SIMPLE_FORMAT_DIR/*VALID_*.csv; do
        [ -f "$file" ] && echo -e "${GREEN}  ✓ $(basename "$file")${NC}" && ((pass_count++))
    done
    
    echo -e "${BLUE}📊 Total: $((fail_count + pass_count)) files generated${NC}"
    echo -e "${RED}   - $fail_count should fail format validation${NC}"
    echo -e "${GREEN}   - $pass_count should pass all validations${NC}"
    
    echo -e "${YELLOW}🎯 TESTING FOCUS: validate_file_format_ops only${NC}"
    echo -e "${YELLOW}💡 Other validations (required fields, data types, file size) should pass${NC}"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
echo -e "${GREEN}🏁 Starting simple invalid format test generation...${NC}"

# Generate invalid format files (will fail format validation)
generate_simple_invalid_format_files

# Generate valid files (will pass all validations)
generate_valid_files_for_other_tests

# Upload to Docker
upload_files_to_docker

# Fix ownership
fix_ownership

# Show summary
show_test_summary

echo -e "${GREEN}🎉 Simple format test completed!${NC}"
echo -e "${BLUE}💡 Ready to test validate_file_format_ops function${NC}"
