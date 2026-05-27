import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../data/medication_repository.dart';
import '../../data/prescription_repository.dart';
import '../../domain/prescription.dart';

// ── Repositories ──────────────────────────────────────────────────────

final Provider<PrescriptionRepository> prescriptionRepositoryProvider =
    Provider<PrescriptionRepository>(
  (ref) => PrescriptionRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    sync: ref.watch(syncEngineProvider),
  ),
);

final Provider<MedicationRepository> medicationRepositoryProvider =
    Provider<MedicationRepository>(
  (ref) => MedicationRepositoryImpl(
    db: ref.watch(appDatabaseProvider),
    sync: ref.watch(syncEngineProvider),
  ),
);

// ── Data providers ────────────────────────────────────────────────────

final StreamProviderFamily<List<Prescription>, String>
    prescriptionsByPatientProvider =
    StreamProvider.family<List<Prescription>, String>(
  (ref, patientId) =>
      ref.watch(prescriptionRepositoryProvider).watchByPatient(patientId),
);

final StreamProviderFamily<List<Prescription>, String>
    activePrescriptionsProvider =
    StreamProvider.family<List<Prescription>, String>(
  (ref, patientId) =>
      ref.watch(prescriptionRepositoryProvider).watchActive(patientId),
);

final AutoDisposeFutureProviderFamily<Prescription?, String>
    prescriptionDetailProvider =
    FutureProvider.autoDispose.family<Prescription?, String>(
  (ref, id) => ref.watch(prescriptionRepositoryProvider).findById(id),
);
