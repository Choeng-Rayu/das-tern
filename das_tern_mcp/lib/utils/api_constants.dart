import 'package:flutter/foundation.dart';

class ApiConstants {
  // IMPORTANT: Set this to your computer's local IP when testing on a physical device
  // Find it with: ip a | grep "inet " (on Linux)
  // For Android emulator: 10.0.2.2
  // For physical device on WiFi: your computer's IP (e.g., 192.168.0.189)
  static const String hostIpAddress =
      '172.20.10.2'; // Current machine Wi-Fi IP (hotspot: 172.20.10.2)

  // Toggle emulator host via --dart-define=USE_ANDROID_EMULATOR=true
  static const bool useAndroidEmulator = bool.fromEnvironment(
    'USE_ANDROID_EMULATOR',
    defaultValue: false,
  );
  static const String androidEmulatorHost = '10.0.2.2';

  // Backend API configuration
  static const String apiPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '3001',
  );
  static const String apiPrefix = 'api/v1';

  static String get baseHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final host = useAndroidEmulator ? androidEmulatorHost : hostIpAddress;
      return 'http://$host';
    }
    return 'http://127.0.0.1';
  }

  static String get apiBaseUrl => '$baseHost:$apiPort/$apiPrefix';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
