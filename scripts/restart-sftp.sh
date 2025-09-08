#!/bin/bash
set -e

echo "🔄 Restarting SFTP container with new permissions..."

# Stop and remove existing container
docker stop lotus-sftp-1 || true
docker rm lotus-sftp-1 || true

# Recreate directories with proper permissions
mkdir -p /home/demo/sftp
mkdir -p /home/demo/sftp/rpm/processed
mkdir -p /home/demo/sftp/tmp/data
chmod -R 755 /home/demo/sftp

# Restart container
/usr/bin/docker run -d --name lotus-sftp-1 --restart always \
  -p 2222:22 \
  -v /opt/sftp-config/sftp.json:/app/config/sftp.json:ro \
  -v /home/demo/sftp:/home/demo/sftp \
  emberstack/sftp:latest

echo "✅ SFTP container restarted successfully!"
echo "📁 Directory structure:"
ls -la /home/demo/sftp/
ls -la /home/demo/sftp/rpm/
ls -la /home/demo/sftp/tmp/
