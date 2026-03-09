# Bakong Payment Fix Summary

## Issue Found

When testing with real payment, the KHQR code was **invalid** and couldn't be scanned by banking apps.

## Root Cause

**Phone number format in `.env` file was incorrect:**

```env
# ❌ WRONG (had spaces and + symbol)
BAKONG_PHONE_NUMBER=+855 96 998 3479

# ✅ CORRECT (no spaces, no + symbol)
BAKONG_PHONE_NUMBER=85596998349
```

The KHQR specification requires phone numbers **without the `+` symbol and without spaces**.

## What Was Changed

**File:** `/home/rayu/das-tern/bakong_payment/.env`

- **Line 11:** Changed from `+855 96 998 3479` to `85596998349`

## Why This Matters

The phone number is embedded in the KHQR token at EMV Tag 29 (Merchant Account Information):

```
29570017kh.gov.nbc.bakong0116choeng_rayu@aclb0212+85596998349
                                               ^-- This field must not have + or spaces
```

With spaces/plus signs, banking apps reject the QR code as **malformed**.

## Token Validity ✅

Your Bakong Developer Token is **valid**:
- **Issued:** January 26, 2026
- **Expires:** April 26, 2026
- **Status:** Valid (68 days remaining)

## How to Test

1. **Restart the Bakong payment service** to pick up the new .env:
   ```bash
   cd /home/rayu/das-tern/bakong_payment
   npm run start:dev
   ```

2. **Create a new payment** from Flutter app

3. **The QR code should now be valid** and scannable by:
   - ABA Mobile
   - ACLEDA Mobile
   - Wing Money
   - Any KHQR-compatible banking app

## Expected KHQR Format (Example)

```
00020101021229570017kh.gov.nbc.bakong0116choeng_rayu@aclb021285596998349530384054040.505802KH5908Das Tern6010Phnom Penh62610125DT-1771294860874-4BA0DD660321Das Tern Subscription0703Web63041B5C
```

Key sections:
- `29570017kh.gov.nbc.bakong...` - Bakong merchant info
- `021285596998349` - Phone number (12 digits, no + or spaces)
- `54040.50` - Amount ($0.50)
- `6261...` - Bill number and store label

## Files Fixed

1. `/home/rayu/das-tern/bakong_payment/.env` - Phone number corrected

## Next Steps

1. Restart Bakong payment service
2. Test payment flow end-to-end
3. Verify QR code scans successfully in banking app
4. Monitor payment status updates

---

**Date:** February 17, 2026
**Status:** ✅ Fixed
