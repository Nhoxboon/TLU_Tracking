import 'package:flutter/material.dart';

class DashboardIcon extends StatelessWidget {
  final DashboardIconType type;
  final Color color;
  final double size;

  const DashboardIcon({
    super.key,
    required this.type,
    required this.color,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case DashboardIconType.server:
        return CustomPaint(
          size: Size(size, size),
          painter: ServerIconPainter(color),
        );
      case DashboardIconType.users:
        return Icon(Icons.groups, color: color, size: size);
      case DashboardIconType.user:
        return Icon(Icons.person, color: color, size: size);
      case DashboardIconType.book:
        return Icon(Icons.menu_book, color: color, size: size);
      case DashboardIconType.briefcase:
        return Icon(Icons.work_outline, color: color, size: size);
      case DashboardIconType.award:
        return Icon(Icons.emoji_events_outlined, color: color, size: size);
    }
  }
}

enum DashboardIconType { server, users, user, book, briefcase, award }

class ServerIconPainter extends CustomPainter {
  final Color color;

  ServerIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

    for (int i = 0; i < 2; i++) {
      final boxHeight = height * 0.15;
      final spacing = height * 0.12;
      final startOffset = height * 0.25;
      final top = startOffset + i * (boxHeight + spacing);
      final bottom = top + boxHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(width * 0.2, top, width * 0.8, bottom),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rect, paint);

      final dotRadius = width * 0.015;
      canvas.drawCircle(
        Offset(width * 0.7, top + boxHeight / 2),
        dotRadius,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
