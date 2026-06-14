import 'dart:async';
import 'dart:collection';
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
  
  // Historical data - Using circular buffer for O(1) operations
  static const int _maxMetrics = 1000;
  final Queue<HealthMetric> _metricsHistory = Queue(capacity: _maxMetrics);
  final Map<String, Queue<HealthMetric>> _metricsByType = {};
  
  // Health score (0-100)
  int _healthScore = 0;
  
  // Throttling for UI updates
  Timer? _notifyTimer;
  bool _pendingNotify = false;
  static const Duration _notifyThrottle = Duration(seconds: 5);
  
  // Dirty flags for selective health score calculation
  bool _heartRateDirty = false;
  bool _spo2Dirty = false;
  bool _bodyTempDirty = false;
  bool _sleepScoreDirty = false;
  
  // Cached health score components
  int _cachedHeartRateScore = 0;
  int _cachedSpo2Score = 0;
  int _cachedBodyTempScore = 0;
  int _cachedSleepScoreComponent = 0;
  
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
  List<HealthMetric> get metricsHistory => _metricsHistory.toList();
  int get healthScore => _healthScore;
  
  // Update heart rate
  void updateHeartRate(int bpm) {
    _heartRate = bpm;
    _heartRateDirty = true;
    _addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'heart_rate',
      value: bpm.toDouble(),
      unit: 'bpm',
      timestamp: DateTime.now(),
    ));
    _calculateHealthScore();
    _scheduleNotify();
  }
  
  // Update SpO2
  void updateSpo2(int percentage) {
    _spo2 = percentage;
    _spo2Dirty = true;
    _addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'spo2',
      value: percentage.toDouble(),
      unit: '%',
      timestamp: DateTime.now(),
    ));
    _calculateHealthScore();
    _scheduleNotify();
  }
  
  // Update body temperature
  void updateBodyTemp(double temp) {
    _bodyTemp = temp;
    _bodyTempDirty = true;
    _addMetric(HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'body_temp',
      value: temp,
      unit: '°C',
      timestamp: DateTime.now(),
    ));
    _calculateHealthScore();
    _scheduleNotify();
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
    _scheduleNotify();
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
    _scheduleNotify();
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
    _scheduleNotify();
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
    _sleepScoreDirty = true;
    
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
    _scheduleNotify();
  }
  
  // Schedule throttled notifyListeners call
  void _scheduleNotify() {
    _pendingNotify = true;
    
    if (_notifyTimer == null || !_notifyTimer!.isActive) {
      _notifyTimer = Timer(_notifyThrottle, () {
        if (_pendingNotify) {
          _pendingNotify = false;
          notifyListeners();
        }
      });
    }
  }
  
  // Add metric to history - O(1) operations with circular buffer
  void _addMetric(HealthMetric metric) {
    _metricsHistory.add(metric);
    
    if (!_metricsByType.containsKey(metric.type)) {
      _metricsByType[metric.type] = Queue(capacity: _maxMetrics);
    }
    _metricsByType[metric.type]!.add(metric);
    
    // Keep only last 1000 metrics per type (O(1) removal from front)
    if (_metricsHistory.length > _maxMetrics) {
      _metricsHistory.removeFirst();
    }
    
    // Also limit per-type queues
    if (_metricsByType[metric.type]!.length > _maxMetrics) {
      _metricsByType[metric.type]!.removeFirst();
    }
  }
  
  // Calculate overall health score with selective updates (dirty flag pattern)
  void _calculateHealthScore() {
    int score = 0;
    int factors = 0;
    
    // Heart rate scoring - only recalculate if dirty
    if (_heartRateDirty || _cachedHeartRateScore == 0) {
      if (_heartRate > 0) {
        if (_heartRate >= 60 && _heartRate <= 100) {
          _cachedHeartRateScore = 25;
        } else if (_heartRate >= 50 && _heartRate < 60 || 
                   _heartRate > 100 && _heartRate <= 110) {
          _cachedHeartRateScore = 15;
        } else {
          _cachedHeartRateScore = 5;
        }
      } else {
        _cachedHeartRateScore = 0;
      }
      _heartRateDirty = false;
    }
    
    if (_heartRate > 0) {
      score += _cachedHeartRateScore;
      factors++;
    }
    
    // SpO2 scoring - only recalculate if dirty
    if (_spo2Dirty || _cachedSpo2Score == 0) {
      if (_spo2 > 0) {
        if (_spo2 >= 95) {
          _cachedSpo2Score = 25;
        } else if (_spo2 >= 90) {
          _cachedSpo2Score = 15;
        } else {
          _cachedSpo2Score = 5;
        }
      } else {
        _cachedSpo2Score = 0;
      }
      _spo2Dirty = false;
    }
    
    if (_spo2 > 0) {
      score += _cachedSpo2Score;
      factors++;
    }
    
    // Body temperature scoring - only recalculate if dirty
    if (_bodyTempDirty || _cachedBodyTempScore == 0) {
      if (_bodyTemp > 0) {
        if (_bodyTemp >= 36.1 && _bodyTemp <= 37.2) {
          _cachedBodyTempScore = 25;
        } else if (_bodyTemp >= 35.5 && _bodyTemp < 36.1 || 
                   _bodyTemp > 37.2 && _bodyTemp <= 38) {
          _cachedBodyTempScore = 15;
        } else {
          _cachedBodyTempScore = 5;
        }
      } else {
        _cachedBodyTempScore = 0;
      }
      _bodyTempDirty = false;
    }
    
    if (_bodyTemp > 0) {
      score += _cachedBodyTempScore;
      factors++;
    }
    
    // Sleep score - only recalculate if dirty
    if (_sleepScoreDirty || _cachedSleepScoreComponent == 0) {
      if (_sleepScore > 0) {
        _cachedSleepScoreComponent = (_sleepScore * 0.25).round();
      } else {
        _cachedSleepScoreComponent = 0;
      }
      _sleepScoreDirty = false;
    }
    
    if (_sleepScore > 0) {
      score += _cachedSleepScoreComponent;
      factors++;
    }
    
    // Calculate average
    _healthScore = factors > 0 ? (score / factors).round() : 0;
  }
  
  // Get metrics by type - returns cached list view
  List<HealthMetric> getMetricsByType(String type) {
    final queue = _metricsByType[type];
    return queue?.toList() ?? [];
  }
  
  // Get metrics for last N hours - optimized with early exit
  List<HealthMetric> getMetricsForLastHours(String type, int hours) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(hours: hours));
    
    final metrics = getMetricsByType(type);
    if (metrics.isEmpty) return [];
    
    // Find index where we can stop (metrics are in chronological order)
    int startIndex = 0;
    for (int i = 0; i < metrics.length; i++) {
      if (metrics[i].timestamp.isAfter(cutoff)) {
        startIndex = i;
        break;
      }
      // If we're still before cutoff, continue
      if (i == metrics.length - 1) {
        // All metrics are before cutoff
        return [];
      }
    }
    
    // Return sublist (more efficient than where+toList)
    return metrics.skipWhile((m) => !m.timestamp.isAfter(cutoff)).toList();
  }
  
  // Get today's metrics - optimized version
  List<HealthMetric> getTodayMetrics(String type) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final metrics = getMetricsByType(type);
    if (metrics.isEmpty) return [];
    
    // Return sublist from first metric after startOfDay
    return metrics.skipWhile((m) => !m.timestamp.isAfter(startOfDay)).toList();
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
    
    // Reset dirty flags and caches
    _heartRateDirty = false;
    _spo2Dirty = false;
    _bodyTempDirty = false;
    _sleepScoreDirty = false;
    _cachedHeartRateScore = 0;
    _cachedSpo2Score = 0;
    _cachedBodyTempScore = 0;
    _cachedSleepScoreComponent = 0;
    
    // Cancel pending notifications
    _notifyTimer?.cancel();
    _pendingNotify = false;
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _notifyTimer?.cancel();
    super.dispose();
  }
}
