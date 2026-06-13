import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/app_models.dart';

/// OCR Service using FREE PaddleOCR via local server or HuggingFace
/// Zero cost alternative to Google Vision API
class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final ImagePicker _picker = ImagePicker();
  
  // Free HuggingFace Inference API (rate limited but free)
  static const String _hfApiUrl = 'https://api-inference.huggingface.co/models/paddleocr/paddleocr';
  
  // Alternative: Local PaddleOCR server endpoint
  String? _localServerUrl;

  void configureLocalServer(String url) {
    _localServerUrl = url;
  }

  /// Capture prescription image from camera
  Future<File?> capturePrescriptionImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
    return null;
  }

  /// Pick prescription image from gallery
  Future<File?> pickPrescriptionImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  /// Perform OCR on prescription image
  /// Returns extracted text with confidence score
  Future<OCRResult> extractText(File imageFile) async {
    try {
      // Use local server if available (faster, no rate limits)
      if (_localServerUrl != null) {
        return await _extractWithLocalServer(imageFile);
      }
      
      // Fallback to HuggingFace API
      return await _extractWithHuggingFace(imageFile);
    } catch (e) {
      debugPrint('OCR extraction error: $e');
      return OCRResult(text: '', confidence: 0, error: e.toString());
    }
  }

  /// Extract using local PaddleOCR server
  Future<OCRResult> _extractWithLocalServer(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_localServerUrl/ocr'),
      );
      
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OCRResult(
          text: data['text'] ?? '',
          confidence: (data['confidence'] ?? 0).toDouble(),
          structuredData: data['structured'],
        );
      } else {
        throw Exception('Local server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Local server OCR error: $e');
      rethrow;
    }
  }

  /// Extract using HuggingFace Inference API (FREE)
  Future<OCRResult> _extractWithHuggingFace(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      final response = await http.post(
        Uri.parse(_hfApiUrl),
        headers: {
          'Content-Type': 'application/octet-stream',
          // Get free token from https://huggingface.co/settings/tokens
          'Authorization': 'Bearer ${_getHFApiToken()}',
        },
        body: bytes,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Parse PaddleOCR output format
        String extractedText = '';
        double confidence = 0.85; // Default confidence
        
        if (data is List) {
          // PaddleOCR returns list of [bbox, text, confidence]
          for (var item in data) {
            if (item is List && item.length >= 3) {
              extractedText += '${item[1]}\n';
              confidence = (item[2] ?? confidence).toDouble();
            }
          }
        } else if (data is Map) {
          extractedText = data['text'] ?? data['prediction'] ?? '';
          confidence = (data['confidence'] ?? confidence).toDouble();
        }
        
        return OCRResult(
          text: extractedText.trim(),
          confidence: confidence,
        );
      } else {
        throw Exception('HuggingFace API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('HuggingFace OCR error: $e');
      rethrow;
    }
  }

  /// Parse extracted text into structured medication data
  Future<List<Medication>> parseMedications(String ocrText) async {
    // Simple regex-based parsing (can be enhanced with AI)
    final medications = <Medication>[];
    
    // Common patterns in prescriptions
    final namePattern = RegExp(r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(\d+(?:\.\d+)?\s*(?:mg|ml|g|mcg))', caseSensitive: false);
    final frequencyPattern = RegExp(r'(once|twice|thrice|every\s+\d+\s*hours?|daily|weekly|monthly|bd|tds|ods)', caseSensitive: false);
    final durationPattern = RegExp(r'for\s+(\d+)\s*(days?|weeks?|months?)', caseSensitive: false);
    
    final names = namePattern.allMatches(ocrText);
    final frequencies = frequencyPattern.allMatches(ocrText);
    final durations = durationPattern.allMatches(ocrText);
    
    for (var i = 0; i < names.length; i++) {
      final nameMatch = names.elementAt(i);
      final medName = nameMatch.group(1)?.trim() ?? '';
      final dosage = nameMatch.group(2)?.trim() ?? '';
      
      final freq = i < frequencies.length 
          ? frequencies.elementAt(i).group(0)?.trim() ?? 'As directed'
          : 'As directed';
      
      final dur = i < durations.length
          ? durations.elementAt(i).group(0)?.trim() ?? 'As advised'
          : 'As advised';
      
      medications.add(Medication(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        name: medName,
        dosage: dosage,
        frequency: freq,
        duration: dur,
        isActive: true,
        remainingDays: _parseDurationToDays(dur),
      ));
    }
    
    return medications;
  }

  int _parseDurationToDays(String duration) {
    final daysPattern = RegExp(r'(\d+)\s*days?');
    final weeksPattern = RegExp(r'(\d+)\s*weeks?');
    final monthsPattern = RegExp(r'(\d+)\s*months?');
    
    final daysMatch = daysPattern.firstMatch(duration);
    if (daysMatch != null) {
      return int.parse(daysMatch.group(1) ?? '0');
    }
    
    final weeksMatch = weeksPattern.firstMatch(duration);
    if (weeksMatch != null) {
      return int.parse(weeksMatch.group(1) ?? '0') * 7;
    }
    
    final monthsMatch = monthsPattern.firstMatch(duration);
    if (monthsMatch != null) {
      return int.parse(monthsMatch.group(1) ?? '0') * 30;
    }
    
    return 0;
  }

  String? _getHFApiToken() {
    // In production, store this securely
    // Users can get free token from https://huggingface.co/settings/tokens
    return const String.fromEnvironment('HF_API_TOKEN', defaultValue: '');
  }
}

class OCRResult {
  final String text;
  final double confidence;
  final Map<String, dynamic>? structuredData;
  final String? error;

  OCRResult({
    required this.text,
    required this.confidence,
    this.structuredData,
    this.error,
  });

  bool get isSuccess => error == null && text.isNotEmpty;
}
