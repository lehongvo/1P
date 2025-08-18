#!/bin/bash

# =============================================================================
# MASTER VALIDATION TEST RUNNER
# =============================================================================
#
# This script runs all validation test scenarios for the DAG:
# monitoring_dashboard_price_and_promotion_1p_rpm_file_tracking
#
# USAGE:
#   ./run_all_validation_tests.sh [YYYY-MM-DD] [--clean] [--test-type]
#
# OPTIONS:
#   --clean           Clean all files from Docker container before testing
#   --test-type TYPE         Run specific test: format|required-fields|data-types|file-size|duplicates|corrupt|missing|mismatches|auto-correction|flag-issues|auto-feedback|file-tracking|validation|monitoring|all
#   --help            Show this help message
#
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default parameters
INPUT_DATE=""
CLEAN_DOCKER=0
TEST_TYPE="all"
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Parse arguments
for arg in "$@"; do
    if [[ "$arg" == "--clean" ]]; then
        CLEAN_DOCKER=1
    elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        echo -e "${CYAN}=== MASTER VALIDATION TEST RUNNER ===${NC}"
        echo -e "${YELLOW}Usage: $0 [YYYY-MM-DD] [--clean] [--test-type TYPE]${NC}"
        echo -e "${YELLOW}Options:${NC}"
        echo -e "${YELLOW}  --clean                  Clean all files from Docker container first${NC}"
        echo -e "${YELLOW}  --test-type TYPE         Run specific test: format|required-fields|data-types|file-size|duplicates|corrupt|missing|mismatches|auto-correction|flag-issues|auto-feedback|file-tracking|fetch-1p|fetch-soa|fetch-rpm|fetch|validation|monitoring|all${NC}"
        echo -e "${YELLOW}  --help                   Show this help message${NC}"
        echo -e "${YELLOW}Examples:${NC}"
        echo -e "${YELLOW}  $0                       # Run all tests with current date${NC}"
        echo -e "${YELLOW}  $0 2024-08-15            # Run all tests with specific date${NC}"
        echo -e "${YELLOW}  $0 --test-type duplicates # Run only duplicate detection tests${NC}"
        echo -e "${YELLOW}  $0 --test-type validation # Run all core validation tests${NC}"
        echo -e "${YELLOW}  $0 --test-type monitoring # Run all monitoring/detection tests${NC}"
        echo -e "${YELLOW}  $0 --clean               # Clean Docker and run all tests${NC}"
        exit 0
    elif [[ "$arg" =~ ^--test-type$ ]]; then
        # Next argument should be the test type
        continue
    elif [[ "$arg" =~ ^(format|required-fields|data-types|file-size|duplicates|corrupt|missing|mismatches|auto-correction|flag-issues|auto-feedback|file-tracking|fetch-1p|fetch-soa|fetch-rpm|fetch|validation|monitoring|all)$ ]]; then
        TEST_TYPE="$arg"
    elif [[ "$arg" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        INPUT_DATE="$arg"
    elif [[ "$arg" == --* ]]; then
        echo -e "${RED}❌ Error: Unknown option '$arg'${NC}"
        exit 1
    fi
done

# If no date was provided, use current date
if [ -z "$INPUT_DATE" ]; then
    INPUT_DATE=$(date +%Y-%m-%d)
fi

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                  VALIDATION TEST SUITE                       ║${NC}"
echo -e "${CYAN}║           DAG: monitoring_dashboard_price_and_promotion      ║${NC}"
echo -e "${CYAN}║                 1p_rpm_file_tracking                         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}📅 Test Date: $INPUT_DATE${NC}"
echo -e "${YELLOW}🧪 Test Type: $TEST_TYPE${NC}"
echo -e "${YELLOW}🧹 Clean Mode: $([ $CLEAN_DOCKER -eq 1 ] && echo "ON" || echo "OFF")${NC}"
echo ""

# Check if Docker container is running
echo -e "${BLUE}🔍 Checking Docker container status...${NC}"
if ! docker ps | grep -q "lotus-sftp-1"; then
    echo -e "${RED}❌ Error: Docker container 'lotus-sftp-1' is not running${NC}"
    echo -e "${YELLOW}💡 Start container first: docker-compose up -d${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker container is running${NC}"
echo ""

# Function to run a test script with proper logging
run_test_script() {
    local script_name="$1"
    local test_description="$2"
    local script_path="$SCRIPT_DIR/$script_name"
    
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║ $test_description${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}❌ Error: Script not found: $script_path${NC}"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        echo -e "${YELLOW}⚠️ Making script executable: $script_path${NC}"
        chmod +x "$script_path"
    fi
    
    local start_time=$(date +%s)
    
    # Run the script with proper parameters
    local cmd_args=""
    if [ $CLEAN_DOCKER -eq 1 ] && [ "$script_name" = "generate_duplicates_test_files.sh" ]; then
        cmd_args="$INPUT_DATE --clean"
    else
        cmd_args="$INPUT_DATE"
    fi
    
    echo -e "${BLUE}🚀 Running: $script_name $cmd_args${NC}"
    
    if "$script_path" $cmd_args; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${GREEN}✅ Test completed successfully in ${duration}s${NC}"
        echo ""
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${RED}❌ Test failed after ${duration}s${NC}"
        echo ""
        return 1
    fi
}

# Function to show test summary
show_test_case_summary() {
    local test_name="$1"
    shift
    local test_cases=("$@")
    
    echo -e "${CYAN}📋 $test_name Test Cases:${NC}"
    for case in "${test_cases[@]}"; do
        echo -e "${YELLOW}   • $case${NC}"
    done
    echo ""
}

# Run specific test types or all tests
case "$TEST_TYPE" in
    "format")
        echo -e "${BLUE}📋 Running FILE FORMAT VALIDATION tests...${NC}"
        show_test_case_summary "FILE FORMAT VALIDATION" \
            "Invalid CSV format (missing/malformed headers)" \
            "Encoding issues (UTF-8, BOM)" \
            "Delimiter issues (semicolon, tab, mixed)" \
            "Line ending issues (Windows CRLF)" \
            "Wrong file type headers" \
            "Missing required columns"
        run_test_script "generate_file_format_validation_test.sh" "TESTING: validate_file_format"
        ;;
        
    "required-fields")
        echo -e "${BLUE}❌ Running REQUIRED FIELDS VALIDATION tests...${NC}"
        show_test_case_summary "REQUIRED FIELDS VALIDATION" \
            "Missing item_id field" \
            "Missing price field" \
            "Missing start_date field" \
            "Missing end_date field" \
            "Missing promotion_id field" \
            "Missing discount field" \
            "Empty required field values" \
            "Valid files for comparison"
        run_test_script "generate_required_fields_validation_test.sh" "TESTING: validate_required_fields"
        ;;
        
    "data-types")
        echo -e "${BLUE}🔢 Running DATA TYPES VALIDATION tests...${NC}"
        show_test_case_summary "DATA TYPES VALIDATION" \
            "Non-numeric price values" \
            "Invalid date formats" \
            "Negative and extreme prices" \
            "Invalid item_id formats" \
            "Invalid discount formats" \
            "Invalid promotion_id formats" \
            "Date logic errors (end_date before start_date)" \
            "Mixed multiple issues" \
            "Valid files for comparison"
        run_test_script "generate_data_types_validation_test.sh" "TESTING: validate_data_types"
        ;;
        
    "file-size")
        echo -e "${BLUE}📊 Running FILE SIZE VALIDATION tests...${NC}"
        show_test_case_summary "FILE SIZE VALIDATION" \
            "Extremely small files (headers only)" \
            "Very small files (< minimum threshold)" \
            "Large files (> maximum threshold)" \
            "Extremely large files (>> maximum threshold)" \
            "Normal sized files for comparison"
        run_test_script "generate_file_size_validation_test.sh" "TESTING: validate_file_size_ops"
        ;;
        
    "flag-issues")
        echo -e "${BLUE}🚩 Running ISSUE FLAGGING tests...${NC}"
        show_test_case_summary "ISSUE FLAGGING" \
            "Multiple issue types for single files" \
            "Different severity levels (critical, warning, info)" \
            "Cross-stage issue combinations" \
            "Issue prioritization and aggregation" \
            "Flag assignment based on issue types"
        run_test_script "generate_flag_issues_test.sh" "TESTING: _flag_issues"
        ;;
        
    "auto-feedback")
        echo -e "${BLUE}🔮 Running AUTO FEEDBACK tests...${NC}"
        show_test_case_summary "AUTO FEEDBACK" \
            "All systems healthy (green status)" \
            "Warning status with moderate issues" \
            "Critical status with severe issues" \
            "Mixed performance with partial recovery" \
            "System recovery after outage"
        run_test_script "generate_auto_feedback_test.sh" "TESTING: _auto_feedback"
        ;;
        
    "file-tracking")
        echo -e "${BLUE}📋 Running FILE TRACKING tests...${NC}"
        show_test_case_summary "FILE TRACKING" \
            "Successful file transfers" \
            "Transfer delays and timeouts" \
            "Failed transfers" \
            "Size and timestamp validation" \
            "Cross-stage matching and orphan detection"
        run_test_script "generate_file_tracking_test.sh" "TESTING: _track_1p_to_soa and _track_soa_to_rpm"
        ;;
        
    "fetch-1p")
        echo -e "${BLUE}📡 Running 1P FILES FETCH tests...${NC}"
        show_test_case_summary "1P FILES FETCH" \
            "Successful fetch operations (normal files)" \
            "Empty directory handling" \
            "Large directory performance (50+ files)" \
            "Connection failure scenarios" \
            "File format variety and filtering" \
            "DateTime folder path replacement"
        run_test_script "generate_fetch_1p_files_test.sh" "TESTING: fetch_files_from_1p"
        ;;
        
    "fetch-soa")
        echo -e "${BLUE}📦 Running SOA FILES FETCH tests...${NC}"
        show_test_case_summary "SOA FILES FETCH" \
            "Transferred files from 1P to SOA" \
            "Processed files ready for RPM" \
            "Orphaned files (SOA only, no 1P source)" \
            "Timestamp variation patterns" \
            "SOA connection failure scenarios" \
            "File metadata extraction tests"
        run_test_script "generate_fetch_soa_files_test.sh" "TESTING: fetch_files_from_soa"
        ;;
        
    "fetch-rpm")
        echo -e "${BLUE}⚙️ Running RPM FILES FETCH tests...${NC}"
        show_test_case_summary "RPM FILES FETCH" \
            "Successfully processed files (completed)" \
            "Pending processing files (queued)" \
            "Failed processing files (errors)" \
            "Multi-connection configuration tests" \
            "RPM-specific path handling tests" \
            "File status determination tests" \
            "Performance and scalability tests (30 files)"
        run_test_script "generate_fetch_rpm_files_test.sh" "TESTING: fetch_files_from_rpm"
        ;;
        
    "fetch")
        echo -e "${BLUE}📡 Running ALL FILE FETCH tests...${NC}"
        echo ""
        
        # Track test results
        declare -a passed_tests
        declare -a failed_tests
        
        # File Fetch Tests
        if run_test_script "generate_fetch_1p_files_test.sh" "TESTING: fetch_files_from_1p"; then
            passed_tests+=("1P Files Fetch")
        else
            failed_tests+=("1P Files Fetch")
        fi
        
        if run_test_script "generate_fetch_soa_files_test.sh" "TESTING: fetch_files_from_soa"; then
            passed_tests+=("SOA Files Fetch")
        else
            failed_tests+=("SOA Files Fetch")
        fi
        
        if run_test_script "generate_fetch_rpm_files_test.sh" "TESTING: fetch_files_from_rpm"; then
            passed_tests+=("RPM Files Fetch")
        else
            failed_tests+=("RPM Files Fetch")
        fi
        
        # Show final summary
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                FILE FETCH TEST SUMMARY                       ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        
        echo -e "${GREEN}✅ PASSED TESTS (${#passed_tests[@]}):${NC}"
        for test in "${passed_tests[@]}"; do
            echo -e "${GREEN}   ✓ $test${NC}"
        done
        
        if [ ${#failed_tests[@]} -gt 0 ]; then
            echo ""
            echo -e "${RED}❌ FAILED TESTS (${#failed_tests[@]}):${NC}"
            for test in "${failed_tests[@]}"; do
                echo -e "${RED}   ✗ $test${NC}"
            done
            echo ""
            echo -e "${RED}🚨 Some fetch tests failed! Please check the logs above.${NC}"
            exit 1
        else
            echo ""
            echo -e "${GREEN}🎉 ALL FILE FETCH TESTS PASSED!${NC}"
        fi
        ;;
        
    "validation")
        echo -e "${BLUE}✅ Running ALL CORE VALIDATION tests...${NC}"
        echo ""
        
        # Track test results
        declare -a passed_tests
        declare -a failed_tests
        
        # Core Validation Tests
        if run_test_script "generate_file_format_validation_test.sh" "TESTING: validate_file_format"; then
            passed_tests+=("File Format Validation")
        else
            failed_tests+=("File Format Validation")
        fi
        
        if run_test_script "generate_required_fields_validation_test.sh" "TESTING: validate_required_fields"; then
            passed_tests+=("Required Fields Validation")
        else
            failed_tests+=("Required Fields Validation")
        fi
        
        if run_test_script "generate_data_types_validation_test.sh" "TESTING: validate_data_types"; then
            passed_tests+=("Data Types Validation")
        else
            failed_tests+=("Data Types Validation")
        fi
        
        if run_test_script "generate_file_size_validation_test.sh" "TESTING: validate_file_size_ops"; then
            passed_tests+=("File Size Validation")
        else
            failed_tests+=("File Size Validation")
        fi
        
        # Show final summary
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                CORE VALIDATION TEST SUMMARY                  ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        
        echo -e "${GREEN}✅ PASSED TESTS (${#passed_tests[@]}):${NC}"
        for test in "${passed_tests[@]}"; do
            echo -e "${GREEN}   ✓ $test${NC}"
        done
        
        if [ ${#failed_tests[@]} -gt 0 ]; then
            echo ""
            echo -e "${RED}❌ FAILED TESTS (${#failed_tests[@]}):${NC}"
            for test in "${failed_tests[@]}"; do
                echo -e "${RED}   ✗ $test${NC}"
            done
            echo ""
            echo -e "${RED}🚨 Some core validation tests failed! Please check the logs above.${NC}"
            exit 1
        else
            echo ""
            echo -e "${GREEN}🎉 ALL CORE VALIDATION TESTS PASSED!${NC}"
        fi
        ;;
        
    "monitoring")
        echo -e "${BLUE}👁️ Running ALL MONITORING/DETECTION tests...${NC}"
        echo ""
        
        # Track test results
        declare -a passed_tests
        declare -a failed_tests
        
        # Monitoring/Detection Tests
        if run_test_script "generate_duplicates_test_files.sh" "TESTING: detect_duplicates_ops"; then
            passed_tests+=("Duplicate Detection")
        else
            failed_tests+=("Duplicate Detection")
        fi
        
        if run_test_script "generate_corrupt_files_test.sh" "TESTING: detect_corrupt_files"; then
            passed_tests+=("Corruption Detection")
        else
            failed_tests+=("Corruption Detection")
        fi
        
        if run_test_script "generate_missing_files_test.sh" "TESTING: detect_missing_files"; then
            passed_tests+=("Missing Files Detection")
        else
            failed_tests+=("Missing Files Detection")
        fi
        
        if run_test_script "generate_mismatches_test.sh" "TESTING: detect_mismatches"; then
            passed_tests+=("Mismatch Detection")
        else
            failed_tests+=("Mismatch Detection")
        fi
        
        if run_test_script "generate_auto_correction_test.sh" "TESTING: auto_correct_and_reupload_ops"; then
            passed_tests+=("Auto-correction")
        else
            failed_tests+=("Auto-correction")
        fi
        
        if run_test_script "generate_flag_issues_test.sh" "TESTING: _flag_issues"; then
            passed_tests+=("Issue Flagging")
        else
            failed_tests+=("Issue Flagging")
        fi
        
        if run_test_script "generate_auto_feedback_test.sh" "TESTING: _auto_feedback"; then
            passed_tests+=("Auto Feedback")
        else
            failed_tests+=("Auto Feedback")
        fi
        
        if run_test_script "generate_file_tracking_test.sh" "TESTING: _track_1p_to_soa and _track_soa_to_rpm"; then
            passed_tests+=("File Tracking")
        else
            failed_tests+=("File Tracking")
        fi
        
        # Show final summary
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              MONITORING/DETECTION TEST SUMMARY                ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        
        echo -e "${GREEN}✅ PASSED TESTS (${#passed_tests[@]}):${NC}"
        for test in "${passed_tests[@]}"; do
            echo -e "${GREEN}   ✓ $test${NC}"
        done
        
        if [ ${#failed_tests[@]} -gt 0 ]; then
            echo ""
            echo -e "${RED}❌ FAILED TESTS (${#failed_tests[@]}):${NC}"
            for test in "${failed_tests[@]}"; do
                echo -e "${RED}   ✗ $test${NC}"
            done
            echo ""
            echo -e "${RED}🚨 Some monitoring tests failed! Please check the logs above.${NC}"
            exit 1
        else
            echo ""
            echo -e "${GREEN}🎉 ALL MONITORING/DETECTION TESTS PASSED!${NC}"
        fi
        ;;
        
    "duplicates")
        echo -e "${BLUE}🔄 Running DUPLICATE DETECTION tests...${NC}"
        show_test_case_summary "DUPLICATE DETECTION" \
            "Source duplicates within same file" \
            "Cross-stage duplicates (1P ↔ SOA)" \
            "Orphaned files (exist in SOA only)" \
            "Complex duplicate patterns"
        run_test_script "generate_duplicates_test_files.sh" "TESTING: detect_duplicates_ops"
        ;;
        
    "corrupt")
        echo -e "${BLUE}💀 Running CORRUPTION DETECTION tests...${NC}"
        show_test_case_summary "CORRUPTION DETECTION" \
            "Zero-size files (0 bytes)" \
            "Files too small (< minimum size)" \
            "Files too large (> maximum size)" \
            "Unreadable/corrupted files" \
            "Files with encoding issues" \
            "Truncated/incomplete files"
        run_test_script "generate_corrupt_files_test.sh" "TESTING: detect_corrupt_files"
        ;;
        
    "missing")
        echo -e "${BLUE}❌ Running MISSING FILES DETECTION tests...${NC}"
        show_test_case_summary "MISSING FILES DETECTION" \
            "Transfer failures (exist in 1P, missing from SOA)" \
            "Data loss risk (old files >24h not processed)" \
            "Orphaned files (exist in SOA, not in 1P source)" \
            "RPM missing files (exist in 1P & SOA, missing from RPM)" \
            "Baseline files for comparison"
        run_test_script "generate_missing_files_test.sh" "TESTING: detect_missing_files"
        ;;
        
    "mismatches")
        echo -e "${BLUE}📏 Running MISMATCH DETECTION tests...${NC}"
        show_test_case_summary "MISMATCH DETECTION" \
            "Size mismatches (1P vs SOA different file sizes)" \
            "Time mismatches (>5 minutes timestamp difference)" \
            "Files missing from SOA (exist in 1P only)" \
            "Files missing from RPM (exist in 1P & SOA only)" \
            "Baseline files for comparison"
        run_test_script "generate_mismatches_test.sh" "TESTING: detect_mismatches"
        ;;
        
    "auto-correction")
        echo -e "${BLUE}🔧 Running AUTO-CORRECTION tests...${NC}"
        show_test_case_summary "AUTO-CORRECTION" \
            "Missing required fields (can add default values)" \
            "Data type mismatches (can convert formats)" \
            "Format issues (can clean up formatting)" \
            "Size issues (can split large files / skip small ones)" \
            "Duplicate entries (can remove exact duplicates)" \
            "Transfer failures (can retry transfers)"
        run_test_script "generate_auto_correction_test.sh" "TESTING: auto_correct_and_reupload_ops"
        ;;
        
    "all"|*)
        echo -e "${BLUE}🧪 Running ALL VALIDATION tests...${NC}"
        echo ""
        
        # Track test results
        declare -a passed_tests
        declare -a failed_tests
        
        # Core Validation Tests (Test 1-4)
        if run_test_script "generate_file_format_validation_test.sh" "TESTING: validate_file_format"; then
            passed_tests+=("File Format Validation")
        else
            failed_tests+=("File Format Validation")
        fi
        
        if run_test_script "generate_required_fields_validation_test.sh" "TESTING: validate_required_fields"; then
            passed_tests+=("Required Fields Validation")
        else
            failed_tests+=("Required Fields Validation")
        fi
        
        if run_test_script "generate_data_types_validation_test.sh" "TESTING: validate_data_types"; then
            passed_tests+=("Data Types Validation")
        else
            failed_tests+=("Data Types Validation")
        fi
        
        if run_test_script "generate_file_size_validation_test.sh" "TESTING: validate_file_size_ops"; then
            passed_tests+=("File Size Validation")
        else
            failed_tests+=("File Size Validation")
        fi
        
        # Detection and Monitoring Tests (Test 5-8)
        if run_test_script "generate_duplicates_test_files.sh" "TESTING: detect_duplicates_ops"; then
            passed_tests+=("Duplicate Detection")
        else
            failed_tests+=("Duplicate Detection")
        fi
        
        if run_test_script "generate_corrupt_files_test.sh" "TESTING: detect_corrupt_files"; then
            passed_tests+=("Corruption Detection")
        else
            failed_tests+=("Corruption Detection")
        fi
        
        if run_test_script "generate_missing_files_test.sh" "TESTING: detect_missing_files"; then
            passed_tests+=("Missing Files Detection")
        else
            failed_tests+=("Missing Files Detection")
        fi
        
        if run_test_script "generate_mismatches_test.sh" "TESTING: detect_mismatches"; then
            passed_tests+=("Mismatch Detection")
        else
            failed_tests+=("Mismatch Detection")
        fi
        
        # Processing and Feedback Tests (Test 9-12)
        if run_test_script "generate_auto_correction_test.sh" "TESTING: auto_correct_and_reupload_ops"; then
            passed_tests+=("Auto-correction")
        else
            failed_tests+=("Auto-correction")
        fi
        
        if run_test_script "generate_flag_issues_test.sh" "TESTING: _flag_issues"; then
            passed_tests+=("Issue Flagging")
        else
            failed_tests+=("Issue Flagging")
        fi
        
        if run_test_script "generate_auto_feedback_test.sh" "TESTING: _auto_feedback"; then
            passed_tests+=("Auto Feedback")
        else
            failed_tests+=("Auto Feedback")
        fi
        
        if run_test_script "generate_file_tracking_test.sh" "TESTING: _track_1p_to_soa and _track_soa_to_rpm"; then
            passed_tests+=("File Tracking")
        else
            failed_tests+=("File Tracking")
        fi
        
        # File Fetch Tests (Test 13-15)
        if run_test_script "generate_fetch_1p_files_test.sh" "TESTING: fetch_files_from_1p"; then
            passed_tests+=("1P Files Fetch")
        else
            failed_tests+=("1P Files Fetch")
        fi
        
        if run_test_script "generate_fetch_soa_files_test.sh" "TESTING: fetch_files_from_soa"; then
            passed_tests+=("SOA Files Fetch")
        else
            failed_tests+=("SOA Files Fetch")
        fi
        
        if run_test_script "generate_fetch_rpm_files_test.sh" "TESTING: fetch_files_from_rpm"; then
            passed_tests+=("RPM Files Fetch")
        else
            failed_tests+=("RPM Files Fetch")
        fi
        
        # Show final summary
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║               COMPREHENSIVE TEST SUMMARY                     ║${NC}"
        echo -e "${CYAN}║                      ALL DAG TASKS                           ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
        
        echo -e "${GREEN}✅ PASSED TESTS (${#passed_tests[@]}):${NC}"
        for test in "${passed_tests[@]}"; do
            echo -e "${GREEN}   ✓ $test${NC}"
        done
        
        if [ ${#failed_tests[@]} -gt 0 ]; then
            echo ""
            echo -e "${RED}❌ FAILED TESTS (${#failed_tests[@]}):${NC}"
            for test in "${failed_tests[@]}"; do
                echo -e "${RED}   ✗ $test${NC}"
            done
            echo ""
            echo -e "${RED}🚨 Some tests failed! Please check the logs above.${NC}"
            exit 1
        else
            echo ""
            echo -e "${GREEN}🎉 ALL TESTS PASSED! Your validation system is ready.${NC}"
        fi
        ;;
esac

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                     TEST EXECUTION COMPLETE                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${YELLOW}📊 Test data is now ready in your Docker containers${NC}"
echo -e "${YELLOW}🚀 You can now trigger the DAG to test the validation functions${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo -e "${BLUE}1. Go to Airflow UI: http://localhost:8080${NC}"
echo -e "${BLUE}2. Find DAG: monitoring_dashboard_price_and_promotion_1p_rpm_file_tracking${NC}"
echo -e "${BLUE}3. Trigger the DAG to test all validation functions${NC}"
echo -e "${BLUE}4. Check the logs for validation results${NC}"
echo ""
