#!/bin/bash

# =============================================================================
# ADD TRANSFER FUNCTIONS TO ALL TEST FILES - SIMPLE VERSION
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== ADDING TRANSFER FUNCTIONS TO ALL TEST FILES ===${NC}"

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

# Transfer functions template
TRANSFER_FUNCTIONS_FILE=$(mktemp)
cat > "$TRANSFER_FUNCTIONS_FILE" << 'EOF'

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

EOF

# Process each file
for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        echo -e "${YELLOW}📝 Processing: $test_file${NC}"
        
        # Create backup
        cp "$test_file" "${test_file}.backup.transfer_$(date +%Y%m%d_%H%M%S)"
        
        # Check if transfer functions already exist
        if grep -q "transfer_1p_to_soa" "$test_file"; then
            echo -e "${BLUE}  ℹ️  Transfer functions already exist, skipping: $test_file${NC}"
            continue
        fi
        
        # Find the last function before main execution or append to end
        if grep -q "# MAIN EXECUTION" "$test_file"; then
            # Insert before MAIN EXECUTION
            main_line=$(grep -n "# MAIN EXECUTION" "$test_file" | head -1 | cut -d: -f1)
            head -n $((main_line - 1)) "$test_file" > "${test_file}.tmp"
            cat "$TRANSFER_FUNCTIONS_FILE" >> "${test_file}.tmp"
            tail -n +$main_line "$test_file" >> "${test_file}.tmp"
            mv "${test_file}.tmp" "$test_file"
        else
            # Append to end of file
            cat "$TRANSFER_FUNCTIONS_FILE" >> "$test_file"
        fi
        
        # Add transfer call to main execution (find fix_ownership and add after it)
        if grep -q "fix_ownership" "$test_file"; then
            # Add after fix_ownership
            sed -i '/fix_ownership$/a\\n    # Execute complete transfer pipeline (1P → SOA → RPM)\n    execute_complete_transfer_pipeline' "$test_file"
        fi
        
        echo -e "${GREEN}  ✅ Added transfer functions to: $test_file${NC}"
    else
        echo -e "${RED}  ❌ File not found: $test_file${NC}"
    fi
done

# Cleanup
rm -f "$TRANSFER_FUNCTIONS_FILE"

echo -e "${GREEN}🎉 Transfer functions added to all test files!${NC}"
echo -e "${YELLOW}💡 All files now include 1P → SOA → RPM transfer pipeline${NC}"
echo -e "${BLUE}📦 Backup files created with transfer timestamp${NC}"
