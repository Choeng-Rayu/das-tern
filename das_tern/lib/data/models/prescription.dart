import 'package:das_tern/data/models/medication.dart';

class Prescription {
  const Prescription({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.medications,
    required this.issuedAt,
    this.notes,
  });

  final String id;
  final String patientId;
  final String doctorName;
  final List<Medication> medications;
  final DateTime issuedAt;
  final String? notes;
}
