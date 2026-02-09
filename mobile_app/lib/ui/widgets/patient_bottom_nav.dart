import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class PatientBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int? badgeCount;

  const PatientBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badgeCount,
  });

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primaryBlue : AppColors.neutralGray,
                size: 24,
              ),
              if (badgeCount != null && badgeCount! > 0 && index == 3)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      badgeCount! > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppColors.primaryBlue : AppColors.neutralGray,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkBlue
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home, 'ទំព័រដើម', 0),
                _buildNavItem(Icons.analytics_outlined, Icons.analytics, 'ការវិភាគថ្នាំ', 1),
                const SizedBox(width: 56),
                _buildNavItem(Icons.people_outline, Icons.people, 'មុខងារគ្រួសារ', 3),
                _buildNavItem(Icons.settings_outlined, Icons.settings, 'ការកំណត់', 4),
              ],
            ),
          ),
          Positioned(
            top: -7,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: FloatingActionButton(
              onPressed: () => onTap(2),
              backgroundColor: AppColors.primaryBlue,
              elevation: 4,
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
