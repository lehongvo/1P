#!/bin/bash

# =============================================================================
# FLAG ISSUES DETECTION TEST SCRIPT
# 
# Purpose: Test the flag_issues task from CLUSTER 4: MONITORING & RECONCILIATION
# Task ID: flag_issues
# Function: _flag_issues
# 
# This script generates test scenarios to validate issue flagging and categorization
# system that aggregates results from detect_mismatches, detect_missing, detect_duplicates,
# and detect_corrupt_files tasks
# =============================================================================

set -e

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the base script for shared configurations
source "$SCRIPT_DIR/generate_mock_data.sh" --source-only

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
            echo "❌ Error: Invalid date '$INPUT_DATE'"
            exit 1
        fi
    elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        echo "Usage: $0 [YYYY-MM-DD] [--clean]"
        echo "  YYYY-MM-DD: Target date for test files"
        echo "  --clean: Clean existing files before generating new ones"
        exit 0
    fi
done

# Use current date if not provided
if [ -z "$INPUT_DATE" ]; then
    INPUT_DATE=$(date +%Y-%m-%d)
fi

# Docker container configuration
DOCKER_CONTAINER="lotus-sftp-1"

# Generate date formats from input (matching generate_mock_data.sh)
DATE_PATTERN=$(parse_date "$INPUT_DATE" "+%Y%m%d")
DATE_FORMAT=$(parse_date "$INPUT_DATE" "+%d%b%Y")
DATE_DIR_FORMAT="$INPUT_DATE"

# Test directory
TEST_DIR="$BASE_DIR/flag_issues_test_$INPUT_DATE"
mkdir -p "$TEST_DIR"

echo "=== FLAG ISSUES DETECTION TEST ===" 
echo "Date: $INPUT_DATE"
echo "Test directory: $TEST_DIR"
echo "Testing issue flagging and categorization system"
echo

# 1P, SOA, RPM folder paths
SFTP_1P_PRICE="/home/demo/sftp/Data/ITSRPC/outgoing_ok/RPR/TH"
SFTP_1P_PROMOTION="/home/demo/sftp/Data/ITSPMT/outgoing_ok/PPR/TH"
SFTP_SOA_PRICE="/home/demo/soa/Data/ITSRPC/outgoing_ok/RPR/TH"
SFTP_SOA_PROMOTION="/home/demo/soa/Data/ITSPMT/outgoing_ok/PPR/TH"
SFTP_RPM_PROCESSED="/home/demo/sftp/rpm/processed"
SFTP_RPM_PENDING="/home/demo/sftp/rpm/pending"

# =============================================================================
# FUNCTION: Generate comprehensive test scenarios for issue flagging
# =============================================================================
generate_flag_issues_test_scenarios() {
    echo "📁 Generating comprehensive test scenarios for issue flagging..."
    
    # Create local test directories
    mkdir -p "$TEST_DIR"/{1p_price,1p_promotion,soa_price,soa_promotion,rpm_processed,rpm_pending}
    mkdir -p "$TEST_DIR"/issue_reports
    
    # ==========================================================================
    # CREATE TEST FILES WITH PROPER NAMING CONVENTION ONLY
    # Format: TH_PRCH_YYYYMMDDHHMMSS.ods or TH_PROMPRCH_YYYYMMDDHHMMSS.ods
    # ==========================================================================
    echo "  Creating test files with proper naming convention..."
    
    # CRITICAL SEVERITY - Data corruption
    printf "item_id,price,date\nITEM001,100.00,$INPUT_DATE\n\x00CORRUPT_DATA\xFF\xFE" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # CRITICAL SEVERITY - Security breach
    cat > "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" << EOF
item_id,price,date,note
ITEM001,100.00,$INPUT_DATE,UNAUTHORIZED_MODIFICATION
<!-- SECURITY ALERT: Unauthorized script injection detected -->
EOF
    
    # HIGH SEVERITY - Data mismatch between stages
    echo "item_id,price,date
ITEM001,100.00,$INPUT_DATE
ITEM002,200.00,$INPUT_DATE" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    echo "item_id,price,date,processed_flag
ITEM001,100.00,$INPUT_DATE,PROCESSED
ITEM002,999.99,$INPUT_DATE,ERROR_PRICE_CHANGED" > "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # HIGH SEVERITY - Mass duplicates (10 files with same content)
    for i in {1..10}; do
        hour=$((i + 9))
        minute=$((i + 10))
        second=$((i + 20))
        timestamp=$(printf "%02d%02d%02d" $hour $minute $second)
        echo "item_id,price,date
ITEM_DUP,500.00,$INPUT_DATE
ITEM_DUP2,600.00,$INPUT_DATE" > "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}$timestamp.ods"
    done
    
    # MEDIUM SEVERITY - File transfer delay (exists in 1P only)
    echo "item_id,price,date
ITEM001,100.00,$INPUT_DATE
ITEM002,200.00,$INPUT_DATE" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # MEDIUM SEVERITY - Format validation issues
    cat > "$TEST_DIR/soa_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" << EOF
item_id;discount;date;comment
ITEM001;0.15;$INPUT_DATE;Using semicolon delimiter
ITEM002;0,20;$INPUT_DATE;Using comma for decimal
EOF
    
    # MEDIUM SEVERITY - Partial file corruption
    cat > "$TEST_DIR/rpm_pending/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" << EOF
item_id,price,date,status
ITEM001,100.00,$INPUT_DATE,VALID
ITEM002,200.00,$INPUT_DATE,VALID
CORRUPTED_ROW_BUT_RECOVERABLE
ITEM004,400.00,$INPUT_DATE,VALID
EOF
    
    # MEDIUM SEVERITY - Encoding issues
    printf "item_id,price,date,description\nITEM001,100.00,$INPUT_DATE,Café product\nITEM002,200.00,$INPUT_DATE,Naïve approach\x80\x81\n" > "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # LOW SEVERITY - Minor formatting inconsistencies
    cat > "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" << EOF
item_id,price,date,extra_spaces
ITEM001  ,  100.00  ,  $INPUT_DATE  ,  trailing spaces  
   ITEM002,200.00,$INPUT_DATE,leading spaces
ITEM003,300.00,$INPUT_DATE,normal formatting
EOF
    
    # LOW SEVERITY - Cross-stage duplicates (normal pipeline flow)
    echo "item_id,price,date
ITEM001,100.00,$INPUT_DATE
ITEM002,200.00,$INPUT_DATE" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    echo "item_id,price,date
ITEM001,100.00,$INPUT_DATE
ITEM002,200.00,$INPUT_DATE" > "$TEST_DIR/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    echo "item_id,price,date
ITEM001,100.00,$INPUT_DATE
ITEM002,200.00,$INPUT_DATE" > "$TEST_DIR/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # LOW SEVERITY - File size variations
    echo "item_id,price" > "$TEST_DIR/rpm_pending/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # MULTIPLE ISSUES - File with multiple problems (missing from SOA, has duplicate content and format issues)
    printf "item_id,price,date,status\nITEM001,100.00,$INPUT_DATE,ISSUE\nDUPLICATE_CONTENT\xFF\xFE\nITEM002,200.00\n" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Create issue reports
    echo "# Test scenario documentation for flag_issues task" > "$TEST_DIR/issue_reports/test_scenarios.txt"
    echo "Generated test files with various issue types for comprehensive testing" >> "$TEST_DIR/issue_reports/test_scenarios.txt"
    
    echo "✅ Test files generated with proper naming convention"
}

# =============================================================================
# FUNCTION: Create issue classification system
# =============================================================================
create_issue_classification_system() {
    echo "📋 Creating issue classification and metadata system..."
    
    # Create issue severity classification
    cat > "$TEST_DIR/issue_reports/severity_classification.json" << EOF
{
    "severity_levels": {
        "CRITICAL": {
            "priority": 1,
            "sla_response_time": "15_minutes",
            "escalation_required": true,
            "business_impact": "SEVERE",
            "examples": ["complete_pipeline_failure", "data_corruption", "security_breach"]
        },
        "HIGH": {
            "priority": 2,
            "sla_response_time": "1_hour",
            "escalation_required": true,
            "business_impact": "HIGH",
            "examples": ["data_mismatch", "mass_duplicates", "sla_breach"]
        },
        "MEDIUM": {
            "priority": 3,
            "sla_response_time": "4_hours",
            "escalation_required": false,
            "business_impact": "MODERATE",
            "examples": ["transfer_delays", "format_issues", "partial_corruption"]
        },
        "LOW": {
            "priority": 4,
            "sla_response_time": "24_hours",
            "escalation_required": false,
            "business_impact": "MINIMAL",
            "examples": ["minor_formatting", "normal_duplicates", "size_variations"]
        },
        "INFO": {
            "priority": 5,
            "sla_response_time": "monitoring_only",
            "escalation_required": false,
            "business_impact": "NONE",
            "examples": ["normal_processing", "performance_metrics", "status_updates"]
        }
    }
}
EOF
    
    echo "✅ Issue classification system created"
}

# =============================================================================
# FUNCTION: Upload flag issues test to Docker container
# =============================================================================
upload_flag_issues_test_to_docker() {
    echo "🐳 Uploading flag issues test data to Docker container..."
    
    # Check if Docker container exists
    if ! command -v docker &> /dev/null || ! docker ps | grep -q "$DOCKER_CONTAINER"; then
        echo "❌ Docker container '$DOCKER_CONTAINER' not found"
        return 1
    fi
    
    # Create directories in Docker container
    echo "  Creating directories in container..."
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_1P_PRICE" "$SFTP_1P_PROMOTION" >/dev/null 2>&1 || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_SOA_PRICE" "$SFTP_SOA_PROMOTION" >/dev/null 2>&1 || true
    docker exec $DOCKER_CONTAINER mkdir -p "$SFTP_RPM_PROCESSED" "$SFTP_RPM_PENDING" >/dev/null 2>&1 || true
    docker exec $DOCKER_CONTAINER mkdir -p "/tmp/issue_reports_$INPUT_DATE" >/dev/null 2>&1 || true
    
    # Function to upload files by severity level
    upload_files_by_severity() {
        local local_dir="$1"
        local docker_path="$2"
        local description="$3"
        
        if [ -d "$TEST_DIR/$local_dir" ] && [ -n "$(ls -A "$TEST_DIR/$local_dir" 2>/dev/null)" ]; then
            echo "  Uploading $description files..."
            local critical=0 high=0 medium=0 low=0 info=0
            
            for file in "$TEST_DIR/$local_dir"/*; do
                if [ -f "$file" ]; then
                    docker cp "$file" "$DOCKER_CONTAINER:$docker_path/" >/dev/null 2>&1
                    filename=$(basename "$file")
                    
                    # Categorize by severity for summary
                    if [[ "$filename" =~ 010[0-9]+ ]]; then
                        echo "    🚨 $filename (CRITICAL)"
                        critical=$((critical + 1))
                    elif [[ "$filename" =~ 020[0-9]+ ]]; then
                        echo "    ⚠️ $filename (HIGH)"
                        high=$((high + 1))
                    elif [[ "$filename" =~ 030[0-9]+ ]]; then
                        echo "    🟡 $filename (MEDIUM)"
                        medium=$((medium + 1))
                    elif [[ "$filename" =~ 040[0-9]+ ]]; then
                        echo "    🟢 $filename (LOW)"
                        low=$((low + 1))
                    else
                        echo "    ℹ️ $filename (INFO/OTHER)"
                        info=$((info + 1))
                    fi
                fi
            done
            echo "    📊 $description summary: Critical=$critical, High=$high, Medium=$medium, Low=$low, Info=$info"
        fi
    }
    
    # Upload files to respective directories
    upload_files_by_severity "1p_price" "$SFTP_1P_PRICE" "1P Price"
    upload_files_by_severity "1p_promotion" "$SFTP_1P_PROMOTION" "1P Promotion"
    upload_files_by_severity "soa_price" "$SFTP_SOA_PRICE" "SOA Price"
    upload_files_by_severity "soa_promotion" "$SFTP_SOA_PROMOTION" "SOA Promotion"
    upload_files_by_severity "rpm_processed" "$SFTP_RPM_PROCESSED" "RPM Processed"
    upload_files_by_severity "rpm_pending" "$SFTP_RPM_PENDING" "RPM Pending"
    
    # Upload issue reports and metadata
    echo "  Uploading issue reports and metadata..."
    for report in "$TEST_DIR/issue_reports"/*; do
        if [ -f "$report" ]; then
            docker cp "$report" "$DOCKER_CONTAINER:/tmp/issue_reports_$INPUT_DATE/" >/dev/null 2>&1
            echo "    ✅ $(basename "$report")"
        fi
    done
    
    # Fix ownership
    echo "  Fixing file ownership..."
    docker exec $DOCKER_CONTAINER chown -R demo:sftp-user-inventory \
        "$SFTP_1P_PRICE" "$SFTP_1P_PROMOTION" \
        "$SFTP_SOA_PRICE" "$SFTP_SOA_PROMOTION" \
        "$SFTP_RPM_PROCESSED" "$SFTP_RPM_PENDING" 2>/dev/null || true
    
    echo "✅ All flag issues test data uploaded to Docker container"
}

# =============================================================================
# FUNCTION: Display expected test results
# =============================================================================
show_flag_issues_expected_results() {
    echo
    echo "=== EXPECTED FLAG ISSUES DETECTION RESULTS ==="
    echo
    echo "📊 Test Files Generated (All with proper naming format):"
    echo
    echo "  🚨 CRITICAL SEVERITY FILES:"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (Data corruption in 1P)"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (Security breach in SOA)"
    echo
    echo "  ⚠️ HIGH SEVERITY FILES:"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (Data mismatch - 1P version)"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (Data mismatch - SOA version)"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods to 192030.ods (10 duplicate files in RPM)"
    echo
    echo "  🟡 MEDIUM SEVERITY FILES:"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (Transfer delay - 1P only)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (Format issues - SOA)"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (Partial corruption - RPM)"
    echo "     - TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods (Encoding issues - 1P)"
    echo
    echo "  🟢 LOW SEVERITY FILES:"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (Format inconsistency - SOA)"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (Cross-stage duplicates - all stages)"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (Size variations - RPM)"
    echo
    echo "  🔀 MULTIPLE ISSUES FILE:"
    echo "     - TH_PRCH_${DATE_PATTERN}${timestamp}.ods (Multiple problems - 1P only)"
    echo
    echo "🔍 The flag_issues task should:"
    echo "   ✓ Detect files across different stages (1P, SOA, RPM)"
    echo "   ✓ Identify various issue types (corruption, mismatch, format, etc.)"
    echo "   ✓ Classify issues by severity levels"
    echo "   ✓ Aggregate results from multiple detection tasks"
    echo "   ✓ Handle cross-stage file analysis"
    echo
    echo "📊 Expected Analysis:"
    echo "   - Files with corruption issues: 2+"
    echo "   - Files with mismatch issues: 2+" 
    echo "   - Files with format issues: 2+"
    echo "   - Cross-stage duplicate files: 3+ (same filename in multiple stages)"
    echo "   - Files missing from expected stages: 1+"
    echo
    echo "📍 Files uploaded to Docker:"
    echo "   - 1P Price: 5 files"
    echo "   - 1P Promotion: 1 file"
    echo "   - SOA Price: 4 files"
    echo "   - SOA Promotion: 1 file"
    echo "   - RPM Processed: 11 files"
    echo "   - RPM Pending: 2 files"
    echo
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    echo "🚀 Starting Flag Issues Detection Test Generation..."
    
    # Generate test scenarios
    generate_flag_issues_test_scenarios
    
    # Create classification system
    create_issue_classification_system
    
    # Upload to Docker container
    upload_flag_issues_test_to_docker
    
    # Show expected results
    show_flag_issues_expected_results
    
    echo "=== FLAG ISSUES DETECTION TEST COMPLETE ==="
    echo "✅ Test data ready for flag_issues task validation"
    echo "📂 Local test files: $TEST_DIR"
    echo "🐳 Docker container files uploaded successfully"
    echo
    echo "💡 Run the DAG's flag_issues task to validate these scenarios"
    echo "🎯 The task should aggregate results from other detection tasks and:"
    echo "   • Classify issues by severity levels"
    echo "   • Set appropriate SLA response times" 
    echo "   • Determine escalation requirements"
    echo "   • Handle multiple issue types per file"
    echo "   • Generate comprehensive issue reports"
}

# Run main function
main "$@"
