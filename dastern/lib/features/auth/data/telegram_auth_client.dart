import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../domain/auth_failure.dart';
import '../domain/chosen_role.dart';

/// Handles the Telegram OIDC PKCE flow via an external browser.
/// The code-exchange step runs in the `auth-telegram` Edge Function.
class TelegramAuthClient {
  TelegramAuthClient(this._supabase, this._secure);
  final SupabaseClient _supabase;
  final FlutterSecureStorage _secure;

  static const _stateKey = 'tg_state_v1';
  static const _redirectUri = 'dastern://auth/telegram/callback';

  Future<void> startAndCompleteSignIn({ChosenRole? role}) async {
    final state = _randomBase64Url(32);
    final codeVerifier = _randomBase64Url(64);
    final codeChallenge = _sha256B64Url(codeVerifier);

    await _secure.write(
      key: _stateKey,
      value: jsonEncode({'state': state, 'verifier': codeVerifier}),
    );

    final config = AppConfig.fromEnvironment();
    final authUrl = Uri.https('oauth.telegram.org', '/auth', <String, String>{
      'bot_id': config.telegramBotClientId,
      'scope': 'openid',
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'dastern',
    );

    final cb = Uri.parse(result);
    final code = cb.queryParameters['code'];
    final returnedState = cb.queryParameters['state'];
    final stored = jsonDecode(
      (await _secure.read(key: _stateKey)) ?? '{}',
    ) as Map<String, dynamic>;

    if (returnedState != stored['state']) throw const AuthFailure.cancelled();
    if (code == null) throw const AuthFailure.invalidProviderResponse();

    final res = await _supabase.functions.invoke(
      'auth-telegram',
      body: <String, dynamic>{
        'code': code,
        'codeVerifier': stored['verifier'],
        'redirectUri': _redirectUri,
        if (role != null) 'role': role.code,
      },
    );

    if (res.status != 200) {
      throw AuthFailure.serverError(
        (res.data as Map<String, dynamic>?)?['error']?.toString(),
      );
    }

    final body = res.data as Map<String, dynamic>;
    if (body['hashed_token'] != null && body['email'] != null) {
      await _supabase.auth.verifyOTP(
        type: OtpType.magiclink,
        token: body['hashed_token'] as String,
        email: body['email'] as String,
      );
    } else if (body['access_token'] != null && body['refresh_token'] != null) {
      await _supabase.auth.setSession(body['refresh_token'] as String);
    } else {
      throw const AuthFailure.invalidProviderResponse();
    }

    await _secure.delete(key: _stateKey);
  }

  static String _randomBase64Url(int byteCount) {
    final bytes = List<int>.generate(
      byteCount,
      (_) => DateTime.now().microsecondsSinceEpoch & 0xFF,
    );
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _sha256B64Url(String input) {
    final digest = sha256.convert(utf8.encode(input));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
