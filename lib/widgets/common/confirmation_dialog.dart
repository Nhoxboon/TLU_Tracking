import 'package:flutter/material.dart';

/// A reusable confirmation dialog widget
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final Color confirmButtonColor;
  final Color cancelButtonColor;

  const ConfirmationDialog({
    super.key,
    this.title = 'Xác nhận',
    this.message = 'Bạn có chắc chắn muốn thực hiện hành động này?',
    this.confirmText = 'Xác nhận',
    this.cancelText = 'Hủy',
    required this.onConfirm,
    this.onCancel,
    this.confirmButtonColor = const Color(0xFFDC2626), // Red for delete action
    this.cancelButtonColor = const Color(0xFF6B7280), // Gray for cancel
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width:
            MediaQuery.of(context).size.width *
            0.25, // Thu nhỏ về 1/4 chiều rộng màn hình
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF171C26),
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF464F60),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: cancelButtonColor, width: 1),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cancelButtonColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Confirm button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmButtonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to show the confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    String title = 'Xác nhận xóa',
    String message =
        'Bạn có chắc chắn muốn xóa? Hành động này không thể hoàn tác.',
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
    Color confirmButtonColor = const Color(0xFFDC2626),
    Color cancelButtonColor = const Color(0xFF6B7280),
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          confirmButtonColor: confirmButtonColor,
          cancelButtonColor: cancelButtonColor,
          onConfirm:
              () {}, // Empty callback, giá trị trả về được xử lý bởi Navigator.pop
          onCancel: () {}, // Empty callback
        );
      },
    );
  }
}
