#!/bin/bash

# =============================================================================
# FIX ALL TEST SCRIPTS TO USE COMPREHENSIVE CLEAN FUNCTION
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== FIXING ALL TEST SCRIPTS TO USE COMPREHENSIVE CLEAN FUNCTION ===${NC}"

# Find all test scripts
test_scripts=$(find . -name "generate_*_test.sh" -o -name "generate_*test*.sh" | grep -v backup | sort)

echo -e "${BLUE}📋 Found test scripts:${NC}"
echo "$test_scripts"

echo -e "\n${YELLOW}🔧 Updating all scripts to use clean_docker_test_files instead of clean_docker_directories...${NC}"

# Update each script
count=0
for script in $test_scripts; do
    if [ -f "$script" ]; then
        echo -e "${YELLOW}  📝 Updating: $script${NC}"
        
        # Create backup
        cp "$script" "${script}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Replace clean_docker_directories with clean_docker_test_files
        if grep -q "clean_docker_directories" "$script"; then
            sed -i 's/clean_docker_directories/clean_docker_test_files/g' "$script"
            echo -e "${GREEN}    ✅ Updated clean function call${NC}"
            ((count++))
        else
            echo -e "${BLUE}    ℹ️  Already using correct function or no clean function${NC}"
        fi
    fi
done

echo -e "\n${GREEN}🎉 Updated $count scripts successfully!${NC}"

echo -e "\n${BLUE}🧪 Testing one script to verify changes...${NC}"
if [ -f "./generate_fetch_1p_files_test.sh" ]; then
    echo -e "${YELLOW}Testing generate_fetch_1p_files_test.sh --help:${NC}"
    ./generate_fetch_1p_files_test.sh --help
fi

echo -e "\n${GREEN}✅ All test scripts now use the comprehensive clean function!${NC}"
echo -e "${YELLOW}💡 The comprehensive clean function removes ALL test files from Docker:${NC}"
echo -e "  • All CSV, ODS, TXT, XLSX files"
echo -e "  • All files with test patterns (TEST*, DUPLICATE*, CORRUPT*, etc.)"
echo -e "  • Files in all directories (1P, SOA, RPM, invalid folders)"
echo -e "  • Deep cleaning across the entire Docker container"

echo -e "\n${BLUE}📝 Usage examples:${NC}"
echo -e "  ./generate_fetch_1p_files_test.sh 2025-08-18 --clean"
echo -e "  ./generate_duplicates_test_files.sh 2025-08-18 --clean"
echo -e "  ./generate_corrupt_files_test.sh 2025-08-18 --clean"
