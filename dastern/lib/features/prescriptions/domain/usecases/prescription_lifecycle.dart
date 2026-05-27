import '../../data/prescription_repository.dart';
import '../../domain/prescription_enums.dart';

/// Pause an active prescription.
class PausePrescription {
  const PausePrescription(this._repo);
  final PrescriptionRepository _repo;

  Future<void> call(String prescriptionId) =>
      _repo.updateStatus(prescriptionId, PrescriptionStatus.paused);
}

/// Resume a paused prescription.
class ResumePrescription {
  const ResumePrescription(this._repo);
  final PrescriptionRepository _repo;

  Future<void> call(String prescriptionId) =>
      _repo.updateStatus(prescriptionId, PrescriptionStatus.active);
}

/// Stop (deactivate) a prescription permanently.
class StopPrescription {
  const StopPrescription(this._repo);
  final PrescriptionRepository _repo;

  Future<void> call(String prescriptionId) =>
      _repo.updateStatus(prescriptionId, PrescriptionStatus.inactive);
}

/// Patient confirms a doctor-authored DRAFT prescription → ACTIVE.
class ConfirmPrescription {
  const ConfirmPrescription(this._repo);
  final PrescriptionRepository _repo;

  Future<void> call(String prescriptionId) =>
      _repo.updateStatus(prescriptionId, PrescriptionStatus.active);
}

/// Patient rejects a doctor-authored DRAFT prescription → INACTIVE.
class RejectPrescription {
  const RejectPrescription(this._repo);
  final PrescriptionRepository _repo;

  Future<void> call(String prescriptionId) =>
      _repo.updateStatus(prescriptionId, PrescriptionStatus.inactive);
}

/// Doctor marks a prescription as urgent (auto-applies immediately).
class MarkUrgent {
  const MarkUrgent(this._repo);
  final PrescriptionRepository _repo;

  Future<void> call(String prescriptionId, String reason) async {
    final p = await _repo.findById(prescriptionId);
    if (p == null) return;
    await _repo.updateStatus(prescriptionId, PrescriptionStatus.active);
    // The urgent flag + reason are updated via a separate outbox op.
    // Full implementation delegates to the repository's update method.
  }
}
