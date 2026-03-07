import requests
import time
import sys

def create_and_show_bakong_qr(amount, currency="USD", use_mock=False):
    """
    Generate a Bakong payment token and display only the token in terminal.
    """
    # API Configuration
    API_URL = "https://api-bakong.nbc.org.kh/v1/generate_bakong_checkout"
    API_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImlkIjoiZDJmNmMzOGYzNDc2NGM3MSJ9LCJpYXQiOjE3Njk0MTc3MTYsImV4cCI6MTc3NzE5MzcxNn0.Z_w1fHx74NVcVey9VQ3mtaZxeduWC-zYWLj07y33ncI"
    MERCHANT_ID = "choeng_rayu@aclb"
    
    # Generate unique transaction ID
    payload = {
        "merchantId": MERCHANT_ID,
        "amount": amount,
        "currency": currency,
        "description": "Terminal Payment Test",
        "externalTransactionId": f"TXN_{int(time.time() * 1000)}"
    }

    try:
        print("\n========================================")
        print("   GENERATING BAKONG KHQR PAYMENT")
        print("========================================\n")
        
        # Mock mode for testing when API is unavailable
        if use_mock:
            print("⚠️  USING MOCK DATA (API unreachable)")
            result = {
                'qrCode': f'00020126360012kh.bnb.khqr01051234567890210201012300398000300059850011480011KHQR0000102050019606400000000100000000000061{int(amount * 100)}5802KH5910MERCHANT6007Phnom Penh63046B3C',
                'md5': 'mock_md5_hash_' + str(int(time.time()))
            }
            qr_code = result.get('qrCode')
            md5_hash = result.get('md5')

            print(f"💰 Amount : {amount} {currency}")
            print(f"🆔 Ref MD5: {md5_hash}")
            print("\n👇 PAYMENT TOKEN:\n")
            print(qr_code)
            print("\n[Status: Mock Mode - Awaiting Scan...]")
            return qr_code
        
        response = requests.post(
            API_URL,
            json=payload,
            headers={
                'Authorization': f'Bearer {API_TOKEN}',
                'Content-Type': 'application/json'
            },
            timeout=10
        )

        # Bakong API response usually nests the result in a 'data' object
        response_data = response.json()
        result = response_data.get('data') or response_data

        if response.status_code == 200 and result and result.get('qrCode'):
            qr_code = result.get('qrCode')
            md5_hash = result.get('md5')

            print(f"💰 Amount : {amount} {currency}")
            print(f"🆔 Ref MD5: {md5_hash}")
            print("\n👇 PAYMENT TOKEN:\n")
            print(qr_code)
            print("\n[Status: Awaiting Scan...]")
            
            return qr_code
        else:
            print("❌ Failed to parse token data from Bakong.")
            print(f"Status: {response.status_code}")
            print(response.text)
            return None

    except Exception as error:
        print("❌ ERROR CONNECTING TO BAKONG:")
        print(f"   {str(error)}")
        print("\n💡 HINT: Use --mock flag to test without API:")
        print("   python3 generate_payment_token.py --mock")
        return None

# Run the script
if __name__ == "__main__":
    use_mock = "--mock" in sys.argv
    create_and_show_bakong_qr(amount=1.00, currency="USD", use_mock=use_mock)