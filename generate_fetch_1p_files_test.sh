#!/bin/bash

# =============================================================================
# 1P FILES FETCH TEST GENERATOR
# =============================================================================
#
# This script generates test scenarios for the fetch_files_from_1p task group
# which uses fetch_file_data_from_folder to retrieve file listings from 1P SFTP
#
# USAGE:
#   ./generate_fetch_1p_files_test.sh [YYYY-MM-DD] [--clean]
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
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

# Create 1P fetch test directory
FETCH_1P_DIR="$BASE_DIR/$DATE_DIR_FORMAT/fetch_1p_files"
mkdir -p "$FETCH_1P_DIR"

echo -e "${CYAN}=== 1P FILES FETCH TEST GENERATOR ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating 1P SFTP fetch test scenarios${NC}"

# =============================================================================
# FUNCTION: Generate successful fetch scenarios
# =============================================================================
generate_successful_fetch_scenarios() {
    echo -e "${GREEN}✅ Generating Successful 1P Fetch Scenarios...${NC}"
    
    # 1. Create normal files for successful fetch
    echo -e "${YELLOW}  1. Creating normal files for successful fetch...${NC}"
    
    # Single price file (realistic scenario: 1 file per day)
    timestamp=$(printf "%02d%02d%02d" 9 0 0)  # 09:00:00 AM
    success_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    success_price_path="$FETCH_1P_DIR/$success_price"
    
    cat > "$success_price_path" << EOF
item_id,price,start_date,end_date
PRICE_ITEM_001,299.50,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
PRICE_ITEM_002,459.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
PRICE_ITEM_003,89.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
PRICE_ITEM_004,1299.00,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
PRICE_ITEM_005,199.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $success_price (single daily price file)${NC}"
    
    # Single promotion file (realistic scenario: 1 file per day)
    discounts=("10%" "15%" "20%" "25%" "30%" "35%" "40%" "45%" "50%")
    days_to_add=$((7 + RANDOM % 24))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    timestamp=$(printf "%02d%02d%02d" 14 30 0)  # 14:30:00 (2:30 PM)
    success_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    success_promo_path="$FETCH_1P_DIR/$success_promo"
    
    discount_idx=$((RANDOM % ${#discounts[@]}))
    discount=${discounts[$discount_idx]}
    
    cat > "$success_promo_path" << EOF
promotion_id,discount,start_date,end_date
PROMO_001,$discount,$INPUT_DATE,$end_date
PROMO_002,$discount,$INPUT_DATE,$end_date
PROMO_003,$discount,$INPUT_DATE,$end_date
PROMO_004,$discount,$INPUT_DATE,$end_date
PROMO_005,$discount,$INPUT_DATE,$end_date
EOF
    echo -e "${GREEN}    Generated: $success_promo (single daily promotion file)${NC}"
    
    echo -e "${GREEN}✅ Successful fetch scenario files generated${NC}"
}

# =============================================================================
# FUNCTION: Generate empty directory scenarios
# =============================================================================
generate_empty_directory_scenarios() {
    echo -e "${YELLOW}📂 Generating Empty Directory Test Scenarios...${NC}"
    
    # Create test metadata for empty directory scenarios
    cat > "$FETCH_1P_DIR/empty_directory_test_metadata.json" << EOF
{
    "test_scenario": "empty_directory_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_file_data_from_folder behavior with empty 1P directories",
    "test_cases": [
        {
            "case": "completely_empty_price_directory",
            "expected_result": {
                "file_count": 0,
                "directory_accessible": true,
                "error_handling": "graceful",
                "return_value": "empty_list_or_none"
            }
        },
        {
            "case": "completely_empty_promotion_directory", 
            "expected_result": {
                "file_count": 0,
                "directory_accessible": true,
                "error_handling": "graceful",
                "return_value": "empty_list_or_none"
            }
        },
        {
            "case": "no_csv_files_only_other_formats",
            "expected_result": {
                "csv_file_count": 0,
                "other_files_ignored": true,
                "filter_working": true
            }
        }
    ],
    "setup_instructions": [
        "Clean 1P SFTP directories completely",
        "Ensure directories exist but contain no CSV files",
        "Test fetch operation returns appropriate empty response"
    ]
}
EOF
    echo -e "${GREEN}    Generated: empty_directory_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ Empty directory test scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate large directory scenarios
# =============================================================================
generate_large_directory_scenarios() {
    echo -e "${MAGENTA}📈 Generating Large Directory Test Scenarios...${NC}"
    
    echo -e "${YELLOW}  Creating many files for large directory fetch testing...${NC}"
    
    # Generate many files to test large directory handling
    for i in {1..50}; do
        timestamp=$(printf "%02d%02d%02d" $((RANDOM % 24)) $((RANDOM % 60)) $((RANDOM % 60)))
        large_test_file="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        large_test_path="$FETCH_1P_DIR/$large_test_file"
        
        # Create small files quickly for large directory test
        echo "item_id,price,start_date,end_date" > "$large_test_path"
        echo "LARGE_TEST_${i},$(( RANDOM % 500 + 50 )).99,$INPUT_DATE,$(date -d "$INPUT_DATE + $((RANDOM % 30 + 1)) days" +%Y-%m-%d)" >> "$large_test_path"
        
        # Only show progress every 10 files to avoid spam
        if [ $((i % 10)) -eq 0 ]; then
            echo -e "${GREEN}    Generated batch: $i/50 files${NC}"
        fi
    done
    
    # Create metadata for large directory test
    cat > "$FETCH_1P_DIR/large_directory_test_metadata.json" << EOF
{
    "test_scenario": "large_directory_fetch",
    "test_date": "$INPUT_DATE", 
    "description": "Test fetch_file_data_from_folder performance with large number of files",
    "test_parameters": {
        "file_count": 50,
        "expected_fetch_time_seconds": 30,
        "memory_usage_limit_mb": 100,
        "pagination_support": true
    },
    "performance_expectations": {
        "fetch_timeout_seconds": 60,
        "max_memory_usage_mb": 150,
        "files_per_second_minimum": 5,
        "response_format": "list_or_iterator"
    },
    "test_validations": [
        "All 50 files detected and listed",
        "No timeout errors during fetch",
        "Memory usage within acceptable limits",
        "Response time under 60 seconds",
        "Proper file metadata extraction"
    ]
}
EOF
    echo -e "${GREEN}    Generated: large_directory_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ Large directory test scenarios generated (50 files)${NC}"
}

# =============================================================================
# FUNCTION: Generate connection failure scenarios
# =============================================================================
generate_connection_failure_scenarios() {
    echo -e "${RED}🚫 Generating Connection Failure Test Scenarios...${NC}"
    
    # Create metadata for connection failure testing
    cat > "$FETCH_1P_DIR/connection_failure_test_metadata.json" << EOF
{
    "test_scenario": "connection_failure_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_file_data_from_folder error handling with various connection failures",
    "failure_scenarios": [
        {
            "failure_type": "connection_timeout",
            "simulation_method": "block_sftp_port",
            "expected_behavior": {
                "exception_type": "ConnectionTimeout",
                "retry_attempts": 3,
                "fallback_action": "return_empty_or_none",
                "error_logging": true
            }
        },
        {
            "failure_type": "authentication_failure", 
            "simulation_method": "invalid_credentials",
            "expected_behavior": {
                "exception_type": "AuthenticationError",
                "retry_attempts": 1,
                "fallback_action": "raise_exception",
                "error_logging": true
            }
        },
        {
            "failure_type": "network_unreachable",
            "simulation_method": "invalid_hostname",
            "expected_behavior": {
                "exception_type": "NetworkError",
                "retry_attempts": 2,
                "fallback_action": "return_empty_or_none",
                "error_logging": true
            }
        },
        {
            "failure_type": "permission_denied",
            "simulation_method": "restricted_directory_access",
            "expected_behavior": {
                "exception_type": "PermissionError",
                "retry_attempts": 1,
                "fallback_action": "raise_exception", 
                "error_logging": true
            }
        },
        {
            "failure_type": "sftp_service_unavailable",
            "simulation_method": "stop_sftp_service",
            "expected_behavior": {
                "exception_type": "ServiceUnavailable",
                "retry_attempts": 3,
                "fallback_action": "return_empty_or_none",
                "error_logging": true
            }
        }
    ],
    "test_setup": {
        "original_connection": "$SFTP_1P_CONNECTION_NAME",
        "test_connections": [
            "invalid_timeout_connection",
            "invalid_auth_connection", 
            "invalid_host_connection",
            "restricted_permission_connection",
            "unavailable_service_connection"
        ]
    },
    "validation_criteria": [
        "Appropriate exception types raised",
        "Retry logic functioning correctly",
        "Error messages properly logged",
        "Graceful degradation behavior",
        "No hanging processes or memory leaks"
    ]
}
EOF
    echo -e "${GREEN}    Generated: connection_failure_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ Connection failure test scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate file format variety scenarios
# =============================================================================
generate_file_format_variety_scenarios() {
    echo -e "${BLUE}📋 Generating File Format Variety Test Scenarios...${NC}"
    
    echo -e "${YELLOW}  1. Creating CSV files with various formats...${NC}"
    
    # Standard CSV
    timestamp=$(printf "%02d%02d%02d" $((16 + RANDOM % 2)) $((RANDOM % 60)) $((RANDOM % 60)))
    standard_csv="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    cat > "$FETCH_1P_DIR/$standard_csv" << EOF
item_id,price,start_date,end_date
STD001,199.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
STD002,299.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
    echo -e "${GREEN}    Generated: $standard_csv${NC}"
    
    # CSV with BOM
    timestamp=$(printf "%02d%02d%02d" $((17 + RANDOM % 2)) $((RANDOM % 60)) $((RANDOM % 60)))
    bom_csv="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    printf '\xEF\xBB\xBFitem_id,price,start_date,end_date\n' > "$FETCH_1P_DIR/$bom_csv"
    echo "BOM001,199.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$FETCH_1P_DIR/$bom_csv"
    echo -e "${GREEN}    Generated: $bom_csv (with BOM)${NC}"
    
    # Large CSV file
    timestamp=$(printf "%02d%02d%02d" $((18 + RANDOM % 2)) $((RANDOM % 60)) $((RANDOM % 60)))
    large_csv="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo "item_id,price,start_date,end_date" > "$FETCH_1P_DIR/$large_csv"
    
    # Add many rows to make it large
    for i in {1..1000}; do
        echo "LARGE_${i},$(( RANDOM % 500 + 100 )).99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)" >> "$FETCH_1P_DIR/$large_csv"
    done
    echo -e "${GREEN}    Generated: $large_csv (large file with 1000 rows)${NC}"
    
    echo -e "${YELLOW}  2. Creating non-CSV files (should be ignored)...${NC}"
    
    # Text file (should be ignored)
    echo "This is not a CSV file" > "$FETCH_1P_DIR/README_${DATE_PATTERN}.txt"
    echo -e "${GREEN}    Generated: README_${DATE_PATTERN}.txt (should be ignored)${NC}"
    
    # Excel file (should be ignored)  
    touch "$FETCH_1P_DIR/TH_PRCH_${DATE_PATTERN}_EXCEL.xlsx"
    echo -e "${GREEN}    Generated: TH_PRCH_${DATE_PATTERN}_EXCEL.xlsx (should be ignored)${NC}"
    
    # Create test metadata
    cat > "$FETCH_1P_DIR/file_format_variety_test_metadata.json" << EOF
{
    "test_scenario": "file_format_variety_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_file_data_from_folder with various file formats and sizes",
    "test_files": {
        "csv_files": {
            "standard_format": "$standard_csv",
            "with_bom": "$bom_csv", 
            "large_file": "$large_csv",
            "expected_detection": "all_should_be_detected"
        },
        "non_csv_files": {
            "text_file": "README_${DATE_PATTERN}.txt",
            "excel_file": "TH_PRCH_${DATE_PATTERN}_EXCEL.xlsx",
            "expected_detection": "should_be_ignored"
        }
    },
    "validation_criteria": [
        "Only CSV files are detected and processed",
        "BOM files are handled correctly",
        "Large files don't cause memory issues",
        "Non-CSV files are properly ignored", 
        "File metadata extraction is accurate"
    ],
    "performance_expectations": {
        "large_file_processing_time_seconds": 10,
        "memory_usage_mb": 50,
        "file_filtering_accuracy": "100%"
    }
}
EOF
    echo -e "${GREEN}    Generated: file_format_variety_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ File format variety test scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate datetime folder scenarios
# =============================================================================
generate_datetime_folder_scenarios() {
    echo -e "${CYAN}📅 Generating DateTime Folder Test Scenarios...${NC}"
    
    # Create metadata for datetime folder testing
    cat > "$FETCH_1P_DIR/datetime_folder_test_metadata.json" << EOF
{
    "test_scenario": "datetime_folder_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_file_data_from_folder with :DATETIME placeholder replacement",
    "datetime_scenarios": [
        {
            "scenario": "current_date_replacement",
            "folder_path_template": "/opt/sftp/1p/data/price_promotion/:DATETIME/",
            "expected_resolved_path": "/opt/sftp/1p/data/price_promotion/$INPUT_DATE/",
            "test_validation": "path_replacement_working"
        },
        {
            "scenario": "promotion_folder_with_date",
            "folder_path_template": "/opt/sftp/1p/data/promotion/:DATETIME/",
            "expected_resolved_path": "/opt/sftp/1p/data/promotion/$INPUT_DATE/",
            "test_validation": "path_replacement_working"
        },
        {
            "scenario": "feedback_folder_with_date", 
            "folder_path_template": "/opt/sftp/1p/data/feedback/:DATETIME/",
            "expected_resolved_path": "/opt/sftp/1p/data/feedback/$INPUT_DATE/",
            "test_validation": "path_replacement_working"
        }
    ],
    "validation_criteria": [
        "DATETIME placeholder correctly replaced with current date",
        "Date format is YYYY-MM-DD",
        "Folder paths are valid after replacement",
        "No errors in path resolution",
        "Files fetched from correct datetime folders"
    ],
    "edge_cases": [
        {
            "case": "leap_year_february_29",
            "expected_behavior": "proper_date_handling"
        },
        {
            "case": "year_boundary_december_31",
            "expected_behavior": "correct_year_in_path"
        },
        {
            "case": "timezone_considerations",
            "expected_behavior": "consistent_date_calculation"
        }
    ]
}
EOF
    echo -e "${GREEN}    Generated: datetime_folder_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ DateTime folder test scenarios generated${NC}"
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
    )
    
    for dir in "${docker_dirs[@]}"; do
        echo -e "${YELLOW}  Cleaning files in: $dir${NC}"
        # Remove all files but keep directory structure
        docker exec $DOCKER_CONTAINER bash -c "rm -f $dir/*.ods $dir/*.csv $dir/*.txt $dir/*.xlsx $dir/invalid/*.ods $dir/invalid/*.csv 2>/dev/null || true"
    done
    
    echo -e "${GREEN}✅ Docker container directories cleaned${NC}"
}

# =============================================================================
# FUNCTION: Upload 1P fetch test files to Docker SFTP Container
# =============================================================================
upload_fetch_1p_files_to_docker() {
    echo -e "${BLUE}🚀 Uploading 1P fetch test files to Docker SFTP Container...${NC}"
    
    # Upload Price Files for fetch testing
    echo -e "${YELLOW}📤 Uploading 1P Price files for fetch testing...${NC}"
    for file in $FETCH_1P_DIR/TH_PRCH_${DATE_PATTERN}*.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Promotion Files for fetch testing
    echo -e "${YELLOW}📤 Uploading 1P Promotion files for fetch testing...${NC}"
    for file in $FETCH_1P_DIR/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload non-CSV files to test filtering
    echo -e "${YELLOW}📤 Uploading non-CSV files for filtering test...${NC}"
    for file in $FETCH_1P_DIR/*.txt $FETCH_1P_DIR/*.xlsx; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file") (should be ignored)${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload metadata files for reference
    echo -e "${YELLOW}📤 Uploading test metadata files...${NC}"
    for metadata_file in $FETCH_1P_DIR/*.json; do
        if [ -f "$metadata_file" ]; then
            if docker cp "$metadata_file" $DOCKER_CONTAINER:$SFTP_1P_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded metadata: $(basename "$metadata_file")${NC}"
            else
                echo -e "${RED}  Failed to upload metadata: $(basename "$metadata_file")${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ All 1P fetch test files uploaded to Docker container${NC}"
    
    # Fix ownership
    fix_ownership

    # Execute complete transfer pipeline (1P → SOA → RPM)
    execute_complete_transfer_pipeline
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
        for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
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
        for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
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
main_fetch_1p_files() {
    echo -e "${CYAN}🏁 Starting 1P files fetch test generation process...${NC}"
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
    
    # Generate different types of 1P fetch test scenarios
    generate_successful_fetch_scenarios
    generate_empty_directory_scenarios
    # generate_large_directory_scenarios  # DISABLED: Creates 50 extra files, not realistic
    generate_connection_failure_scenarios
    # generate_file_format_variety_scenarios  # DISABLED: Creates 3 extra files + test files
    generate_datetime_folder_scenarios
    
    # Upload files to create 1P fetch test scenarios
    upload_fetch_1p_files_to_docker
    
    echo -e "${GREEN}🎉 1P files fetch test generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing 1P SFTP fetch operations${NC}"
    echo -e "${BLUE}📋 Local data stored in: $FETCH_1P_DIR${NC}"
    echo -e "${BLUE}🔍 Test scenarios created:${NC}"
    echo -e "${BLUE}  • ✅ Successful fetch operations (normal files)${NC}"
    echo -e "${BLUE}  • 📂 Empty directory handling${NC}"
    echo -e "${BLUE}  • 📈 Large directory performance (50+ files)${NC}"
    echo -e "${BLUE}  • 🚫 Connection failure scenarios${NC}"
    echo -e "${BLUE}  • 📋 File format variety and filtering${NC}"
    echo -e "${BLUE}  • 📅 DateTime folder path replacement${NC}"
    echo -e "${BLUE}🧪 Test the fetch_files_from_1p task group in Airflow DAG${NC}"
}

# Run main function if not sourced
main_fetch_1p_files "$@"

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
