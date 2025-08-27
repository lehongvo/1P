// =============================================================================
// MOCK DATA SEEDER API CONTINUOUS CALLER
// Calls the seed-mock-data API every 30 seconds continuously
// =============================================================================

const API_ENDPOINT = 'http://localhost:3001/api/v1/seed-mock-data';
const API_KEY = '0x9f299A715cb6aF84e93ba90371538Ddf130E1ec0021hf902';
const INTERVAL_MS = 30000; // 30 seconds

/**
 * Call seed-mock-data API with current timestamp
 */
async function callSeedMockDataAPI() {
    const timestamp = new Date().toISOString();
    
    try {
        const response = await fetch(API_ENDPOINT, {
            method: 'POST',
            headers: {
                'x-api-key': API_KEY,
                'Content-Type': 'application/json',
                'User-Agent': 'MockDataGenerator/1.0'
            }
        });

        if (response.ok) {
            const data = await response.json();
            console.log(`✅ [${timestamp}] Seed mock data API call successful - Status: ${response.status}`);
            console.log(`📊 Response data:`, data);
            return { success: true, data, status: response.status };
        } else {
            console.error(`❌ [${timestamp}] Seed mock data API call failed - Status: ${response.status}`);
            console.error(`📝 Response text:`, await response.text());
            return { success: false, status: response.status, error: 'HTTP Error' };
        }
    } catch (error) {
        console.error(`💥 [${timestamp}] Seed mock data API call error:`, error.message);
        return { success: false, error: error.message };
    }
}

/**
 * Start continuous seed mock data API calls every 30 seconds
 */
function startContinuousSeeding() {
    console.log('🚀 Starting continuous seed mock data API calls...');
    console.log(`📡 Endpoint: ${API_ENDPOINT}`);
    console.log(`⏰ Interval: ${INTERVAL_MS / 1000} seconds`);
    console.log(`🔑 API Key: ${API_KEY.substring(0, 10)}...`);
    console.log('='.repeat(60));

    // Initial call
    callSeedMockDataAPI();

    // Set up interval for continuous calls
    const intervalId = setInterval(async () => {
        await callSeedMockDataAPI();
    }, INTERVAL_MS);

    // Return interval ID for potential cleanup
    return intervalId;
}

/**
 * Stop continuous seeding
 */
function stopContinuousSeeding(intervalId) {
    if (intervalId) {
        clearInterval(intervalId);
        console.log('🛑 Continuous seeding stopped');
        return true;
    }
    return false;
}

/**
 * Test single API call
 */
async function testSingleCall() {
    console.log('🧪 Testing single seed mock data API call...');
    const result = await callSeedMockDataAPI();
    console.log('📋 Test result:', result);
    return result;
}

// Export functions for external use
module.exports = {
    callSeedMockDataAPI,
    startContinuousSeeding,
    stopContinuousSeeding,
    testSingleCall,
    API_ENDPOINT,
    API_KEY,
    INTERVAL_MS
};

// Auto-start if this file is run directly
if (require.main === module) {
    console.log('🎯 Running seed mock data script directly...');
    
    // Start continuous seeding
    const intervalId = startContinuousSeeding();
    
    // Handle graceful shutdown
    process.on('SIGINT', () => {
        console.log('\n🔄 Received SIGINT, shutting down gracefully...');
        stopContinuousSeeding(intervalId);
        process.exit(0);
    });
    
    process.on('SIGTERM', () => {
        console.log('\n🔄 Received SIGTERM, shutting down gracefully...');
        stopContinuousSeeding(intervalId);
        process.exit(0);
    });
}
