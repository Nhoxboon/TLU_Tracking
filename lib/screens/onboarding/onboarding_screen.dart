import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 90),
                  // Onboarding illustration
                  SizedBox(
                    height: 291,
                    width: 291,
                    child: SvgPicture.asset(
                      'assets/images/onboarding_illustration.svg',
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => Container(
                        height: 291,
                        width: 291,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.checklist_rounded,
                            size: 100,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 83),
                  // Main title text
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                        fontFamily: 'Roboto',
                        letterSpacing: -0.68,
                        height: 1.26,
                      ),
                      children: [
                        TextSpan(text: 'Điểm danh tiện lợi với '),
                        TextSpan(
                          text: 'TLU ',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        TextSpan(text: 'Tracking'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Subtitle text
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 54),
                    child: Text(
                      'Hãy để việc điểm danh và theo dõi tiện lợi hơn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF333333),
                        fontFamily: 'Roboto',
                        letterSpacing: -0.36,
                        height: 1.235,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.only(left: 21, right: 20, bottom: 90),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the next screen
                    Navigator.pushReplacementNamed(context, '/student/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Bắt đầu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
