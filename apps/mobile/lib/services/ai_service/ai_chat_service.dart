import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

/// AI Chat Service - FREE using Ollama (Local Llama 3.1)
/// Zero API costs - runs on Oracle Cloud Free Tier or locally
class AIChatService {
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;
  AIChatService._internal();

  late Box<Conversation> _conversationBox;
  late Box<Memory> _memoryBox;
  
  String _ollamaBaseUrl = 'http://localhost:11434'; // Default Ollama URL
  String _model = 'llama3.1:8b'; // Free, open-source model
  
  // User context for personalized responses
  String _userName = 'User';
  int _userAge = 30;
  bool _isMale = true;
  Map<String, dynamic> _healthConditions = {};
  Map<String, dynamic> _preferences = {};

  Future<void> init() async {
    _conversationBox = await Hive.openBox<Conversation>('conversations');
    _memoryBox = await Hive.openBox<Memory>('memories');
  }

  /// Configure Ollama endpoint (can be local or Oracle Cloud)
  void configure({
    required String baseUrl,
    String model = 'llama3.1:8b',
  }) {
    _ollamaBaseUrl = baseUrl;
    _model = model;
  }

  /// Set user profile for personalized AI responses
  void setUserProfile({
    required String name,
    required int age,
    required bool isMale,
    Map<String, dynamic>? healthConditions,
    Map<String, dynamic>? preferences,
  }) {
    _userName = name;
    _userAge = age;
    _isMale = isMale;
    _healthConditions = healthConditions ?? {};
    _preferences = preferences ?? {};
  }

  /// Send message to AI and get response
  Future<String> sendMessage({
    required String message,
    String? conversationId,
    List<Map<String, String>>? context,
  }) async {
    final now = DateTime.now();
    
    // Create or get conversation
    final convId = conversationId ?? now.millisecondsSinceEpoch.toString();
    Conversation? conversation;
    if (conversationId != null) {
      conversation = _conversationBox.get(conversationId);
    }
    
    if (conversation == null) {
      conversation = Conversation(
        id: convId,
        startTime: now,
        messages: [],
      );
    }

    // Add user message
    final userMessage = Message(
      id: '${convId}_user_${now.millisecondsSinceEpoch}',
      role: 'user',
      content: message,
      timestamp: now,
    );
    conversation.messages.add(userMessage);

    // Build system prompt with user context
    final systemPrompt = _buildSystemPrompt();
    
    // Prepare messages for Ollama
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      if (context != null) ...context.map((c) => {'role': c['role']!, 'content': c['content']!}),
      ...conversation.messages.map((m) => {'role': m.role, 'content': m.content}),
    ];

    try {
      // Call Ollama API (FREE)
      final response = await http.post(
        Uri.parse('$_ollamaBaseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'stream': false,
          'options': {
            'temperature': 0.7,
            'top_p': 0.9,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['message']['content'] as String;

        // Add AI response to conversation
        final aiMessage = Message(
          id: '${convId}_ai_${now.millisecondsSinceEpoch}',
          role: 'assistant',
          content: aiResponse,
          timestamp: now,
        );
        conversation.messages.add(aiMessage);
        
        // Save conversation
        await _conversationBox.put(convId, conversation);

        // Extract and save memories from conversation
        await _extractMemories(message, aiResponse);

        return aiResponse;
      } else {
        throw Exception('Ollama API error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to rule-based responses if AI is unavailable
      final fallbackResponse = _getFallbackResponse(message);
      
      final aiMessage = Message(
        id: '${convId}_ai_${now.millisecondsSinceEpoch}',
        role: 'assistant',
        content: fallbackResponse,
        timestamp: now,
      );
      conversation.messages.add(aiMessage);
      await _conversationBox.put(convId, conversation);
      
      return fallbackResponse;
    }
  }

  /// Build personalized system prompt with user context
  String _buildSystemPrompt() {
    final conditions = _healthConditions.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    
    final prefs = _preferences.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    return '''
You are Liafon AI, a caring and intelligent health companion for $_userName (${_userAge}y, ${_isMale ? 'male' : 'female'}).

USER CONTEXT:
- Health Conditions: $conditions
- Preferences: $prefs
- Current time: ${DateTime.now()}

GUIDELINES:
1. Be empathetic, supportive, and non-judgmental
2. Provide evidence-based health advice
3. Always remind user to consult doctors for medical emergencies
4. Keep responses concise (2-3 sentences max for watch display)
5. Use encouraging language for fitness goals
6. Remember user preferences and refer to them naturally
7. If asked about something outside your knowledge, admit it honestly

SAFETY:
- NEVER diagnose medical conditions
- ALWAYS recommend professional help for serious symptoms
- DO NOT provide dosage recommendations for medications
''';
  }

  /// Extract memories from conversation using simple NLP rules
  Future<void> _extractMemories(String userMessage, String aiResponse) async {
    final lowerMsg = userMessage.toLowerCase();
    
    // Pattern matching for memory extraction (FREE alternative to vector DB)
    final memoryPatterns = {
      'allergy': RegExp(r'allergic to (\w+)', caseSensitive: false),
      'preference': RegExp(r'(love|like|hate|dislike) (\w+)', caseSensitive: false),
      'goal': RegExp(r'want to (lose|gain|build) (\w+)', caseSensitive: false),
      'habit': RegExp(r'(always|never|usually) (\w+)', caseSensitive: false),
    };

    for (final entry in memoryPatterns.entries) {
      final match = entry.value.firstMatch(lowerMsg);
      if (match != null) {
        final memory = Memory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          category: entry.key,
          content: match.group(0)!,
          confidence: 0.8,
          createdAt: DateTime.now(),
          verified: false,
        );
        await _memoryBox.put(memory.id, memory);
      }
    }
  }

  /// Fallback responses when AI is unavailable
  String _getFallbackResponse(String message) {
    final lowerMsg = message.toLowerCase();
    
    if (lowerMsg.contains('hello') || lowerMsg.contains('hi')) {
      return 'Hello $_userName! How can I help you today?';
    }
    if (lowerMsg.contains('stress')) {
      return 'I notice you\'re feeling stressed. Try our box breathing exercise: Inhale 4s, hold 4s, exhale 4s. Would you like to start?';
    }
    if (lowerMsg.contains('sleep')) {
      return 'Good sleep is essential! Aim for 7-9 hours. Your sleep quality score helps track improvements.';
    }
    if (lowerMsg.contains('workout') || lowerMsg.contains('exercise')) {
      return 'Great job staying active! Remember to warm up before workouts and stay hydrated.';
    }
    if (lowerMsg.contains('thank')) {
      return 'You\'re welcome! I\'m here to support your health journey.';
    }
    
    return 'That\'s interesting! Tell me more about how you\'re feeling. (AI offline - using basic responses)';
  }

  /// Get conversation history
  List<Conversation> getConversations({int limit = 10}) {
    final conversations = _conversationBox.values
        .toList()
      ..sort((a, b) => b.startTime!.compareTo(a.startTime!));
    
    return conversations.take(limit).toList();
  }

  /// Get memories by category
  List<Memory> getMemories({String? category}) {
    var memories = _memoryBox.values.toList();
    
    if (category != null) {
      memories = memories.where((m) => m.category == category).toList();
    }
    
    return memories;
  }

  /// Delete memory
  Future<void> deleteMemory(String memoryId) async {
    await _memoryBox.delete(memoryId);
  }

  /// Clear all conversations
  Future<void> clearConversations() async {
    await _conversationBox.clear();
  }

  /// Clear all memories
  Future<void> clearMemories() async {
    await _memoryBox.clear();
  }
}

// Models
class Conversation {
  final String id;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<Message> messages;

  Conversation({
    required this.id,
    this.startTime,
    this.endTime,
    List<Message>? messages,
  }) : messages = messages ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }
}

class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime? timestamp;

  Message({
    required this.id,
    required this.role,
    required this.content,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

class Memory {
  final String id;
  final String category;
  final String content;
  final double confidence;
  final DateTime? createdAt;
  final bool verified;

  Memory({
    required this.id,
    required this.category,
    required this.content,
    required this.confidence,
    this.createdAt,
    this.verified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'content': content,
      'confidence': confidence,
      'createdAt': createdAt?.toIso8601String(),
      'verified': verified,
    };
  }
}
