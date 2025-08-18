#!/bin/bash

# =============================================================================
# SOA FILES FETCH TEST GENERATOR
# =============================================================================
#
# This script generates test scenarios for the fetch_files_from_soa task group
# which uses fetch_file_data_from_folder to retrieve file listings from SOA SFTP
#
# USAGE:
#   ./generate_fetch_soa_files_test.sh [YYYY-MM-DD] [--clean]
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

# Create SOA fetch test directory
FETCH_SOA_DIR="$BASE_DIR/$DATE_DIR_FORMAT/fetch_soa_files"
mkdir -p "$FETCH_SOA_DIR"

echo -e "${CYAN}=== SOA FILES FETCH TEST GENERATOR ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating SOA SFTP fetch test scenarios${NC}"

# =============================================================================
# FUNCTION: Generate transferred files scenarios (files moved from 1P to SOA)
# =============================================================================
generate_transferred_files_scenarios() {
    echo -e "${GREEN}📥 Generating Transferred Files from 1P to SOA Scenarios...${NC}"
    
    # 1. Create files that were successfully transferred from 1P
    echo -e "${YELLOW}  1. Creating successfully transferred files...${NC}"
    
    # Price files with slightly later timestamps (simulating transfer delay)
    for i in {1..4}; do
        timestamp=$(printf "%02d%02d%02d" $((9 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        transfer_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        transfer_price_path="$FETCH_SOA_DIR/$transfer_price"
        
        cat > "$transfer_price_path" << EOF
item_id,price,start_date,end_date
SOA_TRANSFER_ITEM_${i}_001,$(( RANDOM % 800 + 200 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
SOA_TRANSFER_ITEM_${i}_002,$(( RANDOM % 800 + 200 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
SOA_TRANSFER_ITEM_${i}_003,$(( RANDOM % 800 + 200 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
SOA_TRANSFER_ITEM_${i}_004,$(( RANDOM % 800 + 200 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d)
EOF
        echo -e "${GREEN}    Generated: $transfer_price (transferred from 1P)${NC}"
    done
    
    # Promotion files with transfer metadata
    discounts=("12%" "18%" "22%" "28%" "32%" "38%" "42%" "48%" "55%")
    days_to_add=$((10 + RANDOM % 20))
    if [ "$(detect_os)" = "macos" ]; then
        end_date=$(date -j -v+${days_to_add}d -f "%Y-%m-%d" "$INPUT_DATE" +%Y-%m-%d)
    else
        end_date=$(date -d "$INPUT_DATE + $days_to_add days" +%Y-%m-%d)
    fi
    
    for i in {1..3}; do
        timestamp=$(printf "%02d%02d%02d" $((14 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        transfer_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
        transfer_promo_path="$FETCH_SOA_DIR/$transfer_promo"
        
        discount_idx=$((RANDOM % ${#discounts[@]}))
        discount=${discounts[$discount_idx]}
        
        cat > "$transfer_promo_path" << EOF
promotion_id,discount,start_date,end_date
SOA_TRANSFER_PROMO_${i}_001,$discount,$INPUT_DATE,$end_date
SOA_TRANSFER_PROMO_${i}_002,$discount,$INPUT_DATE,$end_date
SOA_TRANSFER_PROMO_${i}_003,$discount,$INPUT_DATE,$end_date
SOA_TRANSFER_PROMO_${i}_004,$discount,$INPUT_DATE,$end_date
EOF
        echo -e "${GREEN}    Generated: $transfer_promo (transferred from 1P)${NC}"
    done
    
    echo -e "${GREEN}✅ Transferred files scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate processed files scenarios (files ready for RPM)
# =============================================================================
generate_processed_files_scenarios() {
    echo -e "${MAGENTA}⚙️ Generating Processed Files Ready for RPM Scenarios...${NC}"
    
    # 1. Create files that have been processed and are ready for RPM transfer
    echo -e "${YELLOW}  1. Creating processed files ready for RPM...${NC}"
    
    # Processed price files
    for i in {1..3}; do
        timestamp=$(printf "%02d%02d%02d" $((18 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        processed_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        processed_price_path="$FETCH_SOA_DIR/$processed_price"
        
        cat > "$processed_price_path" << EOF
item_id,price,start_date,end_date,soa_processed_timestamp,validation_status
SOA_PROCESSED_${i}_001,$(( RANDOM % 600 + 300 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),VALIDATED
SOA_PROCESSED_${i}_002,$(( RANDOM % 600 + 300 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),VALIDATED
SOA_PROCESSED_${i}_003,$(( RANDOM % 600 + 300 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),$(date +%s),VALIDATED
EOF
        echo -e "${GREEN}    Generated: $processed_price (processed, ready for RPM)${NC}"
    done
    
    # Processed promotion files  
    for i in {1..2}; do
        timestamp=$(printf "%02d%02d%02d" $((21 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        processed_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
        processed_promo_path="$FETCH_SOA_DIR/$processed_promo"
        
        discount_idx=$((RANDOM % ${#discounts[@]}))
        discount=${discounts[$discount_idx]}
        
        cat > "$processed_promo_path" << EOF
promotion_id,discount,start_date,end_date,soa_processed_timestamp,validation_status
SOA_PROCESSED_PROMO_${i}_001,$discount,$INPUT_DATE,$end_date,$(date +%s),VALIDATED
SOA_PROCESSED_PROMO_${i}_002,$discount,$INPUT_DATE,$end_date,$(date +%s),VALIDATED
SOA_PROCESSED_PROMO_${i}_003,$discount,$INPUT_DATE,$end_date,$(date +%s),VALIDATED
EOF
        echo -e "${GREEN}    Generated: $processed_promo (processed, ready for RPM)${NC}"
    done
    
    echo -e "${GREEN}✅ Processed files scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate orphaned files scenarios (files in SOA without 1P source)
# =============================================================================
generate_orphaned_files_scenarios() {
    echo -e "${YELLOW}👻 Generating Orphaned Files in SOA Scenarios...${NC}"
    
    # 1. Create orphaned files that exist only in SOA (no 1P source)
    echo -e "${YELLOW}  1. Creating orphaned files in SOA...${NC}"
    
    # Orphaned price files
    for i in {1..2}; do
        timestamp=$(printf "%02d%02d%02d" $((23 + i)) $((RANDOM % 60)) $((RANDOM % 60)))
        orphan_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        orphan_price_path="$FETCH_SOA_DIR/$orphan_price"
        
        cat > "$orphan_price_path" << EOF
item_id,price,start_date,end_date,orphan_reason
SOA_ORPHAN_${i}_001,$(( RANDOM % 400 + 100 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),NO_1P_SOURCE
SOA_ORPHAN_${i}_002,$(( RANDOM % 400 + 100 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),NO_1P_SOURCE
SOA_ORPHAN_${i}_003,$(( RANDOM % 400 + 100 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),NO_1P_SOURCE
EOF
        echo -e "${GREEN}    Generated: $orphan_price (orphaned in SOA)${NC}"
    done
    
    # Orphaned promotion files
    timestamp=$(printf "%02d%02d%02d" $((25)) $((RANDOM % 60)) $((RANDOM % 60)))
    orphan_promo="TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    orphan_promo_path="$FETCH_SOA_DIR/$orphan_promo"
    
    cat > "$orphan_promo_path" << EOF
promotion_id,discount,start_date,end_date,orphan_reason
SOA_ORPHAN_PROMO_001,60%,$INPUT_DATE,$end_date,NO_1P_SOURCE
SOA_ORPHAN_PROMO_002,65%,$INPUT_DATE,$end_date,NO_1P_SOURCE
SOA_ORPHAN_PROMO_003,70%,$INPUT_DATE,$end_date,NO_1P_SOURCE
EOF
    echo -e "${GREEN}    Generated: $orphan_promo (orphaned in SOA)${NC}"
    
    echo -e "${GREEN}✅ Orphaned files scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate timestamp variation scenarios
# =============================================================================
generate_timestamp_variation_scenarios() {
    echo -e "${BLUE}🕐 Generating Timestamp Variation Test Scenarios...${NC}"
    
    # 1. Create files with various timestamp patterns for testing
    echo -e "${YELLOW}  1. Creating files with various timestamps...${NC}"
    
    # Files from different times of day
    time_patterns=("080000" "120000" "160000" "200000" "235959")
    
    for i in "${!time_patterns[@]}"; do
        timestamp=${time_patterns[$i]}
        time_test_price="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
        time_test_path="$FETCH_SOA_DIR/$time_test_price"
        
        cat > "$time_test_path" << EOF
item_id,price,start_date,end_date,soa_arrival_time
SOA_TIME_TEST_$((i+1))_001,$(( RANDOM % 500 + 200 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),${timestamp}
SOA_TIME_TEST_$((i+1))_002,$(( RANDOM % 500 + 200 )).$(( RANDOM % 100 )),$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),${timestamp}
EOF
        echo -e "${GREEN}    Generated: $time_test_price (timestamp: $timestamp)${NC}"
    done
    
    # Create metadata for timestamp testing
    cat > "$FETCH_SOA_DIR/timestamp_variation_test_metadata.json" << EOF
{
    "test_scenario": "timestamp_variation_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_file_data_from_folder with files having various timestamps",
    "timestamp_scenarios": [
        {
            "time_pattern": "080000",
            "description": "Early morning files",
            "expected_behavior": "normal_fetch"
        },
        {
            "time_pattern": "120000", 
            "description": "Midday files",
            "expected_behavior": "normal_fetch"
        },
        {
            "time_pattern": "160000",
            "description": "Afternoon files", 
            "expected_behavior": "normal_fetch"
        },
        {
            "time_pattern": "200000",
            "description": "Evening files",
            "expected_behavior": "normal_fetch"
        },
        {
            "time_pattern": "235959",
            "description": "End of day files",
            "expected_behavior": "normal_fetch"
        }
    ],
    "validation_criteria": [
        "All timestamp patterns detected correctly",
        "Files sorted by timestamp if applicable",
        "No timestamp parsing errors",
        "Metadata extraction includes accurate timestamps"
    ]
}
EOF
    echo -e "${GREEN}    Generated: timestamp_variation_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ Timestamp variation scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate SOA-specific connection scenarios
# =============================================================================
generate_soa_connection_scenarios() {
    echo -e "${CYAN}🔗 Generating SOA Connection Test Scenarios...${NC}"
    
    # Create metadata for SOA connection testing
    cat > "$FETCH_SOA_DIR/soa_connection_test_metadata.json" << EOF
{
    "test_scenario": "soa_connection_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_file_data_from_folder SOA-specific connection behaviors",
    "soa_connection_scenarios": [
        {
            "scenario": "high_latency_connection",
            "simulation": "add_network_delay",
            "expected_behavior": {
                "timeout_handling": "graceful",
                "retry_attempts": 3,
                "fallback_action": "return_partial_results"
            }
        },
        {
            "scenario": "intermittent_connection_drops",
            "simulation": "periodic_connection_loss", 
            "expected_behavior": {
                "reconnection_logic": "automatic",
                "data_integrity": "maintained",
                "progress_resume": "from_last_checkpoint"
            }
        },
        {
            "scenario": "soa_server_busy",
            "simulation": "high_server_load",
            "expected_behavior": {
                "backoff_strategy": "exponential",
                "max_wait_time_seconds": 300,
                "queue_position_tracking": true
            }
        },
        {
            "scenario": "soa_maintenance_mode",
            "simulation": "server_maintenance_response",
            "expected_behavior": {
                "maintenance_detection": true,
                "graceful_degradation": true,
                "retry_after_maintenance": true
            }
        }
    ],
    "performance_expectations": {
        "max_fetch_time_seconds": 120,
        "connection_pool_size": 5,
        "concurrent_requests": 3,
        "memory_usage_limit_mb": 200
    }
}
EOF
    echo -e "${GREEN}    Generated: soa_connection_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ SOA connection test scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate file metadata scenarios
# =============================================================================
generate_file_metadata_scenarios() {
    echo -e "${MAGENTA}📊 Generating File Metadata Test Scenarios...${NC}"
    
    # Create files with rich metadata for testing metadata extraction
    echo -e "${YELLOW}  1. Creating files with comprehensive metadata...${NC}"
    
    # File with extended metadata
    timestamp=$(printf "%02d%02d%02d" $((7)) $((RANDOM % 60)) $((RANDOM % 60)))
    metadata_rich_file="TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    metadata_rich_path="$FETCH_SOA_DIR/$metadata_rich_file"
    
    cat > "$metadata_rich_path" << EOF
item_id,price,start_date,end_date,source_system,processing_stage,data_quality_score,last_modified_by
SOA_META_001,199.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),1P_SYSTEM,SOA_PROCESSED,0.95,SOA_PROCESSOR_v2.1
SOA_META_002,299.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),1P_SYSTEM,SOA_PROCESSED,0.98,SOA_PROCESSOR_v2.1
SOA_META_003,399.99,$INPUT_DATE,$(date -d "$INPUT_DATE + 30 days" +%Y-%m-%d),1P_SYSTEM,SOA_PROCESSED,0.92,SOA_PROCESSOR_v2.1
EOF
    
    # Set specific file attributes for testing
    touch -t $(date -d "$INPUT_DATE 10:30:00" +%Y%m%d%H%M.%S) "$metadata_rich_path"
    echo -e "${GREEN}    Generated: $metadata_rich_file (with rich metadata)${NC}"
    
    # Create metadata test specification
    cat > "$FETCH_SOA_DIR/file_metadata_test_metadata.json" << EOF
{
    "test_scenario": "file_metadata_extraction_fetch",
    "test_date": "$INPUT_DATE",
    "description": "Test fetch_file_data_from_folder metadata extraction capabilities",
    "metadata_tests": [
        {
            "test_type": "file_size_extraction",
            "file": "$metadata_rich_file",
            "expected_size_bytes": $(stat -c%s "$metadata_rich_path" 2>/dev/null || echo "unknown"),
            "validation": "size_matches_actual"
        },
        {
            "test_type": "modification_time_extraction",
            "file": "$metadata_rich_file", 
            "expected_format": "iso_8601_or_timestamp",
            "validation": "timestamp_accurate"
        },
        {
            "test_type": "file_permissions_check",
            "file": "$metadata_rich_file",
            "expected_permissions": "readable",
            "validation": "permissions_detected"
        },
        {
            "test_type": "content_type_detection",
            "file": "$metadata_rich_file",
            "expected_content_type": "text_csv",
            "validation": "content_type_correct"
        }
    ],
    "extraction_performance": {
        "max_extraction_time_per_file_ms": 100,
        "batch_extraction_efficiency": true,
        "metadata_caching": "recommended"
    }
}
EOF
    echo -e "${GREEN}    Generated: file_metadata_test_metadata.json${NC}"
    
    echo -e "${GREEN}✅ File metadata test scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Clean Docker container directories
# =============================================================================
clean_docker_test_files() {
    echo -e "${BLUE}🧹 Cleaning existing SOA files from Docker container...${NC}"
    
    # Define SOA directories to clean
    local docker_dirs=(
        "$SFTP_SOA_PRICE"
        "$SFTP_SOA_PROMOTION"
        "${SFTP_SOA_FEEDBACK_PRICE/:DATETIME/$INPUT_DATE}"
        "${SFTP_SOA_FEEDBACK_PROMOTION/:DATETIME/$INPUT_DATE}"
    )
    
    for dir in "${docker_dirs[@]}"; do
        echo -e "${YELLOW}  Cleaning SOA files in: $dir${NC}"
        # Remove all files but keep directory structure
        docker exec $DOCKER_CONTAINER bash -c "rm -f $dir/*.ods $dir/*.csv $dir/*.txt $dir/*.json $dir/invalid/*.ods $dir/invalid/*.csv 2>/dev/null || true"
    done
    
    echo -e "${GREEN}✅ Docker SOA directories cleaned${NC}"
}

# =============================================================================
# FUNCTION: Upload SOA fetch test files to Docker SFTP Container
# =============================================================================
upload_fetch_soa_files_to_docker() {
    echo -e "${BLUE}🚀 Uploading SOA fetch test files to Docker SFTP Container...${NC}"
    
    # Upload SOA Price Files for fetch testing
    echo -e "${YELLOW}📤 Uploading SOA Price files for fetch testing...${NC}"
    for file in $FETCH_SOA_DIR/TH_PRCH_${DATE_PATTERN}${timestamp}.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_SOA_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload SOA Promotion Files for fetch testing
    echo -e "${YELLOW}📤 Uploading SOA Promotion files for fetch testing...${NC}"
    for file in $FETCH_SOA_DIR/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods; do
        if [ -f "$file" ]; then
            if docker cp "$file" $DOCKER_CONTAINER:$SFTP_SOA_PROMOTION/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
            else
                echo -e "${RED}  Failed to upload: $(basename "$file")${NC}"
            fi
        fi
    done
    
    # Upload metadata files for reference
    echo -e "${YELLOW}📤 Uploading SOA test metadata files...${NC}"
    for metadata_file in $FETCH_SOA_DIR/*.json; do
        if [ -f "$metadata_file" ]; then
            if docker cp "$metadata_file" $DOCKER_CONTAINER:$SFTP_SOA_PRICE/ >/dev/null 2>&1; then
                echo -e "${GREEN}  Uploaded metadata: $(basename "$metadata_file")${NC}"
            else
                echo -e "${RED}  Failed to upload metadata: $(basename "$metadata_file")${NC}"
            fi
        fi
    done
    
    echo -e "${GREEN}✅ All SOA fetch test files uploaded to Docker container${NC}"
    
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
main_fetch_soa_files() {
    echo -e "${CYAN}🏁 Starting SOA files fetch test generation process...${NC}"
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
    
    # Generate different types of SOA fetch test scenarios
    generate_transferred_files_scenarios
    generate_processed_files_scenarios
    generate_orphaned_files_scenarios
    generate_timestamp_variation_scenarios
    generate_soa_connection_scenarios
    generate_file_metadata_scenarios
    
    # Upload files to create SOA fetch test scenarios
    upload_fetch_soa_files_to_docker
    
    echo -e "${GREEN}🎉 SOA files fetch test generation completed successfully!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing SOA SFTP fetch operations${NC}"
    echo -e "${BLUE}📋 Local data stored in: $FETCH_SOA_DIR${NC}"
    echo -e "${BLUE}🔍 Test scenarios created:${NC}"
    echo -e "${BLUE}  • 📥 Transferred files from 1P to SOA${NC}"
    echo -e "${BLUE}  • ⚙️ Processed files ready for RPM${NC}"
    echo -e "${BLUE}  • 👻 Orphaned files (SOA only, no 1P source)${NC}"
    echo -e "${BLUE}  • 🕐 Timestamp variation patterns${NC}"
    echo -e "${BLUE}  • 🔗 SOA connection failure scenarios${NC}"
    echo -e "${BLUE}  • 📊 File metadata extraction tests${NC}"
    echo -e "${BLUE}🧪 Test the fetch_files_from_soa task group in Airflow DAG${NC}"
}

# Run main function if not sourced
main_fetch_soa_files "$@"

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
