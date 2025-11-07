import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_recognition_service.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  CameraController? _controller;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(enableContours: true, enableLandmarks: true),
  );
  final FaceRecognitionService _faceService = FaceRecognitionService();
  
  bool _isDetecting = false;
  int _capturedCount = 0;
  bool _isRegistering = false;
  String _status = 'Hướng mặt vào camera';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    
    _controller = CameraController(camera, ResolutionPreset.medium);
    await _controller!.initialize();
    _controller!.startImageStream(_processCameraImage);
    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || _isRegistering) return;
    _isDetecting = true;

    try {
      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isNotEmpty && _capturedCount < 1) {
        print('👤 Face detected! Capturing image');
        await _captureAndUpload();
      }
    } catch (e) {
      print('Error processing image: $e');
    }

    _isDetecting = false;
  }

  Future<void> _captureAndUpload() async {
    if (_isRegistering) return;
    
    setState(() {
      _isRegistering = true;
      _status = 'Đang chụp ảnh...';
    });

    try {
      final XFile imageFile = await _controller!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      final bool isPrimary = true; // Always primary since we only upload one image
      print('📤 Uploading face image, isPrimary: $isPrimary');
      
      final result = await _faceService.uploadFaceTemplate(
        imageBytes, 
        1, // Replace with actual student ID
        isPrimary: isPrimary,
      );

      if (result != null && result.success) {
        _capturedCount++;
        print('✅ Upload successful: ${result.message}');
        setState(() {
          _status = 'Đăng ký thành công!';
        });

        // Show success and return immediately after one upload
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký khuôn mặt thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ Upload failed: ${result?.message}');
        setState(() {
          _status = 'Lỗi: ${result?.message ?? 'Không thể lưu ảnh'}';
        });
      }
    } catch (e) {
      print('❌ Capture error: $e');
      setState(() {
        _status = 'Lỗi chụp ảnh: $e';
      });
    }

    setState(() => _isRegistering = false);
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = <int>[];
    for (final plane in planes) {
      allBytes.addAll(plane.bytes);
    }
    return Uint8List.fromList(allBytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký khuôn mặt')),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _status,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _capturedCount / 1),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isRegistering ? null : () => _captureAndUpload(),
                    child: const Text('Chụp ảnh'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }
}
