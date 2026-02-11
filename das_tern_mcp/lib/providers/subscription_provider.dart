import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';

/// Provider for subscription and Bakong payment state.
///
/// Manages:
/// - Current subscription tier & status
/// - Payment creation + QR code data
/// - Payment status polling (every 5s)
/// - Success/failure state transitions
class SubscriptionProvider extends ChangeNotifier {
  final _api = ApiService();
  final _log = LoggerService.instance;

  // Subscription state
  Map<String, dynamic>? _subscription;
  Map<String, dynamic>? _limits;
  List<dynamic>? _plans;
  List<dynamic>? _paymentMethods;

  // Payment state
  Map<String, dynamic>? _currentPayment;
  String _paymentStatus = ''; // PENDING, PAID, FAILED, TIMEOUT
  String? _errorMessage;
  bool _isLoading = false;
  bool _isPolling = false;
  Timer? _pollingTimer;
  int _pollAttempts = 0;
  static const int _maxPollAttempts = 180; // 15 min at 5s intervals

  // Getters
  Map<String, dynamic>? get subscription => _subscription;
  Map<String, dynamic>? get limits => _limits;
  List<dynamic>? get plans => _plans;
  List<dynamic>? get paymentMethods => _paymentMethods;
  Map<String, dynamic>? get currentPayment => _currentPayment;
  String get paymentStatus => _paymentStatus;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isPolling => _isPolling;

  String get currentTier => _subscription?['tier'] ?? 'FREEMIUM';
  bool get isPremium => currentTier == 'PREMIUM' || currentTier == 'FAMILY_PREMIUM';

  String? get qrCode => _currentPayment?['payment']?['qrCode'];
  String? get md5Hash => _currentPayment?['payment']?['md5Hash'];
  String? get deepLink => _currentPayment?['payment']?['deepLink'];

  /// Load subscription info and available plans.
  Future<void> loadSubscription() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final results = await Future.wait([
        _api.getBakongSubscription(),
        _api.getBakongPlans(),
      ]);

      _subscription = results[0]['subscription'] as Map<String, dynamic>?;
      _limits = results[0]['limits'] as Map<String, dynamic>?;

      final plansData = results[1];
      _plans = plansData['plans'] as List<dynamic>?;
      _paymentMethods = plansData['paymentMethods'] as List<dynamic>?;

      _log.info('Subscription', 'Loaded: tier=${_subscription?['tier']}');
    } catch (e) {
      _log.error('Subscription', 'Failed to load subscription', e);
      _errorMessage = 'Failed to load subscription info';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a Bakong payment for the given plan type.
  Future<bool> createPayment(String planType) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _paymentStatus = '';
      _currentPayment = null;
      notifyListeners();

      _currentPayment = await _api.createBakongPayment(planType);
      _paymentStatus = 'PENDING';

      _log.info('Payment', 'Created payment: md5=${md5Hash}');

      // Start polling
      _startPolling();

      return true;
    } catch (e) {
      _log.error('Payment', 'Failed to create payment', e);
      _errorMessage = e is ApiException ? e.message : 'Failed to create payment';
      _paymentStatus = 'FAILED';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Start polling for payment status updates.
  void _startPolling() {
    _stopPolling();
    _isPolling = true;
    _pollAttempts = 0;

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollPaymentStatus(),
    );
  }

  /// Stop polling.
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    _pollAttempts = 0;
  }

  /// Poll the backend for payment status.
  Future<void> _pollPaymentStatus() async {
    if (md5Hash == null) return;

    _pollAttempts++;
    if (_pollAttempts >= _maxPollAttempts) {
      _paymentStatus = 'TIMEOUT';
      _stopPolling();
      notifyListeners();
      return;
    }

    try {
      final response = await _api.checkBakongPaymentStatus(md5Hash!);
      final status = response['payment']?['status'] as String?;

      if (status != null && status != _paymentStatus) {
        _paymentStatus = status;
        _log.info('Payment', 'Status changed: $status');

        if (status == 'PAID') {
          _stopPolling();
          // Reload subscription to reflect upgrade
          await loadSubscription();
        } else if (status == 'FAILED' || status == 'EXPIRED' || status == 'CANCELLED') {
          _stopPolling();
        }

        notifyListeners();
      }
    } catch (e) {
      _log.error('Payment', 'Poll failed (attempt $_pollAttempts)', e);
      // Don't stop polling on individual errors — retry next interval
    }
  }

  /// Reset payment state (e.g. when navigating away).
  void resetPayment() {
    _stopPolling();
    _currentPayment = null;
    _paymentStatus = '';
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
