#!/bin/bash

# LOTUS O2O System Startup Script
# Script để khởi động Phoenix OMS và Phoenix Commerce Engine

echo "🚀 LOTUS O2O System Startup Script"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker is running${NC}"
}

# Function to check if ports are available
check_ports() {
    local ports=("3001" "3002" "5432")
    
    for port in "${ports[@]}"; do
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠️ Port $port is already in use${NC}"
        else
            echo -e "${GREEN}✅ Port $port is available${NC}"
        fi
    done
}

# Function to install dependencies
install_dependencies() {
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    
    # Install root dependencies
    if [ -f "package.json" ]; then
        npm install
    fi
    
    # Install Phoenix OMS dependencies
    if [ -d "phoenix-oms" ]; then
        echo -e "${BLUE}📦 Installing Phoenix OMS dependencies...${NC}"
        cd phoenix-oms && npm install && cd ..
    fi
    
    # Install Phoenix Commerce Engine dependencies
    if [ -d "phoenix-commerce" ]; then
        echo -e "${BLUE}📦 Installing Phoenix Commerce Engine dependencies...${NC}"
        cd phoenix-commerce && npm install && cd ..
    fi
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# Function to start with Docker
start_with_docker() {
    echo -e "${BLUE}🐳 Starting system with Docker...${NC}"
    
    # Stop any existing containers
    docker-compose down 2>/dev/null
    
    # Build and start services
    docker-compose up -d --build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ System started successfully with Docker${NC}"
        echo ""
        echo "📊 Services are running at:"
        echo "   - Phoenix OMS: http://localhost:3001"
        echo "   - Phoenix Commerce Engine: http://localhost:3002"
        echo "   - PostgreSQL Database: localhost:5432"
        echo ""
        echo "📋 Useful commands:"
        echo "   - View logs: docker-compose logs -f"
        echo "   - Stop services: docker-compose down"
        echo "   - Restart services: docker-compose restart"
    else
        echo -e "${RED}❌ Failed to start system with Docker${NC}"
        exit 1
    fi
}

# Function to start in development mode
start_development() {
    echo -e "${BLUE}🔧 Starting system in development mode...${NC}"
    
    # Start database only
    docker-compose up postgres -d
    
    # Wait for database to be ready
    echo -e "${BLUE}⏳ Waiting for database to be ready...${NC}"
    sleep 10
    
    # Start Phoenix OMS
    echo -e "${BLUE}🚀 Starting Phoenix OMS...${NC}"
    cd phoenix-oms && npm run dev &
    OMS_PID=$!
    cd ..
    
    # Wait a moment for OMS to start
    sleep 5
    
    # Start Phoenix Commerce Engine
    echo -e "${BLUE}🚀 Starting Phoenix Commerce Engine...${NC}"
    cd phoenix-commerce && npm run dev &
    COMMERCE_PID=$!
    cd ..
    
    echo -e "${GREEN}✅ System started in development mode${NC}"
    echo ""
    echo "📊 Services are running at:"
    echo "   - Phoenix OMS: http://localhost:3001"
    echo "   - Phoenix Commerce Engine: http://localhost:3002"
    echo "   - PostgreSQL Database: localhost:5432"
    echo ""
    echo "📋 Process IDs:"
    echo "   - Phoenix OMS: $OMS_PID"
    echo "   - Phoenix Commerce Engine: $COMMERCE_PID"
    echo ""
    echo "🛑 To stop the system, press Ctrl+C"
    
    # Wait for user to stop
    trap "echo ''; echo '🛑 Stopping services...'; kill $OMS_PID $COMMERCE_PID 2>/dev/null; docker-compose down; echo '✅ Services stopped'; exit 0" INT
    wait
}

# Main script
echo "🔍 Checking prerequisites..."
check_docker
check_ports

echo ""
echo "📦 Installing dependencies..."
install_dependencies

echo ""
echo "🚀 Choose startup mode:"
echo "1) Docker (Recommended)"
echo "2) Development mode"
echo "3) Exit"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        start_with_docker
        ;;
    2)
        start_development
        ;;
    3)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac
