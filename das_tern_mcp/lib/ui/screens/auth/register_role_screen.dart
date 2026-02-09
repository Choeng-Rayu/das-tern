import 'package:flutter/material.dart';
import '../../../ui/theme/app_spacing.dart';

/// Screen for choosing registration role: Patient or Doctor.
/// Matches Figma gradient background + Khmer labels.
class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2B7A9E),
              Color(0xFF1A5276),
              Color(0xFF154360),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Back button ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),

                // ── Logo ──
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      'ដាស់តឿន',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                const Text(
                  'ខ្ញុំជា...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'ជ្រើសរើសតួនាទីរបស់អ្នកដើម្បីចាប់ផ្តើម',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Patient card
                _RoleCard(
                  icon: Icons.person_outline,
                  title: 'អ្នកជំងឺ',
                  description:
                      'តាមដានថ្នាំ កំណត់ការរំលឹក និងគ្រប់គ្រងវេជ្ជបញ្ជា។',
                  onTap: () =>
                      Navigator.of(context).pushNamed('/register/patient'),
                ),
                const SizedBox(height: AppSpacing.md),

                // Doctor card
                _RoleCard(
                  icon: Icons.medical_services_outlined,
                  title: 'វេជ្ជបណ្ឌិត',
                  description:
                      'គ្រប់គ្រងអ្នកជំងឺ បង្កើតវេជ្ជបញ្ជា និងតាមដានការទទួលទានថ្នាំ។',
                  onTap: () =>
                      Navigator.of(context).pushNamed('/register/doctor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
