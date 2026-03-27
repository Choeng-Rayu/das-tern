import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/app_button.dart';

/// Welcome/landing screen shown to unauthenticated users.
/// Clean, professional design with centered content and buttons.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF4A9FBF), const Color(0xFF3A8FAF)]
                : [const Color(0xFF5DADE2), const Color(0xFF3498DB)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 60),

                      // Welcome Title
                      Text(
                        l10n.welcomeTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Color(0x4D000000),
                              offset: Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        l10n.welcomeScreenSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xF2FFFFFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Color(0x33000000),
                              offset: Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Buttons container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0x26FFFFFF),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0x4DFFFFFF),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 30,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Sign In button
                            AppButton(
                              text: l10n.signIn,
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/login'),
                              backgroundColor: Colors.white,
                              textColor: const Color(0xFF3498DB),
                              shape: AppButtonShape.pill,
                              size: AppButtonSize.large,
                              elevation: 0,
                            ),
                            const SizedBox(height: 16),

                            // Create Account button
                            AppButton(
                              text: l10n.createAccount,
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed('/register-role'),
                              style: AppButtonStyle.outlined,
                              borderColor: Colors.white,
                              textColor: Colors.white,
                              borderWidth: 2,
                              shape: AppButtonShape.pill,
                              size: AppButtonSize.large,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Emergency Access
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.emergencyAccess,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Color(0x4D000000),
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // Language switcher
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const LanguageSwitcherButton(lightBackground: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
