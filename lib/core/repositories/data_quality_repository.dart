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

  /// Network-first, cache-fallback, matching PondRepository.getPondRisk / getPondEvents.
  /// Safety Rule R5: An unknown/uncached state MUST NOT masquerade as "all clear".
  /// If both network and local cache miss, returns isBlind: true to protect the farmer.
  Future<DataQualitySignal> getDataQuality() async {
    try {
      final res = await _api.getDataQuality();
      await _cache.write(_cacheKey, res.toJson());
      return res;
    } catch (_) {
      final cached = await _cache.read(_cacheKey);
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached.blob) as Map<String, dynamic>;
          return DataQualitySignal.fromJson(decoded);
        } catch (_) {}
      }
      // Safety Rule R5: Total miss (no network + no cache) defaults to BLIND state
      // rather than a false "healthy" signal.
      return const DataQualitySignal(
        isBlind: true,
        suppressionReason: 'No cached data available. Connect to network to verify pond health.',
      );
    }
  }
}

final dataQualityRepositoryProvider = Provider<DataQualityRepository>((ref) {
  return DataQualityRepository(
    ref.watch(apiClientProvider),
    ref.watch(dashboardCacheRepositoryProvider),
  );
});
