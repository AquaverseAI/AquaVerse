import 'dart:async';
import '../models/models.dart';
import 'api_client.dart';

/// Standalone local API client that fulfills all app operations 100% offline
/// without requiring any backend connection or network connectivity.
class StandaloneLocalApiClient implements ApiClient {
  final List<PondLog> _localLogs = [];
  final Set<String> _acknowledgedAlerts = {};
  final Map<String, Map<String, dynamic>> _alertFeedback = {};

  StandaloneLocalApiClient() {
    // Seed initial historical logs
    final now = DateTime.now();
    _localLogs.addAll([
      PondLog(
        id: 'log-seed-1',
        pondId: 'pond-1',
        recordedAt: now.subtract(const Duration(hours: 3)),
        temperatureC: 28.5,
        dissolvedOxygenMgl: 5.6,
        ph: 7.8,
        salinityPpt: 18.0,
        feedGivenKg: 25.0,
        mortalityCount: 0,
        feedTray: FeedTrayStatus.empty,
        waterColor: WaterAppearance.good,
        notes: 'Morning feeding completed. Aerators operational.',
      ),
      PondLog(
        id: 'log-seed-2',
        pondId: 'pond-1',
        recordedAt: now.subtract(const Duration(hours: 9)),
        temperatureC: 27.2,
        dissolvedOxygenMgl: 5.1,
        ph: 7.7,
        salinityPpt: 18.2,
        feedGivenKg: 22.0,
        mortalityCount: 0,
        feedTray: FeedTrayStatus.some,
        waterColor: WaterAppearance.good,
        notes: 'Early morning DO check stable.',
      ),
    ]);
  }

  // ── AUTHENTICATION ─────────────────────────────────────────────────────────

  @override
  Future<OtpRequestResponse> requestOtp(Map<String, dynamic> body) async {
    // Instant local OTP delivery: works for any valid 10-digit number
    return const OtpRequestResponse(
      message: 'OTP generated. Enter any 6 digits to proceed.',
      requestId: 'req-standalone-local',
      devOtp: '123456',
      expiresInSeconds: 300,
    );
  }

  @override
  Future<AuthTokenResponse> verifyOtp(Map<String, dynamic> body) async {
    final requestedRole = body['role']?.toString();
    final isOfficer = requestedRole == 'officer';
    final role = isOfficer ? 'officer' : 'farmer';
    final token = isOfficer
        ? 'standalone-offline-officer-token'
        : 'standalone-offline-farmer-token';

    return AuthTokenResponse(
      accessToken: token,
      tokenType: 'bearer',
      expiresIn: 604800,
      role: role,
      isNewUser: false,
    );
  }

  @override
  Future<AuthTokenResponse> staffTokenLogin(Map<String, dynamic> body) async {
    return const AuthTokenResponse(
      accessToken: 'standalone-offline-officer-token',
      tokenType: 'bearer',
      expiresIn: 604800,
      role: 'officer',
      isNewUser: false,
    );
  }

  @override
  Future<User> getMe() async {
    return const User(
      sub: 'usr-offline-1',
      name: 'Thirunavukkarasu (Farmer)',
      phone: '+919876543210',
      role: 'farmer',
      district: 'Nagapattinam',
    );
  }

  // ── PONDS ──────────────────────────────────────────────────────────────────

  @override
  Future<PondListResponse> getPonds([
    String? cursor,
    int? limit,
    String? district,
  ]) async {
    final now = DateTime.now();
    return PondListResponse(
      items: [
        Pond(
          id: 'pond-1',
          name: 'Pond 1 - North Vantage',
          location: 'Nagapattinam East',
          district: 'Nagapattinam',
          taluk: 'Kilvelur',
          village: 'Velankanni',
          areaSqM: 4000.0,
          depthM: 1.8,
          species: 'Litopenaeus vannamei',
          status: PondStatus.good,
          stockingDate: now.subtract(const Duration(days: 42)),
        ),
        Pond(
          id: 'pond-2',
          name: 'Pond 2 - South Pearl',
          location: 'Nagapattinam South',
          district: 'Nagapattinam',
          taluk: 'Kilvelur',
          village: 'Velankanni',
          areaSqM: 3500.0,
          depthM: 1.6,
          species: 'Litopenaeus vannamei',
          status: PondStatus.good,
          stockingDate: now.subtract(const Duration(days: 28)),
        ),
        Pond(
          id: 'pond-3',
          name: 'Pond 3 - Nursery Bay',
          location: 'Nagapattinam North',
          district: 'Nagapattinam',
          taluk: 'Kilvelur',
          village: 'Velankanni',
          areaSqM: 2000.0,
          depthM: 1.5,
          species: 'Penaeus monodon',
          status: PondStatus.caution,
          stockingDate: now.subtract(const Duration(days: 14)),
        ),
      ],
      totalHint: 3,
    );
  }

  @override
  Future<Pond> getPondDetails(String pondId) async {
    final list = await getPonds();
    return list.items.firstWhere(
      (p) => p.id == pondId,
      orElse: () => list.items.first,
    );
  }

  @override
  Future<PondEventListResponse> getPondEvents(
    String pondId, [
    String? cursor,
    int? limit,
  ]) async {
    final now = DateTime.now();
    return PondEventListResponse(
      items: [
        PondEvent(
          id: 'ev-1',
          eventType: 'aeration',
          title: 'Aerators Activated',
          occurredAt: now.subtract(const Duration(hours: 2)),
          metadata: {'aerator_count': 4},
        ),
        PondEvent(
          id: 'ev-2',
          eventType: 'feeding',
          title: 'Morning Feeding Administered',
          occurredAt: now.subtract(const Duration(hours: 5)),
          metadata: {'feed_kg': 25},
        ),
        PondEvent(
          id: 'ev-3',
          eventType: 'treatment',
          title: 'Water Probiotics Applied',
          occurredAt: now.subtract(const Duration(days: 1)),
          metadata: {'probiotic_type': 'Bacillus subtilis'},
        ),
      ],
      totalHint: 3,
    );
  }

  @override
  Future<PondRisk> getPondRisk(String pondId) async {
    return PondRisk(
      pondId: pondId,
      riskLevel: 'low',
      riskScore: 0.22,
      modelVersion: '1.0',
      scoredAt: DateTime.now(),
      suppressed: false,
    );
  }

  @override
  Future<DOForecast> getDOForecast(String pondId) async {
    final now = DateTime.now();
    return DOForecast(
      pondId: pondId,
      parameter: 'dissolved_oxygen',
      horizonHours: 6,
      modelVersion: '1.0',
      generatedAt: now,
      points: [
        ForecastPoint(
          forecastedAt: now.add(const Duration(hours: 1)),
          p10: 5.2,
          p50: 5.7,
          p90: 6.2,
        ),
        ForecastPoint(
          forecastedAt: now.add(const Duration(hours: 2)),
          p10: 4.9,
          p50: 5.4,
          p90: 5.9,
        ),
        ForecastPoint(
          forecastedAt: now.add(const Duration(hours: 3)),
          p10: 4.6,
          p50: 5.1,
          p90: 5.6,
        ),
        ForecastPoint(
          forecastedAt: now.add(const Duration(hours: 4)),
          p10: 4.3,
          p50: 4.8,
          p90: 5.3,
        ),
        ForecastPoint(
          forecastedAt: now.add(const Duration(hours: 5)),
          p10: 4.2,
          p50: 4.7,
          p90: 5.2,
        ),
        ForecastPoint(
          forecastedAt: now.add(const Duration(hours: 6)),
          p10: 4.5,
          p50: 5.0,
          p90: 5.6,
        ),
      ],
    );
  }

  @override
  Future<PondTimeseriesOut> getTimeseries(
    String pondId, [
    String? parameter,
    String? fromTs,
    String? toTs,
    String? cursor,
    int? limit,
  ]) async {
    final now = DateTime.now();
    return PondTimeseriesOut(
      pondId: pondId,
      parameter: parameter ?? 'dissolved_oxygen',
      points: List.generate(12, (i) {
        final t = now.subtract(Duration(hours: 11 - i));
        return PondTimeseriesPoint(
          recordedAt: t,
          dissolvedOxygenMgl: 5.0 + (i % 3) * 0.4,
          temperatureC: 28.0,
          ph: 7.8,
        );
      }),
    );
  }

  // ── DATA QUALITY ───────────────────────────────────────────────────────────

  @override
  Future<DataQualitySignal> getDataQuality([String? pondId]) async {
    return const DataQualitySignal(
      isBlind: false,
      suppressionReason: null,
      totalLogsLast7d: 14,
    );
  }

  // ── LOGS ───────────────────────────────────────────────────────────────────

  @override
  Future<LogListResponse> getLogs([
    String? pondId,
    String? cursor,
    int? limit,
  ]) async {
    final filtered = pondId != null
        ? _localLogs.where((l) => l.pondId == pondId).toList()
        : _localLogs;
    return LogListResponse(
      items: filtered,
      totalHint: filtered.length,
    );
  }

  @override
  Future<PondLog> createLog(Map<String, dynamic> body) async {
    final newLog = PondLog(
      id: 'srv-${body['client_log_id'] ?? DateTime.now().millisecondsSinceEpoch}',
      pondId: body['pond_id'] as String? ?? 'pond-1',
      clientLogId: body['client_log_id'] as String?,
      recordedAt: DateTime.tryParse(body['logged_at'] as String? ?? '') ?? DateTime.now(),
      temperatureC: (body['temperature_c'] as num?)?.toDouble(),
      dissolvedOxygenMgl: (body['dissolved_oxygen_mgl'] as num?)?.toDouble(),
      ph: (body['ph'] as num?)?.toDouble(),
      salinityPpt: (body['salinity_ppt'] as num?)?.toDouble(),
      feedGivenKg: (body['feed_given_kg'] as num?)?.toDouble(),
      mortalityCount: body['mortality_count'] as int?,
      feedTray: body['feed_tray'] != null ? FeedTrayStatus.values[(body['feed_tray'] as int).clamp(0, 2)] : null,
      waterColor: body['water_color'] != null ? WaterAppearance.good : null,
      notes: body['notes'] as String?,
    );
    _localLogs.insert(0, newLog);
    return newLog;
  }

  // ── MEDIA ──────────────────────────────────────────────────────────────────

  @override
  Future<MediaUploadUrlResponse> getUploadUrl(Map<String, dynamic> body) async {
    final mediaId = 'media-${DateTime.now().millisecondsSinceEpoch}';
    return MediaUploadUrlResponse(
      mediaId: mediaId,
      uploadUrl: 'local://mock-upload/$mediaId',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<MediaCommitResponse> commitMedia(String mediaId) async {
    return MediaCommitResponse(
      mediaId: mediaId,
      status: 'committed',
    );
  }

  // ── ALERTS ─────────────────────────────────────────────────────────────────

  @override
  Future<AlertListResponse> getAlerts([
    String? pondId,
    String? severity,
    bool? acked,
    String? cursor,
    int? limit,
  ]) async {
    final now = DateTime.now();
    final alerts = [
      AlertItem(
        id: 'alt-1',
        pondId: pondId ?? 'pond-1',
        pondName: 'Pond 1 - North Vantage',
        alertType: 'do_drop_warning',
        severity: 'warning',
        title: 'Dissolved Oxygen Trend Notice',
        message:
            'Nighttime DO projected to approach 4.4 mg/L between 3:30 AM and 5:00 AM. Ensure aerators are primed.',
        createdAt: now.subtract(const Duration(hours: 1)),
        acked: _acknowledgedAlerts.contains('alt-1'),
        riskScore: 38,
      ),
      AlertItem(
        id: 'alt-2',
        pondId: pondId ?? 'pond-1',
        pondName: 'Pond 1 - North Vantage',
        alertType: 'feed_adjustment',
        severity: 'low',
        title: 'Feed Tray Clean - Good Appetite',
        message:
            'Morning feed check-tray was completely consumed. Optimal appetite observed across pond quadrants.',
        createdAt: now.subtract(const Duration(hours: 4)),
        acked: _acknowledgedAlerts.contains('alt-2') || true,
        ackedAt: now.subtract(const Duration(hours: 2)),
        riskScore: 16,
      ),
    ];

    final filtered = alerts.where((a) {
      if (acked != null && a.acked != acked) return false;
      return true;
    }).toList();

    return AlertListResponse(items: filtered, totalHint: filtered.length);
  }

  @override
  Future<AlertAckOut> ackAlert(
    String alertId, [
    AlertAckIn body = const AlertAckIn(),
  ]) async {
    _acknowledgedAlerts.add(alertId);
    return AlertAckOut(
      alertId: alertId,
      acked: true,
      ackedAt: DateTime.now(),
      message: 'Alert acknowledged locally',
    );
  }

  @override
  Future<AlertFeedbackOut> sendAlertFeedback(
    String alertId,
    Map<String, dynamic> body,
  ) async {
    _alertFeedback[alertId] = body;
    return AlertFeedbackOut(
      alertId: alertId,
      feedbackRecorded: true,
      message: 'Feedback recorded locally',
    );
  }

  // ── ADVISORIES & ASK AQUA ──────────────────────────────────────────────────

  @override
  Future<AdvisoryListResponse> getAdvisories([
    String? district,
    String? cursor,
    int? limit,
  ]) async {
    final now = DateTime.now();
    return AdvisoryListResponse(
      items: [
        AdvisoryOut(
          id: 'adv-1',
          title: 'Cloudy Skies: Adjust Feeding & Aeration',
          body:
              'Overcast weather projected over the coastal delta today. Phytoplankton photosynthesis will be diminished. Run daytime aerators for 2 additional hours and reduce feed by 10% to prevent unconsumed feed decay on pond bottom.',
          language: 'ta',
          severity: 'warning',
          issuedAt: now.subtract(const Duration(hours: 4)),
        ),
        AdvisoryOut(
          id: 'adv-2',
          title: 'Post-Molt Mineral Supplementation Recommended',
          body:
              'Day 42 molting cycle observed. Check alkalinity levels and supplement agricultural gypsum or dolomite if total alkalinity is under 120 mg/L.',
          language: 'ta',
          severity: 'info',
          issuedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      totalHint: 2,
    );
  }

  @override
  Future<AskResponse> askAqua(AskRequest request) async {
    final q = request.question.toLowerCase();
    String answer;

    if (q.contains('do') || q.contains('oxygen') || q.contains('ஆக்சிஜன்')) {
      answer =
          'Keep Dissolved Oxygen above 4.5 mg/L at all times. During early morning hours (3:00 AM - 6:00 AM), ensure all 4 paddlewheel aerators run continuously.';
    } else if (q.contains('feed') || q.contains('தீவனம்')) {
      answer =
          'For Day 42 Vannamei shrimp, administer 4 feedings daily. Always inspect the feed tray 1.5 to 2 hours after distribution before giving additional feed.';
    } else if (q.contains('ph') || q.contains('காரத்தன்மை')) {
      answer =
          'Ideal pond water pH is 7.5 to 8.5 with daily diurnal fluctuation of less than 0.5. If morning pH is below 7.5, apply agricultural lime (CaCO3) at 100 kg/ha.';
    } else if (q.contains('mortality') || q.contains('இறப்பு')) {
      answer =
          'Zero mortality detected today. If you notice dead shrimp along pond dykes, immediately check DO levels, stop feeding, and inspect gills for fouling.';
    } else {
      answer =
          'AquaVerse AI Advisory: Your current pond conditions for ${request.pondId} are stable. Maintain regular aeration and check feed check-trays twice daily.';
    }

    return AskResponse(
      pondId: request.pondId,
      question: request.question,
      answer: answer,
      language: request.language,
      generatedAt: DateTime.now(),
      rejectedAttemptsThisRequest: 0,
    );
  }

  // ── TRANSLATION ────────────────────────────────────────────────────────────

  @override
  Future<TranslationResponse> translate(TranslationRequest request) async {
    return TranslationResponse(
      originalText: request.text,
      translatedText: request.text,
      sourceLanguage: request.sourceLanguage ?? 'en',
      targetLanguage: request.targetLanguage,
    );
  }
}
