import 'package:drift/drift.dart';
import 'connection/connection.dart' as connection;

part 'database.g.dart';

class PondsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get farmerId => text()();
  TextColumn get location => text()();
  RealColumn get areaSqM => real()();
  RealColumn get depthM => real()();
  TextColumn get linerType => text()();
  TextColumn get waterSource => text()();
  DateTimeColumn get stockingDate => dateTime()();
  TextColumn get species => text()();
  IntColumn get status => integer()(); // enum PondStatus
  DateTimeColumn get lastUpdated => dateTime()();

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
  IntColumn get severity => integer()(); // enum AlertSeverity
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get what => text()();
  TextColumn get why => text()();
  TextColumn get action => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();
  IntColumn get feedback => integer().nullable()(); // enum AlertFeedback
  BoolColumn get isLowConfidence => boolean().withDefault(const Constant(false))();
  BoolColumn get hasSuppressionReason => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [PondsTable, LogsTable, AlertsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connection.openConnection());

  @override
  int get schemaVersion => 1;

  // -- Ponds Queries --
  Future<List<PondsTableData>> getAllPonds() => select(pondsTable).get();
  Future<PondsTableData> getPondById(String id) => (select(pondsTable)..where((t) => t.id.equals(id))).getSingle();
  Future<void> insertOrUpdatePond(PondsTableCompanion pond) => into(pondsTable).insertOnConflictUpdate(pond);
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
    return (update(logsTable)..where((t) => t.id.equals(id))).write(LogsTableCompanion(syncStatus: Value(syncStatus)));
  }

  // -- Alerts Queries --
  Future<List<AlertsTableData>> getAllAlerts() {
    return (select(alertsTable)..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)])).get();
  }
  Future<void> insertAlerts(List<AlertsTableCompanion> alerts) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(alertsTable, alerts);
    });
  }
  Future<void> markAlertAcknowledged(String id) {
    return (update(alertsTable)..where((t) => t.id.equals(id))).write(const AlertsTableCompanion(acknowledged: Value(true)));
  }
}
