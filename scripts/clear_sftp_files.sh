#!/bin/bash

echo "🗑️ Clearing all .ods files from SFTP server..."
echo "Server: 35.240.183.156:2222"
echo ""

# Clear all .ods files from /sftp/rpm/processed
echo "Clearing files from /sftp/rpm/processed..."
sshpass -p "demo" sftp -P 2222 -o StrictHostKeyChecking=no demo@35.240.183.156 << 'EOF'
cd /sftp/rpm/processed
rm *.ods
quit
EOF

# Clear all .ods files from /sftp/tmp/data (if any)
echo "Clearing files from /sftp/tmp/data..."
sshpass -p "demo" sftp -P 2222 -o StrictHostKeyChecking=no demo@35.240.183.156 << 'EOF'
cd /sftp/tmp/data
rm *.ods
quit
EOF

echo ""
echo "✅ All .ods files cleared!"
echo ""

# Verify cleanup
echo "🔍 Verifying cleanup..."
sshpass -p "demo" sftp -P 2222 -o StrictHostKeyChecking=no demo@35.240.183.156 << 'EOF'
cd /sftp/rpm/processed
ls -la
cd ../../tmp/data
ls -la
quit
EOF

echo ""
echo "✅ Cleanup completed!"
