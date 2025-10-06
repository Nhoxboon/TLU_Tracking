import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  bool _isScanning = true;
  bool _scanSuccess = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Simulate QR scan success after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _onQRScanned();
      }
    });
  }

  void _onQRScanned() {
    setState(() {
      _isScanning = false;
      _scanSuccess = true;
    });
    _animationController.forward();
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF110B41), // Dark blue
              Color(0xFF1D1758), // Lighter dark blue
            ],
            stops: [0.03, 0.98],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Camera background simulation
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.3),
              ),
              
              // QR Scanner viewfinder
              Center(
                child: Container(
                  width: 305,
                  height: 360,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF333333),
                        blurRadius: 25,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      color: Colors.white,
                      child: Stack(
                        children: [
                          // QR Code placeholder
                          Center(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CustomPaint(
                                painter: QRCodePainter(),
                              ),
                            ),
                          ),
                          
                          // Scanning line animation
                          if (_isScanning)
                            AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Positioned(
                                  top: 50 + (_scaleAnimation.value * 260),
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          const Color(0xFF2196F3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          
                          // Corner indicators
                          _buildCornerIndicators(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Success checkmark
              if (_scanSuccess)
                Positioned(
                  top: 78,
                  right: 16,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 71,
                      height: 71,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              
              // Success message
              if (_scanSuccess)
                Positioned(
                  bottom: 215,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _scaleAnimation
        
                  ),
                ),
              
              // Back button
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 200,
                      height: 47,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8F99AD),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF2264E5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                          ),
                          BoxShadow(
                            color: const Color(0xFF2264E5).withOpacity(0.12),
                            offset: const Offset(0, 2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 17),
                          const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1E1E1E),
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Về màn hình chính',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                              letterSpacing: 0.32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerIndicators() {
    return Stack(
      children: [
        // Top-left corner
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF2196F3), width: 3),
                left: BorderSide(color: Color(0xFF2196F3), width: 3),
              ),
            ),
          ),
        ),
        // Top-right corner
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF2196F3), width: 3),
                right: BorderSide(color: Color(0xFF2196F3), width: 3),
              ),
            ),
          ),
        ),
        // Bottom-left corner
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF2196F3), width: 3),
                left: BorderSide(color: Color(0xFF2196F3), width: 3),
              ),
            ),
          ),
        ),
        // Bottom-right corner
        Positioned(
          bottom: 20,
          right: 20,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF2196F3), width: 3),
                right: BorderSide(color: Color(0xFF2196F3), width: 3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final blockSize = size.width / 21; // 21x21 QR code pattern

    // Simple QR code pattern simulation
    final qrPattern = [
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,0,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,0,1,0,1,0,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1],
      [1,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
      [0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0],
      [1,0,1,0,1,0,1,1,1,0,1,0,1,1,1,0,1,0,1,0,1],
      [0,1,0,1,0,1,0,0,0,1,0,1,0,0,0,1,0,1,0,1,0],
      [1,0,1,0,1,0,1,1,1,0,1,0,1,1,1,0,1,0,1,0,1],
      [0,1,0,1,0,1,0,0,0,1,0,1,0,0,0,1,0,1,0,1,0],
      [1,0,1,0,1,0,1,1,1,0,1,0,1,1,1,0,1,0,1,0,1],
      [0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0],
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,0,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,0,1,0,1,0,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1],
      [1,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
    ];

    for (int row = 0; row < qrPattern.length; row++) {
      for (int col = 0; col < qrPattern[row].length; col++) {
        if (qrPattern[row][col] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * blockSize,
              row * blockSize,
              blockSize,
              blockSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}