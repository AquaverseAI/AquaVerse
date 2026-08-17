import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/pond_repository.dart';
import '../repositories/log_repository.dart';
import '../repositories/alert_repository.dart';
import '../repositories/data_quality_repository.dart';
import '../providers/providers.dart';
import '../services/demo_data_service.dart'; // fallback for unmigrated parts

final currentPondIdProvider = StateProvider<String>((ref) => 'TN-01-001');

final allPondsProvider = FutureProvider<List<Pond>>((ref) async {
  final repo = ref.watch(pondRepositoryProvider);
  try {
    return await repo.getPonds().timeout(const Duration(seconds: 2));
  } catch (_) {
    return [DemoDataService.pond];
  }
});

final currentPondProvider = FutureProvider<Pond>((ref) async {
  final repo = ref.watch(pondRepositoryProvider);
  final pondId = ref.watch(currentPondIdProvider);
  try {
    return await repo.getPondById(pondId).timeout(const Duration(seconds: 2));
  } catch (_) {
    return DemoDataService.pond;
  }
});

final meProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.getMe().timeout(const Duration(seconds: 2));
    if (res is Map<String, dynamic>) return res;
    return null;
  } catch (_) {
    return null; // Gracefully falls back to DemoDataService.farmer.name in UI
  }
});

final pondRiskProvider = FutureProvider<PondRisk>((ref) async {
  final repo = ref.watch(pondRepositoryProvider);
  final pondId = ref.watch(currentPondIdProvider);
  return await repo.getPondRisk(pondId);
});

final dataQualityProvider = FutureProvider<DataQualitySignal>((ref) async {
  final repo = ref.watch(dataQualityRepositoryProvider);
  return await repo.getDataQuality();
});

final pondEventsProvider = FutureProvider<List<PondEvent>>((ref) async {
  final repo = ref.watch(pondRepositoryProvider);
  final pondId = ref.watch(currentPondIdProvider);
  return await repo.getPondEvents(pondId);
});

final advisoriesProvider = FutureProvider<List<Recommendation>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    return await api.getAdvisories().timeout(const Duration(seconds: 2));
  } catch (_) {
    return DemoDataService.recommendations;
  }
});

// Legacy alias for compatibility
final recommendationsProvider = advisoriesProvider;

final alertsListProvider = FutureProvider<List<AlertItem>>((ref) async {
  final repo = ref.watch(alertRepositoryProvider);
  try {
    return await repo.getAlerts();
  } catch (_) {
    return DemoDataService.alerts;
  }
});

final pondLogsProvider = FutureProvider<List<PondLog>>((ref) async {
  final repo = ref.watch(logRepositoryProvider);
  final pondId = ref.watch(currentPondIdProvider);
  try {
    return await repo.getLogsForPond(pondId);
  } catch (_) {
    return [];
  }
});
