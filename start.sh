#!/bin/bash

echo "🚀 Starting 1P Service Project..."

# Start Docker containers
echo "📦 Starting Docker containers..."
docker-compose up -d

# Wait for containers to be ready
echo "⏳ Waiting for containers to be ready..."
sleep 10

# Check if containers are running
echo "🔍 Checking container status..."
docker-compose ps

# Start mock data generator
echo "🎯 Starting mock data generator..."
cd mock
bash ./generate_mock_data.sh --watch &

echo "✅ Project started successfully!"
echo "📊 Mock data generator is running in background"
echo "🛑 To stop: docker-compose down && pkill -f generate_mock_data"
