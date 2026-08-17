import '../models/models.dart';

/// In-memory demo dataset for AquaVerse AI.
/// Used when no backend is available. All data is realistic for a
/// Pangasius farmer in Thanjavur, Tamil Nadu.
class DemoDataService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  DemoDataService._();
  static final DemoDataService instance = DemoDataService._();

  // ── Farmer ─────────────────────────────────────────────────────────────────
  static final Farmer farmer = Farmer(
    id: 'F-001',
    name: 'Murugan',
    phone: '+91 98765 43210',
    pondId: 'TN-01-001',
    role: 'farmer',
  );

  // ── Pond ───────────────────────────────────────────────────────────────────
  static final Pond pond = Pond(
    id: 'TN-01-001',
    name: 'Main Farm Pond',
    farmerId: 'F-001',
    location: 'Thanjavur, Tamil Nadu',
    areaSqM: 2000,
    depthM: 1.5,
    linerType: 'HDPE',
    waterSource: 'Borewell',
    stockingDate: DateTime.now().subtract(const Duration(days: 45)),
    species: 'Pangasius',
    status: PondStatus.good,
    lastUpdated: DateTime.now().subtract(const Duration(hours: 4)),
  );

  // ── Current pond parameters ─────────────────────────────────────────────────
  static final PondParams params = PondParams(
    ph: 7.8,
    dissolvedOxygen: 5.2,
    temperature: 28.0,
    salinity: 5.2,
    isBlindState: false,
    isLowConfidence: false,
    recordedAt: DateTime.now().subtract(const Duration(hours: 4)),
  );

  // ── Recommendations ─────────────────────────────────────────────────────────
  static final List<Recommendation> recommendations = [
    const Recommendation(
      id: 'R-001',
      title: 'Feed 18 kg',
      subtitle: 'Split into 3 times',
      icon: RecommendationIcon.feed,
    ),
    const Recommendation(
      id: 'R-002',
      title: 'Run Aerator',
      subtitle: '11:00 PM – 06:00 AM',
      timeText: '11 PM – 6 AM',
      icon: RecommendationIcon.aerator,
    ),
    const Recommendation(
      id: 'R-003',
      title: 'Check Water Color',
      subtitle: 'Observe for unusual discoloration',
      icon: RecommendationIcon.waterCheck,
    ),
  ];

  // ── DO Forecast ─────────────────────────────────────────────────────────────
  static List<DOForecastPoint> doForecast() {
    final now = DateTime.now();
    return [
      DOForecastPoint(time: now.subtract(const Duration(hours: 12)), value: 6.2, isDanger: false),
      DOForecastPoint(time: now.subtract(const Duration(hours: 10)), value: 5.8, isDanger: false),
      DOForecastPoint(time: now.subtract(const Duration(hours: 8)),  value: 5.5, isDanger: false),
      DOForecastPoint(time: now.subtract(const Duration(hours: 6)),  value: 5.2, isDanger: false),
      DOForecastPoint(time: now.subtract(const Duration(hours: 4)),  value: 4.8, isDanger: false),
      DOForecastPoint(time: now.subtract(const Duration(hours: 2)),  value: 4.2, isDanger: false),
      DOForecastPoint(time: now,                                      value: 3.8, isDanger: true),
      DOForecastPoint(time: now.add(const Duration(hours: 2)),       value: 3.4, isDanger: true),
      DOForecastPoint(time: now.add(const Duration(hours: 4)),       value: 4.1, isDanger: false),
      DOForecastPoint(time: now.add(const Duration(hours: 6)),       value: 5.0, isDanger: false),
      DOForecastPoint(time: now.add(const Duration(hours: 8)),       value: 5.6, isDanger: false),
      DOForecastPoint(time: now.add(const Duration(hours: 10)),      value: 6.0, isDanger: false),
    ];
  }

  // ── Alerts ──────────────────────────────────────────────────────────────────
  static final List<AlertItem> alerts = [
    AlertItem(
      id: 'A-001',
      severity: AlertSeverity.critical,
      title: 'Low Oxygen Alert',
      description: 'Dissolved oxygen is dropping below safe levels',
      what: 'DO dropped to 3.8 mg/L — below the 4.0 mg/L safe threshold.',
      why: 'High feed load + low wind. Forecasting further drop overnight.',
      action: 'Run aerators immediately. Reduce feed by 30% tonight.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AlertItem(
      id: 'A-002',
      severity: AlertSeverity.attention,
      title: 'High Ammonia Risk',
      description: 'Elevated ammonia levels detected',
      what: 'Ammonia approaching 0.5 ppm based on feed load estimate.',
      why: 'Overfeeding in last 3 days + poor water exchange conditions.',
      action: 'Check ammonia with test kit. Consider 20% water exchange.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isLowConfidence: true,
    ),
    AlertItem(
      id: 'A-003',
      severity: AlertSeverity.info,
      title: 'Rain Forecast',
      description: '60% chance of heavy rain in next 12 hours',
      what: 'IMD forecast shows 60% rain probability.',
      why: 'Rain may lower DO and raise ammonia from runoff.',
      action: 'Monitor DO every 2 hours. Prepare aerators.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AlertItem(
      id: 'A-004',
      severity: AlertSeverity.info,
      title: 'Log Reminder',
      description: "You haven't logged today. Log now for better insights.",
      what: 'No log entry recorded for today.',
      why: 'Consistent logging improves AI forecast accuracy.',
      action: 'Tap Log to record today\'s readings.',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  // ── Crop Cycle ──────────────────────────────────────────────────────────────
  static final CropCycle cropCycle = CropCycle(
    id: 'CC-001',
    pondId: 'TN-01-001',
    stockingDate: DateTime.now().subtract(const Duration(days: 45)),
    species: 'Pangasius',
    stockingCount: 5000,
    cumulativeFeedKg: 1245,
    fcr: 1.32,
    costPerKg: 92,
    marketPricePerKg: 165,
    expectedHarvestKg: 800,
    expectedProfitMin: 105000,
    expectedProfitMax: 145000,
    timeline: [
      CropEvent(
        label: 'Stocked',
        date: DateTime.now().subtract(const Duration(days: 45)),
        description: '5,000 Pangasius fingerlings stocked',
        status: CropEventStatus.completed,
      ),
      CropEvent(
        label: 'Feed Management',
        date: DateTime.now().subtract(const Duration(days: 40)),
        description: 'Optimal feed schedule started',
        status: CropEventStatus.completed,
      ),
      CropEvent(
        label: 'Medicines',
        date: DateTime.now().subtract(const Duration(days: 20)),
        description: '3 records — preventive treatment',
        status: CropEventStatus.completed,
      ),
      CropEvent(
        label: 'Growth',
        date: DateTime.now(),
        description: 'Day 45 — Avg 160g. On track.',
        status: CropEventStatus.active,
      ),
      CropEvent(
        label: 'Harvest',
        date: DateTime.now().add(const Duration(days: 55)),
        description: 'Expected 10 Sep 2026',
        status: CropEventStatus.upcoming,
      ),
    ],
  );

  // ── Notifications ───────────────────────────────────────────────────────────
  static List<NotificationItem> notifications = [
    NotificationItem(
      id: 'N-001',
      title: 'Low DO Alert',
      body: 'Dissolved oxygen dropping. Run aerators now.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      category: NotificationCategory.alert,
      routeTo: '/alerts',
    ),
    NotificationItem(
      id: 'N-002',
      title: 'High Ammonia Risk',
      body: 'Ammonia may be rising. Check levels.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      category: NotificationCategory.alert,
      routeTo: '/alerts',
    ),
    NotificationItem(
      id: 'N-003',
      title: 'Rain Forecast',
      body: '60% chance of heavy rain in next 12 hours.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      category: NotificationCategory.info,
      routeTo: '/alerts',
    ),
    NotificationItem(
      id: 'N-004',
      title: 'Log Reminder',
      body: "You haven't logged today. Log now for better insights.",
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      category: NotificationCategory.reminder,
      routeTo: '/log',
    ),
    NotificationItem(
      id: 'N-005',
      title: 'System Update',
      body: 'AquaVerse AI updated to v1.2. Improved DO forecasting.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      category: NotificationCategory.system,
      isRead: true,
    ),
  ];

  // ── Recent Ask questions ──────────────────────────────────────────────────
  static const List<String> recentQuestions = [
    'இன்று மீன்களுக்கு எவ்வளவு தீவனம் போட வேண்டும்?',
    'நீரில் ஆக்ஸிஜன் குறைவாக இருந்தால் என்ன செய்வது?',
    'அம்மோனியா அளவை எப்படி குறைப்பது?',
    'What is the best time to run aerators?',
  ];

  // ── My Ponds (officer view) ──────────────────────────────────────────────
  static final List<Map<String, dynamic>> officerPonds = [
    {
      'pondId': 'TN-01-001', 'farmerName': 'Murugan',
      'location': 'Thanjavur', 'status': PondStatus.good,
      'lastVisit': '3 days ago', 'risk': 'Low',
    },
    {
      'pondId': 'TN-01-002', 'farmerName': 'Selvam',
      'location': 'Kumbakonam', 'status': PondStatus.caution,
      'lastVisit': '5 days ago', 'risk': 'Medium',
    },
    {
      'pondId': 'TN-01-003', 'farmerName': 'Rajan',
      'location': 'Nagapattinam', 'status': PondStatus.critical,
      'lastVisit': '7 days ago', 'risk': 'High',
    },
    {
      'pondId': 'TN-01-004', 'farmerName': 'Mani',
      'location': 'Thanjavur', 'status': PondStatus.good,
      'lastVisit': '2 days ago', 'risk': 'Low',
    },
    {
      'pondId': 'TN-01-005', 'farmerName': 'Kumar',
      'location': 'Papanasam', 'status': PondStatus.caution,
      'lastVisit': '4 days ago', 'risk': 'Medium',
    },
  ];

  // ── 7-day trend ──────────────────────────────────────────────────────────
  static List<Map<String, double>> weeklyTrend() {
    return [
      {'ph': 7.6, 'do': 5.8, 'temp': 27.5},
      {'ph': 7.7, 'do': 5.5, 'temp': 28.0},
      {'ph': 7.8, 'do': 5.3, 'temp': 28.2},
      {'ph': 7.9, 'do': 5.1, 'temp': 28.5},
      {'ph': 7.8, 'do': 5.0, 'temp': 28.3},
      {'ph': 7.7, 'do': 4.8, 'temp': 28.6},
      {'ph': 7.8, 'do': 5.2, 'temp': 28.0},
    ];
  }

  // ── FAQ ──────────────────────────────────────────────────────────────────
  static const List<Map<String, String>> faqs = [
    {
      'q': 'How often should I log my pond data?',
      'a': 'Log at least once daily, preferably in the morning. Consistent logging improves AI forecast accuracy significantly.',
    },
    {
      'q': 'What is a safe dissolved oxygen level?',
      'a': 'Dissolved oxygen should be above 4.0 mg/L at all times. Below 3.0 mg/L is critical and requires immediate aeration.',
    },
    {
      'q': 'When should I use Ask Aqua?',
      'a': 'Ask Aqua any time you have a question about your pond. It works best when you have logged regularly and have recent data.',
    },
    {
      'q': 'What does the blind state warning mean?',
      'a': 'Blind state means AI cannot generate reliable advice because no log has been recorded for 3+ days. Log your data to resume alerts.',
    },
    {
      'q': 'How do I sync offline logs?',
      'a': 'Offline logs sync automatically when you reconnect to the internet. You can see pending logs in the Log screen.',
    },
  ];
}
