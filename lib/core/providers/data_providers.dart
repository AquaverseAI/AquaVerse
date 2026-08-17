import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/pond_repository.dart';
import '../repositories/log_repository.dart';
import '../repositories/alert_repository.dart';
import '../providers/providers.dart';
import '../services/demo_data_service.dart'; // fallback for unmigrated parts

final currentPondIdProvider = StateProvider<String>((ref) => 'TN-01-001');

final currentPondProvider = FutureProvider<Pond>((ref) async {
  final repo = ref.watch(pondRepositoryProvider);
  final pondId = ref.watch(currentPondIdProvider);
  try {
    return await repo.getPondById(pondId).timeout(const Duration(seconds: 1));
  } catch (_) {
    return DemoDataService.pond;
  }
});

final currentPondParamsProvider = FutureProvider<PondParams>((ref) async {
  // Since PondParams endpoint isn't explicitly in the 17, 
  // we simulate fetching it or fallback. For now, use fallback.
  return DemoDataService.params; 
});

final recommendationsProvider = FutureProvider<List<Recommendation>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    return await api.getAdvisories().timeout(const Duration(seconds: 1));
  } catch (_) {
    return DemoDataService.recommendations;
  }
});

final doForecastProvider = FutureProvider<List<DOForecastPoint>>((ref) async {
  final repo = ref.watch(pondRepositoryProvider);
  final pondId = ref.watch(currentPondIdProvider);
  try {
    return await repo.getDOForecast(pondId).timeout(const Duration(seconds: 1));
  } catch (_) {
    return DemoDataService.doForecast();
  }
});

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
