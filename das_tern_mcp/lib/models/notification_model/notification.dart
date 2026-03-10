/// Notification model matching the backend Prisma schema.
class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    this.metadata,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Parse `data` (from backend) or `metadata` as optional Map
    final rawData = json['data'] ?? json['metadata'];
    Map<String, dynamic>? meta;
    if (rawData is Map) {
      meta = Map<String, dynamic>.from(rawData);
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      userId:
          json['recipientId']?.toString() ?? json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] == true,
      metadata: meta,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
