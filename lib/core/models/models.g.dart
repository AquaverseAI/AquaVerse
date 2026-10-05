// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Farmer _$FarmerFromJson(Map<String, dynamic> json) => Farmer(
  id: json['id'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  pondId: json['pondId'] as String,
  role: json['role'] as String,
);

Map<String, dynamic> _$FarmerToJson(Farmer instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'pondId': instance.pondId,
  'role': instance.role,
};

Pond _$PondFromJson(Map<String, dynamic> json) => Pond(
  id: json['id'] as String,
  name: json['name'] as String,
  district: json['district'] as String? ?? 'Nagapattinam',
  taluk: json['taluk'] as String?,
  village: json['village'] as String?,
  areaHectares: (json['area_hectares'] as num?)?.toDouble(),
  depthMeters: (json['depth_meters'] as num?)?.toDouble(),
  species: json['species'] as String?,
  ownerUserId: json['owner_user_id'] as String? ?? '',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  farmerId: json['farmerId'] as String?,
  location: json['location'] as String?,
  areaSqM: (json['areaSqM'] as num?)?.toDouble(),
  depthM: (json['depthM'] as num?)?.toDouble(),
  linerType: json['linerType'] as String?,
  waterSource: json['waterSource'] as String?,
  stockingDate: json['stockingDate'] == null
      ? null
      : DateTime.parse(json['stockingDate'] as String),
  status:
      $enumDecodeNullable(_$PondStatusEnumMap, json['status']) ??
      PondStatus.good,
  lastUpdated: json['lastUpdated'] == null
      ? null
      : DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$PondToJson(Pond instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'district': instance.district,
  'taluk': instance.taluk,
  'village': instance.village,
  'area_hectares': instance.areaHectares,
  'depth_meters': instance.depthMeters,
  'species': instance.species,
  'owner_user_id': instance.ownerUserId,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'farmerId': instance.farmerId,
  'location': instance.location,
  'areaSqM': instance.areaSqM,
  'depthM': instance.depthM,
  'linerType': instance.linerType,
  'waterSource': instance.waterSource,
  'stockingDate': instance.stockingDate?.toIso8601String(),
  'status': _$PondStatusEnumMap[instance.status]!,
  'lastUpdated': instance.lastUpdated?.toIso8601String(),
};

const _$PondStatusEnumMap = {
  PondStatus.good: 'good',
  PondStatus.caution: 'caution',
  PondStatus.critical: 'critical',
};

PondParams _$PondParamsFromJson(Map<String, dynamic> json) => PondParams(
  ph: (json['ph'] as num).toDouble(),
  dissolvedOxygen: (json['dissolvedOxygen'] as num).toDouble(),
  temperature: (json['temperature'] as num).toDouble(),
  salinity: (json['salinity'] as num).toDouble(),
  isBlindState: json['isBlindState'] as bool? ?? false,
  suppressionReason: json['suppressionReason'] as String?,
  isLowConfidence: json['isLowConfidence'] as bool? ?? false,
  recordedAt: DateTime.parse(json['recordedAt'] as String),
);

Map<String, dynamic> _$PondParamsToJson(PondParams instance) =>
    <String, dynamic>{
      'ph': instance.ph,
      'dissolvedOxygen': instance.dissolvedOxygen,
      'temperature': instance.temperature,
      'salinity': instance.salinity,
      'isBlindState': instance.isBlindState,
      'suppressionReason': instance.suppressionReason,
      'isLowConfidence': instance.isLowConfidence,
      'recordedAt': instance.recordedAt.toIso8601String(),
    };

PondLog _$PondLogFromJson(Map<String, dynamic> json) => PondLog(
  id: json['id'] as String,
  pondId: json['pond_id'] as String,
  recordedAt: json['recorded_at'] == null
      ? null
      : DateTime.parse(json['recorded_at'] as String),
  loggedAt: json['loggedAt'] == null
      ? null
      : DateTime.parse(json['loggedAt'] as String),
  temperatureC: (json['temperature_c'] as num?)?.toDouble(),
  temperature: (json['temperature'] as num?)?.toDouble(),
  dissolvedOxygenMgl: (json['dissolved_oxygen_mgl'] as num?)?.toDouble(),
  dissolvedOxygen: (json['dissolvedOxygen'] as num?)?.toDouble(),
  ph: (json['ph'] as num?)?.toDouble(),
  salinityPpt: (json['salinity_ppt'] as num?)?.toDouble(),
  salinity: (json['salinity'] as num?)?.toDouble(),
  ammoniaNh3Mgl: (json['ammonia_nh3_mgl'] as num?)?.toDouble(),
  turbidityNtu: (json['turbidity_ntu'] as num?)?.toDouble(),
  nitriteMgl: (json['nitrite_mgl'] as num?)?.toDouble(),
  nitrateMgl: (json['nitrate_mgl'] as num?)?.toDouble(),
  alkalinityMgl: (json['alkalinity_mgl'] as num?)?.toDouble(),
  hardnessMgl: (json['hardness_mgl'] as num?)?.toDouble(),
  source: json['source'] as String?,
  clientLogId: json['client_log_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  feedGivenKg: (json['feedGivenKg'] as num?)?.toDouble(),
  mortalityCount: (json['mortalityCount'] as num?)?.toInt(),
  feedTray: $enumDecodeNullable(_$FeedTrayStatusEnumMap, json['feedTray']),
  waterColor: $enumDecodeNullable(_$WaterAppearanceEnumMap, json['waterColor']),
  photoUrls:
      (json['photoUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  syncStatus:
      $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
      SyncStatus.synced,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$PondLogToJson(PondLog instance) => <String, dynamic>{
  'id': instance.id,
  'pond_id': instance.pondId,
  'recorded_at': instance.recordedAt.toIso8601String(),
  'temperature_c': instance.temperatureC,
  'dissolved_oxygen_mgl': instance.dissolvedOxygenMgl,
  'ph': instance.ph,
  'salinity_ppt': instance.salinityPpt,
  'ammonia_nh3_mgl': instance.ammoniaNh3Mgl,
  'turbidity_ntu': instance.turbidityNtu,
  'nitrite_mgl': instance.nitriteMgl,
  'nitrate_mgl': instance.nitrateMgl,
  'alkalinity_mgl': instance.alkalinityMgl,
  'hardness_mgl': instance.hardnessMgl,
  'source': instance.source,
  'client_log_id': instance.clientLogId,
  'created_at': instance.createdAt?.toIso8601String(),
  'feedGivenKg': instance.feedGivenKg,
  'mortalityCount': instance.mortalityCount,
  'feedTray': _$FeedTrayStatusEnumMap[instance.feedTray],
  'waterColor': _$WaterAppearanceEnumMap[instance.waterColor],
  'photoUrls': instance.photoUrls,
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
  'notes': instance.notes,
  'loggedAt': instance.loggedAt.toIso8601String(),
  'temperature': instance.temperature,
  'dissolvedOxygen': instance.dissolvedOxygen,
  'salinity': instance.salinity,
};

const _$FeedTrayStatusEnumMap = {
  FeedTrayStatus.empty: 'empty',
  FeedTrayStatus.some: 'some',
  FeedTrayStatus.lots: 'lots',
};

const _$WaterAppearanceEnumMap = {
  WaterAppearance.good: 'good',
  WaterAppearance.average: 'average',
  WaterAppearance.bad: 'bad',
};

const _$SyncStatusEnumMap = {
  SyncStatus.synced: 'synced',
  SyncStatus.pending: 'pending',
  SyncStatus.uploading: 'uploading',
  SyncStatus.failed: 'failed',
};

AlertItem _$AlertItemFromJson(Map<String, dynamic> json) => AlertItem(
  id: json['id'] as String,
  pondId: json['pond_id'] as String?,
  pondName: json['pond_name'] as String?,
  alertType: json['alert_type'] as String,
  severity: json['severity'] as String,
  title: json['title'] as String,
  message: json['message'] as String,
  suppressed: json['suppressed'] as bool? ?? false,
  suppressionReason: json['suppression_reason'] as String?,
  acked: json['acked'] as bool? ?? false,
  ackedAt: json['acked_at'] == null
      ? null
      : DateTime.parse(json['acked_at'] as String),
  riskScore: (json['risk_score'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
  feedback: $enumDecodeNullable(_$AlertFeedbackEnumMap, json['feedback']),
);

Map<String, dynamic> _$AlertItemToJson(AlertItem instance) => <String, dynamic>{
  'id': instance.id,
  'pond_id': instance.pondId,
  'pond_name': instance.pondName,
  'alert_type': instance.alertType,
  'severity': instance.severity,
  'title': instance.title,
  'message': instance.message,
  'suppressed': instance.suppressed,
  'suppression_reason': instance.suppressionReason,
  'acked': instance.acked,
  'acked_at': instance.ackedAt?.toIso8601String(),
  'risk_score': instance.riskScore,
  'created_at': instance.createdAt.toIso8601String(),
  'feedback': _$AlertFeedbackEnumMap[instance.feedback],
};

const _$AlertFeedbackEnumMap = {
  AlertFeedback.correct: 'correct',
  AlertFeedback.incorrect: 'incorrect',
};

AlertListResponse _$AlertListResponseFromJson(Map<String, dynamic> json) =>
    AlertListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
      totalHint: (json['total_hint'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AlertListResponseToJson(AlertListResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
      'total_hint': instance.totalHint,
    };

AlertAckIn _$AlertAckInFromJson(Map<String, dynamic> json) =>
    AlertAckIn(note: json['note'] as String?);

Map<String, dynamic> _$AlertAckInToJson(AlertAckIn instance) =>
    <String, dynamic>{'note': instance.note};

AlertAckOut _$AlertAckOutFromJson(Map<String, dynamic> json) => AlertAckOut(
  alertId: json['alert_id'] as String,
  acked: json['acked'] as bool,
  ackedAt: DateTime.parse(json['acked_at'] as String),
  message: json['message'] as String,
);

Map<String, dynamic> _$AlertAckOutToJson(AlertAckOut instance) =>
    <String, dynamic>{
      'alert_id': instance.alertId,
      'acked': instance.acked,
      'acked_at': instance.ackedAt.toIso8601String(),
      'message': instance.message,
    };

AlertFeedbackIn _$AlertFeedbackInFromJson(Map<String, dynamic> json) =>
    AlertFeedbackIn(
      useful: json['useful'] as bool,
      comment: json['comment'] as String?,
      falsePositive: json['false_positive'] as bool? ?? false,
    );

Map<String, dynamic> _$AlertFeedbackInToJson(AlertFeedbackIn instance) =>
    <String, dynamic>{
      'useful': instance.useful,
      'comment': instance.comment,
      'false_positive': instance.falsePositive,
    };

AlertFeedbackOut _$AlertFeedbackOutFromJson(Map<String, dynamic> json) =>
    AlertFeedbackOut(
      alertId: json['alert_id'] as String,
      feedbackRecorded: json['feedback_recorded'] as bool,
      message: json['message'] as String,
    );

Map<String, dynamic> _$AlertFeedbackOutToJson(AlertFeedbackOut instance) =>
    <String, dynamic>{
      'alert_id': instance.alertId,
      'feedback_recorded': instance.feedbackRecorded,
      'message': instance.message,
    };

Recommendation _$RecommendationFromJson(Map<String, dynamic> json) =>
    Recommendation(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      timeText: json['timeText'] as String?,
      icon: $enumDecode(_$RecommendationIconEnumMap, json['icon']),
      isDone: json['isDone'] as bool? ?? false,
    );

Map<String, dynamic> _$RecommendationToJson(Recommendation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'timeText': instance.timeText,
      'icon': _$RecommendationIconEnumMap[instance.icon]!,
      'isDone': instance.isDone,
    };

const _$RecommendationIconEnumMap = {
  RecommendationIcon.feed: 'feed',
  RecommendationIcon.aerator: 'aerator',
  RecommendationIcon.waterCheck: 'waterCheck',
  RecommendationIcon.medicine: 'medicine',
  RecommendationIcon.harvest: 'harvest',
};

CropCycle _$CropCycleFromJson(Map<String, dynamic> json) => CropCycle(
  id: json['id'] as String,
  pondId: json['pondId'] as String,
  stockingDate: DateTime.parse(json['stockingDate'] as String),
  harvestDate: json['harvestDate'] == null
      ? null
      : DateTime.parse(json['harvestDate'] as String),
  species: json['species'] as String,
  stockingCount: (json['stockingCount'] as num).toInt(),
  cumulativeFeedKg: (json['cumulativeFeedKg'] as num).toDouble(),
  fcr: (json['fcr'] as num).toDouble(),
  costPerKg: (json['costPerKg'] as num).toDouble(),
  marketPricePerKg: (json['marketPricePerKg'] as num).toDouble(),
  expectedHarvestKg: (json['expectedHarvestKg'] as num).toDouble(),
  expectedProfitMin: (json['expectedProfitMin'] as num).toDouble(),
  expectedProfitMax: (json['expectedProfitMax'] as num).toDouble(),
  timeline: (json['timeline'] as List<dynamic>)
      .map((e) => CropEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CropCycleToJson(CropCycle instance) => <String, dynamic>{
  'id': instance.id,
  'pondId': instance.pondId,
  'stockingDate': instance.stockingDate.toIso8601String(),
  'harvestDate': instance.harvestDate?.toIso8601String(),
  'species': instance.species,
  'stockingCount': instance.stockingCount,
  'cumulativeFeedKg': instance.cumulativeFeedKg,
  'fcr': instance.fcr,
  'costPerKg': instance.costPerKg,
  'marketPricePerKg': instance.marketPricePerKg,
  'expectedHarvestKg': instance.expectedHarvestKg,
  'expectedProfitMin': instance.expectedProfitMin,
  'expectedProfitMax': instance.expectedProfitMax,
  'timeline': instance.timeline.map((e) => e.toJson()).toList(),
};

CropEvent _$CropEventFromJson(Map<String, dynamic> json) => CropEvent(
  label: json['label'] as String,
  date: DateTime.parse(json['date'] as String),
  description: json['description'] as String,
  status: $enumDecode(_$CropEventStatusEnumMap, json['status']),
);

Map<String, dynamic> _$CropEventToJson(CropEvent instance) => <String, dynamic>{
  'label': instance.label,
  'date': instance.date.toIso8601String(),
  'description': instance.description,
  'status': _$CropEventStatusEnumMap[instance.status]!,
};

const _$CropEventStatusEnumMap = {
  CropEventStatus.completed: 'completed',
  CropEventStatus.active: 'active',
  CropEventStatus.upcoming: 'upcoming',
};

NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) =>
    NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: $enumDecode(_$NotificationCategoryEnumMap, json['category']),
      isRead: json['isRead'] as bool? ?? false,
      routeTo: json['routeTo'] as String?,
    );

Map<String, dynamic> _$NotificationItemToJson(NotificationItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'timestamp': instance.timestamp.toIso8601String(),
      'category': _$NotificationCategoryEnumMap[instance.category]!,
      'isRead': instance.isRead,
      'routeTo': instance.routeTo,
    };

const _$NotificationCategoryEnumMap = {
  NotificationCategory.alert: 'alert',
  NotificationCategory.reminder: 'reminder',
  NotificationCategory.info: 'info',
  NotificationCategory.system: 'system',
};

OfficerVisit _$OfficerVisitFromJson(Map<String, dynamic> json) => OfficerVisit(
  id: json['id'] as String,
  pondId: json['pondId'] as String,
  farmerName: json['farmerName'] as String,
  officerId: json['officerId'] as String,
  visitDate: DateTime.parse(json['visitDate'] as String),
  observations: json['observations'] as String,
  suggestions: json['suggestions'] as String,
  photoUrls:
      (json['photoUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  syncStatus:
      $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
      SyncStatus.synced,
);

Map<String, dynamic> _$OfficerVisitToJson(OfficerVisit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pondId': instance.pondId,
      'farmerName': instance.farmerName,
      'officerId': instance.officerId,
      'visitDate': instance.visitDate.toIso8601String(),
      'observations': instance.observations,
      'suggestions': instance.suggestions,
      'photoUrls': instance.photoUrls,
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
    };

PondRisk _$PondRiskFromJson(Map<String, dynamic> json) => PondRisk(
  pondId: json['pond_id'] as String? ?? '',
  riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.1,
  riskLevel: json['risk_level'] as String? ?? 'low',
  components:
      (json['components'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const {},
  modelVersion: json['model_version'] as String? ?? '1.0',
  scoredAt: json['scored_at'] == null
      ? null
      : DateTime.parse(json['scored_at'] as String),
  suppressed: json['suppressed'] as bool? ?? false,
  suppressionReason: json['suppression_reason'] as String?,
  tier: json['tier'] as String?,
  score: (json['score'] as num?)?.toDouble(),
  syncedAt: json['syncedAt'] == null
      ? null
      : DateTime.parse(json['syncedAt'] as String),
);

Map<String, dynamic> _$PondRiskToJson(PondRisk instance) => <String, dynamic>{
  'pond_id': instance.pondId,
  'risk_score': instance.riskScore,
  'risk_level': instance.riskLevel,
  'components': instance.components,
  'model_version': instance.modelVersion,
  'scored_at': instance.scoredAt?.toIso8601String(),
  'suppressed': instance.suppressed,
  'suppression_reason': instance.suppressionReason,
  'score': instance.score,
  'tier': instance.tier,
  'syncedAt': instance.syncedAt?.toIso8601String(),
};

DataQualitySignal _$DataQualitySignalFromJson(Map<String, dynamic> json) =>
    DataQualitySignal(
      pondId: json['pond_id'] as String?,
      totalLogsLast7d: (json['total_logs_last_7d'] as num?)?.toInt() ?? 0,
      missingParameterRates:
          (json['missing_parameter_rates'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      sensorOfflinePonds: (json['sensor_offline_ponds'] as num?)?.toInt() ?? 0,
      staleThresholdHours:
          (json['stale_threshold_hours'] as num?)?.toInt() ?? 24,
      evaluatedAt: json['evaluated_at'] == null
          ? null
          : DateTime.parse(json['evaluated_at'] as String),
      suppressionReason: json['suppressionReason'] as String?,
      isBlind: json['isBlind'] as bool?,
    );

Map<String, dynamic> _$DataQualitySignalToJson(DataQualitySignal instance) =>
    <String, dynamic>{
      'pond_id': instance.pondId,
      'total_logs_last_7d': instance.totalLogsLast7d,
      'missing_parameter_rates': instance.missingParameterRates,
      'sensor_offline_ponds': instance.sensorOfflinePonds,
      'stale_threshold_hours': instance.staleThresholdHours,
      'evaluated_at': instance.evaluatedAt?.toIso8601String(),
      'isBlind': instance.isBlind,
      'suppressionReason': instance.suppressionReason,
    };

PondEvent _$PondEventFromJson(Map<String, dynamic> json) => PondEvent(
  id: json['id'] as String,
  eventType: json['event_type'] as String?,
  type: json['type'] as String?,
  title: json['title'] as String?,
  summary: json['summary'] as String?,
  occurredAt: json['occurred_at'] == null
      ? null
      : DateTime.parse(json['occurred_at'] as String),
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  severity: json['severity'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  payload: json['payload'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PondEventToJson(PondEvent instance) => <String, dynamic>{
  'id': instance.id,
  'event_type': instance.eventType,
  'title': instance.title,
  'occurred_at': instance.occurredAt.toIso8601String(),
  'severity': instance.severity,
  'metadata': instance.metadata,
  'type': instance.type,
  'summary': instance.summary,
  'timestamp': instance.timestamp.toIso8601String(),
  'payload': instance.payload,
};

PondEventListResponse _$PondEventListResponseFromJson(
  Map<String, dynamic> json,
) => PondEventListResponse(
  items: (json['items'] as List<dynamic>)
      .map((e) => PondEvent.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['next_cursor'] as String?,
  totalHint: (json['total_hint'] as num?)?.toInt(),
);

Map<String, dynamic> _$PondEventListResponseToJson(
  PondEventListResponse instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': instance.nextCursor,
  'total_hint': instance.totalHint,
};

User _$UserFromJson(Map<String, dynamic> json) => User(
  sub: json['sub'] as String,
  role: json['role'] as String,
  name: json['name'] as String?,
  district: json['district'] as String?,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'sub': instance.sub,
  'role': instance.role,
  'name': instance.name,
  'district': instance.district,
  'phone': instance.phone,
};

OtpRequestResponse _$OtpRequestResponseFromJson(Map<String, dynamic> json) =>
    OtpRequestResponse(
      message: json['message'] as String,
      expiresInSeconds: (json['expires_in_seconds'] as num).toInt(),
      requestId: json['request_id'] as String,
      devOtp: json['dev_otp'] as String?,
    );

Map<String, dynamic> _$OtpRequestResponseToJson(OtpRequestResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'expires_in_seconds': instance.expiresInSeconds,
      'request_id': instance.requestId,
      'dev_otp': instance.devOtp,
    };

AuthTokenResponse _$AuthTokenResponseFromJson(Map<String, dynamic> json) =>
    AuthTokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: (json['expires_in'] as num).toInt(),
      role: json['role'] as String,
      isNewUser: json['is_new_user'] as bool,
    );

Map<String, dynamic> _$AuthTokenResponseToJson(AuthTokenResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
      'role': instance.role,
      'is_new_user': instance.isNewUser,
    };

DOForecast _$DOForecastFromJson(Map<String, dynamic> json) => DOForecast(
  pondId: json['pond_id'] as String,
  parameter: json['parameter'] as String,
  horizonHours: (json['horizon_hours'] as num).toInt(),
  points: (json['points'] as List<dynamic>)
      .map((e) => ForecastPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  modelVersion: json['model_version'] as String,
  generatedAt: DateTime.parse(json['generated_at'] as String),
  uncertaintyNote: json['uncertainty_note'] as String?,
);

Map<String, dynamic> _$DOForecastToJson(DOForecast instance) =>
    <String, dynamic>{
      'pond_id': instance.pondId,
      'parameter': instance.parameter,
      'horizon_hours': instance.horizonHours,
      'points': instance.points.map((e) => e.toJson()).toList(),
      'model_version': instance.modelVersion,
      'generated_at': instance.generatedAt.toIso8601String(),
      'uncertainty_note': instance.uncertaintyNote,
    };

ForecastPoint _$ForecastPointFromJson(Map<String, dynamic> json) =>
    ForecastPoint(
      forecastedAt: DateTime.parse(json['forecasted_at'] as String),
      p10: (json['p10'] as num).toDouble(),
      p50: (json['p50'] as num).toDouble(),
      p90: (json['p90'] as num).toDouble(),
    );

Map<String, dynamic> _$ForecastPointToJson(ForecastPoint instance) =>
    <String, dynamic>{
      'forecasted_at': instance.forecastedAt.toIso8601String(),
      'p10': instance.p10,
      'p50': instance.p50,
      'p90': instance.p90,
    };

PondTimeseriesOut _$PondTimeseriesOutFromJson(Map<String, dynamic> json) =>
    PondTimeseriesOut(
      pondId: json['pond_id'] as String,
      parameter: json['parameter'] as String,
      points: (json['points'] as List<dynamic>)
          .map((e) => PondTimeseriesPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
    );

Map<String, dynamic> _$PondTimeseriesOutToJson(PondTimeseriesOut instance) =>
    <String, dynamic>{
      'pond_id': instance.pondId,
      'parameter': instance.parameter,
      'points': instance.points.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
    };

PondTimeseriesPoint _$PondTimeseriesPointFromJson(Map<String, dynamic> json) =>
    PondTimeseriesPoint(
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      dissolvedOxygenMgl: (json['dissolved_oxygen_mgl'] as num?)?.toDouble(),
      ph: (json['ph'] as num?)?.toDouble(),
      salinityPpt: (json['salinity_ppt'] as num?)?.toDouble(),
      ammoniaNh3Mgl: (json['ammonia_nh3_mgl'] as num?)?.toDouble(),
      turbidityNtu: (json['turbidity_ntu'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PondTimeseriesPointToJson(
  PondTimeseriesPoint instance,
) => <String, dynamic>{
  'recorded_at': instance.recordedAt.toIso8601String(),
  'temperature_c': instance.temperatureC,
  'dissolved_oxygen_mgl': instance.dissolvedOxygenMgl,
  'ph': instance.ph,
  'salinity_ppt': instance.salinityPpt,
  'ammonia_nh3_mgl': instance.ammoniaNh3Mgl,
  'turbidity_ntu': instance.turbidityNtu,
};

AskRequest _$AskRequestFromJson(Map<String, dynamic> json) => AskRequest(
  pondId: json['pond_id'] as String,
  question: json['question'] as String,
  language: json['language'] as String? ?? 'ta',
  includeTts: json['include_tts'] as bool? ?? false,
);

Map<String, dynamic> _$AskRequestToJson(AskRequest instance) =>
    <String, dynamic>{
      'pond_id': instance.pondId,
      'question': instance.question,
      'language': instance.language,
      'include_tts': instance.includeTts,
    };

AskResponse _$AskResponseFromJson(Map<String, dynamic> json) => AskResponse(
  pondId: json['pond_id'] as String,
  question: json['question'] as String,
  answer: json['answer'] as String,
  language: json['language'] as String,
  ttsUrl: json['tts_url'] as String?,
  generatedAt: DateTime.parse(json['generated_at'] as String),
  rejectedAttemptsThisRequest: (json['rejected_attempts_this_request'] as num)
      .toInt(),
);

Map<String, dynamic> _$AskResponseToJson(AskResponse instance) =>
    <String, dynamic>{
      'pond_id': instance.pondId,
      'question': instance.question,
      'answer': instance.answer,
      'language': instance.language,
      'tts_url': instance.ttsUrl,
      'generated_at': instance.generatedAt.toIso8601String(),
      'rejected_attempts_this_request': instance.rejectedAttemptsThisRequest,
    };

TranslationRequest _$TranslationRequestFromJson(Map<String, dynamic> json) =>
    TranslationRequest(
      text: json['text'] as String,
      targetLanguage: json['targetLanguage'] as String,
      sourceLanguage: json['sourceLanguage'] as String?,
    );

Map<String, dynamic> _$TranslationRequestToJson(TranslationRequest instance) =>
    <String, dynamic>{
      'text': instance.text,
      'targetLanguage': instance.targetLanguage,
      'sourceLanguage': instance.sourceLanguage,
    };

TranslationResponse _$TranslationResponseFromJson(Map<String, dynamic> json) =>
    TranslationResponse(
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      isCached: json['isCached'] as bool?,
    );

Map<String, dynamic> _$TranslationResponseToJson(
  TranslationResponse instance,
) => <String, dynamic>{
  'originalText': instance.originalText,
  'translatedText': instance.translatedText,
  'sourceLanguage': instance.sourceLanguage,
  'targetLanguage': instance.targetLanguage,
  'isCached': instance.isCached,
};

MediaUploadUrlResponse _$MediaUploadUrlResponseFromJson(
  Map<String, dynamic> json,
) => MediaUploadUrlResponse(
  mediaId: json['media_id'] as String,
  uploadUrl: json['upload_url'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$MediaUploadUrlResponseToJson(
  MediaUploadUrlResponse instance,
) => <String, dynamic>{
  'media_id': instance.mediaId,
  'upload_url': instance.uploadUrl,
  'expires_at': instance.expiresAt.toIso8601String(),
};

PondListResponse _$PondListResponseFromJson(Map<String, dynamic> json) =>
    PondListResponse(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => Pond.fromJson(e as Map<String, dynamic>))
          .toList(),
      ponds: (json['ponds'] as List<dynamic>?)
          ?.map((e) => Pond.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
      totalHint: (json['total_hint'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PondListResponseToJson(PondListResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
      'total_hint': instance.totalHint,
      'ponds': instance.ponds.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };

LogListResponse _$LogListResponseFromJson(Map<String, dynamic> json) =>
    LogListResponse(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => PondLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      logs: (json['logs'] as List<dynamic>?)
          ?.map((e) => PondLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
      totalHint: (json['total_hint'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
    );

Map<String, dynamic> _$LogListResponseToJson(LogListResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
      'total_hint': instance.totalHint,
      'logs': instance.logs.map((e) => e.toJson()).toList(),
      'total': instance.total,
    };

AdvisoryOut _$AdvisoryOutFromJson(Map<String, dynamic> json) => AdvisoryOut(
  id: json['id'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  language: json['language'] as String,
  targetDistrict: json['target_district'] as String?,
  targetSpecies: json['target_species'] as String?,
  severity: json['severity'] as String?,
  issuedAt: DateTime.parse(json['issued_at'] as String),
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$AdvisoryOutToJson(AdvisoryOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'language': instance.language,
      'target_district': instance.targetDistrict,
      'target_species': instance.targetSpecies,
      'severity': instance.severity,
      'issued_at': instance.issuedAt.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
    };

AdvisoryListResponse _$AdvisoryListResponseFromJson(
  Map<String, dynamic> json,
) => AdvisoryListResponse(
  items: (json['items'] as List<dynamic>)
      .map((e) => AdvisoryOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['next_cursor'] as String?,
  totalHint: (json['total_hint'] as num?)?.toInt(),
);

Map<String, dynamic> _$AdvisoryListResponseToJson(
  AdvisoryListResponse instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'next_cursor': instance.nextCursor,
  'total_hint': instance.totalHint,
};

MediaCommitResponse _$MediaCommitResponseFromJson(Map<String, dynamic> json) =>
    MediaCommitResponse(
      mediaId: json['media_id'] as String,
      pondId: json['pond_id'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      status: json['status'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MediaCommitResponseToJson(
  MediaCommitResponse instance,
) => <String, dynamic>{
  'media_id': instance.mediaId,
  'pond_id': instance.pondId,
  'filename': instance.filename,
  'mime_type': instance.mimeType,
  'size_bytes': instance.sizeBytes,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
};
