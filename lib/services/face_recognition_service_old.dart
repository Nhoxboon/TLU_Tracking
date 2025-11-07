import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'facenet_service.dart';

class FaceRecognitionService {
  static const String baseUrl = 'http://10.0.2.2:8006/api/v1';
  
  // Singleton pattern
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  // HTTP client
  final http.Client _client = http.Client();

  // Face Recognition API - Generate embedding on client side and send to recognize endpoint
  Future<FaceRecognitionResult?> recognizeFace(
    Uint8List imageBytes, {
    double threshold = 0.8
  }) async {
    try {
      print('Starting face recognition with ${imageBytes.length} bytes image...');
      
      // Generate 512D face embedding on client side
      final embedding = await _extractFaceEmbedding(imageBytes);
      if (embedding == null) {
        print('Failed to generate face embedding from image');
        return null;
      }
      
      print('Successfully generated ${embedding.length}D embedding, sending to recognition endpoint...');
      
      // Send the embedding directly to recognize-vector endpoint
      return await _recognizeFromEmbedding(embedding, threshold);
      
    } catch (e) {
      print('Error in face recognition: $e');
      return null;
    }
  }

  // Extract 512D face embedding from image using real FaceNet model
  Future<List<double>?> _extractFaceEmbedding(Uint8List imageBytes) async {
    try {
      print('Generating real FaceNet 512D embedding from ${imageBytes.length} bytes image...');
      
      // Use real FaceNet model to generate embeddings
      final facenetService = FaceNetService();
      
      // Try to load FaceNet model first
      final modelLoaded = await facenetService.loadModel();
      if (!modelLoaded) {
        print('FaceNet model not available, cannot generate real embeddings');
        return null;
      }
      
      // Generate real FaceNet embedding
      final embedding = await facenetService.extractEmbedding(imageBytes);
      
      if (embedding != null) {
        print('Successfully generated real FaceNet ${embedding.length}D embedding');
        print('Embedding L2 norm: ${_calculateL2Norm(embedding)}');
        return embedding;
      } else {
        print('Failed to generate FaceNet embedding');
        return null;
      }
      
    } catch (e) {
      print('Error generating FaceNet embedding: $e');
      return null;
    }
  }
  
  // Calculate L2 norm of a vector
  double _calculateL2Norm(List<double> vector) {
    double sumSquares = 0.0;
    for (double value in vector) {
      sumSquares += value * value;
    }
    return math.sqrt(sumSquares);
  }

  // Recognize face from embedding vector
  Future<FaceRecognitionResult?> _recognizeFromEmbedding(
    List<double> faceEncoding,
    double threshold,
  ) async {
    try {
      // Create JSON request for vector recognition
      final uri = Uri.parse('$baseUrl/face-templates/recognize-vector');
      print('Face recognition URL: $uri');
      
      // Prepare request body
      final requestBody = {
        'face_encoding': faceEncoding,
        'threshold': threshold,
      };

      // Send POST request
      print('Sending HTTP request...');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Flutter-TLU-Tracking/1.0',
        },
        body: jsonEncode(requestBody),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FaceRecognitionResult.fromJson(data);
      } else {
        print('Face recognition failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in face recognition: $e');
      return null;
    }
  }

  // Cleanup method
  void dispose() {
    _client.close();
  }
}

// Face Recognition Result Model
class FaceRecognitionResult {
  final int studentId;
  final double confidence;
  final double similarityScore;
  final String message;

  FaceRecognitionResult({
    required this.studentId,
    required this.confidence,
    required this.similarityScore,
    required this.message,
  });

  factory FaceRecognitionResult.fromJson(Map<String, dynamic> json) {
    return FaceRecognitionResult(
      studentId: json['student_id'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      similarityScore: (json['similarity_score'] as num).toDouble(),
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'confidence': confidence,
      'similarity_score': similarityScore,
      'message': message,
    };
  }
}
