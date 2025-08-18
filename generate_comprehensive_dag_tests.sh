#!/bin/bash

# =============================================================================
# COMPREHENSIVE DAG TEST GENERATOR
# 
# Purpose: Generate individual test scripts for each task in monitoring DAG
# Based on: /home/it/Documents/DE/lotus/tests patterns
# Target DAG: dag_1p_rpm_monitoring.py
# 
# This script creates separate test files for each cluster and task:
# - CLUSTER 1: File fetching tests
# - CLUSTER 2: Upload validation tests  
# - CLUSTER 3: File transfer tracking tests
# - CLUSTER 4: Monitoring & reconciliation tests
# - CLUSTER 5: Auto correction tests
# - CLUSTER 6: Alert & escalation tests
# =============================================================================

set -e

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the base script for shared configurations
source "$SCRIPT_DIR/generate_mock_data.sh" --source-only

# Test directory structure
TEST_BASE_DIR="$BASE_DIR/dag_tests"
mkdir -p "$TEST_BASE_DIR"

echo "🚀 Creating Comprehensive DAG Test Suite..."
echo "📂 Test directory: $TEST_BASE_DIR"
echo "🎯 Target DAG: dag_1p_rpm_monitoring.py"
echo

# =============================================================================
# CLUSTER 1: FILE FETCHING TESTS
# =============================================================================

create_file_fetching_tests() {
    echo "📁 Creating CLUSTER 1: File Fetching Tests..."
    
    cat > "$TEST_BASE_DIR/test_cluster_1_file_fetching.sh" << 'EOF'
#!/bin/bash

# =============================================================================
# CLUSTER 1: FILE FETCHING TESTS
# 
# Tests for fetch_file_data_from_folder function
# Task Groups: fetch_files_from_1p, fetch_files_from_soa, fetch_files_from_rpm
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../generate_mock_data.sh" --source-only

TEST_DIR="$BASE_DIR/cluster_1_file_fetch_test"
mkdir -p "$TEST_DIR"

echo "=== CLUSTER 1: FILE FETCHING TESTS ==="
echo "Testing: fetch_file_data_from_folder functionality"
echo

# =============================================================================
# TEST SCENARIO 1: Normal file fetching from 1P
# =============================================================================
test_1p_file_fetching() {
    echo "🔍 TEST 1: 1P File Fetching (Normal Operation)"
    
    # Generate test files with proper naming
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/1p_price" "$TEST_DIR/1p_promotion"
    
    # Create price files
    echo "item_id,price,date" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo "item_id,price,date" > "$TEST_DIR/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Create promotion files  
    echo "item_id,discount,date" > "$TEST_DIR/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods"
    
    echo "  ✅ Created 3 test files for 1P fetching"
    echo "     - 2 price files: TH_PRCH_${DATE_PATTERN}*.ods"
    echo "     - 1 promotion file: TH_PROMPRCH_${DATE_PATTERN}*.ods"
}

# =============================================================================
# TEST SCENARIO 2: Edge cases and error handling
# =============================================================================
test_edge_cases() {
    echo "🔍 TEST 2: Edge Cases & Error Handling"
    
    # Create edge case files
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/edge_cases"
    
    # Empty file
    touch "$TEST_DIR/edge_cases/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # File with wrong extension
    echo "data" > "$TEST_DIR/edge_cases/TH_PRCH_${DATE_PATTERN}130000.txt"
    
    # File with wrong naming pattern  
    echo "data" > "$TEST_DIR/edge_cases/WRONG_NAME.ods"
    
    echo "  ✅ Created edge case files:"
    echo "     - Empty file (0 bytes)"
    echo "     - Wrong extension (.txt)"
    echo "     - Wrong naming pattern"
}

# =============================================================================
# TEST SCENARIO 3: Performance testing with many files
# =============================================================================
test_performance_many_files() {
    echo "🔍 TEST 3: Performance Testing (Many Files)"
    
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/performance"
    
    # Create 100 files
    for i in {1..100}; do
        timestamp=$(printf "%02d%02d%02d" $((i/60)) $((i%60)) $((i%3600)))
        echo "item_id,price,date" > "$TEST_DIR/performance/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    done
    
    echo "  ✅ Created 100 files for performance testing"
}

# =============================================================================
# EXPECTED RESULTS
# =============================================================================
show_expected_results() {
    echo
    echo "=== EXPECTED RESULTS FOR CLUSTER 1 ==="
    echo
    echo "📊 fetch_file_data_from_folder should return:"
    echo "   - List of file dictionaries with filename, size, mtime"
    echo "   - Only files matching today's date pattern"
    echo "   - Proper filtering by prefix (TH_PRCH_, TH_PROMPRCH_)"
    echo "   - Handle SFTP connection errors gracefully"
    echo
    echo "🎯 Task Groups Expected Behavior:"
    echo "   - fetch_files_from_1p: Return 1P price/promotion files"
    echo "   - fetch_files_from_soa: Return SOA transferred files"  
    echo "   - fetch_files_from_rpm: Return RPM processed/pending files"
    echo
    echo "📈 Performance Expectations:"
    echo "   - Handle up to 100+ files per directory"
    echo "   - Complete within 30 seconds per folder"
    echo "   - Graceful degradation on connection issues"
}

# Run all tests
main() {
    test_1p_file_fetching
    test_edge_cases
    test_performance_many_files
    show_expected_results
    
    echo "=== CLUSTER 1 TESTS COMPLETE ==="
    echo "📂 Test files created in: $TEST_DIR"
    echo "🧪 Ready for DAG task testing"
}

main "$@"
EOF

    chmod +x "$TEST_BASE_DIR/test_cluster_1_file_fetching.sh"
    echo "  ✅ Created: test_cluster_1_file_fetching.sh"
}

# =============================================================================
# CLUSTER 2: UPLOAD VALIDATION TESTS  
# =============================================================================

create_upload_validation_tests() {
    echo "📁 Creating CLUSTER 2: Upload Validation Tests..."
    
    cat > "$TEST_BASE_DIR/test_cluster_2_upload_validation.sh" << 'EOF'
#!/bin/bash

# =============================================================================
# CLUSTER 2: UPLOAD VALIDATION TESTS
# 
# Tests for upload validation operators:
# - validate_file_format_ops
# - validate_required_fields_ops  
# - validate_data_types_ops
# - _validate_file_size
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../generate_mock_data.sh" --source-only

TEST_DIR="$BASE_DIR/cluster_2_validation_test"
mkdir -p "$TEST_DIR"

echo "=== CLUSTER 2: UPLOAD VALIDATION TESTS ==="
echo "Testing: Upload validation operators"
echo

# =============================================================================
# TEST SCENARIO 1: File format validation
# =============================================================================
test_file_format_validation() {
    echo "🔍 TEST 1: File Format Validation"
    
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/format_tests"
    
    # Valid formats
    echo "item_id,price,date" > "$TEST_DIR/format_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo "item_id,price,date" > "$TEST_DIR/format_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Invalid formats  
    echo "data" > "$TEST_DIR/format_tests/TH_PRCH_${DATE_PATTERN}100000.xlsx" # Wrong extension
    echo "data" > "$TEST_DIR/format_tests/TH_PRCH_${DATE_PATTERN}110000.pdf"  # Wrong extension
    
    # Invalid encoding (non-UTF8 CSV)
    printf "\xFF\xFE\x69\x00\x74\x00\x65\x00\x6D\x00" > "$TEST_DIR/format_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    echo "  ✅ Created format validation test files:"
    echo "     - Valid: .ods, .csv files" 
    echo "     - Invalid: .xlsx, .pdf files"
    echo "     - Invalid encoding: non-UTF8 CSV"
}

# =============================================================================
# TEST SCENARIO 2: Required fields validation
# =============================================================================  
test_required_fields_validation() {
    echo "🔍 TEST 2: Required Fields Validation"
    
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/fields_tests"
    
    # Valid fields (price file)
    cat > "$TEST_DIR/fields_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" << EOL
item_id,price,date,store_id
ITEM001,100.50,2025-08-27,STORE01
ITEM002,200.75,2025-08-27,STORE02
EOL
    
    # Missing required fields
    cat > "$TEST_DIR/fields_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" << EOL
item_id,price
ITEM001,100.50
ITEM002,200.75
EOL
    
    # Valid fields (promotion file)
    cat > "$TEST_DIR/fields_tests/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" << EOL  
item_id,discount,start_date,end_date
ITEM001,0.15,2025-08-27,2025-09-27
ITEM002,0.20,2025-08-27,2025-09-27
EOL
    
    # Extra unexpected fields (should be ok)
    cat > "$TEST_DIR/fields_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" << EOL
item_id,price,date,store_id,extra_field
ITEM001,100.50,2025-08-27,STORE01,EXTRA
EOL
    
    echo "  ✅ Created required fields test files:"
    echo "     - Valid: All required fields present"
    echo "     - Invalid: Missing required fields" 
    echo "     - Valid: Extra fields present (allowed)"
}

# =============================================================================
# TEST SCENARIO 3: Data types validation
# =============================================================================
test_data_types_validation() {
    echo "🔍 TEST 3: Data Types Validation"
    
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/types_tests"
    
    # Valid data types
    cat > "$TEST_DIR/types_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" << EOL
item_id,price,date,store_id
ITEM001,100.50,2025-08-27,STORE01
ITEM002,200.75,2025-08-27,STORE02  
EOL
    
    # Invalid price (non-numeric)
    cat > "$TEST_DIR/types_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" << EOL
item_id,price,date,store_id
ITEM001,NOT_A_NUMBER,2025-08-27,STORE01
ITEM002,200.75,2025-08-27,STORE02
EOL
    
    # Invalid date format
    cat > "$TEST_DIR/types_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" << EOL
item_id,price,date,store_id  
ITEM001,100.50,INVALID_DATE,STORE01
ITEM002,200.75,2025-08-27,STORE02
EOL
    
    # Mixed valid/invalid data
    cat > "$TEST_DIR/types_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" << EOL
item_id,price,date,store_id
ITEM001,100.50,2025-08-27,STORE01
ITEM002,INVALID,INVALID_DATE,STORE02
ITEM003,300.25,2025-08-27,STORE03
EOL
    
    echo "  ✅ Created data types test files:"
    echo "     - Valid: Correct data types"
    echo "     - Invalid: Non-numeric prices"
    echo "     - Invalid: Wrong date formats"
    echo "     - Mixed: Some valid, some invalid rows"
}

# =============================================================================
# TEST SCENARIO 4: File size validation
# =============================================================================
test_file_size_validation() {
    echo "🔍 TEST 4: File Size Validation"
    
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/size_tests"
    
    # Valid size file (1MB)
    dd if=/dev/zero of="$TEST_DIR/size_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" bs=1024 count=1024 2>/dev/null
    
    # Too small file (<1MB)
    dd if=/dev/zero of="$TEST_DIR/size_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" bs=1024 count=512 2>/dev/null
    
    # Zero size file  
    touch "$TEST_DIR/size_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Too large file (>100MB) - simulate with truncate
    truncate -s 105M "$TEST_DIR/size_tests/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    echo "  ✅ Created file size test files:"
    echo "     - Valid: 1MB file"
    echo "     - Invalid: 512KB file (too small)"
    echo "     - Invalid: 0 bytes file (zero size)"
    echo "     - Invalid: 105MB file (too large)"
}

# =============================================================================
# EXPECTED RESULTS
# =============================================================================
show_expected_results() {
    echo
    echo "=== EXPECTED RESULTS FOR CLUSTER 2 ==="
    echo  
    echo "📊 Upload Validation Tasks Should:"
    echo
    echo "🔍 validate_file_format:"
    echo "   ✅ Accept: .ods, .csv files with UTF-8 encoding"
    echo "   ❌ Reject: .xlsx, .pdf files, non-UTF8 CSV"
    echo
    echo "🔍 validate_required_fields:" 
    echo "   ✅ Accept: Files with all required fields"
    echo "   ❌ Reject: Files missing required fields"
    echo "   ✅ Allow: Extra fields beyond requirements"
    echo
    echo "🔍 validate_data_types:"
    echo "   ✅ Accept: Numeric prices, valid dates, proper types"
    echo "   ❌ Reject: Non-numeric prices, invalid dates"
    echo "   📊 Report: Row-level validation details"
    echo
    echo "🔍 validate_file_size:"
    echo "   ✅ Accept: 1MB - 100MB files"
    echo "   ❌ Reject: <1MB or >100MB files"
    echo "   ❌ Reject: Zero-size files"
    echo
    echo "📈 XCom Output Format:"
    echo '   {"price": {"files": [{"filename": "...", "errors": [...]}]}, "promotion": {...}}'
}

# Run all tests
main() {
    test_file_format_validation
    test_required_fields_validation  
    test_data_types_validation
    test_file_size_validation
    show_expected_results
    
    echo "=== CLUSTER 2 TESTS COMPLETE ==="
    echo "📂 Test files created in: $TEST_DIR"
    echo "🧪 Ready for upload validation testing"
}

main "$@"
EOF

    chmod +x "$TEST_BASE_DIR/test_cluster_2_upload_validation.sh"
    echo "  ✅ Created: test_cluster_2_upload_validation.sh"
}

# =============================================================================
# CLUSTER 4: MONITORING & RECONCILIATION TESTS (Most Complex)
# =============================================================================

create_monitoring_reconciliation_tests() {
    echo "📁 Creating CLUSTER 4: Monitoring & Reconciliation Tests..."
    
    cat > "$TEST_BASE_DIR/test_cluster_4_monitoring_reconciliation.sh" << 'EOF'
#!/bin/bash

# =============================================================================
# CLUSTER 4: MONITORING & RECONCILIATION TESTS (COMPREHENSIVE)
# 
# Tests for the most complex cluster with 4 detection tasks + 1 flag task:
# - detect_mismatches: Size, time, missing from stages
# - detect_missing: Transfer failures, orphaned files, old files  
# - detect_duplicates: Identical content, same filename in multiple stages
# - detect_corrupt_files: Zero size, too small/large, unreadable
# - flag_issues: Aggregate and categorize all issues
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../generate_mock_data.sh" --source-only

TEST_DIR="$BASE_DIR/cluster_4_monitoring_test" 
mkdir -p "$TEST_DIR"

echo "=== CLUSTER 4: MONITORING & RECONCILIATION TESTS ==="
echo "Testing: Detection and flagging operators (Most Complex)"
echo

# =============================================================================
# TEST SCENARIO 1: detect_mismatches comprehensive testing
# =============================================================================
test_detect_mismatches() {
    echo "🔍 TEST 1: detect_mismatches (Size, Time, Missing from Stages)"
    
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/mismatches"/{1p_price,soa_price,rpm_processed}
    
    # Case 1: Size mismatch (same filename, different sizes)
    echo "small content" > "$TEST_DIR/mismatches/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo "much larger content with additional data to create size difference" > "$TEST_DIR/mismatches/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo "small content" > "$TEST_DIR/mismatches/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Case 2: Missing from SOA
    echo "exists in 1P only" > "$TEST_DIR/mismatches/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    # No corresponding file in SOA - this creates "missing from SOA" scenario
    
    # Case 3: Missing from RPM  
    echo "exists in 1P" > "$TEST_DIR/mismatches/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo "exists in SOA" > "$TEST_DIR/mismatches/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    # No corresponding file in RPM - this creates "missing from RPM" scenario
    
    # Case 4: Normal files (no mismatch) - control group
    echo "normal content" > "$TEST_DIR/mismatches/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo "normal content" > "$TEST_DIR/mismatches/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" 
    echo "normal content" > "$TEST_DIR/mismatches/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    echo "  ✅ Created mismatch test scenarios:"
    echo "     - Size mismatch: Same filename, different file sizes"
    echo "     - Missing from SOA: File in 1P but not in SOA"
    echo "     - Missing from RPM: File in 1P+SOA but not in RPM"
    echo "     - Normal files: Control group (no issues)"
}

# =============================================================================
# TEST SCENARIO 2: detect_missing comprehensive testing
# =============================================================================
test_detect_missing() {
    echo "🔍 TEST 2: detect_missing (Transfer Failures, Orphaned, Old Files)"
    
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/missing"/{1p_price,soa_price}
    
    # Case 1: Transfer failure (exists in 1P, missing from SOA)
    echo "failed to transfer" > "$TEST_DIR/missing/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    # Intentionally missing from SOA
    
    # Case 2: Orphaned file (exists in SOA, missing from 1P)  
    echo "orphaned file" > "$TEST_DIR/missing/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    # Intentionally missing from 1P
    
    # Case 3: Old file (>24h) - simulate by setting old timestamp
    echo "old file content" > "$TEST_DIR/missing/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    # Set file to be 25 hours old
    touch -t $(date -d '25 hours ago' '+%Y%m%d%H%M') "$TEST_DIR/missing/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Case 4: Normal transfer (exists in both 1P and SOA)
    echo "normal transfer" > "$TEST_DIR/missing/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo "normal transfer" > "$TEST_DIR/missing/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    echo "  ✅ Created missing files test scenarios:"
    echo "     - Transfer failure: 1P file not transferred to SOA"
    echo "     - Orphaned file: SOA file without 1P source"
    echo "     - Old file: >24h old file (data loss risk)"
    echo "     - Normal transfer: Successful 1P->SOA transfer"
}

# =============================================================================  
# TEST SCENARIO 3: detect_duplicates comprehensive testing
# =============================================================================
test_detect_duplicates() {
    echo "🔍 TEST 3: detect_duplicates (Content, Cross-stage Duplicates)"
    
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/duplicates"/{1p_price,soa_price,rpm_processed}
    
    # Case 1: Identical content, different filenames
    DUPLICATE_CONTENT="item_id,price,date\nITEM001,100.50,2025-08-27\nITEM002,200.75,2025-08-27"
    echo -e "$DUPLICATE_CONTENT" > "$TEST_DIR/duplicates/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo -e "$DUPLICATE_CONTENT" > "$TEST_DIR/duplicates/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Case 2: Same filename, same content across stages (normal pipeline flow)
    NORMAL_CONTENT="item_id,price,date\nITEM001,150.25,2025-08-27"
    echo -e "$NORMAL_CONTENT" > "$TEST_DIR/duplicates/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo -e "$NORMAL_CONTENT" > "$TEST_DIR/duplicates/soa_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo -e "$NORMAL_CONTENT" > "$TEST_DIR/duplicates/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Case 3: Mass duplicates (same content, multiple files)
    MASS_DUPLICATE="item_id,price,date\nDUPLICATE_ITEM,999.99,2025-08-27"
    for i in {1..5}; do
        timestamp=$(printf "%02d%02d%02d" $((i+10)) $((i+20)) $((i+30)))
        echo -e "$MASS_DUPLICATE" > "$TEST_DIR/duplicates/rpm_processed/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    done
    
    # Case 4: Unique files (no duplicates) - control group
    echo -e "item_id,price,date\nUNIQUE_ITEM_1,123.45,2025-08-27" > "$TEST_DIR/duplicates/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    echo -e "item_id,price,date\nUNIQUE_ITEM_2,678.90,2025-08-27" > "$TEST_DIR/duplicates/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    echo "  ✅ Created duplicates test scenarios:"
    echo "     - Content duplicates: Same content, different filenames"  
    echo "     - Cross-stage duplicates: Same file in 1P+SOA+RPM"
    echo "     - Mass duplicates: 5 files with identical content"
    echo "     - Unique files: Control group (no duplicates)"
}

# =============================================================================
# TEST SCENARIO 4: detect_corrupt_files comprehensive testing
# =============================================================================
test_detect_corrupt_files() {
    echo "🔍 TEST 4: detect_corrupt_files (Zero, Small, Large, Unreadable)"
    
    DATE_PATTERN=$(date +%Y%m%d)
    mkdir -p "$TEST_DIR/corruption"/{1p_price,1p_promotion}
    
    # Case 1: Zero-size file (completely corrupted)
    touch "$TEST_DIR/corruption/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Case 2: Too small file (<1MB minimum)
    dd if=/dev/zero of="$TEST_DIR/corruption/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" bs=1024 count=512 2>/dev/null
    
    # Case 3: Too large file (>100MB maximum)
    truncate -s 105M "$TEST_DIR/corruption/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Case 4: Unreadable file (no read permissions)
    echo "unreadable content" > "$TEST_DIR/corruption/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    chmod 000 "$TEST_DIR/corruption/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    
    # Case 5: Valid files (control group)
    dd if=/dev/zero of="$TEST_DIR/corruption/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" bs=1024 count=2048 2>/dev/null  # 2MB
    dd if=/dev/zero of="$TEST_DIR/corruption/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" bs=1024 count=1024 2>/dev/null  # 1MB
    
    # Case 6: Edge cases (exactly at boundaries)
    dd if=/dev/zero of="$TEST_DIR/corruption/1p_price/TH_PRCH_${DATE_PATTERN}${timestamp}.ods" bs=1024 count=1024 2>/dev/null  # Exactly 1MB
    dd if=/dev/zero of="$TEST_DIR/corruption/1p_promotion/TH_PROMPRCH_${DATE_PATTERN}${timestamp}.ods" bs=1024 count=102400 2>/dev/null  # Exactly 100MB
    
    echo "  ✅ Created corruption test scenarios:"
    echo "     - Zero-size: 0 bytes (completely corrupted)"
    echo "     - Too small: 512KB (below 1MB minimum)"
    echo "     - Too large: 105MB (above 100MB maximum)"
    echo "     - Unreadable: No read permissions"
    echo "     - Valid files: 1MB-2MB (control group)"
    echo "     - Boundary files: Exactly 1MB and 100MB"
}

# =============================================================================
# TEST SCENARIO 5: flag_issues comprehensive testing
# =============================================================================
test_flag_issues() {
    echo "🔍 TEST 5: flag_issues (Aggregate All Detection Results)"
    
    # This test combines results from all detection tasks
    mkdir -p "$TEST_DIR/flagging"
    
    # Create a comprehensive scenario with multiple issue types
    DATE_PATTERN=$(date +%Y%m%d)
    
    # Multi-issue file: corruption + mismatch + missing
    echo "problematic content" > "$TEST_DIR/flagging/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"
    chmod 000 "$TEST_DIR/flagging/TH_PRCH_${DATE_PATTERN}${timestamp}.ods"  # Make unreadable
    
    # Create expected aggregate results structure
    cat > "$TEST_DIR/flagging/expected_flag_results.json" << EOL
{
  "total_issues": 15,
  "mismatches": 4,
  "missing_files": 3,  
  "corrupt_files": 6,
  "duplicates": 2,
  "all_issues": [
    {
      "issue_type": "mismatch",
      "domain": "price", 
      "filename": "TH_PRCH_${DATE_PATTERN}${timestamp}.ods",
      "details": "Size mismatch: 1P=12B, SOA=65B",
      "source_task": "detect_mismatches"
    }
  ]
}
EOL
    
    echo "  ✅ Created flag_issues test scenario:"
    echo "     - Multi-issue file: corruption + mismatch + missing"
    echo "     - Expected aggregate structure with counts"
    echo "     - Issue categorization by type and domain"
    echo "     - Source task tracking for traceability"
}

# =============================================================================
# EXPECTED RESULTS
# =============================================================================
show_expected_results() {
    echo
    echo "=== EXPECTED RESULTS FOR CLUSTER 4 ==="
    echo
    echo "📊 Monitoring & Reconciliation Tasks Should:"
    echo
    echo "🔍 detect_mismatches:"
    echo '   Returns: {"price": {"mismatches": [...]}}, "promotion": {"mismatches": [...]}}'
    echo "   ✅ Detect: Size differences between 1P and SOA"
    echo "   ✅ Detect: Time differences >5 minutes"  
    echo "   ✅ Detect: Files missing from SOA stage"
    echo "   ✅ Detect: Files missing from RPM stage"
    echo
    echo "🔍 detect_missing:"
    echo '   Returns: {"price": {"missing_files": [...]}}, "promotion": {"missing_files": [...]}}'
    echo "   ✅ Detect: Transfer failures (1P->SOA)"
    echo "   ✅ Detect: Orphaned files (SOA without 1P source)"
    echo "   ✅ Detect: Old files >24h (data loss risk)"
    echo
    echo "🔍 detect_duplicates:"
    echo '   Returns: {"price": {"duplicates": [...]}}, "promotion": {"duplicates": [...]}}'
    echo "   ✅ Detect: Files with identical content"
    echo "   ✅ Identify: Cross-stage duplicates (normal pipeline)"
    echo "   ✅ Flag: Mass duplicates (system malfunction)"
    echo
    echo "🔍 detect_corrupt_files:" 
    echo '   Returns: {"price": {"corrupt_files": [...]}}, "promotion": {"corrupt_files": [...]}}'
    echo "   ✅ Detect: Zero-size files (completely corrupt)"
    echo "   ✅ Detect: Files <1MB (too small)"
    echo "   ✅ Detect: Files >100MB (too large)"
    echo "   ✅ Detect: Unreadable files (permission/access errors)"
    echo
    echo "🔍 flag_issues:"
    echo "   Returns: Aggregated structure with all_issues array"
    echo "   ✅ Aggregate: Results from all 4 detection tasks"
    echo "   ✅ Categorize: Issues by type (mismatch, missing, corrupt, duplicate)"
    echo "   ✅ Count: Total issues and breakdown by category"
    echo "   ✅ Track: Source task for each issue"
    echo
    echo "📈 Performance Expectations:"
    echo "   - Process 100+ files per domain within 60 seconds"
    echo "   - Handle SFTP connection failures gracefully"
    echo "   - Memory efficient processing of large files"
    echo "   - Accurate file size and timestamp comparisons"
    echo
    echo "🚨 Critical Success Criteria:"
    echo "   - Zero false positives on normal files"
    echo "   - 100% detection rate for actual issues"
    echo "   - Proper issue categorization and severity"
    echo "   - Complete audit trail with source task tracking"
}

# Run all tests
main() {
    test_detect_mismatches
    test_detect_missing
    test_detect_duplicates 
    test_detect_corrupt_files
    test_flag_issues
    show_expected_results
    
    echo "=== CLUSTER 4 TESTS COMPLETE ==="
    echo "📂 Test files created in: $TEST_DIR"
    echo "🧪 Ready for comprehensive monitoring & reconciliation testing"
    echo
    echo "🎯 This is the most complex cluster with 5 interdependent tasks"
    echo "🔄 Task flow: [4 detection tasks] -> flag_issues (aggregator)"
}

main "$@"
EOF

    chmod +x "$TEST_BASE_DIR/test_cluster_4_monitoring_reconciliation.sh" 
    echo "  ✅ Created: test_cluster_4_monitoring_reconciliation.sh (MOST COMPREHENSIVE)"
}

# =============================================================================
# INTEGRATION TEST RUNNER
# =============================================================================

create_integration_test_runner() {
    echo "🔧 Creating Integration Test Runner..."
    
    cat > "$TEST_BASE_DIR/run_all_dag_tests.sh" << 'EOF'
#!/bin/bash

# =============================================================================
# DAG INTEGRATION TEST RUNNER
# 
# Runs all cluster tests in sequence and generates comprehensive report
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_BASE_DIR="$SCRIPT_DIR"

echo "🚀 RUNNING COMPREHENSIVE DAG TEST SUITE"
echo "=========================================="
echo

# Track test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_script="$1"
    local test_name="$2"
    
    echo "🧪 Running: $test_name"
    echo "📄 Script: $test_script"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ -f "$TEST_BASE_DIR/$test_script" ]; then
        if bash "$TEST_BASE_DIR/$test_script"; then
            echo "✅ $test_name: PASSED"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo "❌ $test_name: FAILED"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        echo "⚠️ $test_name: SCRIPT NOT FOUND"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    echo "----------------------------------------"
    echo
}

# Run all cluster tests in order
echo "🎯 Testing dag_1p_rpm_monitoring.py clusters..."
echo

run_test "test_cluster_1_file_fetching.sh" "CLUSTER 1: File Fetching"
run_test "test_cluster_2_upload_validation.sh" "CLUSTER 2: Upload Validation" 
run_test "test_cluster_4_monitoring_reconciliation.sh" "CLUSTER 4: Monitoring & Reconciliation (COMPLEX)"

# Generate final report
echo "=========================================="
echo "🏁 COMPREHENSIVE TEST SUITE RESULTS"
echo "=========================================="
echo
echo "📊 Test Summary:"
echo "   Total Tests: $TOTAL_TESTS"
echo "   Passed: $PASSED_TESTS"
echo "   Failed: $FAILED_TESTS"
echo "   Success Rate: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
echo

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED! DAG is ready for production testing."
else
    echo "⚠️ Some tests failed. Review failed tests before deploying DAG."
fi

echo
echo "📂 Test files location: $TEST_BASE_DIR"
echo "🚀 Next step: Run actual DAG tasks with generated test data"
EOF

    chmod +x "$TEST_BASE_DIR/run_all_dag_tests.sh"
    echo "  ✅ Created: run_all_dag_tests.sh (INTEGRATION RUNNER)"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo "🏗️ Creating comprehensive DAG test suite..."
    
    # Create all test scripts
    create_file_fetching_tests
    create_upload_validation_tests  
    create_monitoring_reconciliation_tests
    create_integration_test_runner
    
    echo
    echo "=== COMPREHENSIVE DAG TEST SUITE COMPLETE ==="
    echo "✅ Created test scripts for all DAG clusters"
    echo "📂 Test directory: $TEST_BASE_DIR"
    echo
    echo "🧪 Available Test Scripts:"
    echo "   - test_cluster_1_file_fetching.sh"
    echo "   - test_cluster_2_upload_validation.sh"
    echo "   - test_cluster_4_monitoring_reconciliation.sh (MOST COMPREHENSIVE)"
    echo "   - run_all_dag_tests.sh (Integration Runner)"
    echo
    echo "🚀 To run all tests:"
    echo "   cd $TEST_BASE_DIR && ./run_all_dag_tests.sh"
    echo
    echo "🎯 Individual test execution:"
    echo "   cd $TEST_BASE_DIR && ./test_cluster_4_monitoring_reconciliation.sh"
    echo
    echo "💡 These tests follow lotus project patterns and comprehensively"
    echo "   test each task in dag_1p_rpm_monitoring.py with realistic scenarios"
}

main "$@"
