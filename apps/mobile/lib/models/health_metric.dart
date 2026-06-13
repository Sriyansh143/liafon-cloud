import 'package:flutter/foundation.dart';

/// Comprehensive health metric model supporting all vital signs
class HealthMetric {
  final String id;
  final HealthMetricType type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String? source; // watch, phone, manual
  final Map<String, dynamic>? metadata;
  final int? qualityScore; // 0-100 data quality

  const HealthMetric({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.source,
    this.metadata,
    this.qualityScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'metadata': metadata,
      'quality_score': qualityScore,
    };
  }

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: HealthMetricType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HealthMetricType.unknown,
      ),
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      source: json['source'],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
      qualityScore: json['quality_score'],
    );
  }

  HealthMetric copyWith({
    String? id,
    HealthMetricType? type,
    double? value,
    String? unit,
    DateTime? timestamp,
    String? source,
    Map<String, dynamic>? metadata,
    int? qualityScore,
  }) {
    return HealthMetric(
      id: id ?? this.id,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      qualityScore: qualityScore ?? this.qualityScore,
    );
  }
}

/// All supported health metric types
enum HealthMetricType {
  heartRate,
  heartRateVariability,
  bloodOxygen,
  bodyTemperature,
  respiratoryRate,
  bloodPressureSystolic,
  bloodPressureDiastolic,
  steps,
  distance,
  calories,
  activeMinutes,
  floorsClimbed,
  sleepTotal,
  sleepDeep,
  sleepLight,
  sleepREM,
  sleepAwake,
  stressLevel,
  vo2Max,
  hydration,
  glucose,
  ecg,
  unknown,
}

extension HealthMetricTypeExtension on HealthMetricType {
  String get displayName {
    switch (this) {
      case HealthMetricType.heartRate:
        return 'Heart Rate';
      case HealthMetricType.heartRateVariability:
        return 'HRV';
      case HealthMetricType.bloodOxygen:
        return 'Blood Oxygen';
      case HealthMetricType.bodyTemperature:
        return 'Body Temp';
      case HealthMetricType.respiratoryRate:
        return 'Respiratory Rate';
      case HealthMetricType.bloodPressureSystolic:
        return 'BP Systolic';
      case HealthMetricType.bloodPressureDiastolic:
        return 'BP Diastolic';
      case HealthMetricType.steps:
        return 'Steps';
      case HealthMetricType.distance:
        return 'Distance';
      case HealthMetricType.calories:
        return 'Calories';
      case HealthMetricType.activeMinutes:
        return 'Active Minutes';
      case HealthMetricType.floorsClimbed:
        return 'Floors';
      case HealthMetricType.sleepTotal:
        return 'Sleep';
      case HealthMetricType.sleepDeep:
        return 'Deep Sleep';
      case HealthMetricType.sleepLight:
        return 'Light Sleep';
      case HealthMetricType.sleepREM:
        return 'REM Sleep';
      case HealthMetricType.sleepAwake:
        return 'Awake Time';
      case HealthMetricType.stressLevel:
        return 'Stress';
      case HealthMetricType.vo2Max:
        return 'VO2 Max';
      case HealthMetricType.hydration:
        return 'Hydration';
      case HealthMetricType.glucose:
        return 'Glucose';
      case HealthMetricType.ecg:
        return 'ECG';
      case HealthMetricType.unknown:
        return 'Unknown';
    }
  }

  String get unit {
    switch (this) {
      case HealthMetricType.heartRate:
      case HealthMetricType.respiratoryRate:
        return 'bpm';
      case HealthMetricType.heartRateVariability:
        return 'ms';
      case HealthMetricType.bloodOxygen:
        return '%';
      case HealthMetricType.bodyTemperature:
        return '°C';
      case HealthMetricType.bloodPressureSystolic:
      case HealthMetricType.bloodPressureDiastolic:
        return 'mmHg';
      case HealthMetricType.steps:
        return 'steps';
      case HealthMetricType.distance:
        return 'km';
      case HealthMetricType.calories:
        return 'kcal';
      case HealthMetricType.activeMinutes:
        return 'min';
      case HealthMetricType.floorsClimbed:
        return 'floors';
      case HealthMetricType.sleepTotal:
      case HealthMetricType.sleepDeep:
      case HealthMetricType.sleepLight:
      case HealthMetricType.sleepREM:
      case HealthMetricType.sleepAwake:
        return 'hrs';
      case HealthMetricType.stressLevel:
        return 'score';
      case HealthMetricType.vo2Max:
        return 'ml/kg/min';
      case HealthMetricType.hydration:
        return 'ml';
      case HealthMetricType.glucose:
        return 'mg/dL';
      case HealthMetricType.ecg:
        return 'mV';
      default:
        return '';
    }
  }

  IconData get icon {
    switch (this) {
      case HealthMetricType.heartRate:
      case HealthMetricType.heartRateVariability:
        return Icons.favorite;
      case HealthMetricType.bloodOxygen:
        return Icons.air;
      case HealthMetricType.bodyTemperature:
        return Icons.thermometer;
      case HealthMetricType.respiratoryRate:
        return Icons.lungs;
      case HealthMetricType.bloodPressureSystolic:
      case HealthMetricType.bloodPressureDiastolic:
        return Icons.bloodtype;
      case HealthMetricType.steps:
        return Icons.directions_walk;
      case HealthMetricType.distance:
        return Icons.straighten;
      case HealthMetricType.calories:
        return Icons.local_fire_department;
      case HealthMetricType.activeMinutes:
        return Icons.fitness_center;
      case HealthMetricType.floorsClimbed:
        return Icons.stairs;
      case HealthMetricType.sleepTotal:
      case HealthMetricType.sleepDeep:
      case HealthMetricType.sleepLight:
      case HealthMetricType.sleepREM:
      case HealthMetricType.sleepAwake:
        return Icons.bedtime;
      case HealthMetricType.stressLevel:
        return Icons.psychology;
      case HealthMetricType.vo2Max:
        return Icons.sports;
      case HealthMetricType.hydration:
        return Icons.water_drop;
      case HealthMetricType.glucose:
        return Icons.drop;
      case HealthMetricType.ecg:
        return Icons.monitor_heart;
      default:
        return Icons.analytics;
    }
  }

  Color get color {
    switch (this) {
      case HealthMetricType.heartRate:
      case HealthMetricType.heartRateVariability:
        return const Color(0xFFEF4444);
      case HealthMetricType.bloodOxygen:
        return const Color(0xFF3B82F6);
      case HealthMetricType.bodyTemperature:
        return const Color(0xFFF59E0B);
      case HealthMetricType.respiratoryRate:
        return const Color(0xFF10B981);
      case HealthMetricType.bloodPressureSystolic:
      case HealthMetricType.bloodPressureDiastolic:
        return const Color(0xFF8B5CF6);
      case HealthMetricType.steps:
      case HealthMetricType.distance:
      case HealthMetricType.calories:
      case HealthMetricType.activeMinutes:
      case HealthMetricType.floorsClimbed:
        return const Color(0xFF10B981);
      case HealthMetricType.sleepTotal:
      case HealthMetricType.sleepDeep:
      case HealthMetricType.sleepLight:
      case HealthMetricType.sleepREM:
      case HealthMetricType.sleepAwake:
        return const Color(0xFF6366F1);
      case HealthMetricType.stressLevel:
        return const Color(0xFFF59E0B);
      case HealthMetricType.vo2Max:
        return const Color(0xFFEC4899);
      case HealthMetricType.hydration:
        return const Color(0xFF06B6D4);
      case HealthMetricType.glucose:
        return const Color(0xFF84CC16);
      case HealthMetricType.ecg:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

/// Sleep stage data
class SleepStage {
  final DateTime startTime;
  final DateTime endTime;
  final SleepStageType stage;
  final int durationMinutes;

  const SleepStage({
    required this.startTime,
    required this.endTime,
    required this.stage,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'stage': stage.name,
      'duration_minutes': durationMinutes,
    };
  }

  factory SleepStage.fromJson(Map<String, dynamic> json) {
    return SleepStage(
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      stage: SleepStageType.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => SleepStageType.awake,
      ),
      durationMinutes: json['duration_minutes'] ?? 0,
    );
  }
}

enum SleepStageType { deep, light, rem, awake }

/// Workout/Activity session
class WorkoutSession {
  final String id;
  final String activityType;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final double caloriesBurned;
  final double distance;
  final Map<String, dynamic> metrics; // pace, speed, elevation, etc.
  final List<HealthMetric> heartRateSamples;

  const WorkoutSession({
    required this.id,
    required this.activityType,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.caloriesBurned,
    required this.distance,
    required this.metrics,
    required this.heartRateSamples,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_type': activityType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': duration.inSeconds,
      'calories_burned': caloriesBurned,
      'distance': distance,
      'metrics': metrics,
      'heart_rate_samples': heartRateSamples.map((s) => s.toJson()).toList(),
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      activityType: json['activity_type'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      duration: Duration(seconds: json['duration_seconds'] ?? 0),
      caloriesBurned: (json['calories_burned'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      metrics: json['metrics'] != null ? Map<String, dynamic>.from(json['metrics']) : {},
      heartRateSamples: (json['heart_rate_samples'] as List?)
              ?.map((s) => HealthMetric.fromJson(s))
              .toList() ??
          [],
    );
  }
}
