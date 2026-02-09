import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dose_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Patient home tab – daily dashboard matching Figma design.
/// Shows greeting, time-period medicine cards, progress circle,
/// today's dose checklist, and quick-action section.
class PatientHomeTab extends StatefulWidget {
  const PatientHomeTab({super.key});

  @override
  State<PatientHomeTab> createState() => _PatientHomeTabState();
}

class _PatientHomeTabState extends State<PatientHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoseProvider>().fetchTodaySchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final doseProvider = context.watch<DoseProvider>();
    final user = auth.user;
    final firstName = user?['firstName'] ?? 'អ្នកជំងឺ';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => doseProvider.fetchTodaySchedule(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Blue header section ──
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF29B6F6),
                      Color(0xFF0288D1),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo row
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.medical_services,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Text(
                              'ដាស់តឿន',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Profile avatar
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Greeting
                        Text(
                          'សូស្តី $firstName !',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Time-period medicine section ──
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'និម្មិតពន្ទុថ្នាំ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ថ្ងៃ អាទិត្យ- ទី ${DateTime.now().day}- ${_khmerMonth(DateTime.now().month)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Time period cards row
                    Row(
                      children: [
                        Expanded(
                          child: _TimePeriodCard(
                            label: 'ពេលព្រឹក',
                            icon: Icons.wb_sunny_outlined,
                            color: AppColors.morningYellow,
                            doseCount: _getDoseCountByPeriod(
                                doseProvider, 'MORNING'),
                            badgeText: 'មុនបាយ',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _TimePeriodCard(
                            label: 'ពេលថ្ងៃ',
                            icon: Icons.wb_twilight,
                            color: AppColors.afternoonOrange,
                            doseCount: _getDoseCountByPeriod(
                                doseProvider, 'AFTERNOON'),
                            badgeText: 'ពេលថ្ងៃ',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _TimePeriodCard(
                            label: 'ពេលយប់',
                            icon: Icons.nightlight_round,
                            color: AppColors.nightPurple,
                            doseCount: _getDoseCountByPeriod(
                                doseProvider, 'NIGHT'),
                            badgeText: 'ពេលយប់',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Progress circle section ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          // Progress circle
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: doseProvider.progress,
                                  strokeWidth: 6,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.5),
                                  color: AppColors.primaryBlue,
                                ),
                                Text(
                                  '${(doseProvider.progress * 30).toInt()} ថ្ងៃ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'អ្នកបានទទួលបន្ទុកបញ្ចូល-ខែភ្នំ',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ថ្ងៃទី${(doseProvider.progress * 30).toInt()}ថ្ងៃហើយ',
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'រយពេលការទទួលថ្នាំសរុប 30ថ្ងៃ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Today's doses (checklist) ──
                    Row(
                      children: [
                        const Icon(Icons.checklist, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        const Text(
                          'ការអំពើក (ថ្ងៃនេះ)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    if (doseProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (doseProvider.todaysDoses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: AppColors.successGreen,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'រួចរាល់ទាំងអស់!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'គ្មានថ្នាំបន្ថែមសម្រាប់ថ្ងៃនេះ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...doseProvider.todaysDoses.map(
                        (dose) => _DoseCheckItem(
                          name: dose.medicationName,
                          dosage: dose.dosage,
                          isTaken: dose.status == 'TAKEN',
                          onTake: () =>
                              doseProvider.markTaken(dose.id ?? ''),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Quick actions (មុខងារសំខាន់ៗ) ──
                    const Text(
                      'មុខងារសំខាន់ៗ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    _QuickActionCard(
                      icon: Icons.translate,
                      title: 'ស្វែងរកថ្នាំបញ្ជា',
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.history,
                            title: 'សកម្មភាពពេល\nទទួលថ្នាំគ្រប់សារ',
                            color: const Color(0xFF0288D1),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.family_restroom,
                            title: 'មុខងារគ្រួសារ',
                            color: const Color(0xFF29B6F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getDoseCountByPeriod(DoseProvider provider, String period) {
    return provider.todaysDoses
        .where((d) => d.timePeriod.toUpperCase() == period)
        .length;
  }

  String _khmerMonth(int month) {
    const months = [
      'មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា',
      'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ',
    ];
    return months[month - 1];
  }
}

// ── Time period card matching Figma ──
class _TimePeriodCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int doseCount;
  final String badgeText;

  const _TimePeriodCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.doseCount,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'ថ្នាំចំនួន $doseCount មុខ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dose check item matching Figma ──
class _DoseCheckItem extends StatelessWidget {
  final String name;
  final String dosage;
  final bool isTaken;
  final VoidCallback onTake;

  const _DoseCheckItem({
    required this.name,
    required this.dosage,
    required this.isTaken,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colored dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isTaken ? AppColors.successGreen : AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  dosage,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '1 គ្រាប់',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: isTaken ? null : onTake,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isTaken
                    ? AppColors.primaryBlue
                    : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              child: isTaken
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick action card ──
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
