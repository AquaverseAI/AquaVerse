import 'dart:convert';
import 'package:dio/dio.dart';
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
      final response = await api.getLogs();
      for (final log in response.logList) {
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

    // Fetch server logs + local pending logs
    final serverLogs = await db.getLogsForPond(pondId);
    final localLogs = await db.getLocalLogsForPond(pondId);

    // Map local logs
    final localPondLogs = localLogs.map((d) => PondLog(
      id: d.clientLogId,
      clientLogId: d.clientLogId,
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
    ));

    final serverPondLogs = serverLogs.map((d) => PondLog(
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
    ));

    // Combine avoiding duplicate IDs
    final seenIds = <String>{};
    final combined = <PondLog>[];
    for (final l in [...localPondLogs, ...serverPondLogs]) {
      if (seenIds.add(l.clientLogId ?? l.id)) {
        combined.add(l);
      }
    }
    combined.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return combined;
  }

  Future<void> addLog(PondLog log) async {
    final clientLogId = log.clientLogId ?? log.id;
    final now = DateTime.now();

    // 1. Save to LocalLogsTable (Drift)
    await db.insertLocalLog(LocalLogsTableCompanion(
      clientLogId: Value(clientLogId),
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
      syncStatus: Value(SyncStatus.pending.index),
      notes: Value(log.notes),
      createdAt: Value(now),
    ));

    // Also mirror to legacy LogsTable
    await db.insertLog(LogsTableCompanion(
      id: Value(clientLogId),
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
      syncStatus: Value(SyncStatus.pending.index),
      notes: Value(log.notes),
    ));

    // 2. Queue into persistent OutboxTable
    final payload = {
      'client_log_id': clientLogId,
      'pond_id': log.pondId,
      'logged_at': log.loggedAt.toIso8601String(),
      if (log.feedGivenKg != null) 'feed_given_kg': log.feedGivenKg,
      if (log.mortalityCount != null) 'mortality_count': log.mortalityCount,
      if (log.feedTray != null) 'feed_tray': log.feedTray!.name,
      if (log.waterColor != null) 'water_color': log.waterColor!.name,
      if (log.ph != null) 'ph': log.ph,
      if (log.dissolvedOxygen != null) 'dissolved_oxygen': log.dissolvedOxygen,
      if (log.temperature != null) 'temperature': log.temperature,
      if (log.salinity != null) 'salinity': log.salinity,
      if (log.photoUrls.isNotEmpty) 'photo_urls': log.photoUrls,
      if (log.notes != null) 'notes': log.notes,
    };

    await db.insertOutboxItem(OutboxTableCompanion(
      id: Value(clientLogId),
      clientLogId: Value(clientLogId),
      entityType: const Value('log'),
      payloadJson: Value(jsonEncode(payload)),
      status: const Value('pending'),
      createdAt: Value(now),
    ));

    // 3. Attempt immediate push if online
    await pushPendingLogs();
  }

  Future<void> pushPendingLogs() async {
    final pendingOutbox = await db.getPendingOutboxItems();
    final logItems = pendingOutbox.where((i) => i.entityType == 'log').toList();

    for (final item in logItems) {
      try {
        await db.updateOutboxStatus(item.id, 'syncing');
        await db.updateLocalLogSyncStatus(item.clientLogId, SyncStatus.uploading.index);
        await db.updateLogSyncStatus(item.clientLogId, SyncStatus.uploading.index);

        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
        await api.createLog(payload);

        // Server confirmed
        await db.markOutboxSynced(item.id);
        await db.updateLocalLogSyncStatus(item.clientLogId, SyncStatus.synced.index);
        await db.updateLogSyncStatus(item.clientLogId, SyncStatus.synced.index);
      } on DioException catch (e) {
        if (e.response?.statusCode == 409) {
          // Idempotency: duplicate entry already exists on server, treat as success!
          await db.markOutboxSynced(item.id);
          await db.updateLocalLogSyncStatus(item.clientLogId, SyncStatus.synced.index);
          await db.updateLogSyncStatus(item.clientLogId, SyncStatus.synced.index);
        } else if (e.response != null && e.response!.statusCode! >= 400 && e.response!.statusCode! < 500) {
          // Client validation error - mark failed
          await db.markOutboxFailed(item.id, e.message ?? 'Validation error');
          await db.updateLocalLogSyncStatus(item.clientLogId, SyncStatus.failed.index);
          await db.updateLogSyncStatus(item.clientLogId, SyncStatus.failed.index);
        } else {
          // Network / Server error - keep pending, increment retry
          await db.incrementOutboxRetry(item.id);
          await db.updateLocalLogSyncStatus(item.clientLogId, SyncStatus.pending.index);
          await db.updateLogSyncStatus(item.clientLogId, SyncStatus.pending.index);
        }
      } catch (_) {
        await db.incrementOutboxRetry(item.id);
        await db.updateLocalLogSyncStatus(item.clientLogId, SyncStatus.pending.index);
        await db.updateLogSyncStatus(item.clientLogId, SyncStatus.pending.index);
      }
    }
  }
}

final logRepositoryProvider = Provider<LogRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  return LogRepository(db, api);
});
