import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aquaverse_farmer_app/core/database/database.dart';
import 'package:aquaverse_farmer_app/core/models/models.dart';
import 'package:aquaverse_farmer_app/core/network/api_client.dart';
import 'package:aquaverse_farmer_app/core/repositories/log_repository.dart';

class MockApiClient implements ApiClient {
  List<Map<String, dynamic>> createdLogs = [];

  @override
  Future<PondLog> createLog(Map<String, dynamic> body) async {
    createdLogs.add(body);
    return PondLog(
      id: 'server-${body['client_log_id']}',
      clientLogId: body['client_log_id'] as String,
      pondId: body['pond_id'] as String,
      loggedAt: DateTime.parse(body['logged_at'] as String),
      feedGivenKg: (body['feed_given_kg'] as num?)?.toDouble(),
      mortalityCount: body['mortality_count'] as int?,
    );
  }

  @override
  Future<LogListResponse> getLogs([String? pondId, String? cursor, int? limit]) async {
    return LogListResponse(
      logs: [],
      nextCursor: null,
      total: 0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late MockApiClient mockApi;
  late LogRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockApi = MockApiClient();
    repo = LogRepository(db, mockApi);
  });

  tearDown(() async {
    await db.close();
  });

  group('LogRepository Unit Tests', () {
    test('creates local log and outbox entry with stable client_log_id', () async {
      final now = DateTime.now();
      const testClientLogId = 'client-uuid-test-123';
      final logEntry = PondLog(
        id: testClientLogId,
        clientLogId: testClientLogId,
        pondId: 'TN-01-001',
        loggedAt: now,
        feedGivenKg: 25.0,
        mortalityCount: 2,
        feedTray: FeedTrayStatus.some,
        waterColor: WaterAppearance.good,
        ph: 7.8,
        dissolvedOxygen: 5.6,
        temperature: 28.2,
        salinity: 15.0,
        notes: 'Morning log check',
      );

      await repo.addLog(logEntry);

      // 1. Check local logs table
      final localLogs = await db.getLocalLogsForPond('TN-01-001');
      expect(localLogs.length, 1);
      final local = localLogs.first;
      expect(local.clientLogId, testClientLogId);
      expect(local.feedGivenKg, 25.0);
      expect(local.mortalityCount, 2);
      expect(local.ph, 7.8);
      expect(local.notes, 'Morning log check');

      // 2. Check outbox table
      final allOutbox = await db.select(db.outboxTable).get();
      expect(allOutbox.length, 1);
      expect(allOutbox.first.clientLogId, testClientLogId);
      expect(allOutbox.first.id, testClientLogId);

      // 3. Check mock API received identical client_log_id
      expect(mockApi.createdLogs.length, 1);
      expect(mockApi.createdLogs.first['client_log_id'], testClientLogId);
      expect(mockApi.createdLogs.first['feed_given_kg'], 25.0);
    });

    test('getLogsForPond merges local pending logs and server logs seamlessly', () async {
      final now = DateTime.now();

      // Insert an un-synced local log
      await db.insertLocalLog(LocalLogsTableCompanion(
        clientLogId: const Value('pending-uuid-1'),
        pondId: const Value('TN-01-001'),
        loggedAt: Value(now),
        feedGivenKg: const Value(15.0),
        mortalityCount: const Value(0),
        photoUrlsJson: const Value('[]'),
        syncStatus: Value(SyncStatus.pending.index),
        createdAt: Value(now),
      ));

      final logs = await repo.getLogsForPond('TN-01-001');
      expect(logs.length, 1);
      expect(logs.first.clientLogId, 'pending-uuid-1');
      expect(logs.first.feedGivenKg, 15.0);
    });
  });
}

