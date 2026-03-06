class AdherenceResult {
  final double percentage;
  final int takenCount;
  final int totalCount;
  final String colorCode;
  final String period;

  AdherenceResult({
    required this.percentage,
    required this.takenCount,
    required this.totalCount,
    this.colorCode = 'GREEN',
    this.period = 'daily',
  });

  factory AdherenceResult.fromJson(Map<String, dynamic> json) {
    return AdherenceResult(
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      takenCount: json['takenCount'] as int? ?? json['taken'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? json['total'] as int? ?? 0,
      colorCode: json['colorCode'] as String? ?? 'GREEN',
      period: json['period'] as String? ?? 'daily',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'percentage': percentage,
      'takenCount': takenCount,
      'totalCount': totalCount,
      'colorCode': colorCode,
      'period': period,
    };
  }
}

class AdherenceTrendData {
  final DateTime date;
  final double percentage;
  final int takenCount;
  final int totalCount;

  AdherenceTrendData({
    required this.date,
    required this.percentage,
    required this.takenCount,
    required this.totalCount,
  });

  factory AdherenceTrendData.fromJson(Map<String, dynamic> json) {
    return AdherenceTrendData(
      date: DateTime.parse(json['date'] as String),
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      takenCount: json['takenCount'] as int? ?? json['taken'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'percentage': percentage,
      'takenCount': takenCount,
      'totalCount': totalCount,
    };
  }
}
