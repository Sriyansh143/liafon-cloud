import 'dart:math';
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Fitness Tracking Service - FREE local implementation
/// Supports 10+ workout modes with GPS tracking, calorie calculation, and performance metrics
class FitnessTrackingService {
  static final FitnessTrackingService _instance = FitnessTrackingService._internal();
  factory FitnessTrackingService() => _instance;
  FitnessTrackingService._internal();

  late Box<WorkoutSession> _workoutBox;
  late Box<GPSTrack> _gpsBox;
  late Box<PersonalBest> _pbBox;

  // User profile for calorie calculation
  double _userWeight = 70.0; // kg (default, should be set by user)
  double _userHeight = 170.0; // cm
  int _userAge = 30;
  bool _isMale = true;

  Future<void> init() async {
    _workoutBox = await Hive.openBox<WorkoutSession>('workout_sessions');
    _gpsBox = await Hive.openBox<GPSTrack>('gps_tracks');
    _pbBox = await Hive.openBox<PersonalBest>('personal_bests');
  }

  /// Set user profile for accurate calorie calculation
  void setUserProfile({
    required double weight,
    required double height,
    required int age,
    required bool isMale,
  }) {
    _userWeight = weight;
    _userHeight = height;
    _userAge = age;
    _isMale = isMale;
  }

  /// Start a workout session
  Future<WorkoutSession> startWorkout({
    required WorkoutType type,
    String? name,
  }) async {
    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      name: name ?? _getDefaultWorkoutName(type),
      startTime: DateTime.now(),
      status: WorkoutStatus.inProgress,
    );
    await _workoutBox.put(session.id, session);
    return session;
  }

  /// Record workout data point (heart rate, speed, etc.)
  Future<void> recordWorkoutData(String sessionId, {
    int? heartRate,
    double? speed, // km/h
    double? distance, // km
    double? calories,
    int? steps,
    double? pace, // min/km
  }) async {
    final session = _workoutBox.get(sessionId);
    if (session == null) throw Exception('Session not found');

    final updatedSession = session.copyWith(
      currentHeartRate: heartRate ?? session.currentHeartRate,
      currentSpeed: speed ?? session.currentSpeed,
      totalDistance: (session.totalDistance ?? 0) + (distance ?? 0),
      totalCalories: (session.totalCalories ?? 0) + (calories ?? 0),
      totalSteps: (session.totalSteps ?? 0) + (steps ?? 0),
      lastUpdated: DateTime.now(),
    );

    await _workoutBox.put(sessionId, updatedSession);
  }

  /// Record GPS location during outdoor workout
  Future<void> recordGPSLocation(String sessionId, LatLng location) async {
    final gpsTrack = GPSTrack(
      id: '${sessionId}_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: DateTime.now(),
    );
    await _gpsBox.put(gpsTrack.id, gpsTrack);

    // Update session with latest location
    final session = _workoutBox.get(sessionId);
    if (session != null) {
      await _workoutBox.put(sessionId, session.copyWith(
        lastLatitude: location.latitude,
        lastLongitude: location.longitude,
      ));
    }
  }

  /// End workout session and calculate final metrics
  Future<WorkoutSession> endWorkout(String sessionId) async {
    final session = _workoutBox.get(sessionId);
    if (session == null) throw Exception('Session not found');

    final endTime = DateTime.now();
    final duration = endTime.difference(session.startTime!);

    // Get all GPS tracks for this session
    final gpsTracks = _getGPSTracksForSession(sessionId);
    
    // Calculate total distance from GPS if not already tracked
    double totalDistance = session.totalDistance ?? 0.0;
    if (gpsTracks.length > 1 && session.type.isOutdoorWorkout()) {
      totalDistance = _calculateDistanceFromGPS(gpsTracks);
    }

    // Calculate calories if not provided
    double totalCalories = session.totalCalories ?? 0.0;
    if (totalCalories == 0) {
      totalCalories = _calculateCaloriesBurned(
        workoutType: session.type,
        duration: duration,
        distance: totalDistance,
        avgHeartRate: session.averageHeartRate,
      );
    }

    // Calculate average metrics
    final avgSpeed = totalDistance / (duration.inMinutes / 60); // km/h
    final avgPace = duration.inMinutes / (totalDistance > 0 ? totalDistance : 1); // min/km

    // Check for personal bests
    final newPersonalBests = await _checkPersonalBests(session.type, {
      'distance': totalDistance,
      'duration': duration.inSeconds,
      'avgPace': avgPace,
      'calories': totalCalories,
    });

    final updatedSession = session.copyWith(
      endTime: endTime,
      status: WorkoutStatus.completed,
      duration: duration,
      totalDistance: totalDistance,
      totalCalories: totalCalories,
      averageSpeed: avgSpeed,
      averagePace: avgPace,
      newPersonalBests: newPersonalBests,
    );

    await _workoutBox.put(sessionId, updatedSession);
    return updatedSession;
  }

  /// Calculate calories burned using Mifflin-St Jeor equation + MET values
  double _calculateCaloriesBurned({
    required WorkoutType workoutType,
    required Duration duration,
    required double distance,
    int? avgHeartRate,
  }) {
    // BMR calculation (Mifflin-St Jeor equation)
    double bmr;
    if (_isMale) {
      bmr = 10 * _userWeight + 6.25 * _userHeight - 5 * _userAge + 5;
    } else {
      bmr = 10 * _userWeight + 6.25 * _userHeight - 5 * _userAge - 161;
    }

    // MET (Metabolic Equivalent of Task) values for different workouts
    final metValues = {
      WorkoutType.running: 9.8,
      WorkoutType.cycling: 7.5,
      WorkoutType.walking: 3.8,
      WorkoutType.swimming: 5.8,
      WorkoutType.yoga: 2.5,
      WorkoutType.hiit: 12.0,
      WorkoutType.strengthTraining: 6.0,
      WorkoutType.dance: 5.0,
      WorkoutType.sports: 7.0,
      WorkoutType.hiking: 6.0,
    };

    final met = metValues[workoutType] ?? 5.0;
    
    // If heart rate data available, use more accurate formula
    if (avgHeartRate != null && avgHeartRate > 0) {
      // Calories per minute based on heart rate
      final caloriesPerMinute = (0.6309 * avgHeartRate + 0.09036 * _userWeight + 0.2017 * _userAge - 55.0969) / 4.184;
      return caloriesPerMinute * duration.inMinutes;
    }

    // Standard calorie calculation: MET * weight (kg) * duration (hours)
    final hours = duration.inMinutes / 60.0;
    return met * _userWeight * hours;
  }

  /// Calculate distance from GPS track using Haversine formula
  double _calculateDistanceFromGPS(List<GPSTrack> tracks) {
    if (tracks.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (var i = 1; i < tracks.length; i++) {
      final prev = tracks[i - 1];
      final curr = tracks[i];
      
      final prevPoint = LatLng(prev.latitude, prev.longitude);
      final currPoint = LatLng(curr.latitude, curr.longitude);
      
      totalDistance += _haversineDistance(prevPoint, currPoint);
    }

    return totalDistance / 1000; // Convert to km
  }

  /// Haversine formula to calculate distance between two GPS coordinates
  double _haversineDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    
    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLon = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
              cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Check and update personal bests
  Future<List<String>> _checkPersonalBests(WorkoutType type, Map<String, dynamic> metrics) async {
    final newPBs = <String>[];
    final existingPB = _pbBox.values.firstWhere(
      (pb) => pb.workoutType == type,
      orElse: () => PersonalBest(workoutType: type, records: {}),
    );

    // Check distance PB
    if (metrics['distance'] > (existingPB.records['maxDistance'] ?? 0)) {
      newPBs.add('Longest ${type.name} distance!');
      existingPB.records['maxDistance'] = metrics['distance'];
    }

    // Check duration PB
    if (metrics['duration'] > (existingPB.records['maxDuration'] ?? 0)) {
      newPBs.add('Longest ${type.name} session!');
      existingPB.records['maxDuration'] = metrics['duration'];
    }

    // Check pace PB (lower is better)
    if (metrics['avgPace'] < (existingPB.records['minPace'] ?? double.infinity)) {
      newPBs.add('Fastest ${type.name} pace!');
      existingPB.records['minPace'] = metrics['avgPace'];
    }

    // Check calories PB
    if (metrics['calories'] > (existingPB.records['maxCalories'] ?? 0)) {
      newPBs.add('Most calories burned in ${type.name}!');
      existingPB.records['maxCalories'] = metrics['calories'];
    }

    if (newPBs.isNotEmpty) {
      await _pbBox.put('${type.name}_pb', existingPB);
    }

    return newPBs;
  }

  List<GPSTrack> _getGPSTracksForSession(String sessionId) {
    return _gpsBox.values.where((t) => t.sessionId == sessionId).toList();
  }

  String _getDefaultWorkoutName(WorkoutType type) {
    final names = {
      WorkoutType.running: 'Morning Run',
      WorkoutType.cycling: 'Bike Ride',
      WorkoutType.walking: 'Walk',
      WorkoutType.swimming: 'Swim Session',
      WorkoutType.yoga: 'Yoga Practice',
      WorkoutType.hiit: 'HIIT Workout',
      WorkoutType.strengthTraining: 'Strength Training',
      WorkoutType.dance: 'Dance Session',
      WorkoutType.sports: 'Sports Activity',
      WorkoutType.hiking: 'Hiking Adventure',
      WorkoutType.other: 'Workout',
    };
    return names[type] ?? 'Workout';
  }

  /// Get workout intensity zones based on heart rate
  Map<String, dynamic> getIntensityZones(int maxHeartRate, int currentHeartRate) {
    final zones = {
      'warmup': {'min': maxHeartRate * 0.5, 'max': maxHeartRate * 0.6, 'name': 'Warm Up'},
      'fatBurn': {'min': maxHeartRate * 0.6, 'max': maxHeartRate * 0.7, 'name': 'Fat Burn'},
      'cardio': {'min': maxHeartRate * 0.7, 'max': maxHeartRate * 0.8, 'name': 'Cardio'},
      'peak': {'min': maxHeartRate * 0.8, 'max': maxHeartRate * 0.9, 'name': 'Peak'},
      'maximum': {'min': maxHeartRate * 0.9, 'max': maxHeartRate * 1.0, 'name': 'Maximum'},
    };

    String currentZone = 'unknown';
    zones.forEach((key, zone) {
      if (currentHeartRate >= zone['min'] && currentHeartRate < zone['max']) {
        currentZone = zone['name'];
      }
    });

    return {
      'zones': zones,
      'currentZone': currentZone,
      'currentHeartRate': currentHeartRate,
    };
  }

  /// Get weekly fitness summary
  Map<String, dynamic> getWeeklySummary() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final sessions = _workoutBox.values
        .where((s) => s.endTime != null && s.endTime!.isAfter(weekAgo))
        .toList();

    if (sessions.isEmpty) {
      return {'totalWorkouts': 0, 'totalCalories': 0, 'totalDuration': 0};
    }

    final totalCalories = sessions.fold<double>(0, (sum, s) => sum + (s.totalCalories ?? 0));
    final totalDuration = sessions.fold<Duration>(Duration.zero, (sum, s) => sum + (s.duration ?? Duration.zero));
    final totalDistance = sessions.fold<double>(0, (sum, s) => sum + (s.totalDistance ?? 0));

    // Group by workout type
    final byType = <WorkoutType, int>{};
    for (final session in sessions) {
      byType[session.type] = (byType[session.type] ?? 0) + 1;
    }

    return {
      'totalWorkouts': sessions.length,
      'totalCalories': totalCalories.round(),
      'totalDuration': totalDuration.inMinutes,
      'totalDistance': totalDistance,
      'byType': byType.map((k, v) => MapEntry(k.name, v)),
      'averageCaloriesPerWorkout': (totalCalories / sessions.length).round(),
    };
  }

  /// Get recovery time recommendation
  Duration getRecoveryTime(WorkoutSession session) {
    final intensityFactor = (session.totalCalories ?? 0) / 500; // Normalize to 500 cal workout
    final baseRecovery = Duration(hours: 24);
    
    // More intense workouts need more recovery
    return baseRecovery * (1 + intensityFactor * 0.5);
  }

  /// Clear all fitness data
  Future<void> clearAllData() async {
    await _workoutBox.clear();
    await _gpsBox.clear();
    await _pbBox.clear();
  }
}

// Models
enum WorkoutType {
  running,
  cycling,
  walking,
  swimming,
  yoga,
  hiit,
  strengthTraining,
  dance,
  sports,
  hiking,
  other,
}

extension WorkoutTypeExtension on WorkoutType {
  bool isOutdoorWorkout() {
    return [
      WorkoutType.running,
      WorkoutType.cycling,
      WorkoutType.walking,
      WorkoutType.hiking,
      WorkoutType.sports,
    ].contains(this);
  }
}

enum WorkoutStatus {
  inProgress,
  paused,
  completed,
  cancelled,
}

class WorkoutSession {
  final String id;
  final WorkoutType type;
  final String name;
  final DateTime? startTime;
  final DateTime? endTime;
  final WorkoutStatus status;
  final Duration? duration;
  final double? totalDistance; // km
  final double? totalCalories;
  final int? totalSteps;
  final double? averageSpeed; // km/h
  final double? averagePace; // min/km
  final int? currentHeartRate;
  final int? averageHeartRate;
  final int? maxHeartRate;
  final double? currentSpeed;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastUpdated;
  final List<String>? newPersonalBests;

  WorkoutSession({
    required this.id,
    required this.type,
    required this.name,
    this.startTime,
    this.endTime,
    this.status = WorkoutStatus.inProgress,
    this.duration,
    this.totalDistance,
    this.totalCalories,
    this.totalSteps,
    this.averageSpeed,
    this.averagePace,
    this.currentHeartRate,
    this.averageHeartRate,
    this.maxHeartRate,
    this.currentSpeed,
    this.lastLatitude,
    this.lastLongitude,
    this.lastUpdated,
    this.newPersonalBests,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.name,
      'duration': duration?.inSeconds,
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'totalSteps': totalSteps,
      'averageSpeed': averageSpeed,
      'averagePace': averagePace,
      'currentHeartRate': currentHeartRate,
      'averageHeartRate': averageHeartRate,
      'maxHeartRate': maxHeartRate,
      'newPersonalBests': newPersonalBests,
    };
  }

  WorkoutSession copyWith({
    String? id,
    WorkoutType? type,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    WorkoutStatus? status,
    Duration? duration,
    double? totalDistance,
    double? totalCalories,
    int? totalSteps,
    double? averageSpeed,
    double? averagePace,
    int? currentHeartRate,
    int? averageHeartRate,
    int? maxHeartRate,
    double? currentSpeed,
    double? lastLatitude,
    double? lastLongitude,
    DateTime? lastUpdated,
    List<String>? newPersonalBests,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      totalDistance: totalDistance ?? this.totalDistance,
      totalCalories: totalCalories ?? this.totalCalories,
      totalSteps: totalSteps ?? this.totalSteps,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      averagePace: averagePace ?? this.averagePace,
      currentHeartRate: currentHeartRate ?? this.currentHeartRate,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      newPersonalBests: newPersonalBests ?? this.newPersonalBests,
    );
  }
}

class GPSTrack {
  final String id;
  final String sessionId;
  final double latitude;
  final double longitude;
  final DateTime? timestamp;
  final double? altitude;
  final double? accuracy;

  GPSTrack({
    required this.id,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    this.timestamp,
    this.altitude,
    this.accuracy,
  });
}

class PersonalBest {
  final WorkoutType workoutType;
  final Map<String, dynamic> records;

  PersonalBest({
    required this.workoutType,
    required this.records,
  });
}
