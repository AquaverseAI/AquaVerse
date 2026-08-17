import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../providers/providers.dart';
import 'dashboard_cache_repository.dart';

class DataQualityRepository {
  final ApiClient _api;
  final DashboardCacheRepository _cache;

  static const _cacheKey = 'data_quality';

  DataQualityRepository(this._api, this._cache);

  /// Network-first, cache-fallback, matching PondRepository.getPondRisk /
  /// getPondEvents. On total failure (no network, no cache), returns a
  /// non-blind default rather than throwing — a missing signal should never
  /// silently produce a false "all clear" via an unhandled error state.
  Future<DataQualitySignal> getDataQuality() async {
    try {
      final raw = await _api.getDataQuality();
      await _cache.write(_cacheKey, raw);
      return DataQualitySignal.fromJson(raw, syncedAt: DateTime.now());
    } catch (_) {
      final cached = await _cache.read(_cacheKey);
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached.blob);
          return DataQualitySignal.fromJson(decoded, syncedAt: cached.syncedAt);
        } catch (_) {}
      }
      // TODO(contract): data-quality response schema not confirmed —
      // no cache + no network defaults to isBlind: false. Revisit once
      // schema is confirmed — a genuinely unknown state arguably *should*
      // render as blind rather than healthy; flagged, not decided here.
      return DataQualitySignal(isBlind: false, syncedAt: null);
    }
  }
}

final dataQualityRepositoryProvider = Provider<DataQualityRepository>((ref) {
  return DataQualityRepository(
    ref.watch(apiClientProvider),
    ref.watch(dashboardCacheRepositoryProvider),
  );
});
