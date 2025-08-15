#!/bin/bash

# Test script to verify 10-minute timing
echo "Testing 10-minute timing..."
echo "Current time: $(date)"

# Test the date calculation for next cycle
echo "Testing date calculation:"
echo "Linux: $(date -d "+10 minutes" 2>/dev/null || echo "Linux date command not available")"
echo "macOS: $(date -v+10M 2>/dev/null || echo "macOS date command not available")"

# Test sleep command
echo "Testing 10-second sleep (should wait 10 seconds)..."
sleep 10
echo "Sleep completed at: $(date)"

echo "Test completed!"


