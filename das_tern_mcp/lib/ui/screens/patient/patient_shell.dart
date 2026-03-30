import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/shell_tab_controller.dart';
import '../../../core/router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bottom_navigation.dart';
import 'tab/patient_home_tab.dart';
import 'tab/patient_medications_tab.dart';
import 'tab/patient_scan_tab.dart';
import 'tab/patient_family_tab.dart';
import 'tab/patient_settings_tab.dart';

/// Patient dashboard shell with 5-tab bottom navigation.
/// Figma tabs: ទំព័រដើម | ការវិភាគថ្នាំ | ស្កេនវេជ្ជបញ្ជា | មុខងារគ្រួសារ | ការកំណត់
class PatientShell extends StatefulWidget {
  const PatientShell({super.key});

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _currentIndex = 0;
  late final PageController _pageController;
  ShellTabController? _shellTabController;

  final _tabs = const [
    PatientHomeTab(),
    PatientMedicationsTab(),
    PatientScanTab(),
    PatientFamilyTab(),
    PatientSettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<ShellTabController>();
    if (!identical(_shellTabController, controller)) {
      _shellTabController?.removeListener(_onTabSwitch);
      _shellTabController = controller;
      _shellTabController?.addListener(_onTabSwitch);
    }
  }

  void _onTabSwitch() {
    final i = _shellTabController?.requestedIndex ?? _currentIndex;
    if (!mounted) return;
    setState(() => _currentIndex = i);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _shellTabController?.removeListener(_onTabSwitch);
    _pageController.dispose();
    super.dispose();
  }

  void _showQuickAddMenu(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Create Prescription
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primaryBlue,
                  ),
                ),
                title: Text(
                  l10n.createPrescriptionManual,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n.createPrescriptionManualDesc,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(
                    context,
                    AppRouter.patientPrescriptionWizard,
                  );
                },
              ),
              const Divider(height: 1),
              // Scan Prescription
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.successGreen.withValues(
                    alpha: 0.1,
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: AppColors.successGreen,
                  ),
                ),
                title: Text(
                  l10n.scanPrescriptionOption,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n.scanPrescriptionOptionDesc,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  // Navigate to scan tab
                  setState(() => _currentIndex = 2);
                  _pageController.animateToPage(
                    2,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              const Divider(height: 1),
              // Quick Add
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(
                    0xFF7E57C2,
                  ).withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: Color(0xFF7E57C2),
                  ),
                ),
                title: Text(
                  l10n.quickAddMedicine,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n.quickAddMedicineDesc,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRouter.patientCreateMedicine);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        children: _tabs.map((t) => _KeepAliveTab(child: t)).toList(),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'patient_shell_fab',
              onPressed: () => _showQuickAddMenu(context, l10n),
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(l10n.addMedicine),
              elevation: 4,
            )
          : null,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          _pageController.animateToPage(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          NavItem(
            icon: CupertinoIcons.house,
            activeIcon: CupertinoIcons.house_fill,
            label: l10n.homeTab,
          ),
          NavItem(
            icon: CupertinoIcons.heart,
            activeIcon: CupertinoIcons.heart_fill,
            label: l10n.medicationsAnalysis,
          ),
          NavItem(
            icon: CupertinoIcons.camera_fill,
            activeIcon: CupertinoIcons.camera_fill,
            label: l10n.scanPrescriptionTab,
            isProminent: true,
          ),
          NavItem(
            icon: CupertinoIcons.person_2,
            activeIcon: CupertinoIcons.person_2_fill,
            label: l10n.familyFeatures,
          ),
          NavItem(
            icon: CupertinoIcons.settings,
            activeIcon: CupertinoIcons.settings_solid,
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}

/// Wrapper that keeps a tab alive in a [PageView] so state is not lost when
/// swiping away and returning.
class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
