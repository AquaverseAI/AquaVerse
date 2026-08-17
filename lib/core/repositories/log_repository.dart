import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../providers/providers.dart';

class LogRepository {
  final AppDatabase db;
  final ApiClient api;

  LogRepository(this.db, this.api);

  Future<void> syncLogs() async {
    try {
      final logs = await api.getLogs();
      for (final log in logs) {
        await db.insertLog(LogsTableCompanion(
          id: Value(log.id),
          pondId: Value(log.pondId),
          loggedAt: Value(log.loggedAt),
          feedGivenKg: Value(log.feedGivenKg),
          mortalityCount: Value(log.mortalityCount),
          feedTray: Value(log.feedTray?.index),
          waterColor: Value(log.waterColor?.index),
          ph: Value(log.ph),
          dissolvedOxygen: Value(log.dissolvedOxygen),
          temperature: Value(log.temperature),
          salinity: Value(log.salinity),
          photoUrlsJson: Value(jsonEncode(log.photoUrls)),
          syncStatus: Value(SyncStatus.synced.index),
          notes: Value(log.notes),
        ));
      }
    } catch (_) {}
  }

  Future<List<PondLog>> getLogsForPond(String pondId) async {
    await syncLogs();
    
    // Attempt to push any pending logs
    await pushPendingLogs();

    final data = await db.getLogsForPond(pondId);
    return data.map((d) => PondLog(
      id: d.id,
      pondId: d.pondId,
      loggedAt: d.loggedAt,
      feedGivenKg: d.feedGivenKg,
      mortalityCount: d.mortalityCount,
      feedTray: d.feedTray != null ? FeedTrayStatus.values[d.feedTray!] : null,
      waterColor: d.waterColor != null ? WaterAppearance.values[d.waterColor!] : null,
      ph: d.ph,
      dissolvedOxygen: d.dissolvedOxygen,
      temperature: d.temperature,
      salinity: d.salinity,
      photoUrls: List<String>.from(jsonDecode(d.photoUrlsJson)),
      syncStatus: SyncStatus.values[d.syncStatus],
      notes: d.notes,
    )).toList();
  }

  Future<void> addLog(PondLog log) async {
    // 1. Save to local DB first (Offline-first approach)
    await db.insertLog(LogsTableCompanion(
      id: Value(log.id),
      pondId: Value(log.pondId),
      loggedAt: Value(log.loggedAt),
      feedGivenKg: Value(log.feedGivenKg),
      mortalityCount: Value(log.mortalityCount),
      feedTray: Value(log.feedTray?.index),
      waterColor: Value(log.waterColor?.index),
      ph: Value(log.ph),
      dissolvedOxygen: Value(log.dissolvedOxygen),
      temperature: Value(log.temperature),
      salinity: Value(log.salinity),
      photoUrlsJson: Value(jsonEncode(log.photoUrls)),
      syncStatus: Value(SyncStatus.pending.index), // Mark as pending
      notes: Value(log.notes),
    ));

    // 2. Try pushing to server immediately
    await pushPendingLogs();
  }

  Future<void> pushPendingLogs() async {
    // Note: For simplicity, we assume we fetch all logs and find pending ones
    // In a real app we'd have a specific query for this
    final allLogs = await db.select(db.logsTable).get();
    final pendingLogs = allLogs.where((l) => l.syncStatus == SyncStatus.pending.index).toList();

    for (final pending in pendingLogs) {
      try {
        final log = PondLog(
          id: pending.id,
          pondId: pending.pondId,
          loggedAt: pending.loggedAt,
          feedGivenKg: pending.feedGivenKg,
          mortalityCount: pending.mortalityCount,
          feedTray: pending.feedTray != null ? FeedTrayStatus.values[pending.feedTray!] : null,
          waterColor: pending.waterColor != null ? WaterAppearance.values[pending.waterColor!] : null,
          ph: pending.ph,
          dissolvedOxygen: pending.dissolvedOxygen,
          temperature: pending.temperature,
          salinity: pending.salinity,
          photoUrls: List<String>.from(jsonDecode(pending.photoUrlsJson)),
          syncStatus: SyncStatus.synced,
          notes: pending.notes,
        );

        await db.updateLogSyncStatus(pending.id, SyncStatus.uploading.index);
        await api.createLog(log);
        await db.updateLogSyncStatus(pending.id, SyncStatus.synced.index);
      } catch (e) {
        await db.updateLogSyncStatus(pending.id, SyncStatus.failed.index);
      }
    }
  }
}

final logRepositoryProvider = Provider<LogRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  return LogRepository(db, api);
});
