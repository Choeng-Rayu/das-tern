import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Typed wrapper for Supabase Storage uploads and signed-URL generation.
///
/// Path builders enforce the `{user_id}/...` prefix automatically so
/// callers never construct raw paths.
///
/// Size cap: 50 MB enforced client-side (server policy also enforces it).
///
/// Spec ref: 01-supabase-data-layer §Phase 7.
class SupabaseStorageHelper {
  const SupabaseStorageHelper(this._client);

  final SupabaseClient _client;

  static const int _maxBytes = 50 * 1024 * 1024; // 50 MB

  // ── Buckets ───────────────────────────────────────────────────────────
  static const String profilePictures = 'profile-pictures';
  static const String prescriptionImages = 'prescription-images';
  static const String doctorLicenses = 'doctor-licenses';

  // ── Upload ────────────────────────────────────────────────────────────

  /// Uploads a profile picture for [userId].
  /// Returns the storage path on success.
  Future<String> uploadProfilePicture({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) =>
      _upload(bucket: profilePictures, path: '$userId/$fileName', bytes: bytes);

  Future<String> uploadPrescriptionImage({
    required String patientId,
    required String prescriptionId,
    required String fileName,
    required Uint8List bytes,
  }) =>
      _upload(
        bucket: prescriptionImages,
        path: '$patientId/$prescriptionId/$fileName',
        bytes: bytes,
      );

  Future<String> uploadDoctorLicense({
    required String doctorId,
    required String fileName,
    required Uint8List bytes,
  }) =>
      _upload(bucket: doctorLicenses, path: '$doctorId/$fileName', bytes: bytes);

  // ── Signed URL ────────────────────────────────────────────────────────

  /// Returns a signed URL valid for [expiresIn] seconds (default 1 hour).
  Future<String> signedUrl(
    String bucket,
    String path, {
    int expiresIn = 3600,
  }) =>
      _client.storage.from(bucket).createSignedUrl(path, expiresIn);

  // ── Internal ──────────────────────────────────────────────────────────

  Future<String> _upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    if (bytes.length > _maxBytes) {
      throw ArgumentError('File exceeds 50 MB limit (${bytes.length} bytes)');
    }
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }
}
