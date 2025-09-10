#!/bin/bash

# Script to get full paths for all file types on SFTP server
# Based on Airflow configuration paths

echo "=== SFTP Server File Paths ==="
echo "Server: 34.142.196.11:2222"
echo "User: demo"
echo ""

# Function to get files with full paths
get_files_with_paths() {
    local category=$1
    local path=$2
    
    echo "=== $category Files ==="
    echo "Path: $path"
    
    sshpass -p "demo" sftp -P 2222 -o StrictHostKeyChecking=no demo@34.142.196.11 << EOF
cd $path
pwd
ls -1 | head -10
quit
EOF
    echo ""
}

# Get Price files (TH_PRCH_*)
echo "=== PRICE FILES ==="
echo "Path: /sftp/rpm/processed"
sshpass -p "demo" sftp -P 2222 -o StrictHostKeyChecking=no demo@34.142.196.11 << 'EOF'
cd /sftp/rpm/processed
ls -1 | grep "TH_PRCH_" | head -5 | while read file; do echo "/sftp/rpm/processed/$file"; done
quit
EOF
echo ""

# Get Promotion files (TH_PROMPRCH_*)
echo "=== PROMOTION FILES ==="
echo "Path: /sftp/rpm/processed"
sshpass -p "demo" sftp -P 2222 -o StrictHostKeyChecking=no demo@34.142.196.11 << 'EOF'
cd /sftp/rpm/processed
ls -1 | grep "TH_PROMPRCH_" | head -5 | while read file; do echo "/sftp/rpm/processed/$file"; done
quit
EOF
echo ""

# Get all processed files
echo "=== ALL PROCESSED FILES ==="
echo "Path: /sftp/rpm/processed"
sshpass -p "demo" sftp -P 2222 -o StrictHostKeyChecking=no demo@34.142.196.11 << 'EOF'
cd /sftp/rpm/processed
ls -1 | head -10 | while read file; do echo "/sftp/rpm/processed/$file"; done
quit
EOF
echo ""

# Check pending directory (if exists)
echo "=== PENDING FILES ==="
echo "Path: /sftp/rpm/processed (same as processed in current config)"
echo "Note: Currently both processed and pending point to same directory"
echo ""

# File count summary
echo "=== FILE COUNT SUMMARY ==="
sshpass -p "demo" sftp -P 2222 -o StrictHostKeyChecking=no demo@34.142.196.11 << 'EOF'
cd /sftp/rpm/processed
ls -1 | wc -l
quit
EOF

echo ""
echo "=== AIRFLOW PATH MAPPING ==="
echo "SFTP_1P_FOLDERS:"
echo "  price: /sftp/rpm/processed"
echo "  promotion: /sftp/rpm/processed" 
echo "  feedback_price: /sftp/rpm/processed"
echo "  feedback_promotion: /sftp/rpm/processed"
echo ""
echo "SFTP_RPM_FOLDERS:"
echo "  processed.path: /sftp/rpm/processed"
echo "  pending.path: /sftp/rpm/processed"
