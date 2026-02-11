import * as QRCode from 'qrcode-generator';
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

        // EMV QR Code data format
        const qrData: string[] = [];

        // Payload Format Indicator (Tag 00)
        qrData.push(this.formatTag('00', '01'));

        // Point of Initiation Method (Tag 01)
        // 11 = static QR, 12 = dynamic QR
        qrData.push(this.formatTag('01', isStatic ? '11' : '12'));

        // Merchant Account Information (Tag 29 for Bakong)
        const merchantInfo = [
            this.formatTag('00', 'kh.gov.nbc.bakong'),
            this.formatTag('01', bankAccount),
        ];
        if (phoneNumber) {
            merchantInfo.push(this.formatTag('02', phoneNumber));
        }
        qrData.push(this.formatTag('29', merchantInfo.join('')));

        // Transaction Currency (Tag 53) - 840 for USD, 116 for KHR
        const currencyCode = currency === 'USD' ? '840' : '116';
        qrData.push(this.formatTag('53', currencyCode));

        // Transaction Amount (Tag 54) - only for dynamic QR
        if (!isStatic && amount > 0) {
            qrData.push(this.formatTag('54', amount.toFixed(2)));
        }

        // Country Code (Tag 58) - KH for Cambodia
        qrData.push(this.formatTag('58', 'KH'));

        // Merchant Name (Tag 59)
        qrData.push(this.formatTag('59', merchantName));

        // Merchant City (Tag 60)
        qrData.push(this.formatTag('60', merchantCity));

        // Additional Data Field (Tag 62)
        const additionalData: string[] = [];

        // Bill Number (Tag 01)
        if (billNumber) {
            additionalData.push(this.formatTag('01', billNumber));
        }

        // Store Label (Tag 03)
        if (storeLabel) {
            additionalData.push(this.formatTag('03', storeLabel));
        }

        // Terminal Label (Tag 07)
        if (terminalLabel) {
            additionalData.push(this.formatTag('07', terminalLabel));
        }

        if (additionalData.length > 0) {
            qrData.push(this.formatTag('62', additionalData.join('')));
        }

        // CRC (Tag 63) - placeholder, will be calculated
        qrData.push('6304');

        // Join all data
        const qrString = qrData.join('');

        // Calculate CRC16-CCITT and append
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
