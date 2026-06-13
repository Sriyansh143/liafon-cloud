import 'package:flutter/material.dart';

class HealthMetric {
  final String id;
  final String type; // heart_rate, spo2, steps, sleep, etc.
  final double value;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  HealthMetric({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.metadata,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
  
  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    return HealthMetric(
      id: json['id'],
      type: json['type'],
      value: json['value'].toDouble(),
      unit: json['unit'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

class HealthProvider extends ChangeNotifier {
  // Current vitals
  int _heartRate = 0;
  int _spo2 = 0;
  double _bodyTemp = 0;
  int _steps = 0;
  double _distance = 0;
  double _calories = 0;
  
  // Sleep data
  int _sleepScore = 0;
  Duration _sleepDuration = Duration.zero;
  Duration _deepSleep = Duration.zero;
  Duration _lightSleep = Duration.zero;
  Duration _remSleep = Duration.zero;
  
  // Historical data
  List<HealthMetric> _metricsHistory = [];
  Map<String, List<HealthMetric>> _metricsByType = {};
  
  // Health score (0-100)
  int _healthScore = 0;
  
  // Getters
  int get heartRate => _heartRate;
  int get spo2 => _spo2;
  double get bodyTemp => _bodyTemp;
  int get steps => _steps;
  double get distance => _distance;
  double get calories => _calories;
  int get sleepScore => _sleepScore;
  Duration get sleepDuration => _sleepDuration;
  Duration get deepSleep => _deepSleep;
  Duration get lightSleep => _lightSleep;
  Duration get remSleep => _remSleep;
  List<HealthMetric> get metricsHistory => _metricsHistory;
  int get healthScore => _healthScore;
  
  // Update heart rate
  void updateHeartRate(int bpm) {
    _heartRate = bpm;
    _addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'heart_rate',
      value: bpm.toDouble(),
      unit: 'bpm',
      timestamp: DateTime.now(),
    ));
    _calculateHealthScore();
    notifyListeners();
  }
  
  // Update SpO2
  void updateSpo2(int percentage) {
    _spo2 = percentage;
    _addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'spo2',
      value: percentage.toDouble(),
      unit: '%',
      timestamp: DateTime.now(),
    ));
    _calculateHealthScore();
    notifyListeners();
  }
  
  // Update body temperature
  void updateBodyTemp(double temp) {
    _bodyTemp = temp;
    _addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'body_temp',
      value: temp,
      unit: '°C',
      timestamp: DateTime.now(),
    ));
    _calculateHealthScore();
    notifyListeners();
  }
  
  // Update steps
  void updateSteps(int count) {
    _steps = count;
    _addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'steps',
      value: count.toDouble(),
      unit: 'steps',
      timestamp: DateTime.now(),
    ));
    _calculateHealthScore();
    notifyListeners();
  }
  
  // Update distance
  void updateDistance(double km) {
    _distance = km;
    _addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'distance',
      value: km,
      unit: 'km',
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
  
  // Update calories
  void updateCalories(double kcal) {
    _calories = kcal;
    _addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'calories',
      value: kcal,
      unit: 'kcal',
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
  
  // Update sleep data
  void updateSleepData({
    required int score,
    required Duration totalDuration,
    required Duration deep,
    required Duration light,
    required Duration rem,
  }) {
    _sleepScore = score;
    _sleepDuration = totalDuration;
    _deepSleep = deep;
    _lightSleep = light;
    _remSleep = rem;
    
    _addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'sleep',
      value: score.toDouble(),
      unit: 'score',
      timestamp: DateTime.now(),
      metadata: {
        'total_duration': totalDuration.inMinutes,
        'deep_sleep': deep.inMinutes,
        'light_sleep': light.inMinutes,
        'rem_sleep': rem.inMinutes,
      },
    ));
    _calculateHealthScore();
    notifyListeners();
  }
  
  // Add metric to history
  void _addMetric(HealthMetric metric) {
    _metricsHistory.add(metric);
    
    if (!_metricsByType.containsKey(metric.type)) {
      _metricsByType[metric.type] = [];
    }
    _metricsByType[metric.type]!.add(metric);
    
    // Keep only last 1000 metrics in memory
    if (_metricsHistory.length > 1000) {
      _metricsHistory.removeAt(0);
    }
  }
  
  // Calculate overall health score (0-100)
  void _calculateHealthScore() {
    int score = 0;
    int factors = 0;
    
    // Heart rate scoring (normal: 60-100 bpm)
    if (_heartRate > 0) {
      if (_heartRate >= 60 && _heartRate <= 100) {
        score += 25;
      } else if (_heartRate >= 50 && _heartRate < 60 || 
                 _heartRate > 100 && _heartRate <= 110) {
        score += 15;
      } else {
        score += 5;
      }
      factors++;
    }
    
    // SpO2 scoring (normal: 95-100%)
    if (_spo2 > 0) {
      if (_spo2 >= 95) {
        score += 25;
      } else if (_spo2 >= 90) {
        score += 15;
      } else {
        score += 5;
      }
      factors++;
    }
    
    // Body temperature scoring (normal: 36.1-37.2°C)
    if (_bodyTemp > 0) {
      if (_bodyTemp >= 36.1 && _bodyTemp <= 37.2) {
        score += 25;
      } else if (_bodyTemp >= 35.5 && _bodyTemp < 36.1 || 
                 _bodyTemp > 37.2 && _bodyTemp <= 38) {
        score += 15;
      } else {
        score += 5;
      }
      factors++;
    }
    
    // Sleep score
    if (_sleepScore > 0) {
      score += (_sleepScore * 0.25).round();
      factors++;
    }
    
    // Calculate average
    _healthScore = factors > 0 ? (score / factors).round() : 0;
  }
  
  // Get metrics by type
  List<HealthMetric> getMetricsByType(String type) {
    return _metricsByType[type] ?? [];
  }
  
  // Get metrics for last N hours
  List<HealthMetric> getMetricsForLastHours(String type, int hours) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(hours: hours));
    
    return getMetricsByType(type)
        .where((m) => m.timestamp.isAfter(cutoff))
        .toList();
  }
  
  // Get today's metrics
  List<HealthMetric> getTodayMetrics(String type) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return getMetricsByType(type)
        .where((m) => m.timestamp.isAfter(startOfDay))
        .toList();
  }
  
  // Clear all data
  void clearAllData() {
    _heartRate = 0;
    _spo2 = 0;
    _bodyTemp = 0;
    _steps = 0;
    _distance = 0;
    _calories = 0;
    _sleepScore = 0;
    _sleepDuration = Duration.zero;
    _deepSleep = Duration.zero;
    _lightSleep = Duration.zero;
    _remSleep = Duration.zero;
    _metricsHistory.clear();
    _metricsByType.clear();
    _healthScore = 0;
    notifyListeners();
  }
}
