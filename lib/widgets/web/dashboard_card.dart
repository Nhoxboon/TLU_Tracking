import 'package:flutter/material.dart';
import 'package:android_app/utils/constants/app_theme.dart';
import 'package:android_app/widgets/web/dashboard_icon.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final Color iconColor;
  final DashboardIconType iconType;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.iconType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 262,
      height: 161,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 54,
            offset: Offset(6, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Card content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Opacity(
                  opacity: 0.7,
                  child: Text(title, style: AppTextStyles.cardTitle),
                ),
                const SizedBox(height: 16),

                // Value
                Text(value, style: AppTextStyles.cardValue),
              ],
            ),
          ),

          // Icon
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: .21),
              ),
              child: DashboardIcon(type: iconType, color: iconColor, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}
