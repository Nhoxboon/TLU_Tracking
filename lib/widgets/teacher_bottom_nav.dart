import 'package:flutter/material.dart';

class TeacherBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const TeacherBottomNav({
    Key? key,
    this.currentIndex = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 100,
            offset: const Offset(0, -10),
          ),
        ],
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              currentIndex == 0 ? Icons.home : Icons.home_outlined,
              size: 25,
            ),
            color: currentIndex == 0
                ? const Color(0xFF2196F3)
                : Colors.black.withOpacity(0.7),
            onPressed: () {
              if (onTap != null) {
                onTap!(0);
              } else {
                // Default behavior: navigate to teacher dashboard
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/teacher/dashboard',
                  (route) => false,
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              currentIndex == 1 ? Icons.person : Icons.person_outline,
              size: 25,
            ),
            color: currentIndex == 1
                ? const Color(0xFF2196F3)
                : Colors.black.withOpacity(0.7),
            onPressed: () {
              if (onTap != null) {
                onTap!(1);
              } else {
                // Default behavior: navigate to settings
                Navigator.pushNamed(context, '/student/settings');
              }
            },
          ),
        ],
      ),
    );
  }
}
