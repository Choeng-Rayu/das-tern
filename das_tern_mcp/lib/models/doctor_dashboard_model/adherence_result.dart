/// Adherence calculation result from the doctor dashboard API.
class AdherenceResult {
  final double overallPercentage;
  final String level; // 'GREEN' | 'YELLOW' | 'RED'
  final int totalDoses;
  final int takenDoses;
  final int missedDoses;
  final int lateDoses;
  final List<AdherenceTimelinePoint> timeline;

  AdherenceResult({
    required this.overallPercentage,
    required this.level,
    required this.totalDoses,
    required this.takenDoses,
    required this.missedDoses,
    required this.lateDoses,
    this.timeline = const [],
  });

  factory AdherenceResult.fromJson(Map<String, dynamic> json) {
    return AdherenceResult(
      overallPercentage: (json['overallPercentage'] ?? 0).toDouble(),
      level: json['level'] ?? 'GREEN',
      totalDoses: json['totalDoses'] ?? 0,
      takenDoses: json['takenDoses'] ?? 0,
      missedDoses: json['missedDoses'] ?? 0,
      lateDoses: json['lateDoses'] ?? 0,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => AdherenceTimelinePoint.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'overallPercentage': overallPercentage,
        'level': level,
        'totalDoses': totalDoses,
        'takenDoses': takenDoses,
        'missedDoses': missedDoses,
        'lateDoses': lateDoses,
        'timeline': timeline.map((t) => t.toJson()).toList(),
      };

  bool get isGreen => level == 'GREEN';
  bool get isYellow => level == 'YELLOW';
  bool get isRed => level == 'RED';
}

/// Represents a single day's adherence data point.
class AdherenceTimelinePoint {
  final String date;
  final double percentage;
  final int takenDoses;
  final int totalDoses;

  AdherenceTimelinePoint({
    required this.date,
    required this.percentage,
    required this.takenDoses,
    required this.totalDoses,
  });

  factory AdherenceTimelinePoint.fromJson(Map<String, dynamic> json) {
    return AdherenceTimelinePoint(
      date: json['date'] ?? '',
      percentage: (json['percentage'] ?? 0).toDouble(),
      takenDoses: json['takenDoses'] ?? 0,
      totalDoses: json['totalDoses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'percentage': percentage,
        'takenDoses': takenDoses,
        'totalDoses': totalDoses,
      };
}
