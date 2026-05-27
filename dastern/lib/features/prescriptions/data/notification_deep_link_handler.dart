import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Handles incoming notification taps and routes to the correct screen.
///
/// Notification payloads follow the shape set by the Postgres trigger:
/// `{ "prescription_id": "...", "doctor_id": "..." }`
///
/// Spec ref: 03-prescription-medication §5.4.
class NotificationDeepLinkHandler {
  const NotificationDeepLinkHandler._();

  /// Call this from `onDidReceiveNotificationResponse` (local notifications)
  /// or from the FCM `onMessageOpenedApp` handler.
  ///
  /// [payload] is the raw JSON string stored in the notification's data field.
  static void handle(BuildContext context, String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final prescriptionId = data['prescription_id'] as String?;
      if (prescriptionId == null) return;

      // Route to the prescription detail page with focus=draft so the
      // confirm/reject buttons are highlighted.
      context.push(
        '/patient/prescriptions/$prescriptionId',
        extra: <String, dynamic>{'focus': 'draft'},
      );
    } catch (_) {
      // Malformed payload — ignore silently.
    }
  }
}
