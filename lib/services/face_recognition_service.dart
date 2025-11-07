import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FaceRecognitionService {
  static const String baseUrl = 'http://10.0.2.2:8006/api/v1';
  
  // Singleton pattern
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  // HTTP client
  final http.Client _client = http.Client();

  // Face Recognition API - Send image directly to backend
  Future<FaceRecognitionResult?> recognizeFace(
    Uint8List imageBytes, {
    double threshold = 0.8
  }) async {
    try {
      print('🔍 Starting face recognition with ${imageBytes.length} bytes image...');
      
      // Send image directly to backend recognition endpoint
      return await _recognizeFromImage(imageBytes, threshold);
      
    } catch (e) {
      print('❌ Error in face recognition: $e');
      return null;
    }
  }

  // Send image directly to backend for recognition
  Future<FaceRecognitionResult?> _recognizeFromImage(
    Uint8List imageBytes, 
    double threshold
  ) async {
    try {
      print('📤 Sending image to backend recognition endpoint...');
      
      // Create multipart request to send image
      final uri = Uri.parse('$baseUrl/face-templates/recognize');
      final request = http.MultipartRequest('POST', uri);
      
      // Add image file with proper MIME type
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',  // Field name expected by the API
          imageBytes,
          filename: 'face_image.jpg',
          contentType: MediaType('image', 'jpeg'), // Specify MIME type
        ),
      );
      
      // Add threshold parameter
      request.fields['threshold'] = threshold.toString();
      
      print('🌐 Sending request to: $uri');
      print('📊 Threshold: $threshold');
      
      // Send request
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📨 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Face recognition successful!');
        
        return FaceRecognitionResult(
          isRecognized: data['recognized'] ?? false,
          confidence: (data['confidence'] ?? 0.0).toDouble(),
          studentId: data['student_id']?.toString(),
          studentName: data['student_name']?.toString(),
          similarity: (data['similarity'] ?? 0.0).toDouble(),
          message: data['message']?.toString(),
        );
      } else {
        print('❌ Recognition failed with status: ${response.statusCode}');
        print('📄 Error response: ${response.body}');
        return null;
      }
      
    } catch (e) {
      print('❌ Error sending recognition request: $e');
      return null;
    }
  }

  // Face Registration API - Upload face template for student
  Future<FaceUploadResult?> uploadFaceTemplate(
    Uint8List imageBytes,
    int studentId, {
    bool isPrimary = false
  }) async {
    try {
      print('📸 Uploading face template for student $studentId (primary: $isPrimary)...');
      
      // Create multipart request to upload face template
      final uri = Uri.parse('$baseUrl/face-templates/upload').replace(
        queryParameters: {
          'student_id': studentId.toString(),
          'is_primary': isPrimary.toString(),
        },
      );
      final request = http.MultipartRequest('POST', uri);
      
      // Add image file with proper MIME type
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',  // Field name expected by the API
          imageBytes,
          filename: 'face_template.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      print('🌐 Uploading to: $uri');
      
      // Send request
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📨 Upload response status: ${response.statusCode}');
      print('📄 Upload response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Face template uploaded successfully!');
        
        return FaceUploadResult(
          success: true,
          faceTemplateId: data['id']?.toString(),
          message: data['message']?.toString() ?? 'Face template uploaded successfully',
        );
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        print('📄 Error response: ${response.body}');
        
        return FaceUploadResult(
          success: false,
          message: 'Upload failed with status ${response.statusCode}',
        );
      }
      
    } catch (e) {
      print('❌ Error uploading face template: $e');
      return FaceUploadResult(
        success: false,
        message: 'Error uploading face template: $e',
      );
    }
  }

  // Register multiple face templates for a student (3 photos: 1 primary + 2 secondary)
  Future<FaceRegistrationResult> registerStudentFaces(
    List<Uint8List> imagesList,
    int studentId
  ) async {
    try {
      print('🎯 Starting face registration for student $studentId with ${imagesList.length} images...');
      
      if (imagesList.isEmpty) {
        return FaceRegistrationResult(
          success: false,
          message: 'No images provided for registration',
          uploadedCount: 0,
        );
      }
      
      List<FaceUploadResult> results = [];
      int successCount = 0;
      
      for (int i = 0; i < imagesList.length; i++) {
        final isPrimary = i == 0; // First image is primary
        print('📷 Uploading image ${i + 1}/${imagesList.length} (primary: $isPrimary)...');
        
        final result = await uploadFaceTemplate(
          imagesList[i],
          studentId,
          isPrimary: isPrimary,
        );
        
        if (result != null) {
          results.add(result);
          if (result.success) {
            successCount++;
          }
        } else {
          results.add(FaceUploadResult(
            success: false,
            message: 'Failed to upload image ${i + 1}',
          ));
        }
        
        // Small delay between uploads
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      final success = successCount == imagesList.length;
      print(success 
        ? '✅ Face registration completed successfully! ($successCount/${imagesList.length})' 
        : '⚠️ Face registration partially completed ($successCount/${imagesList.length})');
      
      return FaceRegistrationResult(
        success: success,
        message: success 
          ? 'All face templates uploaded successfully!'
          : 'Only $successCount out of ${imagesList.length} templates uploaded successfully',
        uploadedCount: successCount,
        results: results,
      );
      
    } catch (e) {
      print('❌ Error in face registration: $e');
      return FaceRegistrationResult(
        success: false,
        message: 'Error in face registration: $e',
        uploadedCount: 0,
      );
    }
  }



  // Clean up resources
  void dispose() {
    _client.close();
    print('🧹 Face recognition service disposed');
  }
}

// Result class for face recognition
class FaceRecognitionResult {
  final bool isRecognized;
  final double confidence;
  final String? studentId;
  final String? studentName;
  final double similarity;
  final String? message;

  FaceRecognitionResult({
    required this.isRecognized,
    required this.confidence,
    this.studentId,
    this.studentName,
    required this.similarity,
    this.message,
  });

  @override
  String toString() {
    return 'FaceRecognitionResult(recognized: $isRecognized, confidence: $confidence, '
           'studentId: $studentId, studentName: $studentName, similarity: $similarity, '
           'message: $message)';
  }
}

// Result class for face upload
class FaceUploadResult {
  final bool success;
  final String? faceTemplateId;
  final String? message;

  FaceUploadResult({
    required this.success,
    this.faceTemplateId,
    this.message,
  });

  @override
  String toString() {
    return 'FaceUploadResult(success: $success, faceTemplateId: $faceTemplateId, message: $message)';
  }
}

// Result class for complete face registration process
class FaceRegistrationResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final List<FaceUploadResult>? results;

  FaceRegistrationResult({
    required this.success,
    required this.message,
    required this.uploadedCount,
    this.results,
  });

  @override
  String toString() {
    return 'FaceRegistrationResult(success: $success, message: $message, uploadedCount: $uploadedCount)';
  }
}
