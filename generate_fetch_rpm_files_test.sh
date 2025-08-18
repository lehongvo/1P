#!/bin/bash

# =============================================================================
# RPM FILES FETCH TEST GENERATOR
# =============================================================================
#
# This script generates test scenarios for the fetch_files_from_rpm task group
# which uses fetch_file_data_from_folder with multiple RPM connections and paths
#
# USAGE:
#   ./generate_fetch_rpm_files_test.sh [YYYY-MM-DD] [--clean]
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

# Create RPM fetch test directory
FETCH_RPM_DIR="$BASE_DIR/$DATE_DIR_FORMAT/fetch_rpm_files"
mkdir -p "$FETCH_RPM_DIR"

echo -e "${CYAN}=== RPM FILES FETCH TEST GENERATOR ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating RPM SFTP fetch test scenarios${NC}"

# =============================================================================
# FUNCTION: Generate processed files scenarios (files successfully processed)
# =============================================================================
generate_processed_files_scenarios() {
    echo -e "${GREEN}✅ Generating Processed Files in RPM Scenarios...${NC}"
    
    # 1. Create files that have been successfully processed by RPM
    echo -e "${YELLOW}  1. Creating successfully processed files...${NC}"
    
    # Processed price files
    for i in {1..4}; do
        timestamp=$(printf "%02d%02d%02d" $((8 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        processed_price="TH_PRCH_${DATE_PATTERN}${timestamp}_RPM_PROCESSED_${i}.csv"
        processed_price_path="$FETCH_RPM_DIR/$processed_price"
        
        cat > "$processed_price_path" << EOF
item_id,price,start_date,end_date,rpm_processed_timestamp,final_status,processing_duration_seconds
RPM_PROCESSED_${i}_001,$(( RANDOM % 700 + 250 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),COMPLETED,$((RANDOM % 300 + 30))
RPM_PROCESSED_${i}_002,$(( RANDOM % 700 + 250 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),COMPLETED,$((RANDOM % 300 + 30))
RPM_PROCESSED_${i}_003,$(( RANDOM % 700 + 250 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),COMPLETED,$((RANDOM % 300 + 30))
RPM_PROCESSED_${i}_004,$(( RANDOM % 700 + 250 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),COMPLETED,$((RANDOM % 300 + 30))
EOF
        echo -e "${GREEN}    Generated: $processed_price (successfully processed)${NC}"
    done
    
    # Processed promotion files
    discounts=("8%" "12%" "16%" "24%" "28%" "32%" "40%" "45%" "50%" "60%")
    days_to_add=$((14 + RANDOM % 16))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    for i in {1..3}; do
        timestamp=$(printf "%02d%02d%02d" $((13 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        processed_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}_RPM_PROCESSED_${i}.csv"
        processed_promo_path="$FETCH_RPM_DIR/$processed_promo"
        
        discount_idx=$((RANDOM % ${#discounts[@]}))
        discount=${discounts[$discount_idx]}
        
        cat > "$processed_promo_path" << EOF
promotion_id,discount,start_date,end_date,rpm_processed_timestamp,final_status,processing_duration_seconds
RPM_PROCESSED_PROMO_${i}_001,$discount,$INPUT_DATE,$end_date,$(date +%s),COMPLETED,$((RANDOM % 200 + 45))
RPM_PROCESSED_PROMO_${i}_002,$discount,$INPUT_DATE,$end_date,$(date +%s),COMPLETED,$((RANDOM % 200 + 45))
RPM_PROCESSED_PROMO_${i}_003,$discount,$INPUT_DATE,$end_date,$(date +%s),COMPLETED,$((RANDOM % 200 + 45))
EOF
        echo -e "${GREEN}    Generated: $processed_promo (successfully processed)${NC}"
    done
    
    echo -e "${GREEN}✅ Processed files scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate pending files scenarios (files waiting for processing)
# =============================================================================
generate_pending_files_scenarios() {
    echo -e "${YELLOW}⏳ Generating Pending Files in RPM Scenarios...${NC}"
    
    # 1. Create files that are pending processing in RPM
    echo -e "${YELLOW}  1. Creating pending processing files...${NC}"
    
    # Pending price files
    for i in {1..3}; do
        timestamp=$(printf "%02d%02d%02d" $((17 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        pending_price="TH_PRCH_${DATE_PATTERN}${timestamp}_RPM_PENDING_${i}.csv"
        pending_price_path="$FETCH_RPM_DIR/$pending_price"
        
        cat > "$pending_price_path" << EOF
item_id,price,start_date,end_date,rpm_arrival_timestamp,queue_position,estimated_processing_time_minutes
RPM_PENDING_${i}_001,$(( RANDOM % 600 + 200 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),$((RANDOM % 10 + 1)),$((RANDOM % 30 + 5))
RPM_PENDING_${i}_002,$(( RANDOM % 600 + 200 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),$((RANDOM % 10 + 1)),$((RANDOM % 30 + 5))
RPM_PENDING_${i}_003,$(( RANDOM % 600 + 200 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),$((RANDOM % 10 + 1)),$((RANDOM % 30 + 5))
EOF
        echo -e "${GREEN}    Generated: $pending_price (pending processing)${NC}"
    done
    
    # Pending promotion files
    for i in {1..2}; do
        timestamp=$(printf "%02d%02d%02d" $((21 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        pending_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}_RPM_PENDING_${i}.csv"
        pending_promo_path="$FETCH_RPM_DIR/$pending_promo"
        
        discount_idx=$((RANDOM % ${#discounts[@]}))
        discount=${discounts[$discount_idx]}
        
        cat > "$pending_promo_path" << EOF
promotion_id,discount,start_date,end_date,rpm_arrival_timestamp,queue_position,estimated_processing_time_minutes
RPM_PENDING_PROMO_${i}_001,$discount,$INPUT_DATE,$end_date,$(date +%s),$((RANDOM % 5 + 1)),$((RANDOM % 20 + 10))
RPM_PENDING_PROMO_${i}_002,$discount,$INPUT_DATE,$end_date,$(date +%s),$((RANDOM % 5 + 1)),$((RANDOM % 20 + 10))
RPM_PENDING_PROMO_${i}_003,$discount,$INPUT_DATE,$end_date,$(date +%s),$((RANDOM % 5 + 1)),$((RANDOM % 20 + 10))
EOF
        echo -e "${GREEN}    Generated: $pending_promo (pending processing)${NC}"
    done
    
    echo -e "${GREEN}✅ Pending files scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate failed processing scenarios
# =============================================================================
generate_failed_processing_scenarios() {
    echo -e "${RED}❌ Generating Failed Processing Files in RPM Scenarios...${NC}"
    
    # 1. Create files that failed processing in RPM
    echo -e "${YELLOW}  1. Creating failed processing files...${NC}"
    
    # Failed price files
    for i in {1..2}; do
        timestamp=$(printf "%02d%02d%02d" $((23 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        failed_price="TH_PRCH_${DATE_PATTERN}${timestamp}_RPM_FAILED_${i}.csv"
        failed_price_path="$FETCH_RPM_DIR/$failed_price"
        
        error_types=("VALIDATION_ERROR" "TIMEOUT_ERROR" "DATA_CORRUPTION" "DEPENDENCY_FAILURE" "RESOURCE_EXHAUSTED")
        error_idx=$((RANDOM % ${#error_types[@]}))
        error_type=${error_types[$error_idx]}
        
        cat > "$failed_price_path" << EOF
item_id,price,start_date,end_date,rpm_failure_timestamp,error_type,retry_count,failure_reason
RPM_FAILED_${i}_001,$(( RANDOM % 500 + 150 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),$error_type,$((RANDOM % 3 + 1)),Processing failed due to $error_type
RPM_FAILED_${i}_002,$(( RANDOM % 500 + 150 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),$error_type,$((RANDOM % 3 + 1)),Processing failed due to $error_type
EOF
        echo -e "${GREEN}    Generated: $failed_price (failed processing: $error_type)${NC}"
    done
    
    # Failed promotion files
    timestamp=$(printf "%02d%02d%02d" $((25)) $((RANDOM % 60)) $((RANDOM % 60)))
    failed_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}_RPM.csv"
    failed_promo_path="$FETCH_RPM_DIR/$failed_promo"
    
    error_idx=$((RANDOM % ${#error_types[@]}))
    error_type=${error_types[$error_idx]}
    
    cat > "$failed_promo_path" << EOF
promotion_id,discount,start_date,end_date,rpm_failure_timestamp,error_type,retry_count,failure_reason
RPM_FAILED_PROMO_001,35%,$INPUT_DATE,$end_date,$(date +%s),$error_type,$((RANDOM % 4 + 1)),Processing failed due to $error_type
RPM_FAILED_PROMO_002,40%,$INPUT_DATE,$end_date,$(date +%s),$error_type,$((RANDOM % 4 + 1)),Processing failed due to $error_type
EOF
    echo -e "${GREEN}    Generated: $failed_promo (failed processing: $error_type)${NC}"
    
    echo -e "${GREEN}✅ Failed processing scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate multi-connection test scenarios
# =============================================================================
generate_multi_connection_scenarios() {
    echo -e "${MAGENTA}🔗 Generating Multi-Connection Test Scenarios...${NC}"
    
    # Create metadata for multi-connection testing
    cat > "$FETCH_RPM_DIR/multi_connection_test_metadata.json" << EOF
{
    "test_scenario": "multi_connection_rpm_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_files_from_rpm with multiple connection configurations",
    "rpm_connection_scenarios": [
        {
            "connection_id": "rpm_processed_connection",
            "path": "$SFTP_RPM_PROCESSED",
            "expected_file_types": ["completed", "archived", "processed"],
            "connection_config": {
                "timeout_seconds": 60,
                "retry_attempts": 3,
                "connection_pool_size": 2
            }
        },
        {
            "connection_id": "rpm_pending_connection", 
            "path": "$SFTP_RPM_PENDING",
            "expected_file_types": ["pending", "queued", "in_progress"],
            "connection_config": {
                "timeout_seconds": 30,
                "retry_attempts": 2,
                "connection_pool_size": 1
            }
        },
        {
            "connection_id": "rpm_failed_connection",
            "path": "$SFTP_RPM_PROCESSED/failed",
            "expected_file_types": ["failed", "error", "rejected"],
            "connection_config": {
                "timeout_seconds": 45,
                "retry_attempts": 1,
                "connection_pool_size": 1
            }
        }
    ],
    "validation_criteria": [
        "Each connection fetches files from correct paths",
        "Connection configurations are respected",
        "Files are categorized by connection type",
        "No cross-connection data contamination",
        "Concurrent connections work properly"
    ],
    "performance_expectations": {
        "max_concurrent_connections": 3,
        "connection_establishment_time_ms": 2000,
        "file_listing_time_per_connection_seconds": 30
    }
}
EOF
    echo -e "${GREEN}    Generated: multi_connection_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ Multi-connection test scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate RPM-specific path handling scenarios
# =============================================================================
generate_path_handling_scenarios() {
    echo -e "${BLUE}📂 Generating RPM Path Handling Test Scenarios...${NC}"
    
    # Create metadata for RPM path handling testing
    cat > "$FETCH_RPM_DIR/path_handling_test_metadata.json" << EOF
{
    "test_scenario": "rpm_path_handling_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_file_data_from_folder RPM-specific path handling",
    "path_scenarios": [
        {
            "scenario": "processed_directory_structure",
            "base_path": "$SFTP_RPM_PROCESSED",
            "subdirectories": ["success", "archived", "completed"],
            "expected_behavior": "recursive_file_discovery"
        },
        {
            "scenario": "pending_directory_structure", 
            "base_path": "$SFTP_RPM_PENDING",
            "subdirectories": ["queue", "priority", "standard"],
            "expected_behavior": "priority_based_listing"
        },
        {
            "scenario": "error_directory_structure",
            "base_path": "$SFTP_RPM_PROCESSED/failed",
            "subdirectories": ["validation_errors", "timeout_errors", "system_errors"],
            "expected_behavior": "error_categorized_listing"
        },
        {
            "scenario": "deep_nested_paths",
            "base_path": "$SFTP_RPM_PROCESSED/archive/${INPUT_DATE%%-*}/${INPUT_DATE:5:2}",
            "depth": 3,
            "expected_behavior": "deep_traversal_support"
        }
    ],
    "path_validation": [
        "Correct path resolution",
        "Subdirectory traversal working",
        "Path permission handling",
        "Symlink resolution if applicable",
        "Cross-platform path compatibility"
    ]
}
EOF
    echo -e "${GREEN}    Generated: path_handling_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ RPM path handling test scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate file status determination scenarios
# =============================================================================
generate_file_status_scenarios() {
    echo -e "${CYAN}📊 Generating File Status Determination Test Scenarios...${NC}"
    
    # Create files with various status indicators
    echo -e "${YELLOW}  1. Creating files with status indicators...${NC}"
    
    # Files with different status indicators
    status_indicators=("COMPLETED" "IN_PROGRESS" "PENDING" "FAILED" "RETRYING" "ARCHIVED")
    
    for i in "${!status_indicators[@]}"; do
        status=${status_indicators[$i]}
        timestamp=$(printf "%02d%02d%02d" $((6 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        status_file="TH_PRCH_${DATE_PATTERN}${timestamp}_RPM_STATUS_${status}.csv"
        status_file_path="$FETCH_RPM_DIR/$status_file"
        
        cat > "$status_file_path" << EOF
item_id,price,start_date,end_date,rpm_status,last_update_timestamp,status_reason
STATUS_TEST_${i}_001,$(( RANDOM % 400 + 100 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$status,$(date +%s),Status set to $status during RPM processing
STATUS_TEST_${i}_002,$(( RANDOM % 400 + 100 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$status,$(date +%s),Status set to $status during RPM processing
EOF
        echo -e "${GREEN}    Generated: $status_file (status: $status)${NC}"
    done
    
    # Create metadata for file status testing
    cat > "$FETCH_RPM_DIR/file_status_test_metadata.json" << EOF
{
    "test_scenario": "file_status_determination_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_file_data_from_folder file status determination in RPM",
    "status_tests": [
        {
            "status": "COMPLETED",
            "expected_location": "processed_directory",
            "expected_behavior": "ready_for_archival"
        },
        {
            "status": "IN_PROGRESS", 
            "expected_location": "processing_directory",
            "expected_behavior": "actively_processing"
        },
        {
            "status": "PENDING",
            "expected_location": "pending_directory", 
            "expected_behavior": "queued_for_processing"
        },
        {
            "status": "FAILED",
            "expected_location": "error_directory",
            "expected_behavior": "requires_investigation"
        },
        {
            "status": "RETRYING",
            "expected_location": "retry_directory",
            "expected_behavior": "automatic_retry_scheduled"
        },
        {
            "status": "ARCHIVED",
            "expected_location": "archive_directory",
            "expected_behavior": "long_term_storage"
        }
    ],
    "status_determination_logic": [
        "Status inferred from file location",
        "Status read from file metadata",
        "Status determined by naming convention",
        "Status updated based on timestamp analysis"
    ]
}
EOF
    echo -e "${GREEN}    Generated: file_status_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ File status determination scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate RPM performance testing scenarios
# =============================================================================
generate_performance_scenarios() {
    echo -e "${MAGENTA}⚡ Generating RPM Performance Test Scenarios...${NC}"
    
    echo -e "${YELLOW}  Creating performance test files...${NC}"
    
    # Generate many files for performance testing
    for i in {1..30}; do
        timestamp=$(printf "%02d%02d%02d" $((RANDOM % 24)) $((RANDOM % 60)) $((RANDOM % 60)))
        perf_file="TH_PRCH_${DATE_PATTERN}${timestamp}_RPM_PERF_TEST_${i}.csv"
        perf_file_path="$FETCH_RPM_DIR/$perf_file"
        
        # Create files with varying sizes for performance testing
        rows=$((RANDOM % 100 + 10))
        echo "item_id,price,start_date,end_date,rpm_processing_metrics" > "$perf_file_path"
        
        for j in $(seq 1 $rows); do
            echo "PERF_${i}_${j},$(( RANDOM % 300 + 50 )).99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),cpu_time:$((RANDOM % 100))ms;memory:$((RANDOM % 50 + 10))MB" >> "$perf_file_path"
        done
        
        # Only show progress every 10 files
        if [ $((i % 10)) -eq 0 ]; then
            echo -e "${GREEN}    Generated performance test batch: $i/30 files${NC}"
        fi
    done
    
    # Create performance test metadata
    cat > "$FETCH_RPM_DIR/performance_test_metadata.json" << EOF
{
    "test_scenario": "rpm_performance_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_file_data_from_folder performance with RPM at scale",
    "performance_parameters": {
        "file_count": 30,
        "concurrent_connections": 3,
        "average_file_size_kb": 5,
        "total_data_size_mb": 0.15,
        "expected_fetch_time_seconds": 45
    },
    "performance_benchmarks": {
        "files_per_second_minimum": 2,
        "memory_usage_max_mb": 100,
        "connection_reuse": true,
        "caching_enabled": true,
        "parallel_processing": true
    },
    "scalability_tests": [
        {
            "test_type": "concurrent_connections",
            "max_connections": 5,
            "expected_behavior": "linear_scaling"
        },
        {
            "test_type": "large_directory_listing",
            "file_count": 100,
            "expected_behavior": "pagination_support"
        },
        {
            "test_type": "memory_efficiency",
            "large_files": true,
            "expected_behavior": "streaming_processing"
        }
    ]
}
EOF
    echo -e "${GREEN}    Generated: performance_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ RPM performance test scenarios generated (30 files)${NC}"
}

# =============================================================================
# FUNCTION: Clean Docker container directories
# =============================================================================
clean_docker_test_files() {
    echo -e "${BLUE}🧹 Cleaning existing RPM files from Docker container...${NC}"
    
    # Define RPM directories to clean
    local docker_dirs=(
        "$SFTP_RPM_PROCESSED"
        "$SFTP_RPM_PENDING"
    )
    
    for dir in "${docker_dirs[@]}"; do
        echo -e "${YELLOW}  Cleaning RPM files in: $dir${NC}"
        # Remove all files but keep directory structure
        docker exec $DOCKER_CONTAINER bash -c "rm -f $dir/*.ods $dir/*.csv $dir/*.txt $dir/*.json $dir/failed/*.csv $dir/archive/*.csv 2>/dev/null || true"
        # Also clean subdirectories
        docker exec $DOCKER_CONTAINER bash -c "find $dir -name '*.csv' -type f -delete 2>/dev/null || true"
    done
    
    echo -e "${GREEN}✅ Docker RPM directories cleaned${NC}"
}

# =============================================================================
# FUNCTION: Upload RPM fetch test files to Docker SFTP Container
# =============================================================================
upload_fetch_rpm_files_to_docker() {
    echo -e "${BLUE}🚀 Uploading RPM fetch test files to Docker SFTP Container...${NC}"
    
    # Upload Processed Files to RPM Processed directory
    echo -e "${YELLOW}📤 Uploading RPM Processed files...${NC}"
    for file in $FETCH_RPM_DIR/TH_*_RPM_PROCESSED_*.csv $FETCH_RPM_DIR/TH_*_RPM_STATUS_COMPLETED.csv $FETCH_RPM_DIR/TH_*_RPM_STATUS_ARCHIVED.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_RPM_PROCESSED/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to processed: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Pending Files to RPM Pending directory  
    echo -e "${YELLOW}📤 Uploading RPM Pending files...${NC}"
    for file in $FETCH_RPM_DIR/TH_*_RPM_PENDING_*.csv $FETCH_RPM_DIR/TH_*_RPM_STATUS_PENDING.csv $FETCH_RPM_DIR/TH_*_RPM_STATUS_IN_PROGRESS.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_RPM_PENDING/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to pending: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Failed Files to a failed subdirectory in processed
    echo -e "${YELLOW}📤 Uploading RPM Failed files...${NC}"
    docker exec $DOCKER_CONTAINER mkdir -p $SFTP_RPM_PROCESSED/failed 2>/dev/null || true
    for file in $FETCH_RPM_DIR/TH_*_RPM_FAILED_*.csv $FETCH_RPM_DIR/TH_*_RPM_STATUS.csv; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_RPM_PROCESSED/failed/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded to failed: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload Performance Test Files
    echo -e "${YELLOW}📤 Uploading RPM Performance test files...${NC}"
    for file in $FETCH_RPM_DIR/TH_*_RPM_PERF_TEST_*.csv; do
        if [ -f "$file" ]; then
            # Distribute performance files between processed and pending
            if [ $((RANDOM % 2)) -eq 0 ]; then
                target_dir="$SFTP_RPM_PROCESSED"
            else
                target_dir="$SFTP_RPM_PENDING" 
            fi
            
            if docker cp "$file" $DOCKER_CONTAINER:$target_dir/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded performance file: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload remaining status test files
    echo -e "${YELLOW}📤 Uploading remaining RPM status test files...${NC}"
    for file in $FETCH_RPM_DIR/TH_*_RPM_STATUS_*.csv; do
        if [ -f "$file" ]; then
            # Check if file was already uploaded
            basename_file=$(basename "$file")
            if ! docker exec $DOCKER_CONTAINER find $SFTP_RPM_PROCESSED $SFTP_RPM_PENDING -name "$basename_file" 2>/dev/null | grep -q .; then
                if docker cp "$file" $DOCKER_CONTAINER:$SFTP_RPM_PROCESSED/ >/dev/null 2>&1; then
                    echo -e "${GREEN}  Uploaded status file: $(basename "$file")${NC}"
                fi
            fi
        fi
    done
    
    # Upload metadata files for reference
    echo -e "${YELLOW}📤 Uploading RPM test metadata files...${NC}"
    for metadata_file in $FETCH_RPM_DIR/*.json; do
        if [ -f "$metadata_file" ]; then
            if docker cp "$metadata_file" $DOCKER_CONTAINER:$SFTP_RPM_PROCESSED/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded metadata: $(basename "$metadata_file")${NC}"
            else
                echo -e "${RED}  Failed to upload metadata: $(basename "$metadata_file")${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ All RPM fetch test files uploaded to Docker container${NC}"
    
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
        for f in $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.csv $SFTP_1P_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
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
        for f in $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.csv $SFTP_1P_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
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
        for f in $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*.csv $SFTP_SOA_PRICE/TH_PRCH_${DATE_PATTERN}*.ods; do
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
        for f in $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.csv $SFTP_SOA_PROMOTION/TH_PROMPRCH_${DATE_PATTERN}*.ods; do
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
main_fetch_rpm_files() {
    echo -e "${CYAN}🏁 Starting RPM files fetch test generation process...${NC}"
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
    
    # Generate different types of RPM fetch test scenarios
    generate_processed_files_scenarios
    generate_pending_files_scenarios
    generate_failed_processing_scenarios
    generate_multi_connection_scenarios
    generate_path_handling_scenarios
    generate_file_status_scenarios
    generate_performance_scenarios
    
    # Upload files to create RPM fetch test scenarios
    upload_fetch_rpm_files_to_docker
    
    echo -e "${GREEN}🎉 RPM files fetch test generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing RPM SFTP fetch operations${NC}"
    echo -e "${BLUE}📋 Local data stored in: $FETCH_RPM_DIR${NC}"
    echo -e "${BLUE}🔍 Test scenarios created:${NC}"
    echo -e "${BLUE}  • ✅ Successfully processed files (completed)${NC}"
    echo -e "${BLUE}  • ⏳ Pending processing files (queued)${NC}"
    echo -e "${BLUE}  • ❌ Failed processing files (errors)${NC}"
    echo -e "${BLUE}  • 🔗 Multi-connection configuration tests${NC}"
    echo -e "${BLUE}  • 📂 RPM-specific path handling tests${NC}"
    echo -e "${BLUE}  • 📊 File status determination tests${NC}"
    echo -e "${BLUE}  • ⚡ Performance and scalability tests (30 files)${NC}"
    echo -e "${BLUE}🧪 Test the fetch_files_from_rpm task group in Airflow DAG${NC}"
}

# Run main function if not sourced
main_fetch_rpm_files "$@"

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
