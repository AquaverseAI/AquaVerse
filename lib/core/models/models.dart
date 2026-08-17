import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable(explicitToJson: true)
class Farmer {
  final String id;
  final String name;
  final String phone;
  final String pondId;
  final String role; 

  const Farmer({
    required this.id,
    required this.name,
    required this.phone,
    required this.pondId,
    required this.role,
  });

  factory Farmer.fromJson(Map<String, dynamic> json) => _$FarmerFromJson(json);
  Map<String, dynamic> toJson() => _$FarmerToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Pond {
  final String id;
  final String name;
  final String farmerId;
  final String location;
  final double areaSqM;
  final double depthM;
  final String linerType;
  final String waterSource;
  final DateTime stockingDate;
  final String species;
  final PondStatus status;
  final DateTime lastUpdated;

  const Pond({
    required this.id,
    required this.name,
    required this.farmerId,
    required this.location,
    required this.areaSqM,
    required this.depthM,
    required this.linerType,
    required this.waterSource,
    required this.stockingDate,
    required this.species,
    required this.status,
    required this.lastUpdated,
  });

  factory Pond.fromJson(Map<String, dynamic> json) => _$PondFromJson(json);
  Map<String, dynamic> toJson() => _$PondToJson(this);
}

@JsonEnum()
enum PondStatus { good, caution, critical }

@JsonSerializable(explicitToJson: true)
class PondParams {
  final double ph;
  final double dissolvedOxygen;
  final double temperature;     
  final double salinity;        
  final bool isBlindState;
  final String? suppressionReason;
  final bool isLowConfidence;
  final DateTime recordedAt;

  const PondParams({
    required this.ph,
    required this.dissolvedOxygen,
    required this.temperature,
    required this.salinity,
    this.isBlindState = false,
    this.suppressionReason,
    this.isLowConfidence = false,
    required this.recordedAt,
  });

  factory PondParams.fromJson(Map<String, dynamic> json) => _$PondParamsFromJson(json);
  Map<String, dynamic> toJson() => _$PondParamsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PondLog {
  final String id;
  final String pondId;
  final DateTime loggedAt;
  final double? feedGivenKg;
  final int? mortalityCount;
  final FeedTrayStatus? feedTray;
  final WaterAppearance? waterColor;
  final double? ph;
  final double? dissolvedOxygen;
  final double? temperature;
  final double? salinity;
  final List<String> photoUrls;
  final SyncStatus syncStatus;
  final String? notes;

  const PondLog({
    required this.id,
    required this.pondId,
    required this.loggedAt,
    this.feedGivenKg,
    this.mortalityCount,
    this.feedTray,
    this.waterColor,
    this.ph,
    this.dissolvedOxygen,
    this.temperature,
    this.salinity,
    this.photoUrls = const [],
    this.syncStatus = SyncStatus.synced,
    this.notes,
  });

  PondLog copyWith({SyncStatus? syncStatus}) {
    return PondLog(
      id: id, pondId: pondId, loggedAt: loggedAt,
      feedGivenKg: feedGivenKg, mortalityCount: mortalityCount,
      feedTray: feedTray, waterColor: waterColor, ph: ph,
      dissolvedOxygen: dissolvedOxygen, temperature: temperature,
      salinity: salinity, photoUrls: photoUrls,
      syncStatus: syncStatus ?? this.syncStatus, notes: notes,
    );
  }

  factory PondLog.fromJson(Map<String, dynamic> json) => _$PondLogFromJson(json);
  Map<String, dynamic> toJson() => _$PondLogToJson(this);
}

@JsonEnum()
enum FeedTrayStatus { empty, some, lots }
@JsonEnum()
enum WaterAppearance { good, average, bad }
@JsonEnum()
enum SyncStatus { synced, pending, uploading, failed }

@JsonSerializable(explicitToJson: true)
class AlertItem {
  final String id;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String what;
  final String why;
  final String action;
  final DateTime timestamp;
  final bool acknowledged;
  final AlertFeedback? feedback;
  final bool isLowConfidence;
  final bool hasSuppressionReason;

  const AlertItem({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    required this.what,
    required this.why,
    required this.action,
    required this.timestamp,
    this.acknowledged = false,
    this.feedback,
    this.isLowConfidence = false,
    this.hasSuppressionReason = false,
  });

  AlertItem copyWith({bool? acknowledged, AlertFeedback? feedback}) {
    return AlertItem(
      id: id, severity: severity, title: title, description: description,
      what: what, why: why, action: action, timestamp: timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
      feedback: feedback ?? this.feedback,
      isLowConfidence: isLowConfidence,
      hasSuppressionReason: hasSuppressionReason,
    );
  }

  factory AlertItem.fromJson(Map<String, dynamic> json) => _$AlertItemFromJson(json);
  Map<String, dynamic> toJson() => _$AlertItemToJson(this);
}

@JsonEnum()
enum AlertSeverity { critical, attention, info }
@JsonEnum()
enum AlertFeedback { correct, incorrect }

@JsonSerializable(explicitToJson: true)
class Recommendation {
  final String id;
  final String title;
  final String subtitle;
  final String? timeText;
  final RecommendationIcon icon;
  final bool isDone;

  const Recommendation({
    required this.id,
    required this.title,
    required this.subtitle,
    this.timeText,
    required this.icon,
    this.isDone = false,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) => _$RecommendationFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationToJson(this);
}

@JsonEnum()
enum RecommendationIcon { feed, aerator, waterCheck, medicine, harvest }

@JsonSerializable(explicitToJson: true)
class CropCycle {
  final String id;
  final String pondId;
  final DateTime stockingDate;
  final DateTime? harvestDate;
  final String species;
  final int stockingCount;
  final double cumulativeFeedKg;
  final double fcr;
  final double costPerKg;
  final double marketPricePerKg;
  final double expectedHarvestKg;
  final double expectedProfitMin;
  final double expectedProfitMax;
  final List<CropEvent> timeline;

  const CropCycle({
    required this.id,
    required this.pondId,
    required this.stockingDate,
    this.harvestDate,
    required this.species,
    required this.stockingCount,
    required this.cumulativeFeedKg,
    required this.fcr,
    required this.costPerKg,
    required this.marketPricePerKg,
    required this.expectedHarvestKg,
    required this.expectedProfitMin,
    required this.expectedProfitMax,
    required this.timeline,
  });

  factory CropCycle.fromJson(Map<String, dynamic> json) => _$CropCycleFromJson(json);
  Map<String, dynamic> toJson() => _$CropCycleToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CropEvent {
  final String label;
  final DateTime date;
  final String description;
  final CropEventStatus status;

  const CropEvent({
    required this.label,
    required this.date,
    required this.description,
    required this.status,
  });

  factory CropEvent.fromJson(Map<String, dynamic> json) => _$CropEventFromJson(json);
  Map<String, dynamic> toJson() => _$CropEventToJson(this);
}

@JsonEnum()
enum CropEventStatus { completed, active, upcoming }

@JsonSerializable(explicitToJson: true)
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationCategory category;
  final bool isRead;
  final String? routeTo;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.category,
    this.isRead = false,
    this.routeTo,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id, title: title, body: body, timestamp: timestamp,
      category: category, isRead: isRead ?? this.isRead, routeTo: routeTo,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) => _$NotificationItemFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationItemToJson(this);
}

@JsonEnum()
enum NotificationCategory { alert, reminder, info, system }

@JsonSerializable(explicitToJson: true)
class OfficerVisit {
  final String id;
  final String pondId;
  final String farmerName;
  final String officerId;
  final DateTime visitDate;
  final String observations;
  final String suggestions;
  final List<String> photoUrls;
  final SyncStatus syncStatus;

  const OfficerVisit({
    required this.id,
    required this.pondId,
    required this.farmerName,
    required this.officerId,
    required this.visitDate,
    required this.observations,
    required this.suggestions,
    this.photoUrls = const [],
    this.syncStatus = SyncStatus.synced,
  });

  factory OfficerVisit.fromJson(Map<String, dynamic> json) => _$OfficerVisitFromJson(json);
  Map<String, dynamic> toJson() => _$OfficerVisitToJson(this);
}

// TODO(contract): exact risk response schema not confirmed — building to accept {score, tier} or either alone
@JsonSerializable(explicitToJson: true)
class PondRisk {
  final double? score;
  final String? tier; // "low", "medium", "high"
  final DateTime? syncedAt;
  final Map<String, dynamic>? raw;

  const PondRisk({
    this.score,
    this.tier,
    this.syncedAt,
    this.raw,
  });

  factory PondRisk.fromJson(dynamic json, {DateTime? syncedAt}) {
    if (json is Map<String, dynamic>) {
      final s = (json['score'] as num?)?.toDouble() ?? (json['risk_score'] as num?)?.toDouble();
      final t = (json['tier'] as String?) ?? (json['level'] as String?) ?? (json['risk_tier'] as String?);
      return PondRisk(
        score: s,
        tier: t?.toLowerCase(),
        syncedAt: syncedAt ?? DateTime.now(),
        raw: json,
      );
    }
    return PondRisk(
      score: (json is num) ? json.toDouble() : null,
      tier: (json is String) ? json.toLowerCase() : null,
      syncedAt: syncedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => _$PondRiskToJson(this);

  String get effectiveTier {
    if (tier != null) return tier!;
    if (score != null) {
      if (score! >= 0.7) return 'high';
      if (score! >= 0.3) return 'medium';
      return 'low';
    }
    return 'low';
  }
}

// TODO(contract): data-quality response schema not confirmed — R5 blind-state signal parser
@JsonSerializable(explicitToJson: true)
class DataQualitySignal {
  final bool isBlind;
  final String? suppressionReason;
  final DateTime? syncedAt;
  final Map<String, dynamic>? raw;

  const DataQualitySignal({
    required this.isBlind,
    this.suppressionReason,
    this.syncedAt,
    this.raw,
  });

  factory DataQualitySignal.fromJson(dynamic json, {DateTime? syncedAt}) {
    if (json is Map<String, dynamic>) {
      final blind = (json['is_blind'] as bool?) ??
          (json['blind_state'] as bool?) ??
          (json['isBlindState'] as bool?) ??
          false;
      final reason = (json['suppression_reason'] as String?) ??
          (json['reason'] as String?) ??
          (json['suppressionReason'] as String?);
      return DataQualitySignal(
        isBlind: blind,
        suppressionReason: reason,
        syncedAt: syncedAt ?? DateTime.now(),
        raw: json,
      );
    }
    if (json is bool) {
      return DataQualitySignal(isBlind: json, syncedAt: syncedAt ?? DateTime.now());
    }
    return DataQualitySignal(isBlind: false, syncedAt: syncedAt ?? DateTime.now());
  }

  Map<String, dynamic> toJson() => _$DataQualitySignalToJson(this);
}

// TODO(contract): event taxonomy from /v1/ponds/{pond_id}/events not confirmed — defensive model
@JsonSerializable(explicitToJson: true)
class PondEvent {
  final String id;
  final String type; // e.g. "sensor_fault", "alert_trigger", "photo_submitted", "advisory_issued"
  final String summary;
  final DateTime timestamp;
  final Map<String, dynamic>? payload;

  const PondEvent({
    required this.id,
    required this.type,
    required this.summary,
    required this.timestamp,
    this.payload,
  });

  factory PondEvent.fromJson(Map<String, dynamic> json) {
    return PondEvent(
      id: (json['id'] as String?) ?? (json['event_id'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: (json['type'] as String?) ?? (json['event_type'] as String?) ?? 'info',
      summary: (json['summary'] as String?) ?? (json['description'] as String?) ?? (json['title'] as String?) ?? 'Pond event logged',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
      payload: json['payload'] is Map<String, dynamic> ? json['payload'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() => _$PondEventToJson(this);
}

