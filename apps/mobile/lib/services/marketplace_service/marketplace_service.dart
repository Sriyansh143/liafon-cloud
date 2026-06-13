import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';

/// Marketplace Service - FREE local implementation
/// Requirements posting, AI matching, and points economy
class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._internal();
  factory MarketplaceService() => _instance;
  MarketplaceService._internal();

  late Box<Requirement> _requirementBox;
  late Box<Offer> _offerBox;
  late Box<PointsTransaction> _pointsBox;
  late Box<UserSkill> _skillBox;

  int _userPoints = 0;

  Future<void> init() async {
    _requirementBox = await Hive.openBox<Requirement>('marketplace_requirements');
    _offerBox = await Hive.openBox<Offer>('marketplace_offers');
    _pointsBox = await Hive.openBox<PointsTransaction>('points_transactions');
    _skillBox = await Hive.openBox<UserSkill>('user_skills');
    
    // Load user points
    await _loadUserPoints();
  }

  Future<void> _loadUserPoints() async {
    final transactions = _pointsBox.values.toList();
    _userPoints = transactions.fold<int>(
      0,
      (sum, t) => sum + t.points,
    );
  }

  /// Post a new requirement
  Future<Requirement> postRequirement({
    required String title,
    required String description,
    required Category category,
    required int budgetMin,
    required int budgetMax,
    required Location location,
    bool isRemote = false,
    DateTime? deadline,
  }) async {
    final requirement = Requirement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user', // Replace with actual user ID
      title: title,
      description: description,
      category: category,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      location: location,
      isRemote: isRemote,
      deadline: deadline,
      status: RequirementStatus.pending,
      createdAt: DateTime.now(),
      pointsReward: _calculatePointsReward(budgetMax),
    );

    await _requirementBox.put(requirement.id, requirement);
    
    // Award points for posting
    await _awardPoints('post_requirement', 10, 'Posted requirement: $title');
    
    return requirement;
  }

  /// Calculate points reward based on budget
  int _calculatePointsReward(int budget) {
    if (budget < 1000) return 50;
    if (budget < 5000) return 150;
    if (budget < 10000) return 300;
    return 500;
  }

  /// Get all requirements with optional filtering
  List<Requirement> getRequirements({
    Category? category,
    Location? nearLocation,
    double radiusKm = 50.0,
    RequirementStatus? status,
  }) {
    var requirements = _requirementBox.values.toList();

    if (category != null) {
      requirements = requirements.where((r) => r.category == category).toList();
    }

    if (status != null) {
      requirements = requirements.where((r) => r.status == status).toList();
    }

    if (nearLocation != null) {
      requirements = requirements.where((r) {
        if (r.isRemote) return true;
        final distance = _calculateDistance(
          nearLocation.latitude,
          nearLocation.longitude,
          r.location.latitude,
          r.location.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    }

    // Sort by creation date (newest first)
    requirements.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    
    return requirements;
  }

  /// Make an offer on a requirement
  Future<Offer> makeOffer({
    required String requirementId,
    required String message,
    required int proposedBudget,
  }) async {
    final requirement = _requirementBox.get(requirementId);
    if (requirement == null) {
      throw Exception('Requirement not found');
    }

    final offer = Offer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      requirementId: requirementId,
      userId: 'current_user',
      message: message,
      proposedBudget: proposedBudget,
      status: OfferStatus.pending,
      createdAt: DateTime.now(),
    );

    await _offerBox.put(offer.id, offer);
    return offer;
  }

  /// AI-powered matching (FREE rule-based alternative to ML)
  List<Requirement> matchRequirements({
    required List<String> userSkills,
    Location? userLocation,
  }) {
    final requirements = getRequirements(status: RequirementStatus.pending);
    final matches = <Requirement>[];

    for (final req in requirements) {
      final score = _calculateMatchScore(req, userSkills, userLocation);
      if (score >= 70) { // High match threshold
        matches.add(req);
      }
    }

    // Sort by match score
    matches.sort((a, b) {
      final scoreA = _calculateMatchScore(a, userSkills, userLocation);
      final scoreB = _calculateMatchScore(b, userSkills, userLocation);
      return scoreB.compareTo(scoreA);
    });

    return matches;
  }

  /// Calculate match score (0-100)
  int _calculateMatchScore(
    Requirement req,
    List<String> userSkills,
    Location? userLocation,
  ) {
    int score = 0;

    // Skill match (50 points)
    final categorySkillMap = {
      Category.plumber: ['plumbing', 'repair', 'maintenance'],
      Category.electrician: ['electrical', 'wiring', 'electronics'],
      Category.tutor: ['teaching', 'tutoring', 'education'],
      Category.doctor: ['medical', 'healthcare', 'doctor'],
      Category.lawyer: ['legal', 'law', 'attorney'],
      Category.designer: ['design', 'graphic', 'ui/ux'],
      Category.programmer: ['programming', 'software', 'development'],
      Category.chef: ['cooking', 'chef', 'culinary'],
      Category.trainer: ['fitness', 'training', 'coaching'],
    };

    final relevantSkills = categorySkillMap[req.category] ?? [];
    final matchedSkills = userSkills.where(
      (skill) => relevantSkills.any((s) => s.contains(skill) || skill.contains(s)),
    ).length;

    if (matchedSkills > 0) {
      score += (matchedSkills / relevantSkills.length * 50).round();
    }

    // Location match (30 points)
    if (req.isRemote) {
      score += 30;
    } else if (userLocation != null) {
      final distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        req.location.latitude,
        req.location.longitude,
      );
      if (distance < 5) {
        score += 30;
      } else if (distance < 20) {
        score += 20;
      } else if (distance < 50) {
        score += 10;
      }
    }

    // Budget compatibility (20 points)
    // Simplified: assume user can handle any budget
    score += 20;

    return score.clamp(0, 100);
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
              sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Award points to user
  Future<void> _awardPoints(String type, int points, String description) async {
    final transaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      points: points,
      description: description,
      timestamp: DateTime.now(),
    );
    
    await _pointsBox.put(transaction.id, transaction);
    _userPoints += points;
  }

  /// Spend points
  Future<bool> spendPoints({
    required int amount,
    required String reason,
  }) async {
    if (_userPoints < amount) {
      return false;
    }

    final transaction = PointsTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'spend',
      points: -amount,
      description: reason,
      timestamp: DateTime.now(),
    );
    
    await _pointsBox.put(transaction.id, transaction);
    _userPoints -= amount;
    return true;
  }

  /// Get user points balance
  int getUserPoints() {
    return _userPoints;
  }

  /// Get points transaction history
  List<PointsTransaction> getPointsHistory({int limit = 50}) {
    final transactions = _pointsBox.values
        .toList()
      ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
    
    return transactions.take(limit).toList();
  }

  /// Add user skill
  Future<void> addSkill(String skill) async {
    final userSkill = UserSkill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      skill: skill,
      verified: false,
      addedAt: DateTime.now(),
    );
    await _skillBox.put(userSkill.id, userSkill);
  }

  /// Get user skills
  List<String> getUserSkills() {
    return _skillBox.values.map((s) => s.skill).toList();
  }

  /// Accept offer
  Future<void> acceptOffer(String offerId) async {
    final offer = _offerBox.get(offerId);
    if (offer == null) throw Exception('Offer not found');
    
    final updatedOffer = offer.copyWith(status: OfferStatus.accepted);
    await _offerBox.put(offerId, updatedOffer);
    
    // Update requirement status
    final requirement = _requirementBox.get(offer.requirementId);
    if (requirement != null) {
      final updatedReq = requirement.copyWith(status: RequirementStatus.inProgress);
      await _requirementBox.put(requirement.id, updatedReq);
    }
  }

  /// Complete requirement
  Future<void> completeRequirement(String requirementId) async {
    final requirement = _requirementBox.get(requirementId);
    if (requirement == null) throw Exception('Requirement not found');
    
    final updatedReq = requirement.copyWith(status: RequirementStatus.completed);
    await _requirementBox.put(requirementId, updatedReq);
    
    // Award points to fulfiller
    await _awardPoints(
      'fulfill_requirement',
      requirement.pointsReward,
      'Completed requirement: ${requirement.title}',
    );
  }

  /// Clear all data
  Future<void> clearAllData() async {
    await _requirementBox.clear();
    await _offerBox.clear();
    await _pointsBox.clear();
    await _skillBox.clear();
  }
}

// Models
enum Category {
  plumber,
  electrician,
  tutor,
  doctor,
  lawyer,
  designer,
  programmer,
  chef,
  trainer,
  other,
}

enum RequirementStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

enum OfferStatus {
  pending,
  accepted,
  rejected,
  withdrawn,
}

class Requirement {
  final String id;
  final String userId;
  final String title;
  final String description;
  final Category category;
  final int budgetMin;
  final int budgetMax;
  final Location location;
  final bool isRemote;
  final DateTime? deadline;
  final RequirementStatus status;
  final int pointsReward;
  final DateTime? createdAt;

  Requirement({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.budgetMin,
    required this.budgetMax,
    required this.location,
    this.isRemote = false,
    this.deadline,
    this.status = RequirementStatus.pending,
    required this.pointsReward,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'location': {'lat': location.latitude, 'lng': location.longitude},
      'isRemote': isRemote,
      'deadline': deadline?.toIso8601String(),
      'status': status.name,
      'pointsReward': pointsReward,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Requirement copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    Category? category,
    int? budgetMin,
    int? budgetMax,
    Location? location,
    bool? isRemote,
    DateTime? deadline,
    RequirementStatus? status,
    int? pointsReward,
    DateTime? createdAt,
  }) {
    return Requirement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      location: location ?? this.location,
      isRemote: isRemote ?? this.isRemote,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      pointsReward: pointsReward ?? this.pointsReward,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Location {
  final double latitude;
  final double longitude;
  final String? address;

  Location({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class Offer {
  final String id;
  final String requirementId;
  final String userId;
  final String message;
  final int proposedBudget;
  final OfferStatus status;
  final DateTime? createdAt;

  Offer({
    required this.id,
    required this.requirementId,
    required this.userId,
    required this.message,
    required this.proposedBudget,
    this.status = OfferStatus.pending,
    this.createdAt,
  });

  Offer copyWith({
    String? id,
    String? requirementId,
    String? userId,
    String? message,
    int? proposedBudget,
    OfferStatus? status,
    DateTime? createdAt,
  }) {
    return Offer(
      id: id ?? this.id,
      requirementId: requirementId ?? this.requirementId,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      proposedBudget: proposedBudget ?? this.proposedBudget,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PointsTransaction {
  final String id;
  final String type;
  final int points;
  final String description;
  final DateTime? timestamp;

  PointsTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    this.timestamp,
  });
}

class UserSkill {
  final String id;
  final String skill;
  final bool verified;
  final DateTime? addedAt;

  UserSkill({
    required this.id,
    required this.skill,
    this.verified = false,
    this.addedAt,
  });
}
