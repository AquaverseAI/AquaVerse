import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../providers/providers.dart';

class PondRepository {
  final AppDatabase db;
  final ApiClient api;

  PondRepository(this.db, this.api);

  Future<void> syncPonds() async {
    try {
      final ponds = await api.getPonds();
      for (final p in ponds) {
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
    } catch (e) {
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

  Future<Pond> getPondById(String pondId) async {
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

  Future<dynamic> getPondRisk(String pondId) async {
    return api.getPondRisk(pondId); // Not cached in DB for now, purely real-time
  }

  Future<List<DOForecastPoint>> getDOForecast(String pondId) async {
    return api.getDOForecast(pondId); // Purely real-time data
  }
}

final pondRepositoryProvider = Provider<PondRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  return PondRepository(db, api);
});
