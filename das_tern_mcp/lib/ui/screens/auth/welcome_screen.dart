import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/language_switcher.dart';

/// Welcome/landing screen shown to unauthenticated users.
/// 70% photo with overlay text, 30% bottom panel with Sign In / Create Account.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = constraints.maxHeight * 0.70;
          final bottomHeight = constraints.maxHeight * 0.30;
          final isCompactBottomPanel = bottomHeight < 232;
          final buttonHeight = isCompactBottomPanel ? 48.0 : 50.0;
          final verticalPadding = isCompactBottomPanel ? 20.0 : 28.0;
          final buttonSpacing = isCompactBottomPanel ? 10.0 : 12.0;
          final footerSpacing = isCompactBottomPanel ? 12.0 : 16.0;

          return Stack(
            children: [
              // ── 70% image section ──────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/maximilianovich-doctor-5710159_1920.jpg',
                      fit: BoxFit.cover,
                    ),
                    // Dark gradient overlay so text is readable
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x22000000), Color(0xAA000000)],
                        ),
                      ),
                    ),
                    // Welcome text at bottom of the image area
                    Positioned(
                      bottom: 36,
                      left: 28,
                      right: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.welcomeTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.welcomeScreenSubtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Language switcher top-right
                    const Positioned(
                      top: 52,
                      right: 16,
                      child: LanguageSwitcherButton(),
                    ),
                  ],
                ),
              ),

              // ── 30% bottom panel ──────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: bottomHeight,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sign In button (filled blue)
                      SizedBox(
                        height: buttonHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF1B7EDB)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Text(
                              l10n.signIn,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: buttonSpacing),

                      // Sign Up button (outlined)
                      SizedBox(
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/register-role'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1B7EDB),
                            side: const BorderSide(
                              color: Color(0xFF1B7EDB),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            l10n.createAccount,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B7EDB),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: footerSpacing),

                      // Emergency Access link
                      Center(
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
                              color: Color(0xFF1B7EDB),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
