import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class DoctorBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const DoctorBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.primaryBlue : AppColors.neutralGray,
            size: 24,
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
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'ទំព័រដើម', 0),
            _buildNavItem(Icons.people_alt_outlined, Icons.people_alt, 'តាមដានអ្នកជំងឺ', 1),
            _buildNavItem(Icons.add_circle_outline, Icons.add_circle, 'បង្កើតវេជ្ជបញ្ជា', 2),
            _buildNavItem(Icons.history, Icons.history, 'ប្រវិត្តវេជ្ជបញ្ជារ', 3),
            _buildNavItem(Icons.settings_outlined, Icons.settings, 'ការកំណត់', 4),
          ],
        ),
      ),
    );
  }
}
