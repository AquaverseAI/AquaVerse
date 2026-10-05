// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PondsTableTable extends PondsTable
    with TableInfo<$PondsTableTable, PondsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PondsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _farmerIdMeta = const VerificationMeta(
    'farmerId',
  );
  @override
  late final GeneratedColumn<String> farmerId = GeneratedColumn<String>(
    'farmer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaSqMMeta = const VerificationMeta(
    'areaSqM',
  );
  @override
  late final GeneratedColumn<double> areaSqM = GeneratedColumn<double>(
    'area_sq_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _depthMMeta = const VerificationMeta('depthM');
  @override
  late final GeneratedColumn<double> depthM = GeneratedColumn<double>(
    'depth_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linerTypeMeta = const VerificationMeta(
    'linerType',
  );
  @override
  late final GeneratedColumn<String> linerType = GeneratedColumn<String>(
    'liner_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterSourceMeta = const VerificationMeta(
    'waterSource',
  );
  @override
  late final GeneratedColumn<String> waterSource = GeneratedColumn<String>(
    'water_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockingDateMeta = const VerificationMeta(
    'stockingDate',
  );
  @override
  late final GeneratedColumn<DateTime> stockingDate = GeneratedColumn<DateTime>(
    'stocking_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speciesMeta = const VerificationMeta(
    'species',
  );
  @override
  late final GeneratedColumn<String> species = GeneratedColumn<String>(
    'species',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    farmerId,
    location,
    areaSqM,
    depthM,
    linerType,
    waterSource,
    stockingDate,
    species,
    status,
    lastUpdated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ponds_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PondsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('farmer_id')) {
      context.handle(
        _farmerIdMeta,
        farmerId.isAcceptableOrUnknown(data['farmer_id']!, _farmerIdMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('area_sq_m')) {
      context.handle(
        _areaSqMMeta,
        areaSqM.isAcceptableOrUnknown(data['area_sq_m']!, _areaSqMMeta),
      );
    }
    if (data.containsKey('depth_m')) {
      context.handle(
        _depthMMeta,
        depthM.isAcceptableOrUnknown(data['depth_m']!, _depthMMeta),
      );
    }
    if (data.containsKey('liner_type')) {
      context.handle(
        _linerTypeMeta,
        linerType.isAcceptableOrUnknown(data['liner_type']!, _linerTypeMeta),
      );
    }
    if (data.containsKey('water_source')) {
      context.handle(
        _waterSourceMeta,
        waterSource.isAcceptableOrUnknown(
          data['water_source']!,
          _waterSourceMeta,
        ),
      );
    }
    if (data.containsKey('stocking_date')) {
      context.handle(
        _stockingDateMeta,
        stockingDate.isAcceptableOrUnknown(
          data['stocking_date']!,
          _stockingDateMeta,
        ),
      );
    }
    if (data.containsKey('species')) {
      context.handle(
        _speciesMeta,
        species.isAcceptableOrUnknown(data['species']!, _speciesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PondsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PondsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      farmerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}farmer_id'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      areaSqM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}area_sq_m'],
      ),
      depthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}depth_m'],
      ),
      linerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}liner_type'],
      ),
      waterSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}water_source'],
      ),
      stockingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stocking_date'],
      ),
      species: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}species'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      ),
    );
  }

  @override
  $PondsTableTable createAlias(String alias) {
    return $PondsTableTable(attachedDatabase, alias);
  }
}

class PondsTableData extends DataClass implements Insertable<PondsTableData> {
  final String id;
  final String name;
  final String? farmerId;
  final String? location;
  final double? areaSqM;
  final double? depthM;
  final String? linerType;
  final String? waterSource;
  final DateTime? stockingDate;
  final String? species;
  final int status;
  final DateTime? lastUpdated;
  const PondsTableData({
    required this.id,
    required this.name,
    this.farmerId,
    this.location,
    this.areaSqM,
    this.depthM,
    this.linerType,
    this.waterSource,
    this.stockingDate,
    this.species,
    required this.status,
    this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || farmerId != null) {
      map['farmer_id'] = Variable<String>(farmerId);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || areaSqM != null) {
      map['area_sq_m'] = Variable<double>(areaSqM);
    }
    if (!nullToAbsent || depthM != null) {
      map['depth_m'] = Variable<double>(depthM);
    }
    if (!nullToAbsent || linerType != null) {
      map['liner_type'] = Variable<String>(linerType);
    }
    if (!nullToAbsent || waterSource != null) {
      map['water_source'] = Variable<String>(waterSource);
    }
    if (!nullToAbsent || stockingDate != null) {
      map['stocking_date'] = Variable<DateTime>(stockingDate);
    }
    if (!nullToAbsent || species != null) {
      map['species'] = Variable<String>(species);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  PondsTableCompanion toCompanion(bool nullToAbsent) {
    return PondsTableCompanion(
      id: Value(id),
      name: Value(name),
      farmerId: farmerId == null && nullToAbsent
          ? const Value.absent()
          : Value(farmerId),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      areaSqM: areaSqM == null && nullToAbsent
          ? const Value.absent()
          : Value(areaSqM),
      depthM: depthM == null && nullToAbsent
          ? const Value.absent()
          : Value(depthM),
      linerType: linerType == null && nullToAbsent
          ? const Value.absent()
          : Value(linerType),
      waterSource: waterSource == null && nullToAbsent
          ? const Value.absent()
          : Value(waterSource),
      stockingDate: stockingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(stockingDate),
      species: species == null && nullToAbsent
          ? const Value.absent()
          : Value(species),
      status: Value(status),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory PondsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PondsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      farmerId: serializer.fromJson<String?>(json['farmerId']),
      location: serializer.fromJson<String?>(json['location']),
      areaSqM: serializer.fromJson<double?>(json['areaSqM']),
      depthM: serializer.fromJson<double?>(json['depthM']),
      linerType: serializer.fromJson<String?>(json['linerType']),
      waterSource: serializer.fromJson<String?>(json['waterSource']),
      stockingDate: serializer.fromJson<DateTime?>(json['stockingDate']),
      species: serializer.fromJson<String?>(json['species']),
      status: serializer.fromJson<int>(json['status']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'farmerId': serializer.toJson<String?>(farmerId),
      'location': serializer.toJson<String?>(location),
      'areaSqM': serializer.toJson<double?>(areaSqM),
      'depthM': serializer.toJson<double?>(depthM),
      'linerType': serializer.toJson<String?>(linerType),
      'waterSource': serializer.toJson<String?>(waterSource),
      'stockingDate': serializer.toJson<DateTime?>(stockingDate),
      'species': serializer.toJson<String?>(species),
      'status': serializer.toJson<int>(status),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  PondsTableData copyWith({
    String? id,
    String? name,
    Value<String?> farmerId = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<double?> areaSqM = const Value.absent(),
    Value<double?> depthM = const Value.absent(),
    Value<String?> linerType = const Value.absent(),
    Value<String?> waterSource = const Value.absent(),
    Value<DateTime?> stockingDate = const Value.absent(),
    Value<String?> species = const Value.absent(),
    int? status,
    Value<DateTime?> lastUpdated = const Value.absent(),
  }) => PondsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    farmerId: farmerId.present ? farmerId.value : this.farmerId,
    location: location.present ? location.value : this.location,
    areaSqM: areaSqM.present ? areaSqM.value : this.areaSqM,
    depthM: depthM.present ? depthM.value : this.depthM,
    linerType: linerType.present ? linerType.value : this.linerType,
    waterSource: waterSource.present ? waterSource.value : this.waterSource,
    stockingDate: stockingDate.present ? stockingDate.value : this.stockingDate,
    species: species.present ? species.value : this.species,
    status: status ?? this.status,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
  );
  PondsTableData copyWithCompanion(PondsTableCompanion data) {
    return PondsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      farmerId: data.farmerId.present ? data.farmerId.value : this.farmerId,
      location: data.location.present ? data.location.value : this.location,
      areaSqM: data.areaSqM.present ? data.areaSqM.value : this.areaSqM,
      depthM: data.depthM.present ? data.depthM.value : this.depthM,
      linerType: data.linerType.present ? data.linerType.value : this.linerType,
      waterSource: data.waterSource.present
          ? data.waterSource.value
          : this.waterSource,
      stockingDate: data.stockingDate.present
          ? data.stockingDate.value
          : this.stockingDate,
      species: data.species.present ? data.species.value : this.species,
      status: data.status.present ? data.status.value : this.status,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PondsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('farmerId: $farmerId, ')
          ..write('location: $location, ')
          ..write('areaSqM: $areaSqM, ')
          ..write('depthM: $depthM, ')
          ..write('linerType: $linerType, ')
          ..write('waterSource: $waterSource, ')
          ..write('stockingDate: $stockingDate, ')
          ..write('species: $species, ')
          ..write('status: $status, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    farmerId,
    location,
    areaSqM,
    depthM,
    linerType,
    waterSource,
    stockingDate,
    species,
    status,
    lastUpdated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PondsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.farmerId == this.farmerId &&
          other.location == this.location &&
          other.areaSqM == this.areaSqM &&
          other.depthM == this.depthM &&
          other.linerType == this.linerType &&
          other.waterSource == this.waterSource &&
          other.stockingDate == this.stockingDate &&
          other.species == this.species &&
          other.status == this.status &&
          other.lastUpdated == this.lastUpdated);
}

class PondsTableCompanion extends UpdateCompanion<PondsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> farmerId;
  final Value<String?> location;
  final Value<double?> areaSqM;
  final Value<double?> depthM;
  final Value<String?> linerType;
  final Value<String?> waterSource;
  final Value<DateTime?> stockingDate;
  final Value<String?> species;
  final Value<int> status;
  final Value<DateTime?> lastUpdated;
  final Value<int> rowid;
  const PondsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.farmerId = const Value.absent(),
    this.location = const Value.absent(),
    this.areaSqM = const Value.absent(),
    this.depthM = const Value.absent(),
    this.linerType = const Value.absent(),
    this.waterSource = const Value.absent(),
    this.stockingDate = const Value.absent(),
    this.species = const Value.absent(),
    this.status = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PondsTableCompanion.insert({
    required String id,
    required String name,
    this.farmerId = const Value.absent(),
    this.location = const Value.absent(),
    this.areaSqM = const Value.absent(),
    this.depthM = const Value.absent(),
    this.linerType = const Value.absent(),
    this.waterSource = const Value.absent(),
    this.stockingDate = const Value.absent(),
    this.species = const Value.absent(),
    this.status = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<PondsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? farmerId,
    Expression<String>? location,
    Expression<double>? areaSqM,
    Expression<double>? depthM,
    Expression<String>? linerType,
    Expression<String>? waterSource,
    Expression<DateTime>? stockingDate,
    Expression<String>? species,
    Expression<int>? status,
    Expression<DateTime>? lastUpdated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (farmerId != null) 'farmer_id': farmerId,
      if (location != null) 'location': location,
      if (areaSqM != null) 'area_sq_m': areaSqM,
      if (depthM != null) 'depth_m': depthM,
      if (linerType != null) 'liner_type': linerType,
      if (waterSource != null) 'water_source': waterSource,
      if (stockingDate != null) 'stocking_date': stockingDate,
      if (species != null) 'species': species,
      if (status != null) 'status': status,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PondsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? farmerId,
    Value<String?>? location,
    Value<double?>? areaSqM,
    Value<double?>? depthM,
    Value<String?>? linerType,
    Value<String?>? waterSource,
    Value<DateTime?>? stockingDate,
    Value<String?>? species,
    Value<int>? status,
    Value<DateTime?>? lastUpdated,
    Value<int>? rowid,
  }) {
    return PondsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      farmerId: farmerId ?? this.farmerId,
      location: location ?? this.location,
      areaSqM: areaSqM ?? this.areaSqM,
      depthM: depthM ?? this.depthM,
      linerType: linerType ?? this.linerType,
      waterSource: waterSource ?? this.waterSource,
      stockingDate: stockingDate ?? this.stockingDate,
      species: species ?? this.species,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (farmerId.present) {
      map['farmer_id'] = Variable<String>(farmerId.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (areaSqM.present) {
      map['area_sq_m'] = Variable<double>(areaSqM.value);
    }
    if (depthM.present) {
      map['depth_m'] = Variable<double>(depthM.value);
    }
    if (linerType.present) {
      map['liner_type'] = Variable<String>(linerType.value);
    }
    if (waterSource.present) {
      map['water_source'] = Variable<String>(waterSource.value);
    }
    if (stockingDate.present) {
      map['stocking_date'] = Variable<DateTime>(stockingDate.value);
    }
    if (species.present) {
      map['species'] = Variable<String>(species.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PondsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('farmerId: $farmerId, ')
          ..write('location: $location, ')
          ..write('areaSqM: $areaSqM, ')
          ..write('depthM: $depthM, ')
          ..write('linerType: $linerType, ')
          ..write('waterSource: $waterSource, ')
          ..write('stockingDate: $stockingDate, ')
          ..write('species: $species, ')
          ..write('status: $status, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LogsTableTable extends LogsTable
    with TableInfo<$LogsTableTable, LogsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pondIdMeta = const VerificationMeta('pondId');
  @override
  late final GeneratedColumn<String> pondId = GeneratedColumn<String>(
    'pond_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedGivenKgMeta = const VerificationMeta(
    'feedGivenKg',
  );
  @override
  late final GeneratedColumn<double> feedGivenKg = GeneratedColumn<double>(
    'feed_given_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mortalityCountMeta = const VerificationMeta(
    'mortalityCount',
  );
  @override
  late final GeneratedColumn<int> mortalityCount = GeneratedColumn<int>(
    'mortality_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feedTrayMeta = const VerificationMeta(
    'feedTray',
  );
  @override
  late final GeneratedColumn<int> feedTray = GeneratedColumn<int>(
    'feed_tray',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterColorMeta = const VerificationMeta(
    'waterColor',
  );
  @override
  late final GeneratedColumn<int> waterColor = GeneratedColumn<int>(
    'water_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phMeta = const VerificationMeta('ph');
  @override
  late final GeneratedColumn<double> ph = GeneratedColumn<double>(
    'ph',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dissolvedOxygenMeta = const VerificationMeta(
    'dissolvedOxygen',
  );
  @override
  late final GeneratedColumn<double> dissolvedOxygen = GeneratedColumn<double>(
    'dissolved_oxygen',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salinityMeta = const VerificationMeta(
    'salinity',
  );
  @override
  late final GeneratedColumn<double> salinity = GeneratedColumn<double>(
    'salinity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlsJsonMeta = const VerificationMeta(
    'photoUrlsJson',
  );
  @override
  late final GeneratedColumn<String> photoUrlsJson = GeneratedColumn<String>(
    'photo_urls_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pondId,
    loggedAt,
    feedGivenKg,
    mortalityCount,
    feedTray,
    waterColor,
    ph,
    dissolvedOxygen,
    temperature,
    salinity,
    photoUrlsJson,
    syncStatus,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'logs_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pond_id')) {
      context.handle(
        _pondIdMeta,
        pondId.isAcceptableOrUnknown(data['pond_id']!, _pondIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pondIdMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('feed_given_kg')) {
      context.handle(
        _feedGivenKgMeta,
        feedGivenKg.isAcceptableOrUnknown(
          data['feed_given_kg']!,
          _feedGivenKgMeta,
        ),
      );
    }
    if (data.containsKey('mortality_count')) {
      context.handle(
        _mortalityCountMeta,
        mortalityCount.isAcceptableOrUnknown(
          data['mortality_count']!,
          _mortalityCountMeta,
        ),
      );
    }
    if (data.containsKey('feed_tray')) {
      context.handle(
        _feedTrayMeta,
        feedTray.isAcceptableOrUnknown(data['feed_tray']!, _feedTrayMeta),
      );
    }
    if (data.containsKey('water_color')) {
      context.handle(
        _waterColorMeta,
        waterColor.isAcceptableOrUnknown(data['water_color']!, _waterColorMeta),
      );
    }
    if (data.containsKey('ph')) {
      context.handle(_phMeta, ph.isAcceptableOrUnknown(data['ph']!, _phMeta));
    }
    if (data.containsKey('dissolved_oxygen')) {
      context.handle(
        _dissolvedOxygenMeta,
        dissolvedOxygen.isAcceptableOrUnknown(
          data['dissolved_oxygen']!,
          _dissolvedOxygenMeta,
        ),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('salinity')) {
      context.handle(
        _salinityMeta,
        salinity.isAcceptableOrUnknown(data['salinity']!, _salinityMeta),
      );
    }
    if (data.containsKey('photo_urls_json')) {
      context.handle(
        _photoUrlsJsonMeta,
        photoUrlsJson.isAcceptableOrUnknown(
          data['photo_urls_json']!,
          _photoUrlsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_photoUrlsJsonMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pondId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pond_id'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      feedGivenKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}feed_given_kg'],
      ),
      mortalityCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mortality_count'],
      ),
      feedTray: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feed_tray'],
      ),
      waterColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}water_color'],
      ),
      ph: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ph'],
      ),
      dissolvedOxygen: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dissolved_oxygen'],
      ),
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      ),
      salinity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}salinity'],
      ),
      photoUrlsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_urls_json'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $LogsTableTable createAlias(String alias) {
    return $LogsTableTable(attachedDatabase, alias);
  }
}

class LogsTableData extends DataClass implements Insertable<LogsTableData> {
  final String id;
  final String pondId;
  final DateTime loggedAt;
  final double? feedGivenKg;
  final int? mortalityCount;
  final int? feedTray;
  final int? waterColor;
  final double? ph;
  final double? dissolvedOxygen;
  final double? temperature;
  final double? salinity;
  final String photoUrlsJson;
  final int syncStatus;
  final String? notes;
  const LogsTableData({
    required this.id,
    required this.pondId,
    required this.loggedAt,
    this.feedGivenKg,
    this.mortalityCount,
    this.feedTray,
    this.waterColor,
    this.ph,
    this.dissolvedOxygen,
    this.temperature,
    this.salinity,
    required this.photoUrlsJson,
    required this.syncStatus,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pond_id'] = Variable<String>(pondId);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    if (!nullToAbsent || feedGivenKg != null) {
      map['feed_given_kg'] = Variable<double>(feedGivenKg);
    }
    if (!nullToAbsent || mortalityCount != null) {
      map['mortality_count'] = Variable<int>(mortalityCount);
    }
    if (!nullToAbsent || feedTray != null) {
      map['feed_tray'] = Variable<int>(feedTray);
    }
    if (!nullToAbsent || waterColor != null) {
      map['water_color'] = Variable<int>(waterColor);
    }
    if (!nullToAbsent || ph != null) {
      map['ph'] = Variable<double>(ph);
    }
    if (!nullToAbsent || dissolvedOxygen != null) {
      map['dissolved_oxygen'] = Variable<double>(dissolvedOxygen);
    }
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<double>(temperature);
    }
    if (!nullToAbsent || salinity != null) {
      map['salinity'] = Variable<double>(salinity);
    }
    map['photo_urls_json'] = Variable<String>(photoUrlsJson);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  LogsTableCompanion toCompanion(bool nullToAbsent) {
    return LogsTableCompanion(
      id: Value(id),
      pondId: Value(pondId),
      loggedAt: Value(loggedAt),
      feedGivenKg: feedGivenKg == null && nullToAbsent
          ? const Value.absent()
          : Value(feedGivenKg),
      mortalityCount: mortalityCount == null && nullToAbsent
          ? const Value.absent()
          : Value(mortalityCount),
      feedTray: feedTray == null && nullToAbsent
          ? const Value.absent()
          : Value(feedTray),
      waterColor: waterColor == null && nullToAbsent
          ? const Value.absent()
          : Value(waterColor),
      ph: ph == null && nullToAbsent ? const Value.absent() : Value(ph),
      dissolvedOxygen: dissolvedOxygen == null && nullToAbsent
          ? const Value.absent()
          : Value(dissolvedOxygen),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      salinity: salinity == null && nullToAbsent
          ? const Value.absent()
          : Value(salinity),
      photoUrlsJson: Value(photoUrlsJson),
      syncStatus: Value(syncStatus),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory LogsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogsTableData(
      id: serializer.fromJson<String>(json['id']),
      pondId: serializer.fromJson<String>(json['pondId']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      feedGivenKg: serializer.fromJson<double?>(json['feedGivenKg']),
      mortalityCount: serializer.fromJson<int?>(json['mortalityCount']),
      feedTray: serializer.fromJson<int?>(json['feedTray']),
      waterColor: serializer.fromJson<int?>(json['waterColor']),
      ph: serializer.fromJson<double?>(json['ph']),
      dissolvedOxygen: serializer.fromJson<double?>(json['dissolvedOxygen']),
      temperature: serializer.fromJson<double?>(json['temperature']),
      salinity: serializer.fromJson<double?>(json['salinity']),
      photoUrlsJson: serializer.fromJson<String>(json['photoUrlsJson']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pondId': serializer.toJson<String>(pondId),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'feedGivenKg': serializer.toJson<double?>(feedGivenKg),
      'mortalityCount': serializer.toJson<int?>(mortalityCount),
      'feedTray': serializer.toJson<int?>(feedTray),
      'waterColor': serializer.toJson<int?>(waterColor),
      'ph': serializer.toJson<double?>(ph),
      'dissolvedOxygen': serializer.toJson<double?>(dissolvedOxygen),
      'temperature': serializer.toJson<double?>(temperature),
      'salinity': serializer.toJson<double?>(salinity),
      'photoUrlsJson': serializer.toJson<String>(photoUrlsJson),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  LogsTableData copyWith({
    String? id,
    String? pondId,
    DateTime? loggedAt,
    Value<double?> feedGivenKg = const Value.absent(),
    Value<int?> mortalityCount = const Value.absent(),
    Value<int?> feedTray = const Value.absent(),
    Value<int?> waterColor = const Value.absent(),
    Value<double?> ph = const Value.absent(),
    Value<double?> dissolvedOxygen = const Value.absent(),
    Value<double?> temperature = const Value.absent(),
    Value<double?> salinity = const Value.absent(),
    String? photoUrlsJson,
    int? syncStatus,
    Value<String?> notes = const Value.absent(),
  }) => LogsTableData(
    id: id ?? this.id,
    pondId: pondId ?? this.pondId,
    loggedAt: loggedAt ?? this.loggedAt,
    feedGivenKg: feedGivenKg.present ? feedGivenKg.value : this.feedGivenKg,
    mortalityCount: mortalityCount.present
        ? mortalityCount.value
        : this.mortalityCount,
    feedTray: feedTray.present ? feedTray.value : this.feedTray,
    waterColor: waterColor.present ? waterColor.value : this.waterColor,
    ph: ph.present ? ph.value : this.ph,
    dissolvedOxygen: dissolvedOxygen.present
        ? dissolvedOxygen.value
        : this.dissolvedOxygen,
    temperature: temperature.present ? temperature.value : this.temperature,
    salinity: salinity.present ? salinity.value : this.salinity,
    photoUrlsJson: photoUrlsJson ?? this.photoUrlsJson,
    syncStatus: syncStatus ?? this.syncStatus,
    notes: notes.present ? notes.value : this.notes,
  );
  LogsTableData copyWithCompanion(LogsTableCompanion data) {
    return LogsTableData(
      id: data.id.present ? data.id.value : this.id,
      pondId: data.pondId.present ? data.pondId.value : this.pondId,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      feedGivenKg: data.feedGivenKg.present
          ? data.feedGivenKg.value
          : this.feedGivenKg,
      mortalityCount: data.mortalityCount.present
          ? data.mortalityCount.value
          : this.mortalityCount,
      feedTray: data.feedTray.present ? data.feedTray.value : this.feedTray,
      waterColor: data.waterColor.present
          ? data.waterColor.value
          : this.waterColor,
      ph: data.ph.present ? data.ph.value : this.ph,
      dissolvedOxygen: data.dissolvedOxygen.present
          ? data.dissolvedOxygen.value
          : this.dissolvedOxygen,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      salinity: data.salinity.present ? data.salinity.value : this.salinity,
      photoUrlsJson: data.photoUrlsJson.present
          ? data.photoUrlsJson.value
          : this.photoUrlsJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogsTableData(')
          ..write('id: $id, ')
          ..write('pondId: $pondId, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('feedGivenKg: $feedGivenKg, ')
          ..write('mortalityCount: $mortalityCount, ')
          ..write('feedTray: $feedTray, ')
          ..write('waterColor: $waterColor, ')
          ..write('ph: $ph, ')
          ..write('dissolvedOxygen: $dissolvedOxygen, ')
          ..write('temperature: $temperature, ')
          ..write('salinity: $salinity, ')
          ..write('photoUrlsJson: $photoUrlsJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pondId,
    loggedAt,
    feedGivenKg,
    mortalityCount,
    feedTray,
    waterColor,
    ph,
    dissolvedOxygen,
    temperature,
    salinity,
    photoUrlsJson,
    syncStatus,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogsTableData &&
          other.id == this.id &&
          other.pondId == this.pondId &&
          other.loggedAt == this.loggedAt &&
          other.feedGivenKg == this.feedGivenKg &&
          other.mortalityCount == this.mortalityCount &&
          other.feedTray == this.feedTray &&
          other.waterColor == this.waterColor &&
          other.ph == this.ph &&
          other.dissolvedOxygen == this.dissolvedOxygen &&
          other.temperature == this.temperature &&
          other.salinity == this.salinity &&
          other.photoUrlsJson == this.photoUrlsJson &&
          other.syncStatus == this.syncStatus &&
          other.notes == this.notes);
}

class LogsTableCompanion extends UpdateCompanion<LogsTableData> {
  final Value<String> id;
  final Value<String> pondId;
  final Value<DateTime> loggedAt;
  final Value<double?> feedGivenKg;
  final Value<int?> mortalityCount;
  final Value<int?> feedTray;
  final Value<int?> waterColor;
  final Value<double?> ph;
  final Value<double?> dissolvedOxygen;
  final Value<double?> temperature;
  final Value<double?> salinity;
  final Value<String> photoUrlsJson;
  final Value<int> syncStatus;
  final Value<String?> notes;
  final Value<int> rowid;
  const LogsTableCompanion({
    this.id = const Value.absent(),
    this.pondId = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.feedGivenKg = const Value.absent(),
    this.mortalityCount = const Value.absent(),
    this.feedTray = const Value.absent(),
    this.waterColor = const Value.absent(),
    this.ph = const Value.absent(),
    this.dissolvedOxygen = const Value.absent(),
    this.temperature = const Value.absent(),
    this.salinity = const Value.absent(),
    this.photoUrlsJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LogsTableCompanion.insert({
    required String id,
    required String pondId,
    required DateTime loggedAt,
    this.feedGivenKg = const Value.absent(),
    this.mortalityCount = const Value.absent(),
    this.feedTray = const Value.absent(),
    this.waterColor = const Value.absent(),
    this.ph = const Value.absent(),
    this.dissolvedOxygen = const Value.absent(),
    this.temperature = const Value.absent(),
    this.salinity = const Value.absent(),
    required String photoUrlsJson,
    required int syncStatus,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pondId = Value(pondId),
       loggedAt = Value(loggedAt),
       photoUrlsJson = Value(photoUrlsJson),
       syncStatus = Value(syncStatus);
  static Insertable<LogsTableData> custom({
    Expression<String>? id,
    Expression<String>? pondId,
    Expression<DateTime>? loggedAt,
    Expression<double>? feedGivenKg,
    Expression<int>? mortalityCount,
    Expression<int>? feedTray,
    Expression<int>? waterColor,
    Expression<double>? ph,
    Expression<double>? dissolvedOxygen,
    Expression<double>? temperature,
    Expression<double>? salinity,
    Expression<String>? photoUrlsJson,
    Expression<int>? syncStatus,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pondId != null) 'pond_id': pondId,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (feedGivenKg != null) 'feed_given_kg': feedGivenKg,
      if (mortalityCount != null) 'mortality_count': mortalityCount,
      if (feedTray != null) 'feed_tray': feedTray,
      if (waterColor != null) 'water_color': waterColor,
      if (ph != null) 'ph': ph,
      if (dissolvedOxygen != null) 'dissolved_oxygen': dissolvedOxygen,
      if (temperature != null) 'temperature': temperature,
      if (salinity != null) 'salinity': salinity,
      if (photoUrlsJson != null) 'photo_urls_json': photoUrlsJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LogsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? pondId,
    Value<DateTime>? loggedAt,
    Value<double?>? feedGivenKg,
    Value<int?>? mortalityCount,
    Value<int?>? feedTray,
    Value<int?>? waterColor,
    Value<double?>? ph,
    Value<double?>? dissolvedOxygen,
    Value<double?>? temperature,
    Value<double?>? salinity,
    Value<String>? photoUrlsJson,
    Value<int>? syncStatus,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return LogsTableCompanion(
      id: id ?? this.id,
      pondId: pondId ?? this.pondId,
      loggedAt: loggedAt ?? this.loggedAt,
      feedGivenKg: feedGivenKg ?? this.feedGivenKg,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      feedTray: feedTray ?? this.feedTray,
      waterColor: waterColor ?? this.waterColor,
      ph: ph ?? this.ph,
      dissolvedOxygen: dissolvedOxygen ?? this.dissolvedOxygen,
      temperature: temperature ?? this.temperature,
      salinity: salinity ?? this.salinity,
      photoUrlsJson: photoUrlsJson ?? this.photoUrlsJson,
      syncStatus: syncStatus ?? this.syncStatus,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pondId.present) {
      map['pond_id'] = Variable<String>(pondId.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (feedGivenKg.present) {
      map['feed_given_kg'] = Variable<double>(feedGivenKg.value);
    }
    if (mortalityCount.present) {
      map['mortality_count'] = Variable<int>(mortalityCount.value);
    }
    if (feedTray.present) {
      map['feed_tray'] = Variable<int>(feedTray.value);
    }
    if (waterColor.present) {
      map['water_color'] = Variable<int>(waterColor.value);
    }
    if (ph.present) {
      map['ph'] = Variable<double>(ph.value);
    }
    if (dissolvedOxygen.present) {
      map['dissolved_oxygen'] = Variable<double>(dissolvedOxygen.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (salinity.present) {
      map['salinity'] = Variable<double>(salinity.value);
    }
    if (photoUrlsJson.present) {
      map['photo_urls_json'] = Variable<String>(photoUrlsJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogsTableCompanion(')
          ..write('id: $id, ')
          ..write('pondId: $pondId, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('feedGivenKg: $feedGivenKg, ')
          ..write('mortalityCount: $mortalityCount, ')
          ..write('feedTray: $feedTray, ')
          ..write('waterColor: $waterColor, ')
          ..write('ph: $ph, ')
          ..write('dissolvedOxygen: $dissolvedOxygen, ')
          ..write('temperature: $temperature, ')
          ..write('salinity: $salinity, ')
          ..write('photoUrlsJson: $photoUrlsJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertsTableTable extends AlertsTable
    with TableInfo<$AlertsTableTable, AlertsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pondIdMeta = const VerificationMeta('pondId');
  @override
  late final GeneratedColumn<String> pondId = GeneratedColumn<String>(
    'pond_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pondNameMeta = const VerificationMeta(
    'pondName',
  );
  @override
  late final GeneratedColumn<String> pondName = GeneratedColumn<String>(
    'pond_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alertTypeMeta = const VerificationMeta(
    'alertType',
  );
  @override
  late final GeneratedColumn<String> alertType = GeneratedColumn<String>(
    'alert_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _suppressedMeta = const VerificationMeta(
    'suppressed',
  );
  @override
  late final GeneratedColumn<bool> suppressed = GeneratedColumn<bool>(
    'suppressed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("suppressed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _suppressionReasonMeta = const VerificationMeta(
    'suppressionReason',
  );
  @override
  late final GeneratedColumn<String> suppressionReason =
      GeneratedColumn<String>(
        'suppression_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ackedMeta = const VerificationMeta('acked');
  @override
  late final GeneratedColumn<bool> acked = GeneratedColumn<bool>(
    'acked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("acked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ackedAtMeta = const VerificationMeta(
    'ackedAt',
  );
  @override
  late final GeneratedColumn<DateTime> ackedAt = GeneratedColumn<DateTime>(
    'acked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _riskScoreMeta = const VerificationMeta(
    'riskScore',
  );
  @override
  late final GeneratedColumn<double> riskScore = GeneratedColumn<double>(
    'risk_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedbackMeta = const VerificationMeta(
    'feedback',
  );
  @override
  late final GeneratedColumn<int> feedback = GeneratedColumn<int>(
    'feedback',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pondId,
    pondName,
    alertType,
    severity,
    title,
    message,
    suppressed,
    suppressionReason,
    acked,
    ackedAt,
    riskScore,
    createdAt,
    feedback,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlertsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pond_id')) {
      context.handle(
        _pondIdMeta,
        pondId.isAcceptableOrUnknown(data['pond_id']!, _pondIdMeta),
      );
    }
    if (data.containsKey('pond_name')) {
      context.handle(
        _pondNameMeta,
        pondName.isAcceptableOrUnknown(data['pond_name']!, _pondNameMeta),
      );
    }
    if (data.containsKey('alert_type')) {
      context.handle(
        _alertTypeMeta,
        alertType.isAcceptableOrUnknown(data['alert_type']!, _alertTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_alertTypeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('suppressed')) {
      context.handle(
        _suppressedMeta,
        suppressed.isAcceptableOrUnknown(data['suppressed']!, _suppressedMeta),
      );
    }
    if (data.containsKey('suppression_reason')) {
      context.handle(
        _suppressionReasonMeta,
        suppressionReason.isAcceptableOrUnknown(
          data['suppression_reason']!,
          _suppressionReasonMeta,
        ),
      );
    }
    if (data.containsKey('acked')) {
      context.handle(
        _ackedMeta,
        acked.isAcceptableOrUnknown(data['acked']!, _ackedMeta),
      );
    }
    if (data.containsKey('acked_at')) {
      context.handle(
        _ackedAtMeta,
        ackedAt.isAcceptableOrUnknown(data['acked_at']!, _ackedAtMeta),
      );
    }
    if (data.containsKey('risk_score')) {
      context.handle(
        _riskScoreMeta,
        riskScore.isAcceptableOrUnknown(data['risk_score']!, _riskScoreMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('feedback')) {
      context.handle(
        _feedbackMeta,
        feedback.isAcceptableOrUnknown(data['feedback']!, _feedbackMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlertsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pondId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pond_id'],
      ),
      pondName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pond_name'],
      ),
      alertType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alert_type'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      suppressed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}suppressed'],
      )!,
      suppressionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suppression_reason'],
      ),
      acked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}acked'],
      )!,
      ackedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acked_at'],
      ),
      riskScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}risk_score'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      feedback: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feedback'],
      ),
    );
  }

  @override
  $AlertsTableTable createAlias(String alias) {
    return $AlertsTableTable(attachedDatabase, alias);
  }
}

class AlertsTableData extends DataClass implements Insertable<AlertsTableData> {
  final String id;
  final String? pondId;
  final String? pondName;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final bool suppressed;
  final String? suppressionReason;
  final bool acked;
  final DateTime? ackedAt;
  final double? riskScore;
  final DateTime createdAt;
  final int? feedback;
  const AlertsTableData({
    required this.id,
    this.pondId,
    this.pondName,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    required this.suppressed,
    this.suppressionReason,
    required this.acked,
    this.ackedAt,
    this.riskScore,
    required this.createdAt,
    this.feedback,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || pondId != null) {
      map['pond_id'] = Variable<String>(pondId);
    }
    if (!nullToAbsent || pondName != null) {
      map['pond_name'] = Variable<String>(pondName);
    }
    map['alert_type'] = Variable<String>(alertType);
    map['severity'] = Variable<String>(severity);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    map['suppressed'] = Variable<bool>(suppressed);
    if (!nullToAbsent || suppressionReason != null) {
      map['suppression_reason'] = Variable<String>(suppressionReason);
    }
    map['acked'] = Variable<bool>(acked);
    if (!nullToAbsent || ackedAt != null) {
      map['acked_at'] = Variable<DateTime>(ackedAt);
    }
    if (!nullToAbsent || riskScore != null) {
      map['risk_score'] = Variable<double>(riskScore);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || feedback != null) {
      map['feedback'] = Variable<int>(feedback);
    }
    return map;
  }

  AlertsTableCompanion toCompanion(bool nullToAbsent) {
    return AlertsTableCompanion(
      id: Value(id),
      pondId: pondId == null && nullToAbsent
          ? const Value.absent()
          : Value(pondId),
      pondName: pondName == null && nullToAbsent
          ? const Value.absent()
          : Value(pondName),
      alertType: Value(alertType),
      severity: Value(severity),
      title: Value(title),
      message: Value(message),
      suppressed: Value(suppressed),
      suppressionReason: suppressionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(suppressionReason),
      acked: Value(acked),
      ackedAt: ackedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(ackedAt),
      riskScore: riskScore == null && nullToAbsent
          ? const Value.absent()
          : Value(riskScore),
      createdAt: Value(createdAt),
      feedback: feedback == null && nullToAbsent
          ? const Value.absent()
          : Value(feedback),
    );
  }

  factory AlertsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertsTableData(
      id: serializer.fromJson<String>(json['id']),
      pondId: serializer.fromJson<String?>(json['pondId']),
      pondName: serializer.fromJson<String?>(json['pondName']),
      alertType: serializer.fromJson<String>(json['alertType']),
      severity: serializer.fromJson<String>(json['severity']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      suppressed: serializer.fromJson<bool>(json['suppressed']),
      suppressionReason: serializer.fromJson<String?>(
        json['suppressionReason'],
      ),
      acked: serializer.fromJson<bool>(json['acked']),
      ackedAt: serializer.fromJson<DateTime?>(json['ackedAt']),
      riskScore: serializer.fromJson<double?>(json['riskScore']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      feedback: serializer.fromJson<int?>(json['feedback']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pondId': serializer.toJson<String?>(pondId),
      'pondName': serializer.toJson<String?>(pondName),
      'alertType': serializer.toJson<String>(alertType),
      'severity': serializer.toJson<String>(severity),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'suppressed': serializer.toJson<bool>(suppressed),
      'suppressionReason': serializer.toJson<String?>(suppressionReason),
      'acked': serializer.toJson<bool>(acked),
      'ackedAt': serializer.toJson<DateTime?>(ackedAt),
      'riskScore': serializer.toJson<double?>(riskScore),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'feedback': serializer.toJson<int?>(feedback),
    };
  }

  AlertsTableData copyWith({
    String? id,
    Value<String?> pondId = const Value.absent(),
    Value<String?> pondName = const Value.absent(),
    String? alertType,
    String? severity,
    String? title,
    String? message,
    bool? suppressed,
    Value<String?> suppressionReason = const Value.absent(),
    bool? acked,
    Value<DateTime?> ackedAt = const Value.absent(),
    Value<double?> riskScore = const Value.absent(),
    DateTime? createdAt,
    Value<int?> feedback = const Value.absent(),
  }) => AlertsTableData(
    id: id ?? this.id,
    pondId: pondId.present ? pondId.value : this.pondId,
    pondName: pondName.present ? pondName.value : this.pondName,
    alertType: alertType ?? this.alertType,
    severity: severity ?? this.severity,
    title: title ?? this.title,
    message: message ?? this.message,
    suppressed: suppressed ?? this.suppressed,
    suppressionReason: suppressionReason.present
        ? suppressionReason.value
        : this.suppressionReason,
    acked: acked ?? this.acked,
    ackedAt: ackedAt.present ? ackedAt.value : this.ackedAt,
    riskScore: riskScore.present ? riskScore.value : this.riskScore,
    createdAt: createdAt ?? this.createdAt,
    feedback: feedback.present ? feedback.value : this.feedback,
  );
  AlertsTableData copyWithCompanion(AlertsTableCompanion data) {
    return AlertsTableData(
      id: data.id.present ? data.id.value : this.id,
      pondId: data.pondId.present ? data.pondId.value : this.pondId,
      pondName: data.pondName.present ? data.pondName.value : this.pondName,
      alertType: data.alertType.present ? data.alertType.value : this.alertType,
      severity: data.severity.present ? data.severity.value : this.severity,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      suppressed: data.suppressed.present
          ? data.suppressed.value
          : this.suppressed,
      suppressionReason: data.suppressionReason.present
          ? data.suppressionReason.value
          : this.suppressionReason,
      acked: data.acked.present ? data.acked.value : this.acked,
      ackedAt: data.ackedAt.present ? data.ackedAt.value : this.ackedAt,
      riskScore: data.riskScore.present ? data.riskScore.value : this.riskScore,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      feedback: data.feedback.present ? data.feedback.value : this.feedback,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertsTableData(')
          ..write('id: $id, ')
          ..write('pondId: $pondId, ')
          ..write('pondName: $pondName, ')
          ..write('alertType: $alertType, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('suppressed: $suppressed, ')
          ..write('suppressionReason: $suppressionReason, ')
          ..write('acked: $acked, ')
          ..write('ackedAt: $ackedAt, ')
          ..write('riskScore: $riskScore, ')
          ..write('createdAt: $createdAt, ')
          ..write('feedback: $feedback')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pondId,
    pondName,
    alertType,
    severity,
    title,
    message,
    suppressed,
    suppressionReason,
    acked,
    ackedAt,
    riskScore,
    createdAt,
    feedback,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertsTableData &&
          other.id == this.id &&
          other.pondId == this.pondId &&
          other.pondName == this.pondName &&
          other.alertType == this.alertType &&
          other.severity == this.severity &&
          other.title == this.title &&
          other.message == this.message &&
          other.suppressed == this.suppressed &&
          other.suppressionReason == this.suppressionReason &&
          other.acked == this.acked &&
          other.ackedAt == this.ackedAt &&
          other.riskScore == this.riskScore &&
          other.createdAt == this.createdAt &&
          other.feedback == this.feedback);
}

class AlertsTableCompanion extends UpdateCompanion<AlertsTableData> {
  final Value<String> id;
  final Value<String?> pondId;
  final Value<String?> pondName;
  final Value<String> alertType;
  final Value<String> severity;
  final Value<String> title;
  final Value<String> message;
  final Value<bool> suppressed;
  final Value<String?> suppressionReason;
  final Value<bool> acked;
  final Value<DateTime?> ackedAt;
  final Value<double?> riskScore;
  final Value<DateTime> createdAt;
  final Value<int?> feedback;
  final Value<int> rowid;
  const AlertsTableCompanion({
    this.id = const Value.absent(),
    this.pondId = const Value.absent(),
    this.pondName = const Value.absent(),
    this.alertType = const Value.absent(),
    this.severity = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.suppressed = const Value.absent(),
    this.suppressionReason = const Value.absent(),
    this.acked = const Value.absent(),
    this.ackedAt = const Value.absent(),
    this.riskScore = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.feedback = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertsTableCompanion.insert({
    required String id,
    this.pondId = const Value.absent(),
    this.pondName = const Value.absent(),
    required String alertType,
    required String severity,
    required String title,
    required String message,
    this.suppressed = const Value.absent(),
    this.suppressionReason = const Value.absent(),
    this.acked = const Value.absent(),
    this.ackedAt = const Value.absent(),
    this.riskScore = const Value.absent(),
    required DateTime createdAt,
    this.feedback = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       alertType = Value(alertType),
       severity = Value(severity),
       title = Value(title),
       message = Value(message),
       createdAt = Value(createdAt);
  static Insertable<AlertsTableData> custom({
    Expression<String>? id,
    Expression<String>? pondId,
    Expression<String>? pondName,
    Expression<String>? alertType,
    Expression<String>? severity,
    Expression<String>? title,
    Expression<String>? message,
    Expression<bool>? suppressed,
    Expression<String>? suppressionReason,
    Expression<bool>? acked,
    Expression<DateTime>? ackedAt,
    Expression<double>? riskScore,
    Expression<DateTime>? createdAt,
    Expression<int>? feedback,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pondId != null) 'pond_id': pondId,
      if (pondName != null) 'pond_name': pondName,
      if (alertType != null) 'alert_type': alertType,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (suppressed != null) 'suppressed': suppressed,
      if (suppressionReason != null) 'suppression_reason': suppressionReason,
      if (acked != null) 'acked': acked,
      if (ackedAt != null) 'acked_at': ackedAt,
      if (riskScore != null) 'risk_score': riskScore,
      if (createdAt != null) 'created_at': createdAt,
      if (feedback != null) 'feedback': feedback,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? pondId,
    Value<String?>? pondName,
    Value<String>? alertType,
    Value<String>? severity,
    Value<String>? title,
    Value<String>? message,
    Value<bool>? suppressed,
    Value<String?>? suppressionReason,
    Value<bool>? acked,
    Value<DateTime?>? ackedAt,
    Value<double?>? riskScore,
    Value<DateTime>? createdAt,
    Value<int?>? feedback,
    Value<int>? rowid,
  }) {
    return AlertsTableCompanion(
      id: id ?? this.id,
      pondId: pondId ?? this.pondId,
      pondName: pondName ?? this.pondName,
      alertType: alertType ?? this.alertType,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      suppressed: suppressed ?? this.suppressed,
      suppressionReason: suppressionReason ?? this.suppressionReason,
      acked: acked ?? this.acked,
      ackedAt: ackedAt ?? this.ackedAt,
      riskScore: riskScore ?? this.riskScore,
      createdAt: createdAt ?? this.createdAt,
      feedback: feedback ?? this.feedback,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pondId.present) {
      map['pond_id'] = Variable<String>(pondId.value);
    }
    if (pondName.present) {
      map['pond_name'] = Variable<String>(pondName.value);
    }
    if (alertType.present) {
      map['alert_type'] = Variable<String>(alertType.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (suppressed.present) {
      map['suppressed'] = Variable<bool>(suppressed.value);
    }
    if (suppressionReason.present) {
      map['suppression_reason'] = Variable<String>(suppressionReason.value);
    }
    if (acked.present) {
      map['acked'] = Variable<bool>(acked.value);
    }
    if (ackedAt.present) {
      map['acked_at'] = Variable<DateTime>(ackedAt.value);
    }
    if (riskScore.present) {
      map['risk_score'] = Variable<double>(riskScore.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (feedback.present) {
      map['feedback'] = Variable<int>(feedback.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertsTableCompanion(')
          ..write('id: $id, ')
          ..write('pondId: $pondId, ')
          ..write('pondName: $pondName, ')
          ..write('alertType: $alertType, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('suppressed: $suppressed, ')
          ..write('suppressionReason: $suppressionReason, ')
          ..write('acked: $acked, ')
          ..write('ackedAt: $ackedAt, ')
          ..write('riskScore: $riskScore, ')
          ..write('createdAt: $createdAt, ')
          ..write('feedback: $feedback, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DashboardCacheTableTable extends DashboardCacheTable
    with TableInfo<$DashboardCacheTableTable, DashboardCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DashboardCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadBlobMeta = const VerificationMeta(
    'payloadBlob',
  );
  @override
  late final GeneratedColumn<String> payloadBlob = GeneratedColumn<String>(
    'payload_blob',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, payloadBlob, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dashboard_cache_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DashboardCacheTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('payload_blob')) {
      context.handle(
        _payloadBlobMeta,
        payloadBlob.isAcceptableOrUnknown(
          data['payload_blob']!,
          _payloadBlobMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadBlobMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  DashboardCacheTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DashboardCacheTableData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      payloadBlob: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_blob'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $DashboardCacheTableTable createAlias(String alias) {
    return $DashboardCacheTableTable(attachedDatabase, alias);
  }
}

class DashboardCacheTableData extends DataClass
    implements Insertable<DashboardCacheTableData> {
  final String cacheKey;
  final String payloadBlob;
  final DateTime syncedAt;
  const DashboardCacheTableData({
    required this.cacheKey,
    required this.payloadBlob,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['payload_blob'] = Variable<String>(payloadBlob);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  DashboardCacheTableCompanion toCompanion(bool nullToAbsent) {
    return DashboardCacheTableCompanion(
      cacheKey: Value(cacheKey),
      payloadBlob: Value(payloadBlob),
      syncedAt: Value(syncedAt),
    );
  }

  factory DashboardCacheTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DashboardCacheTableData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      payloadBlob: serializer.fromJson<String>(json['payloadBlob']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'payloadBlob': serializer.toJson<String>(payloadBlob),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  DashboardCacheTableData copyWith({
    String? cacheKey,
    String? payloadBlob,
    DateTime? syncedAt,
  }) => DashboardCacheTableData(
    cacheKey: cacheKey ?? this.cacheKey,
    payloadBlob: payloadBlob ?? this.payloadBlob,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  DashboardCacheTableData copyWithCompanion(DashboardCacheTableCompanion data) {
    return DashboardCacheTableData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      payloadBlob: data.payloadBlob.present
          ? data.payloadBlob.value
          : this.payloadBlob,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DashboardCacheTableData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payloadBlob: $payloadBlob, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, payloadBlob, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DashboardCacheTableData &&
          other.cacheKey == this.cacheKey &&
          other.payloadBlob == this.payloadBlob &&
          other.syncedAt == this.syncedAt);
}

class DashboardCacheTableCompanion
    extends UpdateCompanion<DashboardCacheTableData> {
  final Value<String> cacheKey;
  final Value<String> payloadBlob;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const DashboardCacheTableCompanion({
    this.cacheKey = const Value.absent(),
    this.payloadBlob = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DashboardCacheTableCompanion.insert({
    required String cacheKey,
    required String payloadBlob,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       payloadBlob = Value(payloadBlob),
       syncedAt = Value(syncedAt);
  static Insertable<DashboardCacheTableData> custom({
    Expression<String>? cacheKey,
    Expression<String>? payloadBlob,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (payloadBlob != null) 'payload_blob': payloadBlob,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DashboardCacheTableCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? payloadBlob,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return DashboardCacheTableCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      payloadBlob: payloadBlob ?? this.payloadBlob,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (payloadBlob.present) {
      map['payload_blob'] = Variable<String>(payloadBlob.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DashboardCacheTableCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payloadBlob: $payloadBlob, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTableTable extends OutboxTable
    with TableInfo<$OutboxTableTable, OutboxTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientLogIdMeta = const VerificationMeta(
    'clientLogId',
  );
  @override
  late final GeneratedColumn<String> clientLogId = GeneratedColumn<String>(
    'client_log_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientLogId,
    entityType,
    payloadJson,
    status,
    createdAt,
    syncedAt,
    retryCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_log_id')) {
      context.handle(
        _clientLogIdMeta,
        clientLogId.isAcceptableOrUnknown(
          data['client_log_id']!,
          _clientLogIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientLogIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_log_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxTableTable createAlias(String alias) {
    return $OutboxTableTable(attachedDatabase, alias);
  }
}

class OutboxTableData extends DataClass implements Insertable<OutboxTableData> {
  final String id;
  final String clientLogId;
  final String entityType;
  final String payloadJson;
  final String status;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final int retryCount;
  final String? lastError;
  const OutboxTableData({
    required this.id,
    required this.clientLogId,
    required this.entityType,
    required this.payloadJson,
    required this.status,
    required this.createdAt,
    this.syncedAt,
    required this.retryCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['client_log_id'] = Variable<String>(clientLogId);
    map['entity_type'] = Variable<String>(entityType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxTableCompanion toCompanion(bool nullToAbsent) {
    return OutboxTableCompanion(
      id: Value(id),
      clientLogId: Value(clientLogId),
      entityType: Value(entityType),
      payloadJson: Value(payloadJson),
      status: Value(status),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxTableData(
      id: serializer.fromJson<String>(json['id']),
      clientLogId: serializer.fromJson<String>(json['clientLogId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'clientLogId': serializer.toJson<String>(clientLogId),
      'entityType': serializer.toJson<String>(entityType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxTableData copyWith({
    String? id,
    String? clientLogId,
    String? entityType,
    String? payloadJson,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
  }) => OutboxTableData(
    id: id ?? this.id,
    clientLogId: clientLogId ?? this.clientLogId,
    entityType: entityType ?? this.entityType,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxTableData copyWithCompanion(OutboxTableCompanion data) {
    return OutboxTableData(
      id: data.id.present ? data.id.value : this.id,
      clientLogId: data.clientLogId.present
          ? data.clientLogId.value
          : this.clientLogId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxTableData(')
          ..write('id: $id, ')
          ..write('clientLogId: $clientLogId, ')
          ..write('entityType: $entityType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientLogId,
    entityType,
    payloadJson,
    status,
    createdAt,
    syncedAt,
    retryCount,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxTableData &&
          other.id == this.id &&
          other.clientLogId == this.clientLogId &&
          other.entityType == this.entityType &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError);
}

class OutboxTableCompanion extends UpdateCompanion<OutboxTableData> {
  final Value<String> id;
  final Value<String> clientLogId;
  final Value<String> entityType;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> syncedAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<int> rowid;
  const OutboxTableCompanion({
    this.id = const Value.absent(),
    this.clientLogId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxTableCompanion.insert({
    required String id,
    required String clientLogId,
    required String entityType,
    required String payloadJson,
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.syncedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       clientLogId = Value(clientLogId),
       entityType = Value(entityType),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<OutboxTableData> custom({
    Expression<String>? id,
    Expression<String>? clientLogId,
    Expression<String>? entityType,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientLogId != null) 'client_log_id': clientLogId,
      if (entityType != null) 'entity_type': entityType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxTableCompanion copyWith({
    Value<String>? id,
    Value<String>? clientLogId,
    Value<String>? entityType,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? syncedAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return OutboxTableCompanion(
      id: id ?? this.id,
      clientLogId: clientLogId ?? this.clientLogId,
      entityType: entityType ?? this.entityType,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientLogId.present) {
      map['client_log_id'] = Variable<String>(clientLogId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxTableCompanion(')
          ..write('id: $id, ')
          ..write('clientLogId: $clientLogId, ')
          ..write('entityType: $entityType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalLogsTableTable extends LocalLogsTable
    with TableInfo<$LocalLogsTableTable, LocalLogsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalLogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientLogIdMeta = const VerificationMeta(
    'clientLogId',
  );
  @override
  late final GeneratedColumn<String> clientLogId = GeneratedColumn<String>(
    'client_log_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pondIdMeta = const VerificationMeta('pondId');
  @override
  late final GeneratedColumn<String> pondId = GeneratedColumn<String>(
    'pond_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedGivenKgMeta = const VerificationMeta(
    'feedGivenKg',
  );
  @override
  late final GeneratedColumn<double> feedGivenKg = GeneratedColumn<double>(
    'feed_given_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mortalityCountMeta = const VerificationMeta(
    'mortalityCount',
  );
  @override
  late final GeneratedColumn<int> mortalityCount = GeneratedColumn<int>(
    'mortality_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feedTrayMeta = const VerificationMeta(
    'feedTray',
  );
  @override
  late final GeneratedColumn<int> feedTray = GeneratedColumn<int>(
    'feed_tray',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waterColorMeta = const VerificationMeta(
    'waterColor',
  );
  @override
  late final GeneratedColumn<int> waterColor = GeneratedColumn<int>(
    'water_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phMeta = const VerificationMeta('ph');
  @override
  late final GeneratedColumn<double> ph = GeneratedColumn<double>(
    'ph',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dissolvedOxygenMeta = const VerificationMeta(
    'dissolvedOxygen',
  );
  @override
  late final GeneratedColumn<double> dissolvedOxygen = GeneratedColumn<double>(
    'dissolved_oxygen',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salinityMeta = const VerificationMeta(
    'salinity',
  );
  @override
  late final GeneratedColumn<double> salinity = GeneratedColumn<double>(
    'salinity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlsJsonMeta = const VerificationMeta(
    'photoUrlsJson',
  );
  @override
  late final GeneratedColumn<String> photoUrlsJson = GeneratedColumn<String>(
    'photo_urls_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientLogId,
    pondId,
    loggedAt,
    feedGivenKg,
    mortalityCount,
    feedTray,
    waterColor,
    ph,
    dissolvedOxygen,
    temperature,
    salinity,
    photoUrlsJson,
    syncStatus,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_logs_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalLogsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_log_id')) {
      context.handle(
        _clientLogIdMeta,
        clientLogId.isAcceptableOrUnknown(
          data['client_log_id']!,
          _clientLogIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientLogIdMeta);
    }
    if (data.containsKey('pond_id')) {
      context.handle(
        _pondIdMeta,
        pondId.isAcceptableOrUnknown(data['pond_id']!, _pondIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pondIdMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('feed_given_kg')) {
      context.handle(
        _feedGivenKgMeta,
        feedGivenKg.isAcceptableOrUnknown(
          data['feed_given_kg']!,
          _feedGivenKgMeta,
        ),
      );
    }
    if (data.containsKey('mortality_count')) {
      context.handle(
        _mortalityCountMeta,
        mortalityCount.isAcceptableOrUnknown(
          data['mortality_count']!,
          _mortalityCountMeta,
        ),
      );
    }
    if (data.containsKey('feed_tray')) {
      context.handle(
        _feedTrayMeta,
        feedTray.isAcceptableOrUnknown(data['feed_tray']!, _feedTrayMeta),
      );
    }
    if (data.containsKey('water_color')) {
      context.handle(
        _waterColorMeta,
        waterColor.isAcceptableOrUnknown(data['water_color']!, _waterColorMeta),
      );
    }
    if (data.containsKey('ph')) {
      context.handle(_phMeta, ph.isAcceptableOrUnknown(data['ph']!, _phMeta));
    }
    if (data.containsKey('dissolved_oxygen')) {
      context.handle(
        _dissolvedOxygenMeta,
        dissolvedOxygen.isAcceptableOrUnknown(
          data['dissolved_oxygen']!,
          _dissolvedOxygenMeta,
        ),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('salinity')) {
      context.handle(
        _salinityMeta,
        salinity.isAcceptableOrUnknown(data['salinity']!, _salinityMeta),
      );
    }
    if (data.containsKey('photo_urls_json')) {
      context.handle(
        _photoUrlsJsonMeta,
        photoUrlsJson.isAcceptableOrUnknown(
          data['photo_urls_json']!,
          _photoUrlsJsonMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientLogId};
  @override
  LocalLogsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalLogsTableData(
      clientLogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_log_id'],
      )!,
      pondId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pond_id'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
      feedGivenKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}feed_given_kg'],
      ),
      mortalityCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mortality_count'],
      ),
      feedTray: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feed_tray'],
      ),
      waterColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}water_color'],
      ),
      ph: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ph'],
      ),
      dissolvedOxygen: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dissolved_oxygen'],
      ),
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      ),
      salinity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}salinity'],
      ),
      photoUrlsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_urls_json'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalLogsTableTable createAlias(String alias) {
    return $LocalLogsTableTable(attachedDatabase, alias);
  }
}

class LocalLogsTableData extends DataClass
    implements Insertable<LocalLogsTableData> {
  final String clientLogId;
  final String pondId;
  final DateTime loggedAt;
  final double? feedGivenKg;
  final int? mortalityCount;
  final int? feedTray;
  final int? waterColor;
  final double? ph;
  final double? dissolvedOxygen;
  final double? temperature;
  final double? salinity;
  final String photoUrlsJson;
  final int syncStatus;
  final String? notes;
  final DateTime createdAt;
  const LocalLogsTableData({
    required this.clientLogId,
    required this.pondId,
    required this.loggedAt,
    this.feedGivenKg,
    this.mortalityCount,
    this.feedTray,
    this.waterColor,
    this.ph,
    this.dissolvedOxygen,
    this.temperature,
    this.salinity,
    required this.photoUrlsJson,
    required this.syncStatus,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_log_id'] = Variable<String>(clientLogId);
    map['pond_id'] = Variable<String>(pondId);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    if (!nullToAbsent || feedGivenKg != null) {
      map['feed_given_kg'] = Variable<double>(feedGivenKg);
    }
    if (!nullToAbsent || mortalityCount != null) {
      map['mortality_count'] = Variable<int>(mortalityCount);
    }
    if (!nullToAbsent || feedTray != null) {
      map['feed_tray'] = Variable<int>(feedTray);
    }
    if (!nullToAbsent || waterColor != null) {
      map['water_color'] = Variable<int>(waterColor);
    }
    if (!nullToAbsent || ph != null) {
      map['ph'] = Variable<double>(ph);
    }
    if (!nullToAbsent || dissolvedOxygen != null) {
      map['dissolved_oxygen'] = Variable<double>(dissolvedOxygen);
    }
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<double>(temperature);
    }
    if (!nullToAbsent || salinity != null) {
      map['salinity'] = Variable<double>(salinity);
    }
    map['photo_urls_json'] = Variable<String>(photoUrlsJson);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalLogsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalLogsTableCompanion(
      clientLogId: Value(clientLogId),
      pondId: Value(pondId),
      loggedAt: Value(loggedAt),
      feedGivenKg: feedGivenKg == null && nullToAbsent
          ? const Value.absent()
          : Value(feedGivenKg),
      mortalityCount: mortalityCount == null && nullToAbsent
          ? const Value.absent()
          : Value(mortalityCount),
      feedTray: feedTray == null && nullToAbsent
          ? const Value.absent()
          : Value(feedTray),
      waterColor: waterColor == null && nullToAbsent
          ? const Value.absent()
          : Value(waterColor),
      ph: ph == null && nullToAbsent ? const Value.absent() : Value(ph),
      dissolvedOxygen: dissolvedOxygen == null && nullToAbsent
          ? const Value.absent()
          : Value(dissolvedOxygen),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      salinity: salinity == null && nullToAbsent
          ? const Value.absent()
          : Value(salinity),
      photoUrlsJson: Value(photoUrlsJson),
      syncStatus: Value(syncStatus),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory LocalLogsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalLogsTableData(
      clientLogId: serializer.fromJson<String>(json['clientLogId']),
      pondId: serializer.fromJson<String>(json['pondId']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
      feedGivenKg: serializer.fromJson<double?>(json['feedGivenKg']),
      mortalityCount: serializer.fromJson<int?>(json['mortalityCount']),
      feedTray: serializer.fromJson<int?>(json['feedTray']),
      waterColor: serializer.fromJson<int?>(json['waterColor']),
      ph: serializer.fromJson<double?>(json['ph']),
      dissolvedOxygen: serializer.fromJson<double?>(json['dissolvedOxygen']),
      temperature: serializer.fromJson<double?>(json['temperature']),
      salinity: serializer.fromJson<double?>(json['salinity']),
      photoUrlsJson: serializer.fromJson<String>(json['photoUrlsJson']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientLogId': serializer.toJson<String>(clientLogId),
      'pondId': serializer.toJson<String>(pondId),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
      'feedGivenKg': serializer.toJson<double?>(feedGivenKg),
      'mortalityCount': serializer.toJson<int?>(mortalityCount),
      'feedTray': serializer.toJson<int?>(feedTray),
      'waterColor': serializer.toJson<int?>(waterColor),
      'ph': serializer.toJson<double?>(ph),
      'dissolvedOxygen': serializer.toJson<double?>(dissolvedOxygen),
      'temperature': serializer.toJson<double?>(temperature),
      'salinity': serializer.toJson<double?>(salinity),
      'photoUrlsJson': serializer.toJson<String>(photoUrlsJson),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalLogsTableData copyWith({
    String? clientLogId,
    String? pondId,
    DateTime? loggedAt,
    Value<double?> feedGivenKg = const Value.absent(),
    Value<int?> mortalityCount = const Value.absent(),
    Value<int?> feedTray = const Value.absent(),
    Value<int?> waterColor = const Value.absent(),
    Value<double?> ph = const Value.absent(),
    Value<double?> dissolvedOxygen = const Value.absent(),
    Value<double?> temperature = const Value.absent(),
    Value<double?> salinity = const Value.absent(),
    String? photoUrlsJson,
    int? syncStatus,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => LocalLogsTableData(
    clientLogId: clientLogId ?? this.clientLogId,
    pondId: pondId ?? this.pondId,
    loggedAt: loggedAt ?? this.loggedAt,
    feedGivenKg: feedGivenKg.present ? feedGivenKg.value : this.feedGivenKg,
    mortalityCount: mortalityCount.present
        ? mortalityCount.value
        : this.mortalityCount,
    feedTray: feedTray.present ? feedTray.value : this.feedTray,
    waterColor: waterColor.present ? waterColor.value : this.waterColor,
    ph: ph.present ? ph.value : this.ph,
    dissolvedOxygen: dissolvedOxygen.present
        ? dissolvedOxygen.value
        : this.dissolvedOxygen,
    temperature: temperature.present ? temperature.value : this.temperature,
    salinity: salinity.present ? salinity.value : this.salinity,
    photoUrlsJson: photoUrlsJson ?? this.photoUrlsJson,
    syncStatus: syncStatus ?? this.syncStatus,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalLogsTableData copyWithCompanion(LocalLogsTableCompanion data) {
    return LocalLogsTableData(
      clientLogId: data.clientLogId.present
          ? data.clientLogId.value
          : this.clientLogId,
      pondId: data.pondId.present ? data.pondId.value : this.pondId,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
      feedGivenKg: data.feedGivenKg.present
          ? data.feedGivenKg.value
          : this.feedGivenKg,
      mortalityCount: data.mortalityCount.present
          ? data.mortalityCount.value
          : this.mortalityCount,
      feedTray: data.feedTray.present ? data.feedTray.value : this.feedTray,
      waterColor: data.waterColor.present
          ? data.waterColor.value
          : this.waterColor,
      ph: data.ph.present ? data.ph.value : this.ph,
      dissolvedOxygen: data.dissolvedOxygen.present
          ? data.dissolvedOxygen.value
          : this.dissolvedOxygen,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      salinity: data.salinity.present ? data.salinity.value : this.salinity,
      photoUrlsJson: data.photoUrlsJson.present
          ? data.photoUrlsJson.value
          : this.photoUrlsJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalLogsTableData(')
          ..write('clientLogId: $clientLogId, ')
          ..write('pondId: $pondId, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('feedGivenKg: $feedGivenKg, ')
          ..write('mortalityCount: $mortalityCount, ')
          ..write('feedTray: $feedTray, ')
          ..write('waterColor: $waterColor, ')
          ..write('ph: $ph, ')
          ..write('dissolvedOxygen: $dissolvedOxygen, ')
          ..write('temperature: $temperature, ')
          ..write('salinity: $salinity, ')
          ..write('photoUrlsJson: $photoUrlsJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientLogId,
    pondId,
    loggedAt,
    feedGivenKg,
    mortalityCount,
    feedTray,
    waterColor,
    ph,
    dissolvedOxygen,
    temperature,
    salinity,
    photoUrlsJson,
    syncStatus,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalLogsTableData &&
          other.clientLogId == this.clientLogId &&
          other.pondId == this.pondId &&
          other.loggedAt == this.loggedAt &&
          other.feedGivenKg == this.feedGivenKg &&
          other.mortalityCount == this.mortalityCount &&
          other.feedTray == this.feedTray &&
          other.waterColor == this.waterColor &&
          other.ph == this.ph &&
          other.dissolvedOxygen == this.dissolvedOxygen &&
          other.temperature == this.temperature &&
          other.salinity == this.salinity &&
          other.photoUrlsJson == this.photoUrlsJson &&
          other.syncStatus == this.syncStatus &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class LocalLogsTableCompanion extends UpdateCompanion<LocalLogsTableData> {
  final Value<String> clientLogId;
  final Value<String> pondId;
  final Value<DateTime> loggedAt;
  final Value<double?> feedGivenKg;
  final Value<int?> mortalityCount;
  final Value<int?> feedTray;
  final Value<int?> waterColor;
  final Value<double?> ph;
  final Value<double?> dissolvedOxygen;
  final Value<double?> temperature;
  final Value<double?> salinity;
  final Value<String> photoUrlsJson;
  final Value<int> syncStatus;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalLogsTableCompanion({
    this.clientLogId = const Value.absent(),
    this.pondId = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.feedGivenKg = const Value.absent(),
    this.mortalityCount = const Value.absent(),
    this.feedTray = const Value.absent(),
    this.waterColor = const Value.absent(),
    this.ph = const Value.absent(),
    this.dissolvedOxygen = const Value.absent(),
    this.temperature = const Value.absent(),
    this.salinity = const Value.absent(),
    this.photoUrlsJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalLogsTableCompanion.insert({
    required String clientLogId,
    required String pondId,
    required DateTime loggedAt,
    this.feedGivenKg = const Value.absent(),
    this.mortalityCount = const Value.absent(),
    this.feedTray = const Value.absent(),
    this.waterColor = const Value.absent(),
    this.ph = const Value.absent(),
    this.dissolvedOxygen = const Value.absent(),
    this.temperature = const Value.absent(),
    this.salinity = const Value.absent(),
    this.photoUrlsJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : clientLogId = Value(clientLogId),
       pondId = Value(pondId),
       loggedAt = Value(loggedAt),
       createdAt = Value(createdAt);
  static Insertable<LocalLogsTableData> custom({
    Expression<String>? clientLogId,
    Expression<String>? pondId,
    Expression<DateTime>? loggedAt,
    Expression<double>? feedGivenKg,
    Expression<int>? mortalityCount,
    Expression<int>? feedTray,
    Expression<int>? waterColor,
    Expression<double>? ph,
    Expression<double>? dissolvedOxygen,
    Expression<double>? temperature,
    Expression<double>? salinity,
    Expression<String>? photoUrlsJson,
    Expression<int>? syncStatus,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientLogId != null) 'client_log_id': clientLogId,
      if (pondId != null) 'pond_id': pondId,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (feedGivenKg != null) 'feed_given_kg': feedGivenKg,
      if (mortalityCount != null) 'mortality_count': mortalityCount,
      if (feedTray != null) 'feed_tray': feedTray,
      if (waterColor != null) 'water_color': waterColor,
      if (ph != null) 'ph': ph,
      if (dissolvedOxygen != null) 'dissolved_oxygen': dissolvedOxygen,
      if (temperature != null) 'temperature': temperature,
      if (salinity != null) 'salinity': salinity,
      if (photoUrlsJson != null) 'photo_urls_json': photoUrlsJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalLogsTableCompanion copyWith({
    Value<String>? clientLogId,
    Value<String>? pondId,
    Value<DateTime>? loggedAt,
    Value<double?>? feedGivenKg,
    Value<int?>? mortalityCount,
    Value<int?>? feedTray,
    Value<int?>? waterColor,
    Value<double?>? ph,
    Value<double?>? dissolvedOxygen,
    Value<double?>? temperature,
    Value<double?>? salinity,
    Value<String>? photoUrlsJson,
    Value<int>? syncStatus,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalLogsTableCompanion(
      clientLogId: clientLogId ?? this.clientLogId,
      pondId: pondId ?? this.pondId,
      loggedAt: loggedAt ?? this.loggedAt,
      feedGivenKg: feedGivenKg ?? this.feedGivenKg,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      feedTray: feedTray ?? this.feedTray,
      waterColor: waterColor ?? this.waterColor,
      ph: ph ?? this.ph,
      dissolvedOxygen: dissolvedOxygen ?? this.dissolvedOxygen,
      temperature: temperature ?? this.temperature,
      salinity: salinity ?? this.salinity,
      photoUrlsJson: photoUrlsJson ?? this.photoUrlsJson,
      syncStatus: syncStatus ?? this.syncStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientLogId.present) {
      map['client_log_id'] = Variable<String>(clientLogId.value);
    }
    if (pondId.present) {
      map['pond_id'] = Variable<String>(pondId.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    if (feedGivenKg.present) {
      map['feed_given_kg'] = Variable<double>(feedGivenKg.value);
    }
    if (mortalityCount.present) {
      map['mortality_count'] = Variable<int>(mortalityCount.value);
    }
    if (feedTray.present) {
      map['feed_tray'] = Variable<int>(feedTray.value);
    }
    if (waterColor.present) {
      map['water_color'] = Variable<int>(waterColor.value);
    }
    if (ph.present) {
      map['ph'] = Variable<double>(ph.value);
    }
    if (dissolvedOxygen.present) {
      map['dissolved_oxygen'] = Variable<double>(dissolvedOxygen.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (salinity.present) {
      map['salinity'] = Variable<double>(salinity.value);
    }
    if (photoUrlsJson.present) {
      map['photo_urls_json'] = Variable<String>(photoUrlsJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalLogsTableCompanion(')
          ..write('clientLogId: $clientLogId, ')
          ..write('pondId: $pondId, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('feedGivenKg: $feedGivenKg, ')
          ..write('mortalityCount: $mortalityCount, ')
          ..write('feedTray: $feedTray, ')
          ..write('waterColor: $waterColor, ')
          ..write('ph: $ph, ')
          ..write('dissolvedOxygen: $dissolvedOxygen, ')
          ..write('temperature: $temperature, ')
          ..write('salinity: $salinity, ')
          ..write('photoUrlsJson: $photoUrlsJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingMediaTableTable extends PendingMediaTable
    with TableInfo<$PendingMediaTableTable, PendingMediaTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingMediaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientMediaIdMeta = const VerificationMeta(
    'clientMediaId',
  );
  @override
  late final GeneratedColumn<String> clientMediaId = GeneratedColumn<String>(
    'client_media_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverMediaIdMeta = const VerificationMeta(
    'serverMediaId',
  );
  @override
  late final GeneratedColumn<String> serverMediaId = GeneratedColumn<String>(
    'server_media_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadUrlMeta = const VerificationMeta(
    'uploadUrl',
  );
  @override
  late final GeneratedColumn<String> uploadUrl = GeneratedColumn<String>(
    'upload_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _committedAtMeta = const VerificationMeta(
    'committedAt',
  );
  @override
  late final GeneratedColumn<DateTime> committedAt = GeneratedColumn<DateTime>(
    'committed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientMediaId,
    serverMediaId,
    localFilePath,
    uploadUrl,
    status,
    createdAt,
    committedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_media_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingMediaTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_media_id')) {
      context.handle(
        _clientMediaIdMeta,
        clientMediaId.isAcceptableOrUnknown(
          data['client_media_id']!,
          _clientMediaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientMediaIdMeta);
    }
    if (data.containsKey('server_media_id')) {
      context.handle(
        _serverMediaIdMeta,
        serverMediaId.isAcceptableOrUnknown(
          data['server_media_id']!,
          _serverMediaIdMeta,
        ),
      );
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localFilePathMeta);
    }
    if (data.containsKey('upload_url')) {
      context.handle(
        _uploadUrlMeta,
        uploadUrl.isAcceptableOrUnknown(data['upload_url']!, _uploadUrlMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('committed_at')) {
      context.handle(
        _committedAtMeta,
        committedAt.isAcceptableOrUnknown(
          data['committed_at']!,
          _committedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientMediaId};
  @override
  PendingMediaTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingMediaTableData(
      clientMediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_media_id'],
      )!,
      serverMediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_media_id'],
      ),
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      )!,
      uploadUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_url'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      committedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}committed_at'],
      ),
    );
  }

  @override
  $PendingMediaTableTable createAlias(String alias) {
    return $PendingMediaTableTable(attachedDatabase, alias);
  }
}

class PendingMediaTableData extends DataClass
    implements Insertable<PendingMediaTableData> {
  final String clientMediaId;
  final String? serverMediaId;
  final String localFilePath;
  final String? uploadUrl;
  final String status;
  final DateTime createdAt;
  final DateTime? committedAt;
  const PendingMediaTableData({
    required this.clientMediaId,
    this.serverMediaId,
    required this.localFilePath,
    this.uploadUrl,
    required this.status,
    required this.createdAt,
    this.committedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_media_id'] = Variable<String>(clientMediaId);
    if (!nullToAbsent || serverMediaId != null) {
      map['server_media_id'] = Variable<String>(serverMediaId);
    }
    map['local_file_path'] = Variable<String>(localFilePath);
    if (!nullToAbsent || uploadUrl != null) {
      map['upload_url'] = Variable<String>(uploadUrl);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || committedAt != null) {
      map['committed_at'] = Variable<DateTime>(committedAt);
    }
    return map;
  }

  PendingMediaTableCompanion toCompanion(bool nullToAbsent) {
    return PendingMediaTableCompanion(
      clientMediaId: Value(clientMediaId),
      serverMediaId: serverMediaId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverMediaId),
      localFilePath: Value(localFilePath),
      uploadUrl: uploadUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadUrl),
      status: Value(status),
      createdAt: Value(createdAt),
      committedAt: committedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(committedAt),
    );
  }

  factory PendingMediaTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingMediaTableData(
      clientMediaId: serializer.fromJson<String>(json['clientMediaId']),
      serverMediaId: serializer.fromJson<String?>(json['serverMediaId']),
      localFilePath: serializer.fromJson<String>(json['localFilePath']),
      uploadUrl: serializer.fromJson<String?>(json['uploadUrl']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      committedAt: serializer.fromJson<DateTime?>(json['committedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientMediaId': serializer.toJson<String>(clientMediaId),
      'serverMediaId': serializer.toJson<String?>(serverMediaId),
      'localFilePath': serializer.toJson<String>(localFilePath),
      'uploadUrl': serializer.toJson<String?>(uploadUrl),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'committedAt': serializer.toJson<DateTime?>(committedAt),
    };
  }

  PendingMediaTableData copyWith({
    String? clientMediaId,
    Value<String?> serverMediaId = const Value.absent(),
    String? localFilePath,
    Value<String?> uploadUrl = const Value.absent(),
    String? status,
    DateTime? createdAt,
    Value<DateTime?> committedAt = const Value.absent(),
  }) => PendingMediaTableData(
    clientMediaId: clientMediaId ?? this.clientMediaId,
    serverMediaId: serverMediaId.present
        ? serverMediaId.value
        : this.serverMediaId,
    localFilePath: localFilePath ?? this.localFilePath,
    uploadUrl: uploadUrl.present ? uploadUrl.value : this.uploadUrl,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    committedAt: committedAt.present ? committedAt.value : this.committedAt,
  );
  PendingMediaTableData copyWithCompanion(PendingMediaTableCompanion data) {
    return PendingMediaTableData(
      clientMediaId: data.clientMediaId.present
          ? data.clientMediaId.value
          : this.clientMediaId,
      serverMediaId: data.serverMediaId.present
          ? data.serverMediaId.value
          : this.serverMediaId,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      uploadUrl: data.uploadUrl.present ? data.uploadUrl.value : this.uploadUrl,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      committedAt: data.committedAt.present
          ? data.committedAt.value
          : this.committedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingMediaTableData(')
          ..write('clientMediaId: $clientMediaId, ')
          ..write('serverMediaId: $serverMediaId, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('uploadUrl: $uploadUrl, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('committedAt: $committedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientMediaId,
    serverMediaId,
    localFilePath,
    uploadUrl,
    status,
    createdAt,
    committedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMediaTableData &&
          other.clientMediaId == this.clientMediaId &&
          other.serverMediaId == this.serverMediaId &&
          other.localFilePath == this.localFilePath &&
          other.uploadUrl == this.uploadUrl &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.committedAt == this.committedAt);
}

class PendingMediaTableCompanion
    extends UpdateCompanion<PendingMediaTableData> {
  final Value<String> clientMediaId;
  final Value<String?> serverMediaId;
  final Value<String> localFilePath;
  final Value<String?> uploadUrl;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> committedAt;
  final Value<int> rowid;
  const PendingMediaTableCompanion({
    this.clientMediaId = const Value.absent(),
    this.serverMediaId = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.uploadUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.committedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingMediaTableCompanion.insert({
    required String clientMediaId,
    this.serverMediaId = const Value.absent(),
    required String localFilePath,
    this.uploadUrl = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.committedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientMediaId = Value(clientMediaId),
       localFilePath = Value(localFilePath),
       createdAt = Value(createdAt);
  static Insertable<PendingMediaTableData> custom({
    Expression<String>? clientMediaId,
    Expression<String>? serverMediaId,
    Expression<String>? localFilePath,
    Expression<String>? uploadUrl,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? committedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientMediaId != null) 'client_media_id': clientMediaId,
      if (serverMediaId != null) 'server_media_id': serverMediaId,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (uploadUrl != null) 'upload_url': uploadUrl,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (committedAt != null) 'committed_at': committedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingMediaTableCompanion copyWith({
    Value<String>? clientMediaId,
    Value<String?>? serverMediaId,
    Value<String>? localFilePath,
    Value<String?>? uploadUrl,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? committedAt,
    Value<int>? rowid,
  }) {
    return PendingMediaTableCompanion(
      clientMediaId: clientMediaId ?? this.clientMediaId,
      serverMediaId: serverMediaId ?? this.serverMediaId,
      localFilePath: localFilePath ?? this.localFilePath,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      committedAt: committedAt ?? this.committedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientMediaId.present) {
      map['client_media_id'] = Variable<String>(clientMediaId.value);
    }
    if (serverMediaId.present) {
      map['server_media_id'] = Variable<String>(serverMediaId.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (uploadUrl.present) {
      map['upload_url'] = Variable<String>(uploadUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (committedAt.present) {
      map['committed_at'] = Variable<DateTime>(committedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingMediaTableCompanion(')
          ..write('clientMediaId: $clientMediaId, ')
          ..write('serverMediaId: $serverMediaId, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('uploadUrl: $uploadUrl, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('committedAt: $committedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedUsersTableTable extends CachedUsersTable
    with TableInfo<$CachedUsersTableTable, CachedUsersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedUsersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _districtMeta = const VerificationMeta(
    'district',
  );
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
    'district',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredLanguageMeta = const VerificationMeta(
    'preferredLanguage',
  );
  @override
  late final GeneratedColumn<String> preferredLanguage =
      GeneratedColumn<String>(
        'preferred_language',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('ta'),
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    role,
    district,
    preferredLanguage,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_users_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedUsersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('district')) {
      context.handle(
        _districtMeta,
        district.isAcceptableOrUnknown(data['district']!, _districtMeta),
      );
    }
    if (data.containsKey('preferred_language')) {
      context.handle(
        _preferredLanguageMeta,
        preferredLanguage.isAcceptableOrUnknown(
          data['preferred_language']!,
          _preferredLanguageMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedUsersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedUsersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      district: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district'],
      ),
      preferredLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_language'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $CachedUsersTableTable createAlias(String alias) {
    return $CachedUsersTableTable(attachedDatabase, alias);
  }
}

class CachedUsersTableData extends DataClass
    implements Insertable<CachedUsersTableData> {
  final String id;
  final String? name;
  final String? phone;
  final String role;
  final String? district;
  final String preferredLanguage;
  final DateTime syncedAt;
  const CachedUsersTableData({
    required this.id,
    this.name,
    this.phone,
    required this.role,
    this.district,
    required this.preferredLanguage,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || district != null) {
      map['district'] = Variable<String>(district);
    }
    map['preferred_language'] = Variable<String>(preferredLanguage);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  CachedUsersTableCompanion toCompanion(bool nullToAbsent) {
    return CachedUsersTableCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      role: Value(role),
      district: district == null && nullToAbsent
          ? const Value.absent()
          : Value(district),
      preferredLanguage: Value(preferredLanguage),
      syncedAt: Value(syncedAt),
    );
  }

  factory CachedUsersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedUsersTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      role: serializer.fromJson<String>(json['role']),
      district: serializer.fromJson<String?>(json['district']),
      preferredLanguage: serializer.fromJson<String>(json['preferredLanguage']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'phone': serializer.toJson<String?>(phone),
      'role': serializer.toJson<String>(role),
      'district': serializer.toJson<String?>(district),
      'preferredLanguage': serializer.toJson<String>(preferredLanguage),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  CachedUsersTableData copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    String? role,
    Value<String?> district = const Value.absent(),
    String? preferredLanguage,
    DateTime? syncedAt,
  }) => CachedUsersTableData(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    phone: phone.present ? phone.value : this.phone,
    role: role ?? this.role,
    district: district.present ? district.value : this.district,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  CachedUsersTableData copyWithCompanion(CachedUsersTableCompanion data) {
    return CachedUsersTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      role: data.role.present ? data.role.value : this.role,
      district: data.district.present ? data.district.value : this.district,
      preferredLanguage: data.preferredLanguage.present
          ? data.preferredLanguage.value
          : this.preferredLanguage,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedUsersTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('district: $district, ')
          ..write('preferredLanguage: $preferredLanguage, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, role, district, preferredLanguage, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedUsersTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.role == this.role &&
          other.district == this.district &&
          other.preferredLanguage == this.preferredLanguage &&
          other.syncedAt == this.syncedAt);
}

class CachedUsersTableCompanion extends UpdateCompanion<CachedUsersTableData> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String?> phone;
  final Value<String> role;
  final Value<String?> district;
  final Value<String> preferredLanguage;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const CachedUsersTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.role = const Value.absent(),
    this.district = const Value.absent(),
    this.preferredLanguage = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedUsersTableCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    required String role,
    this.district = const Value.absent(),
    this.preferredLanguage = const Value.absent(),
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       role = Value(role),
       syncedAt = Value(syncedAt);
  static Insertable<CachedUsersTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? role,
    Expression<String>? district,
    Expression<String>? preferredLanguage,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (district != null) 'district': district,
      if (preferredLanguage != null) 'preferred_language': preferredLanguage,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedUsersTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String?>? phone,
    Value<String>? role,
    Value<String?>? district,
    Value<String>? preferredLanguage,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return CachedUsersTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      district: district ?? this.district,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (preferredLanguage.present) {
      map['preferred_language'] = Variable<String>(preferredLanguage.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedUsersTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('role: $role, ')
          ..write('district: $district, ')
          ..write('preferredLanguage: $preferredLanguage, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PondsTableTable pondsTable = $PondsTableTable(this);
  late final $LogsTableTable logsTable = $LogsTableTable(this);
  late final $AlertsTableTable alertsTable = $AlertsTableTable(this);
  late final $DashboardCacheTableTable dashboardCacheTable =
      $DashboardCacheTableTable(this);
  late final $OutboxTableTable outboxTable = $OutboxTableTable(this);
  late final $LocalLogsTableTable localLogsTable = $LocalLogsTableTable(this);
  late final $PendingMediaTableTable pendingMediaTable =
      $PendingMediaTableTable(this);
  late final $CachedUsersTableTable cachedUsersTable = $CachedUsersTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pondsTable,
    logsTable,
    alertsTable,
    dashboardCacheTable,
    outboxTable,
    localLogsTable,
    pendingMediaTable,
    cachedUsersTable,
  ];
}

typedef $$PondsTableTableCreateCompanionBuilder =
    PondsTableCompanion Function({
      required String id,
      required String name,
      Value<String?> farmerId,
      Value<String?> location,
      Value<double?> areaSqM,
      Value<double?> depthM,
      Value<String?> linerType,
      Value<String?> waterSource,
      Value<DateTime?> stockingDate,
      Value<String?> species,
      Value<int> status,
      Value<DateTime?> lastUpdated,
      Value<int> rowid,
    });
typedef $$PondsTableTableUpdateCompanionBuilder =
    PondsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> farmerId,
      Value<String?> location,
      Value<double?> areaSqM,
      Value<double?> depthM,
      Value<String?> linerType,
      Value<String?> waterSource,
      Value<DateTime?> stockingDate,
      Value<String?> species,
      Value<int> status,
      Value<DateTime?> lastUpdated,
      Value<int> rowid,
    });

class $$PondsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PondsTableTable> {
  $$PondsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get farmerId => $composableBuilder(
    column: $table.farmerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get areaSqM => $composableBuilder(
    column: $table.areaSqM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get depthM => $composableBuilder(
    column: $table.depthM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linerType => $composableBuilder(
    column: $table.linerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get waterSource => $composableBuilder(
    column: $table.waterSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get stockingDate => $composableBuilder(
    column: $table.stockingDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PondsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PondsTableTable> {
  $$PondsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get farmerId => $composableBuilder(
    column: $table.farmerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get areaSqM => $composableBuilder(
    column: $table.areaSqM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get depthM => $composableBuilder(
    column: $table.depthM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linerType => $composableBuilder(
    column: $table.linerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waterSource => $composableBuilder(
    column: $table.waterSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get stockingDate => $composableBuilder(
    column: $table.stockingDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PondsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PondsTableTable> {
  $$PondsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get farmerId =>
      $composableBuilder(column: $table.farmerId, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<double> get areaSqM =>
      $composableBuilder(column: $table.areaSqM, builder: (column) => column);

  GeneratedColumn<double> get depthM =>
      $composableBuilder(column: $table.depthM, builder: (column) => column);

  GeneratedColumn<String> get linerType =>
      $composableBuilder(column: $table.linerType, builder: (column) => column);

  GeneratedColumn<String> get waterSource => $composableBuilder(
    column: $table.waterSource,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get stockingDate => $composableBuilder(
    column: $table.stockingDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get species =>
      $composableBuilder(column: $table.species, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );
}

class $$PondsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PondsTableTable,
          PondsTableData,
          $$PondsTableTableFilterComposer,
          $$PondsTableTableOrderingComposer,
          $$PondsTableTableAnnotationComposer,
          $$PondsTableTableCreateCompanionBuilder,
          $$PondsTableTableUpdateCompanionBuilder,
          (
            PondsTableData,
            BaseReferences<_$AppDatabase, $PondsTableTable, PondsTableData>,
          ),
          PondsTableData,
          PrefetchHooks Function()
        > {
  $$PondsTableTableTableManager(_$AppDatabase db, $PondsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PondsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PondsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PondsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> farmerId = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double?> areaSqM = const Value.absent(),
                Value<double?> depthM = const Value.absent(),
                Value<String?> linerType = const Value.absent(),
                Value<String?> waterSource = const Value.absent(),
                Value<DateTime?> stockingDate = const Value.absent(),
                Value<String?> species = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PondsTableCompanion(
                id: id,
                name: name,
                farmerId: farmerId,
                location: location,
                areaSqM: areaSqM,
                depthM: depthM,
                linerType: linerType,
                waterSource: waterSource,
                stockingDate: stockingDate,
                species: species,
                status: status,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> farmerId = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double?> areaSqM = const Value.absent(),
                Value<double?> depthM = const Value.absent(),
                Value<String?> linerType = const Value.absent(),
                Value<String?> waterSource = const Value.absent(),
                Value<DateTime?> stockingDate = const Value.absent(),
                Value<String?> species = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PondsTableCompanion.insert(
                id: id,
                name: name,
                farmerId: farmerId,
                location: location,
                areaSqM: areaSqM,
                depthM: depthM,
                linerType: linerType,
                waterSource: waterSource,
                stockingDate: stockingDate,
                species: species,
                status: status,
                lastUpdated: lastUpdated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PondsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PondsTableTable,
      PondsTableData,
      $$PondsTableTableFilterComposer,
      $$PondsTableTableOrderingComposer,
      $$PondsTableTableAnnotationComposer,
      $$PondsTableTableCreateCompanionBuilder,
      $$PondsTableTableUpdateCompanionBuilder,
      (
        PondsTableData,
        BaseReferences<_$AppDatabase, $PondsTableTable, PondsTableData>,
      ),
      PondsTableData,
      PrefetchHooks Function()
    >;
typedef $$LogsTableTableCreateCompanionBuilder =
    LogsTableCompanion Function({
      required String id,
      required String pondId,
      required DateTime loggedAt,
      Value<double?> feedGivenKg,
      Value<int?> mortalityCount,
      Value<int?> feedTray,
      Value<int?> waterColor,
      Value<double?> ph,
      Value<double?> dissolvedOxygen,
      Value<double?> temperature,
      Value<double?> salinity,
      required String photoUrlsJson,
      required int syncStatus,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$LogsTableTableUpdateCompanionBuilder =
    LogsTableCompanion Function({
      Value<String> id,
      Value<String> pondId,
      Value<DateTime> loggedAt,
      Value<double?> feedGivenKg,
      Value<int?> mortalityCount,
      Value<int?> feedTray,
      Value<int?> waterColor,
      Value<double?> ph,
      Value<double?> dissolvedOxygen,
      Value<double?> temperature,
      Value<double?> salinity,
      Value<String> photoUrlsJson,
      Value<int> syncStatus,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$LogsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LogsTableTable> {
  $$LogsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get feedGivenKg => $composableBuilder(
    column: $table.feedGivenKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mortalityCount => $composableBuilder(
    column: $table.mortalityCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedTray => $composableBuilder(
    column: $table.feedTray,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get waterColor => $composableBuilder(
    column: $table.waterColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dissolvedOxygen => $composableBuilder(
    column: $table.dissolvedOxygen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salinity => $composableBuilder(
    column: $table.salinity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrlsJson => $composableBuilder(
    column: $table.photoUrlsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LogsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LogsTableTable> {
  $$LogsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get feedGivenKg => $composableBuilder(
    column: $table.feedGivenKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mortalityCount => $composableBuilder(
    column: $table.mortalityCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedTray => $composableBuilder(
    column: $table.feedTray,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get waterColor => $composableBuilder(
    column: $table.waterColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dissolvedOxygen => $composableBuilder(
    column: $table.dissolvedOxygen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salinity => $composableBuilder(
    column: $table.salinity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrlsJson => $composableBuilder(
    column: $table.photoUrlsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LogsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogsTableTable> {
  $$LogsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pondId =>
      $composableBuilder(column: $table.pondId, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<double> get feedGivenKg => $composableBuilder(
    column: $table.feedGivenKg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mortalityCount => $composableBuilder(
    column: $table.mortalityCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get feedTray =>
      $composableBuilder(column: $table.feedTray, builder: (column) => column);

  GeneratedColumn<int> get waterColor => $composableBuilder(
    column: $table.waterColor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ph =>
      $composableBuilder(column: $table.ph, builder: (column) => column);

  GeneratedColumn<double> get dissolvedOxygen => $composableBuilder(
    column: $table.dissolvedOxygen,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get salinity =>
      $composableBuilder(column: $table.salinity, builder: (column) => column);

  GeneratedColumn<String> get photoUrlsJson => $composableBuilder(
    column: $table.photoUrlsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$LogsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogsTableTable,
          LogsTableData,
          $$LogsTableTableFilterComposer,
          $$LogsTableTableOrderingComposer,
          $$LogsTableTableAnnotationComposer,
          $$LogsTableTableCreateCompanionBuilder,
          $$LogsTableTableUpdateCompanionBuilder,
          (
            LogsTableData,
            BaseReferences<_$AppDatabase, $LogsTableTable, LogsTableData>,
          ),
          LogsTableData,
          PrefetchHooks Function()
        > {
  $$LogsTableTableTableManager(_$AppDatabase db, $LogsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pondId = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<double?> feedGivenKg = const Value.absent(),
                Value<int?> mortalityCount = const Value.absent(),
                Value<int?> feedTray = const Value.absent(),
                Value<int?> waterColor = const Value.absent(),
                Value<double?> ph = const Value.absent(),
                Value<double?> dissolvedOxygen = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<double?> salinity = const Value.absent(),
                Value<String> photoUrlsJson = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogsTableCompanion(
                id: id,
                pondId: pondId,
                loggedAt: loggedAt,
                feedGivenKg: feedGivenKg,
                mortalityCount: mortalityCount,
                feedTray: feedTray,
                waterColor: waterColor,
                ph: ph,
                dissolvedOxygen: dissolvedOxygen,
                temperature: temperature,
                salinity: salinity,
                photoUrlsJson: photoUrlsJson,
                syncStatus: syncStatus,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pondId,
                required DateTime loggedAt,
                Value<double?> feedGivenKg = const Value.absent(),
                Value<int?> mortalityCount = const Value.absent(),
                Value<int?> feedTray = const Value.absent(),
                Value<int?> waterColor = const Value.absent(),
                Value<double?> ph = const Value.absent(),
                Value<double?> dissolvedOxygen = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<double?> salinity = const Value.absent(),
                required String photoUrlsJson,
                required int syncStatus,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogsTableCompanion.insert(
                id: id,
                pondId: pondId,
                loggedAt: loggedAt,
                feedGivenKg: feedGivenKg,
                mortalityCount: mortalityCount,
                feedTray: feedTray,
                waterColor: waterColor,
                ph: ph,
                dissolvedOxygen: dissolvedOxygen,
                temperature: temperature,
                salinity: salinity,
                photoUrlsJson: photoUrlsJson,
                syncStatus: syncStatus,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LogsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogsTableTable,
      LogsTableData,
      $$LogsTableTableFilterComposer,
      $$LogsTableTableOrderingComposer,
      $$LogsTableTableAnnotationComposer,
      $$LogsTableTableCreateCompanionBuilder,
      $$LogsTableTableUpdateCompanionBuilder,
      (
        LogsTableData,
        BaseReferences<_$AppDatabase, $LogsTableTable, LogsTableData>,
      ),
      LogsTableData,
      PrefetchHooks Function()
    >;
typedef $$AlertsTableTableCreateCompanionBuilder =
    AlertsTableCompanion Function({
      required String id,
      Value<String?> pondId,
      Value<String?> pondName,
      required String alertType,
      required String severity,
      required String title,
      required String message,
      Value<bool> suppressed,
      Value<String?> suppressionReason,
      Value<bool> acked,
      Value<DateTime?> ackedAt,
      Value<double?> riskScore,
      required DateTime createdAt,
      Value<int?> feedback,
      Value<int> rowid,
    });
typedef $$AlertsTableTableUpdateCompanionBuilder =
    AlertsTableCompanion Function({
      Value<String> id,
      Value<String?> pondId,
      Value<String?> pondName,
      Value<String> alertType,
      Value<String> severity,
      Value<String> title,
      Value<String> message,
      Value<bool> suppressed,
      Value<String?> suppressionReason,
      Value<bool> acked,
      Value<DateTime?> ackedAt,
      Value<double?> riskScore,
      Value<DateTime> createdAt,
      Value<int?> feedback,
      Value<int> rowid,
    });

class $$AlertsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AlertsTableTable> {
  $$AlertsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pondName => $composableBuilder(
    column: $table.pondName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get suppressed => $composableBuilder(
    column: $table.suppressed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suppressionReason => $composableBuilder(
    column: $table.suppressionReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get acked => $composableBuilder(
    column: $table.acked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ackedAt => $composableBuilder(
    column: $table.ackedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get riskScore => $composableBuilder(
    column: $table.riskScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedback => $composableBuilder(
    column: $table.feedback,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlertsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertsTableTable> {
  $$AlertsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pondName => $composableBuilder(
    column: $table.pondName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alertType => $composableBuilder(
    column: $table.alertType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get suppressed => $composableBuilder(
    column: $table.suppressed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suppressionReason => $composableBuilder(
    column: $table.suppressionReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get acked => $composableBuilder(
    column: $table.acked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ackedAt => $composableBuilder(
    column: $table.ackedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get riskScore => $composableBuilder(
    column: $table.riskScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedback => $composableBuilder(
    column: $table.feedback,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertsTableTable> {
  $$AlertsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pondId =>
      $composableBuilder(column: $table.pondId, builder: (column) => column);

  GeneratedColumn<String> get pondName =>
      $composableBuilder(column: $table.pondName, builder: (column) => column);

  GeneratedColumn<String> get alertType =>
      $composableBuilder(column: $table.alertType, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<bool> get suppressed => $composableBuilder(
    column: $table.suppressed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get suppressionReason => $composableBuilder(
    column: $table.suppressionReason,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get acked =>
      $composableBuilder(column: $table.acked, builder: (column) => column);

  GeneratedColumn<DateTime> get ackedAt =>
      $composableBuilder(column: $table.ackedAt, builder: (column) => column);

  GeneratedColumn<double> get riskScore =>
      $composableBuilder(column: $table.riskScore, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get feedback =>
      $composableBuilder(column: $table.feedback, builder: (column) => column);
}

class $$AlertsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertsTableTable,
          AlertsTableData,
          $$AlertsTableTableFilterComposer,
          $$AlertsTableTableOrderingComposer,
          $$AlertsTableTableAnnotationComposer,
          $$AlertsTableTableCreateCompanionBuilder,
          $$AlertsTableTableUpdateCompanionBuilder,
          (
            AlertsTableData,
            BaseReferences<_$AppDatabase, $AlertsTableTable, AlertsTableData>,
          ),
          AlertsTableData,
          PrefetchHooks Function()
        > {
  $$AlertsTableTableTableManager(_$AppDatabase db, $AlertsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> pondId = const Value.absent(),
                Value<String?> pondName = const Value.absent(),
                Value<String> alertType = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<bool> suppressed = const Value.absent(),
                Value<String?> suppressionReason = const Value.absent(),
                Value<bool> acked = const Value.absent(),
                Value<DateTime?> ackedAt = const Value.absent(),
                Value<double?> riskScore = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> feedback = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsTableCompanion(
                id: id,
                pondId: pondId,
                pondName: pondName,
                alertType: alertType,
                severity: severity,
                title: title,
                message: message,
                suppressed: suppressed,
                suppressionReason: suppressionReason,
                acked: acked,
                ackedAt: ackedAt,
                riskScore: riskScore,
                createdAt: createdAt,
                feedback: feedback,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> pondId = const Value.absent(),
                Value<String?> pondName = const Value.absent(),
                required String alertType,
                required String severity,
                required String title,
                required String message,
                Value<bool> suppressed = const Value.absent(),
                Value<String?> suppressionReason = const Value.absent(),
                Value<bool> acked = const Value.absent(),
                Value<DateTime?> ackedAt = const Value.absent(),
                Value<double?> riskScore = const Value.absent(),
                required DateTime createdAt,
                Value<int?> feedback = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsTableCompanion.insert(
                id: id,
                pondId: pondId,
                pondName: pondName,
                alertType: alertType,
                severity: severity,
                title: title,
                message: message,
                suppressed: suppressed,
                suppressionReason: suppressionReason,
                acked: acked,
                ackedAt: ackedAt,
                riskScore: riskScore,
                createdAt: createdAt,
                feedback: feedback,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertsTableTable,
      AlertsTableData,
      $$AlertsTableTableFilterComposer,
      $$AlertsTableTableOrderingComposer,
      $$AlertsTableTableAnnotationComposer,
      $$AlertsTableTableCreateCompanionBuilder,
      $$AlertsTableTableUpdateCompanionBuilder,
      (
        AlertsTableData,
        BaseReferences<_$AppDatabase, $AlertsTableTable, AlertsTableData>,
      ),
      AlertsTableData,
      PrefetchHooks Function()
    >;
typedef $$DashboardCacheTableTableCreateCompanionBuilder =
    DashboardCacheTableCompanion Function({
      required String cacheKey,
      required String payloadBlob,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$DashboardCacheTableTableUpdateCompanionBuilder =
    DashboardCacheTableCompanion Function({
      Value<String> cacheKey,
      Value<String> payloadBlob,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$DashboardCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $DashboardCacheTableTable> {
  $$DashboardCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadBlob => $composableBuilder(
    column: $table.payloadBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DashboardCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DashboardCacheTableTable> {
  $$DashboardCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadBlob => $composableBuilder(
    column: $table.payloadBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DashboardCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DashboardCacheTableTable> {
  $$DashboardCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get payloadBlob => $composableBuilder(
    column: $table.payloadBlob,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$DashboardCacheTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DashboardCacheTableTable,
          DashboardCacheTableData,
          $$DashboardCacheTableTableFilterComposer,
          $$DashboardCacheTableTableOrderingComposer,
          $$DashboardCacheTableTableAnnotationComposer,
          $$DashboardCacheTableTableCreateCompanionBuilder,
          $$DashboardCacheTableTableUpdateCompanionBuilder,
          (
            DashboardCacheTableData,
            BaseReferences<
              _$AppDatabase,
              $DashboardCacheTableTable,
              DashboardCacheTableData
            >,
          ),
          DashboardCacheTableData,
          PrefetchHooks Function()
        > {
  $$DashboardCacheTableTableTableManager(
    _$AppDatabase db,
    $DashboardCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DashboardCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DashboardCacheTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DashboardCacheTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> payloadBlob = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DashboardCacheTableCompanion(
                cacheKey: cacheKey,
                payloadBlob: payloadBlob,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String payloadBlob,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => DashboardCacheTableCompanion.insert(
                cacheKey: cacheKey,
                payloadBlob: payloadBlob,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DashboardCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DashboardCacheTableTable,
      DashboardCacheTableData,
      $$DashboardCacheTableTableFilterComposer,
      $$DashboardCacheTableTableOrderingComposer,
      $$DashboardCacheTableTableAnnotationComposer,
      $$DashboardCacheTableTableCreateCompanionBuilder,
      $$DashboardCacheTableTableUpdateCompanionBuilder,
      (
        DashboardCacheTableData,
        BaseReferences<
          _$AppDatabase,
          $DashboardCacheTableTable,
          DashboardCacheTableData
        >,
      ),
      DashboardCacheTableData,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableTableCreateCompanionBuilder =
    OutboxTableCompanion Function({
      required String id,
      required String clientLogId,
      required String entityType,
      required String payloadJson,
      Value<String> status,
      required DateTime createdAt,
      Value<DateTime?> syncedAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$OutboxTableTableUpdateCompanionBuilder =
    OutboxTableCompanion Function({
      Value<String> id,
      Value<String> clientLogId,
      Value<String> entityType,
      Value<String> payloadJson,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> syncedAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$OutboxTableTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientLogId => $composableBuilder(
    column: $table.clientLogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientLogId => $composableBuilder(
    column: $table.clientLogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTableTable> {
  $$OutboxTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientLogId => $composableBuilder(
    column: $table.clientLogId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTableTable,
          OutboxTableData,
          $$OutboxTableTableFilterComposer,
          $$OutboxTableTableOrderingComposer,
          $$OutboxTableTableAnnotationComposer,
          $$OutboxTableTableCreateCompanionBuilder,
          $$OutboxTableTableUpdateCompanionBuilder,
          (
            OutboxTableData,
            BaseReferences<_$AppDatabase, $OutboxTableTable, OutboxTableData>,
          ),
          OutboxTableData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableTableManager(_$AppDatabase db, $OutboxTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> clientLogId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxTableCompanion(
                id: id,
                clientLogId: clientLogId,
                entityType: entityType,
                payloadJson: payloadJson,
                status: status,
                createdAt: createdAt,
                syncedAt: syncedAt,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String clientLogId,
                required String entityType,
                required String payloadJson,
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxTableCompanion.insert(
                id: id,
                clientLogId: clientLogId,
                entityType: entityType,
                payloadJson: payloadJson,
                status: status,
                createdAt: createdAt,
                syncedAt: syncedAt,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTableTable,
      OutboxTableData,
      $$OutboxTableTableFilterComposer,
      $$OutboxTableTableOrderingComposer,
      $$OutboxTableTableAnnotationComposer,
      $$OutboxTableTableCreateCompanionBuilder,
      $$OutboxTableTableUpdateCompanionBuilder,
      (
        OutboxTableData,
        BaseReferences<_$AppDatabase, $OutboxTableTable, OutboxTableData>,
      ),
      OutboxTableData,
      PrefetchHooks Function()
    >;
typedef $$LocalLogsTableTableCreateCompanionBuilder =
    LocalLogsTableCompanion Function({
      required String clientLogId,
      required String pondId,
      required DateTime loggedAt,
      Value<double?> feedGivenKg,
      Value<int?> mortalityCount,
      Value<int?> feedTray,
      Value<int?> waterColor,
      Value<double?> ph,
      Value<double?> dissolvedOxygen,
      Value<double?> temperature,
      Value<double?> salinity,
      Value<String> photoUrlsJson,
      Value<int> syncStatus,
      Value<String?> notes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalLogsTableTableUpdateCompanionBuilder =
    LocalLogsTableCompanion Function({
      Value<String> clientLogId,
      Value<String> pondId,
      Value<DateTime> loggedAt,
      Value<double?> feedGivenKg,
      Value<int?> mortalityCount,
      Value<int?> feedTray,
      Value<int?> waterColor,
      Value<double?> ph,
      Value<double?> dissolvedOxygen,
      Value<double?> temperature,
      Value<double?> salinity,
      Value<String> photoUrlsJson,
      Value<int> syncStatus,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalLogsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalLogsTableTable> {
  $$LocalLogsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientLogId => $composableBuilder(
    column: $table.clientLogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get feedGivenKg => $composableBuilder(
    column: $table.feedGivenKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mortalityCount => $composableBuilder(
    column: $table.mortalityCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedTray => $composableBuilder(
    column: $table.feedTray,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get waterColor => $composableBuilder(
    column: $table.waterColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dissolvedOxygen => $composableBuilder(
    column: $table.dissolvedOxygen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salinity => $composableBuilder(
    column: $table.salinity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrlsJson => $composableBuilder(
    column: $table.photoUrlsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalLogsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalLogsTableTable> {
  $$LocalLogsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientLogId => $composableBuilder(
    column: $table.clientLogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pondId => $composableBuilder(
    column: $table.pondId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get feedGivenKg => $composableBuilder(
    column: $table.feedGivenKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mortalityCount => $composableBuilder(
    column: $table.mortalityCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedTray => $composableBuilder(
    column: $table.feedTray,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get waterColor => $composableBuilder(
    column: $table.waterColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ph => $composableBuilder(
    column: $table.ph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dissolvedOxygen => $composableBuilder(
    column: $table.dissolvedOxygen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salinity => $composableBuilder(
    column: $table.salinity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrlsJson => $composableBuilder(
    column: $table.photoUrlsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalLogsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalLogsTableTable> {
  $$LocalLogsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientLogId => $composableBuilder(
    column: $table.clientLogId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pondId =>
      $composableBuilder(column: $table.pondId, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<double> get feedGivenKg => $composableBuilder(
    column: $table.feedGivenKg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mortalityCount => $composableBuilder(
    column: $table.mortalityCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get feedTray =>
      $composableBuilder(column: $table.feedTray, builder: (column) => column);

  GeneratedColumn<int> get waterColor => $composableBuilder(
    column: $table.waterColor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ph =>
      $composableBuilder(column: $table.ph, builder: (column) => column);

  GeneratedColumn<double> get dissolvedOxygen => $composableBuilder(
    column: $table.dissolvedOxygen,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get salinity =>
      $composableBuilder(column: $table.salinity, builder: (column) => column);

  GeneratedColumn<String> get photoUrlsJson => $composableBuilder(
    column: $table.photoUrlsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalLogsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalLogsTableTable,
          LocalLogsTableData,
          $$LocalLogsTableTableFilterComposer,
          $$LocalLogsTableTableOrderingComposer,
          $$LocalLogsTableTableAnnotationComposer,
          $$LocalLogsTableTableCreateCompanionBuilder,
          $$LocalLogsTableTableUpdateCompanionBuilder,
          (
            LocalLogsTableData,
            BaseReferences<
              _$AppDatabase,
              $LocalLogsTableTable,
              LocalLogsTableData
            >,
          ),
          LocalLogsTableData,
          PrefetchHooks Function()
        > {
  $$LocalLogsTableTableTableManager(
    _$AppDatabase db,
    $LocalLogsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalLogsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalLogsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalLogsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientLogId = const Value.absent(),
                Value<String> pondId = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
                Value<double?> feedGivenKg = const Value.absent(),
                Value<int?> mortalityCount = const Value.absent(),
                Value<int?> feedTray = const Value.absent(),
                Value<int?> waterColor = const Value.absent(),
                Value<double?> ph = const Value.absent(),
                Value<double?> dissolvedOxygen = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<double?> salinity = const Value.absent(),
                Value<String> photoUrlsJson = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalLogsTableCompanion(
                clientLogId: clientLogId,
                pondId: pondId,
                loggedAt: loggedAt,
                feedGivenKg: feedGivenKg,
                mortalityCount: mortalityCount,
                feedTray: feedTray,
                waterColor: waterColor,
                ph: ph,
                dissolvedOxygen: dissolvedOxygen,
                temperature: temperature,
                salinity: salinity,
                photoUrlsJson: photoUrlsJson,
                syncStatus: syncStatus,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientLogId,
                required String pondId,
                required DateTime loggedAt,
                Value<double?> feedGivenKg = const Value.absent(),
                Value<int?> mortalityCount = const Value.absent(),
                Value<int?> feedTray = const Value.absent(),
                Value<int?> waterColor = const Value.absent(),
                Value<double?> ph = const Value.absent(),
                Value<double?> dissolvedOxygen = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<double?> salinity = const Value.absent(),
                Value<String> photoUrlsJson = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalLogsTableCompanion.insert(
                clientLogId: clientLogId,
                pondId: pondId,
                loggedAt: loggedAt,
                feedGivenKg: feedGivenKg,
                mortalityCount: mortalityCount,
                feedTray: feedTray,
                waterColor: waterColor,
                ph: ph,
                dissolvedOxygen: dissolvedOxygen,
                temperature: temperature,
                salinity: salinity,
                photoUrlsJson: photoUrlsJson,
                syncStatus: syncStatus,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalLogsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalLogsTableTable,
      LocalLogsTableData,
      $$LocalLogsTableTableFilterComposer,
      $$LocalLogsTableTableOrderingComposer,
      $$LocalLogsTableTableAnnotationComposer,
      $$LocalLogsTableTableCreateCompanionBuilder,
      $$LocalLogsTableTableUpdateCompanionBuilder,
      (
        LocalLogsTableData,
        BaseReferences<_$AppDatabase, $LocalLogsTableTable, LocalLogsTableData>,
      ),
      LocalLogsTableData,
      PrefetchHooks Function()
    >;
typedef $$PendingMediaTableTableCreateCompanionBuilder =
    PendingMediaTableCompanion Function({
      required String clientMediaId,
      Value<String?> serverMediaId,
      required String localFilePath,
      Value<String?> uploadUrl,
      Value<String> status,
      required DateTime createdAt,
      Value<DateTime?> committedAt,
      Value<int> rowid,
    });
typedef $$PendingMediaTableTableUpdateCompanionBuilder =
    PendingMediaTableCompanion Function({
      Value<String> clientMediaId,
      Value<String?> serverMediaId,
      Value<String> localFilePath,
      Value<String?> uploadUrl,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> committedAt,
      Value<int> rowid,
    });

class $$PendingMediaTableTableFilterComposer
    extends Composer<_$AppDatabase, $PendingMediaTableTable> {
  $$PendingMediaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientMediaId => $composableBuilder(
    column: $table.clientMediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverMediaId => $composableBuilder(
    column: $table.serverMediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadUrl => $composableBuilder(
    column: $table.uploadUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingMediaTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingMediaTableTable> {
  $$PendingMediaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientMediaId => $composableBuilder(
    column: $table.clientMediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverMediaId => $composableBuilder(
    column: $table.serverMediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadUrl => $composableBuilder(
    column: $table.uploadUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingMediaTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingMediaTableTable> {
  $$PendingMediaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientMediaId => $composableBuilder(
    column: $table.clientMediaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverMediaId => $composableBuilder(
    column: $table.serverMediaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadUrl =>
      $composableBuilder(column: $table.uploadUrl, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => column,
  );
}

class $$PendingMediaTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingMediaTableTable,
          PendingMediaTableData,
          $$PendingMediaTableTableFilterComposer,
          $$PendingMediaTableTableOrderingComposer,
          $$PendingMediaTableTableAnnotationComposer,
          $$PendingMediaTableTableCreateCompanionBuilder,
          $$PendingMediaTableTableUpdateCompanionBuilder,
          (
            PendingMediaTableData,
            BaseReferences<
              _$AppDatabase,
              $PendingMediaTableTable,
              PendingMediaTableData
            >,
          ),
          PendingMediaTableData,
          PrefetchHooks Function()
        > {
  $$PendingMediaTableTableTableManager(
    _$AppDatabase db,
    $PendingMediaTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingMediaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingMediaTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingMediaTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> clientMediaId = const Value.absent(),
                Value<String?> serverMediaId = const Value.absent(),
                Value<String> localFilePath = const Value.absent(),
                Value<String?> uploadUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> committedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingMediaTableCompanion(
                clientMediaId: clientMediaId,
                serverMediaId: serverMediaId,
                localFilePath: localFilePath,
                uploadUrl: uploadUrl,
                status: status,
                createdAt: createdAt,
                committedAt: committedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientMediaId,
                Value<String?> serverMediaId = const Value.absent(),
                required String localFilePath,
                Value<String?> uploadUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> committedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingMediaTableCompanion.insert(
                clientMediaId: clientMediaId,
                serverMediaId: serverMediaId,
                localFilePath: localFilePath,
                uploadUrl: uploadUrl,
                status: status,
                createdAt: createdAt,
                committedAt: committedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingMediaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingMediaTableTable,
      PendingMediaTableData,
      $$PendingMediaTableTableFilterComposer,
      $$PendingMediaTableTableOrderingComposer,
      $$PendingMediaTableTableAnnotationComposer,
      $$PendingMediaTableTableCreateCompanionBuilder,
      $$PendingMediaTableTableUpdateCompanionBuilder,
      (
        PendingMediaTableData,
        BaseReferences<
          _$AppDatabase,
          $PendingMediaTableTable,
          PendingMediaTableData
        >,
      ),
      PendingMediaTableData,
      PrefetchHooks Function()
    >;
typedef $$CachedUsersTableTableCreateCompanionBuilder =
    CachedUsersTableCompanion Function({
      required String id,
      Value<String?> name,
      Value<String?> phone,
      required String role,
      Value<String?> district,
      Value<String> preferredLanguage,
      required DateTime syncedAt,
      Value<int> rowid,
    });
typedef $$CachedUsersTableTableUpdateCompanionBuilder =
    CachedUsersTableCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String?> phone,
      Value<String> role,
      Value<String?> district,
      Value<String> preferredLanguage,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

class $$CachedUsersTableTableFilterComposer
    extends Composer<_$AppDatabase, $CachedUsersTableTable> {
  $$CachedUsersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredLanguage => $composableBuilder(
    column: $table.preferredLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedUsersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedUsersTableTable> {
  $$CachedUsersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredLanguage => $composableBuilder(
    column: $table.preferredLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedUsersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedUsersTableTable> {
  $$CachedUsersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get district =>
      $composableBuilder(column: $table.district, builder: (column) => column);

  GeneratedColumn<String> get preferredLanguage => $composableBuilder(
    column: $table.preferredLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$CachedUsersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedUsersTableTable,
          CachedUsersTableData,
          $$CachedUsersTableTableFilterComposer,
          $$CachedUsersTableTableOrderingComposer,
          $$CachedUsersTableTableAnnotationComposer,
          $$CachedUsersTableTableCreateCompanionBuilder,
          $$CachedUsersTableTableUpdateCompanionBuilder,
          (
            CachedUsersTableData,
            BaseReferences<
              _$AppDatabase,
              $CachedUsersTableTable,
              CachedUsersTableData
            >,
          ),
          CachedUsersTableData,
          PrefetchHooks Function()
        > {
  $$CachedUsersTableTableTableManager(
    _$AppDatabase db,
    $CachedUsersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedUsersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedUsersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedUsersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> district = const Value.absent(),
                Value<String> preferredLanguage = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedUsersTableCompanion(
                id: id,
                name: name,
                phone: phone,
                role: role,
                district: district,
                preferredLanguage: preferredLanguage,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                required String role,
                Value<String?> district = const Value.absent(),
                Value<String> preferredLanguage = const Value.absent(),
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedUsersTableCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                role: role,
                district: district,
                preferredLanguage: preferredLanguage,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedUsersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedUsersTableTable,
      CachedUsersTableData,
      $$CachedUsersTableTableFilterComposer,
      $$CachedUsersTableTableOrderingComposer,
      $$CachedUsersTableTableAnnotationComposer,
      $$CachedUsersTableTableCreateCompanionBuilder,
      $$CachedUsersTableTableUpdateCompanionBuilder,
      (
        CachedUsersTableData,
        BaseReferences<
          _$AppDatabase,
          $CachedUsersTableTable,
          CachedUsersTableData
        >,
      ),
      CachedUsersTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PondsTableTableTableManager get pondsTable =>
      $$PondsTableTableTableManager(_db, _db.pondsTable);
  $$LogsTableTableTableManager get logsTable =>
      $$LogsTableTableTableManager(_db, _db.logsTable);
  $$AlertsTableTableTableManager get alertsTable =>
      $$AlertsTableTableTableManager(_db, _db.alertsTable);
  $$DashboardCacheTableTableTableManager get dashboardCacheTable =>
      $$DashboardCacheTableTableTableManager(_db, _db.dashboardCacheTable);
  $$OutboxTableTableTableManager get outboxTable =>
      $$OutboxTableTableTableManager(_db, _db.outboxTable);
  $$LocalLogsTableTableTableManager get localLogsTable =>
      $$LocalLogsTableTableTableManager(_db, _db.localLogsTable);
  $$PendingMediaTableTableTableManager get pendingMediaTable =>
      $$PendingMediaTableTableTableManager(_db, _db.pendingMediaTable);
  $$CachedUsersTableTableTableManager get cachedUsersTable =>
      $$CachedUsersTableTableTableManager(_db, _db.cachedUsersTable);
}
