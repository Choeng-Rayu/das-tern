const axios = require('axios');
// const qrcode = require('qrcode-terminal');

/**
 * BAKONG TERMINAL PAYMENT GENERATOR
 * This script requests a KHQR from the Bakong API and renders it in the terminal.
 */
async function createAndShowBakongQR(amount, currency = "USD") {
    // API Configuration
    const API_URL = "https://api-bakong.nbc.org.kh/v1/generate_bakong_checkout";
    const API_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImlkIjoiZDJmNmMzOGYzNDc2NGM3MSJ9LCJpYXQiOjE3Njk0MTc3MTYsImV4cCI6MTc3NzE5MzcxNn0.Z_w1fHx74NVcVey9VQ3mtaZxeduWC-zYWLj07y33ncI"; 
    const MERCHANT_ID = "choeng_rayu@aclb";

    const payload = {
        merchantId: MERCHANT_ID,
        amount: amount,
        currency: currency,
        description: "Terminal Payment Test",
        externalTransactionId: `TXN_${Date.now()}` // Unique ID per request
    };

    try {
        console.log("\n========================================");
        console.log("   GENERATING BAKONG KHQR PAYMENT");
        console.log("========================================\n");
        
        const response = await axios.post(API_URL, payload, {
            headers: { 
                'Authorization': `Bearer ${API_TOKEN}`,
                'Content-Type': 'application/json'
            }
        });

        // Bakong API response usually nests the result in a 'data' object
        const result = response.data.data || response.data;

        if (result && result.qrCode) {
            const { qrCode, md5 } = result;

            console.log(`💰 Amount : ${amount} ${currency}`);
            console.log(`🆔 Ref MD5: ${md5}`);
            console.log("\n👇 SCAN TO PAY WITH BAKONG APP:\n");
            console.log(qrCode);

            // Renders the KHQR string as a scannable graphic in terminal
            // qrcode.generate(qrCode, { small: true }); 

            console.log("\n[Status: Awaiting Scan...]");
        } else {
            console.log("❌ Failed to parse QR data from Bakong.");
            console.log("Response:", response.data);
        }

    } catch (error) {
        console.error("❌ ERROR CONNECTING TO BAKONG:");
        if (error.response) {
            // Server responded with an error status (4xx, 5xx)
            console.error(`Status: ${error.response.status}`);
            console.error(JSON.stringify(error.response.data, null, 2));
        } else {
            // Network or setup error
            console.error(error.message);
        }
    }
}

// Run the function
createAndShowBakongQR(1.00, "USD");