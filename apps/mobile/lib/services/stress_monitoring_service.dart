import 'dart:math';
import 'package:hive/hive.dart';

/// Stress Monitoring Service - FREE local implementation
/// Uses HRV (Heart Rate Variability) to calculate stress levels
class StressMonitoringService {
  static final StressMonitoringService _instance = StressMonitoringService._internal();
  factory StressMonitoringService() => _instance;
  StressMonitoringService._internal();

  late Box<StressRecord> _stressBox;
  late Box<HRVData> _hrvBox;

  Future<void> init() async {
    _stressBox = await Hive.openBox<StressRecord>('stress_records');
    _hrvBox = await Hive.openBox<HRVData>('hrv_data');
  }

  /// Record heart rate and calculate HRV-based stress level
  Future<StressRecord> recordStressLevel({
    required int heartRate,
    required List<int> rrIntervals, // R-R intervals in milliseconds
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    
    // Calculate HRV metrics from R-R intervals
    final hrvMetrics = _calculateHRVMetrics(rrIntervals);
    
    // Calculate stress score (0-100) based on HRV
    final stressScore = _calculateStressFromHRV(hrvMetrics);
    
    // Determine stress level
    final stressLevel = _getStressLevel(stressScore);
    
    final record = StressRecord(
      id: now.millisecondsSinceEpoch.toString(),
      timestamp: now,
      heartRate: heartRate,
      hrvSdnn: hrvMetrics['sdnn']!,
      hrvRmssd: hrvMetrics['rmssd']!,
      stressScore: stressScore,
      stressLevel: stressLevel,
    );
    
    await _stressBox.put(record.id, record);
    
    // Store raw HRV data for detailed analysis
    final hrvData = HRVData(
      id: '${record.id}_raw',
      stressRecordId: record.id,
      rrIntervals: rrIntervals,
      timestamp: now,
    );
    await _hrvBox.put(hrvData.id, hrvData);
    
    return record;
  }

  /// Calculate HRV metrics from R-R intervals
  Map<String, double> _calculateHRVMetrics(List<int> rrIntervals) {
    if (rrIntervals.length < 2) {
      return {'sdnn': 0.0, 'rmssd': 0.0, 'pnn50': 0.0};
    }

    // SDNN: Standard deviation of NN intervals
    final mean = rrIntervals.reduce((a, b) => a + b) / rrIntervals.length;
    final variance = rrIntervals.fold<double>(
      0.0,
      (sum, interval) => sum + pow(interval - mean, 2),
    ) / rrIntervals.length;
    final sdnn = sqrt(variance);

    // RMSSD: Root mean square of successive differences
    final successiveDiffs = <int>[];
    for (var i = 1; i < rrIntervals.length; i++) {
      successiveDiffs.add(rrIntervals[i] - rrIntervals[i - 1]);
    }
    final rmssdSquared = successiveDiffs.fold<double>(
      0.0,
      (sum, diff) => sum + pow(diff, 2),
    ) / successiveDiffs.length;
    final rmssd = sqrt(rmssdSquared);

    // pNN50: Percentage of successive RR intervals that differ by more than 50ms
    final nn50Count = successiveDiffs.where((diff) => diff.abs() > 50).length;
    final pnn50 = (nn50Count / successiveDiffs.length) * 100;

    return {
      'sdnn': sdnn,
      'rmssd': rmssd,
      'pnn50': pnn50,
    };
  }

  /// Calculate stress score from HRV metrics (0-100, higher = more stressed)
  int _calculateStressFromHRV(Map<String, double> hrvMetrics) {
    final sdnn = hrvMetrics['sdnn']!;
    final rmssd = hrvMetrics['rmssd']!;
    
    // Lower HRV = Higher stress
    // Normal SDNN: 30-50ms (relaxed), <20ms (stressed)
    // Normal RMSSD: 30-50ms (relaxed), <20ms (stressed)
    
    int stressScore = 0;
    
    // SDNN contribution (0-50 points)
    if (sdnn < 20) {
      stressScore += 50;
    } else if (sdnn < 30) {
      stressScore += 35;
    } else if (sdnn < 40) {
      stressScore += 20;
    } else if (sdnn < 50) {
      stressScore += 10;
    } else {
      stressScore += 0;
    }
    
    // RMSSD contribution (0-50 points)
    if (rmssd < 20) {
      stressScore += 50;
    } else if (rmssd < 30) {
      stressScore += 35;
    } else if (rmssd < 40) {
      stressScore += 20;
    } else if (rmssd < 50) {
      stressScore += 10;
    } else {
      stressScore += 0;
    }
    
    return stressScore.clamp(0, 100);
  }

  /// Convert stress score to stress level
  StressLevel _getStressLevel(int score) {
    if (score < 25) return StressLevel.low;
    if (score < 50) return StressLevel.moderate;
    if (score < 75) return StressLevel.high;
    return StressLevel.veryHigh;
  }

  /// Get stress insights and recommendations
  List<String> getStressInsights(StressRecord record) {
    final insights = <String>[];

    switch (record.stressLevel) {
      case StressLevel.low:
        insights.add('Your stress level is low. Great job maintaining balance!');
        break;
      case StressLevel.moderate:
        insights.add('Moderate stress detected. Consider taking short breaks throughout the day.');
        break;
      case StressLevel.high:
        insights.add('High stress detected. Try deep breathing exercises or a short walk.');
        insights.add('Your HRV is lower than normal. Consider reducing caffeine intake.');
        break;
      case StressLevel.veryHigh:
        insights.add('Very high stress alert! Take immediate action to relax.');
        insights.add('Practice 4-7-8 breathing: Inhale 4s, hold 7s, exhale 8s.');
        insights.add('Consider meditation or contacting a friend for support.');
        break;
    }

    // Heart rate correlation
    if (record.heartRate > 100 && record.stressScore > 50) {
      insights.add('Elevated heart rate correlates with stress. Rest and hydrate.');
    }

    return insights;
  }

  /// Get daily stress summary
  Map<String, dynamic> getDailySummary(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final records = _stressBox.values
        .where((r) => r.timestamp!.isAfter(startOfDay) && r.timestamp!.isBefore(endOfDay))
        .toList();

    if (records.isEmpty) {
      return {'averageStress': 0, 'maxStress': 0, 'episodes': 0};
    }

    final avgStress = records.fold<int>(0, (sum, r) => sum + r.stressScore) ~/ records.length;
    final maxStress = records.map((r) => r.stressScore).reduce(max);
    final highStressEpisodes = records.where((r) => r.stressScore >= 60).length;

    return {
      'averageStress': avgStress,
      'maxStress': maxStress,
      'episodes': highStressEpisodes,
      'records': records.map((r) => r.toMap()).toList(),
    };
  }

  /// Get weekly stress trend
  Map<String, dynamic> getWeeklyTrend() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final records = _stressBox.values
        .where((r) => r.timestamp!.isAfter(weekAgo))
        .toList();

    if (records.isEmpty) {
      return {'trend': 'insufficient_data', 'averageStress': 0};
    }

    // Group by day
    final dailyAvg = <DateTime, List<int>>{};
    for (final record in records) {
      final day = DateTime(record.timestamp!.year, record.timestamp!.month, record.timestamp!.day);
      dailyAvg.putIfAbsent(day, () => []).add(record.stressScore);
    }

    final dailyAverages = dailyAvg.entries.map((e) {
      return e.value.reduce((a, b) => a + b) / e.value.length;
    }).toList();

    final overallAvg = dailyAverages.reduce((a, b) => a + b) / dailyAverages.length;
    
    // Determine trend
    String trend;
    if (dailyAverages.length < 2) {
      trend = 'insufficient_data';
    } else {
      final firstHalf = dailyAverages.sublist(0, dailyAverages.length ~/ 2).reduce((a, b) => a + b) / (dailyAverages.length ~/ 2);
      final secondHalf = dailyAverages.sublist(dailyAverages.length ~/ 2).reduce((a, b) => a + b) / (dailyAverages.length - dailyAverages.length ~/ 2);
      
      if (secondHalf < firstHalf - 5) {
        trend = 'improving';
      } else if (secondHalf > firstHalf + 5) {
        trend = 'worsening';
      } else {
        trend = 'stable';
      }
    }

    return {
      'trend': trend,
      'averageStress': overallAvg.round(),
      'dailyAverages': dailyAverages,
    };
  }

  /// Breathing exercise guide (FREE alternative to premium apps)
  Map<String, dynamic> getBreathingExercise({String type = 'box'}) {
    switch (type) {
      case 'box':
        return {
          'name': 'Box Breathing',
          'duration': const Duration(minutes: 2),
          'steps': [
            {'action': 'inhale', 'duration': 4, 'instruction': 'Breathe in through nose for 4 seconds'},
            {'action': 'hold', 'duration': 4, 'instruction': 'Hold breath for 4 seconds'},
            {'action': 'exhale', 'duration': 4, 'instruction': 'Breathe out through mouth for 4 seconds'},
            {'action': 'hold', 'duration': 4, 'instruction': 'Hold empty lungs for 4 seconds'},
          ],
          'cycles': 8,
        };
      case '478':
        return {
          'name': '4-7-8 Relaxation',
          'duration': const Duration(minutes: 4),
          'steps': [
            {'action': 'inhale', 'duration': 4, 'instruction': 'Inhale quietly through nose for 4 seconds'},
            {'action': 'hold', 'duration': 7, 'instruction': 'Hold breath for 7 seconds'},
            {'action': 'exhale', 'duration': 8, 'instruction': 'Exhale completely through mouth for 8 seconds'},
          ],
          'cycles': 4,
        };
      default:
        return getBreathingExercise(type: 'box');
    }
  }

  /// Clear all stress data
  Future<void> clearAllData() async {
    await _stressBox.clear();
    await _hrvBox.clear();
  }
}

// Models
class StressRecord {
  final String id;
  final DateTime? timestamp;
  final int heartRate;
  final double hrvSdnn;
  final double hrvRmssd;
  final int stressScore;
  final StressLevel stressLevel;

  StressRecord({
    required this.id,
    this.timestamp,
    required this.heartRate,
    required this.hrvSdnn,
    required this.hrvRmssd,
    required this.stressScore,
    required this.stressLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp?.toIso8601String(),
      'heartRate': heartRate,
      'hrvSdnn': hrvSdnn,
      'hrvRmssd': hrvRmssd,
      'stressScore': stressScore,
      'stressLevel': stressLevel.name,
    };
  }

  StressRecord copyWith({
    String? id,
    DateTime? timestamp,
    int? heartRate,
    double? hrvSdnn,
    double? hrvRmssd,
    int? stressScore,
    StressLevel? stressLevel,
  }) {
    return StressRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      heartRate: heartRate ?? this.heartRate,
      hrvSdnn: hrvSdnn ?? this.hrvSdnn,
      hrvRmssd: hrvRmssd ?? this.hrvRmssd,
      stressScore: stressScore ?? this.stressScore,
      stressLevel: stressLevel ?? this.stressLevel,
    );
  }
}

class HRVData {
  final String id;
  final String stressRecordId;
  final List<int> rrIntervals;
  final DateTime? timestamp;

  HRVData({
    required this.id,
    required this.stressRecordId,
    required this.rrIntervals,
    this.timestamp,
  });
}

enum StressLevel {
  low,      // 0-24
  moderate, // 25-49
  high,     // 50-74
  veryHigh, // 75-100
}
