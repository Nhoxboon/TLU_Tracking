import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum ScanStatus {
  scanning,
  success,
  failed,
}

class FaceScannerScreen extends StatefulWidget {
  const FaceScannerScreen({super.key});

  @override
  State<FaceScannerScreen> createState() => _FaceScannerScreenState();
}

class _FaceScannerScreenState extends State<FaceScannerScreen>
    with TickerProviderStateMixin {
  ScanStatus _scanStatus = ScanStatus.scanning;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  int _consecutiveFaceFrames = 0;
  int _consecutiveNoFaceFrames = 0;
  late FaceDetector _faceDetector;
  DateTime? _scanStartTime;

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

    // Initialize face detector
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.3,
      ),
    );

    // Initialize camera
    _initializeCamera();
    
    // Set scan start time
    _scanStartTime = DateTime.now();
    
    // Check for timeout after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _scanStatus == ScanStatus.scanning) {
        setState(() {
          _scanStatus = ScanStatus.failed;
        });
        _pulseController.stop();
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
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        debugPrint('Selected camera: ${frontCamera.name}');

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
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

        // Start image stream for face detection
        if (_cameraController != null &&
            !_cameraController!.value.isStreamingImages) {
          await _cameraController!.startImageStream(_processCameraImage);
        }
      } else {
        debugPrint('No cameras available');
        if (mounted) {
          setState(() {
            _scanStatus = ScanStatus.failed;
          });
          _showErrorMessage('Không tìm thấy camera trên thiết bị');
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _scanStatus = ScanStatus.failed;
        });
        _showErrorMessage('Không thể truy cập camera: $e');
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _scanStatus != ScanStatus.scanning) return;
    _isDetecting = true;

    try {
      final camera = _cameraController;
      if (camera == null || !camera.value.isInitialized) return;

      final inputImage = _inputImageFromCameraImage(image, camera.description);

      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted || _scanStatus != ScanStatus.scanning) {
        _isDetecting = false;
        return;
      }

      if (faces.isNotEmpty) {
        _consecutiveFaceFrames += 1;
        _consecutiveNoFaceFrames = 0;

        // Face detected steadily for 10 frames (about 1 second at 30fps)
        if (_consecutiveFaceFrames >= 10) {
          _consecutiveFaceFrames = 0;
          _onFaceDetectedSuccess();
        }
      } else {
        _consecutiveFaceFrames = 0;
        _consecutiveNoFaceFrames += 1;

        // If no face detected for too long, show failed state
        if (_consecutiveNoFaceFrames >= 300) { // ~10 seconds at 30fps
          if (mounted && _scanStatus == ScanStatus.scanning) {
            setState(() {
              _scanStatus = ScanStatus.failed;
            });
            _pulseController.stop();
            try {
              if (_cameraController != null &&
                  _cameraController!.value.isStreamingImages) {
                await _cameraController!.stopImageStream();
              }
            } catch (e) {
              debugPrint('Error stopping stream: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Convert sensor orientation to InputImageRotation
      InputImageRotation rotation;
      switch (camera.sensorOrientation) {
        case 0:
          rotation = InputImageRotation.rotation0deg;
          break;
        case 90:
          rotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      debugPrint('Error creating InputImage: $e');
      return null;
    }
  }

  Future<void> _onFaceDetectedSuccess() async {
    try {
      if (_cameraController != null &&
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }

    if (mounted) {
      setState(() {
        _scanStatus = ScanStatus.success;
      });
      _pulseController.stop();
      _animationController.forward();
      HapticFeedback.mediumImpact();

      // Navigate back after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, {'attendanceSuccess': true});
        }
      });
    }
  }

  void _scanAgain() {
    setState(() {
      _scanStatus = ScanStatus.scanning;
      _consecutiveFaceFrames = 0;
      _consecutiveNoFaceFrames = 0;
    });
    _scanStartTime = DateTime.now();
    _animationController.reset();
    _pulseController.repeat(reverse: true);

    // Restart camera stream if needed
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_cameraController!.value.isStreamingImages) {
      _cameraController!.startImageStream(_processCameraImage);
    } else if (!_isCameraInitialized) {
      _initializeCamera();
    }
    
    // Check for timeout after 15 seconds
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _scanStatus == ScanStatus.scanning) {
        setState(() {
          _scanStatus = ScanStatus.failed;
        });
        _pulseController.stop();
      }
    });
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    try {
      if (_cameraController != null &&
          _cameraController!.value.isStreamingImages) {
        _cameraController!.stopImageStream();
      }
    } catch (e) {
      debugPrint('Error stopping stream in dispose: $e');
    }
    _cameraController?.dispose();
    _faceDetector.close();
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
              // Camera view
              _buildCameraView(),

              // Face detection overlay
              if (_scanStatus == ScanStatus.scanning)
                _buildFaceDetectionOverlay(),

              // Success state
              if (_scanStatus == ScanStatus.success) _buildSuccessState(),

              // Status message
              _buildStatusMessage(),

              // Scan again button
              if (_scanStatus != ScanStatus.scanning) _buildScanAgainButton(),
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
          color: Colors.black.withOpacity(0.7),
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
    String message;
    Color textColor;
    List<Shadow>? shadows;

    switch (_scanStatus) {
      case ScanStatus.scanning:
        message = 'Đang quét...';
        textColor = const Color(0xFF8F99AD);
        shadows = null;
        break;
      case ScanStatus.success:
        message = 'Điểm danh thành công';
        textColor = const Color(0xFF4CAF50);
        shadows = [
          const Shadow(
            color: Color(0xFF4CAF50),
            blurRadius: 8,
          ),
        ];
        break;
      case ScanStatus.failed:
        message = 'Thất bại, vui lòng thử lại';
        textColor = Colors.red;
        shadows = null;
        break;
    }

    return Positioned(
      bottom: 230,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: textColor,
            shadows: shadows,
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

