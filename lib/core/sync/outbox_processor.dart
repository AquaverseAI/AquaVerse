import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../providers/providers.dart';

class OutboxProcessor {
  final AppDatabase db;
  final ApiClient api;
  bool _isProcessing = false;

  OutboxProcessor({required this.db, required this.api});

  /// Processes all pending items in the outbox table.
  /// Idempotent: client_log_id is NEVER regenerated across retries.
  /// HTTP 409 Conflict is treated as a confirmed sync.
  Future<void> syncOutbox() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final pendingItems = await db.getPendingOutboxItems();
      if (pendingItems.isEmpty) {
        _isProcessing = false;
        return;
      }

      debugPrint('🔄 [Outbox] Processing ${pendingItems.length} pending items...');

      for (final item in pendingItems) {
        try {
          await db.updateOutboxStatus(item.id, 'syncing');

          switch (item.entityType) {
            case 'log':
              await _processLogItem(item);
              break;
            case 'alert_ack':
              await _processAlertAckItem(item);
              break;
            case 'alert_feedback':
              await _processAlertFeedbackItem(item);
              break;
            case 'media_commit':
              await _processMediaCommitItem(item);
              break;
            default:
              debugPrint('⚠️ [Outbox] Unknown entity type: ${item.entityType}');
              await db.markOutboxFailed(item.id, 'Unknown entity type');
          }
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 409) {
            // Idempotent success: record already exists on server
            debugPrint('✅ [Outbox] 409 Conflict treated as synced for item: ${item.id}');
            await _markItemSynced(item);
          } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
            // Validation / client error
            debugPrint('❌ [Outbox] Validation error ${e.message} for item: ${item.id}');
            await db.markOutboxFailed(item.id, e.message ?? 'Validation error ($statusCode)');
            if (item.entityType == 'log') {
              await db.updateLocalLogSyncStatus(item.clientLogId, SyncStatus.failed.index);
              await db.updateLogSyncStatus(item.clientLogId, SyncStatus.failed.index);
            }
          } else {
            // Network or server error - keep pending, increment retry
            debugPrint('⏳ [Outbox] Network error, will retry item: ${item.id}');
            await db.incrementOutboxRetry(item.id);
          }
        } catch (e) {
          debugPrint('⏳ [Outbox] Unexpected error $e, will retry item: ${item.id}');
          await db.incrementOutboxRetry(item.id);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processLogItem(OutboxTableData item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    await api.createLog(payload);
    await _markItemSynced(item);
  }

  Future<void> _processAlertAckItem(OutboxTableData item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    final alertId = payload['alert_id'] as String;
    await api.ackAlert(alertId);
    await db.markOutboxSynced(item.id);
  }

  Future<void> _processAlertFeedbackItem(OutboxTableData item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    final alertId = payload['alert_id'] as String;
    await api.sendAlertFeedback(alertId, {
      'useful': payload['useful'] ?? true,
      'false_positive': payload['false_positive'] ?? false,
    });
    await db.markOutboxSynced(item.id);
  }

  Future<void> _processMediaCommitItem(OutboxTableData item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    final mediaId = payload['media_id'] as String;
    await api.commitMedia(mediaId);
    await db.markOutboxSynced(item.id);
  }

  Future<void> _markItemSynced(OutboxTableData item) async {
    await db.markOutboxSynced(item.id);
    if (item.entityType == 'log') {
      await db.updateLocalLogSyncStatus(item.clientLogId, SyncStatus.synced.index);
      await db.updateLogSyncStatus(item.clientLogId, SyncStatus.synced.index);
    }
  }
}

final outboxProcessorProvider = Provider<OutboxProcessor>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  return OutboxProcessor(db: db, api: api);
});
