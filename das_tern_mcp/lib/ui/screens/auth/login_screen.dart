import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/language_switcher.dart';

// ── Google logo widget ──────────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Offset c = Offset(r, r);
    final double sw = r * 0.36; // ring stroke width
    final double mr = r - sw / 2; // mid-radius for arc stroke center

    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(center: c, radius: mr);

    // Arcs drawn clockwise where 0 rad = 3 o'clock.
    // Gap at 3 o'clock: ±14° (for the horizontal bar).
    canvas.drawArc(rect, _rad(14), _rad(91), false, arc(_yellow)); // 14°→105°
    canvas.drawArc(rect, _rad(105), _rad(91), false, arc(_green)); // 105°→196°
    canvas.drawArc(rect, _rad(196), _rad(150), false, arc(_blue)); // 196°→346°
    canvas.drawArc(rect, _rad(346), _rad(28), false, arc(_red)); // 346°→374°

    // Horizontal bar (blue): from center to outer-right edge.
    canvas.drawRect(
      Rect.fromLTRB(c.dx - 1, c.dy - sw / 2, c.dx + r, c.dy + sw / 2),
      Paint()
        ..color = _blue
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final identifier = _identifierController.text.trim();
    final success = await auth.login(identifier, _passwordController.text);

    if (!mounted) return;
    if (success) {
      final role = auth.userRole;
      Navigator.of(
        context,
      ).pushReplacementNamed(role == 'DOCTOR' ? '/doctor' : '/patient');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();

    if (!mounted) return;
    if (success) {
      final role = auth.userRole;
      Navigator.of(
        context,
      ).pushReplacementNamed(role == 'DOCTOR' ? '/doctor' : '/patient');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  Future<void> _handleTelegramSignIn() async {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final success = await auth.signInWithTelegram();

    if (!mounted || success) return;

    final rawError = (auth.error ?? '').toLowerCase();
    String friendlyMessage = l10n.telegramAuthFailed;
    if (rawError.contains('token')) {
      friendlyMessage = l10n.telegramAuthInvalidToken;
    } else if (rawError.contains('network') || rawError.contains('socket')) {
      friendlyMessage = l10n.telegramAuthNetworkError;
    }

    _showErrorDialog(friendlyMessage);
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.error),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.tryAgain),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    // Responsive horizontal padding: scales with screen width
    final hPad = (size.width * 0.06).clamp(16.0, 40.0);
    // Tighten vertical gaps on small/short screens
    final isSmallScreen = size.height < 700;
    final topGap = isSmallScreen ? AppSpacing.lg : AppSpacing.xxl;
    final sectionGap = isSmallScreen ? AppSpacing.md : AppSpacing.xl;
    final iconSize = isSmallScreen ? 56.0 : 72.0;
    final iconInnerSize = isSmallScreen ? 28.0 : 36.0;
    final titleFontSize = size.width < 360 ? 18.0 : 22.0;

    return AuthGradientScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: logo + language switcher ──
            AuthHeader(
              trailing: const LanguageSwitcherButton(lightBackground: true),
            ),
            SizedBox(height: topGap),

            // ── Welcome section ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Column(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_services_rounded,
                      color: const Color(0xFF1976D2),
                      size: iconInnerSize,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.signIn,
                    style: TextStyle(
                      color: const Color(0xFF111111),
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.welcomeMessage,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: sectionGap),

            // ── Form ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email or Phone number
                    AuthFieldLabel(l10n.emailOrPhone),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _identifierController,
                      hintText: l10n.emailOrPhoneHint,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.emailOrPhoneEmpty;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password
                    AuthFieldLabel(l10n.password),
                    const SizedBox(height: AppSpacing.xs),
                    AuthTextField(
                      controller: _passwordController,
                      hintText: l10n.passwordHint,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.passwordEmpty;
                        }
                        if (v.length < 6) {
                          return l10n.passwordTooShort;
                        }
                        return null;
                      },
                    ),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/forgot-password');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.forgotPassword,
                          style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    // Error message
                    if (auth.error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AuthErrorBanner(message: auth.error!),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    // Login button
                    AuthPrimaryButton(
                      onPressed: _handleLogin,
                      isLoading: auth.isLoading,
                      label: l10n.signIn,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── OR divider ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      l10n.orDivider,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Google Sign-In button ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading ? null : _handleGoogleSignIn,
                  icon: const _GoogleIcon(size: 20),
                  label: Text(
                    l10n.signInWithGoogle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF333333),
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Telegram Sign-In button ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: auth.isLoading ? null : _handleTelegramSignIn,
                  icon: const Icon(Icons.telegram, size: 20),
                  label: Text(
                    l10n.continueWithTelegram,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0088CC),
                    disabledBackgroundColor: const Color(0xFF7CC3E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: topGap),

            // ── Register link ──
            AuthLinkRow(
              message: l10n.dontHaveAccount,
              actionText: l10n.createAccount,
              onTap: () => Navigator.of(context).pushNamed('/register-role'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
