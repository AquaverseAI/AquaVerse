import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../models/models.dart';
import '../repositories/pond_repository.dart';
import '../repositories/log_repository.dart';
import '../repositories/alert_repository.dart';
import '../repositories/data_quality_repository.dart';
import '../providers/providers.dart';

final currentPondIdProvider = StateProvider<String>((ref) => 'TN-01-001');

final allPondsProvider = FutureProvider<List<Pond>>((ref) async {
  final repo = ref.watch(pondRepositoryProvider);
  try {
    return await repo.getPonds().timeout(const Duration(seconds: 4));
  } catch (_) {
    final dbPonds = await ref.watch(databaseProvider).getAllPonds();
    return dbPonds.map((d) => Pond(
      id: d.id,
      name: d.name,
      farmerId: d.farmerId,
      location: d.location,
      areaSqM: d.areaSqM,
      depthM: d.depthM,
      linerType: d.linerType,
      waterSource: d.waterSource,
      stockingDate: d.stockingDate,
      species: d.species,
      status: PondStatus.values[d.status],
      lastUpdated: d.lastUpdated,
    )).toList();
  }
});

final currentPondProvider = FutureProvider<Pond>((ref) async {
  final repo = ref.watch(pondRepositoryProvider);
  final pondId = ref.watch(currentPondIdProvider);
  try {
    final p = await repo.getPondById(pondId).timeout(const Duration(seconds: 4));
    if (p != null) return p;
  } catch (_) {}

  final dbPonds = await ref.watch(databaseProvider).getAllPonds();
  final matching = dbPonds.where((p) => p.id == pondId);
  if (matching.isNotEmpty) {
    final d = matching.first;
    return Pond(
      id: d.id,
      name: d.name,
      farmerId: d.farmerId,
      location: d.location,
      areaSqM: d.areaSqM,
      depthM: d.depthM,
      linerType: d.linerType,
      waterSource: d.waterSource,
      stockingDate: d.stockingDate,
      species: d.species,
      status: PondStatus.values[d.status],
      lastUpdated: d.lastUpdated,
    );
  }
  return Pond(
    id: pondId,
    name: 'Pond $pondId',
    status: PondStatus.good,
  );
});

final meProvider = FutureProvider<User?>((ref) async {
  final api = ref.watch(apiClientProvider);
  final db = ref.watch(databaseProvider);
  try {
    final user = await api.getMe().timeout(const Duration(seconds: 4));
    await db.upsertCachedUser(CachedUsersTableCompanion(
      id: Value(user.id),
      name: Value(user.name),
      phone: const Value(null),
      role: Value(user.role),
      district: Value(user.district),
      preferredLanguage: const Value('ta'),
      syncedAt: Value(DateTime.now()),
    ));
    return user;
  } catch (_) {
    final cached = await db.getCachedUser();
    if (cached != null) {
      return User(
        sub: cached.id,
        role: cached.role,
        name: cached.name,
        district: cached.district,
      );
    }
    return null;
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
    final res = await api.getAdvisories().timeout(const Duration(seconds: 3));
    return res.advisoryList;
  } catch (_) {
    return const [];
  }
});

// Legacy alias for compatibility
final recommendationsProvider = advisoriesProvider;

final alertsListProvider = FutureProvider<List<AlertItem>>((ref) async {
  final repo = ref.watch(alertRepositoryProvider);
  try {
    return await repo.getAlerts().timeout(const Duration(seconds: 4));
  } catch (_) {
    final cached = await ref.watch(databaseProvider).getAllAlerts();
    return cached.map((d) => AlertItem(
      id: d.id,
      pondId: d.pondId,
      pondName: d.pondName,
      alertType: d.alertType,
      severity: d.severity,
      title: d.title,
      message: d.message,
      suppressed: d.suppressed,
      suppressionReason: d.suppressionReason,
      acked: d.acked,
      ackedAt: d.ackedAt,
      riskScore: d.riskScore,
      createdAt: d.createdAt,
      feedback: d.feedback != null ? AlertFeedback.values[d.feedback!] : null,
    )).toList();
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

// ── Application & Notification Settings Providers ───────────────────────────
final pushNotifProvider = StateProvider<bool>((ref) => true);
final alertPrefProvider = StateProvider<bool>((ref) => true);
final selectedUnitProvider = StateProvider<String>((ref) => 'metric');
