import 'package:hive/hive.dart';
import '../models/health_metric.dart';

/// Sleep Tracking Service - FREE local implementation
/// Tracks sleep stages (Deep, Light, REM, Awake) using watch sensors
class SleepTrackingService {
  static final SleepTrackingService _instance = SleepTrackingService._internal();
  factory SleepTrackingService() => _instance;
  SleepTrackingService._internal();

  late Box<SleepSession> _sleepBox;
  late Box<SleepStage> _stagesBox;

  Future<void> init() async {
    _sleepBox = await Hive.openBox<SleepSession>('sleep_sessions');
    _stagesBox = await Hive.openBox<SleepStage>('sleep_stages');
  }

  /// Start sleep tracking session
  Future<SleepSession> startSleepSession() async {
    final session = SleepSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      status: SleepStatus.inProgress,
    );
    await _sleepBox.put(session.id, session);
    return session;
  }

  /// End sleep session and calculate metrics
  Future<SleepSession> endSleepSession(String sessionId) async {
    final session = _sleepBox.get(sessionId);
    if (session == null) throw Exception('Session not found');

    final endTime = DateTime.now();
    final stages = _getStagesForSession(sessionId);
    
    final totalDuration = endTime.difference(session.startTime!);
    final deepSleep = stages.where((s) => s.stage == SleepStageType.deep).fold(
      Duration.zero, 
      (sum, s) => sum + s.duration
    );
    final lightSleep = stages.where((s) => s.stage == SleepStageType.light).fold(
      Duration.zero, 
      (sum, s) => sum + s.duration
    );
    final remSleep = stages.where((s) => s.stage == SleepStageType.rem).fold(
      Duration.zero, 
      (sum, s) => sum + s.duration
    );
    final awakeTime = stages.where((s) => s.stage == SleepStageType.awake).fold(
      Duration.zero, 
      (sum, s) => sum + s.duration
    );

    // Calculate sleep quality score (0-100)
    final qualityScore = _calculateSleepQuality(
      totalDuration: totalDuration,
      deepSleep: deepSleep,
      lightSleep: lightSleep,
      remSleep: remSleep,
      awakeTime: awakeTime,
    );

    final updatedSession = session.copyWith(
      endTime: endTime,
      status: SleepStatus.completed,
      totalDuration: totalDuration,
      deepSleepDuration: deepSleep,
      lightSleepDuration: lightSleep,
      remSleepDuration: remSleep,
      awakeDuration: awakeTime,
      sleepQualityScore: qualityScore,
      interruptions: stages.where((s) => s.stage == SleepStageType.awake).length,
    );

    await _sleepBox.put(sessionId, updatedSession);
    return updatedSession;
  }

  /// Record sleep stage from watch sensor data
  Future<void> recordSleepStage(String sessionId, SleepStageType stage, Duration duration) async {
    final sleepStage = SleepStage(
      id: '${sessionId}_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      stage: stage,
      startTime: DateTime.now().subtract(duration),
      duration: duration,
    );
    await _stagesBox.put(sleepStage.id, sleepStage);
  }

  List<SleepStage> _getStagesForSession(String sessionId) {
    return _stagesBox.values.where((s) => s.sessionId == sessionId).toList();
  }

  /// AI-powered sleep quality calculation
  int _calculateSleepQuality({
    required Duration totalDuration,
    required Duration deepSleep,
    required Duration lightSleep,
    required Duration remSleep,
    required Duration awakeTime,
  }) {
    int score = 0;

    // Total sleep duration (ideal: 7-9 hours)
    final hours = totalDuration.inHours;
    if (hours >= 7 && hours <= 9) {
      score += 30;
    } else if (hours >= 6 && hours < 7) {
      score += 20;
    } else if (hours >= 5 && hours < 6) {
      score += 10;
    }

    // Deep sleep percentage (ideal: 13-23%)
    final deepPercentage = deepSleep.inMinutes / totalDuration.inMinutes * 100;
    if (deepPercentage >= 13 && deepPercentage <= 23) {
      score += 25;
    } else if (deepPercentage >= 10 && deepPercentage < 13) {
      score += 15;
    }

    // REM sleep percentage (ideal: 20-25%)
    final remPercentage = remSleep.inMinutes / totalDuration.inMinutes * 100;
    if (remPercentage >= 20 && remPercentage <= 25) {
      score += 25;
    } else if (remPercentage >= 15 && remPercentage < 20) {
      score += 15;
    }

    // Sleep efficiency (less awake time = better)
    final efficiency = (totalDuration.inMinutes - awakeTime.inMinutes) / totalDuration.inMinutes * 100;
    if (efficiency >= 90) {
      score += 20;
    } else if (efficiency >= 80) {
      score += 15;
    } else if (efficiency >= 70) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// Get sleep insights using simple AI rules
  List<String> getSleepInsights(SleepSession session) {
    final insights = <String>[];

    if (session.totalDuration!.inHours < 7) {
      insights.add('You slept less than 7 hours. Try to get more rest for better health.');
    }

    if (session.deepSleepDuration!.inMinutes < session.totalDuration!.inMinutes * 0.13) {
      insights.add('Your deep sleep is low. Avoid caffeine after 6 PM and maintain a cool room temperature.');
    }

    if (session.remSleepDuration!.inMinutes < session.totalDuration!.inMinutes * 0.20) {
      insights.add('REM sleep is below optimal. Reduce screen time before bed and try meditation.');
    }

    if (session.interruptions! > 5) {
      insights.add('You woke up frequently. Consider checking for noise, light, or discomfort.');
    }

    if (session.sleepQualityScore! >= 80) {
      insights.add('Excellent sleep quality! Keep maintaining your healthy sleep habits.');
    }

    return insights;
  }

  /// Get weekly sleep report
  Map<String, dynamic> getWeeklyReport() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final sessions = _sleepBox.values
        .where((s) => s.endTime != null && s.endTime!.isAfter(weekAgo))
        .toList();

    if (sessions.isEmpty) {
      return {'averageDuration': 0, 'averageQuality': 0, 'sessions': []};
    }

    final avgDuration = sessions.fold<Duration>(
      Duration.zero,
      (sum, s) => sum + s.totalDuration!
    ) ~/ sessions.length;

    final avgQuality = sessions.fold<int>(
      0,
      (sum, s) => sum + s.sleepQualityScore!
    ) ~/ sessions.length;

    return {
      'averageDuration': avgDuration.inHours,
      'averageQuality': avgQuality,
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'trend': avgQuality > 70 ? 'improving' : 'needs_attention',
    };
  }

  /// Clear all sleep data
  Future<void> clearAllData() async {
    await _sleepBox.clear();
    await _stagesBox.clear();
  }
}
