import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquaverse_farmer_app/core/database/database.dart';
import 'package:aquaverse_farmer_app/core/models/models.dart';
import 'package:aquaverse_farmer_app/core/network/api_client.dart';
import 'package:aquaverse_farmer_app/core/sync/outbox_processor.dart';

class FakeSuccessApiClient implements ApiClient {
  int createLogCalls = 0;
  int ackAlertCalls = 0;
  int feedbackCalls = 0;
  int commitMediaCalls = 0;

  @override
  Future<PondLog> createLog(Map<String, dynamic> body) async {
    createLogCalls++;
    return PondLog(
      id: 'srv-${body['client_log_id']}',
      clientLogId: body['client_log_id'] as String,
      pondId: body['pond_id'] as String,
      loggedAt: DateTime.parse(body['logged_at'] as String),
    );
  }

  @override
  Future<AlertAckOut> ackAlert(String alertId, [AlertAckIn body = const AlertAckIn()]) async {
    ackAlertCalls++;
    return AlertAckOut(
      alertId: alertId,
      acked: true,
      ackedAt: DateTime.now(),
      message: 'OK',
    );
  }

  @override
  Future<AlertFeedbackOut> sendAlertFeedback(String alertId, Map<String, dynamic> body) async {
    feedbackCalls++;
    return AlertFeedbackOut(
      alertId: alertId,
      feedbackRecorded: true,
      message: 'OK',
    );
  }

  @override
  Future<MediaCommitResponse> commitMedia(String mediaId) async {
    commitMediaCalls++;
    return MediaCommitResponse(mediaId: mediaId, status: 'committed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeConflictApiClient implements ApiClient {
  @override
  Future<PondLog> createLog(Map<String, dynamic> body) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/v1/logs'),
      response: Response(
        requestOptions: RequestOptions(path: '/v1/logs'),
        statusCode: 409,
        statusMessage: 'Conflict - Record already exists',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNetworkErrorApiClient implements ApiClient {
  @override
  Future<PondLog> createLog(Map<String, dynamic> body) async {
    throw DioException(
      requestOptions: RequestOptions(path: '/v1/logs'),
      type: DioExceptionType.connectionTimeout,
      message: 'Connection timed out',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('OutboxProcessor Unit Tests', () {
    test('successfully processes pending log item and marks synced', () async {
      final fakeApi = FakeSuccessApiClient();
      final processor = OutboxProcessor(db: db, api: fakeApi);

      const clientLogId = 'test-uuid-001';
      final now = DateTime.now();

      // Insert local log and outbox entry
      await db.insertLocalLog(LocalLogsTableCompanion(
        clientLogId: const Value(clientLogId),
        pondId: const Value('TN-01-001'),
        loggedAt: Value(now),
        syncStatus: Value(SyncStatus.pending.index),
        createdAt: Value(now),
      ));

      await db.insertOutboxItem(OutboxTableCompanion(
        id: const Value(clientLogId),
        clientLogId: const Value(clientLogId),
        entityType: const Value('log'),
        payloadJson: Value(jsonEncode({
          'client_log_id': clientLogId,
          'pond_id': 'TN-01-001',
          'logged_at': now.toIso8601String(),
        })),
        createdAt: Value(now),
        status: const Value('pending'),
      ));

      expect((await db.getPendingOutboxItems()).length, 1);

      await processor.syncOutbox();

      expect(fakeApi.createLogCalls, 1);
      expect((await db.getPendingOutboxItems()).isEmpty, true);

      final localLog = await db.getLocalLogByClientLogId(clientLogId);
      expect(localLog?.syncStatus, SyncStatus.synced.index);
    });

    test('HTTP 409 Conflict is treated as a confirmed sync (idempotency)', () async {
      final conflictApi = FakeConflictApiClient();
      final processor = OutboxProcessor(db: db, api: conflictApi);

      const clientLogId = 'test-uuid-conflict';
      final now = DateTime.now();

      await db.insertLocalLog(LocalLogsTableCompanion(
        clientLogId: const Value(clientLogId),
        pondId: const Value('TN-01-001'),
        loggedAt: Value(now),
        syncStatus: Value(SyncStatus.pending.index),
        createdAt: Value(now),
      ));

      await db.insertOutboxItem(OutboxTableCompanion(
        id: const Value(clientLogId),
        clientLogId: const Value(clientLogId),
        entityType: const Value('log'),
        payloadJson: Value(jsonEncode({
          'client_log_id': clientLogId,
          'pond_id': 'TN-01-001',
          'logged_at': now.toIso8601String(),
        })),
        createdAt: Value(now),
        status: const Value('pending'),
      ));

      // Execute sync — server returns 409 Conflict
      await processor.syncOutbox();

      // Outbox item should be marked synced, not pending, not failed
      expect((await db.getPendingOutboxItems()).isEmpty, true);

      final localLog = await db.getLocalLogByClientLogId(clientLogId);
      expect(localLog?.syncStatus, SyncStatus.synced.index);
    });

    test('network error keeps outbox item pending and increments retry count', () async {
      final networkErrorApi = FakeNetworkErrorApiClient();
      final processor = OutboxProcessor(db: db, api: networkErrorApi);

      const clientLogId = 'test-uuid-retry';
      final now = DateTime.now();

      await db.insertOutboxItem(OutboxTableCompanion(
        id: const Value(clientLogId),
        clientLogId: const Value(clientLogId),
        entityType: const Value('log'),
        payloadJson: Value(jsonEncode({
          'client_log_id': clientLogId,
          'pond_id': 'TN-01-001',
          'logged_at': now.toIso8601String(),
        })),
        createdAt: Value(now),
        status: const Value('pending'),
      ));

      await processor.syncOutbox();

      final pending = await db.getPendingOutboxItems();
      expect(pending.length, 1);
      expect(pending.first.retryCount, 1);
      expect(pending.first.status, 'pending');
    });

    test('successfully processes alert_ack and alert_feedback outbox items', () async {
      final fakeApi = FakeSuccessApiClient();
      final processor = OutboxProcessor(db: db, api: fakeApi);

      await db.insertOutboxItem(OutboxTableCompanion(
        id: const Value('alert-1'),
        clientLogId: const Value('alert-1'),
        entityType: const Value('alert_ack'),
        payloadJson: Value(jsonEncode({'alert_id': 'alert-1'})),
        createdAt: Value(DateTime.now()),
        status: const Value('pending'),
      ));

      await db.insertOutboxItem(OutboxTableCompanion(
        id: const Value('alert-2-feedback'),
        clientLogId: const Value('alert-2-feedback'),
        entityType: const Value('alert_feedback'),
        payloadJson: Value(jsonEncode({'alert_id': 'alert-2', 'feedback': 'correct'})),
        createdAt: Value(DateTime.now()),
        status: const Value('pending'),
      ));

      await processor.syncOutbox();

      expect(fakeApi.ackAlertCalls, 1);
      expect(fakeApi.feedbackCalls, 1);
      expect((await db.getPendingOutboxItems()).isEmpty, true);
    });
  });
}
