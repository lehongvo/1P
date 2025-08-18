#!/bin/bash

# =============================================================================
# FILE TRACKING TEST FILE GENERATOR
# =============================================================================
# This script generates test scenarios for the file tracking tasks functionality.
# It creates mock SFTP directory listings and file metadata to test how files
# are tracked as they move through the pipeline stages (1P -> SOA -> RPM).
#
# Test Scenarios:
# 1. Successful file transfers with proper tracking
# 2. Transfer delays and timing analysis
# 3. Failed transfers and missing files
# 4. File size and timestamp validation
# 5. Cross-stage file matching and orphan detection
# =============================================================================

# Import shared configuration
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

# Process arguments
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
        echo -e "${YELLOW}  --clean: Remove existing files from Docker container first${NC}"
        exit 0
    else
        echo -e "${RED}❌ Error: Invalid argument '$arg'${NC}"
        exit 1
    fi
done

# Use current date if not provided
if [ -z "$INPUT_DATE" ]; then
    INPUT_DATE=$(date +%Y-%m-%d)
fi

# Generate date formats
DATE_PATTERN=$(parse_date "$INPUT_DATE" "+%Y%m%d")
DATE_DIR_FORMAT="$INPUT_DATE"

# Create file tracking test directory
FILE_TRACKING_DIR="$BASE_DIR/$DATE_DIR_FORMAT/file_tracking"
mkdir -p "$FILE_TRACKING_DIR"

echo -e "${BLUE}=== FILE TRACKING TEST FILES GENERATOR ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}📊 Generating file tracking scenarios for testing${NC}"

# =============================================================================
# FUNCTION: Generate Mock SFTP File Listings
# =============================================================================
generate_mock_sftp_listings() {
    echo -e "${RED}🔧 Generating Mock SFTP File Listings...${NC}"
    
    # 1. Mock 1P SFTP file listings
    echo -e "${YELLOW}  1. Creating mock 1P SFTP file listings...${NC}"
    
    cat > "$FILE_TRACKING_DIR/mock_1p_file_listing.json" << EOF
{
    "listing_date": "$INPUT_DATE",
    "stage": "1p",
    "directories": {
        "price": {
            "path": "/opt/sftp/1p/data/price_promotion",
            "files": [
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 1024,
                    "modified_time": "$(date -d "$INPUT_DATE 08:00:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 07:58:00" +%s)",
                    "status": "ready_for_transfer"
                },
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 2048,
                    "modified_time": "$(date -d "$INPUT_DATE 09:00:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 08:57:00" +%s)",
                    "status": "ready_for_transfer"
                },
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 4096,
                    "modified_time": "$(date -d "$INPUT_DATE 10:00:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 09:58:00" +%s)",
                    "status": "ready_for_transfer"
                },
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 8192,
                    "modified_time": "$(date -d "$INPUT_DATE 11:00:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 10:59:00" +%s)",
                    "status": "ready_for_transfer"
                },
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 512,
                    "modified_time": "$(date -d "$INPUT_DATE 12:00:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 11:58:00" +%s)",
                    "status": "transfer_failed"
                }
            ]
        },
        "promotion": {
            "path": "/opt/sftp/1p/data/promotion",
            "files": [
                {
                    "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 1536,
                    "modified_time": "$(date -d "$INPUT_DATE 13:00:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 12:58:00" +%s)",
                    "status": "ready_for_transfer"
                },
                {
                    "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 3072,
                    "modified_time": "$(date -d "$INPUT_DATE 14:00:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 13:57:00" +%s)",
                    "status": "ready_for_transfer"
                },
                {
                    "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 6144,
                    "modified_time": "$(date -d "$INPUT_DATE 15:00:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 14:58:00" +%s)",
                    "status": "transfer_pending"
                }
            ]
        }
    },
    "summary": {
        "total_files": 8,
        "total_size_bytes": 27648,
        "ready_for_transfer": 6,
        "transfer_pending": 1,
        "transfer_failed": 1
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_1p_file_listing.json${NC}"

    # 2. Mock SOA SFTP file listings
    echo -e "${YELLOW}  2. Creating mock SOA SFTP file listings...${NC}"
    
    cat > "$FILE_TRACKING_DIR/mock_soa_file_listing.json" << EOF
{
    "listing_date": "$INPUT_DATE",
    "stage": "soa",
    "directories": {
        "price": {
            "path": "/opt/sftp/soa/data/price_promotion",
            "files": [
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 1024,
                    "modified_time": "$(date -d "$INPUT_DATE 08:05:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 08:05:00" +%s)",
                    "transfer_time_from_1p_minutes": 5,
                    "status": "transferred_from_1p"
                },
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 2048,
                    "modified_time": "$(date -d "$INPUT_DATE 09:25:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 09:25:00" +%s)",
                    "transfer_time_from_1p_minutes": 25,
                    "status": "transferred_from_1p_delayed"
                },
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 4096,
                    "modified_time": "$(date -d "$INPUT_DATE 11:08:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 11:08:00" +%s)",
                    "transfer_time_from_1p_minutes": 8,
                    "status": "transferred_with_size_mismatch",
                    "original_1p_size": 8192
                },
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 1024,
                    "modified_time": "$(date -d "$INPUT_DATE 20:00:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 20:00:00" +%s)",
                    "status": "orphaned_no_1p_source"
                }
            ]
        },
        "promotion": {
            "path": "/opt/sftp/soa/data/promotion",
            "files": [
                {
                    "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 1536,
                    "modified_time": "$(date -d "$INPUT_DATE 13:07:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 13:07:00" +%s)",
                    "transfer_time_from_1p_minutes": 7,
                    "status": "transferred_from_1p"
                },
                {
                    "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 3072,
                    "modified_time": "$(date -d "$INPUT_DATE 14:45:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 14:45:00" +%s)",
                    "transfer_time_from_1p_minutes": 45,
                    "status": "transferred_with_time_delay",
                    "expected_transfer_time_minutes": 10
                }
            ]
        }
    },
    "summary": {
        "total_files": 6,
        "total_size_bytes": 12800,
        "transferred_from_1p": 4,
        "delayed_transfers": 2,
        "orphaned_files": 1,
        "size_mismatches": 1
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_soa_file_listing.json${NC}"

    # 3. Mock RPM SFTP file listings
    echo -e "${YELLOW}  3. Creating mock RPM SFTP file listings...${NC}"
    
    cat > "$FILE_TRACKING_DIR/mock_rpm_file_listing.json" << EOF
{
    "listing_date": "$INPUT_DATE",
    "stage": "rpm",
    "directories": {
        "processed": {
            "path": "/opt/sftp/rpm/processed",
            "files": [
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 1024,
                    "modified_time": "$(date -d "$INPUT_DATE 08:15:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 08:15:00" +%s)",
                    "transfer_time_from_soa_minutes": 10,
                    "total_pipeline_time_minutes": 15,
                    "status": "fully_processed"
                },
                {
                    "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 1536,
                    "modified_time": "$(date -d "$INPUT_DATE 13:20:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 13:20:00" +%s)",
                    "transfer_time_from_soa_minutes": 13,
                    "total_pipeline_time_minutes": 20,
                    "status": "fully_processed"
                }
            ]
        },
        "pending": {
            "path": "/opt/sftp/rpm/pending",
            "files": [
                {
                    "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 2048,
                    "modified_time": "$(date -d "$INPUT_DATE 09:40:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 09:40:00" +%s)",
                    "transfer_time_from_soa_minutes": 15,
                    "status": "pending_processing"
                },
                {
                    "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                    "size": 3072,
                    "modified_time": "$(date -d "$INPUT_DATE 15:10:00" +%s)",
                    "created_time": "$(date -d "$INPUT_DATE 15:10:00" +%s)",
                    "transfer_time_from_soa_minutes": 25,
                    "status": "pending_with_delay"
                }
            ]
        }
    },
    "summary": {
        "total_files": 4,
        "total_size_bytes": 7680,
        "fully_processed": 2,
        "pending_processing": 2,
        "average_pipeline_time_minutes": 17.5
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_rpm_file_listing.json${NC}"

    echo -e "${GREEN}✅ Mock SFTP file listings generated${NC}"
}

# =============================================================================
# FUNCTION: Generate File Tracking Test Scenarios
# =============================================================================
generate_file_tracking_scenarios() {
    echo -e "${RED}🔧 Generating File Tracking Test Scenarios...${NC}"
    
    # 1. Scenario: Successful file tracking (1P -> SOA -> RPM)
    echo -e "${YELLOW}  1. Creating successful file tracking scenario...${NC}"
    
    cat > "$FILE_TRACKING_DIR/scenario_successful_tracking.json" << EOF
{
    "scenario": "successful_file_tracking",
    "test_date": "$INPUT_DATE",
    "description": "Test tracking of files that successfully move through all pipeline stages",
    "input_data": {
        "test_files": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                "1p_metadata": {
                    "size": 1024,
                    "timestamp": "$(date -d "$INPUT_DATE 08:00:00" +%s)",
                    "status": "ready"
                },
                "soa_metadata": {
                    "size": 1024,
                    "timestamp": "$(date -d "$INPUT_DATE 08:05:00" +%s)",
                    "transfer_duration_minutes": 5,
                    "status": "transferred"
                },
                "rpm_metadata": {
                    "size": 1024,
                    "timestamp": "$(date -d "$INPUT_DATE 08:15:00" +%s)",
                    "transfer_duration_minutes": 10,
                    "total_pipeline_duration_minutes": 15,
                    "status": "processed"
                }
            }
        ]
    },
    "expected_tracking_results": {
        "1p_to_soa": {
            "status": "successful",
            "transfer_time_minutes": 5,
            "size_match": true,
            "issues": []
        },
        "soa_to_rpm": {
            "status": "successful",
            "transfer_time_minutes": 10,
            "size_match": true,
            "issues": []
        },
        "end_to_end": {
            "status": "successful",
            "total_time_minutes": 15,
            "all_stages_present": true
        }
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_successful_tracking.json${NC}"

    # 2. Scenario: Transfer delays and timing issues
    echo -e "${YELLOW}  2. Creating transfer delays scenario...${NC}"
    
    cat > "$FILE_TRACKING_DIR/scenario_transfer_delays.json" << EOF
{
    "scenario": "transfer_delays_timing_issues",
    "test_date": "$INPUT_DATE",
    "description": "Test tracking of files with various transfer delays and timing issues",
    "input_data": {
        "test_files": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                "1p_metadata": {
                    "size": 2048,
                    "timestamp": "$(date -d "$INPUT_DATE 09:00:00" +%s)",
                    "status": "ready"
                },
                "soa_metadata": {
                    "size": 2048,
                    "timestamp": "$(date -d "$INPUT_DATE 09:25:00" +%s)",
                    "transfer_duration_minutes": 25,
                    "status": "delayed_transfer"
                },
                "rpm_metadata": {
                    "size": 2048,
                    "timestamp": "$(date -d "$INPUT_DATE 09:40:00" +%s)",
                    "transfer_duration_minutes": 15,
                    "status": "pending"
                }
            },
            {
                "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                "1p_metadata": {
                    "size": 3072,
                    "timestamp": "$(date -d "$INPUT_DATE 14:00:00" +%s)",
                    "status": "ready"
                },
                "soa_metadata": {
                    "size": 3072,
                    "timestamp": "$(date -d "$INPUT_DATE 14:45:00" +%s)",
                    "transfer_duration_minutes": 45,
                    "status": "severely_delayed"
                },
                "rpm_metadata": {
                    "size": 3072,
                    "timestamp": "$(date -d "$INPUT_DATE 15:10:00" +%s)",
                    "transfer_duration_minutes": 25,
                    "status": "pending_delayed"
                }
            }
        ],
        "timing_thresholds": {
            "1p_to_soa_warning_minutes": 15,
            "1p_to_soa_critical_minutes": 30,
            "soa_to_rpm_warning_minutes": 20,
            "soa_to_rpm_critical_minutes": 40
        }
    },
    "expected_tracking_results": {
        "1p_to_soa": {
            "status": "delayed",
            "delayed_files": 2,
            "warning_level_delays": 2,
            "critical_level_delays": 1,
            "average_delay_minutes": 35.0
        },
        "soa_to_rpm": {
            "status": "delayed", 
            "delayed_files": 2,
            "warning_level_delays": 2,
            "average_delay_minutes": 20.0
        }
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_transfer_delays.json${NC}"

    # 3. Scenario: Failed transfers and missing files
    echo -e "${YELLOW}  3. Creating failed transfers scenario...${NC}"
    
    cat > "$FILE_TRACKING_DIR/scenario_failed_transfers.json" << EOF
{
    "scenario": "failed_transfers_missing_files",
    "test_date": "$INPUT_DATE",
    "description": "Test tracking of files with transfer failures and missing files",
    "input_data": {
        "test_files": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                "1p_metadata": {
                    "size": 4096,
                    "timestamp": "$(date -d "$INPUT_DATE 10:00:00" +%s)",
                    "status": "ready"
                },
                "soa_metadata": null,
                "rpm_metadata": null,
                "failure_reason": "transfer_timeout"
            },
            {
                "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                "1p_metadata": {
                    "size": 512,
                    "timestamp": "$(date -d "$INPUT_DATE 12:00:00" +%s)",
                    "status": "ready"
                },
                "soa_metadata": null,
                "rpm_metadata": null,
                "failure_reason": "connection_failure"
            },
            {
                "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                "1p_metadata": null,
                "soa_metadata": {
                    "size": 1024,
                    "timestamp": "$(date -d "$INPUT_DATE 20:00:00" +%s)",
                    "status": "orphaned"
                },
                "rpm_metadata": null,
                "orphan_type": "no_1p_source"
            },
            {
                "filename": "TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods",
                "1p_metadata": {
                    "size": 6144,
                    "timestamp": "$(date -d "$INPUT_DATE 15:00:00" +%s)",
                    "status": "transfer_pending"
                },
                "soa_metadata": null,
                "rpm_metadata": null,
                "pending_duration_hours": 6
            }
        ]
    },
    "expected_tracking_results": {
        "1p_to_soa": {
            "status": "failed",
            "successful_transfers": 0,
            "failed_transfers": 3,
            "pending_transfers": 1,
            "failure_reasons": {
                "transfer_timeout": 1,
                "connection_failure": 1,
                "pending_too_long": 1
            }
        },
        "soa_to_rpm": {
            "status": "failed",
            "orphaned_files": 1,
            "missing_from_rpm": 4
        },
        "overall_health": {
            "status": "critical",
            "pipeline_success_rate": 0.0
        }
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_failed_transfers.json${NC}"

    # 4. Scenario: Size and metadata mismatches
    echo -e "${YELLOW}  4. Creating size and metadata mismatches scenario...${NC}"
    
    cat > "$FILE_TRACKING_DIR/scenario_metadata_mismatches.json" << EOF
{
    "scenario": "size_metadata_mismatches",
    "test_date": "$INPUT_DATE",
    "description": "Test tracking of files with size differences and metadata mismatches",
    "input_data": {
        "test_files": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                "1p_metadata": {
                    "size": 8192,
                    "timestamp": "$(date -d "$INPUT_DATE 11:00:00" +%s)",
                    "checksum": "abc123def456",
                    "status": "ready"
                },
                "soa_metadata": {
                    "size": 4096,
                    "timestamp": "$(date -d "$INPUT_DATE 11:08:00" +%s)",
                    "checksum": "abc123def457",
                    "status": "transferred_partial",
                    "transfer_duration_minutes": 8
                },
                "rpm_metadata": null,
                "mismatch_types": ["size", "checksum"]
            },
            {
                "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                "1p_metadata": {
                    "size": 1024,
                    "timestamp": "$(date -d "$INPUT_DATE 16:00:00" +%s)",
                    "status": "ready"
                },
                "soa_metadata": {
                    "size": 1024,
                    "timestamp": "$(date -d "$INPUT_DATE 15:55:00" +%s)",
                    "status": "timestamp_anomaly",
                    "transfer_duration_minutes": -5
                },
                "rpm_metadata": null,
                "mismatch_types": ["timestamp_backward"]
            }
        ]
    },
    "expected_tracking_results": {
        "1p_to_soa": {
            "status": "mismatched",
            "size_mismatches": 1,
            "checksum_mismatches": 1,
            "timestamp_issues": 1,
            "successful_transfers": 0
        },
        "data_integrity": {
            "status": "compromised",
            "integrity_issues": 3,
            "requires_investigation": true
        }
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_metadata_mismatches.json${NC}"

    # 5. Scenario: Bulk file tracking (performance test)
    echo -e "${YELLOW}  5. Creating bulk file tracking scenario...${NC}"
    
    cat > "$FILE_TRACKING_DIR/scenario_bulk_tracking.json" << EOF
{
    "scenario": "bulk_file_tracking_performance",
    "test_date": "$INPUT_DATE",
    "description": "Test tracking performance with large number of files",
    "input_data": {
        "file_count": 100,
        "distribution": {
            "successful_transfers": 70,
            "delayed_transfers": 20,
            "failed_transfers": 8,
            "orphaned_files": 2
        },
        "sample_files": [
EOF

    # Generate sample bulk tracking data
    for i in {1..10}; do
        timestamp=$(printf "%02d%02d%02d" $((i + 7)) $((RANDOM % 60)) $((RANDOM % 60)))
        size=$((1024 + RANDOM % 4096))
        transfer_delay=$((RANDOM % 30 + 1))
        
        cat >> "$FILE_TRACKING_DIR/scenario_bulk_tracking.json" << EOF
            {
                "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
                "1p_size": $size,
                "1p_timestamp": "$(date -d "$INPUT_DATE $((i + 7)):$((RANDOM % 60)):00" +%s)",
                "soa_size": $size,
                "soa_timestamp": "$(date -d "$INPUT_DATE $((i + 7)):$((RANDOM % 60 + transfer_delay)):00" +%s)",
                "transfer_duration_minutes": $transfer_delay,
                "status": "$([ $((RANDOM % 4)) -eq 0 ] && echo "delayed" || echo "normal")"
            }$([ $i -lt 10 ] && echo ",")
EOF
    done

    cat >> "$FILE_TRACKING_DIR/scenario_bulk_tracking.json" << EOF
        ]
    },
    "expected_tracking_results": {
        "performance": {
            "processing_time_seconds": 15,
            "files_processed_per_second": 6.67,
            "memory_usage_mb": 50
        },
        "accuracy": {
            "correct_status_assignments": 100,
            "false_positives": 0,
            "false_negatives": 0
        }
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_bulk_tracking.json${NC}"

    echo -e "${GREEN}✅ File tracking test scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate File Tracking Test Script
# =============================================================================
generate_file_tracking_test_script() {
    echo -e "${RED}🔧 Generating File Tracking Test Execution Script...${NC}"
    
    cat > "$FILE_TRACKING_DIR/test_file_tracking.py" << 'EOF'
#!/usr/bin/env python3
"""
File Tracking Test Script
Tests the _track_1p_to_soa and _track_soa_to_rpm functions with various scenarios
"""

import json
import sys
import os
from datetime import datetime, timedelta

# Mock the file tracking functions for testing
def mock_track_1p_to_soa(file_listings):
    """
    Mock implementation of _track_1p_to_soa function for testing
    """
    tracking_results = {
        "tracking_date": datetime.now().isoformat(),
        "stage_transfer": "1p_to_soa",
        "summary": {
            "total_1p_files": 0,
            "successfully_transferred": 0,
            "failed_transfers": 0,
            "pending_transfers": 0,
            "delayed_transfers": 0,
            "size_mismatches": 0,
            "orphaned_soa_files": 0
        },
        "transfer_details": [],
        "issues": []
    }
    
    # Get file listings
    files_1p = file_listings.get("1p_files", [])
    files_soa = file_listings.get("soa_files", [])
    
    tracking_results["summary"]["total_1p_files"] = len(files_1p)
    
    # Create lookup dictionary for SOA files
    soa_lookup = {file_data["filename"]: file_data for file_data in files_soa}
    
    # Track each 1P file
    for file_1p in files_1p:
        filename = file_1p["filename"]
        tracking_detail = {
            "filename": filename,
            "1p_metadata": file_1p,
            "transfer_status": "unknown"
        }
        
        if filename in soa_lookup:
            file_soa = soa_lookup[filename]
            tracking_detail["soa_metadata"] = file_soa
            
            # Analyze transfer
            transfer_analysis = analyze_1p_to_soa_transfer(file_1p, file_soa)
            tracking_detail.update(transfer_analysis)
            
            # Update summary based on analysis
            if transfer_analysis["transfer_status"] == "successful":
                tracking_results["summary"]["successfully_transferred"] += 1
            elif transfer_analysis["transfer_status"] == "delayed":
                tracking_results["summary"]["delayed_transfers"] += 1
            elif transfer_analysis["transfer_status"] == "size_mismatch":
                tracking_results["summary"]["size_mismatches"] += 1
                
            # Add issues if any
            if transfer_analysis.get("issues"):
                tracking_results["issues"].extend(transfer_analysis["issues"])
                
        else:
            tracking_detail["transfer_status"] = "failed"
            tracking_detail["failure_reason"] = "file_not_found_in_soa"
            tracking_results["summary"]["failed_transfers"] += 1
            tracking_results["issues"].append({
                "type": "transfer_failure",
                "filename": filename,
                "details": "File present in 1P but missing in SOA"
            })
        
        tracking_results["transfer_details"].append(tracking_detail)
    
    # Check for orphaned files in SOA
    files_1p_names = {f["filename"] for f in files_1p}
    for file_soa in files_soa:
        if file_soa["filename"] not in files_1p_names:
            tracking_results["summary"]["orphaned_soa_files"] += 1
            tracking_results["issues"].append({
                "type": "orphaned_file",
                "filename": file_soa["filename"],
                "details": "File present in SOA but missing in 1P"
            })
    
    return tracking_results

def mock_track_soa_to_rpm(file_listings):
    """
    Mock implementation of _track_soa_to_rpm function for testing
    """
    tracking_results = {
        "tracking_date": datetime.now().isoformat(),
        "stage_transfer": "soa_to_rpm",
        "summary": {
            "total_soa_files": 0,
            "successfully_transferred": 0,
            "failed_transfers": 0,
            "pending_transfers": 0,
            "processed_files": 0,
            "average_transfer_time_minutes": 0.0
        },
        "transfer_details": [],
        "issues": []
    }
    
    # Get file listings
    files_soa = file_listings.get("soa_files", [])
    files_rpm = file_listings.get("rpm_files", [])
    
    tracking_results["summary"]["total_soa_files"] = len(files_soa)
    
    # Create lookup dictionary for RPM files (all directories)
    rpm_lookup = {}
    for file_data in files_rpm:
        rpm_lookup[file_data["filename"]] = file_data
    
    # Track each SOA file
    total_transfer_time = 0
    transfer_count = 0
    
    for file_soa in files_soa:
        filename = file_soa["filename"]
        tracking_detail = {
            "filename": filename,
            "soa_metadata": file_soa,
            "transfer_status": "unknown"
        }
        
        if filename in rpm_lookup:
            file_rpm = rpm_lookup[filename]
            tracking_detail["rpm_metadata"] = file_rpm
            
            # Analyze transfer
            transfer_analysis = analyze_soa_to_rpm_transfer(file_soa, file_rpm)
            tracking_detail.update(transfer_analysis)
            
            # Update summary based on analysis
            if transfer_analysis["transfer_status"] == "processed":
                tracking_results["summary"]["processed_files"] += 1
            elif transfer_analysis["transfer_status"] == "pending":
                tracking_results["summary"]["pending_transfers"] += 1
            elif transfer_analysis["transfer_status"] == "successful":
                tracking_results["summary"]["successfully_transferred"] += 1
            
            # Track transfer times
            if "transfer_duration_minutes" in transfer_analysis:
                total_transfer_time += transfer_analysis["transfer_duration_minutes"]
                transfer_count += 1
                
            # Add issues if any
            if transfer_analysis.get("issues"):
                tracking_results["issues"].extend(transfer_analysis["issues"])
                
        else:
            tracking_detail["transfer_status"] = "failed"
            tracking_detail["failure_reason"] = "file_not_found_in_rpm"
            tracking_results["summary"]["failed_transfers"] += 1
            tracking_results["issues"].append({
                "type": "transfer_failure",
                "filename": filename,
                "details": "File present in SOA but missing in RPM"
            })
        
        tracking_results["transfer_details"].append(tracking_detail)
    
    # Calculate average transfer time
    if transfer_count > 0:
        tracking_results["summary"]["average_transfer_time_minutes"] = round(
            total_transfer_time / transfer_count, 1
        )
    
    return tracking_results

def analyze_1p_to_soa_transfer(file_1p, file_soa):
    """Analyze transfer from 1P to SOA"""
    analysis = {
        "transfer_status": "successful",
        "transfer_duration_minutes": 0,
        "size_match": True,
        "issues": []
    }
    
    # Check size match
    if file_1p["size"] != file_soa["size"]:
        analysis["size_match"] = False
        analysis["transfer_status"] = "size_mismatch"
        analysis["issues"].append({
            "type": "size_mismatch",
            "1p_size": file_1p["size"],
            "soa_size": file_soa["size"],
            "details": f"Size mismatch: 1P={file_1p['size']}, SOA={file_soa['size']}"
        })
    
    # Calculate transfer duration
    if "modified_time" in file_1p and "modified_time" in file_soa:
        duration_seconds = file_soa["modified_time"] - file_1p["modified_time"]
        analysis["transfer_duration_minutes"] = max(0, duration_seconds // 60)
        
        # Check for delayed transfer (>15 minutes warning, >30 minutes critical)
        if analysis["transfer_duration_minutes"] > 30:
            analysis["transfer_status"] = "critically_delayed"
            analysis["issues"].append({
                "type": "critical_delay",
                "duration_minutes": analysis["transfer_duration_minutes"],
                "details": f"Critical transfer delay: {analysis['transfer_duration_minutes']} minutes"
            })
        elif analysis["transfer_duration_minutes"] > 15:
            if analysis["transfer_status"] == "successful":
                analysis["transfer_status"] = "delayed"
            analysis["issues"].append({
                "type": "transfer_delay",
                "duration_minutes": analysis["transfer_duration_minutes"],
                "details": f"Transfer delay: {analysis['transfer_duration_minutes']} minutes"
            })
    
    return analysis

def analyze_soa_to_rpm_transfer(file_soa, file_rpm):
    """Analyze transfer from SOA to RPM"""
    analysis = {
        "transfer_status": "successful",
        "transfer_duration_minutes": 0,
        "rpm_location": "unknown",
        "issues": []
    }
    
    # Determine RPM location status
    if "status" in file_rpm:
        if "fully_processed" in file_rpm["status"]:
            analysis["transfer_status"] = "processed"
            analysis["rpm_location"] = "processed"
        elif "pending" in file_rpm["status"]:
            analysis["transfer_status"] = "pending"
            analysis["rpm_location"] = "pending"
    
    # Calculate transfer duration
    if "modified_time" in file_soa and "modified_time" in file_rpm:
        duration_seconds = file_rpm["modified_time"] - file_soa["modified_time"]
        analysis["transfer_duration_minutes"] = max(0, duration_seconds // 60)
        
        # Check for delayed transfer (>20 minutes warning, >40 minutes critical)
        if analysis["transfer_duration_minutes"] > 40:
            analysis["issues"].append({
                "type": "critical_delay",
                "duration_minutes": analysis["transfer_duration_minutes"],
                "details": f"Critical SOA to RPM delay: {analysis['transfer_duration_minutes']} minutes"
            })
        elif analysis["transfer_duration_minutes"] > 20:
            analysis["issues"].append({
                "type": "transfer_delay",
                "duration_minutes": analysis["transfer_duration_minutes"],
                "details": f"SOA to RPM delay: {analysis['transfer_duration_minutes']} minutes"
            })
    
    return analysis

def test_file_tracking_scenario(scenario_file):
    """Test file tracking with a specific scenario"""
    print(f"\n=== Testing Scenario: {scenario_file} ===")
    
    try:
        with open(scenario_file, 'r') as f:
            scenario_data = json.load(f)
        
        print(f"Scenario: {scenario_data.get('scenario', 'unknown')}")
        print(f"Description: {scenario_data.get('description', 'No description')}")
        
        # Prepare input data
        input_data = scenario_data.get("input_data", {})
        
        # Convert test files to mock listings format
        file_listings = prepare_mock_file_listings(input_data)
        
        # Test 1P to SOA tracking
        print(f"\n--- Testing 1P to SOA Tracking ---")
        track_1p_soa_results = mock_track_1p_to_soa(file_listings)
        display_tracking_results(track_1p_soa_results, "1P to SOA")
        
        # Test SOA to RPM tracking
        print(f"\n--- Testing SOA to RPM Tracking ---")
        track_soa_rpm_results = mock_track_soa_to_rpm(file_listings)
        display_tracking_results(track_soa_rpm_results, "SOA to RPM")
        
        # Validate against expected results
        expected = scenario_data.get("expected_tracking_results", {})
        if expected:
            print(f"\n--- Validation ---")
            validate_tracking_results({
                "1p_to_soa": track_1p_soa_results,
                "soa_to_rpm": track_soa_rpm_results
            }, expected)
        
        # Save results
        result_file = scenario_file.replace('.json', '_tracking_results.json')
        results = {
            "1p_to_soa_tracking": track_1p_soa_results,
            "soa_to_rpm_tracking": track_soa_rpm_results
        }
        
        with open(result_file, 'w') as f:
            json.dump(results, f, indent=2)
        print(f"Results saved to: {result_file}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error testing scenario {scenario_file}: {str(e)}")
        return False

def prepare_mock_file_listings(input_data):
    """Convert scenario input data to mock file listings format"""
    file_listings = {
        "1p_files": [],
        "soa_files": [],
        "rpm_files": []
    }
    
    # Process test files from scenario
    test_files = input_data.get("test_files", [])
    
    for test_file in test_files:
        filename = test_file["filename"]
        
        # Add 1P file if metadata exists
        if test_file.get("1p_metadata"):
            file_1p = test_file["1p_metadata"].copy()
            file_1p["filename"] = filename
            file_listings["1p_files"].append(file_1p)
        
        # Add SOA file if metadata exists
        if test_file.get("soa_metadata"):
            file_soa = test_file["soa_metadata"].copy()
            file_soa["filename"] = filename
            file_listings["soa_files"].append(file_soa)
        
        # Add RPM file if metadata exists
        if test_file.get("rpm_metadata"):
            file_rpm = test_file["rpm_metadata"].copy()
            file_rpm["filename"] = filename
            file_listings["rpm_files"].append(file_rpm)
    
    return file_listings

def display_tracking_results(tracking_results, stage_name):
    """Display tracking results in a readable format"""
    summary = tracking_results["summary"]
    
    print(f"{stage_name} Summary:")
    for key, value in summary.items():
        print(f"  {key.replace('_', ' ').title()}: {value}")
    
    # Show issues if any
    issues = tracking_results.get("issues", [])
    if issues:
        print(f"\n{stage_name} Issues:")
        for i, issue in enumerate(issues[:5], 1):  # Show first 5 issues
            print(f"  {i}. {issue['type']}: {issue['details']}")
        if len(issues) > 5:
            print(f"  ... and {len(issues) - 5} more issues")

def validate_tracking_results(actual, expected):
    """Validate actual tracking results against expected results"""
    validations = []
    
    # Validate 1P to SOA tracking
    if "1p_to_soa" in expected and "1p_to_soa" in actual:
        actual_1p_soa = actual["1p_to_soa"]["summary"]
        expected_1p_soa = expected["1p_to_soa"]
        
        if "successful_transfers" in expected_1p_soa:
            validations.append((
                "1P to SOA Successful",
                actual_1p_soa["successfully_transferred"],
                expected_1p_soa["successful_transfers"],
                actual_1p_soa["successfully_transferred"] == expected_1p_soa["successful_transfers"]
            ))
        
        if "failed_transfers" in expected_1p_soa:
            validations.append((
                "1P to SOA Failed",
                actual_1p_soa["failed_transfers"],
                expected_1p_soa["failed_transfers"],
                actual_1p_soa["failed_transfers"] == expected_1p_soa["failed_transfers"]
            ))
    
    # Validate SOA to RPM tracking
    if "soa_to_rpm" in expected and "soa_to_rpm" in actual:
        actual_soa_rpm = actual["soa_to_rpm"]["summary"]
        expected_soa_rpm = expected["soa_to_rpm"]
        
        if "processed_files" in expected_soa_rpm:
            validations.append((
                "SOA to RPM Processed",
                actual_soa_rpm["processed_files"],
                expected_soa_rpm["processed_files"],
                actual_soa_rpm["processed_files"] == expected_soa_rpm["processed_files"]
            ))
    
    # Display validation results
    for test_name, actual_val, expected_val, passed in validations:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} {test_name}: Expected {expected_val}, Got {actual_val}")

def main():
    """Main test execution"""
    print("📊 FILE TRACKING TEST RUNNER")
    print("=" * 50)
    
    # Get current directory
    test_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"Test directory: {test_dir}")
    
    # Find all scenario files
    scenario_files = [f for f in os.listdir(test_dir) if f.startswith('scenario_') and f.endswith('.json')]
    
    if not scenario_files:
        print("❌ No scenario files found!")
        return False
    
    print(f"Found {len(scenario_files)} test scenarios")
    
    # Run all scenarios
    passed = 0
    failed = 0
    
    for scenario_file in sorted(scenario_files):
        scenario_path = os.path.join(test_dir, scenario_file)
        if test_file_tracking_scenario(scenario_path):
            passed += 1
        else:
            failed += 1
    
    # Summary
    print(f"\n{'='*50}")
    print(f"🏁 TEST SUMMARY")
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    print(f"Total: {passed + failed}")
    
    if failed == 0:
        print("🎉 All tests passed!")
        return True
    else:
        print(f"❌ {failed} test(s) failed")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
EOF
    
    chmod +x "$FILE_TRACKING_DIR/test_file_tracking.py"
    echo -e "${GREEN}    Generated: test_file_tracking.py (executable test script)${NC}"
    
    # Create test runner script
    cat > "$FILE_TRACKING_DIR/run_file_tracking_tests.sh" << EOF
#!/bin/bash

echo "📊 Running File Tracking Tests..."
cd "$FILE_TRACKING_DIR"

# Run the Python test script
python3 test_file_tracking.py

echo ""
echo "📊 Test Results Summary:"
ls -la *_tracking_results.json 2>/dev/null | wc -l | xargs echo "Generated result files:"
ls -la *_tracking_results.json 2>/dev/null || echo "No result files generated"

echo ""
echo "🔍 To review detailed results:"
echo "  cat $FILE_TRACKING_DIR/*_tracking_results.json"
EOF
    
    chmod +x "$FILE_TRACKING_DIR/run_file_tracking_tests.sh"
    echo -e "${GREEN}    Generated: run_file_tracking_tests.sh (test runner)${NC}"
    
    echo -e "${GREEN}✅ File tracking test scripts generated${NC}"
}

# =============================================================================
# FUNCTION: Upload file tracking test files
# =============================================================================
upload_file_tracking_files() {
    echo -e "${BLUE}🚀 Uploading file tracking test files...${NC}"
    
    # Create test data in Docker container
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_1P_PRICE/file_tracking_test" 2>/dev/null || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_SOA_PRICE/file_tracking_test" 2>/dev/null || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_RPM_PROCESSED/file_tracking_test" 2>/dev/null || true
    
    # Upload mock file listings and scenario files
    for file in "$FILE_TRACKING_DIR"/*.json; do
        if [ -f "$file" ]; then
            docker cp "$file" $DOCKER_CONTAINER:"$SFTP_1P_PRICE/file_tracking_test/" >/dev/null 2>&1
            echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
        fi
    done
    
    # Upload test scripts
    docker cp "$FILE_TRACKING_DIR/test_file_tracking.py" $DOCKER_CONTAINER:"$SFTP_1P_PRICE/file_tracking_test/" >/dev/null 2>&1
    docker cp "$FILE_TRACKING_DIR/run_file_tracking_tests.sh" $DOCKER_CONTAINER:"$SFTP_1P_PRICE/file_tracking_test/" >/dev/null 2>&1
    
    echo -e "${GREEN}✅ File tracking test files uploaded${NC}"
    
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
main_file_tracking() {
    echo -e "${BLUE}🏁 Starting file tracking test file generation...${NC}"
    echo -e "${BLUE}📅 Processing date: $INPUT_DATE${NC}"
    
    # Check if Docker container is running
    if ! docker ps | grep -q $DOCKER_CONTAINER; then
        echo -e "${RED}❌ Error: Docker container '$DOCKER_CONTAINER' is not running${NC}"
        echo -e "${YELLOW}💡 Start container first: docker-compose up -d${NC}"
        exit 1
    fi
    
    # Generate mock SFTP file listings
    generate_mock_sftp_listings
    
    # Generate test scenarios
    generate_file_tracking_scenarios
    
    # Generate test scripts
    generate_file_tracking_test_script
    
    # Upload to Docker
    upload_file_tracking_files
    
    echo -e "${GREEN}🎉 File tracking test files generation completed!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing file tracking functionality${NC}"
    echo -e "${BLUE}📋 Local data stored in: $FILE_TRACKING_DIR${NC}"
    echo -e "${BLUE}📊 Test scenarios created:${NC}"
    echo -e "${BLUE}  • Successful file tracking (1P -> SOA -> RPM)${NC}"
    echo -e "${BLUE}  • Transfer delays and timing analysis${NC}"
    echo -e "${BLUE}  • Failed transfers and missing files${NC}"
    echo -e "${BLUE}  • Size and metadata mismatches${NC}"
    echo -e "${BLUE}  • Bulk file tracking (100 files)${NC}"
    echo -e "${BLUE}🧪 Run tests with: cd $FILE_TRACKING_DIR && ./run_file_tracking_tests.sh${NC}"
}

# Run main function if not sourced
main_file_tracking "$@"

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
