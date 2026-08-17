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
  farmerId: json['farmerId'] as String,
  location: json['location'] as String,
  areaSqM: (json['areaSqM'] as num).toDouble(),
  depthM: (json['depthM'] as num).toDouble(),
  linerType: json['linerType'] as String,
  waterSource: json['waterSource'] as String,
  stockingDate: DateTime.parse(json['stockingDate'] as String),
  species: json['species'] as String,
  status: $enumDecode(_$PondStatusEnumMap, json['status']),
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$PondToJson(Pond instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'farmerId': instance.farmerId,
  'location': instance.location,
  'areaSqM': instance.areaSqM,
  'depthM': instance.depthM,
  'linerType': instance.linerType,
  'waterSource': instance.waterSource,
  'stockingDate': instance.stockingDate.toIso8601String(),
  'species': instance.species,
  'status': _$PondStatusEnumMap[instance.status]!,
  'lastUpdated': instance.lastUpdated.toIso8601String(),
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
  pondId: json['pondId'] as String,
  loggedAt: DateTime.parse(json['loggedAt'] as String),
  feedGivenKg: (json['feedGivenKg'] as num?)?.toDouble(),
  mortalityCount: (json['mortalityCount'] as num?)?.toInt(),
  feedTray: $enumDecodeNullable(_$FeedTrayStatusEnumMap, json['feedTray']),
  waterColor: $enumDecodeNullable(_$WaterAppearanceEnumMap, json['waterColor']),
  ph: (json['ph'] as num?)?.toDouble(),
  dissolvedOxygen: (json['dissolvedOxygen'] as num?)?.toDouble(),
  temperature: (json['temperature'] as num?)?.toDouble(),
  salinity: (json['salinity'] as num?)?.toDouble(),
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
  'pondId': instance.pondId,
  'loggedAt': instance.loggedAt.toIso8601String(),
  'feedGivenKg': instance.feedGivenKg,
  'mortalityCount': instance.mortalityCount,
  'feedTray': _$FeedTrayStatusEnumMap[instance.feedTray],
  'waterColor': _$WaterAppearanceEnumMap[instance.waterColor],
  'ph': instance.ph,
  'dissolvedOxygen': instance.dissolvedOxygen,
  'temperature': instance.temperature,
  'salinity': instance.salinity,
  'photoUrls': instance.photoUrls,
  'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
  'notes': instance.notes,
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
  severity: $enumDecode(_$AlertSeverityEnumMap, json['severity']),
  title: json['title'] as String,
  description: json['description'] as String,
  what: json['what'] as String,
  why: json['why'] as String,
  action: json['action'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  acknowledged: json['acknowledged'] as bool? ?? false,
  feedback: $enumDecodeNullable(_$AlertFeedbackEnumMap, json['feedback']),
  isLowConfidence: json['isLowConfidence'] as bool? ?? false,
  hasSuppressionReason: json['hasSuppressionReason'] as bool? ?? false,
);

Map<String, dynamic> _$AlertItemToJson(AlertItem instance) => <String, dynamic>{
  'id': instance.id,
  'severity': _$AlertSeverityEnumMap[instance.severity]!,
  'title': instance.title,
  'description': instance.description,
  'what': instance.what,
  'why': instance.why,
  'action': instance.action,
  'timestamp': instance.timestamp.toIso8601String(),
  'acknowledged': instance.acknowledged,
  'feedback': _$AlertFeedbackEnumMap[instance.feedback],
  'isLowConfidence': instance.isLowConfidence,
  'hasSuppressionReason': instance.hasSuppressionReason,
};

const _$AlertSeverityEnumMap = {
  AlertSeverity.critical: 'critical',
  AlertSeverity.attention: 'attention',
  AlertSeverity.info: 'info',
};

const _$AlertFeedbackEnumMap = {
  AlertFeedback.correct: 'correct',
  AlertFeedback.incorrect: 'incorrect',
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

DOForecastPoint _$DOForecastPointFromJson(Map<String, dynamic> json) =>
    DOForecastPoint(
      time: DateTime.parse(json['time'] as String),
      value: (json['value'] as num).toDouble(),
      isDanger: json['isDanger'] as bool,
    );

Map<String, dynamic> _$DOForecastPointToJson(DOForecastPoint instance) =>
    <String, dynamic>{
      'time': instance.time.toIso8601String(),
      'value': instance.value,
      'isDanger': instance.isDanger,
    };
