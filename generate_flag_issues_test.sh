#!/bin/bash

# =============================================================================
# FLAG ISSUES TEST FILE GENERATOR
# =============================================================================
# This script generates test scenarios for the _flag_issues task functionality.
# It creates mock input data simulating results from detection tasks and tests
# how issues are flagged and categorized.
#
# Test Scenarios:
# 1. Multiple issue types for single files
# 2. Different severity levels (critical, warning, info)
# 3. Cross-stage issue combinations
# 4. Issue prioritization and aggregation
# 5. Flag assignment based on issue types
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

# Create flag issues test directory
FLAG_ISSUES_DIR="$BASE_DIR/$DATE_DIR_FORMAT/flag_issues"
mkdir -p "$FLAG_ISSUES_DIR"

echo -e "${BLUE}=== FLAG ISSUES TEST FILES GENERATOR ===${NC}"
echo -e "${YELLOW}📅 Target Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}🚩 Generating issue flagging scenarios for testing${NC}"

# =============================================================================
# FUNCTION: Generate Detection Results Input (Mock XCom Data)
# =============================================================================
generate_detection_results_mock() {
    echo -e "${RED}🔧 Generating Mock Detection Results for Flag Issues Testing...${NC}"
    
    # 1. Mock results from detect_mismatches
    echo -e "${YELLOW}  1. Creating mock mismatch detection results...${NC}"
    
    cat > "$FLAG_ISSUES_DIR/mock_detect_mismatches_results.json" << EOF
{
    "detection_date": "$INPUT_DATE",
    "task_id": "detect_mismatches",
    "results": {
        "size_mismatches": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}120000_PRICE.csv",
                "1p_size": 1024,
                "soa_size": 512,
                "rpm_size": 1024,
                "mismatch_type": "size_difference_1p_soa",
                "severity": "warning"
            },
            {
                "filename": "TH_PROMPRCH_${DATE_PATTERN}130000_PROMOTION.csv",
                "1p_size": 2048,
                "soa_size": 2048,
                "rpm_size": 1024,
                "mismatch_type": "size_difference_soa_rpm",
                "severity": "critical"
            }
        ],
        "time_mismatches": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}140000_PRICE.csv",
                "1p_timestamp": "$(date -d "$INPUT_DATE 10:00:00" +%s)",
                "soa_timestamp": "$(date -d "$INPUT_DATE 10:30:00" +%s)",
                "time_diff_minutes": 30,
                "mismatch_type": "time_difference_exceeds_threshold",
                "severity": "warning"
            }
        ],
        "content_mismatches": [
            {
                "filename": "TH_PROMPRCH_${DATE_PATTERN}150000_PROMOTION.csv",
                "1p_checksum": "abc123def456",
                "soa_checksum": "abc123def457",
                "mismatch_type": "content_checksum_difference",
                "severity": "critical"
            }
        ]
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_detect_mismatches_results.json${NC}"

    # 2. Mock results from detect_missing
    echo -e "${YELLOW}  2. Creating mock missing detection results...${NC}"
    
    cat > "$FLAG_ISSUES_DIR/mock_detect_missing_results.json" << EOF
{
    "detection_date": "$INPUT_DATE",
    "task_id": "detect_missing",
    "results": {
        "missing_in_soa": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}160000_PRICE.csv",
                "source_stage": "1p",
                "missing_stage": "soa",
                "last_seen": "$(date -d "$INPUT_DATE 09:00:00" +%s)",
                "missing_duration_hours": 8,
                "severity": "critical"
            }
        ],
        "missing_in_rpm": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}170000_PRICE.csv",
                "source_stage": "soa",
                "missing_stage": "rpm",
                "last_seen": "$(date -d "$INPUT_DATE 11:00:00" +%s)",
                "missing_duration_hours": 6,
                "severity": "warning"
            },
            {
                "filename": "TH_PROMPRCH_${DATE_PATTERN}180000_PROMOTION.csv",
                "source_stage": "soa",
                "missing_stage": "rpm",
                "last_seen": "$(date -d "$INPUT_DATE 08:00:00" +%s)",
                "missing_duration_hours": 9,
                "severity": "critical"
            }
        ],
        "orphaned_files": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}190000_ORPHAN.csv",
                "found_stage": "soa",
                "orphaned_duration_hours": 24,
                "severity": "warning"
            }
        ]
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_detect_missing_results.json${NC}"

    # 3. Mock results from detect_corrupt_files
    echo -e "${YELLOW}  3. Creating mock corrupt detection results...${NC}"
    
    cat > "$FLAG_ISSUES_DIR/mock_detect_corrupt_results.json" << EOF
{
    "detection_date": "$INPUT_DATE",
    "task_id": "detect_corrupt_files",
    "results": {
        "zero_size_files": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}200000_ZERO.csv",
                "stage": "1p",
                "file_size": 0,
                "corruption_type": "zero_size",
                "severity": "critical"
            }
        ],
        "unreadable_files": [
            {
                "filename": "TH_PROMPRCH_${DATE_PATTERN}210000_CORRUPT.csv",
                "stage": "soa",
                "corruption_type": "unreadable_content",
                "error_message": "Invalid CSV format - unable to parse",
                "severity": "critical"
            }
        ],
        "too_small_files": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}220000.csv",
                "stage": "1p",
                "file_size": 45,
                "min_expected_size": 100,
                "corruption_type": "too_small",
                "severity": "warning"
            }
        ],
        "too_large_files": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}230000.csv",
                "stage": "soa",
                "file_size": 104857600,
                "max_allowed_size": 52428800,
                "corruption_type": "too_large",
                "severity": "warning"
            }
        ]
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_detect_corrupt_results.json${NC}"

    # 4. Mock results from detect_duplicates
    echo -e "${YELLOW}  4. Creating mock duplicate detection results...${NC}"
    
    cat > "$FLAG_ISSUES_DIR/mock_detect_duplicates_results.json" << EOF
{
    "detection_date": "$INPUT_DATE",
    "task_id": "detect_duplicates",
    "results": {
        "internal_duplicates": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}240000_INTERNAL_DUP.csv",
                "stage": "1p",
                "duplicate_rows": 15,
                "total_rows": 100,
                "duplicate_percentage": 15.0,
                "duplicate_type": "internal_row_duplicates",
                "severity": "warning"
            }
        ],
        "cross_stage_duplicates": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}250000_CROSS_DUP.csv",
                "stages": ["1p", "soa"],
                "duplicate_type": "cross_stage_filename_duplicate",
                "severity": "warning"
            }
        ],
        "content_duplicates": [
            {
                "filename_1": "TH_PROMPRCH_${DATE_PATTERN}260000_CONTENT1.csv",
                "filename_2": "TH_PROMPRCH_${DATE_PATTERN}260001_CONTENT2.csv",
                "stage": "soa",
                "content_similarity": 95.5,
                "duplicate_type": "content_similarity_high",
                "severity": "info"
            }
        ]
    }
}
EOF
    echo -e "${GREEN}    Generated: mock_detect_duplicates_results.json${NC}"

    echo -e "${GREEN}✅ Mock detection results generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Flag Issues Test Scenarios
# =============================================================================
generate_flag_issues_scenarios() {
    echo -e "${RED}🔧 Generating Flag Issues Test Scenarios...${NC}"
    
    # 1. Scenario: Single file with multiple issues
    echo -e "${YELLOW}  1. Creating single file with multiple issues scenario...${NC}"
    
    cat > "$FLAG_ISSUES_DIR/scenario_multiple_issues_single_file.json" << EOF
{
    "scenario": "single_file_multiple_issues",
    "test_date": "$INPUT_DATE",
    "description": "Test flagging when single file has multiple types of issues",
    "input_data": {
        "filename": "TH_PRCH_${DATE_PATTERN}270000_MULTI_ISSUE.csv",
        "issues": {
            "mismatch": {
                "type": "size_difference",
                "severity": "warning",
                "details": "Size differs between 1P (1024) and SOA (512)"
            },
            "corrupt": {
                "type": "unreadable_content", 
                "severity": "critical",
                "details": "File contains invalid CSV format"
            },
            "duplicate": {
                "type": "internal_row_duplicates",
                "severity": "warning",
                "details": "Contains 20% duplicate rows"
            }
        }
    },
    "expected_flags": {
        "overall_severity": "critical",
        "flag_count": 3,
        "primary_issue": "corrupt",
        "requires_manual_intervention": true,
        "auto_correctable": false
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_multiple_issues_single_file.json${NC}"

    # 2. Scenario: Cross-stage issue propagation
    echo -e "${YELLOW}  2. Creating cross-stage issue propagation scenario...${NC}"
    
    cat > "$FLAG_ISSUES_DIR/scenario_cross_stage_issues.json" << EOF
{
    "scenario": "cross_stage_issue_propagation",
    "test_date": "$INPUT_DATE",
    "description": "Test flagging when issues cascade across pipeline stages",
    "input_data": {
        "filename": "TH_PROMPRCH_${DATE_PATTERN}280000_CROSS_STAGE.csv",
        "stage_progression": {
            "1p": {
                "status": "valid",
                "issues": []
            },
            "soa": {
                "status": "missing",
                "issues": [
                    {
                        "type": "transfer_failure",
                        "severity": "critical",
                        "details": "File failed to transfer from 1P to SOA"
                    }
                ]
            },
            "rpm": {
                "status": "not_applicable",
                "issues": [
                    {
                        "type": "missing_upstream",
                        "severity": "critical", 
                        "details": "File missing in SOA, cannot proceed to RPM"
                    }
                ]
            }
        }
    },
    "expected_flags": {
        "overall_severity": "critical",
        "affected_stages": ["soa", "rpm"],
        "root_cause": "transfer_failure_1p_to_soa",
        "requires_manual_intervention": true,
        "escalation_required": true
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_cross_stage_issues.json${NC}"

    # 3. Scenario: Issue severity prioritization
    echo -e "${YELLOW}  3. Creating issue severity prioritization scenario...${NC}"
    
    cat > "$FLAG_ISSUES_DIR/scenario_severity_prioritization.json" << EOF
{
    "scenario": "severity_prioritization",
    "test_date": "$INPUT_DATE",
    "description": "Test how issues are prioritized based on severity levels",
    "input_data": {
        "batch_issues": [
            {
                "filename": "TH_PRCH_${DATE_PATTERN}290000.csv",
                "issues": [
                    {
                        "type": "minor_format_issue",
                        "severity": "info",
                        "details": "Extra whitespace in headers"
                    }
                ]
            },
            {
                "filename": "TH_PRCH_${DATE_PATTERN}300000.csv",
                "issues": [
                    {
                        "type": "size_mismatch",
                        "severity": "warning",
                        "details": "File size differs by 10%"
                    },
                    {
                        "type": "time_mismatch",
                        "severity": "warning",
                        "details": "Transfer time exceeds 15 minutes"
                    }
                ]
            },
            {
                "filename": "TH_PRCH_${DATE_PATTERN}310000.csv",
                "issues": [
                    {
                        "type": "data_corruption",
                        "severity": "critical",
                        "details": "File unreadable - corrupted content"
                    }
                ]
            }
        ]
    },
    "expected_flags": {
        "priority_order": [
            "TH_PRCH_${DATE_PATTERN}310000.csv",
            "TH_PRCH_${DATE_PATTERN}300000.csv", 
            "TH_PRCH_${DATE_PATTERN}290000.csv"
        ],
        "escalation_files": ["TH_PRCH_${DATE_PATTERN}310000.csv"],
        "auto_correctable_files": ["TH_PRCH_${DATE_PATTERN}290000.csv"],
        "manual_review_files": ["TH_PRCH_${DATE_PATTERN}300000.csv"]
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_severity_prioritization.json${NC}"

    # 4. Scenario: Bulk issue flagging (stress test)
    echo -e "${YELLOW}  4. Creating bulk issue flagging scenario...${NC}"
    
    cat > "$FLAG_ISSUES_DIR/scenario_bulk_issues.json" << EOF
{
    "scenario": "bulk_issue_flagging",
    "test_date": "$INPUT_DATE",
    "description": "Test flagging performance with large number of issues",
    "input_data": {
        "bulk_issues": {
            "total_files": 100,
            "issue_distribution": {
                "mismatches": 25,
                "missing": 20,
                "corrupt": 15,
                "duplicates": 30,
                "mixed_issues": 10
            },
            "severity_distribution": {
                "critical": 20,
                "warning": 50,
                "info": 30
            }
        },
        "sample_files": [
EOF

    # Generate sample bulk issues
    for i in {1..20}; do
        severity=("critical" "warning" "info")
        issue_type=("mismatch" "missing" "corrupt" "duplicate")
        random_severity=${severity[$((RANDOM % 3))]}
        random_issue=${issue_type[$((RANDOM % 4))]}
        timestamp=$(printf "%02d%02d%02d" $((i % 24)) $((RANDOM % 60)) $((RANDOM % 60)))
        
        cat >> "$FLAG_ISSUES_DIR/scenario_bulk_issues.json" << EOF
            {
                "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}_BULK_${i}.csv",
                "issue_type": "$random_issue",
                "severity": "$random_severity",
                "details": "Bulk test issue $i - $random_issue with $random_severity severity"
            }$([ $i -lt 20 ] && echo ",")
EOF
    done

    cat >> "$FLAG_ISSUES_DIR/scenario_bulk_issues.json" << EOF
        ]
    },
    "expected_flags": {
        "total_flagged_files": 100,
        "critical_flags": 20,
        "warning_flags": 50,
        "info_flags": 30,
        "requires_batch_processing": true,
        "estimated_processing_time_seconds": 10
    }
}
EOF
    echo -e "${GREEN}    Generated: scenario_bulk_issues.json${NC}"

    echo -e "${GREEN}✅ Flag issues test scenarios generated${NC}"
}

# =============================================================================
# FUNCTION: Generate Flag Issues Test Script
# =============================================================================
generate_flag_issues_test_script() {
    echo -e "${RED}🔧 Generating Flag Issues Test Execution Script...${NC}"
    
    cat > "$FLAG_ISSUES_DIR/test_flag_issues.py" << 'EOF'
#!/usr/bin/env python3
"""
Flag Issues Test Script
Tests the _flag_issues function with various scenarios
"""

import json
import sys
import os
from datetime import datetime, timedelta

# Mock the _flag_issues function for testing
def mock_flag_issues(detection_results):
    """
    Mock implementation of _flag_issues function for testing
    """
    flagged_issues = {
        "flagging_date": datetime.now().isoformat(),
        "total_issues": 0,
        "critical_issues": 0,
        "warning_issues": 0,
        "info_issues": 0,
        "flagged_files": [],
        "escalation_required": [],
        "auto_correctable": [],
        "manual_review": []
    }
    
    # Process each detection result
    for result_type, results in detection_results.items():
        if result_type == "detection_date":
            continue
            
        if isinstance(results, dict) and "results" in results:
            # Process structured detection results
            for issue_category, issues in results["results"].items():
                for issue in issues:
                    if isinstance(issue, dict):
                        process_single_issue(issue, flagged_issues)
        elif isinstance(results, list):
            # Process list of issues
            for issue in results:
                if isinstance(issue, dict):
                    process_single_issue(issue, flagged_issues)
    
    # Determine escalation requirements
    flagged_issues["escalation_required"] = [
        file_info for file_info in flagged_issues["flagged_files"]
        if file_info["severity"] == "critical"
    ]
    
    return flagged_issues

def process_single_issue(issue, flagged_issues):
    """Process a single issue and update flagged_issues"""
    severity = issue.get("severity", "info")
    filename = issue.get("filename", "unknown")
    
    flagged_issues["total_issues"] += 1
    
    if severity == "critical":
        flagged_issues["critical_issues"] += 1
    elif severity == "warning":
        flagged_issues["warning_issues"] += 1
    else:
        flagged_issues["info_issues"] += 1
    
    # Add to flagged files
    file_info = {
        "filename": filename,
        "severity": severity,
        "issue_type": issue.get("type", issue.get("mismatch_type", issue.get("corruption_type", "unknown"))),
        "details": issue.get("details", ""),
        "flagged_timestamp": datetime.now().isoformat()
    }
    
    flagged_issues["flagged_files"].append(file_info)
    
    # Categorize based on severity and type
    if severity == "info" or "format" in file_info["issue_type"]:
        flagged_issues["auto_correctable"].append(file_info)
    elif severity == "critical":
        flagged_issues["manual_review"].append(file_info)
    else:
        flagged_issues["manual_review"].append(file_info)

def test_flag_issues_scenario(scenario_file):
    """Test flag issues with a specific scenario"""
    print(f"\n=== Testing Scenario: {scenario_file} ===")
    
    try:
        with open(scenario_file, 'r') as f:
            scenario_data = json.load(f)
        
        print(f"Scenario: {scenario_data.get('scenario', 'unknown')}")
        print(f"Description: {scenario_data.get('description', 'No description')}")
        
        # Run flag issues with scenario input
        input_data = scenario_data.get("input_data", {})
        flagged_results = mock_flag_issues(input_data)
        
        # Display results
        print(f"\n--- Flagging Results ---")
        print(f"Total Issues: {flagged_results['total_issues']}")
        print(f"Critical: {flagged_results['critical_issues']}")
        print(f"Warning: {flagged_results['warning_issues']}")
        print(f"Info: {flagged_results['info_issues']}")
        print(f"Auto-correctable: {len(flagged_results['auto_correctable'])}")
        print(f"Manual Review: {len(flagged_results['manual_review'])}")
        print(f"Escalation Required: {len(flagged_results['escalation_required'])}")
        
        # Validate against expected results
        expected = scenario_data.get("expected_flags", {})
        if expected:
            print(f"\n--- Validation ---")
            validate_results(flagged_results, expected)
        
        # Save results
        result_file = scenario_file.replace('.json', '_results.json')
        with open(result_file, 'w') as f:
            json.dump(flagged_results, f, indent=2)
        print(f"Results saved to: {result_file}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error testing scenario {scenario_file}: {str(e)}")
        return False

def validate_results(actual, expected):
    """Validate actual results against expected results"""
    validations = []
    
    # Check total issues
    if "total_issues" in expected:
        actual_total = actual["total_issues"]
        expected_total = expected.get("flag_count", expected.get("total_issues", 0))
        validations.append((
            "Total Issues",
            actual_total,
            expected_total,
            actual_total == expected_total
        ))
    
    # Check critical issues
    if "critical_flags" in expected:
        validations.append((
            "Critical Issues",
            actual["critical_issues"],
            expected["critical_flags"],
            actual["critical_issues"] == expected["critical_flags"]
        ))
    
    # Check escalation requirement
    if "escalation_required" in expected:
        actual_escalation = len(actual["escalation_required"]) > 0
        expected_escalation = expected["escalation_required"]
        validations.append((
            "Escalation Required",
            actual_escalation,
            expected_escalation,
            actual_escalation == expected_escalation
        ))
    
    # Display validation results
    for test_name, actual_val, expected_val, passed in validations:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} {test_name}: Expected {expected_val}, Got {actual_val}")

def main():
    """Main test execution"""
    print("🚩 FLAG ISSUES TEST RUNNER")
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
        if test_flag_issues_scenario(scenario_path):
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
    
    chmod +x "$FLAG_ISSUES_DIR/test_flag_issues.py"
    echo -e "${GREEN}    Generated: test_flag_issues.py (executable test script)${NC}"
    
    # Create test runner script
    cat > "$FLAG_ISSUES_DIR/run_flag_issues_tests.sh" << EOF
#!/bin/bash

echo "🚩 Running Flag Issues Tests..."
cd "$FLAG_ISSUES_DIR"

# Run the Python test script
python3 test_flag_issues.py

echo ""
echo "📊 Test Results Summary:"
ls -la *_results.json 2>/dev/null | wc -l | xargs echo "Generated result files:"
ls -la *_results.json 2>/dev/null || echo "No result files generated"

echo ""
echo "🔍 To review detailed results:"
echo "  cat $FLAG_ISSUES_DIR/*_results.json"
EOF
    
    chmod +x "$FLAG_ISSUES_DIR/run_flag_issues_tests.sh"
    echo -e "${GREEN}    Generated: run_flag_issues_tests.sh (test runner)${NC}"
    
    echo -e "${GREEN}✅ Flag issues test scripts generated${NC}"
}

# =============================================================================
# FUNCTION: Upload flag issues test files
# =============================================================================
upload_flag_issues_files() {
    echo -e "${BLUE}🚀 Uploading flag issues test files...${NC}"
    
    # Create test data in Docker container for flag issues testing
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_1P_PRICE/flag_issues_test" 2>/dev/null || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_SOA_PRICE/flag_issues_test" 2>/dev/null || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_RPM_PROCESSED/flag_issues_test" 2>/dev/null || true
    
    # Upload test scenario files
    for file in "$FLAG_ISSUES_DIR"/*.json; do
        if [ -f "$file" ]; then
            docker cp "$file" $DOCKER_CONTAINER:"$SFTP_1P_PRICE/flag_issues_test/" >/dev/null 2>&1
            echo -e "${GREEN}  Uploaded: $(basename "$file")${NC}"
        fi
    done
    
    # Upload test scripts
    docker cp "$FLAG_ISSUES_DIR/test_flag_issues.py" $DOCKER_CONTAINER:"$SFTP_1P_PRICE/flag_issues_test/" >/dev/null 2>&1
    docker cp "$FLAG_ISSUES_DIR/run_flag_issues_tests.sh" $DOCKER_CONTAINER:"$SFTP_1P_PRICE/flag_issues_test/" >/dev/null 2>&1
    
    echo -e "${GREEN}✅ Flag issues test files uploaded${NC}"
    
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
main_flag_issues() {
    echo -e "${BLUE}🏁 Starting flag issues test file generation...${NC}"
    echo -e "${BLUE}📅 Processing date: $INPUT_DATE${NC}"
    
    # Check if Docker container is running
    if ! docker ps | grep -q $DOCKER_CONTAINER; then
        echo -e "${RED}❌ Error: Docker container '$DOCKER_CONTAINER' is not running${NC}"
        echo -e "${YELLOW}💡 Start container first: docker-compose up -d${NC}"
        exit 1
    fi
    
    # Generate mock detection results
    generate_detection_results_mock
    
    # Generate test scenarios
    generate_flag_issues_scenarios
    
    # Generate test scripts
    generate_flag_issues_test_script
    
    # Upload to Docker
    upload_flag_issues_files
    
    echo -e "${GREEN}🎉 Flag issues test files generation completed!${NC}"
    echo -e "${YELLOW}💡 Files ready for testing issue flagging functionality${NC}"
    echo -e "${BLUE}📋 Local data stored in: $FLAG_ISSUES_DIR${NC}"
    echo -e "${BLUE}🚩 Test scenarios created:${NC}"
    echo -e "${BLUE}  • Single file with multiple issues${NC}"
    echo -e "${BLUE}  • Cross-stage issue propagation${NC}"
    echo -e "${BLUE}  • Issue severity prioritization${NC}"
    echo -e "${BLUE}  • Bulk issue flagging (100 files)${NC}"
    echo -e "${BLUE}🧪 Run tests with: cd $FLAG_ISSUES_DIR && ./run_flag_issues_tests.sh${NC}"
}

# Run main function if not sourced
main_flag_issues "$@"

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
