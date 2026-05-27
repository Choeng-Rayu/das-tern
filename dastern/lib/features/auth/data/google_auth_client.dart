import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../domain/auth_failure.dart';

/// Wraps the Google Sign-In plugin and exchanges the ID token with Supabase.
class GoogleAuthClient {
  Future<AuthResponse> authenticate(SupabaseClient supabase) async {
    final google = GoogleSignIn(
      serverClientId: AppConfig.fromEnvironment().googleWebClientId,
      scopes: const <String>['email', 'profile', 'openid'],
    );
    final user = await google.signIn();
    if (user == null) throw const AuthFailure.cancelled();

    final auth = await user.authentication;
    final idToken = auth.idToken;
    if (idToken == null) throw const AuthFailure.invalidProviderResponse();

    return supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
  }
}
