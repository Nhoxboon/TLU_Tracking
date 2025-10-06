import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart'; // Uncomment when camera is needed

class QRScannerScreenReal extends StatefulWidget {
  const QRScannerScreenReal({super.key});

  @override
  State<QRScannerScreenReal> createState() => _QRScannerScreenRealState();
}

class _QRScannerScreenRealState extends State<QRScannerScreenReal>
    with TickerProviderStateMixin {
  // QRViewController? controller; // Uncomment when using real camera
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool _isScanning = true;
  bool _scanSuccess = false;
  late AnimationController _animationController;
  late AnimationController _scanLineController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for success state
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

    // Scan line animation
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    ));

    // Start scanning animation
    _scanLineController.repeat();

    // Simulate QR scan success after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _onQRScanned('QR_CODE_DATA');
      }
    });
  }

  void _onQRScanned(String qrData) {
    if (!_scanSuccess) {
      setState(() {
        _isScanning = false;
        _scanSuccess = true;
      });
      _scanLineController.stop();
      _animationController.forward();
      
      // Provide haptic feedback
      HapticFeedback.lightImpact();
      
      // Show success for 2 seconds then navigate back
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, {'success': true, 'data': qrData});
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scanLineController.dispose();
    // controller?.dispose(); // Uncomment when using real camera
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
              // Camera view or simulation
              _buildCameraView(),
              
              // QR Scanner overlay
              _buildScannerOverlay(),
              
              // Success checkmark
              if (_scanSuccess) _buildSuccessCheckmark(),
              
              // Success message
              if (_scanSuccess) _buildSuccessMessage(),
              
              // Back button
              _buildBackButton(),
              
              // Status bar
              _buildStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    // For now, return a simulated camera view
    // When ready to use real camera, uncomment and implement QRView
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: 305,
          height: 360,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF333333),
                blurRadius: 25,
                spreadRadius: 0,
              ),
            ],
          ),
          child: CustomPaint(
            painter: QRCodePainter(),
          ),
        ),
      ),
    );

    // Real camera implementation (uncomment when needed):
    /*
    return QRView(
      key: qrKey,
      onQRViewCreated: (QRViewController controller) {
        this.controller = controller;
        controller.scannedDataStream.listen((scanData) {
          _onQRScanned(scanData.code ?? '');
        });
      },
      overlay: QrScannerOverlayShape(
        borderColor: const Color(0xFF2196F3),
        borderRadius: 6,
        borderLength: 30,
        borderWidth: 3,
        cutOutSize: 305,
      ),
    );
    */
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 305,
        height: 360,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            // Corner indicators
            _buildCornerIndicators(),
            
            // Scanning line animation
            if (_isScanning)
              AnimatedBuilder(
                animation: _scanLineAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: 20 + (_scanLineAnimation.value * 320),
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF2196F3),
                            const Color(0xFF2196F3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerIndicators() {
    const cornerSize = 25.0;
    const cornerThickness = 3.0;
    const cornerColor = Color(0xFF2196F3);

    return Stack(
      children: [
        // Top-left corner
        Positioned(
          top: 15,
          left: 15,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: cornerThickness),
                left: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
        // Top-right corner
        Positioned(
          top: 15,
          right: 15,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: cornerThickness),
                right: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
        // Bottom-left corner
        Positioned(
          bottom: 15,
          left: 15,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: cornerThickness),
                left: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
        // Bottom-right corner
        Positioned(
          bottom: 15,
          right: 15,
          child: Container(
            width: cornerSize,
            height: cornerSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: cornerThickness),
                right: BorderSide(color: cornerColor, width: cornerThickness),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCheckmark() {
    return Positioned(
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
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4CAF50),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Positioned(
      bottom: 215,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _scaleAnimation,
        child: const Text(
          'Điểm danh thành công',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF24EB0A),
            shadows: [
              Shadow(
                color: Color(0xFF24EB0A),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
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
                const Text(
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
    );
  }

  Widget _buildStatusBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 24,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text(
                '09:30 PM',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: const [
                  Icon(Icons.bluetooth, size: 14, color: Colors.black),
                  SizedBox(width: 4),
                  Icon(Icons.wifi, size: 14, color: Colors.black),
                  SizedBox(width: 4),
                  Icon(Icons.signal_cellular_4_bar, size: 14, color: Colors.black),
                  SizedBox(width: 4),
                  Icon(Icons.battery_full, size: 14, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
      ),
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