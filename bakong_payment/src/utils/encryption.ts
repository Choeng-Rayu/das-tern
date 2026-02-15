import * as crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16;
const SALT_LENGTH = 64;
const KEY_LENGTH = 32;
const TAG_LENGTH = 16;
const TAG_POSITION = SALT_LENGTH + IV_LENGTH;
const ENCRYPTED_POSITION = TAG_POSITION + TAG_LENGTH;

/**
 * Derives encryption key from password using PBKDF2
 */
function getKey(salt: Buffer, password: string): Buffer {
    return crypto.pbkdf2Sync(password, salt, 100000, KEY_LENGTH, 'sha512');
}

/**
 * Encrypts data using AES-256-GCM
 * @param data - Data to encrypt
 * @param password - Encryption password (from env ENCRYPTION_KEY)
 * @returns Encrypted data as base64 string
 */
export function encrypt(data: string, password?: string): string {
    const encryptionKey = password || process.env.ENCRYPTION_KEY;

    if (!encryptionKey) {
        throw new Error('Encryption key not configured');
    }

    const salt = crypto.randomBytes(SALT_LENGTH);
    const iv = crypto.randomBytes(IV_LENGTH);
    const key = getKey(salt, encryptionKey);

    const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
    const encrypted = Buffer.concat([cipher.update(data, 'utf8'), cipher.final()]);
    const tag = cipher.getAuthTag();

    return Buffer.concat([salt, iv, tag, encrypted]).toString('base64');
}

/**
 * Decrypts data encrypted with encrypt function
 * @param encryptedData - Base64 encrypted data
 * @param password - Encryption password (from env ENCRYPTION_KEY)
 * @returns Decrypted data as string
 */
export function decrypt(encryptedData: string, password?: string): string {
    const encryptionKey = password || process.env.ENCRYPTION_KEY;

    if (!encryptionKey) {
        throw new Error('Encryption key not configured');
    }

    const data = Buffer.from(encryptedData, 'base64');

    const salt = data.subarray(0, SALT_LENGTH);
    const iv = data.subarray(SALT_LENGTH, TAG_POSITION);
    const tag = data.subarray(TAG_POSITION, ENCRYPTED_POSITION);
    const encrypted = data.subarray(ENCRYPTED_POSITION);

    const key = getKey(salt, encryptionKey);

    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    decipher.setAuthTag(tag);

    return decipher.update(encrypted) + decipher.final('utf8');
}

/**
 * Hashes data using SHA-256
 * @param data - Data to hash
 * @returns Hash as hex string
 */
export function hash(data: string): string {
    return crypto.createHash('sha256').update(data).digest('hex');
}

/**
 * Generates MD5 hash (for Bakong payment tracking)
 * @param data - Data to hash
 * @returns MD5 hash as hex string
 */
export function md5(data: string): string {
    return crypto.createHash('md5').update(data).digest('hex');
}

/**
 * Generates HMAC-SHA256 signature for webhooks
 * @param data - Data to sign
 * @param secret - Secret key
 * @returns HMAC signature as hex string
 */
export function generateHmacSignature(data: string, secret: string): string {
    return crypto.createHmac('sha256', secret).update(data).digest('hex');
}

/**
 * Verifies HMAC-SHA256 signature
 * @param data - Original data
 * @param signature - Signature to verify
 * @param secret - Secret key
 * @returns True if signature is valid
 */
export function verifyHmacSignature(data: string, signature: string, secret: string): boolean {
    const expectedSignature = generateHmacSignature(data, secret);
    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature));
}
