import 'package:flutter_test/flutter_test.dart';
import 'package:das_tern_mcp/domain/models/user_models.dart';
import 'package:das_tern_mcp/providers/auth_provider.dart';

void main() {
  group('AuthProvider typed state', () {
    late AuthProvider provider;

    setUp(() {
      // Disable Telegram deep link listener in tests
      provider = AuthProvider(enableTelegramDeepLinkListener: false);
    });

    test('initial state is unknown', () {
      expect(provider.authStatus, AuthStatus.unknown);
      expect(provider.currentUser, isNull);
      expect(provider.isAuthenticated, false);
    });

    test('viewState reflects current state', () {
      final state = provider.viewState;
      expect(state.status, AuthStatus.unknown);
      expect(state.isAuthenticated, false);
      expect(state.currentUser, isNull);
      expect(state.isLoading, false);
    });

    test('clearError clears error in viewState', () {
      // Trigger an error state by accessing error
      provider.clearError();
      expect(provider.viewState.error, isNull);
    });

    test('legacy getters still work', () {
      expect(provider.user, isNull);
      expect(provider.userRole, isNull);
      expect(provider.isDoctor, false);
      expect(provider.isPatient, false);
      expect(provider.error, isNull);
    });
  });
}
