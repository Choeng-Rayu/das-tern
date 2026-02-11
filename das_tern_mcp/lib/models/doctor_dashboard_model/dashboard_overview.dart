/// Dashboard overview data returned by GET /doctor/dashboard.
class DashboardOverview {
  final int totalPatients;
  final int patientsNeedingAttention;
  final List<MissedDoseAlert> todayAlerts;
  final List<Map<String, dynamic>> recentActivity;
  final int pendingRequests;

  DashboardOverview({
    required this.totalPatients,
    required this.patientsNeedingAttention,
    required this.todayAlerts,
    required this.recentActivity,
    required this.pendingRequests,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      totalPatients: json['totalPatients'] ?? 0,
      patientsNeedingAttention: json['patientsNeedingAttention'] ?? 0,
      todayAlerts: (json['todayAlerts'] as List<dynamic>?)
              ?.map((e) =>
                  MissedDoseAlert.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      recentActivity: (json['recentActivity'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      pendingRequests: json['pendingRequests'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalPatients': totalPatients,
        'patientsNeedingAttention': patientsNeedingAttention,
        'todayAlerts': todayAlerts.map((a) => a.toJson()).toList(),
        'recentActivity': recentActivity,
        'pendingRequests': pendingRequests,
      };
}

/// Alert for missed doses shown on the doctor dashboard.
class MissedDoseAlert {
  final String type; // 'WARNING' | 'CRITICAL'
  final String patientId;
  final String patientName;
  final int consecutiveMissed;
  final DateTime? lastMissedAt;

  MissedDoseAlert({
    required this.type,
    required this.patientId,
    required this.patientName,
    required this.consecutiveMissed,
    this.lastMissedAt,
  });

  factory MissedDoseAlert.fromJson(Map<String, dynamic> json) {
    return MissedDoseAlert(
      type: json['type'] ?? 'WARNING',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? 'Patient',
      consecutiveMissed: json['consecutiveMissed'] ?? 0,
      lastMissedAt: json['lastMissedAt'] != null
          ? DateTime.tryParse(json['lastMissedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'patientId': patientId,
        'patientName': patientName,
        'consecutiveMissed': consecutiveMissed,
        'lastMissedAt': lastMissedAt?.toIso8601String(),
      };

  bool get isCritical => type == 'CRITICAL';
}
