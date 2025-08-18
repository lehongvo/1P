#!/bin/bash

# =============================================================================
# ADD FIX_OWNERSHIP FUNCTION TO ALL TEST FILES
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ADDING fix_ownership FUNCTION TO ALL TEST FILES ===${NC}"

# List of test files to update
TEST_FILES=(
    "generate_missing_fields_test.sh"
    "generate_data_types_validation_test.sh"
    "generate_file_format_validation_test.sh"
    "generate_file_size_validation_test.sh"
    "generate_corrupt_files_test.sh"
    "generate_duplicates_test_files.sh"
    "generate_missing_files_test.sh"
    "generate_mismatches_test.sh"
    "generate_auto_correction_test.sh"
    "generate_auto_feedback_test.sh"
    "generate_flag_issues_test.sh"
    "generate_file_tracking_test.sh"
    "generate_fetch_1p_files_test.sh"
    "generate_fetch_soa_files_test.sh"
    "generate_fetch_rpm_files_test.sh"
    "generate_required_fields_validation_test.sh"
)

# fix_ownership function template
FIX_OWNERSHIP_FUNCTION='# =============================================================================
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
}'

# Process each file
for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        echo -e "${YELLOW}📝 Processing: $test_file${NC}"
        
        # Create backup
        cp "$test_file" "${test_file}.backup.add_fix_ownership_$(date +%Y%m%d_%H%M%S)"
        
        # Check if fix_ownership function already exists
        if grep -q "^fix_ownership()" "$test_file"; then
            echo -e "${BLUE}  ℹ️  fix_ownership function already exists, skipping: $test_file${NC}"
            continue
        fi
        
        # Find the last function before main execution or append to end
        if grep -q "# MAIN EXECUTION" "$test_file"; then
            # Insert before MAIN EXECUTION
            main_line=$(grep -n "# MAIN EXECUTION" "$test_file" | head -1 | cut -d: -f1)
            {
                head -n $((main_line - 1)) "$test_file"
                echo ""
                echo "$FIX_OWNERSHIP_FUNCTION"
                echo ""
                tail -n +$main_line "$test_file"
            } > "${test_file}.tmp"
            mv "${test_file}.tmp" "$test_file"
        else
            # Append to end of file
            {
                cat "$test_file"
                echo ""
                echo "$FIX_OWNERSHIP_FUNCTION"
                echo ""
            } > "${test_file}.tmp"
            mv "${test_file}.tmp" "$test_file"
        fi
        
        echo -e "${GREEN}  ✅ Added fix_ownership function to: $test_file${NC}"
    else
        echo -e "${RED}  ❌ File not found: $test_file${NC}"
    fi
done

echo -e "${GREEN}🎉 fix_ownership function added to all test files!${NC}"
echo -e "${YELLOW}💡 All files now have fix_ownership function with airflow:airflow ownership${NC}"
echo -e "${BLUE}📦 Backup files created with add_fix_ownership timestamp${NC}"
