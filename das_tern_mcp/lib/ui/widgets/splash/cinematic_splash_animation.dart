import 'dart:math';
import 'package:flutter/material.dart';
import 'floating_particles.dart';
import 'healthcare_painters.dart';
import '../../theme/app_colors.dart';

/// Data for each floating healthcare icon that orbits around the logo.
class _HealthcareIconData {
  final CustomPainter Function(Color color, double opacity) painterBuilder;
  final double angle; // starting angle in radians
  final double orbitRadius;
  final int targetLetterIndex; // letter index this icon "morphs" into

  const _HealthcareIconData({
    required this.painterBuilder,
    required this.angle,
    required this.orbitRadius,
    required this.targetLetterIndex,
  });
}

/// The cinematic splash animation for DasTern.
///
/// 5-phase timeline:
///   Phase 1 (0.00–0.12): Clean startup – dark bg fades in
///   Phase 2 (0.12–0.38): Floating elements appear – particles, icons, scattered letters
///   Phase 3 (0.38–0.62): Logo formation – letters assemble, icons converge
///   Phase 4 (0.62–0.88): Final brand moment – glow pulse, ECG sweep, tagline
///   Phase 5 (0.88–1.00): Transition – fade to white for page switch
class CinematicSplashAnimation extends StatefulWidget {
  /// Called when the animation completes and the app should navigate away.
  final VoidCallback onAnimationComplete;

  const CinematicSplashAnimation({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<CinematicSplashAnimation> createState() =>
      _CinematicSplashAnimationState();
}

class _CinematicSplashAnimationState extends State<CinematicSplashAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _particleController;

  // Letter data for "DasTern"
  static const String _logoText = 'DasTern';
  final List<Offset> _letterScatterPositions = [];
  List<Particle> _particles = [];
  bool _particlesInitialized = false;

  // Healthcare icons config
  late final List<_HealthcareIconData> _healthcareIcons;

  @override
  void initState() {
    super.initState();

    // Main 4-second animation
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Continuous particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _particleController.addListener(_updateParticles);

    _healthcareIcons = [
      _HealthcareIconData(
        painterBuilder: (c, o) => PillPainter(color: c, opacity: o),
        angle: 0,
        orbitRadius: 110,
        targetLetterIndex: 0, // D
      ),
      _HealthcareIconData(
        painterBuilder: (c, o) => MedicalCrossPainter(color: c, opacity: o),
        angle: pi * 0.4,
        orbitRadius: 120,
        targetLetterIndex: 1, // a
      ),
      _HealthcareIconData(
        painterBuilder: (c, o) => StethoscopePainter(color: c, opacity: o),
        angle: pi * 0.8,
        orbitRadius: 115,
        targetLetterIndex: 3, // T
      ),
      _HealthcareIconData(
        painterBuilder: (c, o) => ClockPainter(color: c, opacity: o),
        angle: pi * 1.2,
        orbitRadius: 125,
        targetLetterIndex: 5, // r
      ),
      _HealthcareIconData(
        painterBuilder: (c, o) => PillPainter(color: c, opacity: o),
        angle: pi * 1.6,
        orbitRadius: 105,
        targetLetterIndex: 6, // n
      ),
    ];

    // Generate random scatter positions for letters
    final random = Random(42);
    for (int i = 0; i < _logoText.length; i++) {
      _letterScatterPositions.add(
        Offset(
          (random.nextDouble() - 0.5) * 300,
          (random.nextDouble() - 0.5) * 400,
        ),
      );
    }

    _mainController.forward();

    // Trigger navigation callback after animation + 1s delay
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });
  }

  void _updateParticles() {
    if (_particles.isNotEmpty && mounted) {
      final size = MediaQuery.of(context).size;
      updateParticles(_particles, size.width, size.height);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_particlesInitialized) {
      final size = MediaQuery.of(context).size;
      _particles = generateParticles(40, size.width, size.height);
      _particlesInitialized = true;
    }
  }

  @override
  void dispose() {
    _particleController.removeListener(_updateParticles);
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _particleController]),
      builder: (context, _) {
        final t = _mainController.value;
        return _buildScene(t);
      },
    );
  }

  Widget _buildScene(double t) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine colors based on theme
    final primaryColor = isDarkMode
        ? AppColors.darkPrimary
        : AppColors.primaryBlue;
    final bgStartColor = isDarkMode
        ? AppColors.darkScaffold
        : const Color(0xFF0A1628);
    final bgEndColor = isDarkMode
        ? const Color(0xFF1A1A2E)
        : const Color(0xFF16213E);
    final transitionColor = isDarkMode ? AppColors.darkScaffold : Colors.white;

    // Phase 1: Background fade in (0.00 – 0.12)
    final bgOpacity = _remap(t, 0, 0.12, 0, 1);

    // Phase 5: Transition overlay (0.88 – 1.0)
    final transitionOverlay = _remap(t, 0.88, 1.0, 0, 1);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(Colors.black, bgStartColor, bgOpacity) ?? bgStartColor,
            Color.lerp(Colors.black, bgEndColor, bgOpacity) ?? bgEndColor,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Floating particles
          if (t > 0.08)
            CustomPaint(
              size: size,
              painter: FloatingParticlesPainter(
                particles: _particles,
                color: primaryColor,
                globalOpacity:
                    _remap(t, 0.08, 0.25, 0, 1) *
                    (1 - _remap(t, 0.88, 1.0, 0, 1)),
              ),
            ),

          // Radial glow behind the logo area
          if (t > 0.3) Center(child: _buildRadialGlow(t, primaryColor)),

          // Healthcare icons (floating then converging)
          if (t > 0.12 && t < 0.75)
            ..._buildHealthcareIcons(t, size, primaryColor),

          // Animated letters
          if (t > 0.15) _buildLetters(t, size, primaryColor, isDarkMode),

          // ECG line sweep across the formed logo (Phase 4)
          if (t > 0.65 && t < 0.88) _buildEcgSweep(t, size, primaryColor),

          // Tagline fade in (Phase 4)
          if (t > 0.68) _buildTagline(t, isDarkMode),

          // Transition overlay (Phase 5)
          if (transitionOverlay > 0)
            Container(
              color: transitionColor.withValues(alpha: transitionOverlay),
            ),
        ],
      ),
    );
  }

  /// Radial glow background behind the logo.
  Widget _buildRadialGlow(double t, Color primaryColor) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final glowOpacity =
        _remap(t, 0.3, 0.65, 0, isDarkMode ? 0.5 : 0.35) *
        (1 - _remap(t, 0.88, 1.0, 0, 1));

    // Pulse effect in Phase 4 - more dramatic
    double pulse = 1.0;
    if (t > 0.62 && t < 0.88) {
      final pulseT = _remap(t, 0.62, 0.88, 0, 1);
      pulse = 1.0 + 0.12 * sin(pulseT * pi * 3);
    }

    return Container(
      width: 320 * pulse,
      height: 320 * pulse,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            primaryColor.withValues(alpha: glowOpacity),
            primaryColor.withValues(alpha: glowOpacity * 0.5),
            primaryColor.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  /// Builds the floating healthcare icons that orbit and converge.
  List<Widget> _buildHealthcareIcons(double t, Size size, Color primaryColor) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Phase 2: icons appear and orbit (0.12 – 0.38)
    final appearT = _remap(t, 0.12, 0.25, 0, 1);
    // Phase 3: icons converge toward their target letters (0.38 – 0.62)
    final convergeT = _remap(t, 0.38, 0.62, 0, 1);
    // Fade out as they converge
    final iconOpacity = appearT * (1 - _remap(t, 0.55, 0.75, 0, 1));

    // Orbit rotation over time
    final orbitAngle = _remap(t, 0.12, 0.62, 0, pi * 1.5);

    return _healthcareIcons.map((icon) {
      // Orbiting position
      final currentAngle = icon.angle + orbitAngle;
      final orbitX =
          cx + cos(currentAngle) * icon.orbitRadius * (1 - convergeT);
      final orbitY =
          cy + sin(currentAngle) * icon.orbitRadius * (1 - convergeT);

      // Target position (towards center where the letter will form)
      final targetX = cx;
      final targetY = cy;

      final x = orbitX + (targetX - orbitX) * convergeT;
      final y = orbitY + (targetY - orbitY) * convergeT;

      return Positioned(
        left: x - 16,
        top: y - 16,
        child: Opacity(
          opacity: iconOpacity.clamp(0.0, 1.0),
          child: SizedBox(
            width: 32,
            height: 32,
            child: CustomPaint(
              painter: icon.painterBuilder(
                primaryColor,
                iconOpacity.clamp(0.0, 1.0),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Builds the letter-by-letter assembly animation.
  Widget _buildLetters(
    double t,
    Size size,
    Color primaryColor,
    bool isDarkMode,
  ) {
    // Phase 2: letters scatter/appear (0.15 – 0.38)
    final scatterAppear = _remap(t, 0.15, 0.3, 0, 1);
    // Phase 4: scale up to final size (0.55 – 0.65)
    final scaleUp = _remap(t, 0.55, 0.65, 1.0, 1.1);
    // Phase 5: fade out (0.88 – 1.0)
    final fadeOut = 1 - _remap(t, 0.88, 1.0, 0, 1);

    return Center(
      child: Opacity(
        opacity: (scatterAppear * fadeOut).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scaleUp.clamp(1.0, 1.1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_logoText.length, (i) {
              final char = _logoText[i];
              final scatter = _letterScatterPositions[i];

              // Stagger each letter's appearance
              final letterDelay = i * 0.02;
              final letterAppear = _remap(
                t,
                0.15 + letterDelay,
                0.3 + letterDelay,
                0,
                1,
              );
              final letterAssemble = Curves.easeOutCubic.transform(
                _remap(t, 0.38 + letterDelay, 0.55 + letterDelay, 0, 1),
              );

              // Move from scattered position to assembled position
              final dx = scatter.dx * (1 - letterAssemble);
              final dy = scatter.dy * (1 - letterAssemble);

              final isCapital = char == 'D' || char == 'T';

              return Transform.translate(
                offset: Offset(dx, dy),
                child: Opacity(
                  opacity: letterAppear.clamp(0.0, 1.0),
                  child: Text(
                    char,
                    style: TextStyle(
                      fontFamily: 'Serif',
                      fontSize: isCapital ? 52 : 46,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: t > 0.55
                          ? [
                              Shadow(
                                color: primaryColor.withValues(
                                  alpha: _remap(t, 0.55, 0.7, 0, 0.7),
                                ),
                                blurRadius: 24,
                              ),
                              Shadow(
                                color: primaryColor.withValues(
                                  alpha: _remap(t, 0.55, 0.7, 0, 0.4),
                                ),
                                blurRadius: 12,
                              ),
                            ]
                          : [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// ECG line that sweeps across the formed logo.
  Widget _buildEcgSweep(double t, Size size, Color primaryColor) {
    final ecgProgress = _remap(t, 0.65, 0.82, 0, 1);
    final ecgOpacity =
        _remap(t, 0.65, 0.7, 0, 0.7) * (1 - _remap(t, 0.8, 0.88, 0, 1));

    return Center(
      child: Opacity(
        opacity: ecgOpacity.clamp(0.0, 1.0),
        child: SizedBox(
          width: 280,
          height: 60,
          child: CustomPaint(
            painter: EcgPainter(
              progress: ecgProgress.clamp(0.0, 1.0),
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Tagline that fades in below the logo.
  Widget _buildTagline(double t, bool isDarkMode) {
    final taglineOpacity =
        _remap(t, 0.68, 0.78, 0, 1) * (1 - _remap(t, 0.88, 1.0, 0, 1));

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Opacity(
          opacity: taglineOpacity.clamp(0.0, 1.0),
          child: Text(
            'Your Health, Our Priority',
            style: TextStyle(
              fontFamily: 'Serif',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDarkMode ? Colors.white60 : Colors.white70,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }

  /// Remaps a value from [inMin..inMax] to [outMin..outMax], clamped.
  static double _remap(
    double value,
    double inMin,
    double inMax,
    double outMin,
    double outMax,
  ) {
    final t = ((value - inMin) / (inMax - inMin)).clamp(0.0, 1.0);
    return outMin + (outMax - outMin) * t;
  }
}
