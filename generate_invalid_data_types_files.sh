#!/bin/bash

# =============================================================================
# INVALID DATA TYPES FILE GENERATOR FOR TESTING VALIDATION FAILURES
# =============================================================================
#
# This script generates CSV files with invalid data types to test the
# validate_data_types_ops function in data processing pipelines
#
# USAGE:
#   ./generate_invalid_data_types_files.sh [YYYY-MM-DD] [--clean]
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

# Create invalid data types directory
INVALID_TYPES_DIR="$BASE_DIR/$DATE_DIR_FORMAT/invalid_data_types"
mkdir -p "$INVALID_TYPES_DIR"

echo -e "${BLUE}=== INVALID DATA TYPES FILE GENERATOR FOR TESTING ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating files with invalid data types for testing validation${NC}"

# =============================================================================
# FUNCTION: Generate Price Files with Invalid Data Types
# =============================================================================
generate_price_files_with_invalid_data_types() {
    echo -e "${RED}🛑 Generating Price Files with Invalid Data Types...${NC}"
    
    # Define fields to test for data type violations
    # Based on the UPLOAD_VALIDATION_CONFIG that would be used in validate_data_types_ops
    local field_data_types=(
        "item_id:string:INVALID_123"      # Replace with non-string
        "price:numeric:NOT_A_NUMBER"      # Replace with non-numeric
        "start_date:date:INVALID_DATE"    # Replace with non-date
        "end_date:date:2025/99/99"        # Replace with invalid date format
    )
    
    # Generate a file for each field with invalid data type
    for field_info in "${field_data_types[@]}"; do
        # Split the field info using delimiter
        IFS=':' read -r field_name expected_type invalid_value <<< "$field_info"
        
        timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
        # Use standard filename format without any suffix that might confuse validation
        file_name="TH_PRCH_${DATE_PATTERN}${timestamp}.csv"
        file_path="$INVALID_TYPES_DIR/$file_name"
        
        # Create file with all required fields
        echo "item_id,price,start_date,end_date" > "$file_path"
        
        # Add fewer valid data rows and put invalid data at the beginning for better detection
        echo "ITEM001,$((100 + RANDOM % 900)).$((RANDOM % 99)),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
        
        # Add multiple rows with invalid data for the specific field at the beginning
        case $field_name in
            "item_id")
                # Add 5 invalid rows at the beginning
                for i in {1..5}; do
                    echo "$invalid_value,$((100 + RANDOM % 900)).$((RANDOM % 99)),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path.tmp"
                done
                ;;
            "price")
                # Add 5 invalid rows at the beginning
                for i in {1..5}; do
                    echo "ITEM00$i,$invalid_value,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path.tmp"
                done
                ;;
            "start_date")
                # Add 5 invalid rows at the beginning
                for i in {1..5}; do
                    echo "ITEM00$i,$((100 + RANDOM % 900)).$((RANDOM % 99)),$invalid_value,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path.tmp"
                done
                ;;
            "end_date")
                # Add 5 invalid rows at the beginning
                for i in {1..5}; do
                    echo "ITEM00$i,$((100 + RANDOM % 900)).$((RANDOM % 99)),$INPUT_DATE,$invalid_value" >> "$file_path.tmp"
                done
                ;;
        esac
        
        # Concatenate the temporary file with invalid rows first to the main file
        if [ -f "$file_path.tmp" ]; then
            cat "$file_path.tmp" "$file_path" > "$file_path.new"
            mv "$file_path.new" "$file_path"
            rm "$file_path.tmp"
        fi
        
        echo -e "${YELLOW}  Generated: $file_name (Invalid $field_name data type)${NC}"
    done
    
    # Create a file with multiple data type violations
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    # Use standard filename format
    file_name="TH_PRCH_${DATE_PATTERN}${timestamp}.csv"
    file_path="$INVALID_TYPES_DIR/$file_name"
    
    # Create header
    echo "item_id,price,start_date,end_date" > "$file_path"
    
    # Add only one valid data row and put invalid data rows first for better detection
    echo "ITEM001,$((100 + RANDOM % 900)).$((RANDOM % 99)),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path"
    
    # Add multiple rows with invalid data types at the beginning of the file
    # Create a temporary file with invalid data
    for i in {1..10}; do
        echo "INVALID_$i,NOT_A_NUMBER_$i,INVALID_DATE_$i,2025/99/99" >> "$file_path.tmp"
    done
    echo "ITEM0099,ABC123,$INPUT_DATE,TOMORROW" >> "$file_path.tmp"
    echo "12345,123.45,01/01/2025,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path.tmp"
    
    # Concatenate the temporary file with invalid rows first to the main file
    if [ -f "$file_path.tmp" ]; then
        cat "$file_path.tmp" "$file_path" > "$file_path.new"
        mv "$file_path.new" "$file_path"
        rm "$file_path.tmp"
    fi
    
    echo -e "${YELLOW}  Generated: $file_name (Multiple invalid data types)${NC}"
    
    # Create a file with mixed valid and invalid data
    timestamp=$(printf "%02d%02d%02d" $((5 + RANDOM % 8)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PRCH_${DATE_PATTERN}${timestamp}.csv"
    file_path="$INVALID_TYPES_DIR/$file_name"
    
    # Create header
    echo "item_id,price,start_date,end_date" > "$file_path"
    
    # Create a temporary file with invalid data at the beginning followed by some valid data
    echo "ITEM002,NOT_PRICE,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path.tmp"
    echo "ITEM003,200.75,INVALID_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path.tmp"
    echo "ITEM004,300.25,$INPUT_DATE,INVALID_END_DATE" >> "$file_path.tmp"
    echo "12345,400.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path.tmp"
    echo "ITEM006,ABC123.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path.tmp"
    echo "ITEM007,500.99,2025-13-32,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path.tmp"
    echo "ITEM008,600.75,$INPUT_DATE,2025-99-99" >> "$file_path.tmp"
    echo "INVALID_ID,NOT_PRICE,BAD_DATE,WRONG_END" >> "$file_path.tmp"
    echo "ITEM010,700.25,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$file_path.tmp"
    
    # Concatenate the temporary file with invalid rows first to the main file
    if [ -f "$file_path.tmp" ]; then
        cat "$file_path.tmp" "$file_path" > "$file_path.new"
        mv "$file_path.new" "$file_path"
        rm "$file_path.tmp"
    fi
    
    echo -e "${YELLOW}  Generated: $file_name (Mixed valid and invalid data types)${NC}"
    
    echo -e "${GREEN}✅ Price files with invalid data types generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Promotion Files with Invalid Data Types
# =============================================================================
generate_promotion_files_with_invalid_data_types() {
    echo -e "${RED}🛑 Generating Promotion Files with Invalid Data Types...${NC}"
    
    # Define fields to test for data type violations in promotion files
    local field_data_types=(
        "promotion_id:string:12345"        # Replace with numeric instead of string
        "discount:percentage:INVALID_PERC"  # Replace with non-percentage
        "start_date:date:NOT_A_DATE"        # Replace with non-date
        "end_date:date:2025/13/40"          # Replace with invalid date format
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
    
    # Generate a file for each field with invalid data type
    for field_info in "${field_data_types[@]}"; do
        # Split the field info using delimiter
        IFS=':' read -r field_name expected_type invalid_value <<< "$field_info"
        
        timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
        file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.csv"
        file_path="$INVALID_TYPES_DIR/$file_name"
        
        # Create file with all required fields
        echo "promotion_id,discount,start_date,end_date" > "$file_path"
        
        # Add only one valid data row for better detection of invalid data
        discount=${discounts[$((RANDOM % ${#discounts[@]}))]}
        echo "PROMO001,$discount,$INPUT_DATE,$end_date" >> "$file_path"
        
        # Add multiple rows with invalid data for the specific field at the beginning
        case $field_name in
            "promotion_id")
                # Add 5 invalid rows at the beginning
                for i in {1..5}; do
                    echo "$invalid_value,${discounts[$((RANDOM % ${#discounts[@]}))]},$INPUT_DATE,$end_date" >> "$file_path.tmp"
                done
                ;;
            "discount")
                # Add 5 invalid rows at the beginning
                for i in {1..5}; do
                    echo "PROMO00$i,$invalid_value,$INPUT_DATE,$end_date" >> "$file_path.tmp"
                done
                ;;
            "start_date")
                # Add 5 invalid rows at the beginning
                for i in {1..5}; do
                    echo "PROMO00$i,${discounts[$((RANDOM % ${#discounts[@]}))]},$invalid_value,$end_date" >> "$file_path.tmp"
                done
                ;;
            "end_date")
                # Add 5 invalid rows at the beginning
                for i in {1..5}; do
                    echo "PROMO00$i,${discounts[$((RANDOM % ${#discounts[@]}))]},$INPUT_DATE,$invalid_value" >> "$file_path.tmp"
                done
                ;;
        esac
        
        # Concatenate the temporary file with invalid rows first to the main file
        if [ -f "$file_path.tmp" ]; then
            cat "$file_path.tmp" "$file_path" > "$file_path.new"
            mv "$file_path.new" "$file_path"
            rm "$file_path.tmp"
        fi
        
        echo -e "${YELLOW}  Generated: $file_name (Invalid $field_name data type)${NC}"
    done
    
    # Create a file with multiple data type violations
    timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.csv"
    file_path="$INVALID_TYPES_DIR/$file_name"
    
    # Create header
    echo "promotion_id,discount,start_date,end_date" > "$file_path"
    
    # Add only one valid data row for better detection of invalid data
    discount=${discounts[$((RANDOM % ${#discounts[@]}))]}
    echo "PROMO001,$discount,$INPUT_DATE,$end_date" >> "$file_path"
    
    # Add multiple rows with invalid data types at the beginning of the file
    # Create a temporary file with invalid data
    for i in {1..10}; do
        echo "12345,INVALID_PERC_$i,NOT_A_DATE_$i,2025/13/40" >> "$file_path.tmp"
    done
    echo "PROMO099,123.45,$INPUT_DATE,TOMORROW" >> "$file_path.tmp"
    echo "ABC-123,abc%,01/01/2025,$end_date" >> "$file_path.tmp"
    
    # Concatenate the temporary file with invalid rows first to the main file
    if [ -f "$file_path.tmp" ]; then
        cat "$file_path.tmp" "$file_path" > "$file_path.new"
        mv "$file_path.new" "$file_path"
        rm "$file_path.tmp"
    fi
    
    echo -e "${YELLOW}  Generated: $file_name (Multiple invalid data types)${NC}"
    
    # Create a file with mixed valid and invalid data
    timestamp=$(printf "%02d%02d%02d" $((6 + RANDOM % 7)) $((RANDOM % 60)) $((RANDOM % 60)))
    file_name="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.csv"
    file_path="$INVALID_TYPES_DIR/$file_name"
    
    # Create header
    echo "promotion_id,discount,start_date,end_date" > "$file_path"
    
    # Create a temporary file with invalid data at the beginning followed by some valid data
    echo "PROMO002,INVALID_PERC,$INPUT_DATE,$end_date" >> "$file_path.tmp"
    echo "PROMO003,20%,INVALID_DATE,$end_date" >> "$file_path.tmp"
    echo "PROMO004,30%,$INPUT_DATE,INVALID_END_DATE" >> "$file_path.tmp"
    echo "12345,40%,$INPUT_DATE,$end_date" >> "$file_path.tmp"
    echo "PROMO006,123.45%,$INPUT_DATE,$end_date" >> "$file_path.tmp"
    echo "PROMO007,50%,2025-13-32,$end_date" >> "$file_path.tmp"
    echo "PROMO008,60%,$INPUT_DATE,2025-99-99" >> "$file_path.tmp"
    echo "INVALID_ID,WRONG%,BAD_DATE,WRONG_END" >> "$file_path.tmp"
    echo "PROMO010,70%,$INPUT_DATE,$end_date" >> "$file_path.tmp"
    
    # Concatenate the temporary file with invalid rows first to the main file
    if [ -f "$file_path.tmp" ]; then
        cat "$file_path.tmp" "$file_path" > "$file_path.new"
        mv "$file_path.new" "$file_path"
        rm "$file_path.tmp"
    fi
    
    echo -e "${YELLOW}  Generated: $file_name (Mixed valid and invalid data types)${NC}"
    
    echo -e "${GREEN}✅ Promotion files with invalid data types generated${NC}"
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
    
    # Cleaning specific invalid data types subdirectories
    docker exec $DOCKER_CONTAINER bash -c "rm -rf $SFTP_1P_PRICE/invalid_data_types 2>/dev/null || true" 
    docker exec $DOCKER_CONTAINER bash -c "rm -rf $SFTP_1P_PROMOTION/invalid_data_types 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "rm -rf $SFTP_SOA_PRICE/invalid_data_types 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "rm -rf $SFTP_SOA_PROMOTION/invalid_data_types 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "rm -rf $SFTP_RPM_PROCESSED/invalid_data_types 2>/dev/null || true"
    docker exec $DOCKER_CONTAINER bash -c "rm -rf $SFTP_RPM_PENDING/invalid_data_types 2>/dev/null || true"
    
    # Also clean files in main directories
    for dir in "${docker_dirs[@]}"; do
        echo -e "${YELLOW}  Cleaning files in: $dir${NC}"
        # Remove files with invalid data type patterns from main directories
        docker exec $DOCKER_CONTAINER bash -c "rm -f $dir/TH_PRCH_${DATE_PATTERN}*_INVALID_*.csv 2>/dev/null || true"
        docker exec $DOCKER_CONTAINER bash -c "rm -f $dir/TH_PRCH_${DATE_PATTERN}*_MULTIPLE_INVALID_TYPES.csv 2>/dev/null || true"
        docker exec $DOCKER_CONTAINER bash -c "rm -f $dir/TH_PRCH_${DATE_PATTERN}*_MIXED_TYPES.csv 2>/dev/null || true" 
        docker exec $DOCKER_CONTAINER bash -c "rm -f $dir/TH_PROMPRCH_${DATE_PATTERN}*_INVALID_*.csv 2>/dev/null || true"
        docker exec $DOCKER_CONTAINER bash -c "rm -f $dir/TH_PROMPRCH_${DATE_PATTERN}*_MULTIPLE_INVALID_TYPES.csv 2>/dev/null || true"
        docker exec $DOCKER_CONTAINER bash -c "rm -f $dir/TH_PROMPRCH_${DATE_PATTERN}*_MIXED_TYPES.csv 2>/dev/null || true"
    done
    
    echo -e "${GREEN}✅ Docker container directories cleaned${NC}"
}

# =============================================================================
# FUNCTION: Upload & Transfer Files with Invalid Data Types (1P → SOA → RPM)
# =============================================================================
upload_invalid_data_types_files_to_docker() {
    echo -e "${BLUE}🚀 Uploading and transferring files with invalid data types...${NC}"
    
    # 2. Upload Price Files with invalid data types to 1P
    echo -e "${YELLOW}📤 Uploading Price files with invalid data types to 1P main directories...${NC}"
    for file in $INVALID_TYPES_DIR/TH_PRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            
            # Upload to 1P (directly to main directory)
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  → 1P: $filename${NC}"
                
                # Copy from 1P to SOA
                docker exec $DOCKER_CONTAINER bash -c "
                    cp $SFTP_1P_PRICE/$filename $SFTP_SOA_PRICE/
                " >/dev/null 2>&1
                echo -e "${GREEN}  → SOA: $filename${NC}"
                
                # Copy from SOA to RPM
                docker exec $DOCKER_CONTAINER bash -c "
                    cp $SFTP_SOA_PRICE/$filename $SFTP_RPM_PROCESSED/
                " >/dev/null 2>&1
                echo -e "${GREEN}  → RPM: $filename${NC}"
            else
                echo -e "${RED}  Failed to upload: $filename${NC}"
            fi
        fi
    done
    
    # 3. Upload Promotion Files with invalid data types to 1P
    echo -e "${YELLOW}📤 Uploading Promotion files with invalid data types to 1P main directories...${NC}"
    for file in $INVALID_TYPES_DIR/TH_PROMPRCH_${DATE_PATTERN}*.csv; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            
            # Upload to 1P (directly to main directory)
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  → 1P: $filename${NC}"
                
                # Copy from 1P to SOA
                docker exec $DOCKER_CONTAINER bash -c "
                    cp $SFTP_1P_PROMOTION/$filename $SFTP_SOA_PROMOTION/
                " >/dev/null 2>&1
                echo -e "${GREEN}  → SOA: $filename${NC}"
                
                # Copy from SOA to RPM
                docker exec $DOCKER_CONTAINER bash -c "
                    cp $SFTP_SOA_PROMOTION/$filename $SFTP_RPM_PROCESSED/
                " >/dev/null 2>&1
                echo -e "${GREEN}  → RPM: $filename${NC}"
            else
                echo -e "${RED}  Failed to upload: $filename${NC}"
            fi
        fi
    done
    
    # 4. Fix ownership for all directories
    fix_ownership
    
    echo -e "${GREEN}✅ All files with invalid data types uploaded and transferred through pipeline${NC}"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main_invalid_data_types() {
    echo -e "${BLUE}🏁 Starting invalid data types file generation process...${NC}"
    echo -e "${BLUE}📅 Processing date: $INPUT_DATE${NC}"
    
    # Check if Docker container is running
    if ! docker ps | grep -q $DOCKER_CONTAINER; then
        echo -e "${RED}❌ Error: Docker container '$DOCKER_CONTAINER' is not running${NC}"
        echo -e "${YELLOW}💡 Start container first: docker-compose up -d${NC}"
        exit 1
    fi
    
    # Always clean Docker container directories for invalid data types files
    # to avoid duplicates and ensure clean testing environment
    clean_docker_directories
    
    # Generate files with invalid data types
    generate_price_files_with_invalid_data_types
    generate_promotion_files_with_invalid_data_types
    
    # Upload and transfer files to Docker through entire pipeline (1P → SOA → RPM)
    upload_invalid_data_types_files_to_docker
    
    echo -e "${GREEN}🎉 Invalid data types file generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing data type validation${NC}"
    echo -e "${BLUE}📋 Local data stored in: $INVALID_TYPES_DIR/${NC}"
}

# Run main function if not sourced
main_invalid_data_types "$@"
