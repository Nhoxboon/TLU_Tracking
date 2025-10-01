import 'package:flutter/material.dart';
import 'package:android_app/widgets/common/confirmation_dialog.dart';

/// A reusable action button widget with hover and press effects
class CustomActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final String? tooltip;
  final bool requiresConfirmation;
  final String? confirmationTitle;
  final String? confirmationMessage;

  const CustomActionButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.size = 32,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 8,
    this.tooltip,
    this.requiresConfirmation = false,
    this.confirmationTitle,
    this.confirmationMessage,
  });

  void _handleTap(BuildContext context) async {
    if (requiresConfirmation) {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: confirmationTitle ?? 'Xác nhận xóa',
        message:
            confirmationMessage ??
            'Bạn có chắc chắn muốn xóa? Hành động này không thể hoàn tác.',
      );

      if (confirmed == true) {
        onTap();
      }
    } else {
      onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final widget = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(borderRadius),
        hoverColor: iconColor.withValues(alpha: 0.1),
        splashColor: iconColor.withValues(alpha: 0.2),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFFAFBFD),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? const Color(0xFFD5D5D5),
              width: 0.6,
            ),
          ),
          child: Icon(
            icon,
            size: size * 0.5, // Icon size is half of container size
            color: iconColor,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: widget);
    }

    return widget;
  }
}
