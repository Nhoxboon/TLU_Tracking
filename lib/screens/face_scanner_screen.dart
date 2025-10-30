import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

class FaceScannerScreen extends StatefulWidget {
  const FaceScannerScreen({super.key});

  @override
  State<FaceScannerScreen> createState() => _FaceScannerScreenState();
}

class _FaceScannerScreenState extends State<FaceScannerScreen>
    with TickerProviderStateMixin {
  bool _isScanning = true;
  bool _scanSuccess = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for success state
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Pulse animation for face detection
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation
    _pulseController.repeat(reverse: true);

    // Initialize camera
    _initializeCamera();

    // Simulate face scan success after 4 seconds (for demo)
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _onFaceScanned();
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      debugPrint('Available cameras: ${_cameras?.length}');
      
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use front camera for face detection
        final frontCamera = _cameras!.firstWhere(
          (camera) {
            debugPrint('Camera: ${camera.name}, Direction: ${camera.lensDirection}');
            return camera.lensDirection == CameraLensDirection.front;
          },
          orElse: () => _cameras!.first,
        );
        
        debugPrint('Selected camera: ${frontCamera.name}');
        
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,  // Changed to medium for better performance
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        await _cameraController!.initialize();
        debugPrint('Camera initialized successfully');
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        debugPrint('No cameras available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy camera trên thiết bị'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      // Show error dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể truy cập camera: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _onFaceScanned() {
    setState(() {
      _isScanning = false;
      _scanSuccess = true;
    });
    _pulseController.stop();
    _animationController.forward();
    
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    // Navigate back after success with result
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Navigate back to session detail with success result
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/session/detail', 
          (route) => route.settings.name == '/session/detail' || route.isFirst,
          arguments: {'attendanceSuccess': true}
        );
      }
    });
  }

  void _scanAgain() {
    setState(() {
      _isScanning = true;
      _scanSuccess = false;
    });
    _animationController.reset();
    _pulseController.repeat(reverse: true);
    
    // Restart camera if needed
    if (!_isCameraInitialized) {
      _initializeCamera();
    }
    
    // Simulate face scan again after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _onFaceScanned();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _cameraController?.dispose();
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
              // Camera view simulation
              _buildCameraView(),
              
              // Face detection overlay
              if (_isScanning) _buildFaceDetectionOverlay(),
              
              // Success state
              if (_scanSuccess) _buildSuccessState(),
              
              // Status message
              _buildStatusMessage(),
              
              // Scan again button
              _buildScanAgainButton(),
              
              // Status bar
              _buildStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
        ),
        child: Center(
          child: Container(
            width: double.infinity,
            height: 344,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isCameraInitialized && 
                     _cameraController != null && 
                     _cameraController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey[200]!,
                            Colors.grey[400]!,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFF2196F3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _cameraController == null 
                                ? 'Đang khởi động camera...' 
                                : 'Đang tải...',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaceDetectionOverlay() {
    return Positioned.fill(
      child: Center(
        child: Container(
          width: double.infinity,
          height: 344,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: CustomPaint(
                  painter: FaceDetectionPainter(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Positioned.fill(
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4CAF50),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 60,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Positioned(
      bottom: 230,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          _scanSuccess ? 'Nhận diện thành công!' : 'Đang quét...',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: _scanSuccess ? const Color(0xFF4CAF50) : const Color(0xFF8F99AD),
            shadows: _scanSuccess ? [
              const Shadow(
                color: Color(0xFF4CAF50),
                blurRadius: 8,
              ),
            ] : null,
          ),
        ),
      ),
    );
  }

  Widget _buildScanAgainButton() {
    return Positioned(
      bottom: 160,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _scanAgain,
          child: Container(
            width: 135,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.refresh,
                  color: Color(0xFF1E1E1E),
                  size: 20,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Quét lại',
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

class FaceDetectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final faceRect = Rect.fromCenter(
      center: center,
      width: 200,
      height: 250,
    );

    // Draw face detection rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(faceRect, const Radius.circular(20)),
      paint,
    );

    // Draw corner indicators
    final cornerLength = 25.0;
    final cornerPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Top-left corner
    canvas.drawLine(
      Offset(faceRect.left, faceRect.top + cornerLength),
      Offset(faceRect.left, faceRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(faceRect.left, faceRect.top),
      Offset(faceRect.left + cornerLength, faceRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(faceRect.right - cornerLength, faceRect.top),
      Offset(faceRect.right, faceRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(faceRect.right, faceRect.top),
      Offset(faceRect.right, faceRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(faceRect.left, faceRect.bottom - cornerLength),
      Offset(faceRect.left, faceRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(faceRect.left, faceRect.bottom),
      Offset(faceRect.left + cornerLength, faceRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(faceRect.right - cornerLength, faceRect.bottom),
      Offset(faceRect.right, faceRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(faceRect.right, faceRect.bottom - cornerLength),
      Offset(faceRect.right, faceRect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}