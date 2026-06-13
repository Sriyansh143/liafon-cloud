import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_models.dart';

/// Emergency Service - FREE implementation using WhatsApp & Local PDF
/// Zero-cost alternative to Twilio/SMS APIs
class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  bool _isMonitoring = false;
  Timer? _fallDetectionTimer;
  Timer? _locationUpdateTimer;
  
  // Emergency state
  bool _emergencyActive = false;
  DateTime? _emergencyTriggeredAt;
  Position? _lastKnownLocation;
  List<EmergencyContact> _emergencyContacts = [];
  
  // Secret password for silent trigger
  String? _secretPassword;

  bool get isMonitoring => _isMonitoring;
  bool get isEmergencyActive => _emergencyActive;
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;

  /// Configure emergency contacts
  void setEmergencyContacts(List<EmergencyContact> contacts) {
    _emergencyContacts = contacts..sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Set secret password for silent emergency trigger
  void setSecretPassword(String password) {
    _secretPassword = password;
  }

  /// Check if input matches secret password
  bool checkSecretPassword(String input) {
    return _secretPassword != null && input == _secretPassword;
  }

  /// Start fall/unconscious detection monitoring
  void startFallDetection() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    debugPrint('🚨 Fall detection monitoring started');
    
    // In real implementation, this would use accelerometer/gyroscope data
    // from the watch via Bluetooth LE
    _fallDetectionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        // Placeholder for actual fall detection logic
        // This would analyze sensor data from the watch
        _analyzeMotionData();
      },
    );
  }

  /// Stop fall detection monitoring
  void stopFallDetection() {
    _isMonitoring = false;
    _fallDetectionTimer?.cancel();
    _fallDetectionTimer = null;
    debugPrint('Fall detection monitoring stopped');
  }

  /// Analyze motion data for fall detection (placeholder)
  void _analyzeMotionData() {
    // TODO: Integrate with watch sensors via Bluetooth
    // This would detect sudden acceleration changes indicative of a fall
  }

  /// Trigger emergency manually or automatically
  Future<void> triggerEmergency({
    bool isAutomatic = false,
    String? reason,
  }) async {
    if (_emergencyActive) {
      debugPrint('Emergency already active');
      return;
    }

    _emergencyActive = true;
    _emergencyTriggeredAt = DateTime.now();
    
    debugPrint('🚨 EMERGENCY TRIGGERED: ${isAutomatic ? 'Automatic ($reason)' : 'Manual'}');

    try {
      // 1. Get current location
      await _getCurrentLocation();

      // 2. Generate health report PDF
      final pdfPath = await _generateHealthReportPDF();

      // 3. Send alerts to all emergency contacts via WhatsApp
      await _sendWhatsAppAlerts(isAutomatic: isAutomatic, reason: reason);

      // 4. Share PDF if possible
      if (pdfPath != null) {
        await _shareHealthReport(pdfPath);
      }

      // 5. Log emergency event
      _logEmergencyEvent(isAutomatic: isAutomatic, reason: reason);

    } catch (e) {
      debugPrint('Error during emergency trigger: $e');
    }
  }

  /// Cancel emergency (user is safe)
  void cancelEmergency() {
    _emergencyActive = false;
    _locationUpdateTimer?.cancel();
    debugPrint('✅ Emergency cancelled - User is safe');
  }

  /// Get current location with high accuracy
  Future<Position?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions denied');
          return _lastKnownLocation;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied');
        return _lastKnownLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _lastKnownLocation = position;
      debugPrint('📍 Location: ${position.latitude}, ${position.longitude}');
      
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Return last known location
      return _lastKnownLocation;
    }
  }

  /// Generate health report PDF (FREE using pdf package)
  Future<String?> _generateHealthReportPDF() async {
    try {
      final pdf = pw.Document();
      
      // Get app directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/health_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('🏥 EMERGENCY HEALTH REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                pw.Text('Generated: ${DateTime.now().toString()}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(),
                
                pw.Section(
                  title: pw.Text('Patient Information',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('Name: [User Name]'),
                      pw.Text('Age: [Age]'),
                      pw.Text('Blood Group: [Blood Group]'),
                      pw.Text('Allergies: [Allergies]'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),
                
                pw.Section(
                  title: pw.Text('Current Vitals',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('Heart Rate: [HR] bpm'),
                      pw.Text('SpO2: [SpO2]%'),
                      pw.Text('Temperature: [Temp]°C'),
                      pw.Text('Last Updated: ${DateTime.now()}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),
                
                if (_lastKnownLocation != null) ...[
                  pw.Section(
                    title: pw.Text('Location',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('Latitude: ${_lastKnownLocation!.latitude}'),
                        pw.Text('Longitude: ${_lastKnownLocation!.longitude}'),
                        pw.Text(
                          'Google Maps: https://www.google.com/maps?q=${_lastKnownLocation!.latitude},${_lastKnownLocation!.longitude}',
                          style: pw.TextStyle(color: PdfColors.blue),
                        ),
                      ],
                    ),
                  ),
                ],
                
                pw.SizedBox(height: 15),
                
                pw.Section(
                  title: pw.Text('Emergency Contacts',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  child: pw.Column(
                    children: _emergencyContacts.map((contact) {
                      return pw.Text('${contact.name} (${contact.relationship}): ${contact.phoneNumber}');
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      debugPrint('📄 Health report PDF generated: $filePath');
      return filePath;
      
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      return null;
    }
  }

  /// Send WhatsApp alerts to emergency contacts (FREE)
  Future<void> _sendWhatsAppAlerts({
    bool isAutomatic = false,
    String? reason,
  }) async {
    if (_emergencyContacts.isEmpty) {
      debugPrint('No emergency contacts configured');
      return;
    }

    final locationText = _lastKnownLocation != null
        ? '📍 Location: https://www.google.com/maps?q=${_lastKnownLocation!.latitude},${_lastKnownLocation!.longitude}'
        : '📍 Location: Unable to get current location';

    final alertMessage = '''
🚨 *EMERGENCY ALERT* 🚨

${isAutomatic ? '⚠️ Automatic Detection: $reason' : '🆘 Manual Emergency Trigger'}

Time: ${DateTime.now().toString()}

$locationText

⚕️ Please check on the user immediately!

Sent via Liafon Cloud Smartwatch
''';

    // Send to each contact via WhatsApp
    for (final contact in _emergencyContacts) {
      try {
        final whatsappNumber = contact.whatsappNumber ?? contact.phoneNumber;
        final encodedMessage = Uri.encodeComponent(alertMessage);
        final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';
        
        debugPrint('Sending WhatsApp alert to: ${contact.name} ($whatsappNumber)');
        
        if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
          // Note: This opens WhatsApp with pre-filled message
          // User needs to press send (free method without API)
          await launchUrl(
            Uri.parse(whatsappUrl),
            mode: LaunchMode.externalApplication,
          );
          
          // Small delay between messages
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        debugPrint('Error sending WhatsApp to ${contact.name}: $e');
      }
    }
  }

  /// Share health report PDF
  Future<void> _shareHealthReport(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(pdfPath)],
          subject: 'Emergency Health Report',
        );
      }
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }

  /// Log emergency event (for audit trail)
  void _logEmergencyEvent({
    bool isAutomatic = false,
    String? reason,
  }) {
    // In production, save to local database or sync to server
    final logEntry = {
      'timestamp': _emergencyTriggeredAt?.toIso8601String(),
      'type': isAutomatic ? 'automatic' : 'manual',
      'reason': reason,
      'location': _lastKnownLocation != null
          ? {
              'latitude': _lastKnownLocation!.latitude,
              'longitude': _lastKnownLocation!.longitude,
            }
          : null,
      'contacts_notified': _emergencyContacts.length,
    };
    
    debugPrint('📝 Emergency logged: $logEntry');
  }

  /// Test emergency alert (sends dummy alert to verify setup)
  Future<void> testEmergencyAlert(EmergencyContact contact) async {
    final testMessage = '''
🧪 *TEST ALERT* 🧪

This is a test emergency alert from Liafon Cloud.

Your emergency contact setup is working correctly!

Time: ${DateTime.now()}
''';

    try {
      final whatsappNumber = contact.whatsappNumber ?? contact.phoneNumber;
      final encodedMessage = Uri.encodeComponent(testMessage);
      final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$encodedMessage';
      
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Error sending test alert: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    stopFallDetection();
    _locationUpdateTimer?.cancel();
    _emergencyActive = false;
  }
}
