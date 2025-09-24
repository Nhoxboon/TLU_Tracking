import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';

class SidebarItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isActive;

  const SidebarItem({
    super.key,
    required this.title,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: isActive
              ? const BorderRadius.horizontal(right: Radius.circular(6))
              : null,
        ),
        child: Stack(
          children: [
            if (isActive)
              Positioned(
                left: -5,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 9,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 78.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: isActive
                      ? AppTextStyles.activeMenuItem
                      : AppTextStyles.menuItem,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
