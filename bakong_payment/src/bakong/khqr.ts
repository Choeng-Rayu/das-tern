import QRCode from 'qrcode-generator';
import { md5 } from '../utils/encryption';
import logger from '../utils/logger';

export interface KHQRParams {
    bankAccount: string;        // Merchant ID
    merchantName: string;       // Merchant display name
    merchantCity: string;       // Merchant city
    amount: number;            // Payment amount
    currency: string;          // USD or KHR
    storeLabel?: string;       // Store identifier
    phoneNumber: string;       // Merchant phone (without +)
    billNumber: string;        // Unique bill/invoice number
    terminalLabel?: string;    // Terminal identifier
    isStatic?: boolean;        // Static vs dynamic QR
}

export interface ImageOptions {
    format: 'png' | 'svg' | 'buffer';
    size?: number;
    margin?: number;
}

export interface DeeplinkOptions {
    callback?: string;         // Success callback URL
    appIconUrl?: string;      // App icon URL
    appName?: string;         // App name for display
}

/**
 * KHQR (Khmer QR) Implementation for Bakong Payments
 * Based on EMV QR Code Specification
 */
export class BakongKHQR {
    /**
     * Creates a KHQR code string
     * @param params - KHQR parameters
     * @returns KHQR string
     */
    static createQR(params: KHQRParams): string {
        const {
            bankAccount,
            merchantName,
            merchantCity,
            amount,
            currency,
            storeLabel,
            phoneNumber,
            billNumber,
            terminalLabel,
            isStatic = false,
        } = params;

        // EMV / KHQR Code data format
        // Tag order MUST follow the official Bakong KHQR specification:
        // 00, 01, 29, 52, 58, 59, 60, 99, 54, 53, 62, 63
        const qrData: string[] = [];

        // Tag 00 - Payload Format Indicator
        qrData.push(this.formatTag('00', '01'));

        // Tag 01 - Point of Initiation Method: 11 = static, 12 = dynamic
        qrData.push(this.formatTag('01', isStatic ? '11' : '12'));

        // Tag 29 - Merchant Account Information (Bakong Individual)
        // Sub-tag 00: GUID must be exactly "bakong.gov.kh" per NBC KHQR spec
        // Sub-tag 01: Bakong account (e.g. "choeng_rayu@aclb")
        // Sub-tag 02: Phone number (optional)
        const merchantInfo = [
            this.formatTag('00', 'bakong.gov.kh'),
            this.formatTag('01', bankAccount),
        ];
        if (phoneNumber) {
            merchantInfo.push(this.formatTag('02', phoneNumber));
        }
        qrData.push(this.formatTag('29', merchantInfo.join('')));

        // Tag 52 - Merchant Category Code (required by KHQR spec)
        qrData.push(this.formatTag('52', '5999'));

        // Tag 58 - Country Code
        qrData.push(this.formatTag('58', 'KH'));

        // Tag 59 - Merchant Name
        qrData.push(this.formatTag('59', merchantName));

        // Tag 60 - Merchant City
        qrData.push(this.formatTag('60', merchantCity));

        // Tag 99 - Timestamp (required by KHQR spec)
        // Format: languagePreference(00) + length(2digit) + timestampMs
        const timestampMs = Date.now().toString();
        const tsLenStr = timestampMs.length.toString().padStart(2, '0');
        const tsField = '00' + tsLenStr + timestampMs;
        qrData.push(this.formatTag('99', tsField));

        // Tag 54 - Transaction Amount (dynamic QR only)
        // NOTE: Per KHQR spec, amount (54) comes BEFORE currency (53)
        if (!isStatic && amount > 0) {
            qrData.push(this.formatTag('54', amount.toFixed(2)));
        }

        // Tag 53 - Transaction Currency (840 = USD, 116 = KHR)
        const currencyCode = currency === 'USD' ? '840' : '116';
        qrData.push(this.formatTag('53', currencyCode));

        // Tag 62 - Additional Data Field
        const additionalData: string[] = [];
        if (billNumber) {
            additionalData.push(this.formatTag('01', billNumber));
        }
        if (storeLabel) {
            additionalData.push(this.formatTag('03', storeLabel));
        }
        if (terminalLabel) {
            additionalData.push(this.formatTag('07', terminalLabel));
        }
        if (additionalData.length > 0) {
            qrData.push(this.formatTag('62', additionalData.join('')));
        }

        // Tag 63 - CRC placeholder (4 zeros, value filled below)
        qrData.push('6304');

        // Join and calculate CRC16-CCITT
        const qrString = qrData.join('');
        const crc = this.calculateCRC16(qrString);
        const finalQR = qrString + crc.toString(16).toUpperCase().padStart(4, '0');

        logger.info('KHQR code generated', {
            billNumber,
            amount,
            currency,
            bankAccount,
        });

        return finalQR;
    }

    /**
     * Generates MD5 hash from QR code string (required by Bakong for payment tracking)
     * @param qrCode - KHQR string
     * @returns MD5 hash
     */
    static generateMD5(qrCode: string): string {
        return md5(qrCode);
    }

    /**
     * Generates QR code image
     * @param qrCode - KHQR string
     * @param options - Image options
     * @returns QR code image data
     */
    static generateQRImage(qrCode: string, options: ImageOptions = { format: 'png', size: 256 }): string {
        const { size = 256, margin = 4 } = options;

        const qr = QRCode(0, 'M');
        qr.addData(qrCode);
        qr.make();

        // Generate base64 data URL for PNG
        return qr.createDataURL(size / qr.getModuleCount(), margin);
    }

    /**
     * Generates Bakong deep link for mobile app
     * @param qrCode - KHQR string
     * @param options - Deep link options
     * @returns Deep link URL
     */
    static generateDeeplink(qrCode: string, options?: DeeplinkOptions): string {
        const base = 'bakong://qr';
        const params = new URLSearchParams();

        params.append('qr', qrCode);

        if (options?.callback) {
            params.append('callback', options.callback);
        }

        if (options?.appIconUrl) {
            params.append('appIconUrl', options.appIconUrl);
        }

        if (options?.appName) {
            params.append('appName', options.appName);
        }

        return `${base}?${params.toString()}`;
    }

    /**
     * Formats a tag-length-value (TLV) entry
     * @param tag - Tag identifier
     * @param value - Tag value
     * @returns Formatted TLV string
     */
    private static formatTag(tag: string, value: string): string {
        const length = value.length.toString().padStart(2, '0');
        return `${tag}${length}${value}`;
    }

    /**
     * Calculates CRC16-CCITT checksum
     * @param data - Data to calculate checksum for
     * @returns CRC16 checksum
     */
    private static calculateCRC16(data: string): number {
        const polynomial = 0x1021; // CRC16-CCITT polynomial
        let crc = 0xFFFF;

        for (let i = 0; i < data.length; i++) {
            crc ^= data.charCodeAt(i) << 8;

            for (let j = 0; j < 8; j++) {
                if (crc & 0x8000) {
                    crc = (crc << 1) ^ polynomial;
                } else {
                    crc = crc << 1;
                }
            }
        }

        return crc & 0xFFFF;
    }
}
