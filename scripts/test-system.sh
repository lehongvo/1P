#!/bin/bash

# LOTUS O2O System Test Script
# Test script để kiểm tra Phoenix OMS và Phoenix Commerce Engine

echo "🚀 LOTUS O2O System Test Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base URLs
OMS_URL="http://localhost:3001"
COMMERCE_URL="http://localhost:3002"

# Function to check if service is running
check_service() {
    local url=$1
    local service_name=$2
    
    echo -e "${BLUE}🔍 Checking $service_name...${NC}"
    
    if curl -s "$url/api/v1/health" > /dev/null; then
        echo -e "${GREEN}✅ $service_name is running${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name is not running${NC}"
        return 1
    fi
}

# Function to make API request
make_request() {
    local method=$1
    local url=$2
    local data=$3
    local description=$4
    
    echo -e "${BLUE}📡 $description${NC}"
    
    if [ -z "$data" ]; then
        response=$(curl -s -X "$method" "$url")
    else
        response=$(curl -s -X "$method" "$url" -H "Content-Type: application/json" -d "$data")
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Success${NC}"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    else
        echo -e "${RED}❌ Failed${NC}"
        echo "$response"
    fi
    echo ""
}

# Check if services are running
echo "📋 Checking services..."
check_service "$OMS_URL" "Phoenix OMS" || exit 1
check_service "$COMMERCE_URL" "Phoenix Commerce Engine" || exit 1

echo ""
echo "🧪 Starting tests..."
echo "==================="

# Test 1: Create mock data
echo "1️⃣ Creating mock data..."
make_request "POST" "$OMS_URL/api/v1/seed-mock-data" "" "Creating 50 mock orders"

# Wait a moment for data to be created
sleep 2

# Test 2: Get orders
echo "2️⃣ Getting orders..."
make_request "GET" "$OMS_URL/api/v1/orders?limit=5" "" "Getting first 5 orders"

# Test 3: Get a specific order
echo "3️⃣ Getting specific order..."
# First get order list to find an order ID
orders_response=$(curl -s "$OMS_URL/api/v1/orders?limit=1")
order_id=$(echo "$orders_response" | jq -r '.data[0].order_id' 2>/dev/null)

if [ "$order_id" != "null" ] && [ -n "$order_id" ]; then
    make_request "GET" "$OMS_URL/api/v1/orders/$order_id" "" "Getting order details for $order_id"
    
    # Test 4: Process order in Commerce Engine
    echo "4️⃣ Processing order in Commerce Engine..."
    make_request "POST" "$COMMERCE_URL/api/v1/process/$order_id" "" "Processing order $order_id"
    
    # Test 5: Get order status history
    echo "5️⃣ Getting order status history..."
    make_request "GET" "$OMS_URL/api/v1/orders/$order_id/history" "" "Getting status history for $order_id"
else
    echo -e "${YELLOW}⚠️ No orders found, skipping order-specific tests${NC}"
fi

# Test 6: Get processing history
echo "6️⃣ Getting processing history..."
make_request "GET" "$COMMERCE_URL/api/v1/processing-history?limit=5" "" "Getting processing history"

# Test 7: Get monitoring events
echo "7️⃣ Getting monitoring events..."
make_request "GET" "$COMMERCE_URL/api/v1/monitoring-events?limit=5" "" "Getting monitoring events"

# Test 8: Get processing stats
echo "8️⃣ Getting processing statistics..."
make_request "GET" "$COMMERCE_URL/api/v1/processing-stats" "" "Getting processing statistics"

# Test 9: Simulate order processing
echo "9️⃣ Simulating order processing..."
make_request "POST" "$COMMERCE_URL/api/v1/simulate-processing" "" "Running order processing simulation"

# Test 10: Create a new order
echo "🔟 Creating a new order..."
new_order_data='{
  "customer_id": "CUST-TEST-001",
  "customer_name": "Test Customer",
  "customer_email": "test@example.com",
  "customer_phone": "0901234567",
  "total_amount": 15000000,
  "currency": "VND",
  "payment_method": "CREDIT_CARD",
  "shipping_address": "123 Test Street, District 1, Ho Chi Minh City",
  "items": [
    {
      "product_id": "P001",
      "product_name": "iPhone 15 Pro",
      "quantity": 1,
      "unit_price": 15000000
    }
  ]
}'

make_request "POST" "$OMS_URL/api/v1/orders" "$new_order_data" "Creating new test order"

echo ""
echo "🎉 Test completed!"
echo "=================="
echo -e "${GREEN}✅ All tests finished${NC}"
echo ""
echo "📊 You can now monitor the system:"
echo "   - Phoenix OMS: $OMS_URL"
echo "   - Phoenix Commerce Engine: $COMMERCE_URL"
echo "   - Database: localhost:5432 (lotus_o2o)"
echo ""
echo "🔄 The Commerce Engine will automatically process orders every 30 seconds"
echo "📈 Check the monitoring endpoints for real-time statistics"
