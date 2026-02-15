import 'package:flutter/material.dart';
import '../models/doctor_dashboard_model/doctor_dashboard_models.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';

/// State provider for the Doctor Dashboard feature.
/// Manages dashboard overview, patient list, patient details,
/// adherence data, connection management, and doctor notes.
class DoctorDashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final LoggerService _log = LoggerService.instance;

  // ── Dashboard Overview ──
  bool _dashboardLoading = false;
  DashboardOverview? _dashboardOverview;

  // ── Patient List ──
  bool _patientListLoading = false;
  List<PatientListItem> _patients = [];
  int _totalPatients = 0;
  String? _adherenceFilter;
  String _sortBy = 'adherencePercentage';
  String _sortOrder = 'asc';
  int _page = 1;
  String? _searchQuery;

  // ── Patient Details ──
  bool _detailsLoading = false;
  PatientDetails? _selectedPatientDetails;

  // ── Adherence Data ──
  bool _adherenceLoading = false;
  AdherenceResult? _patientAdherence;

  // ── Pending Connections ──
  bool _pendingLoading = false;
  List<PendingConnection> _pendingConnections = [];

  // ── Doctor Notes ──
  bool _notesLoading = false;
  List<DoctorNote> _doctorNotes = [];

  // ── Doctor Prescriptions ──
  bool _prescriptionsLoading = false;
  List<Map<String, dynamic>> _doctorPrescriptions = [];
  int _totalPrescriptions = 0;

  // ── Error State ──
  String? _error;

  // ── Getters ──
  bool get dashboardLoading => _dashboardLoading;
  DashboardOverview? get dashboardOverview => _dashboardOverview;

  bool get patientListLoading => _patientListLoading;
  List<PatientListItem> get patients => _patients;
  int get totalPatients => _totalPatients;
  String? get adherenceFilter => _adherenceFilter;
  String? get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  int get currentPage => _page;

  bool get detailsLoading => _detailsLoading;
  PatientDetails? get selectedPatientDetails => _selectedPatientDetails;

  bool get adherenceLoading => _adherenceLoading;
  AdherenceResult? get patientAdherence => _patientAdherence;

  bool get pendingLoading => _pendingLoading;
  List<PendingConnection> get pendingConnections => _pendingConnections;

  bool get notesLoading => _notesLoading;
  List<DoctorNote> get doctorNotes => _doctorNotes;

  bool get prescriptionsLoading => _prescriptionsLoading;
  List<Map<String, dynamic>> get doctorPrescriptions => _doctorPrescriptions;
  int get totalPrescriptions => _totalPrescriptions;

  String? get error => _error;

  int get patientsNeedingAttention =>
      _dashboardOverview?.patientsNeedingAttention ?? 0;
  int get pendingRequestCount =>
      _dashboardOverview?.pendingRequests ?? _pendingConnections.length;

  // ────────────────────────────────────────────
  // Dashboard Overview
  // ────────────────────────────────────────────

  Future<void> fetchDashboardOverview() async {
    _dashboardLoading = true;
    _error = null;
    notifyListeners();
    try {
      final json = await _api.getDoctorDashboard();
      _dashboardOverview = DashboardOverview.fromJson(json);
      _log.success('DoctorDashboard', 'Dashboard overview loaded');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('DoctorDashboard', 'Failed to load dashboard', e);
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  // ────────────────────────────────────────────
  // Patient List
  // ────────────────────────────────────────────

  Future<void> fetchPatients({bool reset = false}) async {
    if (reset) _page = 1;
    _patientListLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getDoctorPatients(
        adherenceFilter: _adherenceFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        page: _page,
        limit: 20,
        search: _searchQuery,
      );
      final rawList = List<Map<String, dynamic>>.from(result['patients'] ?? []);
      _patients = rawList.map((e) => PatientListItem.fromJson(e)).toList();
      _totalPatients = result['total'] ?? 0;
      _log.success('DoctorDashboard', 'Patient list loaded: ${_patients.length}');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('DoctorDashboard', 'Failed to load patients', e);
    } finally {
      _patientListLoading = false;
      notifyListeners();
    }
  }

  void setAdherenceFilter(String? filter) {
    _adherenceFilter = filter;
    fetchPatients(reset: true);
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    fetchPatients(reset: true);
  }

  void setSorting(String sortBy, String order) {
    _sortBy = sortBy;
    _sortOrder = order;
    fetchPatients(reset: true);
  }

  void nextPage() {
    _page++;
    fetchPatients();
  }

  // ────────────────────────────────────────────
  // Patient Details
  // ────────────────────────────────────────────

  Future<void> fetchPatientDetails(String patientId) async {
    _detailsLoading = true;
    _error = null;
    notifyListeners();
    try {
      final json = await _api.getDoctorPatientDetails(patientId);
      _selectedPatientDetails = PatientDetails.fromJson(json);
      _log.success('DoctorDashboard', 'Patient details loaded: $patientId');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('DoctorDashboard', 'Failed to load patient details', e);
    } finally {
      _detailsLoading = false;
      notifyListeners();
    }
  }

  // ────────────────────────────────────────────
  // Adherence
  // ────────────────────────────────────────────

  Future<void> fetchPatientAdherence(String patientId,
      {String? startDate, String? endDate}) async {
    _adherenceLoading = true;
    _error = null;
    notifyListeners();
    try {
      final json = await _api.getDoctorPatientAdherence(
        patientId,
        startDate: startDate,
        endDate: endDate,
      );
      _patientAdherence = AdherenceResult.fromJson(json);
      _log.success('DoctorDashboard', 'Adherence data loaded');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('DoctorDashboard', 'Failed to load adherence', e);
    } finally {
      _adherenceLoading = false;
      notifyListeners();
    }
  }

  // ────────────────────────────────────────────
  // Pending Connections
  // ────────────────────────────────────────────

  Future<void> fetchPendingConnections() async {
    _pendingLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getDoctorPendingConnections();
      _pendingConnections = List<Map<String, dynamic>>.from(result)
          .map((e) => PendingConnection.fromJson(e))
          .toList();
      _log.success('DoctorDashboard',
          'Pending connections loaded: ${_pendingConnections.length}');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('DoctorDashboard', 'Failed to load pending connections', e);
    } finally {
      _pendingLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptConnection(String connectionId) async {
    try {
      await _api.acceptDoctorConnection(connectionId);
      _pendingConnections.removeWhere((c) => c.id == connectionId);
      notifyListeners();
      await fetchDashboardOverview();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectConnection(String connectionId, {String? reason}) async {
    try {
      await _api.rejectDoctorConnection(connectionId, reason: reason);
      _pendingConnections.removeWhere((c) => c.id == connectionId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> disconnectPatient(String connectionId, String reason) async {
    try {
      await _api.disconnectDoctorPatient(connectionId, reason);
      notifyListeners();
      await fetchDashboardOverview();
      await fetchPatients(reset: true);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ────────────────────────────────────────────
  // Doctor Notes
  // ────────────────────────────────────────────

  Future<void> fetchNotes(String patientId) async {
    _notesLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getDoctorNotes(patientId);
      _doctorNotes = List<Map<String, dynamic>>.from(result)
          .map((e) => DoctorNote.fromJson(e))
          .toList();
      _log.success(
          'DoctorDashboard', 'Notes loaded: ${_doctorNotes.length}');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('DoctorDashboard', 'Failed to load notes', e);
    } finally {
      _notesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNote(String patientId, String content) async {
    try {
      final json = await _api.createDoctorNote(patientId, content);
      _doctorNotes.insert(0, DoctorNote.fromJson(json));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNote(String noteId, String content) async {
    try {
      final json = await _api.updateDoctorNote(noteId, content);
      final updated = DoctorNote.fromJson(json);
      final index = _doctorNotes.indexWhere((n) => n.id == noteId);
      if (index >= 0) {
        _doctorNotes[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ────────────────────────────────────────────
  // Utility
  // ────────────────────────────────────────────

  Future<bool> deleteNote(String noteId) async {
    try {
      await _api.deleteDoctorNote(noteId);
      _doctorNotes.removeWhere((n) => n.id == noteId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ────────────────────────────────────────────
  // Doctor Prescriptions
  // ────────────────────────────────────────────

  Future<void> fetchDoctorPrescriptions({String? status}) async {
    _prescriptionsLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getDoctorPrescriptions(status: status);
      _doctorPrescriptions =
          List<Map<String, dynamic>>.from(result['prescriptions'] ?? []);
      _totalPrescriptions = result['total'] ?? 0;
      _log.success('DoctorDashboard',
          'Prescriptions loaded: ${_doctorPrescriptions.length}');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _log.error('DoctorDashboard', 'Failed to load prescriptions', e);
    } finally {
      _prescriptionsLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearPatientDetails() {
    _selectedPatientDetails = null;
    _patientAdherence = null;
    _doctorNotes = [];
    notifyListeners();
  }
}
