import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  MobileScannerController cameraController = MobileScannerController();
  String? scannedCode;

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
  }

  void _onQRScanned(String code) {
    if (!_isScanning) return; // Prevent multiple scans
    
    setState(() {
      _isScanning = false;
      _scanSuccess = true;
      scannedCode = code;
    });
    _animationController.forward();
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Navigate to face scanner after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/face/scanner');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
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
              // Real camera view
              MobileScanner(
                controller: cameraController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _onQRScanned(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
              
              // Dark overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.5),
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
                    child: Stack(
                      children: [
                        // Transparent area to show camera
                        Container(
                          color: Colors.transparent,
                        ),
                        
                        // Corner indicators
                        _buildCornerIndicators(),
                        
                        // Scanning instruction
                        if (_isScanning)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Đặt mã QR vào khung hình',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
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
                    opacity: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        'Quét thành công!\n${scannedCode ?? ""}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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