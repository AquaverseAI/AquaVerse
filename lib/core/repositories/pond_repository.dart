import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../providers/providers.dart';
import 'dashboard_cache_repository.dart';

class PondRepository {
  final AppDatabase db;
  final ApiClient api;
  final DashboardCacheRepository cache;

  PondRepository(this.db, this.api, this.cache);

  Future<void> syncPonds() async {
    try {
      final response = await api.getPonds();
      for (final p in response.pondList) {
        await db.insertOrUpdatePond(PondsTableCompanion(
          id: Value(p.id),
          name: Value(p.name),
          farmerId: Value(p.farmerId),
          location: Value(p.location),
          areaSqM: Value(p.areaSqM),
          depthM: Value(p.depthM),
          linerType: Value(p.linerType),
          waterSource: Value(p.waterSource),
          stockingDate: Value(p.stockingDate),
          species: Value(p.species),
          status: Value(p.status.index),
          lastUpdated: Value(p.lastUpdated),
        ));
      }
    } catch (_) {
      // Offline or error — fallback to local Drift data implicitly
    }
  }

  Future<List<Pond>> getPonds() async {
    await syncPonds();
    final data = await db.getAllPonds();
    return data.map((d) => Pond(
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

  Future<Pond?> getPondById(String pondId) async {
    try {
      final p = await api.getPondDetails(pondId);
      await db.insertOrUpdatePond(PondsTableCompanion(
        id: Value(p.id),
        name: Value(p.name),
        farmerId: Value(p.farmerId),
        location: Value(p.location),
        areaSqM: Value(p.areaSqM),
        depthM: Value(p.depthM),
        linerType: Value(p.linerType),
        waterSource: Value(p.waterSource),
        stockingDate: Value(p.stockingDate),
        species: Value(p.species),
        status: Value(p.status.index),
        lastUpdated: Value(p.lastUpdated),
      ));
    } catch (_) {}

    final d = await db.getPondById(pondId);
    if (d == null) return null;
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

  Future<PondRisk> getPondRisk(String pondId) async {
    final key = 'risk_$pondId';
    try {
      final raw = await api.getPondRisk(pondId);
      await cache.write(key, raw.toJson());
      return raw;
    } catch (_) {
      final cached = await cache.read(key);
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached.blob) as Map<String, dynamic>;
          return PondRisk.fromJson(decoded);
        } catch (_) {}
      }
      return const PondRisk(tier: 'low');
    }
  }

  Future<List<PondEvent>> getPondEvents(String pondId) async {
    final key = 'events_$pondId';
    try {
      final response = await api.getPondEvents(pondId);
      final events = response.items;
      await cache.write(key, events.map((e) => e.toJson()).toList());
      return events;
    } catch (_) {
      final cached = await cache.read(key);
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached.blob);
          if (decoded is List) {
            return decoded.map((e) => PondEvent.fromJson(e as Map<String, dynamic>)).toList();
          }
        } catch (_) {}
      }
      return [];
    }
  }
}

final pondRepositoryProvider = Provider<PondRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  final cache = ref.watch(dashboardCacheRepositoryProvider);
  return PondRepository(db, api, cache);
});
