import 'package:das_tern/data/models/medication.dart';

class ProcessOcrResultUseCase {
  List<Medication> call(String rawText) {
    final List<String> lines = rawText
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const <Medication>[];
    }

    return List<Medication>.generate(lines.length, (int index) {
      final List<String> parts = lines[index]
          .split(',')
          .map((String part) => part.trim())
          .where((String part) => part.isNotEmpty)
          .toList();

      final String name = parts.isNotEmpty ? parts[0] : 'Unknown';
      final double dosage = parts.length > 1
          ? double.tryParse(parts[1]) ?? 1
          : 1;
      final String unit = parts.length > 2 ? parts[2] : 'tablet';
      final String frequency = parts.length > 3 ? parts[3] : '1 time/day';

      return Medication(
        id: 'ocr-${index + 1}',
        name: name,
        dosage: dosage,
        unit: unit,
        frequency: frequency,
      );
    });
  }
}
