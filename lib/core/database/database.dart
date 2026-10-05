import 'package:drift/drift.dart';
import 'connection/connection.dart' as connection;

part 'database.g.dart';

class PondsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get farmerId => text().nullable()();
  TextColumn get location => text().nullable()();
  RealColumn get areaSqM => real().nullable()();
  RealColumn get depthM => real().nullable()();
  TextColumn get linerType => text().nullable()();
  TextColumn get waterSource => text().nullable()();
  DateTimeColumn get stockingDate => dateTime().nullable()();                                                                                                                                                                                                                                                                                                                                                                                        
  TextColumn get species => text().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))(); // enum PondStatus
  DateTimeColumn get lastUpdated => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get pondId => text()();
  DateTimeColumn get loggedAt => dateTime()();
  RealColumn get feedGivenKg => real().nullable()();
  IntColumn get mortalityCount => integer().nullable()();
  IntColumn get feedTray => integer().nullable()(); // enum FeedTrayStatus
  IntColumn get waterColor => integer().nullable()(); // enum WaterAppearance
  RealColumn get ph => real().nullable()();
  RealColumn get dissolvedOxygen => real().nullable()();
  RealColumn get temperature => real().nullable()();
  RealColumn get salinity => real().nullable()();
  TextColumn get photoUrlsJson => text()(); // JSON string array
  IntColumn get syncStatus => integer()(); // enum SyncStatus
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AlertsTable extends Table {
  TextColumn get id => text()();
  TextColumn get pondId => text().nullable()();
  TextColumn get pondName => text().nullable()();
  TextColumn get alertType => text()();
  TextColumn get severity => text()(); // "high", "warning", "low"
  TextColumn get title => text()();
  TextColumn get message => text()();
  BoolColumn get suppressed => boolean().withDefault(const Constant(false))();
  TextColumn get suppressionReason => text().nullable()();
  BoolColumn get acked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get ackedAt => dateTime().nullable()();
  RealColumn get riskScore => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get feedback => integer().nullable()(); // enum AlertFeedback

  @override
  Set<Column> get primaryKey => {id};
}

class DashboardCacheTable extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get payloadBlob => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

@DriftDatabase(tables: [PondsTable, LogsTable, AlertsTable, DashboardCacheTable])
class OutboxTable extends Table {
  TextColumn get id => text()();
  TextColumn get clientLogId => text()(); // Idempotency key
  TextColumn get entityType => text()(); // 'log', 'media_commit', 'alert_ack', 'alert_feedback'
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, syncing, synced, failed
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalLogsTable extends Table {
  TextColumn get clientLogId => text()(); // Primary key & idempotency key
  TextColumn get pondId => text()();
  DateTimeColumn get loggedAt => dateTime()();
  RealColumn get feedGivenKg => real().nullable()();
  IntColumn get mortalityCount => integer().nullable()();
  IntColumn get feedTray => integer().nullable()(); // enum FeedTrayStatus
  IntColumn get waterColor => integer().nullable()(); // enum WaterAppearance
  RealColumn get ph => real().nullable()();
  RealColumn get dissolvedOxygen => real().nullable()();
  RealColumn get temperature => real().nullable()();
  RealColumn get salinity => real().nullable()();
  TextColumn get photoUrlsJson => text().withDefault(const Constant('[]'))();
  IntColumn get syncStatus => integer().withDefault(const Constant(1))(); // 0=synced, 1=pending, 2=uploading, 3=failed
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {clientLogId};
}

class PendingMediaTable extends Table {
  TextColumn get clientMediaId => text()();
  TextColumn get serverMediaId => text().nullable()();
  TextColumn get localFilePath => text()();
  TextColumn get uploadUrl => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, uploading, uploaded, committed, failed
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get committedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {clientMediaId};
}

class CachedUsersTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text()();
  TextColumn get district => text().nullable()();
  TextColumn get preferredLanguage => text().withDefault(const Constant('ta'))();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  PondsTable,
  LogsTable,
  AlertsTable,
  DashboardCacheTable,
  OutboxTable,
  LocalLogsTable,
  PendingMediaTable,
  CachedUsersTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connection.openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(dashboardCacheTable);
          }
          if (from < 3) {
            await m.createTable(outboxTable);
            await m.createTable(localLogsTable);
            await m.createTable(pendingMediaTable);
            await m.createTable(cachedUsersTable);
          }
          if (from < 4) {
            await m.deleteTable('alerts_table');
            await m.createTable(alertsTable);
          }
        },
      );

  // -- Ponds Queries --
  Future<List<PondsTableData>> getAllPonds() => select(pondsTable).get();
  Future<PondsTableData?> getPondById(String id) =>
      (select(pondsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<void> insertOrUpdatePond(PondsTableCompanion pond) =>
      into(pondsTable).insertOnConflictUpdate(pond);
  Future<void> clearPonds() => delete(pondsTable).go();

  // -- Logs Queries --
  Future<List<LogsTableData>> getLogsForPond(String pondId) {
    return (select(logsTable)
          ..where((t) => t.pondId.equals(pondId))
          ..orderBy([(t) => OrderingTerm(expression: t.loggedAt, mode: OrderingMode.desc)]))
        .get();
  }
  Future<void> insertLog(LogsTableCompanion log) => into(logsTable).insert(log);
  Future<void> updateLogSyncStatus(String id, int syncStatus) {
    return (update(logsTable)..where((t) => t.id.equals(id)))
        .write(LogsTableCompanion(syncStatus: Value(syncStatus)));
  }

  // -- Alerts Queries --
  Future<List<AlertsTableData>> getAllAlerts() {
    return (select(alertsTable)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
  }
  Future<void> insertAlerts(List<AlertsTableCompanion> alerts) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(alertsTable, alerts);
    });
  }
  Future<void> markAlertAcknowledged(String id) {
    return (update(alertsTable)..where((t) => t.id.equals(id))).write(AlertsTableCompanion(
      acked: const Value(true),
      ackedAt: Value(DateTime.now()),
    ));
  }

  // -- Dashboard Cache Queries --
  Future<void> upsertDashboardCache(String key, String blob, DateTime syncedAt) {
    return into(dashboardCacheTable).insertOnConflictUpdate(
      DashboardCacheTableCompanion(
        cacheKey: Value(key),
        payloadBlob: Value(blob),
        syncedAt: Value(syncedAt),
      ),
    );
  }

  Future<DashboardCacheTableData?> getDashboardCache(String key) {
    return (select(dashboardCacheTable)..where((t) => t.cacheKey.equals(key))).getSingleOrNull();
  }

  // -- Outbox Queries --
  Future<List<OutboxTableData>> getPendingOutboxItems() {
    return (select(outboxTable)
          ..where((t) => t.status.equals('pending') | t.status.equals('syncing'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
  }

  Future<void> insertOutboxItem(OutboxTableCompanion item) =>
      into(outboxTable).insertOnConflictUpdate(item);

  Future<void> updateOutboxStatus(String id, String status, {String? error}) {
    return (update(outboxTable)..where((t) => t.id.equals(id))).write(
      OutboxTableCompanion(
        status: Value(status),
        lastError: Value(error),
        syncedAt: status == 'synced' ? Value(DateTime.now()) : const Value.absent(),
      ),
    );
  }

  Future<void> markOutboxSynced(String id) => updateOutboxStatus(id, 'synced');

  Future<void> markOutboxFailed(String id, String error) =>
      updateOutboxStatus(id, 'failed', error: error);

  Future<void> incrementOutboxRetry(String id) async {
    final item = await (select(outboxTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (item != null) {
      await (update(outboxTable)..where((t) => t.id.equals(id))).write(
        OutboxTableCompanion(
          retryCount: Value(item.retryCount + 1),
          status: const Value('pending'),
        ),
      );
    }
  }

  // -- Local Logs Queries --
  Future<List<LocalLogsTableData>> getLocalLogsForPond(String pondId) {
    return (select(localLogsTable)
          ..where((t) => t.pondId.equals(pondId))
          ..orderBy([(t) => OrderingTerm(expression: t.loggedAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<void> insertLocalLog(LocalLogsTableCompanion log) =>
      into(localLogsTable).insertOnConflictUpdate(log);

  Future<void> updateLocalLogSyncStatus(String clientLogId, int syncStatus) {
    return (update(localLogsTable)..where((t) => t.clientLogId.equals(clientLogId)))
        .write(LocalLogsTableCompanion(syncStatus: Value(syncStatus)));
  }

  Future<LocalLogsTableData?> getLocalLogByClientLogId(String clientLogId) {
    return (select(localLogsTable)..where((t) => t.clientLogId.equals(clientLogId))).getSingleOrNull();
  }

  // -- Pending Media Queries --
  Future<void> insertPendingMedia(PendingMediaTableCompanion media) =>
      into(pendingMediaTable).insertOnConflictUpdate(media);

  Future<void> updatePendingMediaStatus(
    String clientMediaId,
    String status, {
    String? serverMediaId,
    String? uploadUrl,
  }) {
    return (update(pendingMediaTable)..where((t) => t.clientMediaId.equals(clientMediaId))).write(
      PendingMediaTableCompanion(
        status: Value(status),
        serverMediaId: serverMediaId != null ? Value(serverMediaId) : const Value.absent(),
        uploadUrl: uploadUrl != null ? Value(uploadUrl) : const Value.absent(),
        committedAt: status == 'committed' ? Value(DateTime.now()) : const Value.absent(),
      ),
    );
  }

  // -- Cached User Queries --
  Future<CachedUsersTableData?> getCachedUser() {
    return (select(cachedUsersTable)..limit(1)).getSingleOrNull();
  }

  Future<void> upsertCachedUser(CachedUsersTableCompanion user) =>
      into(cachedUsersTable).insertOnConflictUpdate(user);

  Future<void> clearCachedUser() => delete(cachedUsersTable).go();
}

