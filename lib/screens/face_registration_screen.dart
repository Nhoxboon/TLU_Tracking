import 'package:flutter/material.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  bool _isRegistering = false;
  bool _registrationSuccess = false;

  void _startRegistration() {
    setState(() {
      _isRegistering = true;
    });

    // Simulate face registration process
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isRegistering = false;
          _registrationSuccess = true;
        });

        // Show success and navigate back
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1E1E1E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Đăng ký khuôn mặt',
                    style: TextStyle(
                      fontFamily: 'Sen',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF32343E),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Instruction text
              const Text(
                'Vui lòng đặt khuôn mặt vào khung và giữ yên để đăng ký',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Sen',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B6E82),
                ),
              ),

              const SizedBox(height: 40),

              // Face capture area
              Expanded(
                child: Center(
                  child: Container(
                    width: 300,
                    height: 400,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _registrationSuccess
                            ? Colors.green
                            : _isRegistering
                                ? const Color(0xFF2196F3)
                                : Colors.grey,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Camera simulation
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.face,
                              size: 100,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        // Status overlay
                        if (_isRegistering || _registrationSuccess)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isRegistering) ...[
                                    const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2196F3),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Đang đăng ký...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ] else if (_registrationSuccess) ...[
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Đăng ký thành công!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Register button
              if (!_isRegistering && !_registrationSuccess)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _startRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Bắt đầu đăng ký',
                      style: TextStyle(
                        fontFamily: 'Sen',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}