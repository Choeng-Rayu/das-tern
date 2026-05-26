/// Use case: parse raw OCR text and extract a list of [Medication] candidates.
///
/// Pure business logic — no Flutter, no HTTP, no I/O.
library;

import '../../data/models/medication.dart';

/// Parses OCR text from a scanned prescription image and returns a list of
/// best-effort [Medication] candidates.
///
/// The parser uses simple heuristics:
///  - Lines that look like medication names (capitalised words).
///  - Dosage extracted from patterns like `500mg`, `1 tablet`, `10ml`.
///  - Frequency extracted from keywords: `twice`, `once`, `3 times`, etc.
///
/// Returns an empty list if nothing parseable is found.
///
/// Usage:
/// ```dart
/// final meds = ProcessOcrResultUseCase()(ocrText);
/// ```
class ProcessOcrResultUseCase {
  const ProcessOcrResultUseCase();

  // ── Regex patterns ────────────────────────────────────────────────────────

  static final RegExp _dosagePattern = RegExp(
    r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml|tablet|tab|cap|capsule|unit|iu)',
    caseSensitive: false,
  );

  static final RegExp _frequencyKeyword = RegExp(
    r'\b(once|twice|three times|3 times|four times|4 times|'
    r'1x|2x|3x|4x|od|bd|tds|qds|qid|bid|tid)\b',
    caseSensitive: false,
  );

  /// Maps frequency keywords → numeric frequency per day.
  static const Map<String, int> _freqMap = {
    'once': 1,
    '1x': 1,
    'od': 1,
    'twice': 2,
    '2x': 2,
    'bd': 2,
    'bid': 2,
    'three times': 3,
    '3 times': 3,
    '3x': 3,
    'tds': 3,
    'tid': 3,
    'four times': 4,
    '4 times': 4,
    '4x': 4,
    'qds': 4,
    'qid': 4,
  };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Extracts [Medication] candidates from [ocrText].
  List<Medication> call(String ocrText) {
    if (ocrText.trim().isEmpty) return [];

    final lines = ocrText.split(RegExp(r'[\n\r]+'));
    final medications = <Medication>[];
    int idCounter = 1;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final candidate = _tryParseLine(line, idCounter);
      if (candidate != null) {
        medications.add(candidate);
        idCounter++;
      }
    }

    return medications;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Attempts to extract a [Medication] from a single OCR [line].
  ///
  /// Returns `null` if the line doesn't look like a medication entry.
  Medication? _tryParseLine(String line, int idCounter) {
    // Skip very short lines and lines that are purely numeric.
    if (line.length < 3) return null;
    if (RegExp(r'^\d+$').hasMatch(line)) return null;

    // Extract dosage info.
    final dosageMatch = _dosagePattern.firstMatch(line);
    final dosageAmount = dosageMatch?.group(1) ?? '';
    final unit = dosageMatch?.group(2) ?? 'tablet';

    // Extract frequency.
    final freqMatch = _frequencyKeyword.firstMatch(line.toLowerCase());
    final frequency = freqMatch != null
        ? (_freqMap[freqMatch.group(0)!.toLowerCase()] ?? 1)
        : 1;

    // Build a medication name by stripping dosage and frequency tokens.
    final name = _extractName(line, dosageMatch?.group(0), freqMatch?.group(0));
    if (name.isEmpty) return null;

    return Medication(
      id: 'ocr_$idCounter',
      name: name,
      dosage: dosageAmount,
      unit: unit,
      frequency: frequency,
      scheduleTimes: const [],
      isActive: true,
    );
  }

  /// Cleans up the OCR line to produce a medication name.
  String _extractName(String line, String? dosageToken, String? freqToken) {
    var name = line;
    if (dosageToken != null) name = name.replaceFirst(dosageToken, '');
    if (freqToken != null) {
      name = name.replaceAll(
        RegExp(freqToken, caseSensitive: false),
        '',
      );
    }
    // Remove common noise characters.
    name = name.replaceAll(RegExp(r'[^a-zA-Z\s\-]'), '').trim();
    // Collapse whitespace.
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Must start with a letter.
    if (name.isEmpty || !RegExp(r'^[a-zA-Z]').hasMatch(name)) return '';
    return name;
  }
}
