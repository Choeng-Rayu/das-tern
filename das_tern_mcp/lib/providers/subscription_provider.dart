import 'dart:async';

import 'package:app_links/app_links.dart';
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
  SubscriptionProvider({
    ApiService? apiService,
    LoggerService? loggerService,
    AppLinks? appLinks,
  })  : _api = apiService ?? ApiService.instance,
        _log = loggerService ?? LoggerService.instance,
        _appLinks = appLinks ?? AppLinks();

  final ApiService _api;
  final LoggerService _log;
  final AppLinks _appLinks;

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
  StreamSubscription<Uri>? _paymentLinkSubscription;
  int _pollAttempts = 0;
  static const int _maxPollAttempts = 180; // 15 min at 5s intervals
  bool _paymentLinkListenerStarted = false;

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
  bool get isPremium =>
      currentTier == 'PREMIUM' || currentTier == 'FAMILY_PREMIUM';
  bool get isPlatinum => currentTier == 'FAMILY_PREMIUM';
  bool get hasOcrAccess =>
      currentTier == 'PREMIUM' ||
      currentTier == 'FAMILY_PREMIUM' ||
      currentTier == 'PLATINUM';
  bool get hasGroupPlan => currentTier == 'PLATINUM';

  // Trial status
  bool get isOnTrial {
    if (_subscription?['expiresAt'] == null) return false;
    final expiresAt = DateTime.tryParse(_subscription!['expiresAt']);
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt) && currentTier == 'PREMIUM';
  }

  DateTime? get trialExpiresAt {
    if (_subscription?['expiresAt'] == null) return null;
    return DateTime.tryParse(_subscription!['expiresAt']);
  }

  int get trialDaysRemaining {
    if (!isOnTrial || trialExpiresAt == null) return 0;
    return trialExpiresAt!.difference(DateTime.now()).inDays;
  }

  bool get hasUsedTrial => _subscription?['hasUsedTrial'] == true;
  bool get canClaimTrial =>
      !isPremium && currentTier == 'FREEMIUM' && !hasUsedTrial;

  String? get qrCode => _currentPayment?['payment']?['qrCode'];
  String? get md5Hash => _currentPayment?['payment']?['md5Hash'];
  String? get deepLink => _currentPayment?['payment']?['deepLink'];

  /// Load subscription info and available plans.
  /// Tries bakong-payment endpoint first, falls back to /subscriptions/me.
  Future<void> loadSubscription() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Try to load subscription - fallback chain
      try {
        final results = await Future.wait([
          _api.getBakongSubscription(),
          _api.getBakongPlans(),
        ]).timeout(const Duration(seconds: 10));

        _subscription = results[0]['subscription'] as Map<String, dynamic>?;
        _limits = results[0]['limits'] as Map<String, dynamic>?;

        final plansData = results[1];
        _plans = plansData['plans'] as List<dynamic>?;
        _paymentMethods = plansData['paymentMethods'] as List<dynamic>?;
      } catch (_) {
        // Fallback: load from /subscriptions/me directly
        _log.warning(
          'Subscription',
          'Bakong endpoint failed, falling back to /subscriptions/me',
        );
        try {
          final sub = await _api.getSubscription().timeout(
            const Duration(seconds: 10),
          );
          _subscription = sub;
        } catch (e2) {
          _log.error('Subscription', 'Fallback also failed', e2);
          rethrow;
        }
      }

      _log.info('Subscription', 'Loaded: tier=${_subscription?['tier']}');
    } catch (e) {
      _log.error('Subscription', 'Failed to load subscription', e);
      _errorMessage = 'Failed to load subscription info.';
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

      _log.info('Payment', 'Created payment: md5=$md5Hash');

      // Start listening to payment return deep links once per provider lifecycle.
      await _initPaymentReturnListener();

      // Start polling
      _startPolling();

      return true;
    } catch (e) {
      _log.error('Payment', 'Failed to create payment', e);
      _errorMessage = e is ApiException
          ? e.message
          : 'Failed to create payment';
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
        } else if (status == 'FAILED' ||
            status == 'EXPIRED' ||
            status == 'CANCELLED') {
          _stopPolling();
        }

        notifyListeners();
      }
    } catch (e) {
      _log.error('Payment', 'Poll failed (attempt $_pollAttempts)', e);
      // Don't stop polling on individual errors — retry next interval
    }
  }

  /// Force an immediate status refresh (used on app resume/deep-link return).
  Future<void> refreshPaymentStatusNow() async {
    await _pollPaymentStatus();
  }

  Future<void> _initPaymentReturnListener() async {
    if (_paymentLinkListenerStarted) {
      return;
    }
    _paymentLinkListenerStarted = true;

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handlePaymentCallbackUri(initialUri);
      }
    } catch (error) {
      _log.warning(
        'Payment',
        'Failed reading initial payment deep link',
        error,
      );
    }

    _paymentLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handlePaymentCallbackUri(uri);
      },
      onError: (error) {
        _log.warning('Payment', 'Payment deep link stream error', error);
      },
    );
  }

  void _handlePaymentCallbackUri(Uri uri) {
    if (!_isPaymentCallbackUri(uri)) {
      return;
    }

    _log.info('Payment', 'Payment return deep link received', uri.toString());
    unawaited(_pollPaymentStatus());
  }

  bool _isPaymentCallbackUri(Uri uri) {
    return uri.scheme == 'dastern' && uri.host == 'payment';
  }

  /// Reset payment state (e.g. when navigating away).
  void resetPayment() {
    _stopPolling();
    _currentPayment = null;
    _paymentStatus = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Upgrade to Platinum plan via /subscriptions/upgrade.
  /// Platinum = FAMILY_PREMIUM tier in the backend.
  Future<bool> upgradeToPlatinum() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _api.upgradeSubscription('FAMILY_PREMIUM');
      _subscription = result;
      _isLoading = false;
      notifyListeners();
      loadSubscription();
      return true;
    } catch (e) {
      _log.error('Subscription', 'Failed to upgrade to Platinum', e);
      _errorMessage = e is ApiException
          ? e.message
          : 'Failed to upgrade to Platinum.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Claim the 1-month free Premium trial.
  /// Uses /subscriptions/claim-trial endpoint to set tier to PREMIUM.
  Future<bool> claimFreeTrial() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _api.claimFreeTrial();
      // Immediately update local subscription so the UI reflects PREMIUM
      _subscription = result;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      _log.info('Subscription', 'Free trial claimed successfully');

      // Also reload full subscription in background to refresh limits
      loadSubscription();

      return true;
    } catch (e) {
      _log.error('Subscription', 'Failed to claim free trial', e);
      _errorMessage = e is ApiException
          ? e.message
          : 'Failed to claim free trial. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _paymentLinkSubscription?.cancel();
    super.dispose();
  }
}
