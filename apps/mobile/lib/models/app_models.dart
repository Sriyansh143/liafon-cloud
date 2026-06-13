import 'dart:async';
import 'package:flutter/foundation.dart';

/// Prescription medication extracted via OCR
class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String? instructions;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int remainingDays;
  final String? doctorName;
  final DateTime? prescribedDate;

  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.remainingDays = 0,
    this.doctorName,
    this.prescribedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'remaining_days': remainingDays,
      'doctor_name': doctorName,
      'prescribed_date': prescribedDate?.toIso8601String(),
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      instructions: json['instructions'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      remainingDays: json['remaining_days'] ?? 0,
      doctorName: json['doctor_name'],
      prescribedDate: json['prescribed_date'] != null 
          ? DateTime.parse(json['prescribed_date']) 
          : null,
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    String? duration,
    String? instructions,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? remainingDays,
    String? doctorName,
    DateTime? prescribedDate,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      remainingDays: remainingDays ?? this.remainingDays,
      doctorName: doctorName ?? this.doctorName,
      prescribedDate: prescribedDate ?? this.prescribedDate,
    );
  }
}

/// Lab test result from prescription/scan
class LabTest {
  final String id;
  final String testName;
  final double value;
  final String unit;
  final double? normalRangeMin;
  final double? normalRangeMax;
  final TestResultStatus status; // normal, high, low, critical
  final DateTime testDate;
  final String? labName;

  const LabTest({
    required this.id,
    required this.testName,
    required this.value,
    required this.unit,
    this.normalRangeMin,
    this.normalRangeMax,
    this.status = TestResultStatus.normal,
    required this.testDate,
    this.labName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'test_name': testName,
      'value': value,
      'unit': unit,
      'normal_range_min': normalRangeMin,
      'normal_range_max': normalRangeMax,
      'status': status.name,
      'test_date': testDate.toIso8601String(),
      'lab_name': labName,
    };
  }

  factory LabTest.fromJson(Map<String, dynamic> json) {
    return LabTest(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      testName: json['test_name'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      normalRangeMin: json['normal_range_min']?.toDouble(),
      normalRangeMax: json['normal_range_max']?.toDouble(),
      status: TestResultStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TestResultStatus.normal,
      ),
      testDate: json['test_date'] != null 
          ? DateTime.parse(json['test_date']) 
          : DateTime.now(),
      labName: json['lab_name'],
    );
  }
}

enum TestResultStatus { normal, high, low, critical }

/// Scanned prescription document
class Prescription {
  final String id;
  final String imageUrl;
  final String? ocrText;
  final List<Medication> medications;
  final List<LabTest> labTests;
  final String? diagnosis;
  final String? doctorName;
  final String? clinicName;
  final DateTime? consultationDate;
  final DateTime scannedDate;
  final PrescriptionSource source;
  final double confidenceScore; // OCR confidence 0-1

  const Prescription({
    required this.id,
    required this.imageUrl,
    this.ocrText,
    this.medications = const [],
    this.labTests = const [],
    this.diagnosis,
    this.doctorName,
    this.clinicName,
    this.consultationDate,
    required this.scannedDate,
    this.source = PrescriptionSource.camera,
    this.confidenceScore = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'ocr_text': ocrText,
      'medications': medications.map((m) => m.toJson()).toList(),
      'lab_tests': labTests.map((t) => t.toJson()).toList(),
      'diagnosis': diagnosis,
      'doctor_name': doctorName,
      'clinic_name': clinicName,
      'consultation_date': consultationDate?.toIso8601String(),
      'scanned_date': scannedDate.toIso8601String(),
      'source': source.name,
      'confidence_score': confidenceScore,
    };
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      imageUrl: json['image_url'] ?? '',
      ocrText: json['ocr_text'],
      medications: (json['medications'] as List?)
              ?.map((m) => Medication.fromJson(m))
              .toList() ??
          [],
      labTests: (json['lab_tests'] as List?)
              ?.map((t) => LabTest.fromJson(t))
              .toList() ??
          [],
      diagnosis: json['diagnosis'],
      doctorName: json['doctor_name'],
      clinicName: json['clinic_name'],
      consultationDate: json['consultation_date'] != null 
          ? DateTime.parse(json['consultation_date']) 
          : null,
      scannedDate: json['scanned_date'] != null 
          ? DateTime.parse(json['scanned_date']) 
          : DateTime.now(),
      source: PrescriptionSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => PrescriptionSource.camera,
      ),
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
    );
  }
}

enum PrescriptionSource { camera, gallery, pdf }

/// Emergency contact
class EmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phoneNumber;
  final String? whatsappNumber;
  final String? email;
  final int priority; // 1 = highest priority
  final bool isActive;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    this.whatsappNumber,
    this.email,
    this.priority = 1,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phone_number': phoneNumber,
      'whatsapp_number': whatsappNumber,
      'email': email,
      'priority': priority,
      'is_active': isActive,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      whatsappNumber: json['whatsapp_number'],
      email: json['email'],
      priority: json['priority'] ?? 1,
      isActive: json['is_active'] ?? true,
    );
  }
}

/// User memory for AI personalization
class Memory {
  final String id;
  final MemoryCategory category;
  final String key;
  final String value;
  final double confidenceScore; // 0-1
  final DateTime createdAt;
  final DateTime? lastAccessedAt;
  final int accessCount;
  final bool isVerified;

  const Memory({
    required this.id,
    required this.category,
    required this.key,
    required this.value,
    this.confidenceScore = 0.5,
    required this.createdAt,
    this.lastAccessedAt,
    this.accessCount = 0,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'key': key,
      'value': value,
      'confidence_score': confidenceScore,
      'created_at': createdAt.toIso8601String(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'access_count': accessCount,
      'is_verified': isVerified,
    };
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      category: MemoryCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => MemoryCategory.other,
      ),
      key: json['key'] ?? '',
      value: json['value'] ?? '',
      confidenceScore: (json['confidence_score'] ?? 0.5).toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      lastAccessedAt: json['last_accessed_at'] != null 
          ? DateTime.parse(json['last_accessed_at']) 
          : null,
      accessCount: json['access_count'] ?? 0,
      isVerified: json['is_verified'] ?? false,
    );
  }

  Memory copyWith({
    String? id,
    MemoryCategory? category,
    String? key,
    String? value,
    double? confidenceScore,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    int? accessCount,
    bool? isVerified,
  }) {
    return Memory(
      id: id ?? this.id,
      category: category ?? this.category,
      key: key ?? this.key,
      value: value ?? this.value,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      accessCount: accessCount ?? this.accessCount,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

enum MemoryCategory {
  health,
  preferences,
  interests,
  relationships,
  work,
  hobbies,
  food,
  behavior,
  location,
  other,
}

/// Marketplace requirement post
class Requirement {
  final String id;
  final String userId;
  final String title;
  final String description;
  final RequirementCategory category;
  final double budgetMin;
  final double budgetMax;
  final String location;
  final double? latitude;
  final double? longitude;
  final bool isRemote;
  final DateTime deadline;
  final int pointsReward;
  final RequirementStatus status;
  final DateTime createdAt;
  final List<String> offers; // offer IDs

  const Requirement({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.budgetMin,
    required this.budgetMax,
    required this.location,
    this.latitude,
    this.longitude,
    this.isRemote = false,
    required this.deadline,
    required this.pointsReward,
    this.status = RequirementStatus.open,
    required this.createdAt,
    this.offers = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'is_remote': isRemote,
      'deadline': deadline.toIso8601String(),
      'points_reward': pointsReward,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'offers': offers,
    };
  }

  factory Requirement.fromJson(Map<String, dynamic> json) {
    return Requirement(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: RequirementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => RequirementCategory.other,
      ),
      budgetMin: (json['budget_min'] ?? 0).toDouble(),
      budgetMax: (json['budget_max'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isRemote: json['is_remote'] ?? false,
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']) 
          : DateTime.now().add(const Duration(days: 7)),
      pointsReward: json['points_reward'] ?? 100,
      status: RequirementStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RequirementStatus.open,
      ),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      offers: (json['offers'] as List?)?.cast<String>() ?? [],
    );
  }
}

enum RequirementCategory {
  plumber,
  electrician,
  tutor,
  doctor,
  lawyer,
  designer,
  programmer,
  chef,
  trainer,
  cleaner,
  driver,
  mechanic,
  other,
}

enum RequirementStatus { open, inProgress, completed, cancelled }

/// Points transaction in economy system
class PointsTransaction {
  final String id;
  final String userId;
  final int points;
  final TransactionType type;
  final String description;
  final String? referenceId;
  final DateTime createdAt;
  final int balanceAfter;

  const PointsTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.type,
    required this.description,
    this.referenceId,
    required this.createdAt,
    required this.balanceAfter,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'type': type.name,
      'description': description,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
      'balance_after': balanceAfter,
    };
  }

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    return PointsTransaction(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['user_id'] ?? '',
      points: json['points'] ?? 0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.other,
      ),
      description: json['description'] ?? '',
      referenceId: json['reference_id'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      balanceAfter: json['balance_after'] ?? 0,
    );
  }
}

enum TransactionType {
  earn,
  spend,
  redeem,
  referral,
  healthCheck,
  prescriptionScan,
  purchase,
  goalAchieved,
  marketplace,
  other,
}

/// AI-generated deal recommendation
class Deal {
  final String id;
  final String title;
  final String description;
  final DealCategory category;
  final String merchant;
  final double discountPercent;
  final double? originalPrice;
  final double? dealPrice;
  final String affiliateLink;
  final DateTime validUntil;
  final int relevanceScore; // 0-100
  final DealInteractionStatus status;
  final DateTime createdAt;

  const Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.merchant,
    required this.discountPercent,
    this.originalPrice,
    this.dealPrice,
    required this.affiliateLink,
    required this.validUntil,
    required this.relevanceScore,
    this.status = DealInteractionStatus.shown,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'merchant': merchant,
      'discount_percent': discountPercent,
      'original_price': originalPrice,
      'deal_price': dealPrice,
      'affiliate_link': affiliateLink,
      'valid_until': validUntil.toIso8601String(),
      'relevance_score': relevanceScore,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: DealCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => DealCategory.other,
      ),
      merchant: json['merchant'] ?? '',
      discountPercent: (json['discount_percent'] ?? 0).toDouble(),
      originalPrice: json['original_price']?.toDouble(),
      dealPrice: json['deal_price']?.toDouble(),
      affiliateLink: json['affiliate_link'] ?? '',
      validUntil: json['valid_until'] != null 
          ? DateTime.parse(json['valid_until']) 
          : DateTime.now().add(const Duration(days: 30)),
      relevanceScore: json['relevance_score'] ?? 50,
      status: DealInteractionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DealInteractionStatus.shown,
      ),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

enum DealCategory {
  fashion,
  electronics,
  health,
  fitness,
  food,
  travel,
  services,
  entertainment,
  other,
}

enum DealInteractionStatus { shown, clicked, purchased, dismissed }
