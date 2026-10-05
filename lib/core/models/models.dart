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
  final String district;
  final String? taluk;
  final String? village;
  @JsonKey(name: 'area_hectares')
  final double? areaHectares;
  @JsonKey(name: 'depth_meters')
  final double? depthMeters;
  final String? species;
  @JsonKey(name: 'owner_user_id')
  final String ownerUserId;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Local / legacy UI fields
  final String? farmerId;
  final String? location;
  final double? areaSqM;
  final double? depthM;
  final String? linerType;
  final String? waterSource;
  final DateTime? stockingDate;
  final PondStatus status;
  final DateTime? lastUpdated;

  const Pond({
    required this.id,
    required this.name,
    this.district = 'Nagapattinam',
    this.taluk,
    this.village,
    this.areaHectares,
    this.depthMeters,
    this.species,
    this.ownerUserId = '',
    this.createdAt,
    this.updatedAt,
    this.farmerId,
    this.location,
    this.areaSqM,
    this.depthM,
    this.linerType,
    this.waterSource,
    this.stockingDate,
    this.status = PondStatus.good,
    this.lastUpdated,
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
  @JsonKey(name: 'pond_id')
  final String pondId;
  @JsonKey(name: 'recorded_at')
  final DateTime recordedAt;
  @JsonKey(name: 'temperature_c')
  final double? temperatureC;
  @JsonKey(name: 'dissolved_oxygen_mgl')
  final double? dissolvedOxygenMgl;
  final double? ph;
  @JsonKey(name: 'salinity_ppt')
  final double? salinityPpt;
  @JsonKey(name: 'ammonia_nh3_mgl')
  final double? ammoniaNh3Mgl;
  @JsonKey(name: 'turbidity_ntu')
  final double? turbidityNtu;
  @JsonKey(name: 'nitrite_mgl')
  final double? nitriteMgl;
  @JsonKey(name: 'nitrate_mgl')
  final double? nitrateMgl;
  @JsonKey(name: 'alkalinity_mgl')
  final double? alkalinityMgl;
  @JsonKey(name: 'hardness_mgl')
  final double? hardnessMgl;
  final String? source;
  @JsonKey(name: 'client_log_id')
  final String? clientLogId;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  final double? feedGivenKg;
  final int? mortalityCount;
  final FeedTrayStatus? feedTray;
  final WaterAppearance? waterColor;
  final List<String> photoUrls;
  final SyncStatus syncStatus;
  final String? notes;

  PondLog({
    required this.id,
    required this.pondId,
    DateTime? recordedAt,
    DateTime? loggedAt,
    double? temperatureC,
    double? temperature,
    double? dissolvedOxygenMgl,
    double? dissolvedOxygen,
    this.ph,
    double? salinityPpt,
    double? salinity,
    this.ammoniaNh3Mgl,
    this.turbidityNtu,
    this.nitriteMgl,
    this.nitrateMgl,
    this.alkalinityMgl,
    this.hardnessMgl,
    this.source,
    this.clientLogId,
    this.createdAt,
    this.feedGivenKg,
    this.mortalityCount,
    this.feedTray,
    this.waterColor,
    this.photoUrls = const [],
    this.syncStatus = SyncStatus.synced,
    this.notes,
  })  : recordedAt = recordedAt ?? (loggedAt ?? DateTime.now()),
        temperatureC = temperatureC ?? temperature,
        dissolvedOxygenMgl = dissolvedOxygenMgl ?? dissolvedOxygen,
        salinityPpt = salinityPpt ?? salinity;

  // ---------------------------------------------------------------------------
  // UI convenience getters
  // ---------------------------------------------------------------------------
  DateTime get loggedAt => recordedAt;
  double? get temperature => temperatureC;
  double? get dissolvedOxygen => dissolvedOxygenMgl;
  double? get salinity => salinityPpt;

  PondLog copyWith({
    String? id,
    String? clientLogId,
    String? pondId,
    DateTime? recordedAt,
    double? temperatureC,
    double? dissolvedOxygenMgl,
    double? ph,
    double? salinityPpt,
    List<String>? photoUrls,
    SyncStatus? syncStatus,
    String? notes,
  }) {
    return PondLog(
      id: id ?? this.id,
      clientLogId: clientLogId ?? this.clientLogId,
      pondId: pondId ?? this.pondId,
      recordedAt: recordedAt ?? this.recordedAt,
      temperatureC: temperatureC ?? this.temperatureC,
      dissolvedOxygenMgl: dissolvedOxygenMgl ?? this.dissolvedOxygenMgl,
      ph: ph ?? this.ph,
      salinityPpt: salinityPpt ?? this.salinityPpt,
      ammoniaNh3Mgl: ammoniaNh3Mgl,
      turbidityNtu: turbidityNtu,
      nitriteMgl: nitriteMgl,
      nitrateMgl: nitrateMgl,
      alkalinityMgl: alkalinityMgl,
      hardnessMgl: hardnessMgl,
      source: source,
      createdAt: createdAt,
      photoUrls: photoUrls ?? this.photoUrls,
      syncStatus: syncStatus ?? this.syncStatus,
      notes: notes ?? this.notes,
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
  @JsonKey(name: 'pond_id')
  final String? pondId;
  @JsonKey(name: 'pond_name')
  final String? pondName;
  @JsonKey(name: 'alert_type')
  final String alertType;
  /// Severity as returned by backend: "high", "warning", "low"
  final String severity;
  final String title;
  final String message;
  final bool suppressed;
  @JsonKey(name: 'suppression_reason')
  final String? suppressionReason;
  final bool acked;
  @JsonKey(name: 'acked_at')
  final DateTime? ackedAt;
  @JsonKey(name: 'risk_score')
  final double? riskScore;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  // Client-side only — not from server
  final AlertFeedback? feedback;

  const AlertItem({
    required this.id,
    this.pondId,
    this.pondName,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    this.suppressed = false,
    this.suppressionReason,
    this.acked = false,
    this.ackedAt,
    this.riskScore,
    required this.createdAt,
    this.feedback,
  });

  AlertItem copyWith({bool? acked, AlertFeedback? feedback}) {
    return AlertItem(
      id: id, pondId: pondId, pondName: pondName,
      alertType: alertType, severity: severity,
      title: title, message: message,
      suppressed: suppressed, suppressionReason: suppressionReason,
      acked: acked ?? this.acked, ackedAt: ackedAt,
      riskScore: riskScore, createdAt: createdAt,
      feedback: feedback ?? this.feedback,
    );
  }

  // ---------------------------------------------------------------------------
  // UI convenience getters — computed from contract-aligned fields
  // ---------------------------------------------------------------------------

  /// Convenience for code that still reads `acknowledged`
  bool get acknowledged => acked;

  /// Map backend severity string to the AlertSeverity enum for UI usage
  AlertSeverity get severityEnum {
    switch (severity.toLowerCase()) {
      case 'high': return AlertSeverity.high;
      case 'warning': return AlertSeverity.warning;
      default: return AlertSeverity.low;
    }
  }

  String get description => message;
  String get what => message;
  String get why => suppressionReason ?? 'Parameter exceeded safe threshold';
  String get action => 'Inspect pond conditions and follow advisory instructions';
  DateTime get timestamp => createdAt;
  bool get isLowConfidence => suppressed;
  bool get hasSuppressionReason => suppressed;

  factory AlertItem.fromJson(Map<String, dynamic> json) => _$AlertItemFromJson(json);
  Map<String, dynamic> toJson() => _$AlertItemToJson(this);
}

/// Pagination wrapper for /v1/alerts — matches CursorPage_AlertOut_ schema.
@JsonSerializable(explicitToJson: true)
class AlertListResponse {
  final List<AlertItem> items;
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;
  @JsonKey(name: 'total_hint')
  final int? totalHint;

  const AlertListResponse({
    required this.items,
    this.nextCursor,
    this.totalHint,
  });

  factory AlertListResponse.fromJson(Map<String, dynamic> json) =>
      _$AlertListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AlertListResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AlertAckIn {
  final String? note;

  const AlertAckIn({this.note});

  factory AlertAckIn.fromJson(Map<String, dynamic> json) =>
      _$AlertAckInFromJson(json);
  Map<String, dynamic> toJson() => _$AlertAckInToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AlertAckOut {
  @JsonKey(name: 'alert_id')
  final String alertId;
  final bool acked;
  @JsonKey(name: 'acked_at')
  final DateTime ackedAt;
  final String message;

  const AlertAckOut({
    required this.alertId,
    required this.acked,
    required this.ackedAt,
    required this.message,
  });

  factory AlertAckOut.fromJson(Map<String, dynamic> json) =>
      _$AlertAckOutFromJson(json);
  Map<String, dynamic> toJson() => _$AlertAckOutToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AlertFeedbackIn {
  final bool useful;
  final String? comment;
  @JsonKey(name: 'false_positive')
  final bool falsePositive;

  const AlertFeedbackIn({
    required this.useful,
    this.comment,
    this.falsePositive = false,
  });

  factory AlertFeedbackIn.fromJson(Map<String, dynamic> json) =>
      _$AlertFeedbackInFromJson(json);
  Map<String, dynamic> toJson() => _$AlertFeedbackInToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AlertFeedbackOut {
  @JsonKey(name: 'alert_id')
  final String alertId;
  @JsonKey(name: 'feedback_recorded')
  final bool feedbackRecorded;
  final String message;

  const AlertFeedbackOut({
    required this.alertId,
    required this.feedbackRecorded,
    required this.message,
  });

  factory AlertFeedbackOut.fromJson(Map<String, dynamic> json) =>
      _$AlertFeedbackOutFromJson(json);
  Map<String, dynamic> toJson() => _$AlertFeedbackOutToJson(this);
}

/// Backend severity values: "high", "warning", "low"
@JsonEnum()
enum AlertSeverity { high, warning, low }
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

/// Contract-aligned with RiskOut schema.
@JsonSerializable(explicitToJson: true)
class PondRisk {
  @JsonKey(name: 'pond_id')
  final String pondId;
  @JsonKey(name: 'risk_score')
  final double riskScore;
  @JsonKey(name: 'risk_level')
  final String riskLevel;
  final Map<String, double> components;
  @JsonKey(name: 'model_version')
  final String modelVersion;
  @JsonKey(name: 'scored_at')
  final DateTime? scoredAt;
  final bool suppressed;
  @JsonKey(name: 'suppression_reason')
  final String? suppressionReason;

  const PondRisk({
    this.pondId = '',
    this.riskScore = 0.1,
    this.riskLevel = 'low',
    this.components = const {},
    this.modelVersion = '1.0',
    this.scoredAt,
    this.suppressed = false,
    this.suppressionReason,
    String? tier,
    double? score,
    DateTime? syncedAt,
    Map<String, dynamic>? raw,
  });

  // ---------------------------------------------------------------------------
  // UI convenience getters — sit ABOVE correct contract-aligned serialization
  // ---------------------------------------------------------------------------
  double? get score => riskScore;
  String get tier => riskLevel.toLowerCase();
  String get effectiveTier => riskLevel.toLowerCase();
  DateTime? get syncedAt => scoredAt;

  factory PondRisk.fromJson(Map<String, dynamic> json) => _$PondRiskFromJson(json);
  Map<String, dynamic> toJson() => _$PondRiskToJson(this);
}


/// Contract-aligned with DataQualityOut schema.
@JsonSerializable(explicitToJson: true)
class DataQualitySignal {
  @JsonKey(name: 'pond_id')
  final String? pondId;
  @JsonKey(name: 'total_logs_last_7d')
  final int totalLogsLast7d;
  @JsonKey(name: 'missing_parameter_rates')
  final Map<String, double> missingParameterRates;
  @JsonKey(name: 'sensor_offline_ponds')
  final int sensorOfflinePonds;
  @JsonKey(name: 'stale_threshold_hours')
  final int staleThresholdHours;
  @JsonKey(name: 'evaluated_at')
  final DateTime? evaluatedAt;
  final String? _suppressionReason;
  final bool? _isBlind;

  const DataQualitySignal({
    this.pondId,
    this.totalLogsLast7d = 0,
    this.missingParameterRates = const {},
    this.sensorOfflinePonds = 0,
    this.staleThresholdHours = 24,
    this.evaluatedAt,
    String? suppressionReason,
    bool? isBlind,
  })  : _suppressionReason = suppressionReason,
        _isBlind = isBlind;

  // ---------------------------------------------------------------------------
  // UI convenience — determines whether to show blind-state banner.
  // A pond is considered "blind" if the sensor is offline or DO is missing >50%.
  // ---------------------------------------------------------------------------
  bool get isBlind =>
      _isBlind ??
      (sensorOfflinePonds > 0 ||
          (missingParameterRates['dissolved_oxygen_mgl'] ?? 0.0) > 0.5);

  String? get suppressionReason {
    if (_suppressionReason != null) return _suppressionReason;
    if (sensorOfflinePonds > 0) return 'Sensor is offline. Water quality data may be stale.';
    if ((missingParameterRates['dissolved_oxygen_mgl'] ?? 0.0) > 0.5) {
      return 'Dissolved oxygen data missing for more than 50% of logs in the last 7 days.';
    }
    return null;
  }

  factory DataQualitySignal.fromJson(Map<String, dynamic> json) =>
      _$DataQualitySignalFromJson(json);
  Map<String, dynamic> toJson() => _$DataQualitySignalToJson(this);
}

/// Contract-aligned with PondEventOut schema.
@JsonSerializable(explicitToJson: true)
class PondEvent {
  final String id;
  @JsonKey(name: 'event_type')
  final String eventType;
  final String title;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;
  final String? severity;
  final Map<String, dynamic>? metadata;

  PondEvent({
    required this.id,
    String? eventType,
    String? type,
    String? title,
    String? summary,
    DateTime? occurredAt,
    DateTime? timestamp,
    this.severity,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? payload,
  })  : eventType = eventType ?? (type ?? 'info'),
        title = title ?? (summary ?? 'Event'),
        occurredAt = occurredAt ?? (timestamp ?? DateTime.now()),
        metadata = metadata ?? payload;

  // ---------------------------------------------------------------------------
  // UI convenience getters
  // ---------------------------------------------------------------------------
  String get type => eventType;
  String get summary => title;
  DateTime get timestamp => occurredAt;
  Map<String, dynamic>? get payload => metadata;

  factory PondEvent.fromJson(Map<String, dynamic> json) =>
      _$PondEventFromJson(json);
  Map<String, dynamic> toJson() => _$PondEventToJson(this);
}

/// Pagination wrapper for /v1/ponds/{id}/events — matches CursorPage_PondEventOut_ schema.
@JsonSerializable(explicitToJson: true)
class PondEventListResponse {
  final List<PondEvent> items;
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;
  @JsonKey(name: 'total_hint')
  final int? totalHint;

  const PondEventListResponse({
    required this.items,
    this.nextCursor,
    this.totalHint,
  });

  factory PondEventListResponse.fromJson(Map<String, dynamic> json) =>
      _$PondEventListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PondEventListResponseToJson(this);
}

// ============================================================================
// USER & AUTHENTICATION MODELS
// ============================================================================

@JsonSerializable(explicitToJson: true)
class User {
  /// The user's UUID — returned as `sub` by /auth/me (JWT subject claim).
  final String sub;
  final String role;
  final String? name;
  final String? district;
  final String? phone;

  const User({
    required this.sub,
    required this.role,
    this.name,
    this.district,
    this.phone,
  });

  /// Convenience alias: callers can use `.id` or `.sub` interchangeably.
  String get id => sub;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isFarmer => role.toLowerCase() == 'farmer';
  bool get isOfficer => role.toLowerCase() == 'officer' || role.toLowerCase() == 'extension_officer';
}

@JsonSerializable(explicitToJson: true)
class OtpRequestResponse {
  final String message;
  @JsonKey(name: 'expires_in_seconds')
  final int expiresInSeconds;
  @JsonKey(name: 'request_id')
  final String requestId;
  /// Only present in dev/test environments when SMS_PROVIDER=mock
  @JsonKey(name: 'dev_otp')
  final String? devOtp;

  const OtpRequestResponse({
    required this.message,
    required this.expiresInSeconds,
    required this.requestId,
    this.devOtp,
  });

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestResponseFromJson(json);
  Map<String, dynamic> toJson() => _$OtpRequestResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AuthTokenResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  final String role;
  @JsonKey(name: 'is_new_user')
  final bool isNewUser;

  const AuthTokenResponse({
    required this.accessToken,
    this.tokenType = 'bearer',
    required this.expiresIn,
    required this.role,
    required this.isNewUser,
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthTokenResponseToJson(this);
}

// ============================================================================
// FORECAST & TIMESERIES MODELS
// ============================================================================

@JsonSerializable(explicitToJson: true)
class DOForecast {
  @JsonKey(name: 'pond_id')
  final String pondId;
  final String parameter;
  @JsonKey(name: 'horizon_hours')
  final int horizonHours;
  final List<ForecastPoint> points;
  @JsonKey(name: 'model_version')
  final String modelVersion;
  @JsonKey(name: 'generated_at')
  final DateTime generatedAt;
  @JsonKey(name: 'uncertainty_note')
  final String? uncertaintyNote;

  const DOForecast({
    required this.pondId,
    required this.parameter,
    required this.horizonHours,
    required this.points,
    required this.modelVersion,
    required this.generatedAt,
    this.uncertaintyNote,
  });

  // ---------------------------------------------------------------------------
  // UI convenience getters — derived from contract-aligned fields
  // ---------------------------------------------------------------------------
  double? get currentDo => points.isNotEmpty ? points.first.p50 : null;
  double? get minDo => points.isEmpty ? null : points.map((p) => p.p10).reduce((a, b) => a < b ? a : b);
  double? get maxDo => points.isEmpty ? null : points.map((p) => p.p90).reduce((a, b) => a > b ? a : b);

  factory DOForecast.fromJson(Map<String, dynamic> json) =>
      _$DOForecastFromJson(json);
  Map<String, dynamic> toJson() => _$DOForecastToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ForecastPoint {
  @JsonKey(name: 'forecasted_at')
  final DateTime forecastedAt;
  final double p10;
  final double p50;
  final double p90;

  const ForecastPoint({
    required this.forecastedAt,
    required this.p10,
    required this.p50,
    required this.p90,
  });

  // ---------------------------------------------------------------------------
  // UI convenience getters — sit ABOVE correct contract-aligned serialization
  // ---------------------------------------------------------------------------
  DateTime get timestamp => forecastedAt;
  double get value => p50;
  double get lowerBound => p10;
  double get upperBound => p90;

  factory ForecastPoint.fromJson(Map<String, dynamic> json) =>
      _$ForecastPointFromJson(json);
  Map<String, dynamic> toJson() => _$ForecastPointToJson(this);
}

/// Contract-aligned with PondTimeseriesOut schema.
@JsonSerializable(explicitToJson: true)
class PondTimeseriesOut {
  @JsonKey(name: 'pond_id')
  final String pondId;
  final String parameter;
  final List<PondTimeseriesPoint> points;
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;

  const PondTimeseriesOut({
    required this.pondId,
    required this.parameter,
    required this.points,
    this.nextCursor,
  });

  factory PondTimeseriesOut.fromJson(Map<String, dynamic> json) =>
      _$PondTimeseriesOutFromJson(json);
  Map<String, dynamic> toJson() => _$PondTimeseriesOutToJson(this);
}

/// Contract-aligned with PondTimeseriesPoint schema.
@JsonSerializable(explicitToJson: true)
class PondTimeseriesPoint {
  @JsonKey(name: 'recorded_at')
  final DateTime recordedAt;
  @JsonKey(name: 'temperature_c')
  final double? temperatureC;
  @JsonKey(name: 'dissolved_oxygen_mgl')
  final double? dissolvedOxygenMgl;
  final double? ph;
  @JsonKey(name: 'salinity_ppt')
  final double? salinityPpt;
  @JsonKey(name: 'ammonia_nh3_mgl')
  final double? ammoniaNh3Mgl;
  @JsonKey(name: 'turbidity_ntu')
  final double? turbidityNtu;

  const PondTimeseriesPoint({
    required this.recordedAt,
    this.temperatureC,
    this.dissolvedOxygenMgl,
    this.ph,
    this.salinityPpt,
    this.ammoniaNh3Mgl,
    this.turbidityNtu,
  });

  // UI convenience getters
  DateTime get timestamp => recordedAt;
  double get value => dissolvedOxygenMgl ?? temperatureC ?? ph ?? salinityPpt ?? 0.0;

  factory PondTimeseriesPoint.fromJson(Map<String, dynamic> json) =>
      _$PondTimeseriesPointFromJson(json);
  Map<String, dynamic> toJson() => _$PondTimeseriesPointToJson(this);
}

// Legacy alias for compatibility with existing code
typedef TimeSeriesData = PondTimeseriesOut;
typedef TimeSeriesPoint = PondTimeseriesPoint;

// ============================================================================
// ASK / ADVISORY MODELS
// ============================================================================

@JsonSerializable(explicitToJson: true)
class AskRequest {
  @JsonKey(name: 'pond_id')
  final String pondId;
  final String question;
  final String language;
  @JsonKey(name: 'include_tts')
  final bool includeTts;

  const AskRequest({
    required this.pondId,
    required this.question,
    this.language = 'ta',
    this.includeTts = false,
  });

  factory AskRequest.fromJson(Map<String, dynamic> json) =>
      _$AskRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AskRequestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AskResponse {
  @JsonKey(name: 'pond_id')
  final String pondId;
  final String question;
  final String answer;
  final String language;
  @JsonKey(name: 'tts_url')
  final String? ttsUrl;
  @JsonKey(name: 'generated_at')
  final DateTime generatedAt;
  @JsonKey(name: 'rejected_attempts_this_request')
  final int rejectedAttemptsThisRequest;

  const AskResponse({
    required this.pondId,
    required this.question,
    required this.answer,
    required this.language,
    this.ttsUrl,
    required this.generatedAt,
    required this.rejectedAttemptsThisRequest,
  });

  // UI convenience getter — existing code may reference `.narration`
  String? get narration => ttsUrl;

  factory AskResponse.fromJson(Map<String, dynamic> json) =>
      _$AskResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AskResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TranslationRequest {
  final String text;
  final String targetLanguage;
  final String? sourceLanguage;

  const TranslationRequest({
    required this.text,
    required this.targetLanguage,
    this.sourceLanguage,
  });

  factory TranslationRequest.fromJson(Map<String, dynamic> json) =>
      _$TranslationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TranslationRequestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TranslationResponse {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final bool? isCached;

  const TranslationResponse({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.isCached,
  });

  factory TranslationResponse.fromJson(Map<String, dynamic> json) =>
      _$TranslationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TranslationResponseToJson(this);
}

// ============================================================================
// MEDIA UPLOAD MODELS
// ============================================================================

@JsonSerializable(explicitToJson: true)
class MediaUploadUrlResponse {
  @JsonKey(name: 'media_id')
  final String mediaId;
  @JsonKey(name: 'upload_url')
  final String uploadUrl;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  const MediaUploadUrlResponse({
    required this.mediaId,
    required this.uploadUrl,
    required this.expiresAt,
  });

  /// Convenience alias — some call sites still reference `.putUrl`
  String get putUrl => uploadUrl;

  factory MediaUploadUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaUploadUrlResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MediaUploadUrlResponseToJson(this);
}

// ============================================================================
// PAGINATION MODELS
// PAGINATION & API RESPONSE WRAPPER MODELS
// ============================================================================

// Note: Paginated responses are returned as Map<String, dynamic> from Retrofit
// The repository layer will convert these to typed lists
@JsonSerializable(explicitToJson: true)
class PondListResponse {
  final List<Pond> items;
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;
  @JsonKey(name: 'total_hint')
  final int? totalHint;

  PondListResponse({
    List<Pond>? items,
    List<Pond>? ponds,
    this.nextCursor,
    int? totalHint,
    int? total,
  })  : items = items ?? (ponds ?? const []),
        totalHint = totalHint ?? total;

  List<Pond> get pondList => items;
  List<Pond> get ponds => items;
  int? get total => totalHint;

  factory PondListResponse.fromJson(Map<String, dynamic> json) =>
      _$PondListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PondListResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LogListResponse {
  final List<PondLog> items;
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;
  @JsonKey(name: 'total_hint')
  final int? totalHint;

  LogListResponse({
    List<PondLog>? items,
    List<PondLog>? logs,
    this.nextCursor,
    int? totalHint,
    int? total,
  })  : items = items ?? (logs ?? const []),
        totalHint = totalHint ?? total;

  List<PondLog> get logList => items;
  List<PondLog> get logs => items;
  int? get total => totalHint;

  factory LogListResponse.fromJson(Map<String, dynamic> json) =>
      _$LogListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LogListResponseToJson(this);
}

/// Contract-aligned with AdvisoryOut schema.
@JsonSerializable(explicitToJson: true)
class AdvisoryOut {
  final String id;
  final String title;
  final String body;
  final String language;
  @JsonKey(name: 'target_district')
  final String? targetDistrict;
  @JsonKey(name: 'target_species')
  final String? targetSpecies;
  final String? severity;
  @JsonKey(name: 'issued_at')
  final DateTime issuedAt;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  const AdvisoryOut({
    required this.id,
    required this.title,
    required this.body,
    required this.language,
    this.targetDistrict,
    this.targetSpecies,
    this.severity,
    required this.issuedAt,
    this.expiresAt,
  });

  String get subtitle => body;

  factory AdvisoryOut.fromJson(Map<String, dynamic> json) =>
      _$AdvisoryOutFromJson(json);
  Map<String, dynamic> toJson() => _$AdvisoryOutToJson(this);
}

/// Pagination wrapper for /v1/advisories — matches CursorPage_AdvisoryOut_ schema.
@JsonSerializable(explicitToJson: true)
class AdvisoryListResponse {
  final List<AdvisoryOut> items;
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;
  @JsonKey(name: 'total_hint')
  final int? totalHint;

  const AdvisoryListResponse({
    required this.items,
    this.nextCursor,
    this.totalHint,
  });

  List<AdvisoryOut> get advisories => items;
  List<Recommendation> get advisoryList => items.map((a) => Recommendation(
    id: a.id,
    title: a.title,
    subtitle: a.body,
    icon: RecommendationIcon.waterCheck,
  )).toList();

  factory AdvisoryListResponse.fromJson(Map<String, dynamic> json) =>
      _$AdvisoryListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AdvisoryListResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MediaCommitResponse {
  @JsonKey(name: 'media_id')
  final String mediaId;
  @JsonKey(name: 'pond_id')
  final String pondId;
  final String filename;
  @JsonKey(name: 'mime_type')
  final String mimeType;
  @JsonKey(name: 'size_bytes')
  final int? sizeBytes;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  MediaCommitResponse({
    required this.mediaId,
    this.pondId = '',
    this.filename = '',
    this.mimeType = '',
    this.sizeBytes,
    required this.status,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MediaCommitResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaCommitResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MediaCommitResponseToJson(this);
}



