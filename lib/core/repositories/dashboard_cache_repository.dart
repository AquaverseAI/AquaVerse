import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/providers.dart';

class DashboardCacheEntry {
  final String blob;
  final DateTime syncedAt;

  DashboardCacheEntry({required this.blob, required this.syncedAt});
}

class DashboardCacheRepository {
  final AppDatabase db;

  DashboardCacheRepository(this.db);

  Future<void> write(String key, dynamic payload) async {
    try {
      final jsonStr = payload is String ? payload : jsonEncode(payload);
      await db.upsertDashboardCache(key, jsonStr, DateTime.now());
    } catch (_) {}
  }

  Future<DashboardCacheEntry?> read(String key) async {
    try {
      final row = await db.getDashboardCache(key);
      if (row != null) {
        return DashboardCacheEntry(blob: row.payloadBlob, syncedAt: row.syncedAt);
      }
    } catch (_) {}
    return null;
  }
}

final dashboardCacheRepositoryProvider = Provider<DashboardCacheRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DashboardCacheRepository(db);
});
