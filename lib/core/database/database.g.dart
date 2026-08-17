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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areaSqMMeta = const VerificationMeta(
    'areaSqM',
  );
  @override
  late final GeneratedColumn<double> areaSqM = GeneratedColumn<double>(
    'area_sq_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _depthMMeta = const VerificationMeta('depthM');
  @override
  late final GeneratedColumn<double> depthM = GeneratedColumn<double>(
    'depth_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linerTypeMeta = const VerificationMeta(
    'linerType',
  );
  @override
  late final GeneratedColumn<String> linerType = GeneratedColumn<String>(
    'liner_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _waterSourceMeta = const VerificationMeta(
    'waterSource',
  );
  @override
  late final GeneratedColumn<String> waterSource = GeneratedColumn<String>(
    'water_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockingDateMeta = const VerificationMeta(
    'stockingDate',
  );
  @override
  late final GeneratedColumn<DateTime> stockingDate = GeneratedColumn<DateTime>(
    'stocking_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speciesMeta = const VerificationMeta(
    'species',
  );
  @override
  late final GeneratedColumn<String> species = GeneratedColumn<String>(
    'species',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
    } else if (isInserting) {
      context.missing(_farmerIdMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('area_sq_m')) {
      context.handle(
        _areaSqMMeta,
        areaSqM.isAcceptableOrUnknown(data['area_sq_m']!, _areaSqMMeta),
      );
    } else if (isInserting) {
      context.missing(_areaSqMMeta);
    }
    if (data.containsKey('depth_m')) {
      context.handle(
        _depthMMeta,
        depthM.isAcceptableOrUnknown(data['depth_m']!, _depthMMeta),
      );
    } else if (isInserting) {
      context.missing(_depthMMeta);
    }
    if (data.containsKey('liner_type')) {
      context.handle(
        _linerTypeMeta,
        linerType.isAcceptableOrUnknown(data['liner_type']!, _linerTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_linerTypeMeta);
    }
    if (data.containsKey('water_source')) {
      context.handle(
        _waterSourceMeta,
        waterSource.isAcceptableOrUnknown(
          data['water_source']!,
          _waterSourceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_waterSourceMeta);
    }
    if (data.containsKey('stocking_date')) {
      context.handle(
        _stockingDateMeta,
        stockingDate.isAcceptableOrUnknown(
          data['stocking_date']!,
          _stockingDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stockingDateMeta);
    }
    if (data.containsKey('species')) {
      context.handle(
        _speciesMeta,
        species.isAcceptableOrUnknown(data['species']!, _speciesMeta),
      );
    } else if (isInserting) {
      context.missing(_speciesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
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
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      areaSqM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}area_sq_m'],
      )!,
      depthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}depth_m'],
      )!,
      linerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}liner_type'],
      )!,
      waterSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}water_source'],
      )!,
      stockingDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stocking_date'],
      )!,
      species: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}species'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      )!,
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
  final String farmerId;
  final String location;
  final double areaSqM;
  final double depthM;
  final String linerType;
  final String waterSource;
  final DateTime stockingDate;
  final String species;
  final int status;
  final DateTime lastUpdated;
  const PondsTableData({
    required this.id,
    required this.name,
    required this.farmerId,
    required this.location,
    required this.areaSqM,
    required this.depthM,
    required this.linerType,
    required this.waterSource,
    required this.stockingDate,
    required this.species,
    required this.status,
    required this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['farmer_id'] = Variable<String>(farmerId);
    map['location'] = Variable<String>(location);
    map['area_sq_m'] = Variable<double>(areaSqM);
    map['depth_m'] = Variable<double>(depthM);
    map['liner_type'] = Variable<String>(linerType);
    map['water_source'] = Variable<String>(waterSource);
    map['stocking_date'] = Variable<DateTime>(stockingDate);
    map['species'] = Variable<String>(species);
    map['status'] = Variable<int>(status);
    map['last_updated'] = Variable<DateTime>(lastUpdated);
    return map;
  }

  PondsTableCompanion toCompanion(bool nullToAbsent) {
    return PondsTableCompanion(
      id: Value(id),
      name: Value(name),
      farmerId: Value(farmerId),
      location: Value(location),
      areaSqM: Value(areaSqM),
      depthM: Value(depthM),
      linerType: Value(linerType),
      waterSource: Value(waterSource),
      stockingDate: Value(stockingDate),
      species: Value(species),
      status: Value(status),
      lastUpdated: Value(lastUpdated),
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
      farmerId: serializer.fromJson<String>(json['farmerId']),
      location: serializer.fromJson<String>(json['location']),
      areaSqM: serializer.fromJson<double>(json['areaSqM']),
      depthM: serializer.fromJson<double>(json['depthM']),
      linerType: serializer.fromJson<String>(json['linerType']),
      waterSource: serializer.fromJson<String>(json['waterSource']),
      stockingDate: serializer.fromJson<DateTime>(json['stockingDate']),
      species: serializer.fromJson<String>(json['species']),
      status: serializer.fromJson<int>(json['status']),
      lastUpdated: serializer.fromJson<DateTime>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'farmerId': serializer.toJson<String>(farmerId),
      'location': serializer.toJson<String>(location),
      'areaSqM': serializer.toJson<double>(areaSqM),
      'depthM': serializer.toJson<double>(depthM),
      'linerType': serializer.toJson<String>(linerType),
      'waterSource': serializer.toJson<String>(waterSource),
      'stockingDate': serializer.toJson<DateTime>(stockingDate),
      'species': serializer.toJson<String>(species),
      'status': serializer.toJson<int>(status),
      'lastUpdated': serializer.toJson<DateTime>(lastUpdated),
    };
  }

  PondsTableData copyWith({
    String? id,
    String? name,
    String? farmerId,
    String? location,
    double? areaSqM,
    double? depthM,
    String? linerType,
    String? waterSource,
    DateTime? stockingDate,
    String? species,
    int? status,
    DateTime? lastUpdated,
  }) => PondsTableData(
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
  final Value<String> farmerId;
  final Value<String> location;
  final Value<double> areaSqM;
  final Value<double> depthM;
  final Value<String> linerType;
  final Value<String> waterSource;
  final Value<DateTime> stockingDate;
  final Value<String> species;
  final Value<int> status;
  final Value<DateTime> lastUpdated;
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
    required String farmerId,
    required String location,
    required double areaSqM,
    required double depthM,
    required String linerType,
    required String waterSource,
    required DateTime stockingDate,
    required String species,
    required int status,
    required DateTime lastUpdated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       farmerId = Value(farmerId),
       location = Value(location),
       areaSqM = Value(areaSqM),
       depthM = Value(depthM),
       linerType = Value(linerType),
       waterSource = Value(waterSource),
       stockingDate = Value(stockingDate),
       species = Value(species),
       status = Value(status),
       lastUpdated = Value(lastUpdated);
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
    Value<String>? farmerId,
    Value<String>? location,
    Value<double>? areaSqM,
    Value<double>? depthM,
    Value<String>? linerType,
    Value<String>? waterSource,
    Value<DateTime>? stockingDate,
    Value<String>? species,
    Value<int>? status,
    Value<DateTime>? lastUpdated,
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
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _whatMeta = const VerificationMeta('what');
  @override
  late final GeneratedColumn<String> what = GeneratedColumn<String>(
    'what',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _whyMeta = const VerificationMeta('why');
  @override
  late final GeneratedColumn<String> why = GeneratedColumn<String>(
    'why',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acknowledgedMeta = const VerificationMeta(
    'acknowledged',
  );
  @override
  late final GeneratedColumn<bool> acknowledged = GeneratedColumn<bool>(
    'acknowledged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("acknowledged" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _isLowConfidenceMeta = const VerificationMeta(
    'isLowConfidence',
  );
  @override
  late final GeneratedColumn<bool> isLowConfidence = GeneratedColumn<bool>(
    'is_low_confidence',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_low_confidence" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _hasSuppressionReasonMeta =
      const VerificationMeta('hasSuppressionReason');
  @override
  late final GeneratedColumn<bool> hasSuppressionReason = GeneratedColumn<bool>(
    'has_suppression_reason',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_suppression_reason" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    severity,
    title,
    description,
    what,
    why,
    action,
    timestamp,
    acknowledged,
    feedback,
    isLowConfidence,
    hasSuppressionReason,
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('what')) {
      context.handle(
        _whatMeta,
        what.isAcceptableOrUnknown(data['what']!, _whatMeta),
      );
    } else if (isInserting) {
      context.missing(_whatMeta);
    }
    if (data.containsKey('why')) {
      context.handle(
        _whyMeta,
        why.isAcceptableOrUnknown(data['why']!, _whyMeta),
      );
    } else if (isInserting) {
      context.missing(_whyMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('acknowledged')) {
      context.handle(
        _acknowledgedMeta,
        acknowledged.isAcceptableOrUnknown(
          data['acknowledged']!,
          _acknowledgedMeta,
        ),
      );
    }
    if (data.containsKey('feedback')) {
      context.handle(
        _feedbackMeta,
        feedback.isAcceptableOrUnknown(data['feedback']!, _feedbackMeta),
      );
    }
    if (data.containsKey('is_low_confidence')) {
      context.handle(
        _isLowConfidenceMeta,
        isLowConfidence.isAcceptableOrUnknown(
          data['is_low_confidence']!,
          _isLowConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('has_suppression_reason')) {
      context.handle(
        _hasSuppressionReasonMeta,
        hasSuppressionReason.isAcceptableOrUnknown(
          data['has_suppression_reason']!,
          _hasSuppressionReasonMeta,
        ),
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
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}severity'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      what: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}what'],
      )!,
      why: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}why'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      acknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}acknowledged'],
      )!,
      feedback: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feedback'],
      ),
      isLowConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_low_confidence'],
      )!,
      hasSuppressionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_suppression_reason'],
      )!,
    );
  }

  @override
  $AlertsTableTable createAlias(String alias) {
    return $AlertsTableTable(attachedDatabase, alias);
  }
}

class AlertsTableData extends DataClass implements Insertable<AlertsTableData> {
  final String id;
  final int severity;
  final String title;
  final String description;
  final String what;
  final String why;
  final String action;
  final DateTime timestamp;
  final bool acknowledged;
  final int? feedback;
  final bool isLowConfidence;
  final bool hasSuppressionReason;
  const AlertsTableData({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    required this.what,
    required this.why,
    required this.action,
    required this.timestamp,
    required this.acknowledged,
    this.feedback,
    required this.isLowConfidence,
    required this.hasSuppressionReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['severity'] = Variable<int>(severity);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['what'] = Variable<String>(what);
    map['why'] = Variable<String>(why);
    map['action'] = Variable<String>(action);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['acknowledged'] = Variable<bool>(acknowledged);
    if (!nullToAbsent || feedback != null) {
      map['feedback'] = Variable<int>(feedback);
    }
    map['is_low_confidence'] = Variable<bool>(isLowConfidence);
    map['has_suppression_reason'] = Variable<bool>(hasSuppressionReason);
    return map;
  }

  AlertsTableCompanion toCompanion(bool nullToAbsent) {
    return AlertsTableCompanion(
      id: Value(id),
      severity: Value(severity),
      title: Value(title),
      description: Value(description),
      what: Value(what),
      why: Value(why),
      action: Value(action),
      timestamp: Value(timestamp),
      acknowledged: Value(acknowledged),
      feedback: feedback == null && nullToAbsent
          ? const Value.absent()
          : Value(feedback),
      isLowConfidence: Value(isLowConfidence),
      hasSuppressionReason: Value(hasSuppressionReason),
    );
  }

  factory AlertsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertsTableData(
      id: serializer.fromJson<String>(json['id']),
      severity: serializer.fromJson<int>(json['severity']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      what: serializer.fromJson<String>(json['what']),
      why: serializer.fromJson<String>(json['why']),
      action: serializer.fromJson<String>(json['action']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      acknowledged: serializer.fromJson<bool>(json['acknowledged']),
      feedback: serializer.fromJson<int?>(json['feedback']),
      isLowConfidence: serializer.fromJson<bool>(json['isLowConfidence']),
      hasSuppressionReason: serializer.fromJson<bool>(
        json['hasSuppressionReason'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'severity': serializer.toJson<int>(severity),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'what': serializer.toJson<String>(what),
      'why': serializer.toJson<String>(why),
      'action': serializer.toJson<String>(action),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'acknowledged': serializer.toJson<bool>(acknowledged),
      'feedback': serializer.toJson<int?>(feedback),
      'isLowConfidence': serializer.toJson<bool>(isLowConfidence),
      'hasSuppressionReason': serializer.toJson<bool>(hasSuppressionReason),
    };
  }

  AlertsTableData copyWith({
    String? id,
    int? severity,
    String? title,
    String? description,
    String? what,
    String? why,
    String? action,
    DateTime? timestamp,
    bool? acknowledged,
    Value<int?> feedback = const Value.absent(),
    bool? isLowConfidence,
    bool? hasSuppressionReason,
  }) => AlertsTableData(
    id: id ?? this.id,
    severity: severity ?? this.severity,
    title: title ?? this.title,
    description: description ?? this.description,
    what: what ?? this.what,
    why: why ?? this.why,
    action: action ?? this.action,
    timestamp: timestamp ?? this.timestamp,
    acknowledged: acknowledged ?? this.acknowledged,
    feedback: feedback.present ? feedback.value : this.feedback,
    isLowConfidence: isLowConfidence ?? this.isLowConfidence,
    hasSuppressionReason: hasSuppressionReason ?? this.hasSuppressionReason,
  );
  AlertsTableData copyWithCompanion(AlertsTableCompanion data) {
    return AlertsTableData(
      id: data.id.present ? data.id.value : this.id,
      severity: data.severity.present ? data.severity.value : this.severity,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      what: data.what.present ? data.what.value : this.what,
      why: data.why.present ? data.why.value : this.why,
      action: data.action.present ? data.action.value : this.action,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      acknowledged: data.acknowledged.present
          ? data.acknowledged.value
          : this.acknowledged,
      feedback: data.feedback.present ? data.feedback.value : this.feedback,
      isLowConfidence: data.isLowConfidence.present
          ? data.isLowConfidence.value
          : this.isLowConfidence,
      hasSuppressionReason: data.hasSuppressionReason.present
          ? data.hasSuppressionReason.value
          : this.hasSuppressionReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertsTableData(')
          ..write('id: $id, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('what: $what, ')
          ..write('why: $why, ')
          ..write('action: $action, ')
          ..write('timestamp: $timestamp, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('feedback: $feedback, ')
          ..write('isLowConfidence: $isLowConfidence, ')
          ..write('hasSuppressionReason: $hasSuppressionReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    severity,
    title,
    description,
    what,
    why,
    action,
    timestamp,
    acknowledged,
    feedback,
    isLowConfidence,
    hasSuppressionReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertsTableData &&
          other.id == this.id &&
          other.severity == this.severity &&
          other.title == this.title &&
          other.description == this.description &&
          other.what == this.what &&
          other.why == this.why &&
          other.action == this.action &&
          other.timestamp == this.timestamp &&
          other.acknowledged == this.acknowledged &&
          other.feedback == this.feedback &&
          other.isLowConfidence == this.isLowConfidence &&
          other.hasSuppressionReason == this.hasSuppressionReason);
}

class AlertsTableCompanion extends UpdateCompanion<AlertsTableData> {
  final Value<String> id;
  final Value<int> severity;
  final Value<String> title;
  final Value<String> description;
  final Value<String> what;
  final Value<String> why;
  final Value<String> action;
  final Value<DateTime> timestamp;
  final Value<bool> acknowledged;
  final Value<int?> feedback;
  final Value<bool> isLowConfidence;
  final Value<bool> hasSuppressionReason;
  final Value<int> rowid;
  const AlertsTableCompanion({
    this.id = const Value.absent(),
    this.severity = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.what = const Value.absent(),
    this.why = const Value.absent(),
    this.action = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.acknowledged = const Value.absent(),
    this.feedback = const Value.absent(),
    this.isLowConfidence = const Value.absent(),
    this.hasSuppressionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertsTableCompanion.insert({
    required String id,
    required int severity,
    required String title,
    required String description,
    required String what,
    required String why,
    required String action,
    required DateTime timestamp,
    this.acknowledged = const Value.absent(),
    this.feedback = const Value.absent(),
    this.isLowConfidence = const Value.absent(),
    this.hasSuppressionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       severity = Value(severity),
       title = Value(title),
       description = Value(description),
       what = Value(what),
       why = Value(why),
       action = Value(action),
       timestamp = Value(timestamp);
  static Insertable<AlertsTableData> custom({
    Expression<String>? id,
    Expression<int>? severity,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? what,
    Expression<String>? why,
    Expression<String>? action,
    Expression<DateTime>? timestamp,
    Expression<bool>? acknowledged,
    Expression<int>? feedback,
    Expression<bool>? isLowConfidence,
    Expression<bool>? hasSuppressionReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (what != null) 'what': what,
      if (why != null) 'why': why,
      if (action != null) 'action': action,
      if (timestamp != null) 'timestamp': timestamp,
      if (acknowledged != null) 'acknowledged': acknowledged,
      if (feedback != null) 'feedback': feedback,
      if (isLowConfidence != null) 'is_low_confidence': isLowConfidence,
      if (hasSuppressionReason != null)
        'has_suppression_reason': hasSuppressionReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? severity,
    Value<String>? title,
    Value<String>? description,
    Value<String>? what,
    Value<String>? why,
    Value<String>? action,
    Value<DateTime>? timestamp,
    Value<bool>? acknowledged,
    Value<int?>? feedback,
    Value<bool>? isLowConfidence,
    Value<bool>? hasSuppressionReason,
    Value<int>? rowid,
  }) {
    return AlertsTableCompanion(
      id: id ?? this.id,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      what: what ?? this.what,
      why: why ?? this.why,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
      feedback: feedback ?? this.feedback,
      isLowConfidence: isLowConfidence ?? this.isLowConfidence,
      hasSuppressionReason: hasSuppressionReason ?? this.hasSuppressionReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (severity.present) {
      map['severity'] = Variable<int>(severity.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (what.present) {
      map['what'] = Variable<String>(what.value);
    }
    if (why.present) {
      map['why'] = Variable<String>(why.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (acknowledged.present) {
      map['acknowledged'] = Variable<bool>(acknowledged.value);
    }
    if (feedback.present) {
      map['feedback'] = Variable<int>(feedback.value);
    }
    if (isLowConfidence.present) {
      map['is_low_confidence'] = Variable<bool>(isLowConfidence.value);
    }
    if (hasSuppressionReason.present) {
      map['has_suppression_reason'] = Variable<bool>(
        hasSuppressionReason.value,
      );
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
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('what: $what, ')
          ..write('why: $why, ')
          ..write('action: $action, ')
          ..write('timestamp: $timestamp, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('feedback: $feedback, ')
          ..write('isLowConfidence: $isLowConfidence, ')
          ..write('hasSuppressionReason: $hasSuppressionReason, ')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pondsTable,
    logsTable,
    alertsTable,
  ];
}

typedef $$PondsTableTableCreateCompanionBuilder =
    PondsTableCompanion Function({
      required String id,
      required String name,
      required String farmerId,
      required String location,
      required double areaSqM,
      required double depthM,
      required String linerType,
      required String waterSource,
      required DateTime stockingDate,
      required String species,
      required int status,
      required DateTime lastUpdated,
      Value<int> rowid,
    });
typedef $$PondsTableTableUpdateCompanionBuilder =
    PondsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> farmerId,
      Value<String> location,
      Value<double> areaSqM,
      Value<double> depthM,
      Value<String> linerType,
      Value<String> waterSource,
      Value<DateTime> stockingDate,
      Value<String> species,
      Value<int> status,
      Value<DateTime> lastUpdated,
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
                Value<String> farmerId = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<double> areaSqM = const Value.absent(),
                Value<double> depthM = const Value.absent(),
                Value<String> linerType = const Value.absent(),
                Value<String> waterSource = const Value.absent(),
                Value<DateTime> stockingDate = const Value.absent(),
                Value<String> species = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<DateTime> lastUpdated = const Value.absent(),
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
                required String farmerId,
                required String location,
                required double areaSqM,
                required double depthM,
                required String linerType,
                required String waterSource,
                required DateTime stockingDate,
                required String species,
                required int status,
                required DateTime lastUpdated,
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
      required int severity,
      required String title,
      required String description,
      required String what,
      required String why,
      required String action,
      required DateTime timestamp,
      Value<bool> acknowledged,
      Value<int?> feedback,
      Value<bool> isLowConfidence,
      Value<bool> hasSuppressionReason,
      Value<int> rowid,
    });
typedef $$AlertsTableTableUpdateCompanionBuilder =
    AlertsTableCompanion Function({
      Value<String> id,
      Value<int> severity,
      Value<String> title,
      Value<String> description,
      Value<String> what,
      Value<String> why,
      Value<String> action,
      Value<DateTime> timestamp,
      Value<bool> acknowledged,
      Value<int?> feedback,
      Value<bool> isLowConfidence,
      Value<bool> hasSuppressionReason,
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

  ColumnFilters<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get what => $composableBuilder(
    column: $table.what,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedback => $composableBuilder(
    column: $table.feedback,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLowConfidence => $composableBuilder(
    column: $table.isLowConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasSuppressionReason => $composableBuilder(
    column: $table.hasSuppressionReason,
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

  ColumnOrderings<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get what => $composableBuilder(
    column: $table.what,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedback => $composableBuilder(
    column: $table.feedback,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLowConfidence => $composableBuilder(
    column: $table.isLowConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasSuppressionReason => $composableBuilder(
    column: $table.hasSuppressionReason,
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

  GeneratedColumn<int> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get what =>
      $composableBuilder(column: $table.what, builder: (column) => column);

  GeneratedColumn<String> get why =>
      $composableBuilder(column: $table.why, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => column,
  );

  GeneratedColumn<int> get feedback =>
      $composableBuilder(column: $table.feedback, builder: (column) => column);

  GeneratedColumn<bool> get isLowConfidence => $composableBuilder(
    column: $table.isLowConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasSuppressionReason => $composableBuilder(
    column: $table.hasSuppressionReason,
    builder: (column) => column,
  );
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
                Value<int> severity = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> what = const Value.absent(),
                Value<String> why = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> acknowledged = const Value.absent(),
                Value<int?> feedback = const Value.absent(),
                Value<bool> isLowConfidence = const Value.absent(),
                Value<bool> hasSuppressionReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsTableCompanion(
                id: id,
                severity: severity,
                title: title,
                description: description,
                what: what,
                why: why,
                action: action,
                timestamp: timestamp,
                acknowledged: acknowledged,
                feedback: feedback,
                isLowConfidence: isLowConfidence,
                hasSuppressionReason: hasSuppressionReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int severity,
                required String title,
                required String description,
                required String what,
                required String why,
                required String action,
                required DateTime timestamp,
                Value<bool> acknowledged = const Value.absent(),
                Value<int?> feedback = const Value.absent(),
                Value<bool> isLowConfidence = const Value.absent(),
                Value<bool> hasSuppressionReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertsTableCompanion.insert(
                id: id,
                severity: severity,
                title: title,
                description: description,
                what: what,
                why: why,
                action: action,
                timestamp: timestamp,
                acknowledged: acknowledged,
                feedback: feedback,
                isLowConfidence: isLowConfidence,
                hasSuppressionReason: hasSuppressionReason,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PondsTableTableTableManager get pondsTable =>
      $$PondsTableTableTableManager(_db, _db.pondsTable);
  $$LogsTableTableTableManager get logsTable =>
      $$LogsTableTableTableManager(_db, _db.logsTable);
  $$AlertsTableTableTableManager get alertsTable =>
      $$AlertsTableTableTableManager(_db, _db.alertsTable);
}
