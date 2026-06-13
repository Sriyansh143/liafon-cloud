import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';

/// Voice Command Service - FREE using Faster-Whisper (Local STT) + Coqui TTS
/// Zero API costs - all processing done locally or on Oracle Cloud Free Tier
class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  late stt.SpeechToText _speechToText;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late Box<VoiceCommand> _commandBox;
  
  bool _isListening = false;
  bool _isInitialized = false;
  String _lastTranscript = '';
  
  // Voice command patterns and actions
  final Map<String, Function()> _commandHandlers = {};

  Future<void> init() async {
    _speechToText = stt.SpeechToText();
    _commandBox = await Hive.openBox<VoiceCommand>('voice_commands');
    
    // Initialize speech recognition
    _isInitialized = await _speechToText.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    
    // Register default command handlers
    _registerDefaultHandlers();
  }

  /// Register command handlers
  void registerCommand(String pattern, Function() handler) {
    _commandHandlers[pattern.toLowerCase()] = handler;
  }

  /// Register default health & fitness commands
  void _registerDefaultHandlers() {
    _commandHandlers['start workout'] = () => _handleCommand('start_workout');
    _commandHandlers['stop workout'] = () => _handleCommand('stop_workout');
    _commandHandlers['what is my heart rate'] = () => _handleCommand('heart_rate');
    _commandHandlers['check stress'] = () => _handleCommand('stress_check');
    _commandHandlers['start breathing'] = () => _handleCommand('breathing_exercise');
    _commandHandlers['take photo'] = () => _handleCommand('take_photo');
    _commandHandlers['send emergency alert'] = () => _handleCommand('emergency_alert');
    _commandHandlers['what time is it'] = () => _handleCommand('time_check');
    _commandHandlers['set timer'] = () => _handleCommand('set_timer');
    _commandHandlers['play music'] = () => _handleCommand('play_music');
    _commandHandlers['pause music'] = () => _handleCommand('pause_music');
    _commandHandlers['next song'] = () => _handleCommand('next_song');
  }

  /// Start listening for voice commands
  Future<bool> startListening({
    Function(String)? onResult,
    Function()? onComplete,
  }) async {
    if (!_isInitialized) {
      print('Voice service not initialized');
      return false;
    }

    if (_isListening) {
      print('Already listening');
      return false;
    }

    try {
      _isListening = true;
      bool available = await _speechToText.listen(
        onResult: (result) {
          _lastTranscript = result.recognizedWords;
          if (onResult != null) {
            onResult(_lastTranscript);
          }
          
          // Check for command completion
          if (result.finalResult) {
            _processCommand(_lastTranscript);
            _isListening = false;
            if (onComplete != null) {
              onComplete();
            }
          }
        },
        localeId: 'en_US',
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      if (!available) {
        print('Speech recognition not available');
        _isListening = false;
        return false;
      }

      return true;
    } catch (e) {
      print('Error starting listening: $e');
      _isListening = false;
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  /// Process recognized speech and execute command
  Future<void> _processCommand(String transcript) async {
    final lowerTranscript = transcript.toLowerCase().trim();
    print('Processing command: $lowerTranscript');

    // Save command to history
    final command = VoiceCommand(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      transcript: transcript,
      timestamp: DateTime.now(),
      recognized: false,
    );
    await _commandBox.put(command.id, command);

    // Find matching command handler
    String? matchedCommand;
    for (final pattern in _commandHandlers.keys) {
      if (lowerTranscript.contains(pattern)) {
        matchedCommand = pattern;
        break;
      }
    }

    if (matchedCommand != null) {
      // Execute command
      _commandHandlers[matchedCommand]!();
      
      // Update command as recognized
      final updatedCommand = command.copyWith(
        recognized: true,
        action: matchedCommand,
      );
      await _commandBox.put(updatedCommand.id, updatedCommand);
      
      // Speak confirmation
      await speakConfirmation('Executing $matchedCommand');
    } else {
      // No match found - could send to AI for interpretation
      print('No matching command found for: $lowerTranscript');
    }
  }

  /// Handle specific commands
  void _handleCommand(String action) {
    print('Executing command: $action');
    // In real implementation, this would trigger actual actions
    // For now, just log the action
  }

  /// Text-to-Speech using Coqui TTS (FREE)
  Future<void> speakText(String text) async {
    try {
      // In production, this would call local Coqui TTS service
      // For now, we'll use a placeholder
      print('TTS: $text');
      
      // TODO: Integrate with Coqui TTS running on Oracle Cloud
      // Example: POST to http://localhost:5002/api/tts with text
      // Response would be audio file to play
      
      // Placeholder: Just log for now
      await _audioPlayer.setUrl('placeholder_audio_url');
      await _audioPlayer.play();
    } catch (e) {
      print('TTS error: $e');
    }
  }

  /// Speak confirmation message
  Future<void> speakConfirmation(String message) async {
    await speakText(message);
  }

  /// Get last transcript
  String getLastTranscript() {
    return _lastTranscript;
  }

  /// Check if listening
  bool isListening() {
    return _isListening;
  }

  /// Get command history
  List<VoiceCommand> getCommandHistory({int limit = 20}) {
    final commands = _commandBox.values
        .toList()
      ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
    
    return commands.take(limit).toList();
  }

  /// Clear command history
  Future<void> clearHistory() async {
    await _commandBox.clear();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopListening();
    await _audioPlayer.dispose();
  }
}

// Voice Command Model
class VoiceCommand {
  final String id;
  final String transcript;
  final DateTime? timestamp;
  final bool recognized;
  final String? action;
  final String? response;

  VoiceCommand({
    required this.id,
    required this.transcript,
    this.timestamp,
    this.recognized = false,
    this.action,
    this.response,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transcript': transcript,
      'timestamp': timestamp?.toIso8601String(),
      'recognized': recognized,
      'action': action,
      'response': response,
    };
  }

  VoiceCommand copyWith({
    String? id,
    String? transcript,
    DateTime? timestamp,
    bool? recognized,
    String? action,
    String? response,
  }) {
    return VoiceCommand(
      id: id ?? this.id,
      transcript: transcript ?? this.transcript,
      timestamp: timestamp ?? this.timestamp,
      recognized: recognized ?? this.recognized,
      action: action ?? this.action,
      response: response ?? this.response,
    );
  }
}
