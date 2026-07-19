// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HouseholdsTable extends Households
    with TableInfo<$HouseholdsTable, DbHousehold> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
  );
  static const VerificationMeta _primaryLanguageMeta = const VerificationMeta(
    'primaryLanguage',
  );
  @override
  late final GeneratedColumn<String> primaryLanguage = GeneratedColumn<String>(
    'primary_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ar'),
  );
  static const VerificationMeta _memberUserNameMeta = const VerificationMeta(
    'memberUserName',
  );
  @override
  late final GeneratedColumn<String> memberUserName = GeneratedColumn<String>(
    'member_user_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _memberSpouseNameMeta = const VerificationMeta(
    'memberSpouseName',
  );
  @override
  late final GeneratedColumn<String> memberSpouseName = GeneratedColumn<String>(
    'member_spouse_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memberChildNameMeta = const VerificationMeta(
    'memberChildName',
  );
  @override
  late final GeneratedColumn<String> memberChildName = GeneratedColumn<String>(
    'member_child_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    ownerUserId,
    currencyCode,
    primaryLanguage,
    memberUserName,
    memberSpouseName,
    memberChildName,
    createdAt,
    updatedAt,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'households';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbHousehold> instance, {
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
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ownerUserIdMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('primary_language')) {
      context.handle(
        _primaryLanguageMeta,
        primaryLanguage.isAcceptableOrUnknown(
          data['primary_language']!,
          _primaryLanguageMeta,
        ),
      );
    }
    if (data.containsKey('member_user_name')) {
      context.handle(
        _memberUserNameMeta,
        memberUserName.isAcceptableOrUnknown(
          data['member_user_name']!,
          _memberUserNameMeta,
        ),
      );
    }
    if (data.containsKey('member_spouse_name')) {
      context.handle(
        _memberSpouseNameMeta,
        memberSpouseName.isAcceptableOrUnknown(
          data['member_spouse_name']!,
          _memberSpouseNameMeta,
        ),
      );
    }
    if (data.containsKey('member_child_name')) {
      context.handle(
        _memberChildNameMeta,
        memberChildName.isAcceptableOrUnknown(
          data['member_child_name']!,
          _memberChildNameMeta,
        ),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbHousehold map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbHousehold(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      primaryLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_language'],
      )!,
      memberUserName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_user_name'],
      )!,
      memberSpouseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_spouse_name'],
      ),
      memberChildName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_child_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $HouseholdsTable createAlias(String alias) {
    return $HouseholdsTable(attachedDatabase, alias);
  }
}

class DbHousehold extends DataClass implements Insertable<DbHousehold> {
  final String id;
  final String name;
  final String ownerUserId;

  /// ISO 4217 currency code. Default 'EGP' for V1.
  final String currencyCode;
  final String primaryLanguage;
  final String memberUserName;
  final String? memberSpouseName;
  final String? memberChildName;
  final String createdAt;
  final String updatedAt;

  /// Schema version for data migration. Current version: 1.
  final int schemaVersion;
  const DbHousehold({
    required this.id,
    required this.name,
    required this.ownerUserId,
    required this.currencyCode,
    required this.primaryLanguage,
    required this.memberUserName,
    this.memberSpouseName,
    this.memberChildName,
    required this.createdAt,
    required this.updatedAt,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['owner_user_id'] = Variable<String>(ownerUserId);
    map['currency_code'] = Variable<String>(currencyCode);
    map['primary_language'] = Variable<String>(primaryLanguage);
    map['member_user_name'] = Variable<String>(memberUserName);
    if (!nullToAbsent || memberSpouseName != null) {
      map['member_spouse_name'] = Variable<String>(memberSpouseName);
    }
    if (!nullToAbsent || memberChildName != null) {
      map['member_child_name'] = Variable<String>(memberChildName);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  HouseholdsCompanion toCompanion(bool nullToAbsent) {
    return HouseholdsCompanion(
      id: Value(id),
      name: Value(name),
      ownerUserId: Value(ownerUserId),
      currencyCode: Value(currencyCode),
      primaryLanguage: Value(primaryLanguage),
      memberUserName: Value(memberUserName),
      memberSpouseName: memberSpouseName == null && nullToAbsent
          ? const Value.absent()
          : Value(memberSpouseName),
      memberChildName: memberChildName == null && nullToAbsent
          ? const Value.absent()
          : Value(memberChildName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory DbHousehold.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbHousehold(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerUserId: serializer.fromJson<String>(json['ownerUserId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      primaryLanguage: serializer.fromJson<String>(json['primaryLanguage']),
      memberUserName: serializer.fromJson<String>(json['memberUserName']),
      memberSpouseName: serializer.fromJson<String?>(json['memberSpouseName']),
      memberChildName: serializer.fromJson<String?>(json['memberChildName']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'ownerUserId': serializer.toJson<String>(ownerUserId),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'primaryLanguage': serializer.toJson<String>(primaryLanguage),
      'memberUserName': serializer.toJson<String>(memberUserName),
      'memberSpouseName': serializer.toJson<String?>(memberSpouseName),
      'memberChildName': serializer.toJson<String?>(memberChildName),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  DbHousehold copyWith({
    String? id,
    String? name,
    String? ownerUserId,
    String? currencyCode,
    String? primaryLanguage,
    String? memberUserName,
    Value<String?> memberSpouseName = const Value.absent(),
    Value<String?> memberChildName = const Value.absent(),
    String? createdAt,
    String? updatedAt,
    int? schemaVersion,
  }) => DbHousehold(
    id: id ?? this.id,
    name: name ?? this.name,
    ownerUserId: ownerUserId ?? this.ownerUserId,
    currencyCode: currencyCode ?? this.currencyCode,
    primaryLanguage: primaryLanguage ?? this.primaryLanguage,
    memberUserName: memberUserName ?? this.memberUserName,
    memberSpouseName: memberSpouseName.present
        ? memberSpouseName.value
        : this.memberSpouseName,
    memberChildName: memberChildName.present
        ? memberChildName.value
        : this.memberChildName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  DbHousehold copyWithCompanion(HouseholdsCompanion data) {
    return DbHousehold(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      primaryLanguage: data.primaryLanguage.present
          ? data.primaryLanguage.value
          : this.primaryLanguage,
      memberUserName: data.memberUserName.present
          ? data.memberUserName.value
          : this.memberUserName,
      memberSpouseName: data.memberSpouseName.present
          ? data.memberSpouseName.value
          : this.memberSpouseName,
      memberChildName: data.memberChildName.present
          ? data.memberChildName.value
          : this.memberChildName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbHousehold(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('primaryLanguage: $primaryLanguage, ')
          ..write('memberUserName: $memberUserName, ')
          ..write('memberSpouseName: $memberSpouseName, ')
          ..write('memberChildName: $memberChildName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    ownerUserId,
    currencyCode,
    primaryLanguage,
    memberUserName,
    memberSpouseName,
    memberChildName,
    createdAt,
    updatedAt,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbHousehold &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerUserId == this.ownerUserId &&
          other.currencyCode == this.currencyCode &&
          other.primaryLanguage == this.primaryLanguage &&
          other.memberUserName == this.memberUserName &&
          other.memberSpouseName == this.memberSpouseName &&
          other.memberChildName == this.memberChildName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.schemaVersion == this.schemaVersion);
}

class HouseholdsCompanion extends UpdateCompanion<DbHousehold> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> ownerUserId;
  final Value<String> currencyCode;
  final Value<String> primaryLanguage;
  final Value<String> memberUserName;
  final Value<String?> memberSpouseName;
  final Value<String?> memberChildName;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const HouseholdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.primaryLanguage = const Value.absent(),
    this.memberUserName = const Value.absent(),
    this.memberSpouseName = const Value.absent(),
    this.memberChildName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdsCompanion.insert({
    required String id,
    required String name,
    required String ownerUserId,
    this.currencyCode = const Value.absent(),
    this.primaryLanguage = const Value.absent(),
    this.memberUserName = const Value.absent(),
    this.memberSpouseName = const Value.absent(),
    this.memberChildName = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       ownerUserId = Value(ownerUserId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DbHousehold> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? ownerUserId,
    Expression<String>? currencyCode,
    Expression<String>? primaryLanguage,
    Expression<String>? memberUserName,
    Expression<String>? memberSpouseName,
    Expression<String>? memberChildName,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (primaryLanguage != null) 'primary_language': primaryLanguage,
      if (memberUserName != null) 'member_user_name': memberUserName,
      if (memberSpouseName != null) 'member_spouse_name': memberSpouseName,
      if (memberChildName != null) 'member_child_name': memberChildName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? ownerUserId,
    Value<String>? currencyCode,
    Value<String>? primaryLanguage,
    Value<String>? memberUserName,
    Value<String?>? memberSpouseName,
    Value<String?>? memberChildName,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return HouseholdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      currencyCode: currencyCode ?? this.currencyCode,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      memberUserName: memberUserName ?? this.memberUserName,
      memberSpouseName: memberSpouseName ?? this.memberSpouseName,
      memberChildName: memberChildName ?? this.memberChildName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
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
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (primaryLanguage.present) {
      map['primary_language'] = Variable<String>(primaryLanguage.value);
    }
    if (memberUserName.present) {
      map['member_user_name'] = Variable<String>(memberUserName.value);
    }
    if (memberSpouseName.present) {
      map['member_spouse_name'] = Variable<String>(memberSpouseName.value);
    }
    if (memberChildName.present) {
      map['member_child_name'] = Variable<String>(memberChildName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('primaryLanguage: $primaryLanguage, ')
          ..write('memberUserName: $memberUserName, ')
          ..write('memberSpouseName: $memberSpouseName, ')
          ..write('memberChildName: $memberChildName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HouseholdMembersTable extends HouseholdMembers
    with TableInfo<$HouseholdMembersTable, DbHouseholdMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _lifecycleMeta = const VerificationMeta(
    'lifecycle',
  );
  @override
  late final GeneratedColumn<String> lifecycle = GeneratedColumn<String>(
    'lifecycle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    displayName,
    role,
    lifecycle,
    createdAt,
    updatedAt,
    isArchived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'household_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbHouseholdMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('lifecycle')) {
      context.handle(
        _lifecycleMeta,
        lifecycle.isAcceptableOrUnknown(data['lifecycle']!, _lifecycleMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbHouseholdMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbHouseholdMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      lifecycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lifecycle'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
    );
  }

  @override
  $HouseholdMembersTable createAlias(String alias) {
    return $HouseholdMembersTable(attachedDatabase, alias);
  }
}

class DbHouseholdMember extends DataClass
    implements Insertable<DbHouseholdMember> {
  final String id;
  final String householdId;
  final String displayName;

  /// role: 'primary_user' | 'spouse' | 'child'
  final String role;

  /// lifecycle: 'active' | 'archived'
  final String lifecycle;
  final String createdAt;
  final String updatedAt;
  final bool isArchived;
  const DbHouseholdMember({
    required this.id,
    required this.householdId,
    required this.displayName,
    required this.role,
    required this.lifecycle,
    required this.createdAt,
    required this.updatedAt,
    required this.isArchived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['display_name'] = Variable<String>(displayName);
    map['role'] = Variable<String>(role);
    map['lifecycle'] = Variable<String>(lifecycle);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  HouseholdMembersCompanion toCompanion(bool nullToAbsent) {
    return HouseholdMembersCompanion(
      id: Value(id),
      householdId: Value(householdId),
      displayName: Value(displayName),
      role: Value(role),
      lifecycle: Value(lifecycle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isArchived: Value(isArchived),
    );
  }

  factory DbHouseholdMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbHouseholdMember(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      role: serializer.fromJson<String>(json['role']),
      lifecycle: serializer.fromJson<String>(json['lifecycle']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'displayName': serializer.toJson<String>(displayName),
      'role': serializer.toJson<String>(role),
      'lifecycle': serializer.toJson<String>(lifecycle),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  DbHouseholdMember copyWith({
    String? id,
    String? householdId,
    String? displayName,
    String? role,
    String? lifecycle,
    String? createdAt,
    String? updatedAt,
    bool? isArchived,
  }) => DbHouseholdMember(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    displayName: displayName ?? this.displayName,
    role: role ?? this.role,
    lifecycle: lifecycle ?? this.lifecycle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isArchived: isArchived ?? this.isArchived,
  );
  DbHouseholdMember copyWithCompanion(HouseholdMembersCompanion data) {
    return DbHouseholdMember(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      role: data.role.present ? data.role.value : this.role,
      lifecycle: data.lifecycle.present ? data.lifecycle.value : this.lifecycle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbHouseholdMember(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdId,
    displayName,
    role,
    lifecycle,
    createdAt,
    updatedAt,
    isArchived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbHouseholdMember &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.displayName == this.displayName &&
          other.role == this.role &&
          other.lifecycle == this.lifecycle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isArchived == this.isArchived);
}

class HouseholdMembersCompanion extends UpdateCompanion<DbHouseholdMember> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> displayName;
  final Value<String> role;
  final Value<String> lifecycle;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<bool> isArchived;
  final Value<int> rowid;
  const HouseholdMembersCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.role = const Value.absent(),
    this.lifecycle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdMembersCompanion.insert({
    required String id,
    required String householdId,
    required String displayName,
    required String role,
    this.lifecycle = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       displayName = Value(displayName),
       role = Value(role),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DbHouseholdMember> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? displayName,
    Expression<String>? role,
    Expression<String>? lifecycle,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<bool>? isArchived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (displayName != null) 'display_name': displayName,
      if (role != null) 'role': role,
      if (lifecycle != null) 'lifecycle': lifecycle,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? displayName,
    Value<String>? role,
    Value<String>? lifecycle,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<bool>? isArchived,
    Value<int>? rowid,
  }) {
    return HouseholdMembersCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      lifecycle: lifecycle ?? this.lifecycle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (lifecycle.present) {
      map['lifecycle'] = Variable<String>(lifecycle.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdMembersCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('displayName: $displayName, ')
          ..write('role: $role, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinancialAccountsTable extends FinancialAccounts
    with TableInfo<$FinancialAccountsTable, DbFinancialAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinancialAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerTypeMeta = const VerificationMeta(
    'ownerType',
  );
  @override
  late final GeneratedColumn<String> ownerType = GeneratedColumn<String>(
    'owner_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fundPurposeMeta = const VerificationMeta(
    'fundPurpose',
  );
  @override
  late final GeneratedColumn<String> fundPurpose = GeneratedColumn<String>(
    'fund_purpose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('available'),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
  );
  static const VerificationMeta _isSpendableMeta = const VerificationMeta(
    'isSpendable',
  );
  @override
  late final GeneratedColumn<bool> isSpendable = GeneratedColumn<bool>(
    'is_spendable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_spendable" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isProtectedMeta = const VerificationMeta(
    'isProtected',
  );
  @override
  late final GeneratedColumn<bool> isProtected = GeneratedColumn<bool>(
    'is_protected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_protected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _includeInNetWorthMeta = const VerificationMeta(
    'includeInNetWorth',
  );
  @override
  late final GeneratedColumn<bool> includeInNetWorth = GeneratedColumn<bool>(
    'include_in_net_worth',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_net_worth" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _includeInZakatMeta = const VerificationMeta(
    'includeInZakat',
  );
  @override
  late final GeneratedColumn<bool> includeInZakat = GeneratedColumn<bool>(
    'include_in_zakat',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_zakat" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<String> archivedAt = GeneratedColumn<String>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idempotencyPayloadMeta =
      const VerificationMeta('idempotencyPayload');
  @override
  late final GeneratedColumn<String> idempotencyPayload =
      GeneratedColumn<String>(
        'idempotency_payload',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    name,
    type,
    ownerType,
    fundPurpose,
    currencyCode,
    isSpendable,
    isProtected,
    includeInNetWorth,
    includeInZakat,
    isArchived,
    archivedAt,
    notes,
    displayOrder,
    metadata,
    createdAt,
    updatedAt,
    createdBy,
    syncStatus,
    idempotencyKey,
    idempotencyPayload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'financial_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbFinancialAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('owner_type')) {
      context.handle(
        _ownerTypeMeta,
        ownerType.isAcceptableOrUnknown(data['owner_type']!, _ownerTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerTypeMeta);
    }
    if (data.containsKey('fund_purpose')) {
      context.handle(
        _fundPurposeMeta,
        fundPurpose.isAcceptableOrUnknown(
          data['fund_purpose']!,
          _fundPurposeMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('is_spendable')) {
      context.handle(
        _isSpendableMeta,
        isSpendable.isAcceptableOrUnknown(
          data['is_spendable']!,
          _isSpendableMeta,
        ),
      );
    }
    if (data.containsKey('is_protected')) {
      context.handle(
        _isProtectedMeta,
        isProtected.isAcceptableOrUnknown(
          data['is_protected']!,
          _isProtectedMeta,
        ),
      );
    }
    if (data.containsKey('include_in_net_worth')) {
      context.handle(
        _includeInNetWorthMeta,
        includeInNetWorth.isAcceptableOrUnknown(
          data['include_in_net_worth']!,
          _includeInNetWorthMeta,
        ),
      );
    }
    if (data.containsKey('include_in_zakat')) {
      context.handle(
        _includeInZakatMeta,
        includeInZakat.isAcceptableOrUnknown(
          data['include_in_zakat']!,
          _includeInZakatMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('idempotency_payload')) {
      context.handle(
        _idempotencyPayloadMeta,
        idempotencyPayload.isAcceptableOrUnknown(
          data['idempotency_payload']!,
          _idempotencyPayloadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbFinancialAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbFinancialAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      ownerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_type'],
      )!,
      fundPurpose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fund_purpose'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      isSpendable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_spendable'],
      )!,
      isProtected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_protected'],
      )!,
      includeInNetWorth: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_net_worth'],
      )!,
      includeInZakat: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_zakat'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archived_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
      idempotencyPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_payload'],
      ),
    );
  }

  @override
  $FinancialAccountsTable createAlias(String alias) {
    return $FinancialAccountsTable(attachedDatabase, alias);
  }
}

class DbFinancialAccount extends DataClass
    implements Insertable<DbFinancialAccount> {
  final String id;
  final String householdId;
  final String name;

  /// FinancialAccountType code (immutable after creation).
  final String type;

  /// AccountOwnerType code.
  final String ownerType;

  /// FundPurpose code.
  final String fundPurpose;

  /// ISO 4217 currency code.
  final String currencyCode;
  final bool isSpendable;
  final bool isProtected;
  final bool includeInNetWorth;
  final bool includeInZakat;
  final bool isArchived;
  final String? archivedAt;
  final String? notes;
  final int displayOrder;

  /// JSON string with type-specific extra fields (bank name, certificate data, gold weight, etc.).
  final String? metadata;
  final String createdAt;
  final String updatedAt;
  final String createdBy;

  /// SyncStatus code.
  final String syncStatus;

  /// Caller-supplied idempotency key scoped to (household_id, idempotency_key).
  /// Nullable: accounts created without a key have no idempotency protection.
  final String? idempotencyKey;

  /// Stable serialised fingerprint of the creation payload.
  /// Stored alongside [idempotencyKey] so that same-key-different-payload
  /// conflicts can be detected without re-hashing on every lookup.
  final String? idempotencyPayload;
  const DbFinancialAccount({
    required this.id,
    required this.householdId,
    required this.name,
    required this.type,
    required this.ownerType,
    required this.fundPurpose,
    required this.currencyCode,
    required this.isSpendable,
    required this.isProtected,
    required this.includeInNetWorth,
    required this.includeInZakat,
    required this.isArchived,
    this.archivedAt,
    this.notes,
    required this.displayOrder,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.syncStatus,
    this.idempotencyKey,
    this.idempotencyPayload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['owner_type'] = Variable<String>(ownerType);
    map['fund_purpose'] = Variable<String>(fundPurpose);
    map['currency_code'] = Variable<String>(currencyCode);
    map['is_spendable'] = Variable<bool>(isSpendable);
    map['is_protected'] = Variable<bool>(isProtected);
    map['include_in_net_worth'] = Variable<bool>(includeInNetWorth);
    map['include_in_zakat'] = Variable<bool>(includeInZakat);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<String>(archivedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['display_order'] = Variable<int>(displayOrder);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['created_by'] = Variable<String>(createdBy);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    if (!nullToAbsent || idempotencyPayload != null) {
      map['idempotency_payload'] = Variable<String>(idempotencyPayload);
    }
    return map;
  }

  FinancialAccountsCompanion toCompanion(bool nullToAbsent) {
    return FinancialAccountsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      type: Value(type),
      ownerType: Value(ownerType),
      fundPurpose: Value(fundPurpose),
      currencyCode: Value(currencyCode),
      isSpendable: Value(isSpendable),
      isProtected: Value(isProtected),
      includeInNetWorth: Value(includeInNetWorth),
      includeInZakat: Value(includeInZakat),
      isArchived: Value(isArchived),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      displayOrder: Value(displayOrder),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: Value(createdBy),
      syncStatus: Value(syncStatus),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      idempotencyPayload: idempotencyPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyPayload),
    );
  }

  factory DbFinancialAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbFinancialAccount(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      ownerType: serializer.fromJson<String>(json['ownerType']),
      fundPurpose: serializer.fromJson<String>(json['fundPurpose']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      isSpendable: serializer.fromJson<bool>(json['isSpendable']),
      isProtected: serializer.fromJson<bool>(json['isProtected']),
      includeInNetWorth: serializer.fromJson<bool>(json['includeInNetWorth']),
      includeInZakat: serializer.fromJson<bool>(json['includeInZakat']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      archivedAt: serializer.fromJson<String?>(json['archivedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      idempotencyPayload: serializer.fromJson<String?>(
        json['idempotencyPayload'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'ownerType': serializer.toJson<String>(ownerType),
      'fundPurpose': serializer.toJson<String>(fundPurpose),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'isSpendable': serializer.toJson<bool>(isSpendable),
      'isProtected': serializer.toJson<bool>(isProtected),
      'includeInNetWorth': serializer.toJson<bool>(includeInNetWorth),
      'includeInZakat': serializer.toJson<bool>(includeInZakat),
      'isArchived': serializer.toJson<bool>(isArchived),
      'archivedAt': serializer.toJson<String?>(archivedAt),
      'notes': serializer.toJson<String?>(notes),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'metadata': serializer.toJson<String?>(metadata),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'idempotencyPayload': serializer.toJson<String?>(idempotencyPayload),
    };
  }

  DbFinancialAccount copyWith({
    String? id,
    String? householdId,
    String? name,
    String? type,
    String? ownerType,
    String? fundPurpose,
    String? currencyCode,
    bool? isSpendable,
    bool? isProtected,
    bool? includeInNetWorth,
    bool? includeInZakat,
    bool? isArchived,
    Value<String?> archivedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? displayOrder,
    Value<String?> metadata = const Value.absent(),
    String? createdAt,
    String? updatedAt,
    String? createdBy,
    String? syncStatus,
    Value<String?> idempotencyKey = const Value.absent(),
    Value<String?> idempotencyPayload = const Value.absent(),
  }) => DbFinancialAccount(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    name: name ?? this.name,
    type: type ?? this.type,
    ownerType: ownerType ?? this.ownerType,
    fundPurpose: fundPurpose ?? this.fundPurpose,
    currencyCode: currencyCode ?? this.currencyCode,
    isSpendable: isSpendable ?? this.isSpendable,
    isProtected: isProtected ?? this.isProtected,
    includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
    includeInZakat: includeInZakat ?? this.includeInZakat,
    isArchived: isArchived ?? this.isArchived,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    notes: notes.present ? notes.value : this.notes,
    displayOrder: displayOrder ?? this.displayOrder,
    metadata: metadata.present ? metadata.value : this.metadata,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    syncStatus: syncStatus ?? this.syncStatus,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
    idempotencyPayload: idempotencyPayload.present
        ? idempotencyPayload.value
        : this.idempotencyPayload,
  );
  DbFinancialAccount copyWithCompanion(FinancialAccountsCompanion data) {
    return DbFinancialAccount(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      ownerType: data.ownerType.present ? data.ownerType.value : this.ownerType,
      fundPurpose: data.fundPurpose.present
          ? data.fundPurpose.value
          : this.fundPurpose,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      isSpendable: data.isSpendable.present
          ? data.isSpendable.value
          : this.isSpendable,
      isProtected: data.isProtected.present
          ? data.isProtected.value
          : this.isProtected,
      includeInNetWorth: data.includeInNetWorth.present
          ? data.includeInNetWorth.value
          : this.includeInNetWorth,
      includeInZakat: data.includeInZakat.present
          ? data.includeInZakat.value
          : this.includeInZakat,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      idempotencyPayload: data.idempotencyPayload.present
          ? data.idempotencyPayload.value
          : this.idempotencyPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbFinancialAccount(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('ownerType: $ownerType, ')
          ..write('fundPurpose: $fundPurpose, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isSpendable: $isSpendable, ')
          ..write('isProtected: $isProtected, ')
          ..write('includeInNetWorth: $includeInNetWorth, ')
          ..write('includeInZakat: $includeInZakat, ')
          ..write('isArchived: $isArchived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('notes: $notes, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('idempotencyPayload: $idempotencyPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    householdId,
    name,
    type,
    ownerType,
    fundPurpose,
    currencyCode,
    isSpendable,
    isProtected,
    includeInNetWorth,
    includeInZakat,
    isArchived,
    archivedAt,
    notes,
    displayOrder,
    metadata,
    createdAt,
    updatedAt,
    createdBy,
    syncStatus,
    idempotencyKey,
    idempotencyPayload,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbFinancialAccount &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.type == this.type &&
          other.ownerType == this.ownerType &&
          other.fundPurpose == this.fundPurpose &&
          other.currencyCode == this.currencyCode &&
          other.isSpendable == this.isSpendable &&
          other.isProtected == this.isProtected &&
          other.includeInNetWorth == this.includeInNetWorth &&
          other.includeInZakat == this.includeInZakat &&
          other.isArchived == this.isArchived &&
          other.archivedAt == this.archivedAt &&
          other.notes == this.notes &&
          other.displayOrder == this.displayOrder &&
          other.metadata == this.metadata &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.syncStatus == this.syncStatus &&
          other.idempotencyKey == this.idempotencyKey &&
          other.idempotencyPayload == this.idempotencyPayload);
}

class FinancialAccountsCompanion extends UpdateCompanion<DbFinancialAccount> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String> type;
  final Value<String> ownerType;
  final Value<String> fundPurpose;
  final Value<String> currencyCode;
  final Value<bool> isSpendable;
  final Value<bool> isProtected;
  final Value<bool> includeInNetWorth;
  final Value<bool> includeInZakat;
  final Value<bool> isArchived;
  final Value<String?> archivedAt;
  final Value<String?> notes;
  final Value<int> displayOrder;
  final Value<String?> metadata;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> createdBy;
  final Value<String> syncStatus;
  final Value<String?> idempotencyKey;
  final Value<String?> idempotencyPayload;
  final Value<int> rowid;
  const FinancialAccountsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.ownerType = const Value.absent(),
    this.fundPurpose = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.isSpendable = const Value.absent(),
    this.isProtected = const Value.absent(),
    this.includeInNetWorth = const Value.absent(),
    this.includeInZakat = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.metadata = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.idempotencyPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinancialAccountsCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    required String type,
    required String ownerType,
    this.fundPurpose = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.isSpendable = const Value.absent(),
    this.isProtected = const Value.absent(),
    this.includeInNetWorth = const Value.absent(),
    this.includeInZakat = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.metadata = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    required String createdBy,
    this.syncStatus = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.idempotencyPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       name = Value(name),
       type = Value(type),
       ownerType = Value(ownerType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy);
  static Insertable<DbFinancialAccount> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? ownerType,
    Expression<String>? fundPurpose,
    Expression<String>? currencyCode,
    Expression<bool>? isSpendable,
    Expression<bool>? isProtected,
    Expression<bool>? includeInNetWorth,
    Expression<bool>? includeInZakat,
    Expression<bool>? isArchived,
    Expression<String>? archivedAt,
    Expression<String>? notes,
    Expression<int>? displayOrder,
    Expression<String>? metadata,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? createdBy,
    Expression<String>? syncStatus,
    Expression<String>? idempotencyKey,
    Expression<String>? idempotencyPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (ownerType != null) 'owner_type': ownerType,
      if (fundPurpose != null) 'fund_purpose': fundPurpose,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (isSpendable != null) 'is_spendable': isSpendable,
      if (isProtected != null) 'is_protected': isProtected,
      if (includeInNetWorth != null) 'include_in_net_worth': includeInNetWorth,
      if (includeInZakat != null) 'include_in_zakat': includeInZakat,
      if (isArchived != null) 'is_archived': isArchived,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (notes != null) 'notes': notes,
      if (displayOrder != null) 'display_order': displayOrder,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (idempotencyPayload != null) 'idempotency_payload': idempotencyPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinancialAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? name,
    Value<String>? type,
    Value<String>? ownerType,
    Value<String>? fundPurpose,
    Value<String>? currencyCode,
    Value<bool>? isSpendable,
    Value<bool>? isProtected,
    Value<bool>? includeInNetWorth,
    Value<bool>? includeInZakat,
    Value<bool>? isArchived,
    Value<String?>? archivedAt,
    Value<String?>? notes,
    Value<int>? displayOrder,
    Value<String?>? metadata,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? createdBy,
    Value<String>? syncStatus,
    Value<String?>? idempotencyKey,
    Value<String?>? idempotencyPayload,
    Value<int>? rowid,
  }) {
    return FinancialAccountsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerType: ownerType ?? this.ownerType,
      fundPurpose: fundPurpose ?? this.fundPurpose,
      currencyCode: currencyCode ?? this.currencyCode,
      isSpendable: isSpendable ?? this.isSpendable,
      isProtected: isProtected ?? this.isProtected,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      includeInZakat: includeInZakat ?? this.includeInZakat,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      notes: notes ?? this.notes,
      displayOrder: displayOrder ?? this.displayOrder,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      syncStatus: syncStatus ?? this.syncStatus,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      idempotencyPayload: idempotencyPayload ?? this.idempotencyPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (ownerType.present) {
      map['owner_type'] = Variable<String>(ownerType.value);
    }
    if (fundPurpose.present) {
      map['fund_purpose'] = Variable<String>(fundPurpose.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (isSpendable.present) {
      map['is_spendable'] = Variable<bool>(isSpendable.value);
    }
    if (isProtected.present) {
      map['is_protected'] = Variable<bool>(isProtected.value);
    }
    if (includeInNetWorth.present) {
      map['include_in_net_worth'] = Variable<bool>(includeInNetWorth.value);
    }
    if (includeInZakat.present) {
      map['include_in_zakat'] = Variable<bool>(includeInZakat.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<String>(archivedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (idempotencyPayload.present) {
      map['idempotency_payload'] = Variable<String>(idempotencyPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinancialAccountsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('ownerType: $ownerType, ')
          ..write('fundPurpose: $fundPurpose, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isSpendable: $isSpendable, ')
          ..write('isProtected: $isProtected, ')
          ..write('includeInNetWorth: $includeInNetWorth, ')
          ..write('includeInZakat: $includeInZakat, ')
          ..write('isArchived: $isArchived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('notes: $notes, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('metadata: $metadata, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('idempotencyPayload: $idempotencyPayload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, DbLedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES financial_accounts (id)',
    ),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
  );
  static const VerificationMeta _entryTypeMeta = const VerificationMeta(
    'entryType',
  );
  @override
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
    'entry_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveDateMeta = const VerificationMeta(
    'effectiveDate',
  );
  @override
  late final GeneratedColumn<String> effectiveDate = GeneratedColumn<String>(
    'effective_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<String> recordedAt = GeneratedColumn<String>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReversalMeta = const VerificationMeta(
    'isReversal',
  );
  @override
  late final GeneratedColumn<bool> isReversal = GeneratedColumn<bool>(
    'is_reversal',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_reversal" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reversalOfEntryIdMeta = const VerificationMeta(
    'reversalOfEntryId',
  );
  @override
  late final GeneratedColumn<String> reversalOfEntryId =
      GeneratedColumn<String>(
        'reversal_of_entry_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationId,
    householdId,
    accountId,
    direction,
    amountMinorUnits,
    currencyCode,
    entryType,
    effectiveDate,
    recordedAt,
    notes,
    createdBy,
    isReversal,
    reversalOfEntryId,
    syncStatus,
    metadata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbLedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorUnitsMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('entry_type')) {
      context.handle(
        _entryTypeMeta,
        entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entryTypeMeta);
    }
    if (data.containsKey('effective_date')) {
      context.handle(
        _effectiveDateMeta,
        effectiveDate.isAcceptableOrUnknown(
          data['effective_date']!,
          _effectiveDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveDateMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('is_reversal')) {
      context.handle(
        _isReversalMeta,
        isReversal.isAcceptableOrUnknown(data['is_reversal']!, _isReversalMeta),
      );
    }
    if (data.containsKey('reversal_of_entry_id')) {
      context.handle(
        _reversalOfEntryIdMeta,
        reversalOfEntryId.isAcceptableOrUnknown(
          data['reversal_of_entry_id']!,
          _reversalOfEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbLedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbLedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      entryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_type'],
      )!,
      effectiveDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_date'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      isReversal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_reversal'],
      )!,
      reversalOfEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reversal_of_entry_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }
}

class DbLedgerEntry extends DataClass implements Insertable<DbLedgerEntry> {
  final String id;

  /// Groups all entries that belong to the same financial operation.
  final String operationId;
  final String householdId;
  final String accountId;

  /// LedgerDirection: 'credit' or 'debit'.
  final String direction;

  /// Always positive. CHECK(amount_minor_units > 0) enforced in migration.
  final int amountMinorUnits;

  /// ISO 4217 currency code.
  final String currencyCode;

  /// LedgerEntryType code.
  final String entryType;

  /// User-chosen date in "YYYY-MM-DD" format. May be backdated.
  final String effectiveDate;

  /// System UTC ISO 8601 timestamp.
  final String recordedAt;
  final String? notes;
  final String createdBy;
  final bool isReversal;

  /// When [isReversal] is true, points to the original entry's [id].
  final String? reversalOfEntryId;

  /// SyncStatus code.
  final String syncStatus;

  /// JSON string for operation-specific supplementary data.
  final String? metadata;
  const DbLedgerEntry({
    required this.id,
    required this.operationId,
    required this.householdId,
    required this.accountId,
    required this.direction,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.entryType,
    required this.effectiveDate,
    required this.recordedAt,
    this.notes,
    required this.createdBy,
    required this.isReversal,
    this.reversalOfEntryId,
    required this.syncStatus,
    this.metadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation_id'] = Variable<String>(operationId);
    map['household_id'] = Variable<String>(householdId);
    map['account_id'] = Variable<String>(accountId);
    map['direction'] = Variable<String>(direction);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['currency_code'] = Variable<String>(currencyCode);
    map['entry_type'] = Variable<String>(entryType);
    map['effective_date'] = Variable<String>(effectiveDate);
    map['recorded_at'] = Variable<String>(recordedAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['is_reversal'] = Variable<bool>(isReversal);
    if (!nullToAbsent || reversalOfEntryId != null) {
      map['reversal_of_entry_id'] = Variable<String>(reversalOfEntryId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      operationId: Value(operationId),
      householdId: Value(householdId),
      accountId: Value(accountId),
      direction: Value(direction),
      amountMinorUnits: Value(amountMinorUnits),
      currencyCode: Value(currencyCode),
      entryType: Value(entryType),
      effectiveDate: Value(effectiveDate),
      recordedAt: Value(recordedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdBy: Value(createdBy),
      isReversal: Value(isReversal),
      reversalOfEntryId: reversalOfEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(reversalOfEntryId),
      syncStatus: Value(syncStatus),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory DbLedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbLedgerEntry(
      id: serializer.fromJson<String>(json['id']),
      operationId: serializer.fromJson<String>(json['operationId']),
      householdId: serializer.fromJson<String>(json['householdId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      direction: serializer.fromJson<String>(json['direction']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      entryType: serializer.fromJson<String>(json['entryType']),
      effectiveDate: serializer.fromJson<String>(json['effectiveDate']),
      recordedAt: serializer.fromJson<String>(json['recordedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      isReversal: serializer.fromJson<bool>(json['isReversal']),
      reversalOfEntryId: serializer.fromJson<String?>(
        json['reversalOfEntryId'],
      ),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operationId': serializer.toJson<String>(operationId),
      'householdId': serializer.toJson<String>(householdId),
      'accountId': serializer.toJson<String>(accountId),
      'direction': serializer.toJson<String>(direction),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'entryType': serializer.toJson<String>(entryType),
      'effectiveDate': serializer.toJson<String>(effectiveDate),
      'recordedAt': serializer.toJson<String>(recordedAt),
      'notes': serializer.toJson<String?>(notes),
      'createdBy': serializer.toJson<String>(createdBy),
      'isReversal': serializer.toJson<bool>(isReversal),
      'reversalOfEntryId': serializer.toJson<String?>(reversalOfEntryId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  DbLedgerEntry copyWith({
    String? id,
    String? operationId,
    String? householdId,
    String? accountId,
    String? direction,
    int? amountMinorUnits,
    String? currencyCode,
    String? entryType,
    String? effectiveDate,
    String? recordedAt,
    Value<String?> notes = const Value.absent(),
    String? createdBy,
    bool? isReversal,
    Value<String?> reversalOfEntryId = const Value.absent(),
    String? syncStatus,
    Value<String?> metadata = const Value.absent(),
  }) => DbLedgerEntry(
    id: id ?? this.id,
    operationId: operationId ?? this.operationId,
    householdId: householdId ?? this.householdId,
    accountId: accountId ?? this.accountId,
    direction: direction ?? this.direction,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    currencyCode: currencyCode ?? this.currencyCode,
    entryType: entryType ?? this.entryType,
    effectiveDate: effectiveDate ?? this.effectiveDate,
    recordedAt: recordedAt ?? this.recordedAt,
    notes: notes.present ? notes.value : this.notes,
    createdBy: createdBy ?? this.createdBy,
    isReversal: isReversal ?? this.isReversal,
    reversalOfEntryId: reversalOfEntryId.present
        ? reversalOfEntryId.value
        : this.reversalOfEntryId,
    syncStatus: syncStatus ?? this.syncStatus,
    metadata: metadata.present ? metadata.value : this.metadata,
  );
  DbLedgerEntry copyWithCompanion(LedgerEntriesCompanion data) {
    return DbLedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      direction: data.direction.present ? data.direction.value : this.direction,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      effectiveDate: data.effectiveDate.present
          ? data.effectiveDate.value
          : this.effectiveDate,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      isReversal: data.isReversal.present
          ? data.isReversal.value
          : this.isReversal,
      reversalOfEntryId: data.reversalOfEntryId.present
          ? data.reversalOfEntryId.value
          : this.reversalOfEntryId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbLedgerEntry(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('householdId: $householdId, ')
          ..write('accountId: $accountId, ')
          ..write('direction: $direction, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('entryType: $entryType, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('notes: $notes, ')
          ..write('createdBy: $createdBy, ')
          ..write('isReversal: $isReversal, ')
          ..write('reversalOfEntryId: $reversalOfEntryId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationId,
    householdId,
    accountId,
    direction,
    amountMinorUnits,
    currencyCode,
    entryType,
    effectiveDate,
    recordedAt,
    notes,
    createdBy,
    isReversal,
    reversalOfEntryId,
    syncStatus,
    metadata,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbLedgerEntry &&
          other.id == this.id &&
          other.operationId == this.operationId &&
          other.householdId == this.householdId &&
          other.accountId == this.accountId &&
          other.direction == this.direction &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.currencyCode == this.currencyCode &&
          other.entryType == this.entryType &&
          other.effectiveDate == this.effectiveDate &&
          other.recordedAt == this.recordedAt &&
          other.notes == this.notes &&
          other.createdBy == this.createdBy &&
          other.isReversal == this.isReversal &&
          other.reversalOfEntryId == this.reversalOfEntryId &&
          other.syncStatus == this.syncStatus &&
          other.metadata == this.metadata);
}

class LedgerEntriesCompanion extends UpdateCompanion<DbLedgerEntry> {
  final Value<String> id;
  final Value<String> operationId;
  final Value<String> householdId;
  final Value<String> accountId;
  final Value<String> direction;
  final Value<int> amountMinorUnits;
  final Value<String> currencyCode;
  final Value<String> entryType;
  final Value<String> effectiveDate;
  final Value<String> recordedAt;
  final Value<String?> notes;
  final Value<String> createdBy;
  final Value<bool> isReversal;
  final Value<String?> reversalOfEntryId;
  final Value<String> syncStatus;
  final Value<String?> metadata;
  final Value<int> rowid;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.operationId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.direction = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.entryType = const Value.absent(),
    this.effectiveDate = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.isReversal = const Value.absent(),
    this.reversalOfEntryId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    required String id,
    required String operationId,
    required String householdId,
    required String accountId,
    required String direction,
    required int amountMinorUnits,
    this.currencyCode = const Value.absent(),
    required String entryType,
    required String effectiveDate,
    required String recordedAt,
    this.notes = const Value.absent(),
    required String createdBy,
    this.isReversal = const Value.absent(),
    this.reversalOfEntryId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       operationId = Value(operationId),
       householdId = Value(householdId),
       accountId = Value(accountId),
       direction = Value(direction),
       amountMinorUnits = Value(amountMinorUnits),
       entryType = Value(entryType),
       effectiveDate = Value(effectiveDate),
       recordedAt = Value(recordedAt),
       createdBy = Value(createdBy);
  static Insertable<DbLedgerEntry> custom({
    Expression<String>? id,
    Expression<String>? operationId,
    Expression<String>? householdId,
    Expression<String>? accountId,
    Expression<String>? direction,
    Expression<int>? amountMinorUnits,
    Expression<String>? currencyCode,
    Expression<String>? entryType,
    Expression<String>? effectiveDate,
    Expression<String>? recordedAt,
    Expression<String>? notes,
    Expression<String>? createdBy,
    Expression<bool>? isReversal,
    Expression<String>? reversalOfEntryId,
    Expression<String>? syncStatus,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationId != null) 'operation_id': operationId,
      if (householdId != null) 'household_id': householdId,
      if (accountId != null) 'account_id': accountId,
      if (direction != null) 'direction': direction,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (entryType != null) 'entry_type': entryType,
      if (effectiveDate != null) 'effective_date': effectiveDate,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      if (isReversal != null) 'is_reversal': isReversal,
      if (reversalOfEntryId != null) 'reversal_of_entry_id': reversalOfEntryId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? operationId,
    Value<String>? householdId,
    Value<String>? accountId,
    Value<String>? direction,
    Value<int>? amountMinorUnits,
    Value<String>? currencyCode,
    Value<String>? entryType,
    Value<String>? effectiveDate,
    Value<String>? recordedAt,
    Value<String?>? notes,
    Value<String>? createdBy,
    Value<bool>? isReversal,
    Value<String?>? reversalOfEntryId,
    Value<String>? syncStatus,
    Value<String?>? metadata,
    Value<int>? rowid,
  }) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      householdId: householdId ?? this.householdId,
      accountId: accountId ?? this.accountId,
      direction: direction ?? this.direction,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      entryType: entryType ?? this.entryType,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      isReversal: isReversal ?? this.isReversal,
      reversalOfEntryId: reversalOfEntryId ?? this.reversalOfEntryId,
      syncStatus: syncStatus ?? this.syncStatus,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (effectiveDate.present) {
      map['effective_date'] = Variable<String>(effectiveDate.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<String>(recordedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (isReversal.present) {
      map['is_reversal'] = Variable<bool>(isReversal.value);
    }
    if (reversalOfEntryId.present) {
      map['reversal_of_entry_id'] = Variable<String>(reversalOfEntryId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('householdId: $householdId, ')
          ..write('accountId: $accountId, ')
          ..write('direction: $direction, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('entryType: $entryType, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('notes: $notes, ')
          ..write('createdBy: $createdBy, ')
          ..write('isReversal: $isReversal, ')
          ..write('reversalOfEntryId: $reversalOfEntryId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperationsTable extends Operations
    with TableInfo<$OperationsTable, DbOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveDateMeta = const VerificationMeta(
    'effectiveDate',
  );
  @override
  late final GeneratedColumn<String> effectiveDate = GeneratedColumn<String>(
    'effective_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<String> recordedAt = GeneratedColumn<String>(
    'recorded_at',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryCodeMeta = const VerificationMeta(
    'categoryCode',
  );
  @override
  late final GeneratedColumn<String> categoryCode = GeneratedColumn<String>(
    'category_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spenderRoleMeta = const VerificationMeta(
    'spenderRole',
  );
  @override
  late final GeneratedColumn<String> spenderRole = GeneratedColumn<String>(
    'spender_role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beneficiaryRoleMeta = const VerificationMeta(
    'beneficiaryRole',
  );
  @override
  late final GeneratedColumn<String> beneficiaryRole = GeneratedColumn<String>(
    'beneficiary_role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceAccountIdMeta = const VerificationMeta(
    'sourceAccountId',
  );
  @override
  late final GeneratedColumn<String> sourceAccountId = GeneratedColumn<String>(
    'source_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES financial_accounts (id)',
    ),
  );
  static const VerificationMeta _destinationAccountIdMeta =
      const VerificationMeta('destinationAccountId');
  @override
  late final GeneratedColumn<String> destinationAccountId =
      GeneratedColumn<String>(
        'destination_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES financial_accounts (id)',
        ),
      );
  static const VerificationMeta _totalAmountMinorUnitsMeta =
      const VerificationMeta('totalAmountMinorUnits');
  @override
  late final GeneratedColumn<int> totalAmountMinorUnits = GeneratedColumn<int>(
    'total_amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recurringRuleIdMeta = const VerificationMeta(
    'recurringRuleId',
  );
  @override
  late final GeneratedColumn<String> recurringRuleId = GeneratedColumn<String>(
    'recurring_rule_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptPathMeta = const VerificationMeta(
    'receiptPath',
  );
  @override
  late final GeneratedColumn<String> receiptPath = GeneratedColumn<String>(
    'receipt_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isReversedMeta = const VerificationMeta(
    'isReversed',
  );
  @override
  late final GeneratedColumn<bool> isReversed = GeneratedColumn<bool>(
    'is_reversed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_reversed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reversedByMeta = const VerificationMeta(
    'reversedBy',
  );
  @override
  late final GeneratedColumn<String> reversedBy = GeneratedColumn<String>(
    'reversed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    idempotencyKey,
    householdId,
    type,
    effectiveDate,
    recordedAt,
    description,
    categoryCode,
    scope,
    spenderRole,
    beneficiaryRole,
    sourceAccountId,
    destinationAccountId,
    totalAmountMinorUnits,
    currencyCode,
    isRecurring,
    recurringRuleId,
    tags,
    receiptPath,
    isReversed,
    reversedBy,
    createdBy,
    createdAt,
    updatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('effective_date')) {
      context.handle(
        _effectiveDateMeta,
        effectiveDate.isAcceptableOrUnknown(
          data['effective_date']!,
          _effectiveDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveDateMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category_code')) {
      context.handle(
        _categoryCodeMeta,
        categoryCode.isAcceptableOrUnknown(
          data['category_code']!,
          _categoryCodeMeta,
        ),
      );
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    }
    if (data.containsKey('spender_role')) {
      context.handle(
        _spenderRoleMeta,
        spenderRole.isAcceptableOrUnknown(
          data['spender_role']!,
          _spenderRoleMeta,
        ),
      );
    }
    if (data.containsKey('beneficiary_role')) {
      context.handle(
        _beneficiaryRoleMeta,
        beneficiaryRole.isAcceptableOrUnknown(
          data['beneficiary_role']!,
          _beneficiaryRoleMeta,
        ),
      );
    }
    if (data.containsKey('source_account_id')) {
      context.handle(
        _sourceAccountIdMeta,
        sourceAccountId.isAcceptableOrUnknown(
          data['source_account_id']!,
          _sourceAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('destination_account_id')) {
      context.handle(
        _destinationAccountIdMeta,
        destinationAccountId.isAcceptableOrUnknown(
          data['destination_account_id']!,
          _destinationAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('total_amount_minor_units')) {
      context.handle(
        _totalAmountMinorUnitsMeta,
        totalAmountMinorUnits.isAcceptableOrUnknown(
          data['total_amount_minor_units']!,
          _totalAmountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMinorUnitsMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    }
    if (data.containsKey('recurring_rule_id')) {
      context.handle(
        _recurringRuleIdMeta,
        recurringRuleId.isAcceptableOrUnknown(
          data['recurring_rule_id']!,
          _recurringRuleIdMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('receipt_path')) {
      context.handle(
        _receiptPathMeta,
        receiptPath.isAcceptableOrUnknown(
          data['receipt_path']!,
          _receiptPathMeta,
        ),
      );
    }
    if (data.containsKey('is_reversed')) {
      context.handle(
        _isReversedMeta,
        isReversed.isAcceptableOrUnknown(data['is_reversed']!, _isReversedMeta),
      );
    }
    if (data.containsKey('reversed_by')) {
      context.handle(
        _reversedByMeta,
        reversedBy.isAcceptableOrUnknown(data['reversed_by']!, _reversedByMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      effectiveDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_date'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_at'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      categoryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_code'],
      ),
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      ),
      spenderRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spender_role'],
      ),
      beneficiaryRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beneficiary_role'],
      ),
      sourceAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_account_id'],
      ),
      destinationAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_account_id'],
      ),
      totalAmountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_amount_minor_units'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      recurringRuleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurring_rule_id'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      receiptPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_path'],
      ),
      isReversed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_reversed'],
      )!,
      reversedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reversed_by'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $OperationsTable createAlias(String alias) {
    return $OperationsTable(attachedDatabase, alias);
  }
}

class DbOperation extends DataClass implements Insertable<DbOperation> {
  /// Stable client-generated UUID. Primary key.
  final String id;

  /// Explicit idempotency key scoped by [householdId].
  ///
  /// Defaults to [id] at the application layer when not supplied by the caller.
  /// A UNIQUE(household_id, idempotency_key) constraint is enforced via a
  /// custom index in [AppDatabase.onCreate] / schema-v2 migration.
  ///
  /// Distinguishes:
  /// - Same key + same operation_id → alreadyExists (safe retry)
  /// - Same key + different operation_id → conflict (caller error)
  final String? idempotencyKey;
  final String householdId;

  /// OperationType code.
  final String type;

  /// User-chosen effective date "YYYY-MM-DD".
  final String effectiveDate;

  /// System UTC ISO 8601 timestamp.
  final String recordedAt;
  final String? description;

  /// Income/expense category code.
  final String? categoryCode;

  /// ExpenseScope code.
  final String? scope;

  /// HouseholdMemberRole code.
  final String? spenderRole;

  /// HouseholdMemberRole code.
  final String? beneficiaryRole;
  final String? sourceAccountId;
  final String? destinationAccountId;

  /// Face amount in minor units (always positive).
  final int totalAmountMinorUnits;

  /// ISO 4217 currency code.
  final String currencyCode;
  final bool isRecurring;
  final String? recurringRuleId;

  /// JSON array of tag strings.
  final String? tags;

  /// Local path to an encrypted receipt image (display-layer only).
  final String? receiptPath;

  /// Set to true when a reversal operation has been applied (INV-002).
  /// This is the ONLY field that may be updated after creation.
  final bool isReversed;

  /// The [id] of the reversal operation that cancelled this one.
  final String? reversedBy;
  final String createdBy;
  final String createdAt;

  /// Updated only when [isReversed] is set.
  final String updatedAt;

  /// SyncStatus code.
  final String syncStatus;
  const DbOperation({
    required this.id,
    this.idempotencyKey,
    required this.householdId,
    required this.type,
    required this.effectiveDate,
    required this.recordedAt,
    this.description,
    this.categoryCode,
    this.scope,
    this.spenderRole,
    this.beneficiaryRole,
    this.sourceAccountId,
    this.destinationAccountId,
    required this.totalAmountMinorUnits,
    required this.currencyCode,
    required this.isRecurring,
    this.recurringRuleId,
    this.tags,
    this.receiptPath,
    required this.isReversed,
    this.reversedBy,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    map['household_id'] = Variable<String>(householdId);
    map['type'] = Variable<String>(type);
    map['effective_date'] = Variable<String>(effectiveDate);
    map['recorded_at'] = Variable<String>(recordedAt);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || categoryCode != null) {
      map['category_code'] = Variable<String>(categoryCode);
    }
    if (!nullToAbsent || scope != null) {
      map['scope'] = Variable<String>(scope);
    }
    if (!nullToAbsent || spenderRole != null) {
      map['spender_role'] = Variable<String>(spenderRole);
    }
    if (!nullToAbsent || beneficiaryRole != null) {
      map['beneficiary_role'] = Variable<String>(beneficiaryRole);
    }
    if (!nullToAbsent || sourceAccountId != null) {
      map['source_account_id'] = Variable<String>(sourceAccountId);
    }
    if (!nullToAbsent || destinationAccountId != null) {
      map['destination_account_id'] = Variable<String>(destinationAccountId);
    }
    map['total_amount_minor_units'] = Variable<int>(totalAmountMinorUnits);
    map['currency_code'] = Variable<String>(currencyCode);
    map['is_recurring'] = Variable<bool>(isRecurring);
    if (!nullToAbsent || recurringRuleId != null) {
      map['recurring_rule_id'] = Variable<String>(recurringRuleId);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || receiptPath != null) {
      map['receipt_path'] = Variable<String>(receiptPath);
    }
    map['is_reversed'] = Variable<bool>(isReversed);
    if (!nullToAbsent || reversedBy != null) {
      map['reversed_by'] = Variable<String>(reversedBy);
    }
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  OperationsCompanion toCompanion(bool nullToAbsent) {
    return OperationsCompanion(
      id: Value(id),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      householdId: Value(householdId),
      type: Value(type),
      effectiveDate: Value(effectiveDate),
      recordedAt: Value(recordedAt),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      categoryCode: categoryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryCode),
      scope: scope == null && nullToAbsent
          ? const Value.absent()
          : Value(scope),
      spenderRole: spenderRole == null && nullToAbsent
          ? const Value.absent()
          : Value(spenderRole),
      beneficiaryRole: beneficiaryRole == null && nullToAbsent
          ? const Value.absent()
          : Value(beneficiaryRole),
      sourceAccountId: sourceAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceAccountId),
      destinationAccountId: destinationAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationAccountId),
      totalAmountMinorUnits: Value(totalAmountMinorUnits),
      currencyCode: Value(currencyCode),
      isRecurring: Value(isRecurring),
      recurringRuleId: recurringRuleId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringRuleId),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      receiptPath: receiptPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptPath),
      isReversed: Value(isReversed),
      reversedBy: reversedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(reversedBy),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory DbOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbOperation(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      householdId: serializer.fromJson<String>(json['householdId']),
      type: serializer.fromJson<String>(json['type']),
      effectiveDate: serializer.fromJson<String>(json['effectiveDate']),
      recordedAt: serializer.fromJson<String>(json['recordedAt']),
      description: serializer.fromJson<String?>(json['description']),
      categoryCode: serializer.fromJson<String?>(json['categoryCode']),
      scope: serializer.fromJson<String?>(json['scope']),
      spenderRole: serializer.fromJson<String?>(json['spenderRole']),
      beneficiaryRole: serializer.fromJson<String?>(json['beneficiaryRole']),
      sourceAccountId: serializer.fromJson<String?>(json['sourceAccountId']),
      destinationAccountId: serializer.fromJson<String?>(
        json['destinationAccountId'],
      ),
      totalAmountMinorUnits: serializer.fromJson<int>(
        json['totalAmountMinorUnits'],
      ),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      recurringRuleId: serializer.fromJson<String?>(json['recurringRuleId']),
      tags: serializer.fromJson<String?>(json['tags']),
      receiptPath: serializer.fromJson<String?>(json['receiptPath']),
      isReversed: serializer.fromJson<bool>(json['isReversed']),
      reversedBy: serializer.fromJson<String?>(json['reversedBy']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'householdId': serializer.toJson<String>(householdId),
      'type': serializer.toJson<String>(type),
      'effectiveDate': serializer.toJson<String>(effectiveDate),
      'recordedAt': serializer.toJson<String>(recordedAt),
      'description': serializer.toJson<String?>(description),
      'categoryCode': serializer.toJson<String?>(categoryCode),
      'scope': serializer.toJson<String?>(scope),
      'spenderRole': serializer.toJson<String?>(spenderRole),
      'beneficiaryRole': serializer.toJson<String?>(beneficiaryRole),
      'sourceAccountId': serializer.toJson<String?>(sourceAccountId),
      'destinationAccountId': serializer.toJson<String?>(destinationAccountId),
      'totalAmountMinorUnits': serializer.toJson<int>(totalAmountMinorUnits),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'recurringRuleId': serializer.toJson<String?>(recurringRuleId),
      'tags': serializer.toJson<String?>(tags),
      'receiptPath': serializer.toJson<String?>(receiptPath),
      'isReversed': serializer.toJson<bool>(isReversed),
      'reversedBy': serializer.toJson<String?>(reversedBy),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  DbOperation copyWith({
    String? id,
    Value<String?> idempotencyKey = const Value.absent(),
    String? householdId,
    String? type,
    String? effectiveDate,
    String? recordedAt,
    Value<String?> description = const Value.absent(),
    Value<String?> categoryCode = const Value.absent(),
    Value<String?> scope = const Value.absent(),
    Value<String?> spenderRole = const Value.absent(),
    Value<String?> beneficiaryRole = const Value.absent(),
    Value<String?> sourceAccountId = const Value.absent(),
    Value<String?> destinationAccountId = const Value.absent(),
    int? totalAmountMinorUnits,
    String? currencyCode,
    bool? isRecurring,
    Value<String?> recurringRuleId = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<String?> receiptPath = const Value.absent(),
    bool? isReversed,
    Value<String?> reversedBy = const Value.absent(),
    String? createdBy,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) => DbOperation(
    id: id ?? this.id,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
    householdId: householdId ?? this.householdId,
    type: type ?? this.type,
    effectiveDate: effectiveDate ?? this.effectiveDate,
    recordedAt: recordedAt ?? this.recordedAt,
    description: description.present ? description.value : this.description,
    categoryCode: categoryCode.present ? categoryCode.value : this.categoryCode,
    scope: scope.present ? scope.value : this.scope,
    spenderRole: spenderRole.present ? spenderRole.value : this.spenderRole,
    beneficiaryRole: beneficiaryRole.present
        ? beneficiaryRole.value
        : this.beneficiaryRole,
    sourceAccountId: sourceAccountId.present
        ? sourceAccountId.value
        : this.sourceAccountId,
    destinationAccountId: destinationAccountId.present
        ? destinationAccountId.value
        : this.destinationAccountId,
    totalAmountMinorUnits: totalAmountMinorUnits ?? this.totalAmountMinorUnits,
    currencyCode: currencyCode ?? this.currencyCode,
    isRecurring: isRecurring ?? this.isRecurring,
    recurringRuleId: recurringRuleId.present
        ? recurringRuleId.value
        : this.recurringRuleId,
    tags: tags.present ? tags.value : this.tags,
    receiptPath: receiptPath.present ? receiptPath.value : this.receiptPath,
    isReversed: isReversed ?? this.isReversed,
    reversedBy: reversedBy.present ? reversedBy.value : this.reversedBy,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  DbOperation copyWithCompanion(OperationsCompanion data) {
    return DbOperation(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      type: data.type.present ? data.type.value : this.type,
      effectiveDate: data.effectiveDate.present
          ? data.effectiveDate.value
          : this.effectiveDate,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      description: data.description.present
          ? data.description.value
          : this.description,
      categoryCode: data.categoryCode.present
          ? data.categoryCode.value
          : this.categoryCode,
      scope: data.scope.present ? data.scope.value : this.scope,
      spenderRole: data.spenderRole.present
          ? data.spenderRole.value
          : this.spenderRole,
      beneficiaryRole: data.beneficiaryRole.present
          ? data.beneficiaryRole.value
          : this.beneficiaryRole,
      sourceAccountId: data.sourceAccountId.present
          ? data.sourceAccountId.value
          : this.sourceAccountId,
      destinationAccountId: data.destinationAccountId.present
          ? data.destinationAccountId.value
          : this.destinationAccountId,
      totalAmountMinorUnits: data.totalAmountMinorUnits.present
          ? data.totalAmountMinorUnits.value
          : this.totalAmountMinorUnits,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      recurringRuleId: data.recurringRuleId.present
          ? data.recurringRuleId.value
          : this.recurringRuleId,
      tags: data.tags.present ? data.tags.value : this.tags,
      receiptPath: data.receiptPath.present
          ? data.receiptPath.value
          : this.receiptPath,
      isReversed: data.isReversed.present
          ? data.isReversed.value
          : this.isReversed,
      reversedBy: data.reversedBy.present
          ? data.reversedBy.value
          : this.reversedBy,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbOperation(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('householdId: $householdId, ')
          ..write('type: $type, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('description: $description, ')
          ..write('categoryCode: $categoryCode, ')
          ..write('scope: $scope, ')
          ..write('spenderRole: $spenderRole, ')
          ..write('beneficiaryRole: $beneficiaryRole, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('totalAmountMinorUnits: $totalAmountMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurringRuleId: $recurringRuleId, ')
          ..write('tags: $tags, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('isReversed: $isReversed, ')
          ..write('reversedBy: $reversedBy, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    idempotencyKey,
    householdId,
    type,
    effectiveDate,
    recordedAt,
    description,
    categoryCode,
    scope,
    spenderRole,
    beneficiaryRole,
    sourceAccountId,
    destinationAccountId,
    totalAmountMinorUnits,
    currencyCode,
    isRecurring,
    recurringRuleId,
    tags,
    receiptPath,
    isReversed,
    reversedBy,
    createdBy,
    createdAt,
    updatedAt,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbOperation &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.householdId == this.householdId &&
          other.type == this.type &&
          other.effectiveDate == this.effectiveDate &&
          other.recordedAt == this.recordedAt &&
          other.description == this.description &&
          other.categoryCode == this.categoryCode &&
          other.scope == this.scope &&
          other.spenderRole == this.spenderRole &&
          other.beneficiaryRole == this.beneficiaryRole &&
          other.sourceAccountId == this.sourceAccountId &&
          other.destinationAccountId == this.destinationAccountId &&
          other.totalAmountMinorUnits == this.totalAmountMinorUnits &&
          other.currencyCode == this.currencyCode &&
          other.isRecurring == this.isRecurring &&
          other.recurringRuleId == this.recurringRuleId &&
          other.tags == this.tags &&
          other.receiptPath == this.receiptPath &&
          other.isReversed == this.isReversed &&
          other.reversedBy == this.reversedBy &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class OperationsCompanion extends UpdateCompanion<DbOperation> {
  final Value<String> id;
  final Value<String?> idempotencyKey;
  final Value<String> householdId;
  final Value<String> type;
  final Value<String> effectiveDate;
  final Value<String> recordedAt;
  final Value<String?> description;
  final Value<String?> categoryCode;
  final Value<String?> scope;
  final Value<String?> spenderRole;
  final Value<String?> beneficiaryRole;
  final Value<String?> sourceAccountId;
  final Value<String?> destinationAccountId;
  final Value<int> totalAmountMinorUnits;
  final Value<String> currencyCode;
  final Value<bool> isRecurring;
  final Value<String?> recurringRuleId;
  final Value<String?> tags;
  final Value<String?> receiptPath;
  final Value<bool> isReversed;
  final Value<String?> reversedBy;
  final Value<String> createdBy;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const OperationsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.householdId = const Value.absent(),
    this.type = const Value.absent(),
    this.effectiveDate = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.description = const Value.absent(),
    this.categoryCode = const Value.absent(),
    this.scope = const Value.absent(),
    this.spenderRole = const Value.absent(),
    this.beneficiaryRole = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    this.totalAmountMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurringRuleId = const Value.absent(),
    this.tags = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.isReversed = const Value.absent(),
    this.reversedBy = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OperationsCompanion.insert({
    required String id,
    this.idempotencyKey = const Value.absent(),
    required String householdId,
    required String type,
    required String effectiveDate,
    required String recordedAt,
    this.description = const Value.absent(),
    this.categoryCode = const Value.absent(),
    this.scope = const Value.absent(),
    this.spenderRole = const Value.absent(),
    this.beneficiaryRole = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.destinationAccountId = const Value.absent(),
    required int totalAmountMinorUnits,
    this.currencyCode = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurringRuleId = const Value.absent(),
    this.tags = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.isReversed = const Value.absent(),
    this.reversedBy = const Value.absent(),
    required String createdBy,
    required String createdAt,
    required String updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       type = Value(type),
       effectiveDate = Value(effectiveDate),
       recordedAt = Value(recordedAt),
       totalAmountMinorUnits = Value(totalAmountMinorUnits),
       createdBy = Value(createdBy),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DbOperation> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? householdId,
    Expression<String>? type,
    Expression<String>? effectiveDate,
    Expression<String>? recordedAt,
    Expression<String>? description,
    Expression<String>? categoryCode,
    Expression<String>? scope,
    Expression<String>? spenderRole,
    Expression<String>? beneficiaryRole,
    Expression<String>? sourceAccountId,
    Expression<String>? destinationAccountId,
    Expression<int>? totalAmountMinorUnits,
    Expression<String>? currencyCode,
    Expression<bool>? isRecurring,
    Expression<String>? recurringRuleId,
    Expression<String>? tags,
    Expression<String>? receiptPath,
    Expression<bool>? isReversed,
    Expression<String>? reversedBy,
    Expression<String>? createdBy,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (householdId != null) 'household_id': householdId,
      if (type != null) 'type': type,
      if (effectiveDate != null) 'effective_date': effectiveDate,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (description != null) 'description': description,
      if (categoryCode != null) 'category_code': categoryCode,
      if (scope != null) 'scope': scope,
      if (spenderRole != null) 'spender_role': spenderRole,
      if (beneficiaryRole != null) 'beneficiary_role': beneficiaryRole,
      if (sourceAccountId != null) 'source_account_id': sourceAccountId,
      if (destinationAccountId != null)
        'destination_account_id': destinationAccountId,
      if (totalAmountMinorUnits != null)
        'total_amount_minor_units': totalAmountMinorUnits,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurringRuleId != null) 'recurring_rule_id': recurringRuleId,
      if (tags != null) 'tags': tags,
      if (receiptPath != null) 'receipt_path': receiptPath,
      if (isReversed != null) 'is_reversed': isReversed,
      if (reversedBy != null) 'reversed_by': reversedBy,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OperationsCompanion copyWith({
    Value<String>? id,
    Value<String?>? idempotencyKey,
    Value<String>? householdId,
    Value<String>? type,
    Value<String>? effectiveDate,
    Value<String>? recordedAt,
    Value<String?>? description,
    Value<String?>? categoryCode,
    Value<String?>? scope,
    Value<String?>? spenderRole,
    Value<String?>? beneficiaryRole,
    Value<String?>? sourceAccountId,
    Value<String?>? destinationAccountId,
    Value<int>? totalAmountMinorUnits,
    Value<String>? currencyCode,
    Value<bool>? isRecurring,
    Value<String?>? recurringRuleId,
    Value<String?>? tags,
    Value<String?>? receiptPath,
    Value<bool>? isReversed,
    Value<String?>? reversedBy,
    Value<String>? createdBy,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return OperationsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      householdId: householdId ?? this.householdId,
      type: type ?? this.type,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      recordedAt: recordedAt ?? this.recordedAt,
      description: description ?? this.description,
      categoryCode: categoryCode ?? this.categoryCode,
      scope: scope ?? this.scope,
      spenderRole: spenderRole ?? this.spenderRole,
      beneficiaryRole: beneficiaryRole ?? this.beneficiaryRole,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      totalAmountMinorUnits:
          totalAmountMinorUnits ?? this.totalAmountMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      tags: tags ?? this.tags,
      receiptPath: receiptPath ?? this.receiptPath,
      isReversed: isReversed ?? this.isReversed,
      reversedBy: reversedBy ?? this.reversedBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (effectiveDate.present) {
      map['effective_date'] = Variable<String>(effectiveDate.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<String>(recordedAt.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (categoryCode.present) {
      map['category_code'] = Variable<String>(categoryCode.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (spenderRole.present) {
      map['spender_role'] = Variable<String>(spenderRole.value);
    }
    if (beneficiaryRole.present) {
      map['beneficiary_role'] = Variable<String>(beneficiaryRole.value);
    }
    if (sourceAccountId.present) {
      map['source_account_id'] = Variable<String>(sourceAccountId.value);
    }
    if (destinationAccountId.present) {
      map['destination_account_id'] = Variable<String>(
        destinationAccountId.value,
      );
    }
    if (totalAmountMinorUnits.present) {
      map['total_amount_minor_units'] = Variable<int>(
        totalAmountMinorUnits.value,
      );
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (recurringRuleId.present) {
      map['recurring_rule_id'] = Variable<String>(recurringRuleId.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (receiptPath.present) {
      map['receipt_path'] = Variable<String>(receiptPath.value);
    }
    if (isReversed.present) {
      map['is_reversed'] = Variable<bool>(isReversed.value);
    }
    if (reversedBy.present) {
      map['reversed_by'] = Variable<String>(reversedBy.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperationsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('householdId: $householdId, ')
          ..write('type: $type, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('description: $description, ')
          ..write('categoryCode: $categoryCode, ')
          ..write('scope: $scope, ')
          ..write('spenderRole: $spenderRole, ')
          ..write('beneficiaryRole: $beneficiaryRole, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('destinationAccountId: $destinationAccountId, ')
          ..write('totalAmountMinorUnits: $totalAmountMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurringRuleId: $recurringRuleId, ')
          ..write('tags: $tags, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('isReversed: $isReversed, ')
          ..write('reversedBy: $reversedBy, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChildWithdrawalAuditsTable extends ChildWithdrawalAudits
    with TableInfo<$ChildWithdrawalAuditsTable, DbChildWithdrawalAudit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildWithdrawalAuditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES operations (id)',
    ),
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES financial_accounts (id)',
    ),
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beneficiaryMeta = const VerificationMeta(
    'beneficiary',
  );
  @override
  late final GeneratedColumn<String> beneficiary = GeneratedColumn<String>(
    'beneficiary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<String> confirmedAt = GeneratedColumn<String>(
    'confirmed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedByMeta = const VerificationMeta(
    'confirmedBy',
  );
  @override
  late final GeneratedColumn<String> confirmedBy = GeneratedColumn<String>(
    'confirmed_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warningShownMeta = const VerificationMeta(
    'warningShown',
  );
  @override
  late final GeneratedColumn<bool> warningShown = GeneratedColumn<bool>(
    'warning_shown',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("warning_shown" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _biometricConfirmedMeta =
      const VerificationMeta('biometricConfirmed');
  @override
  late final GeneratedColumn<bool> biometricConfirmed = GeneratedColumn<bool>(
    'biometric_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("biometric_confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationId,
    householdId,
    accountId,
    amountMinorUnits,
    reason,
    beneficiary,
    confirmedAt,
    confirmedBy,
    warningShown,
    biometricConfirmed,
    createdAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'child_withdrawal_audits';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbChildWithdrawalAudit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorUnitsMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('beneficiary')) {
      context.handle(
        _beneficiaryMeta,
        beneficiary.isAcceptableOrUnknown(
          data['beneficiary']!,
          _beneficiaryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_beneficiaryMeta);
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confirmedAtMeta);
    }
    if (data.containsKey('confirmed_by')) {
      context.handle(
        _confirmedByMeta,
        confirmedBy.isAcceptableOrUnknown(
          data['confirmed_by']!,
          _confirmedByMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_confirmedByMeta);
    }
    if (data.containsKey('warning_shown')) {
      context.handle(
        _warningShownMeta,
        warningShown.isAcceptableOrUnknown(
          data['warning_shown']!,
          _warningShownMeta,
        ),
      );
    }
    if (data.containsKey('biometric_confirmed')) {
      context.handle(
        _biometricConfirmedMeta,
        biometricConfirmed.isAcceptableOrUnknown(
          data['biometric_confirmed']!,
          _biometricConfirmedMeta,
        ),
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
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbChildWithdrawalAudit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbChildWithdrawalAudit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      beneficiary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beneficiary'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_at'],
      )!,
      confirmedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmed_by'],
      )!,
      warningShown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}warning_shown'],
      )!,
      biometricConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}biometric_confirmed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ChildWithdrawalAuditsTable createAlias(String alias) {
    return $ChildWithdrawalAuditsTable(attachedDatabase, alias);
  }
}

class DbChildWithdrawalAudit extends DataClass
    implements Insertable<DbChildWithdrawalAudit> {
  final String id;
  final String operationId;
  final String householdId;
  final String accountId;

  /// Always positive; CHECK enforced in migration SQL.
  final int amountMinorUnits;

  /// Mandatory non-empty reason. CHECK(length(reason) > 0) enforced in migration.
  final String reason;

  /// HouseholdMemberRole code.
  final String beneficiary;

  /// UTC ISO 8601 timestamp of user confirmation.
  final String confirmedAt;
  final String confirmedBy;

  /// Must always be true. CHECK(warning_shown = 1) enforced in migration.
  final bool warningShown;
  final bool biometricConfirmed;
  final String createdAt;

  /// SyncStatus code.
  final String syncStatus;
  const DbChildWithdrawalAudit({
    required this.id,
    required this.operationId,
    required this.householdId,
    required this.accountId,
    required this.amountMinorUnits,
    required this.reason,
    required this.beneficiary,
    required this.confirmedAt,
    required this.confirmedBy,
    required this.warningShown,
    required this.biometricConfirmed,
    required this.createdAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation_id'] = Variable<String>(operationId);
    map['household_id'] = Variable<String>(householdId);
    map['account_id'] = Variable<String>(accountId);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['reason'] = Variable<String>(reason);
    map['beneficiary'] = Variable<String>(beneficiary);
    map['confirmed_at'] = Variable<String>(confirmedAt);
    map['confirmed_by'] = Variable<String>(confirmedBy);
    map['warning_shown'] = Variable<bool>(warningShown);
    map['biometric_confirmed'] = Variable<bool>(biometricConfirmed);
    map['created_at'] = Variable<String>(createdAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  ChildWithdrawalAuditsCompanion toCompanion(bool nullToAbsent) {
    return ChildWithdrawalAuditsCompanion(
      id: Value(id),
      operationId: Value(operationId),
      householdId: Value(householdId),
      accountId: Value(accountId),
      amountMinorUnits: Value(amountMinorUnits),
      reason: Value(reason),
      beneficiary: Value(beneficiary),
      confirmedAt: Value(confirmedAt),
      confirmedBy: Value(confirmedBy),
      warningShown: Value(warningShown),
      biometricConfirmed: Value(biometricConfirmed),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory DbChildWithdrawalAudit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbChildWithdrawalAudit(
      id: serializer.fromJson<String>(json['id']),
      operationId: serializer.fromJson<String>(json['operationId']),
      householdId: serializer.fromJson<String>(json['householdId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      reason: serializer.fromJson<String>(json['reason']),
      beneficiary: serializer.fromJson<String>(json['beneficiary']),
      confirmedAt: serializer.fromJson<String>(json['confirmedAt']),
      confirmedBy: serializer.fromJson<String>(json['confirmedBy']),
      warningShown: serializer.fromJson<bool>(json['warningShown']),
      biometricConfirmed: serializer.fromJson<bool>(json['biometricConfirmed']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operationId': serializer.toJson<String>(operationId),
      'householdId': serializer.toJson<String>(householdId),
      'accountId': serializer.toJson<String>(accountId),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'reason': serializer.toJson<String>(reason),
      'beneficiary': serializer.toJson<String>(beneficiary),
      'confirmedAt': serializer.toJson<String>(confirmedAt),
      'confirmedBy': serializer.toJson<String>(confirmedBy),
      'warningShown': serializer.toJson<bool>(warningShown),
      'biometricConfirmed': serializer.toJson<bool>(biometricConfirmed),
      'createdAt': serializer.toJson<String>(createdAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  DbChildWithdrawalAudit copyWith({
    String? id,
    String? operationId,
    String? householdId,
    String? accountId,
    int? amountMinorUnits,
    String? reason,
    String? beneficiary,
    String? confirmedAt,
    String? confirmedBy,
    bool? warningShown,
    bool? biometricConfirmed,
    String? createdAt,
    String? syncStatus,
  }) => DbChildWithdrawalAudit(
    id: id ?? this.id,
    operationId: operationId ?? this.operationId,
    householdId: householdId ?? this.householdId,
    accountId: accountId ?? this.accountId,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    reason: reason ?? this.reason,
    beneficiary: beneficiary ?? this.beneficiary,
    confirmedAt: confirmedAt ?? this.confirmedAt,
    confirmedBy: confirmedBy ?? this.confirmedBy,
    warningShown: warningShown ?? this.warningShown,
    biometricConfirmed: biometricConfirmed ?? this.biometricConfirmed,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  DbChildWithdrawalAudit copyWithCompanion(
    ChildWithdrawalAuditsCompanion data,
  ) {
    return DbChildWithdrawalAudit(
      id: data.id.present ? data.id.value : this.id,
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      reason: data.reason.present ? data.reason.value : this.reason,
      beneficiary: data.beneficiary.present
          ? data.beneficiary.value
          : this.beneficiary,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
      confirmedBy: data.confirmedBy.present
          ? data.confirmedBy.value
          : this.confirmedBy,
      warningShown: data.warningShown.present
          ? data.warningShown.value
          : this.warningShown,
      biometricConfirmed: data.biometricConfirmed.present
          ? data.biometricConfirmed.value
          : this.biometricConfirmed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbChildWithdrawalAudit(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('householdId: $householdId, ')
          ..write('accountId: $accountId, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('reason: $reason, ')
          ..write('beneficiary: $beneficiary, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('confirmedBy: $confirmedBy, ')
          ..write('warningShown: $warningShown, ')
          ..write('biometricConfirmed: $biometricConfirmed, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationId,
    householdId,
    accountId,
    amountMinorUnits,
    reason,
    beneficiary,
    confirmedAt,
    confirmedBy,
    warningShown,
    biometricConfirmed,
    createdAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbChildWithdrawalAudit &&
          other.id == this.id &&
          other.operationId == this.operationId &&
          other.householdId == this.householdId &&
          other.accountId == this.accountId &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.reason == this.reason &&
          other.beneficiary == this.beneficiary &&
          other.confirmedAt == this.confirmedAt &&
          other.confirmedBy == this.confirmedBy &&
          other.warningShown == this.warningShown &&
          other.biometricConfirmed == this.biometricConfirmed &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus);
}

class ChildWithdrawalAuditsCompanion
    extends UpdateCompanion<DbChildWithdrawalAudit> {
  final Value<String> id;
  final Value<String> operationId;
  final Value<String> householdId;
  final Value<String> accountId;
  final Value<int> amountMinorUnits;
  final Value<String> reason;
  final Value<String> beneficiary;
  final Value<String> confirmedAt;
  final Value<String> confirmedBy;
  final Value<bool> warningShown;
  final Value<bool> biometricConfirmed;
  final Value<String> createdAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const ChildWithdrawalAuditsCompanion({
    this.id = const Value.absent(),
    this.operationId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.reason = const Value.absent(),
    this.beneficiary = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.confirmedBy = const Value.absent(),
    this.warningShown = const Value.absent(),
    this.biometricConfirmed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChildWithdrawalAuditsCompanion.insert({
    required String id,
    required String operationId,
    required String householdId,
    required String accountId,
    required int amountMinorUnits,
    required String reason,
    required String beneficiary,
    required String confirmedAt,
    required String confirmedBy,
    this.warningShown = const Value.absent(),
    this.biometricConfirmed = const Value.absent(),
    required String createdAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       operationId = Value(operationId),
       householdId = Value(householdId),
       accountId = Value(accountId),
       amountMinorUnits = Value(amountMinorUnits),
       reason = Value(reason),
       beneficiary = Value(beneficiary),
       confirmedAt = Value(confirmedAt),
       confirmedBy = Value(confirmedBy),
       createdAt = Value(createdAt);
  static Insertable<DbChildWithdrawalAudit> custom({
    Expression<String>? id,
    Expression<String>? operationId,
    Expression<String>? householdId,
    Expression<String>? accountId,
    Expression<int>? amountMinorUnits,
    Expression<String>? reason,
    Expression<String>? beneficiary,
    Expression<String>? confirmedAt,
    Expression<String>? confirmedBy,
    Expression<bool>? warningShown,
    Expression<bool>? biometricConfirmed,
    Expression<String>? createdAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationId != null) 'operation_id': operationId,
      if (householdId != null) 'household_id': householdId,
      if (accountId != null) 'account_id': accountId,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (reason != null) 'reason': reason,
      if (beneficiary != null) 'beneficiary': beneficiary,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (confirmedBy != null) 'confirmed_by': confirmedBy,
      if (warningShown != null) 'warning_shown': warningShown,
      if (biometricConfirmed != null) 'biometric_confirmed': biometricConfirmed,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChildWithdrawalAuditsCompanion copyWith({
    Value<String>? id,
    Value<String>? operationId,
    Value<String>? householdId,
    Value<String>? accountId,
    Value<int>? amountMinorUnits,
    Value<String>? reason,
    Value<String>? beneficiary,
    Value<String>? confirmedAt,
    Value<String>? confirmedBy,
    Value<bool>? warningShown,
    Value<bool>? biometricConfirmed,
    Value<String>? createdAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return ChildWithdrawalAuditsCompanion(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      householdId: householdId ?? this.householdId,
      accountId: accountId ?? this.accountId,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      reason: reason ?? this.reason,
      beneficiary: beneficiary ?? this.beneficiary,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      warningShown: warningShown ?? this.warningShown,
      biometricConfirmed: biometricConfirmed ?? this.biometricConfirmed,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (beneficiary.present) {
      map['beneficiary'] = Variable<String>(beneficiary.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<String>(confirmedAt.value);
    }
    if (confirmedBy.present) {
      map['confirmed_by'] = Variable<String>(confirmedBy.value);
    }
    if (warningShown.present) {
      map['warning_shown'] = Variable<bool>(warningShown.value);
    }
    if (biometricConfirmed.present) {
      map['biometric_confirmed'] = Variable<bool>(biometricConfirmed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildWithdrawalAuditsCompanion(')
          ..write('id: $id, ')
          ..write('operationId: $operationId, ')
          ..write('householdId: $householdId, ')
          ..write('accountId: $accountId, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('reason: $reason, ')
          ..write('beneficiary: $beneficiary, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('confirmedBy: $confirmedBy, ')
          ..write('warningShown: $warningShown, ')
          ..write('biometricConfirmed: $biometricConfirmed, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperationContextsTable extends OperationContexts
    with TableInfo<$OperationContextsTable, DbOperationContext> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperationContextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spenderMemberIdMeta = const VerificationMeta(
    'spenderMemberId',
  );
  @override
  late final GeneratedColumn<String> spenderMemberId = GeneratedColumn<String>(
    'spender_member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beneficiaryMemberIdMeta =
      const VerificationMeta('beneficiaryMemberId');
  @override
  late final GeneratedColumn<String> beneficiaryMemberId =
      GeneratedColumn<String>(
        'beneficiary_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _expenseScopeMeta = const VerificationMeta(
    'expenseScope',
  );
  @override
  late final GeneratedColumn<String> expenseScope = GeneratedColumn<String>(
    'expense_scope',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recurringNoteMeta = const VerificationMeta(
    'recurringNote',
  );
  @override
  late final GeneratedColumn<String> recurringNote = GeneratedColumn<String>(
    'recurring_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryCodeMeta = const VerificationMeta(
    'categoryCode',
  );
  @override
  late final GeneratedColumn<String> categoryCode = GeneratedColumn<String>(
    'category_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    householdId,
    spenderMemberId,
    beneficiaryMemberId,
    expenseScope,
    isRecurring,
    recurringNote,
    categoryCode,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operation_contexts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbOperationContext> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('spender_member_id')) {
      context.handle(
        _spenderMemberIdMeta,
        spenderMemberId.isAcceptableOrUnknown(
          data['spender_member_id']!,
          _spenderMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('beneficiary_member_id')) {
      context.handle(
        _beneficiaryMemberIdMeta,
        beneficiaryMemberId.isAcceptableOrUnknown(
          data['beneficiary_member_id']!,
          _beneficiaryMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('expense_scope')) {
      context.handle(
        _expenseScopeMeta,
        expenseScope.isAcceptableOrUnknown(
          data['expense_scope']!,
          _expenseScopeMeta,
        ),
      );
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    }
    if (data.containsKey('recurring_note')) {
      context.handle(
        _recurringNoteMeta,
        recurringNote.isAcceptableOrUnknown(
          data['recurring_note']!,
          _recurringNoteMeta,
        ),
      );
    }
    if (data.containsKey('category_code')) {
      context.handle(
        _categoryCodeMeta,
        categoryCode.isAcceptableOrUnknown(
          data['category_code']!,
          _categoryCodeMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  DbOperationContext map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbOperationContext(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      spenderMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spender_member_id'],
      ),
      beneficiaryMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beneficiary_member_id'],
      ),
      expenseScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_scope'],
      ),
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      recurringNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurring_note'],
      ),
      categoryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_code'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OperationContextsTable createAlias(String alias) {
    return $OperationContextsTable(attachedDatabase, alias);
  }
}

class DbOperationContext extends DataClass
    implements Insertable<DbOperationContext> {
  /// The parent operation's ID. Primary key.
  final String operationId;

  /// The household this operation belongs to.
  final String householdId;

  /// Stable member UUID for the person who spent / initiated the transaction.
  /// Not a role code — this never changes when members are renamed.
  final String? spenderMemberId;

  /// Stable member UUID for the person who benefits from the transaction.
  final String? beneficiaryMemberId;

  /// [ExpenseScope] code for expense and child-fund operations.
  final String? expenseScope;

  /// True when the user flagged this as a recurring transaction.
  /// Automatic scheduling is deferred to a future phase.
  final bool isRecurring;

  /// Human-readable note about recurring intent, e.g. 'recurring_marker_not_scheduled'.
  final String? recurringNote;

  /// Stable category code, mirrors [operations.category_code] for query
  /// convenience without a JOIN.
  final String? categoryCode;

  /// Optional free-text note from the user. Mirrors the [operations.description]
  /// field for structured-query access.
  final String? note;

  /// UTC ISO 8601 creation timestamp.
  final String createdAt;
  const DbOperationContext({
    required this.operationId,
    required this.householdId,
    this.spenderMemberId,
    this.beneficiaryMemberId,
    this.expenseScope,
    required this.isRecurring,
    this.recurringNote,
    this.categoryCode,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['household_id'] = Variable<String>(householdId);
    if (!nullToAbsent || spenderMemberId != null) {
      map['spender_member_id'] = Variable<String>(spenderMemberId);
    }
    if (!nullToAbsent || beneficiaryMemberId != null) {
      map['beneficiary_member_id'] = Variable<String>(beneficiaryMemberId);
    }
    if (!nullToAbsent || expenseScope != null) {
      map['expense_scope'] = Variable<String>(expenseScope);
    }
    map['is_recurring'] = Variable<bool>(isRecurring);
    if (!nullToAbsent || recurringNote != null) {
      map['recurring_note'] = Variable<String>(recurringNote);
    }
    if (!nullToAbsent || categoryCode != null) {
      map['category_code'] = Variable<String>(categoryCode);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  OperationContextsCompanion toCompanion(bool nullToAbsent) {
    return OperationContextsCompanion(
      operationId: Value(operationId),
      householdId: Value(householdId),
      spenderMemberId: spenderMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(spenderMemberId),
      beneficiaryMemberId: beneficiaryMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(beneficiaryMemberId),
      expenseScope: expenseScope == null && nullToAbsent
          ? const Value.absent()
          : Value(expenseScope),
      isRecurring: Value(isRecurring),
      recurringNote: recurringNote == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringNote),
      categoryCode: categoryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryCode),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory DbOperationContext.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbOperationContext(
      operationId: serializer.fromJson<String>(json['operationId']),
      householdId: serializer.fromJson<String>(json['householdId']),
      spenderMemberId: serializer.fromJson<String?>(json['spenderMemberId']),
      beneficiaryMemberId: serializer.fromJson<String?>(
        json['beneficiaryMemberId'],
      ),
      expenseScope: serializer.fromJson<String?>(json['expenseScope']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      recurringNote: serializer.fromJson<String?>(json['recurringNote']),
      categoryCode: serializer.fromJson<String?>(json['categoryCode']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'householdId': serializer.toJson<String>(householdId),
      'spenderMemberId': serializer.toJson<String?>(spenderMemberId),
      'beneficiaryMemberId': serializer.toJson<String?>(beneficiaryMemberId),
      'expenseScope': serializer.toJson<String?>(expenseScope),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'recurringNote': serializer.toJson<String?>(recurringNote),
      'categoryCode': serializer.toJson<String?>(categoryCode),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  DbOperationContext copyWith({
    String? operationId,
    String? householdId,
    Value<String?> spenderMemberId = const Value.absent(),
    Value<String?> beneficiaryMemberId = const Value.absent(),
    Value<String?> expenseScope = const Value.absent(),
    bool? isRecurring,
    Value<String?> recurringNote = const Value.absent(),
    Value<String?> categoryCode = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? createdAt,
  }) => DbOperationContext(
    operationId: operationId ?? this.operationId,
    householdId: householdId ?? this.householdId,
    spenderMemberId: spenderMemberId.present
        ? spenderMemberId.value
        : this.spenderMemberId,
    beneficiaryMemberId: beneficiaryMemberId.present
        ? beneficiaryMemberId.value
        : this.beneficiaryMemberId,
    expenseScope: expenseScope.present ? expenseScope.value : this.expenseScope,
    isRecurring: isRecurring ?? this.isRecurring,
    recurringNote: recurringNote.present
        ? recurringNote.value
        : this.recurringNote,
    categoryCode: categoryCode.present ? categoryCode.value : this.categoryCode,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  DbOperationContext copyWithCompanion(OperationContextsCompanion data) {
    return DbOperationContext(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      spenderMemberId: data.spenderMemberId.present
          ? data.spenderMemberId.value
          : this.spenderMemberId,
      beneficiaryMemberId: data.beneficiaryMemberId.present
          ? data.beneficiaryMemberId.value
          : this.beneficiaryMemberId,
      expenseScope: data.expenseScope.present
          ? data.expenseScope.value
          : this.expenseScope,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      recurringNote: data.recurringNote.present
          ? data.recurringNote.value
          : this.recurringNote,
      categoryCode: data.categoryCode.present
          ? data.categoryCode.value
          : this.categoryCode,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbOperationContext(')
          ..write('operationId: $operationId, ')
          ..write('householdId: $householdId, ')
          ..write('spenderMemberId: $spenderMemberId, ')
          ..write('beneficiaryMemberId: $beneficiaryMemberId, ')
          ..write('expenseScope: $expenseScope, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurringNote: $recurringNote, ')
          ..write('categoryCode: $categoryCode, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    householdId,
    spenderMemberId,
    beneficiaryMemberId,
    expenseScope,
    isRecurring,
    recurringNote,
    categoryCode,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbOperationContext &&
          other.operationId == this.operationId &&
          other.householdId == this.householdId &&
          other.spenderMemberId == this.spenderMemberId &&
          other.beneficiaryMemberId == this.beneficiaryMemberId &&
          other.expenseScope == this.expenseScope &&
          other.isRecurring == this.isRecurring &&
          other.recurringNote == this.recurringNote &&
          other.categoryCode == this.categoryCode &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class OperationContextsCompanion extends UpdateCompanion<DbOperationContext> {
  final Value<String> operationId;
  final Value<String> householdId;
  final Value<String?> spenderMemberId;
  final Value<String?> beneficiaryMemberId;
  final Value<String?> expenseScope;
  final Value<bool> isRecurring;
  final Value<String?> recurringNote;
  final Value<String?> categoryCode;
  final Value<String?> note;
  final Value<String> createdAt;
  final Value<int> rowid;
  const OperationContextsCompanion({
    this.operationId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.spenderMemberId = const Value.absent(),
    this.beneficiaryMemberId = const Value.absent(),
    this.expenseScope = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurringNote = const Value.absent(),
    this.categoryCode = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OperationContextsCompanion.insert({
    required String operationId,
    required String householdId,
    this.spenderMemberId = const Value.absent(),
    this.beneficiaryMemberId = const Value.absent(),
    this.expenseScope = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurringNote = const Value.absent(),
    this.categoryCode = const Value.absent(),
    this.note = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       householdId = Value(householdId),
       createdAt = Value(createdAt);
  static Insertable<DbOperationContext> custom({
    Expression<String>? operationId,
    Expression<String>? householdId,
    Expression<String>? spenderMemberId,
    Expression<String>? beneficiaryMemberId,
    Expression<String>? expenseScope,
    Expression<bool>? isRecurring,
    Expression<String>? recurringNote,
    Expression<String>? categoryCode,
    Expression<String>? note,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (householdId != null) 'household_id': householdId,
      if (spenderMemberId != null) 'spender_member_id': spenderMemberId,
      if (beneficiaryMemberId != null)
        'beneficiary_member_id': beneficiaryMemberId,
      if (expenseScope != null) 'expense_scope': expenseScope,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurringNote != null) 'recurring_note': recurringNote,
      if (categoryCode != null) 'category_code': categoryCode,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OperationContextsCompanion copyWith({
    Value<String>? operationId,
    Value<String>? householdId,
    Value<String?>? spenderMemberId,
    Value<String?>? beneficiaryMemberId,
    Value<String?>? expenseScope,
    Value<bool>? isRecurring,
    Value<String?>? recurringNote,
    Value<String?>? categoryCode,
    Value<String?>? note,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return OperationContextsCompanion(
      operationId: operationId ?? this.operationId,
      householdId: householdId ?? this.householdId,
      spenderMemberId: spenderMemberId ?? this.spenderMemberId,
      beneficiaryMemberId: beneficiaryMemberId ?? this.beneficiaryMemberId,
      expenseScope: expenseScope ?? this.expenseScope,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringNote: recurringNote ?? this.recurringNote,
      categoryCode: categoryCode ?? this.categoryCode,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (spenderMemberId.present) {
      map['spender_member_id'] = Variable<String>(spenderMemberId.value);
    }
    if (beneficiaryMemberId.present) {
      map['beneficiary_member_id'] = Variable<String>(
        beneficiaryMemberId.value,
      );
    }
    if (expenseScope.present) {
      map['expense_scope'] = Variable<String>(expenseScope.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (recurringNote.present) {
      map['recurring_note'] = Variable<String>(recurringNote.value);
    }
    if (categoryCode.present) {
      map['category_code'] = Variable<String>(categoryCode.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperationContextsCompanion(')
          ..write('operationId: $operationId, ')
          ..write('householdId: $householdId, ')
          ..write('spenderMemberId: $spenderMemberId, ')
          ..write('beneficiaryMemberId: $beneficiaryMemberId, ')
          ..write('expenseScope: $expenseScope, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurringNote: $recurringNote, ')
          ..write('categoryCode: $categoryCode, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, DbBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
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
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitMinorUnitsMeta = const VerificationMeta(
    'limitMinorUnits',
  );
  @override
  late final GeneratedColumn<int> limitMinorUnits = GeneratedColumn<int>(
    'limit_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodTypeMeta = const VerificationMeta(
    'periodType',
  );
  @override
  late final GeneratedColumn<String> periodType = GeneratedColumn<String>(
    'period_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fixedStartDateMeta = const VerificationMeta(
    'fixedStartDate',
  );
  @override
  late final GeneratedColumn<String> fixedStartDate = GeneratedColumn<String>(
    'fixed_start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedEndDateMeta = const VerificationMeta(
    'fixedEndDate',
  );
  @override
  late final GeneratedColumn<String> fixedEndDate = GeneratedColumn<String>(
    'fixed_end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filterCategoryCodeMeta =
      const VerificationMeta('filterCategoryCode');
  @override
  late final GeneratedColumn<String> filterCategoryCode =
      GeneratedColumn<String>(
        'filter_category_code',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _filterScopeCodeMeta = const VerificationMeta(
    'filterScopeCode',
  );
  @override
  late final GeneratedColumn<String> filterScopeCode = GeneratedColumn<String>(
    'filter_scope_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filterSpenderMemberIdMeta =
      const VerificationMeta('filterSpenderMemberId');
  @override
  late final GeneratedColumn<String> filterSpenderMemberId =
      GeneratedColumn<String>(
        'filter_spender_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _filterBeneficiaryMemberIdMeta =
      const VerificationMeta('filterBeneficiaryMemberId');
  @override
  late final GeneratedColumn<String> filterBeneficiaryMemberId =
      GeneratedColumn<String>(
        'filter_beneficiary_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _filterPaymentAccountIdMeta =
      const VerificationMeta('filterPaymentAccountId');
  @override
  late final GeneratedColumn<String> filterPaymentAccountId =
      GeneratedColumn<String>(
        'filter_payment_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<int> isArchived = GeneratedColumn<int>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyPayloadMeta =
      const VerificationMeta('idempotencyPayload');
  @override
  late final GeneratedColumn<String> idempotencyPayload =
      GeneratedColumn<String>(
        'idempotency_payload',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    name,
    currencyCode,
    limitMinorUnits,
    periodType,
    fixedStartDate,
    fixedEndDate,
    filterCategoryCode,
    filterScopeCode,
    filterSpenderMemberId,
    filterBeneficiaryMemberId,
    filterPaymentAccountId,
    isArchived,
    idempotencyKey,
    idempotencyPayload,
    createdAt,
    updatedAt,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbBudget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('limit_minor_units')) {
      context.handle(
        _limitMinorUnitsMeta,
        limitMinorUnits.isAcceptableOrUnknown(
          data['limit_minor_units']!,
          _limitMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_limitMinorUnitsMeta);
    }
    if (data.containsKey('period_type')) {
      context.handle(
        _periodTypeMeta,
        periodType.isAcceptableOrUnknown(data['period_type']!, _periodTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_periodTypeMeta);
    }
    if (data.containsKey('fixed_start_date')) {
      context.handle(
        _fixedStartDateMeta,
        fixedStartDate.isAcceptableOrUnknown(
          data['fixed_start_date']!,
          _fixedStartDateMeta,
        ),
      );
    }
    if (data.containsKey('fixed_end_date')) {
      context.handle(
        _fixedEndDateMeta,
        fixedEndDate.isAcceptableOrUnknown(
          data['fixed_end_date']!,
          _fixedEndDateMeta,
        ),
      );
    }
    if (data.containsKey('filter_category_code')) {
      context.handle(
        _filterCategoryCodeMeta,
        filterCategoryCode.isAcceptableOrUnknown(
          data['filter_category_code']!,
          _filterCategoryCodeMeta,
        ),
      );
    }
    if (data.containsKey('filter_scope_code')) {
      context.handle(
        _filterScopeCodeMeta,
        filterScopeCode.isAcceptableOrUnknown(
          data['filter_scope_code']!,
          _filterScopeCodeMeta,
        ),
      );
    }
    if (data.containsKey('filter_spender_member_id')) {
      context.handle(
        _filterSpenderMemberIdMeta,
        filterSpenderMemberId.isAcceptableOrUnknown(
          data['filter_spender_member_id']!,
          _filterSpenderMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('filter_beneficiary_member_id')) {
      context.handle(
        _filterBeneficiaryMemberIdMeta,
        filterBeneficiaryMemberId.isAcceptableOrUnknown(
          data['filter_beneficiary_member_id']!,
          _filterBeneficiaryMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('filter_payment_account_id')) {
      context.handle(
        _filterPaymentAccountIdMeta,
        filterPaymentAccountId.isAcceptableOrUnknown(
          data['filter_payment_account_id']!,
          _filterPaymentAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('idempotency_payload')) {
      context.handle(
        _idempotencyPayloadMeta,
        idempotencyPayload.isAcceptableOrUnknown(
          data['idempotency_payload']!,
          _idempotencyPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyPayloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbBudget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      limitMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_minor_units'],
      )!,
      periodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_type'],
      )!,
      fixedStartDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_start_date'],
      ),
      fixedEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_end_date'],
      ),
      filterCategoryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_category_code'],
      ),
      filterScopeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_scope_code'],
      ),
      filterSpenderMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_spender_member_id'],
      ),
      filterBeneficiaryMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_beneficiary_member_id'],
      ),
      filterPaymentAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_payment_account_id'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_archived'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      idempotencyPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class DbBudget extends DataClass implements Insertable<DbBudget> {
  /// Stable client-generated UUID. Primary key.
  final String id;

  /// FK to households.id.
  final String householdId;

  /// User-visible budget name.
  final String name;

  /// ISO 4217 currency code. Immutable after creation.
  final String currencyCode;

  /// Spending limit in currency minor units.
  final int limitMinorUnits;

  /// 'monthly' or 'fixed'. Immutable after creation.
  final String periodType;

  /// ISO date yyyy-MM-dd inclusive start (only for periodType = 'fixed').
  final String? fixedStartDate;

  /// ISO date yyyy-MM-dd exclusive end (only for periodType = 'fixed').
  final String? fixedEndDate;

  /// Optional category code filter.
  final String? filterCategoryCode;

  /// Optional expense scope code filter.
  final String? filterScopeCode;

  /// Optional spender member UUID filter.
  final String? filterSpenderMemberId;

  /// Optional beneficiary member UUID filter.
  final String? filterBeneficiaryMemberId;

  /// Optional payment account ID filter.
  final String? filterPaymentAccountId;

  /// 0 = active, 1 = archived.
  final int isArchived;

  /// Stable fingerprint of creation payload for idempotency conflict detection.
  final String idempotencyKey;

  /// JSON-like serialized creation payload (for same-key-different-payload check).
  final String idempotencyPayload;

  /// UTC ISO 8601 creation timestamp.
  final String createdAt;

  /// UTC ISO 8601 last-updated timestamp.
  final String updatedAt;

  /// Schema version for this row (always 1 in Phase 5A).
  final int schemaVersion;
  const DbBudget({
    required this.id,
    required this.householdId,
    required this.name,
    required this.currencyCode,
    required this.limitMinorUnits,
    required this.periodType,
    this.fixedStartDate,
    this.fixedEndDate,
    this.filterCategoryCode,
    this.filterScopeCode,
    this.filterSpenderMemberId,
    this.filterBeneficiaryMemberId,
    this.filterPaymentAccountId,
    required this.isArchived,
    required this.idempotencyKey,
    required this.idempotencyPayload,
    required this.createdAt,
    required this.updatedAt,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['currency_code'] = Variable<String>(currencyCode);
    map['limit_minor_units'] = Variable<int>(limitMinorUnits);
    map['period_type'] = Variable<String>(periodType);
    if (!nullToAbsent || fixedStartDate != null) {
      map['fixed_start_date'] = Variable<String>(fixedStartDate);
    }
    if (!nullToAbsent || fixedEndDate != null) {
      map['fixed_end_date'] = Variable<String>(fixedEndDate);
    }
    if (!nullToAbsent || filterCategoryCode != null) {
      map['filter_category_code'] = Variable<String>(filterCategoryCode);
    }
    if (!nullToAbsent || filterScopeCode != null) {
      map['filter_scope_code'] = Variable<String>(filterScopeCode);
    }
    if (!nullToAbsent || filterSpenderMemberId != null) {
      map['filter_spender_member_id'] = Variable<String>(filterSpenderMemberId);
    }
    if (!nullToAbsent || filterBeneficiaryMemberId != null) {
      map['filter_beneficiary_member_id'] = Variable<String>(
        filterBeneficiaryMemberId,
      );
    }
    if (!nullToAbsent || filterPaymentAccountId != null) {
      map['filter_payment_account_id'] = Variable<String>(
        filterPaymentAccountId,
      );
    }
    map['is_archived'] = Variable<int>(isArchived);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['idempotency_payload'] = Variable<String>(idempotencyPayload);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      currencyCode: Value(currencyCode),
      limitMinorUnits: Value(limitMinorUnits),
      periodType: Value(periodType),
      fixedStartDate: fixedStartDate == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedStartDate),
      fixedEndDate: fixedEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedEndDate),
      filterCategoryCode: filterCategoryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(filterCategoryCode),
      filterScopeCode: filterScopeCode == null && nullToAbsent
          ? const Value.absent()
          : Value(filterScopeCode),
      filterSpenderMemberId: filterSpenderMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(filterSpenderMemberId),
      filterBeneficiaryMemberId:
          filterBeneficiaryMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(filterBeneficiaryMemberId),
      filterPaymentAccountId: filterPaymentAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(filterPaymentAccountId),
      isArchived: Value(isArchived),
      idempotencyKey: Value(idempotencyKey),
      idempotencyPayload: Value(idempotencyPayload),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory DbBudget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbBudget(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      limitMinorUnits: serializer.fromJson<int>(json['limitMinorUnits']),
      periodType: serializer.fromJson<String>(json['periodType']),
      fixedStartDate: serializer.fromJson<String?>(json['fixedStartDate']),
      fixedEndDate: serializer.fromJson<String?>(json['fixedEndDate']),
      filterCategoryCode: serializer.fromJson<String?>(
        json['filterCategoryCode'],
      ),
      filterScopeCode: serializer.fromJson<String?>(json['filterScopeCode']),
      filterSpenderMemberId: serializer.fromJson<String?>(
        json['filterSpenderMemberId'],
      ),
      filterBeneficiaryMemberId: serializer.fromJson<String?>(
        json['filterBeneficiaryMemberId'],
      ),
      filterPaymentAccountId: serializer.fromJson<String?>(
        json['filterPaymentAccountId'],
      ),
      isArchived: serializer.fromJson<int>(json['isArchived']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      idempotencyPayload: serializer.fromJson<String>(
        json['idempotencyPayload'],
      ),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'limitMinorUnits': serializer.toJson<int>(limitMinorUnits),
      'periodType': serializer.toJson<String>(periodType),
      'fixedStartDate': serializer.toJson<String?>(fixedStartDate),
      'fixedEndDate': serializer.toJson<String?>(fixedEndDate),
      'filterCategoryCode': serializer.toJson<String?>(filterCategoryCode),
      'filterScopeCode': serializer.toJson<String?>(filterScopeCode),
      'filterSpenderMemberId': serializer.toJson<String?>(
        filterSpenderMemberId,
      ),
      'filterBeneficiaryMemberId': serializer.toJson<String?>(
        filterBeneficiaryMemberId,
      ),
      'filterPaymentAccountId': serializer.toJson<String?>(
        filterPaymentAccountId,
      ),
      'isArchived': serializer.toJson<int>(isArchived),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'idempotencyPayload': serializer.toJson<String>(idempotencyPayload),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  DbBudget copyWith({
    String? id,
    String? householdId,
    String? name,
    String? currencyCode,
    int? limitMinorUnits,
    String? periodType,
    Value<String?> fixedStartDate = const Value.absent(),
    Value<String?> fixedEndDate = const Value.absent(),
    Value<String?> filterCategoryCode = const Value.absent(),
    Value<String?> filterScopeCode = const Value.absent(),
    Value<String?> filterSpenderMemberId = const Value.absent(),
    Value<String?> filterBeneficiaryMemberId = const Value.absent(),
    Value<String?> filterPaymentAccountId = const Value.absent(),
    int? isArchived,
    String? idempotencyKey,
    String? idempotencyPayload,
    String? createdAt,
    String? updatedAt,
    int? schemaVersion,
  }) => DbBudget(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    name: name ?? this.name,
    currencyCode: currencyCode ?? this.currencyCode,
    limitMinorUnits: limitMinorUnits ?? this.limitMinorUnits,
    periodType: periodType ?? this.periodType,
    fixedStartDate: fixedStartDate.present
        ? fixedStartDate.value
        : this.fixedStartDate,
    fixedEndDate: fixedEndDate.present ? fixedEndDate.value : this.fixedEndDate,
    filterCategoryCode: filterCategoryCode.present
        ? filterCategoryCode.value
        : this.filterCategoryCode,
    filterScopeCode: filterScopeCode.present
        ? filterScopeCode.value
        : this.filterScopeCode,
    filterSpenderMemberId: filterSpenderMemberId.present
        ? filterSpenderMemberId.value
        : this.filterSpenderMemberId,
    filterBeneficiaryMemberId: filterBeneficiaryMemberId.present
        ? filterBeneficiaryMemberId.value
        : this.filterBeneficiaryMemberId,
    filterPaymentAccountId: filterPaymentAccountId.present
        ? filterPaymentAccountId.value
        : this.filterPaymentAccountId,
    isArchived: isArchived ?? this.isArchived,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    idempotencyPayload: idempotencyPayload ?? this.idempotencyPayload,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  DbBudget copyWithCompanion(BudgetsCompanion data) {
    return DbBudget(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      limitMinorUnits: data.limitMinorUnits.present
          ? data.limitMinorUnits.value
          : this.limitMinorUnits,
      periodType: data.periodType.present
          ? data.periodType.value
          : this.periodType,
      fixedStartDate: data.fixedStartDate.present
          ? data.fixedStartDate.value
          : this.fixedStartDate,
      fixedEndDate: data.fixedEndDate.present
          ? data.fixedEndDate.value
          : this.fixedEndDate,
      filterCategoryCode: data.filterCategoryCode.present
          ? data.filterCategoryCode.value
          : this.filterCategoryCode,
      filterScopeCode: data.filterScopeCode.present
          ? data.filterScopeCode.value
          : this.filterScopeCode,
      filterSpenderMemberId: data.filterSpenderMemberId.present
          ? data.filterSpenderMemberId.value
          : this.filterSpenderMemberId,
      filterBeneficiaryMemberId: data.filterBeneficiaryMemberId.present
          ? data.filterBeneficiaryMemberId.value
          : this.filterBeneficiaryMemberId,
      filterPaymentAccountId: data.filterPaymentAccountId.present
          ? data.filterPaymentAccountId.value
          : this.filterPaymentAccountId,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      idempotencyPayload: data.idempotencyPayload.present
          ? data.idempotencyPayload.value
          : this.idempotencyPayload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbBudget(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('limitMinorUnits: $limitMinorUnits, ')
          ..write('periodType: $periodType, ')
          ..write('fixedStartDate: $fixedStartDate, ')
          ..write('fixedEndDate: $fixedEndDate, ')
          ..write('filterCategoryCode: $filterCategoryCode, ')
          ..write('filterScopeCode: $filterScopeCode, ')
          ..write('filterSpenderMemberId: $filterSpenderMemberId, ')
          ..write('filterBeneficiaryMemberId: $filterBeneficiaryMemberId, ')
          ..write('filterPaymentAccountId: $filterPaymentAccountId, ')
          ..write('isArchived: $isArchived, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('idempotencyPayload: $idempotencyPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdId,
    name,
    currencyCode,
    limitMinorUnits,
    periodType,
    fixedStartDate,
    fixedEndDate,
    filterCategoryCode,
    filterScopeCode,
    filterSpenderMemberId,
    filterBeneficiaryMemberId,
    filterPaymentAccountId,
    isArchived,
    idempotencyKey,
    idempotencyPayload,
    createdAt,
    updatedAt,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbBudget &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.currencyCode == this.currencyCode &&
          other.limitMinorUnits == this.limitMinorUnits &&
          other.periodType == this.periodType &&
          other.fixedStartDate == this.fixedStartDate &&
          other.fixedEndDate == this.fixedEndDate &&
          other.filterCategoryCode == this.filterCategoryCode &&
          other.filterScopeCode == this.filterScopeCode &&
          other.filterSpenderMemberId == this.filterSpenderMemberId &&
          other.filterBeneficiaryMemberId == this.filterBeneficiaryMemberId &&
          other.filterPaymentAccountId == this.filterPaymentAccountId &&
          other.isArchived == this.isArchived &&
          other.idempotencyKey == this.idempotencyKey &&
          other.idempotencyPayload == this.idempotencyPayload &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.schemaVersion == this.schemaVersion);
}

class BudgetsCompanion extends UpdateCompanion<DbBudget> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String> currencyCode;
  final Value<int> limitMinorUnits;
  final Value<String> periodType;
  final Value<String?> fixedStartDate;
  final Value<String?> fixedEndDate;
  final Value<String?> filterCategoryCode;
  final Value<String?> filterScopeCode;
  final Value<String?> filterSpenderMemberId;
  final Value<String?> filterBeneficiaryMemberId;
  final Value<String?> filterPaymentAccountId;
  final Value<int> isArchived;
  final Value<String> idempotencyKey;
  final Value<String> idempotencyPayload;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.limitMinorUnits = const Value.absent(),
    this.periodType = const Value.absent(),
    this.fixedStartDate = const Value.absent(),
    this.fixedEndDate = const Value.absent(),
    this.filterCategoryCode = const Value.absent(),
    this.filterScopeCode = const Value.absent(),
    this.filterSpenderMemberId = const Value.absent(),
    this.filterBeneficiaryMemberId = const Value.absent(),
    this.filterPaymentAccountId = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.idempotencyPayload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    required String currencyCode,
    required int limitMinorUnits,
    required String periodType,
    this.fixedStartDate = const Value.absent(),
    this.fixedEndDate = const Value.absent(),
    this.filterCategoryCode = const Value.absent(),
    this.filterScopeCode = const Value.absent(),
    this.filterSpenderMemberId = const Value.absent(),
    this.filterBeneficiaryMemberId = const Value.absent(),
    this.filterPaymentAccountId = const Value.absent(),
    this.isArchived = const Value.absent(),
    required String idempotencyKey,
    required String idempotencyPayload,
    required String createdAt,
    required String updatedAt,
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       name = Value(name),
       currencyCode = Value(currencyCode),
       limitMinorUnits = Value(limitMinorUnits),
       periodType = Value(periodType),
       idempotencyKey = Value(idempotencyKey),
       idempotencyPayload = Value(idempotencyPayload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DbBudget> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? currencyCode,
    Expression<int>? limitMinorUnits,
    Expression<String>? periodType,
    Expression<String>? fixedStartDate,
    Expression<String>? fixedEndDate,
    Expression<String>? filterCategoryCode,
    Expression<String>? filterScopeCode,
    Expression<String>? filterSpenderMemberId,
    Expression<String>? filterBeneficiaryMemberId,
    Expression<String>? filterPaymentAccountId,
    Expression<int>? isArchived,
    Expression<String>? idempotencyKey,
    Expression<String>? idempotencyPayload,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (limitMinorUnits != null) 'limit_minor_units': limitMinorUnits,
      if (periodType != null) 'period_type': periodType,
      if (fixedStartDate != null) 'fixed_start_date': fixedStartDate,
      if (fixedEndDate != null) 'fixed_end_date': fixedEndDate,
      if (filterCategoryCode != null)
        'filter_category_code': filterCategoryCode,
      if (filterScopeCode != null) 'filter_scope_code': filterScopeCode,
      if (filterSpenderMemberId != null)
        'filter_spender_member_id': filterSpenderMemberId,
      if (filterBeneficiaryMemberId != null)
        'filter_beneficiary_member_id': filterBeneficiaryMemberId,
      if (filterPaymentAccountId != null)
        'filter_payment_account_id': filterPaymentAccountId,
      if (isArchived != null) 'is_archived': isArchived,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (idempotencyPayload != null) 'idempotency_payload': idempotencyPayload,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? name,
    Value<String>? currencyCode,
    Value<int>? limitMinorUnits,
    Value<String>? periodType,
    Value<String?>? fixedStartDate,
    Value<String?>? fixedEndDate,
    Value<String?>? filterCategoryCode,
    Value<String?>? filterScopeCode,
    Value<String?>? filterSpenderMemberId,
    Value<String?>? filterBeneficiaryMemberId,
    Value<String?>? filterPaymentAccountId,
    Value<int>? isArchived,
    Value<String>? idempotencyKey,
    Value<String>? idempotencyPayload,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      currencyCode: currencyCode ?? this.currencyCode,
      limitMinorUnits: limitMinorUnits ?? this.limitMinorUnits,
      periodType: periodType ?? this.periodType,
      fixedStartDate: fixedStartDate ?? this.fixedStartDate,
      fixedEndDate: fixedEndDate ?? this.fixedEndDate,
      filterCategoryCode: filterCategoryCode ?? this.filterCategoryCode,
      filterScopeCode: filterScopeCode ?? this.filterScopeCode,
      filterSpenderMemberId:
          filterSpenderMemberId ?? this.filterSpenderMemberId,
      filterBeneficiaryMemberId:
          filterBeneficiaryMemberId ?? this.filterBeneficiaryMemberId,
      filterPaymentAccountId:
          filterPaymentAccountId ?? this.filterPaymentAccountId,
      isArchived: isArchived ?? this.isArchived,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      idempotencyPayload: idempotencyPayload ?? this.idempotencyPayload,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (limitMinorUnits.present) {
      map['limit_minor_units'] = Variable<int>(limitMinorUnits.value);
    }
    if (periodType.present) {
      map['period_type'] = Variable<String>(periodType.value);
    }
    if (fixedStartDate.present) {
      map['fixed_start_date'] = Variable<String>(fixedStartDate.value);
    }
    if (fixedEndDate.present) {
      map['fixed_end_date'] = Variable<String>(fixedEndDate.value);
    }
    if (filterCategoryCode.present) {
      map['filter_category_code'] = Variable<String>(filterCategoryCode.value);
    }
    if (filterScopeCode.present) {
      map['filter_scope_code'] = Variable<String>(filterScopeCode.value);
    }
    if (filterSpenderMemberId.present) {
      map['filter_spender_member_id'] = Variable<String>(
        filterSpenderMemberId.value,
      );
    }
    if (filterBeneficiaryMemberId.present) {
      map['filter_beneficiary_member_id'] = Variable<String>(
        filterBeneficiaryMemberId.value,
      );
    }
    if (filterPaymentAccountId.present) {
      map['filter_payment_account_id'] = Variable<String>(
        filterPaymentAccountId.value,
      );
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<int>(isArchived.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (idempotencyPayload.present) {
      map['idempotency_payload'] = Variable<String>(idempotencyPayload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('limitMinorUnits: $limitMinorUnits, ')
          ..write('periodType: $periodType, ')
          ..write('fixedStartDate: $fixedStartDate, ')
          ..write('fixedEndDate: $fixedEndDate, ')
          ..write('filterCategoryCode: $filterCategoryCode, ')
          ..write('filterScopeCode: $filterScopeCode, ')
          ..write('filterSpenderMemberId: $filterSpenderMemberId, ')
          ..write('filterBeneficiaryMemberId: $filterBeneficiaryMemberId, ')
          ..write('filterPaymentAccountId: $filterPaymentAccountId, ')
          ..write('isArchived: $isArchived, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('idempotencyPayload: $idempotencyPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTableTable extends GoalsTable
    with TableInfo<$GoalsTableTable, DbGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reserveAccountIdMeta = const VerificationMeta(
    'reserveAccountId',
  );
  @override
  late final GeneratedColumn<String> reserveAccountId = GeneratedColumn<String>(
    'reserve_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES financial_accounts (id)',
    ),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyPayloadMeta =
      const VerificationMeta('idempotencyPayload');
  @override
  late final GeneratedColumn<String> idempotencyPayload =
      GeneratedColumn<String>(
        'idempotency_payload',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<String> archivedAt = GeneratedColumn<String>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _earlyCompletionReasonMeta =
      const VerificationMeta('earlyCompletionReason');
  @override
  late final GeneratedColumn<String> earlyCompletionReason =
      GeneratedColumn<String>(
        'early_completion_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    reserveAccountId,
    currencyCode,
    status,
    idempotencyKey,
    idempotencyPayload,
    createdAt,
    completedAt,
    archivedAt,
    earlyCompletionReason,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('reserve_account_id')) {
      context.handle(
        _reserveAccountIdMeta,
        reserveAccountId.isAcceptableOrUnknown(
          data['reserve_account_id']!,
          _reserveAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reserveAccountIdMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('idempotency_payload')) {
      context.handle(
        _idempotencyPayloadMeta,
        idempotencyPayload.isAcceptableOrUnknown(
          data['idempotency_payload']!,
          _idempotencyPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyPayloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('early_completion_reason')) {
      context.handle(
        _earlyCompletionReasonMeta,
        earlyCompletionReason.isAcceptableOrUnknown(
          data['early_completion_reason']!,
          _earlyCompletionReasonMeta,
        ),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      reserveAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reserve_account_id'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      idempotencyPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archived_at'],
      ),
      earlyCompletionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}early_completion_reason'],
      ),
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $GoalsTableTable createAlias(String alias) {
    return $GoalsTableTable(attachedDatabase, alias);
  }
}

class DbGoal extends DataClass implements Insertable<DbGoal> {
  /// Stable client-generated UUID. Primary key.
  final String id;

  /// FK to households.id.
  final String householdId;

  /// FK to financial_accounts.id — the dedicated goalReserve account.
  final String reserveAccountId;

  /// ISO 4217 currency code. Immutable after creation.
  final String currencyCode;

  /// 'active', 'targetReached', 'completed', 'archived'.
  final String status;

  /// Unique per (household_id, idempotency_key).
  final String idempotencyKey;

  /// Serialised creation-payload fingerprint for conflict detection.
  final String idempotencyPayload;

  /// UTC ISO 8601 creation timestamp.
  final String createdAt;

  /// Set when status = 'completed'.
  final String? completedAt;

  /// Set when status = 'archived'.
  final String? archivedAt;

  /// Reason stored when earlyCompletion = true (Phase 5B.3).
  final String? earlyCompletionReason;

  /// Schema version for forward-compatibility (always 1 in Phase 5B).
  final int schemaVersion;
  const DbGoal({
    required this.id,
    required this.householdId,
    required this.reserveAccountId,
    required this.currencyCode,
    required this.status,
    required this.idempotencyKey,
    required this.idempotencyPayload,
    required this.createdAt,
    this.completedAt,
    this.archivedAt,
    this.earlyCompletionReason,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['reserve_account_id'] = Variable<String>(reserveAccountId);
    map['currency_code'] = Variable<String>(currencyCode);
    map['status'] = Variable<String>(status);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['idempotency_payload'] = Variable<String>(idempotencyPayload);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<String>(archivedAt);
    }
    if (!nullToAbsent || earlyCompletionReason != null) {
      map['early_completion_reason'] = Variable<String>(earlyCompletionReason);
    }
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  GoalsTableCompanion toCompanion(bool nullToAbsent) {
    return GoalsTableCompanion(
      id: Value(id),
      householdId: Value(householdId),
      reserveAccountId: Value(reserveAccountId),
      currencyCode: Value(currencyCode),
      status: Value(status),
      idempotencyKey: Value(idempotencyKey),
      idempotencyPayload: Value(idempotencyPayload),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      earlyCompletionReason: earlyCompletionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(earlyCompletionReason),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory DbGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbGoal(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      reserveAccountId: serializer.fromJson<String>(json['reserveAccountId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      status: serializer.fromJson<String>(json['status']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      idempotencyPayload: serializer.fromJson<String>(
        json['idempotencyPayload'],
      ),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
      archivedAt: serializer.fromJson<String?>(json['archivedAt']),
      earlyCompletionReason: serializer.fromJson<String?>(
        json['earlyCompletionReason'],
      ),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'reserveAccountId': serializer.toJson<String>(reserveAccountId),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'status': serializer.toJson<String>(status),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'idempotencyPayload': serializer.toJson<String>(idempotencyPayload),
      'createdAt': serializer.toJson<String>(createdAt),
      'completedAt': serializer.toJson<String?>(completedAt),
      'archivedAt': serializer.toJson<String?>(archivedAt),
      'earlyCompletionReason': serializer.toJson<String?>(
        earlyCompletionReason,
      ),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  DbGoal copyWith({
    String? id,
    String? householdId,
    String? reserveAccountId,
    String? currencyCode,
    String? status,
    String? idempotencyKey,
    String? idempotencyPayload,
    String? createdAt,
    Value<String?> completedAt = const Value.absent(),
    Value<String?> archivedAt = const Value.absent(),
    Value<String?> earlyCompletionReason = const Value.absent(),
    int? schemaVersion,
  }) => DbGoal(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    reserveAccountId: reserveAccountId ?? this.reserveAccountId,
    currencyCode: currencyCode ?? this.currencyCode,
    status: status ?? this.status,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    idempotencyPayload: idempotencyPayload ?? this.idempotencyPayload,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    earlyCompletionReason: earlyCompletionReason.present
        ? earlyCompletionReason.value
        : this.earlyCompletionReason,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  DbGoal copyWithCompanion(GoalsTableCompanion data) {
    return DbGoal(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      reserveAccountId: data.reserveAccountId.present
          ? data.reserveAccountId.value
          : this.reserveAccountId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      status: data.status.present ? data.status.value : this.status,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      idempotencyPayload: data.idempotencyPayload.present
          ? data.idempotencyPayload.value
          : this.idempotencyPayload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      earlyCompletionReason: data.earlyCompletionReason.present
          ? data.earlyCompletionReason.value
          : this.earlyCompletionReason,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbGoal(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('reserveAccountId: $reserveAccountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('status: $status, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('idempotencyPayload: $idempotencyPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('earlyCompletionReason: $earlyCompletionReason, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdId,
    reserveAccountId,
    currencyCode,
    status,
    idempotencyKey,
    idempotencyPayload,
    createdAt,
    completedAt,
    archivedAt,
    earlyCompletionReason,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbGoal &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.reserveAccountId == this.reserveAccountId &&
          other.currencyCode == this.currencyCode &&
          other.status == this.status &&
          other.idempotencyKey == this.idempotencyKey &&
          other.idempotencyPayload == this.idempotencyPayload &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.archivedAt == this.archivedAt &&
          other.earlyCompletionReason == this.earlyCompletionReason &&
          other.schemaVersion == this.schemaVersion);
}

class GoalsTableCompanion extends UpdateCompanion<DbGoal> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> reserveAccountId;
  final Value<String> currencyCode;
  final Value<String> status;
  final Value<String> idempotencyKey;
  final Value<String> idempotencyPayload;
  final Value<String> createdAt;
  final Value<String?> completedAt;
  final Value<String?> archivedAt;
  final Value<String?> earlyCompletionReason;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const GoalsTableCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.reserveAccountId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.status = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.idempotencyPayload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.earlyCompletionReason = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsTableCompanion.insert({
    required String id,
    required String householdId,
    required String reserveAccountId,
    required String currencyCode,
    required String status,
    required String idempotencyKey,
    required String idempotencyPayload,
    required String createdAt,
    this.completedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.earlyCompletionReason = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       reserveAccountId = Value(reserveAccountId),
       currencyCode = Value(currencyCode),
       status = Value(status),
       idempotencyKey = Value(idempotencyKey),
       idempotencyPayload = Value(idempotencyPayload),
       createdAt = Value(createdAt);
  static Insertable<DbGoal> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? reserveAccountId,
    Expression<String>? currencyCode,
    Expression<String>? status,
    Expression<String>? idempotencyKey,
    Expression<String>? idempotencyPayload,
    Expression<String>? createdAt,
    Expression<String>? completedAt,
    Expression<String>? archivedAt,
    Expression<String>? earlyCompletionReason,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (reserveAccountId != null) 'reserve_account_id': reserveAccountId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (status != null) 'status': status,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (idempotencyPayload != null) 'idempotency_payload': idempotencyPayload,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (earlyCompletionReason != null)
        'early_completion_reason': earlyCompletionReason,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? reserveAccountId,
    Value<String>? currencyCode,
    Value<String>? status,
    Value<String>? idempotencyKey,
    Value<String>? idempotencyPayload,
    Value<String>? createdAt,
    Value<String?>? completedAt,
    Value<String?>? archivedAt,
    Value<String?>? earlyCompletionReason,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return GoalsTableCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      reserveAccountId: reserveAccountId ?? this.reserveAccountId,
      currencyCode: currencyCode ?? this.currencyCode,
      status: status ?? this.status,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      idempotencyPayload: idempotencyPayload ?? this.idempotencyPayload,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      earlyCompletionReason:
          earlyCompletionReason ?? this.earlyCompletionReason,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (reserveAccountId.present) {
      map['reserve_account_id'] = Variable<String>(reserveAccountId.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (idempotencyPayload.present) {
      map['idempotency_payload'] = Variable<String>(idempotencyPayload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<String>(archivedAt.value);
    }
    if (earlyCompletionReason.present) {
      map['early_completion_reason'] = Variable<String>(
        earlyCompletionReason.value,
      );
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsTableCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('reserveAccountId: $reserveAccountId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('status: $status, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('idempotencyPayload: $idempotencyPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('earlyCompletionReason: $earlyCompletionReason, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalRevisionsTableTable extends GoalRevisionsTable
    with TableInfo<$GoalRevisionsTableTable, DbGoalRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalRevisionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
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
  static const VerificationMeta _purposeCodeMeta = const VerificationMeta(
    'purposeCode',
  );
  @override
  late final GeneratedColumn<String> purposeCode = GeneratedColumn<String>(
    'purpose_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetMinorUnitsMeta = const VerificationMeta(
    'targetMinorUnits',
  );
  @override
  late final GeneratedColumn<int> targetMinorUnits = GeneratedColumn<int>(
    'target_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionReasonMeta = const VerificationMeta(
    'revisionReason',
  );
  @override
  late final GeneratedColumn<String> revisionReason = GeneratedColumn<String>(
    'revision_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beneficiaryMemberIdMeta =
      const VerificationMeta('beneficiaryMemberId');
  @override
  late final GeneratedColumn<String> beneficiaryMemberId =
      GeneratedColumn<String>(
        'beneficiary_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    householdId,
    name,
    purposeCode,
    targetMinorUnits,
    currencyCode,
    createdAt,
    revisionReason,
    targetDate,
    beneficiaryMemberId,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbGoalRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('purpose_code')) {
      context.handle(
        _purposeCodeMeta,
        purposeCode.isAcceptableOrUnknown(
          data['purpose_code']!,
          _purposeCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purposeCodeMeta);
    }
    if (data.containsKey('target_minor_units')) {
      context.handle(
        _targetMinorUnitsMeta,
        targetMinorUnits.isAcceptableOrUnknown(
          data['target_minor_units']!,
          _targetMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetMinorUnitsMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('revision_reason')) {
      context.handle(
        _revisionReasonMeta,
        revisionReason.isAcceptableOrUnknown(
          data['revision_reason']!,
          _revisionReasonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_revisionReasonMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('beneficiary_member_id')) {
      context.handle(
        _beneficiaryMemberIdMeta,
        beneficiaryMemberId.isAcceptableOrUnknown(
          data['beneficiary_member_id']!,
          _beneficiaryMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbGoalRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbGoalRevision(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      purposeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose_code'],
      )!,
      targetMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_minor_units'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      revisionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_reason'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      ),
      beneficiaryMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beneficiary_member_id'],
      ),
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $GoalRevisionsTableTable createAlias(String alias) {
    return $GoalRevisionsTableTable(attachedDatabase, alias);
  }
}

class DbGoalRevision extends DataClass implements Insertable<DbGoalRevision> {
  final String id;
  final String goalId;
  final String householdId;
  final String name;

  /// Stable non-localized code from [GoalPurpose.code].
  final String purposeCode;

  /// Target amount in currency minor units.
  final int targetMinorUnits;

  /// ISO 4217 currency code. Matches the parent goal currency.
  final String currencyCode;

  /// UTC ISO 8601 timestamp.
  final String createdAt;

  /// Human-readable reason for this revision.
  final String revisionReason;

  /// Optional ISO date (yyyy-MM-dd).
  final String? targetDate;

  /// Optional household member UUID.
  final String? beneficiaryMemberId;
  final int schemaVersion;
  const DbGoalRevision({
    required this.id,
    required this.goalId,
    required this.householdId,
    required this.name,
    required this.purposeCode,
    required this.targetMinorUnits,
    required this.currencyCode,
    required this.createdAt,
    required this.revisionReason,
    this.targetDate,
    this.beneficiaryMemberId,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    map['purpose_code'] = Variable<String>(purposeCode);
    map['target_minor_units'] = Variable<int>(targetMinorUnits);
    map['currency_code'] = Variable<String>(currencyCode);
    map['created_at'] = Variable<String>(createdAt);
    map['revision_reason'] = Variable<String>(revisionReason);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<String>(targetDate);
    }
    if (!nullToAbsent || beneficiaryMemberId != null) {
      map['beneficiary_member_id'] = Variable<String>(beneficiaryMemberId);
    }
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  GoalRevisionsTableCompanion toCompanion(bool nullToAbsent) {
    return GoalRevisionsTableCompanion(
      id: Value(id),
      goalId: Value(goalId),
      householdId: Value(householdId),
      name: Value(name),
      purposeCode: Value(purposeCode),
      targetMinorUnits: Value(targetMinorUnits),
      currencyCode: Value(currencyCode),
      createdAt: Value(createdAt),
      revisionReason: Value(revisionReason),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      beneficiaryMemberId: beneficiaryMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(beneficiaryMemberId),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory DbGoalRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbGoalRevision(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      purposeCode: serializer.fromJson<String>(json['purposeCode']),
      targetMinorUnits: serializer.fromJson<int>(json['targetMinorUnits']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      revisionReason: serializer.fromJson<String>(json['revisionReason']),
      targetDate: serializer.fromJson<String?>(json['targetDate']),
      beneficiaryMemberId: serializer.fromJson<String?>(
        json['beneficiaryMemberId'],
      ),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'purposeCode': serializer.toJson<String>(purposeCode),
      'targetMinorUnits': serializer.toJson<int>(targetMinorUnits),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'createdAt': serializer.toJson<String>(createdAt),
      'revisionReason': serializer.toJson<String>(revisionReason),
      'targetDate': serializer.toJson<String?>(targetDate),
      'beneficiaryMemberId': serializer.toJson<String?>(beneficiaryMemberId),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  DbGoalRevision copyWith({
    String? id,
    String? goalId,
    String? householdId,
    String? name,
    String? purposeCode,
    int? targetMinorUnits,
    String? currencyCode,
    String? createdAt,
    String? revisionReason,
    Value<String?> targetDate = const Value.absent(),
    Value<String?> beneficiaryMemberId = const Value.absent(),
    int? schemaVersion,
  }) => DbGoalRevision(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    householdId: householdId ?? this.householdId,
    name: name ?? this.name,
    purposeCode: purposeCode ?? this.purposeCode,
    targetMinorUnits: targetMinorUnits ?? this.targetMinorUnits,
    currencyCode: currencyCode ?? this.currencyCode,
    createdAt: createdAt ?? this.createdAt,
    revisionReason: revisionReason ?? this.revisionReason,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    beneficiaryMemberId: beneficiaryMemberId.present
        ? beneficiaryMemberId.value
        : this.beneficiaryMemberId,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  DbGoalRevision copyWithCompanion(GoalRevisionsTableCompanion data) {
    return DbGoalRevision(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      purposeCode: data.purposeCode.present
          ? data.purposeCode.value
          : this.purposeCode,
      targetMinorUnits: data.targetMinorUnits.present
          ? data.targetMinorUnits.value
          : this.targetMinorUnits,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      revisionReason: data.revisionReason.present
          ? data.revisionReason.value
          : this.revisionReason,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      beneficiaryMemberId: data.beneficiaryMemberId.present
          ? data.beneficiaryMemberId.value
          : this.beneficiaryMemberId,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbGoalRevision(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('purposeCode: $purposeCode, ')
          ..write('targetMinorUnits: $targetMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('revisionReason: $revisionReason, ')
          ..write('targetDate: $targetDate, ')
          ..write('beneficiaryMemberId: $beneficiaryMemberId, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    householdId,
    name,
    purposeCode,
    targetMinorUnits,
    currencyCode,
    createdAt,
    revisionReason,
    targetDate,
    beneficiaryMemberId,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbGoalRevision &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.purposeCode == this.purposeCode &&
          other.targetMinorUnits == this.targetMinorUnits &&
          other.currencyCode == this.currencyCode &&
          other.createdAt == this.createdAt &&
          other.revisionReason == this.revisionReason &&
          other.targetDate == this.targetDate &&
          other.beneficiaryMemberId == this.beneficiaryMemberId &&
          other.schemaVersion == this.schemaVersion);
}

class GoalRevisionsTableCompanion extends UpdateCompanion<DbGoalRevision> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String> purposeCode;
  final Value<int> targetMinorUnits;
  final Value<String> currencyCode;
  final Value<String> createdAt;
  final Value<String> revisionReason;
  final Value<String?> targetDate;
  final Value<String?> beneficiaryMemberId;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const GoalRevisionsTableCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.purposeCode = const Value.absent(),
    this.targetMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.revisionReason = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.beneficiaryMemberId = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalRevisionsTableCompanion.insert({
    required String id,
    required String goalId,
    required String householdId,
    required String name,
    required String purposeCode,
    required int targetMinorUnits,
    required String currencyCode,
    required String createdAt,
    required String revisionReason,
    this.targetDate = const Value.absent(),
    this.beneficiaryMemberId = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       householdId = Value(householdId),
       name = Value(name),
       purposeCode = Value(purposeCode),
       targetMinorUnits = Value(targetMinorUnits),
       currencyCode = Value(currencyCode),
       createdAt = Value(createdAt),
       revisionReason = Value(revisionReason);
  static Insertable<DbGoalRevision> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? purposeCode,
    Expression<int>? targetMinorUnits,
    Expression<String>? currencyCode,
    Expression<String>? createdAt,
    Expression<String>? revisionReason,
    Expression<String>? targetDate,
    Expression<String>? beneficiaryMemberId,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (purposeCode != null) 'purpose_code': purposeCode,
      if (targetMinorUnits != null) 'target_minor_units': targetMinorUnits,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (createdAt != null) 'created_at': createdAt,
      if (revisionReason != null) 'revision_reason': revisionReason,
      if (targetDate != null) 'target_date': targetDate,
      if (beneficiaryMemberId != null)
        'beneficiary_member_id': beneficiaryMemberId,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalRevisionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? householdId,
    Value<String>? name,
    Value<String>? purposeCode,
    Value<int>? targetMinorUnits,
    Value<String>? currencyCode,
    Value<String>? createdAt,
    Value<String>? revisionReason,
    Value<String?>? targetDate,
    Value<String?>? beneficiaryMemberId,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return GoalRevisionsTableCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      purposeCode: purposeCode ?? this.purposeCode,
      targetMinorUnits: targetMinorUnits ?? this.targetMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt ?? this.createdAt,
      revisionReason: revisionReason ?? this.revisionReason,
      targetDate: targetDate ?? this.targetDate,
      beneficiaryMemberId: beneficiaryMemberId ?? this.beneficiaryMemberId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (purposeCode.present) {
      map['purpose_code'] = Variable<String>(purposeCode.value);
    }
    if (targetMinorUnits.present) {
      map['target_minor_units'] = Variable<int>(targetMinorUnits.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (revisionReason.present) {
      map['revision_reason'] = Variable<String>(revisionReason.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (beneficiaryMemberId.present) {
      map['beneficiary_member_id'] = Variable<String>(
        beneficiaryMemberId.value,
      );
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalRevisionsTableCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('purposeCode: $purposeCode, ')
          ..write('targetMinorUnits: $targetMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('createdAt: $createdAt, ')
          ..write('revisionReason: $revisionReason, ')
          ..write('targetDate: $targetDate, ')
          ..write('beneficiaryMemberId: $beneficiaryMemberId, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalMovementsTableTable extends GoalMovementsTable
    with TableInfo<$GoalMovementsTableTable, DbGoalMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalMovementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferOperationIdMeta =
      const VerificationMeta('transferOperationId');
  @override
  late final GeneratedColumn<String> transferOperationId =
      GeneratedColumn<String>(
        'transfer_operation_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _movementTypeMeta = const VerificationMeta(
    'movementType',
  );
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
    'movement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _releaseReasonMeta = const VerificationMeta(
    'releaseReason',
  );
  @override
  late final GeneratedColumn<String> releaseReason = GeneratedColumn<String>(
    'release_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reversalOfMovementIdMeta =
      const VerificationMeta('reversalOfMovementId');
  @override
  late final GeneratedColumn<String> reversalOfMovementId =
      GeneratedColumn<String>(
        'reversal_of_movement_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    householdId,
    transferOperationId,
    movementType,
    createdAt,
    releaseReason,
    reversalOfMovementId,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbGoalMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('transfer_operation_id')) {
      context.handle(
        _transferOperationIdMeta,
        transferOperationId.isAcceptableOrUnknown(
          data['transfer_operation_id']!,
          _transferOperationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferOperationIdMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
        _movementTypeMeta,
        movementType.isAcceptableOrUnknown(
          data['movement_type']!,
          _movementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('release_reason')) {
      context.handle(
        _releaseReasonMeta,
        releaseReason.isAcceptableOrUnknown(
          data['release_reason']!,
          _releaseReasonMeta,
        ),
      );
    }
    if (data.containsKey('reversal_of_movement_id')) {
      context.handle(
        _reversalOfMovementIdMeta,
        reversalOfMovementId.isAcceptableOrUnknown(
          data['reversal_of_movement_id']!,
          _reversalOfMovementIdMeta,
        ),
      );
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbGoalMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbGoalMovement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      transferOperationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_operation_id'],
      )!,
      movementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}movement_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      releaseReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_reason'],
      ),
      reversalOfMovementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reversal_of_movement_id'],
      ),
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $GoalMovementsTableTable createAlias(String alias) {
    return $GoalMovementsTableTable(attachedDatabase, alias);
  }
}

class DbGoalMovement extends DataClass implements Insertable<DbGoalMovement> {
  final String id;
  final String goalId;
  final String householdId;

  /// References [operations.id] of the underlying ledger transfer or reversal.
  final String transferOperationId;

  /// 'funding', 'release', or 'reversal'.
  final String movementType;

  /// UTC ISO 8601 timestamp.
  final String createdAt;

  /// Required when movementType = 'release'.
  final String? releaseReason;

  /// When movementType = 'reversal', references the original movement being reversed.
  /// Added in schema v12 (Phase 5B.4).
  final String? reversalOfMovementId;
  final int schemaVersion;
  const DbGoalMovement({
    required this.id,
    required this.goalId,
    required this.householdId,
    required this.transferOperationId,
    required this.movementType,
    required this.createdAt,
    this.releaseReason,
    this.reversalOfMovementId,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['household_id'] = Variable<String>(householdId);
    map['transfer_operation_id'] = Variable<String>(transferOperationId);
    map['movement_type'] = Variable<String>(movementType);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || releaseReason != null) {
      map['release_reason'] = Variable<String>(releaseReason);
    }
    if (!nullToAbsent || reversalOfMovementId != null) {
      map['reversal_of_movement_id'] = Variable<String>(reversalOfMovementId);
    }
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  GoalMovementsTableCompanion toCompanion(bool nullToAbsent) {
    return GoalMovementsTableCompanion(
      id: Value(id),
      goalId: Value(goalId),
      householdId: Value(householdId),
      transferOperationId: Value(transferOperationId),
      movementType: Value(movementType),
      createdAt: Value(createdAt),
      releaseReason: releaseReason == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseReason),
      reversalOfMovementId: reversalOfMovementId == null && nullToAbsent
          ? const Value.absent()
          : Value(reversalOfMovementId),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory DbGoalMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbGoalMovement(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      householdId: serializer.fromJson<String>(json['householdId']),
      transferOperationId: serializer.fromJson<String>(
        json['transferOperationId'],
      ),
      movementType: serializer.fromJson<String>(json['movementType']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      releaseReason: serializer.fromJson<String?>(json['releaseReason']),
      reversalOfMovementId: serializer.fromJson<String?>(
        json['reversalOfMovementId'],
      ),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'householdId': serializer.toJson<String>(householdId),
      'transferOperationId': serializer.toJson<String>(transferOperationId),
      'movementType': serializer.toJson<String>(movementType),
      'createdAt': serializer.toJson<String>(createdAt),
      'releaseReason': serializer.toJson<String?>(releaseReason),
      'reversalOfMovementId': serializer.toJson<String?>(reversalOfMovementId),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  DbGoalMovement copyWith({
    String? id,
    String? goalId,
    String? householdId,
    String? transferOperationId,
    String? movementType,
    String? createdAt,
    Value<String?> releaseReason = const Value.absent(),
    Value<String?> reversalOfMovementId = const Value.absent(),
    int? schemaVersion,
  }) => DbGoalMovement(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    householdId: householdId ?? this.householdId,
    transferOperationId: transferOperationId ?? this.transferOperationId,
    movementType: movementType ?? this.movementType,
    createdAt: createdAt ?? this.createdAt,
    releaseReason: releaseReason.present
        ? releaseReason.value
        : this.releaseReason,
    reversalOfMovementId: reversalOfMovementId.present
        ? reversalOfMovementId.value
        : this.reversalOfMovementId,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  DbGoalMovement copyWithCompanion(GoalMovementsTableCompanion data) {
    return DbGoalMovement(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      transferOperationId: data.transferOperationId.present
          ? data.transferOperationId.value
          : this.transferOperationId,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      releaseReason: data.releaseReason.present
          ? data.releaseReason.value
          : this.releaseReason,
      reversalOfMovementId: data.reversalOfMovementId.present
          ? data.reversalOfMovementId.value
          : this.reversalOfMovementId,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbGoalMovement(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('householdId: $householdId, ')
          ..write('transferOperationId: $transferOperationId, ')
          ..write('movementType: $movementType, ')
          ..write('createdAt: $createdAt, ')
          ..write('releaseReason: $releaseReason, ')
          ..write('reversalOfMovementId: $reversalOfMovementId, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    householdId,
    transferOperationId,
    movementType,
    createdAt,
    releaseReason,
    reversalOfMovementId,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbGoalMovement &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.householdId == this.householdId &&
          other.transferOperationId == this.transferOperationId &&
          other.movementType == this.movementType &&
          other.createdAt == this.createdAt &&
          other.releaseReason == this.releaseReason &&
          other.reversalOfMovementId == this.reversalOfMovementId &&
          other.schemaVersion == this.schemaVersion);
}

class GoalMovementsTableCompanion extends UpdateCompanion<DbGoalMovement> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> householdId;
  final Value<String> transferOperationId;
  final Value<String> movementType;
  final Value<String> createdAt;
  final Value<String?> releaseReason;
  final Value<String?> reversalOfMovementId;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const GoalMovementsTableCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.transferOperationId = const Value.absent(),
    this.movementType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.releaseReason = const Value.absent(),
    this.reversalOfMovementId = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalMovementsTableCompanion.insert({
    required String id,
    required String goalId,
    required String householdId,
    required String transferOperationId,
    required String movementType,
    required String createdAt,
    this.releaseReason = const Value.absent(),
    this.reversalOfMovementId = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       householdId = Value(householdId),
       transferOperationId = Value(transferOperationId),
       movementType = Value(movementType),
       createdAt = Value(createdAt);
  static Insertable<DbGoalMovement> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? householdId,
    Expression<String>? transferOperationId,
    Expression<String>? movementType,
    Expression<String>? createdAt,
    Expression<String>? releaseReason,
    Expression<String>? reversalOfMovementId,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (householdId != null) 'household_id': householdId,
      if (transferOperationId != null)
        'transfer_operation_id': transferOperationId,
      if (movementType != null) 'movement_type': movementType,
      if (createdAt != null) 'created_at': createdAt,
      if (releaseReason != null) 'release_reason': releaseReason,
      if (reversalOfMovementId != null)
        'reversal_of_movement_id': reversalOfMovementId,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalMovementsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? householdId,
    Value<String>? transferOperationId,
    Value<String>? movementType,
    Value<String>? createdAt,
    Value<String?>? releaseReason,
    Value<String?>? reversalOfMovementId,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return GoalMovementsTableCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      householdId: householdId ?? this.householdId,
      transferOperationId: transferOperationId ?? this.transferOperationId,
      movementType: movementType ?? this.movementType,
      createdAt: createdAt ?? this.createdAt,
      releaseReason: releaseReason ?? this.releaseReason,
      reversalOfMovementId: reversalOfMovementId ?? this.reversalOfMovementId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (transferOperationId.present) {
      map['transfer_operation_id'] = Variable<String>(
        transferOperationId.value,
      );
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (releaseReason.present) {
      map['release_reason'] = Variable<String>(releaseReason.value);
    }
    if (reversalOfMovementId.present) {
      map['reversal_of_movement_id'] = Variable<String>(
        reversalOfMovementId.value,
      );
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalMovementsTableCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('householdId: $householdId, ')
          ..write('transferOperationId: $transferOperationId, ')
          ..write('movementType: $movementType, ')
          ..write('createdAt: $createdAt, ')
          ..write('releaseReason: $releaseReason, ')
          ..write('reversalOfMovementId: $reversalOfMovementId, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalLifecycleEventsTableTable extends GoalLifecycleEventsTable
    with TableInfo<$GoalLifecycleEventsTableTable, DbGoalLifecycleEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalLifecycleEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completionTypeMeta = const VerificationMeta(
    'completionType',
  );
  @override
  late final GeneratedColumn<String> completionType = GeneratedColumn<String>(
    'completion_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _earlyCompletionReasonMeta =
      const VerificationMeta('earlyCompletionReason');
  @override
  late final GeneratedColumn<String> earlyCompletionReason =
      GeneratedColumn<String>(
        'early_completion_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _earlyCompletionConfirmedMeta =
      const VerificationMeta('earlyCompletionConfirmed');
  @override
  late final GeneratedColumn<int> earlyCompletionConfirmed =
      GeneratedColumn<int>(
        'early_completion_confirmed',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorMetadataMeta = const VerificationMeta(
    'actorMetadata',
  );
  @override
  late final GeneratedColumn<String> actorMetadata = GeneratedColumn<String>(
    'actor_metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effectiveAtMeta = const VerificationMeta(
    'effectiveAt',
  );
  @override
  late final GeneratedColumn<String> effectiveAt = GeneratedColumn<String>(
    'effective_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(12),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    householdId,
    eventType,
    completionType,
    earlyCompletionReason,
    earlyCompletionConfirmed,
    idempotencyKey,
    actorMetadata,
    effectiveAt,
    createdAt,
    schemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_lifecycle_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbGoalLifecycleEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('completion_type')) {
      context.handle(
        _completionTypeMeta,
        completionType.isAcceptableOrUnknown(
          data['completion_type']!,
          _completionTypeMeta,
        ),
      );
    }
    if (data.containsKey('early_completion_reason')) {
      context.handle(
        _earlyCompletionReasonMeta,
        earlyCompletionReason.isAcceptableOrUnknown(
          data['early_completion_reason']!,
          _earlyCompletionReasonMeta,
        ),
      );
    }
    if (data.containsKey('early_completion_confirmed')) {
      context.handle(
        _earlyCompletionConfirmedMeta,
        earlyCompletionConfirmed.isAcceptableOrUnknown(
          data['early_completion_confirmed']!,
          _earlyCompletionConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('actor_metadata')) {
      context.handle(
        _actorMetadataMeta,
        actorMetadata.isAcceptableOrUnknown(
          data['actor_metadata']!,
          _actorMetadataMeta,
        ),
      );
    }
    if (data.containsKey('effective_at')) {
      context.handle(
        _effectiveAtMeta,
        effectiveAt.isAcceptableOrUnknown(
          data['effective_at']!,
          _effectiveAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbGoalLifecycleEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbGoalLifecycleEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      completionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_type'],
      ),
      earlyCompletionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}early_completion_reason'],
      ),
      earlyCompletionConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}early_completion_confirmed'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
      actorMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_metadata'],
      ),
      effectiveAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}effective_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
    );
  }

  @override
  $GoalLifecycleEventsTableTable createAlias(String alias) {
    return $GoalLifecycleEventsTableTable(attachedDatabase, alias);
  }
}

class DbGoalLifecycleEvent extends DataClass
    implements Insertable<DbGoalLifecycleEvent> {
  final String id;
  final String goalId;
  final String householdId;

  /// 'created', 'completed', 'archived', 'restored'.
  final String eventType;

  /// 'normal' or 'early' — only for completed events.
  final String? completionType;

  /// Non-empty when completionType = 'early'.
  final String? earlyCompletionReason;

  /// Must be 1 when completionType = 'early'.
  final int earlyCompletionConfirmed;

  /// Scoped idempotency key; UNIQUE across the table.
  final String? idempotencyKey;

  /// Arbitrary JSON actor metadata (user id, device, session).
  final String? actorMetadata;

  /// Business-effective timestamp (ISO 8601 UTC).
  final String effectiveAt;

  /// Row-creation timestamp (ISO 8601 UTC).
  final String createdAt;
  final int schemaVersion;
  const DbGoalLifecycleEvent({
    required this.id,
    required this.goalId,
    required this.householdId,
    required this.eventType,
    this.completionType,
    this.earlyCompletionReason,
    required this.earlyCompletionConfirmed,
    this.idempotencyKey,
    this.actorMetadata,
    required this.effectiveAt,
    required this.createdAt,
    required this.schemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['household_id'] = Variable<String>(householdId);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || completionType != null) {
      map['completion_type'] = Variable<String>(completionType);
    }
    if (!nullToAbsent || earlyCompletionReason != null) {
      map['early_completion_reason'] = Variable<String>(earlyCompletionReason);
    }
    map['early_completion_confirmed'] = Variable<int>(earlyCompletionConfirmed);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    if (!nullToAbsent || actorMetadata != null) {
      map['actor_metadata'] = Variable<String>(actorMetadata);
    }
    map['effective_at'] = Variable<String>(effectiveAt);
    map['created_at'] = Variable<String>(createdAt);
    map['schema_version'] = Variable<int>(schemaVersion);
    return map;
  }

  GoalLifecycleEventsTableCompanion toCompanion(bool nullToAbsent) {
    return GoalLifecycleEventsTableCompanion(
      id: Value(id),
      goalId: Value(goalId),
      householdId: Value(householdId),
      eventType: Value(eventType),
      completionType: completionType == null && nullToAbsent
          ? const Value.absent()
          : Value(completionType),
      earlyCompletionReason: earlyCompletionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(earlyCompletionReason),
      earlyCompletionConfirmed: Value(earlyCompletionConfirmed),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      actorMetadata: actorMetadata == null && nullToAbsent
          ? const Value.absent()
          : Value(actorMetadata),
      effectiveAt: Value(effectiveAt),
      createdAt: Value(createdAt),
      schemaVersion: Value(schemaVersion),
    );
  }

  factory DbGoalLifecycleEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbGoalLifecycleEvent(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      householdId: serializer.fromJson<String>(json['householdId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      completionType: serializer.fromJson<String?>(json['completionType']),
      earlyCompletionReason: serializer.fromJson<String?>(
        json['earlyCompletionReason'],
      ),
      earlyCompletionConfirmed: serializer.fromJson<int>(
        json['earlyCompletionConfirmed'],
      ),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      actorMetadata: serializer.fromJson<String?>(json['actorMetadata']),
      effectiveAt: serializer.fromJson<String>(json['effectiveAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'householdId': serializer.toJson<String>(householdId),
      'eventType': serializer.toJson<String>(eventType),
      'completionType': serializer.toJson<String?>(completionType),
      'earlyCompletionReason': serializer.toJson<String?>(
        earlyCompletionReason,
      ),
      'earlyCompletionConfirmed': serializer.toJson<int>(
        earlyCompletionConfirmed,
      ),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'actorMetadata': serializer.toJson<String?>(actorMetadata),
      'effectiveAt': serializer.toJson<String>(effectiveAt),
      'createdAt': serializer.toJson<String>(createdAt),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
    };
  }

  DbGoalLifecycleEvent copyWith({
    String? id,
    String? goalId,
    String? householdId,
    String? eventType,
    Value<String?> completionType = const Value.absent(),
    Value<String?> earlyCompletionReason = const Value.absent(),
    int? earlyCompletionConfirmed,
    Value<String?> idempotencyKey = const Value.absent(),
    Value<String?> actorMetadata = const Value.absent(),
    String? effectiveAt,
    String? createdAt,
    int? schemaVersion,
  }) => DbGoalLifecycleEvent(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    householdId: householdId ?? this.householdId,
    eventType: eventType ?? this.eventType,
    completionType: completionType.present
        ? completionType.value
        : this.completionType,
    earlyCompletionReason: earlyCompletionReason.present
        ? earlyCompletionReason.value
        : this.earlyCompletionReason,
    earlyCompletionConfirmed:
        earlyCompletionConfirmed ?? this.earlyCompletionConfirmed,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
    actorMetadata: actorMetadata.present
        ? actorMetadata.value
        : this.actorMetadata,
    effectiveAt: effectiveAt ?? this.effectiveAt,
    createdAt: createdAt ?? this.createdAt,
    schemaVersion: schemaVersion ?? this.schemaVersion,
  );
  DbGoalLifecycleEvent copyWithCompanion(
    GoalLifecycleEventsTableCompanion data,
  ) {
    return DbGoalLifecycleEvent(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      completionType: data.completionType.present
          ? data.completionType.value
          : this.completionType,
      earlyCompletionReason: data.earlyCompletionReason.present
          ? data.earlyCompletionReason.value
          : this.earlyCompletionReason,
      earlyCompletionConfirmed: data.earlyCompletionConfirmed.present
          ? data.earlyCompletionConfirmed.value
          : this.earlyCompletionConfirmed,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      actorMetadata: data.actorMetadata.present
          ? data.actorMetadata.value
          : this.actorMetadata,
      effectiveAt: data.effectiveAt.present
          ? data.effectiveAt.value
          : this.effectiveAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbGoalLifecycleEvent(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('householdId: $householdId, ')
          ..write('eventType: $eventType, ')
          ..write('completionType: $completionType, ')
          ..write('earlyCompletionReason: $earlyCompletionReason, ')
          ..write('earlyCompletionConfirmed: $earlyCompletionConfirmed, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('actorMetadata: $actorMetadata, ')
          ..write('effectiveAt: $effectiveAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('schemaVersion: $schemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    householdId,
    eventType,
    completionType,
    earlyCompletionReason,
    earlyCompletionConfirmed,
    idempotencyKey,
    actorMetadata,
    effectiveAt,
    createdAt,
    schemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbGoalLifecycleEvent &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.householdId == this.householdId &&
          other.eventType == this.eventType &&
          other.completionType == this.completionType &&
          other.earlyCompletionReason == this.earlyCompletionReason &&
          other.earlyCompletionConfirmed == this.earlyCompletionConfirmed &&
          other.idempotencyKey == this.idempotencyKey &&
          other.actorMetadata == this.actorMetadata &&
          other.effectiveAt == this.effectiveAt &&
          other.createdAt == this.createdAt &&
          other.schemaVersion == this.schemaVersion);
}

class GoalLifecycleEventsTableCompanion
    extends UpdateCompanion<DbGoalLifecycleEvent> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> householdId;
  final Value<String> eventType;
  final Value<String?> completionType;
  final Value<String?> earlyCompletionReason;
  final Value<int> earlyCompletionConfirmed;
  final Value<String?> idempotencyKey;
  final Value<String?> actorMetadata;
  final Value<String> effectiveAt;
  final Value<String> createdAt;
  final Value<int> schemaVersion;
  final Value<int> rowid;
  const GoalLifecycleEventsTableCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.householdId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.completionType = const Value.absent(),
    this.earlyCompletionReason = const Value.absent(),
    this.earlyCompletionConfirmed = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.actorMetadata = const Value.absent(),
    this.effectiveAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalLifecycleEventsTableCompanion.insert({
    required String id,
    required String goalId,
    required String householdId,
    required String eventType,
    this.completionType = const Value.absent(),
    this.earlyCompletionReason = const Value.absent(),
    this.earlyCompletionConfirmed = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.actorMetadata = const Value.absent(),
    required String effectiveAt,
    required String createdAt,
    this.schemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       householdId = Value(householdId),
       eventType = Value(eventType),
       effectiveAt = Value(effectiveAt),
       createdAt = Value(createdAt);
  static Insertable<DbGoalLifecycleEvent> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? householdId,
    Expression<String>? eventType,
    Expression<String>? completionType,
    Expression<String>? earlyCompletionReason,
    Expression<int>? earlyCompletionConfirmed,
    Expression<String>? idempotencyKey,
    Expression<String>? actorMetadata,
    Expression<String>? effectiveAt,
    Expression<String>? createdAt,
    Expression<int>? schemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (householdId != null) 'household_id': householdId,
      if (eventType != null) 'event_type': eventType,
      if (completionType != null) 'completion_type': completionType,
      if (earlyCompletionReason != null)
        'early_completion_reason': earlyCompletionReason,
      if (earlyCompletionConfirmed != null)
        'early_completion_confirmed': earlyCompletionConfirmed,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (actorMetadata != null) 'actor_metadata': actorMetadata,
      if (effectiveAt != null) 'effective_at': effectiveAt,
      if (createdAt != null) 'created_at': createdAt,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalLifecycleEventsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? householdId,
    Value<String>? eventType,
    Value<String?>? completionType,
    Value<String?>? earlyCompletionReason,
    Value<int>? earlyCompletionConfirmed,
    Value<String?>? idempotencyKey,
    Value<String?>? actorMetadata,
    Value<String>? effectiveAt,
    Value<String>? createdAt,
    Value<int>? schemaVersion,
    Value<int>? rowid,
  }) {
    return GoalLifecycleEventsTableCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      householdId: householdId ?? this.householdId,
      eventType: eventType ?? this.eventType,
      completionType: completionType ?? this.completionType,
      earlyCompletionReason:
          earlyCompletionReason ?? this.earlyCompletionReason,
      earlyCompletionConfirmed:
          earlyCompletionConfirmed ?? this.earlyCompletionConfirmed,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      actorMetadata: actorMetadata ?? this.actorMetadata,
      effectiveAt: effectiveAt ?? this.effectiveAt,
      createdAt: createdAt ?? this.createdAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (completionType.present) {
      map['completion_type'] = Variable<String>(completionType.value);
    }
    if (earlyCompletionReason.present) {
      map['early_completion_reason'] = Variable<String>(
        earlyCompletionReason.value,
      );
    }
    if (earlyCompletionConfirmed.present) {
      map['early_completion_confirmed'] = Variable<int>(
        earlyCompletionConfirmed.value,
      );
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (actorMetadata.present) {
      map['actor_metadata'] = Variable<String>(actorMetadata.value);
    }
    if (effectiveAt.present) {
      map['effective_at'] = Variable<String>(effectiveAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalLifecycleEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('householdId: $householdId, ')
          ..write('eventType: $eventType, ')
          ..write('completionType: $completionType, ')
          ..write('earlyCompletionReason: $earlyCompletionReason, ')
          ..write('earlyCompletionConfirmed: $earlyCompletionConfirmed, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('actorMetadata: $actorMetadata, ')
          ..write('effectiveAt: $effectiveAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HouseholdsTable households = $HouseholdsTable(this);
  late final $HouseholdMembersTable householdMembers = $HouseholdMembersTable(
    this,
  );
  late final $FinancialAccountsTable financialAccounts =
      $FinancialAccountsTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $OperationsTable operations = $OperationsTable(this);
  late final $ChildWithdrawalAuditsTable childWithdrawalAudits =
      $ChildWithdrawalAuditsTable(this);
  late final $OperationContextsTable operationContexts =
      $OperationContextsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $GoalsTableTable goalsTable = $GoalsTableTable(this);
  late final $GoalRevisionsTableTable goalRevisionsTable =
      $GoalRevisionsTableTable(this);
  late final $GoalMovementsTableTable goalMovementsTable =
      $GoalMovementsTableTable(this);
  late final $GoalLifecycleEventsTableTable goalLifecycleEventsTable =
      $GoalLifecycleEventsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    households,
    householdMembers,
    financialAccounts,
    ledgerEntries,
    operations,
    childWithdrawalAudits,
    operationContexts,
    budgets,
    goalsTable,
    goalRevisionsTable,
    goalMovementsTable,
    goalLifecycleEventsTable,
  ];
}

typedef $$HouseholdsTableCreateCompanionBuilder =
    HouseholdsCompanion Function({
      required String id,
      required String name,
      required String ownerUserId,
      Value<String> currencyCode,
      Value<String> primaryLanguage,
      Value<String> memberUserName,
      Value<String?> memberSpouseName,
      Value<String?> memberChildName,
      required String createdAt,
      required String updatedAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });
typedef $$HouseholdsTableUpdateCompanionBuilder =
    HouseholdsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> ownerUserId,
      Value<String> currencyCode,
      Value<String> primaryLanguage,
      Value<String> memberUserName,
      Value<String?> memberSpouseName,
      Value<String?> memberChildName,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$HouseholdsTableReferences
    extends BaseReferences<_$AppDatabase, $HouseholdsTable, DbHousehold> {
  $$HouseholdsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HouseholdMembersTable, List<DbHouseholdMember>>
  _householdMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.householdMembers,
    aliasName: 'households__id__household_members__household_id',
  );

  $$HouseholdMembersTableProcessedTableManager get householdMembersRefs {
    final manager = $$HouseholdMembersTableTableManager(
      $_db,
      $_db.householdMembers,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _householdMembersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FinancialAccountsTable, List<DbFinancialAccount>>
  _financialAccountsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.financialAccounts,
        aliasName: 'households__id__financial_accounts__household_id',
      );

  $$FinancialAccountsTableProcessedTableManager get financialAccountsRefs {
    final manager = $$FinancialAccountsTableTableManager(
      $_db,
      $_db.financialAccounts,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _financialAccountsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<DbLedgerEntry>>
  _ledgerEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'households__id__ledger_entries__household_id',
  );

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OperationsTable, List<DbOperation>>
  _operationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.operations,
    aliasName: 'households__id__operations__household_id',
  );

  $$OperationsTableProcessedTableManager get operationsRefs {
    final manager = $$OperationsTableTableManager(
      $_db,
      $_db.operations,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_operationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ChildWithdrawalAuditsTable,
    List<DbChildWithdrawalAudit>
  >
  _childWithdrawalAuditsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.childWithdrawalAudits,
        aliasName: 'households__id__child_withdrawal_audits__household_id',
      );

  $$ChildWithdrawalAuditsTableProcessedTableManager
  get childWithdrawalAuditsRefs {
    final manager = $$ChildWithdrawalAuditsTableTableManager(
      $_db,
      $_db.childWithdrawalAudits,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _childWithdrawalAuditsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<DbBudget>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: 'households__id__budgets__household_id',
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HouseholdsTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableFilterComposer({
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

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryLanguage => $composableBuilder(
    column: $table.primaryLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberUserName => $composableBuilder(
    column: $table.memberUserName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberSpouseName => $composableBuilder(
    column: $table.memberSpouseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberChildName => $composableBuilder(
    column: $table.memberChildName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> householdMembersRefs(
    Expression<bool> Function($$HouseholdMembersTableFilterComposer f) f,
  ) {
    final $$HouseholdMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.householdMembers,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdMembersTableFilterComposer(
            $db: $db,
            $table: $db.householdMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> financialAccountsRefs(
    Expression<bool> Function($$FinancialAccountsTableFilterComposer f) f,
  ) {
    final $$FinancialAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> operationsRefs(
    Expression<bool> Function($$OperationsTableFilterComposer f) f,
  ) {
    final $$OperationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableFilterComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> childWithdrawalAuditsRefs(
    Expression<bool> Function($$ChildWithdrawalAuditsTableFilterComposer f) f,
  ) {
    final $$ChildWithdrawalAuditsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.childWithdrawalAudits,
          getReferencedColumn: (t) => t.householdId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChildWithdrawalAuditsTableFilterComposer(
                $db: $db,
                $table: $db.childWithdrawalAudits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableOrderingComposer({
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

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryLanguage => $composableBuilder(
    column: $table.primaryLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberUserName => $composableBuilder(
    column: $table.memberUserName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberSpouseName => $composableBuilder(
    column: $table.memberSpouseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberChildName => $composableBuilder(
    column: $table.memberChildName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HouseholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableAnnotationComposer({
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

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get primaryLanguage => $composableBuilder(
    column: $table.primaryLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memberUserName => $composableBuilder(
    column: $table.memberUserName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memberSpouseName => $composableBuilder(
    column: $table.memberSpouseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memberChildName => $composableBuilder(
    column: $table.memberChildName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  Expression<T> householdMembersRefs<T extends Object>(
    Expression<T> Function($$HouseholdMembersTableAnnotationComposer a) f,
  ) {
    final $$HouseholdMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.householdMembers,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.householdMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> financialAccountsRefs<T extends Object>(
    Expression<T> Function($$FinancialAccountsTableAnnotationComposer a) f,
  ) {
    final $$FinancialAccountsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.financialAccounts,
          getReferencedColumn: (t) => t.householdId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialAccountsTableAnnotationComposer(
                $db: $db,
                $table: $db.financialAccounts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> operationsRefs<T extends Object>(
    Expression<T> Function($$OperationsTableAnnotationComposer a) f,
  ) {
    final $$OperationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableAnnotationComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> childWithdrawalAuditsRefs<T extends Object>(
    Expression<T> Function($$ChildWithdrawalAuditsTableAnnotationComposer a) f,
  ) {
    final $$ChildWithdrawalAuditsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.childWithdrawalAudits,
          getReferencedColumn: (t) => t.householdId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChildWithdrawalAuditsTableAnnotationComposer(
                $db: $db,
                $table: $db.childWithdrawalAudits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HouseholdsTable,
          DbHousehold,
          $$HouseholdsTableFilterComposer,
          $$HouseholdsTableOrderingComposer,
          $$HouseholdsTableAnnotationComposer,
          $$HouseholdsTableCreateCompanionBuilder,
          $$HouseholdsTableUpdateCompanionBuilder,
          (DbHousehold, $$HouseholdsTableReferences),
          DbHousehold,
          PrefetchHooks Function({
            bool householdMembersRefs,
            bool financialAccountsRefs,
            bool ledgerEntriesRefs,
            bool operationsRefs,
            bool childWithdrawalAuditsRefs,
            bool budgetsRefs,
          })
        > {
  $$HouseholdsTableTableManager(_$AppDatabase db, $HouseholdsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> ownerUserId = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> primaryLanguage = const Value.absent(),
                Value<String> memberUserName = const Value.absent(),
                Value<String?> memberSpouseName = const Value.absent(),
                Value<String?> memberChildName = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdsCompanion(
                id: id,
                name: name,
                ownerUserId: ownerUserId,
                currencyCode: currencyCode,
                primaryLanguage: primaryLanguage,
                memberUserName: memberUserName,
                memberSpouseName: memberSpouseName,
                memberChildName: memberChildName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String ownerUserId,
                Value<String> currencyCode = const Value.absent(),
                Value<String> primaryLanguage = const Value.absent(),
                Value<String> memberUserName = const Value.absent(),
                Value<String?> memberSpouseName = const Value.absent(),
                Value<String?> memberChildName = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdsCompanion.insert(
                id: id,
                name: name,
                ownerUserId: ownerUserId,
                currencyCode: currencyCode,
                primaryLanguage: primaryLanguage,
                memberUserName: memberUserName,
                memberSpouseName: memberSpouseName,
                memberChildName: memberChildName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HouseholdsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                householdMembersRefs = false,
                financialAccountsRefs = false,
                ledgerEntriesRefs = false,
                operationsRefs = false,
                childWithdrawalAuditsRefs = false,
                budgetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (householdMembersRefs) db.householdMembers,
                    if (financialAccountsRefs) db.financialAccounts,
                    if (ledgerEntriesRefs) db.ledgerEntries,
                    if (operationsRefs) db.operations,
                    if (childWithdrawalAuditsRefs) db.childWithdrawalAudits,
                    if (budgetsRefs) db.budgets,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (householdMembersRefs)
                        await $_getPrefetchedData<
                          DbHousehold,
                          $HouseholdsTable,
                          DbHouseholdMember
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._householdMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).householdMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (financialAccountsRefs)
                        await $_getPrefetchedData<
                          DbHousehold,
                          $HouseholdsTable,
                          DbFinancialAccount
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._financialAccountsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).financialAccountsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedData<
                          DbHousehold,
                          $HouseholdsTable,
                          DbLedgerEntry
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (operationsRefs)
                        await $_getPrefetchedData<
                          DbHousehold,
                          $HouseholdsTable,
                          DbOperation
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._operationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).operationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (childWithdrawalAuditsRefs)
                        await $_getPrefetchedData<
                          DbHousehold,
                          $HouseholdsTable,
                          DbChildWithdrawalAudit
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._childWithdrawalAuditsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).childWithdrawalAuditsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetsRefs)
                        await $_getPrefetchedData<
                          DbHousehold,
                          $HouseholdsTable,
                          DbBudget
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdsTableReferences
                              ._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdsTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.householdId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HouseholdsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HouseholdsTable,
      DbHousehold,
      $$HouseholdsTableFilterComposer,
      $$HouseholdsTableOrderingComposer,
      $$HouseholdsTableAnnotationComposer,
      $$HouseholdsTableCreateCompanionBuilder,
      $$HouseholdsTableUpdateCompanionBuilder,
      (DbHousehold, $$HouseholdsTableReferences),
      DbHousehold,
      PrefetchHooks Function({
        bool householdMembersRefs,
        bool financialAccountsRefs,
        bool ledgerEntriesRefs,
        bool operationsRefs,
        bool childWithdrawalAuditsRefs,
        bool budgetsRefs,
      })
    >;
typedef $$HouseholdMembersTableCreateCompanionBuilder =
    HouseholdMembersCompanion Function({
      required String id,
      required String householdId,
      required String displayName,
      required String role,
      Value<String> lifecycle,
      required String createdAt,
      required String updatedAt,
      Value<bool> isArchived,
      Value<int> rowid,
    });
typedef $$HouseholdMembersTableUpdateCompanionBuilder =
    HouseholdMembersCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> displayName,
      Value<String> role,
      Value<String> lifecycle,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<bool> isArchived,
      Value<int> rowid,
    });

final class $$HouseholdMembersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $HouseholdMembersTable,
          DbHouseholdMember
        > {
  $$HouseholdMembersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) => db.households
      .createAlias('household_members__household_id__households__id');

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HouseholdMembersTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lifecycle => $composableBuilder(
    column: $table.lifecycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HouseholdMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lifecycle => $composableBuilder(
    column: $table.lifecycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HouseholdMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get lifecycle =>
      $composableBuilder(column: $table.lifecycle, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HouseholdMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HouseholdMembersTable,
          DbHouseholdMember,
          $$HouseholdMembersTableFilterComposer,
          $$HouseholdMembersTableOrderingComposer,
          $$HouseholdMembersTableAnnotationComposer,
          $$HouseholdMembersTableCreateCompanionBuilder,
          $$HouseholdMembersTableUpdateCompanionBuilder,
          (DbHouseholdMember, $$HouseholdMembersTableReferences),
          DbHouseholdMember,
          PrefetchHooks Function({bool householdId})
        > {
  $$HouseholdMembersTableTableManager(
    _$AppDatabase db,
    $HouseholdMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> lifecycle = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdMembersCompanion(
                id: id,
                householdId: householdId,
                displayName: displayName,
                role: role,
                lifecycle: lifecycle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: isArchived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String displayName,
                required String role,
                Value<String> lifecycle = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<bool> isArchived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdMembersCompanion.insert(
                id: id,
                householdId: householdId,
                displayName: displayName,
                role: role,
                lifecycle: lifecycle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: isArchived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HouseholdMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({householdId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (householdId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.householdId,
                                referencedTable:
                                    $$HouseholdMembersTableReferences
                                        ._householdIdTable(db),
                                referencedColumn:
                                    $$HouseholdMembersTableReferences
                                        ._householdIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HouseholdMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HouseholdMembersTable,
      DbHouseholdMember,
      $$HouseholdMembersTableFilterComposer,
      $$HouseholdMembersTableOrderingComposer,
      $$HouseholdMembersTableAnnotationComposer,
      $$HouseholdMembersTableCreateCompanionBuilder,
      $$HouseholdMembersTableUpdateCompanionBuilder,
      (DbHouseholdMember, $$HouseholdMembersTableReferences),
      DbHouseholdMember,
      PrefetchHooks Function({bool householdId})
    >;
typedef $$FinancialAccountsTableCreateCompanionBuilder =
    FinancialAccountsCompanion Function({
      required String id,
      required String householdId,
      required String name,
      required String type,
      required String ownerType,
      Value<String> fundPurpose,
      Value<String> currencyCode,
      Value<bool> isSpendable,
      Value<bool> isProtected,
      Value<bool> includeInNetWorth,
      Value<bool> includeInZakat,
      Value<bool> isArchived,
      Value<String?> archivedAt,
      Value<String?> notes,
      Value<int> displayOrder,
      Value<String?> metadata,
      required String createdAt,
      required String updatedAt,
      required String createdBy,
      Value<String> syncStatus,
      Value<String?> idempotencyKey,
      Value<String?> idempotencyPayload,
      Value<int> rowid,
    });
typedef $$FinancialAccountsTableUpdateCompanionBuilder =
    FinancialAccountsCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> name,
      Value<String> type,
      Value<String> ownerType,
      Value<String> fundPurpose,
      Value<String> currencyCode,
      Value<bool> isSpendable,
      Value<bool> isProtected,
      Value<bool> includeInNetWorth,
      Value<bool> includeInZakat,
      Value<bool> isArchived,
      Value<String?> archivedAt,
      Value<String?> notes,
      Value<int> displayOrder,
      Value<String?> metadata,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String> createdBy,
      Value<String> syncStatus,
      Value<String?> idempotencyKey,
      Value<String?> idempotencyPayload,
      Value<int> rowid,
    });

final class $$FinancialAccountsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $FinancialAccountsTable,
          DbFinancialAccount
        > {
  $$FinancialAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) => db.households
      .createAlias('financial_accounts__household_id__households__id');

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LedgerEntriesTable, List<DbLedgerEntry>>
  _ledgerEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerEntries,
    aliasName: 'financial_accounts__id__ledger_entries__account_id',
  );

  $$LedgerEntriesTableProcessedTableManager get ledgerEntriesRefs {
    final manager = $$LedgerEntriesTableTableManager(
      $_db,
      $_db.ledgerEntries,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ledgerEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OperationsTable, List<DbOperation>>
  _sourceOperationsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.operations,
    aliasName: 'financial_accounts__id__operations__source_account_id',
  );

  $$OperationsTableProcessedTableManager get sourceOperations {
    final manager = $$OperationsTableTableManager($_db, $_db.operations).filter(
      (f) => f.sourceAccountId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_sourceOperationsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OperationsTable, List<DbOperation>>
  _destinationOperationsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.operations,
        aliasName: 'financial_accounts__id__operations__destination_account_id',
      );

  $$OperationsTableProcessedTableManager get destinationOperations {
    final manager = $$OperationsTableTableManager($_db, $_db.operations).filter(
      (f) => f.destinationAccountId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(
      _destinationOperationsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ChildWithdrawalAuditsTable,
    List<DbChildWithdrawalAudit>
  >
  _childWithdrawalAuditsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.childWithdrawalAudits,
        aliasName:
            'financial_accounts__id__child_withdrawal_audits__account_id',
      );

  $$ChildWithdrawalAuditsTableProcessedTableManager
  get childWithdrawalAuditsRefs {
    final manager = $$ChildWithdrawalAuditsTableTableManager(
      $_db,
      $_db.childWithdrawalAudits,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _childWithdrawalAuditsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GoalsTableTable, List<DbGoal>>
  _goalsTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.goalsTable,
    aliasName: 'financial_accounts__id__goals__reserve_account_id',
  );

  $$GoalsTableTableProcessedTableManager get goalsTableRefs {
    final manager = $$GoalsTableTableTableManager($_db, $_db.goalsTable).filter(
      (f) => f.reserveAccountId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_goalsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FinancialAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $FinancialAccountsTable> {
  $$FinancialAccountsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fundPurpose => $composableBuilder(
    column: $table.fundPurpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSpendable => $composableBuilder(
    column: $table.isSpendable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeInNetWorth => $composableBuilder(
    column: $table.includeInNetWorth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeInZakat => $composableBuilder(
    column: $table.includeInZakat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyPayload => $composableBuilder(
    column: $table.idempotencyPayload,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ledgerEntriesRefs(
    Expression<bool> Function($$LedgerEntriesTableFilterComposer f) f,
  ) {
    final $$LedgerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableFilterComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sourceOperations(
    Expression<bool> Function($$OperationsTableFilterComposer f) f,
  ) {
    final $$OperationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.sourceAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableFilterComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> destinationOperations(
    Expression<bool> Function($$OperationsTableFilterComposer f) f,
  ) {
    final $$OperationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.destinationAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableFilterComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> childWithdrawalAuditsRefs(
    Expression<bool> Function($$ChildWithdrawalAuditsTableFilterComposer f) f,
  ) {
    final $$ChildWithdrawalAuditsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.childWithdrawalAudits,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChildWithdrawalAuditsTableFilterComposer(
                $db: $db,
                $table: $db.childWithdrawalAudits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> goalsTableRefs(
    Expression<bool> Function($$GoalsTableTableFilterComposer f) f,
  ) {
    final $$GoalsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.reserveAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableFilterComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FinancialAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinancialAccountsTable> {
  $$FinancialAccountsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fundPurpose => $composableBuilder(
    column: $table.fundPurpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSpendable => $composableBuilder(
    column: $table.isSpendable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeInNetWorth => $composableBuilder(
    column: $table.includeInNetWorth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeInZakat => $composableBuilder(
    column: $table.includeInZakat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyPayload => $composableBuilder(
    column: $table.idempotencyPayload,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FinancialAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinancialAccountsTable> {
  $$FinancialAccountsTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get ownerType =>
      $composableBuilder(column: $table.ownerType, builder: (column) => column);

  GeneratedColumn<String> get fundPurpose => $composableBuilder(
    column: $table.fundPurpose,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSpendable => $composableBuilder(
    column: $table.isSpendable,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isProtected => $composableBuilder(
    column: $table.isProtected,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get includeInNetWorth => $composableBuilder(
    column: $table.includeInNetWorth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get includeInZakat => $composableBuilder(
    column: $table.includeInZakat,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyPayload => $composableBuilder(
    column: $table.idempotencyPayload,
    builder: (column) => column,
  );

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ledgerEntriesRefs<T extends Object>(
    Expression<T> Function($$LedgerEntriesTableAnnotationComposer a) f,
  ) {
    final $$LedgerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerEntries,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sourceOperations<T extends Object>(
    Expression<T> Function($$OperationsTableAnnotationComposer a) f,
  ) {
    final $$OperationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.sourceAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableAnnotationComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> destinationOperations<T extends Object>(
    Expression<T> Function($$OperationsTableAnnotationComposer a) f,
  ) {
    final $$OperationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.destinationAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableAnnotationComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> childWithdrawalAuditsRefs<T extends Object>(
    Expression<T> Function($$ChildWithdrawalAuditsTableAnnotationComposer a) f,
  ) {
    final $$ChildWithdrawalAuditsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.childWithdrawalAudits,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChildWithdrawalAuditsTableAnnotationComposer(
                $db: $db,
                $table: $db.childWithdrawalAudits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> goalsTableRefs<T extends Object>(
    Expression<T> Function($$GoalsTableTableAnnotationComposer a) f,
  ) {
    final $$GoalsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.reserveAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FinancialAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinancialAccountsTable,
          DbFinancialAccount,
          $$FinancialAccountsTableFilterComposer,
          $$FinancialAccountsTableOrderingComposer,
          $$FinancialAccountsTableAnnotationComposer,
          $$FinancialAccountsTableCreateCompanionBuilder,
          $$FinancialAccountsTableUpdateCompanionBuilder,
          (DbFinancialAccount, $$FinancialAccountsTableReferences),
          DbFinancialAccount,
          PrefetchHooks Function({
            bool householdId,
            bool ledgerEntriesRefs,
            bool sourceOperations,
            bool destinationOperations,
            bool childWithdrawalAuditsRefs,
            bool goalsTableRefs,
          })
        > {
  $$FinancialAccountsTableTableManager(
    _$AppDatabase db,
    $FinancialAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinancialAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FinancialAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FinancialAccountsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> ownerType = const Value.absent(),
                Value<String> fundPurpose = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<bool> isSpendable = const Value.absent(),
                Value<bool> isProtected = const Value.absent(),
                Value<bool> includeInNetWorth = const Value.absent(),
                Value<bool> includeInZakat = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> archivedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String?> idempotencyPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinancialAccountsCompanion(
                id: id,
                householdId: householdId,
                name: name,
                type: type,
                ownerType: ownerType,
                fundPurpose: fundPurpose,
                currencyCode: currencyCode,
                isSpendable: isSpendable,
                isProtected: isProtected,
                includeInNetWorth: includeInNetWorth,
                includeInZakat: includeInZakat,
                isArchived: isArchived,
                archivedAt: archivedAt,
                notes: notes,
                displayOrder: displayOrder,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                syncStatus: syncStatus,
                idempotencyKey: idempotencyKey,
                idempotencyPayload: idempotencyPayload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String name,
                required String type,
                required String ownerType,
                Value<String> fundPurpose = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<bool> isSpendable = const Value.absent(),
                Value<bool> isProtected = const Value.absent(),
                Value<bool> includeInNetWorth = const Value.absent(),
                Value<bool> includeInZakat = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> archivedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                required String createdBy,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String?> idempotencyPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinancialAccountsCompanion.insert(
                id: id,
                householdId: householdId,
                name: name,
                type: type,
                ownerType: ownerType,
                fundPurpose: fundPurpose,
                currencyCode: currencyCode,
                isSpendable: isSpendable,
                isProtected: isProtected,
                includeInNetWorth: includeInNetWorth,
                includeInZakat: includeInZakat,
                isArchived: isArchived,
                archivedAt: archivedAt,
                notes: notes,
                displayOrder: displayOrder,
                metadata: metadata,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                syncStatus: syncStatus,
                idempotencyKey: idempotencyKey,
                idempotencyPayload: idempotencyPayload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FinancialAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                householdId = false,
                ledgerEntriesRefs = false,
                sourceOperations = false,
                destinationOperations = false,
                childWithdrawalAuditsRefs = false,
                goalsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ledgerEntriesRefs) db.ledgerEntries,
                    if (sourceOperations) db.operations,
                    if (destinationOperations) db.operations,
                    if (childWithdrawalAuditsRefs) db.childWithdrawalAudits,
                    if (goalsTableRefs) db.goalsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (householdId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.householdId,
                                    referencedTable:
                                        $$FinancialAccountsTableReferences
                                            ._householdIdTable(db),
                                    referencedColumn:
                                        $$FinancialAccountsTableReferences
                                            ._householdIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ledgerEntriesRefs)
                        await $_getPrefetchedData<
                          DbFinancialAccount,
                          $FinancialAccountsTable,
                          DbLedgerEntry
                        >(
                          currentTable: table,
                          referencedTable: $$FinancialAccountsTableReferences
                              ._ledgerEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinancialAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sourceOperations)
                        await $_getPrefetchedData<
                          DbFinancialAccount,
                          $FinancialAccountsTable,
                          DbOperation
                        >(
                          currentTable: table,
                          referencedTable: $$FinancialAccountsTableReferences
                              ._sourceOperationsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinancialAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).sourceOperations,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (destinationOperations)
                        await $_getPrefetchedData<
                          DbFinancialAccount,
                          $FinancialAccountsTable,
                          DbOperation
                        >(
                          currentTable: table,
                          referencedTable: $$FinancialAccountsTableReferences
                              ._destinationOperationsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinancialAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).destinationOperations,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.destinationAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (childWithdrawalAuditsRefs)
                        await $_getPrefetchedData<
                          DbFinancialAccount,
                          $FinancialAccountsTable,
                          DbChildWithdrawalAudit
                        >(
                          currentTable: table,
                          referencedTable: $$FinancialAccountsTableReferences
                              ._childWithdrawalAuditsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinancialAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).childWithdrawalAuditsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (goalsTableRefs)
                        await $_getPrefetchedData<
                          DbFinancialAccount,
                          $FinancialAccountsTable,
                          DbGoal
                        >(
                          currentTable: table,
                          referencedTable: $$FinancialAccountsTableReferences
                              ._goalsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FinancialAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).goalsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.reserveAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FinancialAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinancialAccountsTable,
      DbFinancialAccount,
      $$FinancialAccountsTableFilterComposer,
      $$FinancialAccountsTableOrderingComposer,
      $$FinancialAccountsTableAnnotationComposer,
      $$FinancialAccountsTableCreateCompanionBuilder,
      $$FinancialAccountsTableUpdateCompanionBuilder,
      (DbFinancialAccount, $$FinancialAccountsTableReferences),
      DbFinancialAccount,
      PrefetchHooks Function({
        bool householdId,
        bool ledgerEntriesRefs,
        bool sourceOperations,
        bool destinationOperations,
        bool childWithdrawalAuditsRefs,
        bool goalsTableRefs,
      })
    >;
typedef $$LedgerEntriesTableCreateCompanionBuilder =
    LedgerEntriesCompanion Function({
      required String id,
      required String operationId,
      required String householdId,
      required String accountId,
      required String direction,
      required int amountMinorUnits,
      Value<String> currencyCode,
      required String entryType,
      required String effectiveDate,
      required String recordedAt,
      Value<String?> notes,
      required String createdBy,
      Value<bool> isReversal,
      Value<String?> reversalOfEntryId,
      Value<String> syncStatus,
      Value<String?> metadata,
      Value<int> rowid,
    });
typedef $$LedgerEntriesTableUpdateCompanionBuilder =
    LedgerEntriesCompanion Function({
      Value<String> id,
      Value<String> operationId,
      Value<String> householdId,
      Value<String> accountId,
      Value<String> direction,
      Value<int> amountMinorUnits,
      Value<String> currencyCode,
      Value<String> entryType,
      Value<String> effectiveDate,
      Value<String> recordedAt,
      Value<String?> notes,
      Value<String> createdBy,
      Value<bool> isReversal,
      Value<String?> reversalOfEntryId,
      Value<String> syncStatus,
      Value<String?> metadata,
      Value<int> rowid,
    });

final class $$LedgerEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LedgerEntriesTable, DbLedgerEntry> {
  $$LedgerEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias('ledger_entries__household_id__households__id');

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FinancialAccountsTable _accountIdTable(_$AppDatabase db) => db
      .financialAccounts
      .createAlias('ledger_entries__account_id__financial_accounts__id');

  $$FinancialAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$FinancialAccountsTableTableManager(
      $_db,
      $_db.financialAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
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

  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReversal => $composableBuilder(
    column: $table.isReversal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reversalOfEntryId => $composableBuilder(
    column: $table.reversalOfEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableFilterComposer get accountId {
    final $$FinancialAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryType => $composableBuilder(
    column: $table.entryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReversal => $composableBuilder(
    column: $table.isReversal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reversalOfEntryId => $composableBuilder(
    column: $table.reversalOfEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableOrderingComposer get accountId {
    final $$FinancialAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<String> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<bool> get isReversal => $composableBuilder(
    column: $table.isReversal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reversalOfEntryId => $composableBuilder(
    column: $table.reversalOfEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableAnnotationComposer get accountId {
    final $$FinancialAccountsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.financialAccounts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialAccountsTableAnnotationComposer(
                $db: $db,
                $table: $db.financialAccounts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$LedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerEntriesTable,
          DbLedgerEntry,
          $$LedgerEntriesTableFilterComposer,
          $$LedgerEntriesTableOrderingComposer,
          $$LedgerEntriesTableAnnotationComposer,
          $$LedgerEntriesTableCreateCompanionBuilder,
          $$LedgerEntriesTableUpdateCompanionBuilder,
          (DbLedgerEntry, $$LedgerEntriesTableReferences),
          DbLedgerEntry,
          PrefetchHooks Function({bool householdId, bool accountId})
        > {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> entryType = const Value.absent(),
                Value<String> effectiveDate = const Value.absent(),
                Value<String> recordedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<bool> isReversal = const Value.absent(),
                Value<String?> reversalOfEntryId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion(
                id: id,
                operationId: operationId,
                householdId: householdId,
                accountId: accountId,
                direction: direction,
                amountMinorUnits: amountMinorUnits,
                currencyCode: currencyCode,
                entryType: entryType,
                effectiveDate: effectiveDate,
                recordedAt: recordedAt,
                notes: notes,
                createdBy: createdBy,
                isReversal: isReversal,
                reversalOfEntryId: reversalOfEntryId,
                syncStatus: syncStatus,
                metadata: metadata,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String operationId,
                required String householdId,
                required String accountId,
                required String direction,
                required int amountMinorUnits,
                Value<String> currencyCode = const Value.absent(),
                required String entryType,
                required String effectiveDate,
                required String recordedAt,
                Value<String?> notes = const Value.absent(),
                required String createdBy,
                Value<bool> isReversal = const Value.absent(),
                Value<String?> reversalOfEntryId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerEntriesCompanion.insert(
                id: id,
                operationId: operationId,
                householdId: householdId,
                accountId: accountId,
                direction: direction,
                amountMinorUnits: amountMinorUnits,
                currencyCode: currencyCode,
                entryType: entryType,
                effectiveDate: effectiveDate,
                recordedAt: recordedAt,
                notes: notes,
                createdBy: createdBy,
                isReversal: isReversal,
                reversalOfEntryId: reversalOfEntryId,
                syncStatus: syncStatus,
                metadata: metadata,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LedgerEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({householdId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (householdId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.householdId,
                                referencedTable: $$LedgerEntriesTableReferences
                                    ._householdIdTable(db),
                                referencedColumn: $$LedgerEntriesTableReferences
                                    ._householdIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$LedgerEntriesTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$LedgerEntriesTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerEntriesTable,
      DbLedgerEntry,
      $$LedgerEntriesTableFilterComposer,
      $$LedgerEntriesTableOrderingComposer,
      $$LedgerEntriesTableAnnotationComposer,
      $$LedgerEntriesTableCreateCompanionBuilder,
      $$LedgerEntriesTableUpdateCompanionBuilder,
      (DbLedgerEntry, $$LedgerEntriesTableReferences),
      DbLedgerEntry,
      PrefetchHooks Function({bool householdId, bool accountId})
    >;
typedef $$OperationsTableCreateCompanionBuilder =
    OperationsCompanion Function({
      required String id,
      Value<String?> idempotencyKey,
      required String householdId,
      required String type,
      required String effectiveDate,
      required String recordedAt,
      Value<String?> description,
      Value<String?> categoryCode,
      Value<String?> scope,
      Value<String?> spenderRole,
      Value<String?> beneficiaryRole,
      Value<String?> sourceAccountId,
      Value<String?> destinationAccountId,
      required int totalAmountMinorUnits,
      Value<String> currencyCode,
      Value<bool> isRecurring,
      Value<String?> recurringRuleId,
      Value<String?> tags,
      Value<String?> receiptPath,
      Value<bool> isReversed,
      Value<String?> reversedBy,
      required String createdBy,
      required String createdAt,
      required String updatedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$OperationsTableUpdateCompanionBuilder =
    OperationsCompanion Function({
      Value<String> id,
      Value<String?> idempotencyKey,
      Value<String> householdId,
      Value<String> type,
      Value<String> effectiveDate,
      Value<String> recordedAt,
      Value<String?> description,
      Value<String?> categoryCode,
      Value<String?> scope,
      Value<String?> spenderRole,
      Value<String?> beneficiaryRole,
      Value<String?> sourceAccountId,
      Value<String?> destinationAccountId,
      Value<int> totalAmountMinorUnits,
      Value<String> currencyCode,
      Value<bool> isRecurring,
      Value<String?> recurringRuleId,
      Value<String?> tags,
      Value<String?> receiptPath,
      Value<bool> isReversed,
      Value<String?> reversedBy,
      Value<String> createdBy,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$OperationsTableReferences
    extends BaseReferences<_$AppDatabase, $OperationsTable, DbOperation> {
  $$OperationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias('operations__household_id__households__id');

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FinancialAccountsTable _sourceAccountIdTable(_$AppDatabase db) => db
      .financialAccounts
      .createAlias('operations__source_account_id__financial_accounts__id');

  $$FinancialAccountsTableProcessedTableManager? get sourceAccountId {
    final $_column = $_itemColumn<String>('source_account_id');
    if ($_column == null) return null;
    final manager = $$FinancialAccountsTableTableManager(
      $_db,
      $_db.financialAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FinancialAccountsTable _destinationAccountIdTable(_$AppDatabase db) =>
      db.financialAccounts.createAlias(
        'operations__destination_account_id__financial_accounts__id',
      );

  $$FinancialAccountsTableProcessedTableManager? get destinationAccountId {
    final $_column = $_itemColumn<String>('destination_account_id');
    if ($_column == null) return null;
    final manager = $$FinancialAccountsTableTableManager(
      $_db,
      $_db.financialAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _destinationAccountIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ChildWithdrawalAuditsTable,
    List<DbChildWithdrawalAudit>
  >
  _childWithdrawalAuditsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.childWithdrawalAudits,
        aliasName: 'operations__id__child_withdrawal_audits__operation_id',
      );

  $$ChildWithdrawalAuditsTableProcessedTableManager
  get childWithdrawalAuditsRefs {
    final manager = $$ChildWithdrawalAuditsTableTableManager(
      $_db,
      $_db.childWithdrawalAudits,
    ).filter((f) => f.operationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _childWithdrawalAuditsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OperationsTableFilterComposer
    extends Composer<_$AppDatabase, $OperationsTable> {
  $$OperationsTableFilterComposer({
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

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spenderRole => $composableBuilder(
    column: $table.spenderRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beneficiaryRole => $composableBuilder(
    column: $table.beneficiaryRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalAmountMinorUnits => $composableBuilder(
    column: $table.totalAmountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurringRuleId => $composableBuilder(
    column: $table.recurringRuleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptPath => $composableBuilder(
    column: $table.receiptPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReversed => $composableBuilder(
    column: $table.isReversed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reversedBy => $composableBuilder(
    column: $table.reversedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableFilterComposer get sourceAccountId {
    final $$FinancialAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceAccountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableFilterComposer get destinationAccountId {
    final $$FinancialAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationAccountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> childWithdrawalAuditsRefs(
    Expression<bool> Function($$ChildWithdrawalAuditsTableFilterComposer f) f,
  ) {
    final $$ChildWithdrawalAuditsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.childWithdrawalAudits,
          getReferencedColumn: (t) => t.operationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChildWithdrawalAuditsTableFilterComposer(
                $db: $db,
                $table: $db.childWithdrawalAudits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$OperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $OperationsTable> {
  $$OperationsTableOrderingComposer({
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

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spenderRole => $composableBuilder(
    column: $table.spenderRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beneficiaryRole => $composableBuilder(
    column: $table.beneficiaryRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalAmountMinorUnits => $composableBuilder(
    column: $table.totalAmountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurringRuleId => $composableBuilder(
    column: $table.recurringRuleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptPath => $composableBuilder(
    column: $table.receiptPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReversed => $composableBuilder(
    column: $table.isReversed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reversedBy => $composableBuilder(
    column: $table.reversedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableOrderingComposer get sourceAccountId {
    final $$FinancialAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceAccountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableOrderingComposer get destinationAccountId {
    final $$FinancialAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.destinationAccountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OperationsTable> {
  $$OperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get effectiveDate => $composableBuilder(
    column: $table.effectiveDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get spenderRole => $composableBuilder(
    column: $table.spenderRole,
    builder: (column) => column,
  );

  GeneratedColumn<String> get beneficiaryRole => $composableBuilder(
    column: $table.beneficiaryRole,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalAmountMinorUnits => $composableBuilder(
    column: $table.totalAmountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurringRuleId => $composableBuilder(
    column: $table.recurringRuleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get receiptPath => $composableBuilder(
    column: $table.receiptPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isReversed => $composableBuilder(
    column: $table.isReversed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reversedBy => $composableBuilder(
    column: $table.reversedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableAnnotationComposer get sourceAccountId {
    final $$FinancialAccountsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sourceAccountId,
          referencedTable: $db.financialAccounts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialAccountsTableAnnotationComposer(
                $db: $db,
                $table: $db.financialAccounts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$FinancialAccountsTableAnnotationComposer get destinationAccountId {
    final $$FinancialAccountsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.destinationAccountId,
          referencedTable: $db.financialAccounts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialAccountsTableAnnotationComposer(
                $db: $db,
                $table: $db.financialAccounts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> childWithdrawalAuditsRefs<T extends Object>(
    Expression<T> Function($$ChildWithdrawalAuditsTableAnnotationComposer a) f,
  ) {
    final $$ChildWithdrawalAuditsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.childWithdrawalAudits,
          getReferencedColumn: (t) => t.operationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChildWithdrawalAuditsTableAnnotationComposer(
                $db: $db,
                $table: $db.childWithdrawalAudits,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$OperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OperationsTable,
          DbOperation,
          $$OperationsTableFilterComposer,
          $$OperationsTableOrderingComposer,
          $$OperationsTableAnnotationComposer,
          $$OperationsTableCreateCompanionBuilder,
          $$OperationsTableUpdateCompanionBuilder,
          (DbOperation, $$OperationsTableReferences),
          DbOperation,
          PrefetchHooks Function({
            bool householdId,
            bool sourceAccountId,
            bool destinationAccountId,
            bool childWithdrawalAuditsRefs,
          })
        > {
  $$OperationsTableTableManager(_$AppDatabase db, $OperationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> effectiveDate = const Value.absent(),
                Value<String> recordedAt = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> categoryCode = const Value.absent(),
                Value<String?> scope = const Value.absent(),
                Value<String?> spenderRole = const Value.absent(),
                Value<String?> beneficiaryRole = const Value.absent(),
                Value<String?> sourceAccountId = const Value.absent(),
                Value<String?> destinationAccountId = const Value.absent(),
                Value<int> totalAmountMinorUnits = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<String?> recurringRuleId = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> receiptPath = const Value.absent(),
                Value<bool> isReversed = const Value.absent(),
                Value<String?> reversedBy = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperationsCompanion(
                id: id,
                idempotencyKey: idempotencyKey,
                householdId: householdId,
                type: type,
                effectiveDate: effectiveDate,
                recordedAt: recordedAt,
                description: description,
                categoryCode: categoryCode,
                scope: scope,
                spenderRole: spenderRole,
                beneficiaryRole: beneficiaryRole,
                sourceAccountId: sourceAccountId,
                destinationAccountId: destinationAccountId,
                totalAmountMinorUnits: totalAmountMinorUnits,
                currencyCode: currencyCode,
                isRecurring: isRecurring,
                recurringRuleId: recurringRuleId,
                tags: tags,
                receiptPath: receiptPath,
                isReversed: isReversed,
                reversedBy: reversedBy,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> idempotencyKey = const Value.absent(),
                required String householdId,
                required String type,
                required String effectiveDate,
                required String recordedAt,
                Value<String?> description = const Value.absent(),
                Value<String?> categoryCode = const Value.absent(),
                Value<String?> scope = const Value.absent(),
                Value<String?> spenderRole = const Value.absent(),
                Value<String?> beneficiaryRole = const Value.absent(),
                Value<String?> sourceAccountId = const Value.absent(),
                Value<String?> destinationAccountId = const Value.absent(),
                required int totalAmountMinorUnits,
                Value<String> currencyCode = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<String?> recurringRuleId = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> receiptPath = const Value.absent(),
                Value<bool> isReversed = const Value.absent(),
                Value<String?> reversedBy = const Value.absent(),
                required String createdBy,
                required String createdAt,
                required String updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperationsCompanion.insert(
                id: id,
                idempotencyKey: idempotencyKey,
                householdId: householdId,
                type: type,
                effectiveDate: effectiveDate,
                recordedAt: recordedAt,
                description: description,
                categoryCode: categoryCode,
                scope: scope,
                spenderRole: spenderRole,
                beneficiaryRole: beneficiaryRole,
                sourceAccountId: sourceAccountId,
                destinationAccountId: destinationAccountId,
                totalAmountMinorUnits: totalAmountMinorUnits,
                currencyCode: currencyCode,
                isRecurring: isRecurring,
                recurringRuleId: recurringRuleId,
                tags: tags,
                receiptPath: receiptPath,
                isReversed: isReversed,
                reversedBy: reversedBy,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OperationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                householdId = false,
                sourceAccountId = false,
                destinationAccountId = false,
                childWithdrawalAuditsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (childWithdrawalAuditsRefs) db.childWithdrawalAudits,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (householdId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.householdId,
                                    referencedTable: $$OperationsTableReferences
                                        ._householdIdTable(db),
                                    referencedColumn:
                                        $$OperationsTableReferences
                                            ._householdIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (sourceAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.sourceAccountId,
                                    referencedTable: $$OperationsTableReferences
                                        ._sourceAccountIdTable(db),
                                    referencedColumn:
                                        $$OperationsTableReferences
                                            ._sourceAccountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (destinationAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.destinationAccountId,
                                    referencedTable: $$OperationsTableReferences
                                        ._destinationAccountIdTable(db),
                                    referencedColumn:
                                        $$OperationsTableReferences
                                            ._destinationAccountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (childWithdrawalAuditsRefs)
                        await $_getPrefetchedData<
                          DbOperation,
                          $OperationsTable,
                          DbChildWithdrawalAudit
                        >(
                          currentTable: table,
                          referencedTable: $$OperationsTableReferences
                              ._childWithdrawalAuditsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OperationsTableReferences(
                                db,
                                table,
                                p0,
                              ).childWithdrawalAuditsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.operationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$OperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OperationsTable,
      DbOperation,
      $$OperationsTableFilterComposer,
      $$OperationsTableOrderingComposer,
      $$OperationsTableAnnotationComposer,
      $$OperationsTableCreateCompanionBuilder,
      $$OperationsTableUpdateCompanionBuilder,
      (DbOperation, $$OperationsTableReferences),
      DbOperation,
      PrefetchHooks Function({
        bool householdId,
        bool sourceAccountId,
        bool destinationAccountId,
        bool childWithdrawalAuditsRefs,
      })
    >;
typedef $$ChildWithdrawalAuditsTableCreateCompanionBuilder =
    ChildWithdrawalAuditsCompanion Function({
      required String id,
      required String operationId,
      required String householdId,
      required String accountId,
      required int amountMinorUnits,
      required String reason,
      required String beneficiary,
      required String confirmedAt,
      required String confirmedBy,
      Value<bool> warningShown,
      Value<bool> biometricConfirmed,
      required String createdAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$ChildWithdrawalAuditsTableUpdateCompanionBuilder =
    ChildWithdrawalAuditsCompanion Function({
      Value<String> id,
      Value<String> operationId,
      Value<String> householdId,
      Value<String> accountId,
      Value<int> amountMinorUnits,
      Value<String> reason,
      Value<String> beneficiary,
      Value<String> confirmedAt,
      Value<String> confirmedBy,
      Value<bool> warningShown,
      Value<bool> biometricConfirmed,
      Value<String> createdAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$ChildWithdrawalAuditsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ChildWithdrawalAuditsTable,
          DbChildWithdrawalAudit
        > {
  $$ChildWithdrawalAuditsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OperationsTable _operationIdTable(_$AppDatabase db) => db.operations
      .createAlias('child_withdrawal_audits__operation_id__operations__id');

  $$OperationsTableProcessedTableManager get operationId {
    final $_column = $_itemColumn<String>('operation_id')!;

    final manager = $$OperationsTableTableManager(
      $_db,
      $_db.operations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_operationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) => db.households
      .createAlias('child_withdrawal_audits__household_id__households__id');

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FinancialAccountsTable _accountIdTable(_$AppDatabase db) =>
      db.financialAccounts.createAlias(
        'child_withdrawal_audits__account_id__financial_accounts__id',
      );

  $$FinancialAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$FinancialAccountsTableTableManager(
      $_db,
      $_db.financialAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChildWithdrawalAuditsTableFilterComposer
    extends Composer<_$AppDatabase, $ChildWithdrawalAuditsTable> {
  $$ChildWithdrawalAuditsTableFilterComposer({
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

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beneficiary => $composableBuilder(
    column: $table.beneficiary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmedBy => $composableBuilder(
    column: $table.confirmedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get warningShown => $composableBuilder(
    column: $table.warningShown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get biometricConfirmed => $composableBuilder(
    column: $table.biometricConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$OperationsTableFilterComposer get operationId {
    final $$OperationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationId,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableFilterComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableFilterComposer get accountId {
    final $$FinancialAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChildWithdrawalAuditsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildWithdrawalAuditsTable> {
  $$ChildWithdrawalAuditsTableOrderingComposer({
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

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beneficiary => $composableBuilder(
    column: $table.beneficiary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmedBy => $composableBuilder(
    column: $table.confirmedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get warningShown => $composableBuilder(
    column: $table.warningShown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get biometricConfirmed => $composableBuilder(
    column: $table.biometricConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$OperationsTableOrderingComposer get operationId {
    final $$OperationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationId,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableOrderingComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableOrderingComposer get accountId {
    final $$FinancialAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChildWithdrawalAuditsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildWithdrawalAuditsTable> {
  $$ChildWithdrawalAuditsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get beneficiary => $composableBuilder(
    column: $table.beneficiary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get confirmedBy => $composableBuilder(
    column: $table.confirmedBy,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get warningShown => $composableBuilder(
    column: $table.warningShown,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get biometricConfirmed => $composableBuilder(
    column: $table.biometricConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$OperationsTableAnnotationComposer get operationId {
    final $$OperationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operationId,
      referencedTable: $db.operations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperationsTableAnnotationComposer(
            $db: $db,
            $table: $db.operations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FinancialAccountsTableAnnotationComposer get accountId {
    final $$FinancialAccountsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.financialAccounts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialAccountsTableAnnotationComposer(
                $db: $db,
                $table: $db.financialAccounts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ChildWithdrawalAuditsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildWithdrawalAuditsTable,
          DbChildWithdrawalAudit,
          $$ChildWithdrawalAuditsTableFilterComposer,
          $$ChildWithdrawalAuditsTableOrderingComposer,
          $$ChildWithdrawalAuditsTableAnnotationComposer,
          $$ChildWithdrawalAuditsTableCreateCompanionBuilder,
          $$ChildWithdrawalAuditsTableUpdateCompanionBuilder,
          (DbChildWithdrawalAudit, $$ChildWithdrawalAuditsTableReferences),
          DbChildWithdrawalAudit,
          PrefetchHooks Function({
            bool operationId,
            bool householdId,
            bool accountId,
          })
        > {
  $$ChildWithdrawalAuditsTableTableManager(
    _$AppDatabase db,
    $ChildWithdrawalAuditsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildWithdrawalAuditsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ChildWithdrawalAuditsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ChildWithdrawalAuditsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> operationId = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> beneficiary = const Value.absent(),
                Value<String> confirmedAt = const Value.absent(),
                Value<String> confirmedBy = const Value.absent(),
                Value<bool> warningShown = const Value.absent(),
                Value<bool> biometricConfirmed = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildWithdrawalAuditsCompanion(
                id: id,
                operationId: operationId,
                householdId: householdId,
                accountId: accountId,
                amountMinorUnits: amountMinorUnits,
                reason: reason,
                beneficiary: beneficiary,
                confirmedAt: confirmedAt,
                confirmedBy: confirmedBy,
                warningShown: warningShown,
                biometricConfirmed: biometricConfirmed,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String operationId,
                required String householdId,
                required String accountId,
                required int amountMinorUnits,
                required String reason,
                required String beneficiary,
                required String confirmedAt,
                required String confirmedBy,
                Value<bool> warningShown = const Value.absent(),
                Value<bool> biometricConfirmed = const Value.absent(),
                required String createdAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildWithdrawalAuditsCompanion.insert(
                id: id,
                operationId: operationId,
                householdId: householdId,
                accountId: accountId,
                amountMinorUnits: amountMinorUnits,
                reason: reason,
                beneficiary: beneficiary,
                confirmedAt: confirmedAt,
                confirmedBy: confirmedBy,
                warningShown: warningShown,
                biometricConfirmed: biometricConfirmed,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChildWithdrawalAuditsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({operationId = false, householdId = false, accountId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (operationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.operationId,
                                    referencedTable:
                                        $$ChildWithdrawalAuditsTableReferences
                                            ._operationIdTable(db),
                                    referencedColumn:
                                        $$ChildWithdrawalAuditsTableReferences
                                            ._operationIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (householdId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.householdId,
                                    referencedTable:
                                        $$ChildWithdrawalAuditsTableReferences
                                            ._householdIdTable(db),
                                    referencedColumn:
                                        $$ChildWithdrawalAuditsTableReferences
                                            ._householdIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable:
                                        $$ChildWithdrawalAuditsTableReferences
                                            ._accountIdTable(db),
                                    referencedColumn:
                                        $$ChildWithdrawalAuditsTableReferences
                                            ._accountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ChildWithdrawalAuditsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildWithdrawalAuditsTable,
      DbChildWithdrawalAudit,
      $$ChildWithdrawalAuditsTableFilterComposer,
      $$ChildWithdrawalAuditsTableOrderingComposer,
      $$ChildWithdrawalAuditsTableAnnotationComposer,
      $$ChildWithdrawalAuditsTableCreateCompanionBuilder,
      $$ChildWithdrawalAuditsTableUpdateCompanionBuilder,
      (DbChildWithdrawalAudit, $$ChildWithdrawalAuditsTableReferences),
      DbChildWithdrawalAudit,
      PrefetchHooks Function({
        bool operationId,
        bool householdId,
        bool accountId,
      })
    >;
typedef $$OperationContextsTableCreateCompanionBuilder =
    OperationContextsCompanion Function({
      required String operationId,
      required String householdId,
      Value<String?> spenderMemberId,
      Value<String?> beneficiaryMemberId,
      Value<String?> expenseScope,
      Value<bool> isRecurring,
      Value<String?> recurringNote,
      Value<String?> categoryCode,
      Value<String?> note,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$OperationContextsTableUpdateCompanionBuilder =
    OperationContextsCompanion Function({
      Value<String> operationId,
      Value<String> householdId,
      Value<String?> spenderMemberId,
      Value<String?> beneficiaryMemberId,
      Value<String?> expenseScope,
      Value<bool> isRecurring,
      Value<String?> recurringNote,
      Value<String?> categoryCode,
      Value<String?> note,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$OperationContextsTableFilterComposer
    extends Composer<_$AppDatabase, $OperationContextsTable> {
  $$OperationContextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get spenderMemberId => $composableBuilder(
    column: $table.spenderMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beneficiaryMemberId => $composableBuilder(
    column: $table.beneficiaryMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expenseScope => $composableBuilder(
    column: $table.expenseScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurringNote => $composableBuilder(
    column: $table.recurringNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OperationContextsTableOrderingComposer
    extends Composer<_$AppDatabase, $OperationContextsTable> {
  $$OperationContextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spenderMemberId => $composableBuilder(
    column: $table.spenderMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beneficiaryMemberId => $composableBuilder(
    column: $table.beneficiaryMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expenseScope => $composableBuilder(
    column: $table.expenseScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurringNote => $composableBuilder(
    column: $table.recurringNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OperationContextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OperationContextsTable> {
  $$OperationContextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get spenderMemberId => $composableBuilder(
    column: $table.spenderMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get beneficiaryMemberId => $composableBuilder(
    column: $table.beneficiaryMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expenseScope => $composableBuilder(
    column: $table.expenseScope,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurringNote => $composableBuilder(
    column: $table.recurringNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OperationContextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OperationContextsTable,
          DbOperationContext,
          $$OperationContextsTableFilterComposer,
          $$OperationContextsTableOrderingComposer,
          $$OperationContextsTableAnnotationComposer,
          $$OperationContextsTableCreateCompanionBuilder,
          $$OperationContextsTableUpdateCompanionBuilder,
          (
            DbOperationContext,
            BaseReferences<
              _$AppDatabase,
              $OperationContextsTable,
              DbOperationContext
            >,
          ),
          DbOperationContext,
          PrefetchHooks Function()
        > {
  $$OperationContextsTableTableManager(
    _$AppDatabase db,
    $OperationContextsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperationContextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperationContextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperationContextsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String?> spenderMemberId = const Value.absent(),
                Value<String?> beneficiaryMemberId = const Value.absent(),
                Value<String?> expenseScope = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<String?> recurringNote = const Value.absent(),
                Value<String?> categoryCode = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperationContextsCompanion(
                operationId: operationId,
                householdId: householdId,
                spenderMemberId: spenderMemberId,
                beneficiaryMemberId: beneficiaryMemberId,
                expenseScope: expenseScope,
                isRecurring: isRecurring,
                recurringNote: recurringNote,
                categoryCode: categoryCode,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String householdId,
                Value<String?> spenderMemberId = const Value.absent(),
                Value<String?> beneficiaryMemberId = const Value.absent(),
                Value<String?> expenseScope = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<String?> recurringNote = const Value.absent(),
                Value<String?> categoryCode = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => OperationContextsCompanion.insert(
                operationId: operationId,
                householdId: householdId,
                spenderMemberId: spenderMemberId,
                beneficiaryMemberId: beneficiaryMemberId,
                expenseScope: expenseScope,
                isRecurring: isRecurring,
                recurringNote: recurringNote,
                categoryCode: categoryCode,
                note: note,
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

typedef $$OperationContextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OperationContextsTable,
      DbOperationContext,
      $$OperationContextsTableFilterComposer,
      $$OperationContextsTableOrderingComposer,
      $$OperationContextsTableAnnotationComposer,
      $$OperationContextsTableCreateCompanionBuilder,
      $$OperationContextsTableUpdateCompanionBuilder,
      (
        DbOperationContext,
        BaseReferences<
          _$AppDatabase,
          $OperationContextsTable,
          DbOperationContext
        >,
      ),
      DbOperationContext,
      PrefetchHooks Function()
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      required String id,
      required String householdId,
      required String name,
      required String currencyCode,
      required int limitMinorUnits,
      required String periodType,
      Value<String?> fixedStartDate,
      Value<String?> fixedEndDate,
      Value<String?> filterCategoryCode,
      Value<String?> filterScopeCode,
      Value<String?> filterSpenderMemberId,
      Value<String?> filterBeneficiaryMemberId,
      Value<String?> filterPaymentAccountId,
      Value<int> isArchived,
      required String idempotencyKey,
      required String idempotencyPayload,
      required String createdAt,
      required String updatedAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> name,
      Value<String> currencyCode,
      Value<int> limitMinorUnits,
      Value<String> periodType,
      Value<String?> fixedStartDate,
      Value<String?> fixedEndDate,
      Value<String?> filterCategoryCode,
      Value<String?> filterScopeCode,
      Value<String?> filterSpenderMemberId,
      Value<String?> filterBeneficiaryMemberId,
      Value<String?> filterPaymentAccountId,
      Value<int> isArchived,
      Value<String> idempotencyKey,
      Value<String> idempotencyPayload,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, DbBudget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias('budgets__household_id__households__id');

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
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

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitMinorUnits => $composableBuilder(
    column: $table.limitMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedStartDate => $composableBuilder(
    column: $table.fixedStartDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedEndDate => $composableBuilder(
    column: $table.fixedEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterCategoryCode => $composableBuilder(
    column: $table.filterCategoryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterScopeCode => $composableBuilder(
    column: $table.filterScopeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterSpenderMemberId => $composableBuilder(
    column: $table.filterSpenderMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterBeneficiaryMemberId => $composableBuilder(
    column: $table.filterBeneficiaryMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterPaymentAccountId => $composableBuilder(
    column: $table.filterPaymentAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyPayload => $composableBuilder(
    column: $table.idempotencyPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
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

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitMinorUnits => $composableBuilder(
    column: $table.limitMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedStartDate => $composableBuilder(
    column: $table.fixedStartDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedEndDate => $composableBuilder(
    column: $table.fixedEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterCategoryCode => $composableBuilder(
    column: $table.filterCategoryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterScopeCode => $composableBuilder(
    column: $table.filterScopeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterSpenderMemberId => $composableBuilder(
    column: $table.filterSpenderMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterBeneficiaryMemberId => $composableBuilder(
    column: $table.filterBeneficiaryMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterPaymentAccountId => $composableBuilder(
    column: $table.filterPaymentAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyPayload => $composableBuilder(
    column: $table.idempotencyPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
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

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get limitMinorUnits => $composableBuilder(
    column: $table.limitMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedStartDate => $composableBuilder(
    column: $table.fixedStartDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedEndDate => $composableBuilder(
    column: $table.fixedEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filterCategoryCode => $composableBuilder(
    column: $table.filterCategoryCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filterScopeCode => $composableBuilder(
    column: $table.filterScopeCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filterSpenderMemberId => $composableBuilder(
    column: $table.filterSpenderMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filterBeneficiaryMemberId => $composableBuilder(
    column: $table.filterBeneficiaryMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filterPaymentAccountId => $composableBuilder(
    column: $table.filterPaymentAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyPayload => $composableBuilder(
    column: $table.idempotencyPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          DbBudget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (DbBudget, $$BudgetsTableReferences),
          DbBudget,
          PrefetchHooks Function({bool householdId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> limitMinorUnits = const Value.absent(),
                Value<String> periodType = const Value.absent(),
                Value<String?> fixedStartDate = const Value.absent(),
                Value<String?> fixedEndDate = const Value.absent(),
                Value<String?> filterCategoryCode = const Value.absent(),
                Value<String?> filterScopeCode = const Value.absent(),
                Value<String?> filterSpenderMemberId = const Value.absent(),
                Value<String?> filterBeneficiaryMemberId = const Value.absent(),
                Value<String?> filterPaymentAccountId = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> idempotencyPayload = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                householdId: householdId,
                name: name,
                currencyCode: currencyCode,
                limitMinorUnits: limitMinorUnits,
                periodType: periodType,
                fixedStartDate: fixedStartDate,
                fixedEndDate: fixedEndDate,
                filterCategoryCode: filterCategoryCode,
                filterScopeCode: filterScopeCode,
                filterSpenderMemberId: filterSpenderMemberId,
                filterBeneficiaryMemberId: filterBeneficiaryMemberId,
                filterPaymentAccountId: filterPaymentAccountId,
                isArchived: isArchived,
                idempotencyKey: idempotencyKey,
                idempotencyPayload: idempotencyPayload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String name,
                required String currencyCode,
                required int limitMinorUnits,
                required String periodType,
                Value<String?> fixedStartDate = const Value.absent(),
                Value<String?> fixedEndDate = const Value.absent(),
                Value<String?> filterCategoryCode = const Value.absent(),
                Value<String?> filterScopeCode = const Value.absent(),
                Value<String?> filterSpenderMemberId = const Value.absent(),
                Value<String?> filterBeneficiaryMemberId = const Value.absent(),
                Value<String?> filterPaymentAccountId = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                required String idempotencyKey,
                required String idempotencyPayload,
                required String createdAt,
                required String updatedAt,
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                householdId: householdId,
                name: name,
                currencyCode: currencyCode,
                limitMinorUnits: limitMinorUnits,
                periodType: periodType,
                fixedStartDate: fixedStartDate,
                fixedEndDate: fixedEndDate,
                filterCategoryCode: filterCategoryCode,
                filterScopeCode: filterScopeCode,
                filterSpenderMemberId: filterSpenderMemberId,
                filterBeneficiaryMemberId: filterBeneficiaryMemberId,
                filterPaymentAccountId: filterPaymentAccountId,
                isArchived: isArchived,
                idempotencyKey: idempotencyKey,
                idempotencyPayload: idempotencyPayload,
                createdAt: createdAt,
                updatedAt: updatedAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({householdId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (householdId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.householdId,
                                referencedTable: $$BudgetsTableReferences
                                    ._householdIdTable(db),
                                referencedColumn: $$BudgetsTableReferences
                                    ._householdIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      DbBudget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (DbBudget, $$BudgetsTableReferences),
      DbBudget,
      PrefetchHooks Function({bool householdId})
    >;
typedef $$GoalsTableTableCreateCompanionBuilder =
    GoalsTableCompanion Function({
      required String id,
      required String householdId,
      required String reserveAccountId,
      required String currencyCode,
      required String status,
      required String idempotencyKey,
      required String idempotencyPayload,
      required String createdAt,
      Value<String?> completedAt,
      Value<String?> archivedAt,
      Value<String?> earlyCompletionReason,
      Value<int> schemaVersion,
      Value<int> rowid,
    });
typedef $$GoalsTableTableUpdateCompanionBuilder =
    GoalsTableCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> reserveAccountId,
      Value<String> currencyCode,
      Value<String> status,
      Value<String> idempotencyKey,
      Value<String> idempotencyPayload,
      Value<String> createdAt,
      Value<String?> completedAt,
      Value<String?> archivedAt,
      Value<String?> earlyCompletionReason,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$GoalsTableTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTableTable, DbGoal> {
  $$GoalsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FinancialAccountsTable _reserveAccountIdTable(_$AppDatabase db) => db
      .financialAccounts
      .createAlias('goals__reserve_account_id__financial_accounts__id');

  $$FinancialAccountsTableProcessedTableManager get reserveAccountId {
    final $_column = $_itemColumn<String>('reserve_account_id')!;

    final manager = $$FinancialAccountsTableTableManager(
      $_db,
      $_db.financialAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reserveAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GoalRevisionsTableTable, List<DbGoalRevision>>
  _goalRevisionsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.goalRevisionsTable,
        aliasName: 'goals__id__goal_revisions__goal_id',
      );

  $$GoalRevisionsTableTableProcessedTableManager get goalRevisionsTableRefs {
    final manager = $$GoalRevisionsTableTableTableManager(
      $_db,
      $_db.goalRevisionsTable,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _goalRevisionsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GoalMovementsTableTable, List<DbGoalMovement>>
  _goalMovementsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.goalMovementsTable,
        aliasName: 'goals__id__goal_movements__goal_id',
      );

  $$GoalMovementsTableTableProcessedTableManager get goalMovementsTableRefs {
    final manager = $$GoalMovementsTableTableTableManager(
      $_db,
      $_db.goalMovementsTable,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _goalMovementsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $GoalLifecycleEventsTableTable,
    List<DbGoalLifecycleEvent>
  >
  _goalLifecycleEventsTableRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.goalLifecycleEventsTable,
        aliasName: 'goals__id__goal_lifecycle_events__goal_id',
      );

  $$GoalLifecycleEventsTableTableProcessedTableManager
  get goalLifecycleEventsTableRefs {
    final manager = $$GoalLifecycleEventsTableTableTableManager(
      $_db,
      $_db.goalLifecycleEventsTable,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _goalLifecycleEventsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GoalsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GoalsTableTable> {
  $$GoalsTableTableFilterComposer({
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

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyPayload => $composableBuilder(
    column: $table.idempotencyPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get earlyCompletionReason => $composableBuilder(
    column: $table.earlyCompletionReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$FinancialAccountsTableFilterComposer get reserveAccountId {
    final $$FinancialAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reserveAccountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableFilterComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> goalRevisionsTableRefs(
    Expression<bool> Function($$GoalRevisionsTableTableFilterComposer f) f,
  ) {
    final $$GoalRevisionsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalRevisionsTable,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalRevisionsTableTableFilterComposer(
            $db: $db,
            $table: $db.goalRevisionsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> goalMovementsTableRefs(
    Expression<bool> Function($$GoalMovementsTableTableFilterComposer f) f,
  ) {
    final $$GoalMovementsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalMovementsTable,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalMovementsTableTableFilterComposer(
            $db: $db,
            $table: $db.goalMovementsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> goalLifecycleEventsTableRefs(
    Expression<bool> Function($$GoalLifecycleEventsTableTableFilterComposer f)
    f,
  ) {
    final $$GoalLifecycleEventsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.goalLifecycleEventsTable,
          getReferencedColumn: (t) => t.goalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GoalLifecycleEventsTableTableFilterComposer(
                $db: $db,
                $table: $db.goalLifecycleEventsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GoalsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTableTable> {
  $$GoalsTableTableOrderingComposer({
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

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyPayload => $composableBuilder(
    column: $table.idempotencyPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get earlyCompletionReason => $composableBuilder(
    column: $table.earlyCompletionReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$FinancialAccountsTableOrderingComposer get reserveAccountId {
    final $$FinancialAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reserveAccountId,
      referencedTable: $db.financialAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FinancialAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.financialAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTableTable> {
  $$GoalsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyPayload => $composableBuilder(
    column: $table.idempotencyPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get earlyCompletionReason => $composableBuilder(
    column: $table.earlyCompletionReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$FinancialAccountsTableAnnotationComposer get reserveAccountId {
    final $$FinancialAccountsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.reserveAccountId,
          referencedTable: $db.financialAccounts,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FinancialAccountsTableAnnotationComposer(
                $db: $db,
                $table: $db.financialAccounts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> goalRevisionsTableRefs<T extends Object>(
    Expression<T> Function($$GoalRevisionsTableTableAnnotationComposer a) f,
  ) {
    final $$GoalRevisionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.goalRevisionsTable,
          getReferencedColumn: (t) => t.goalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GoalRevisionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.goalRevisionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> goalMovementsTableRefs<T extends Object>(
    Expression<T> Function($$GoalMovementsTableTableAnnotationComposer a) f,
  ) {
    final $$GoalMovementsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.goalMovementsTable,
          getReferencedColumn: (t) => t.goalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GoalMovementsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.goalMovementsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> goalLifecycleEventsTableRefs<T extends Object>(
    Expression<T> Function($$GoalLifecycleEventsTableTableAnnotationComposer a)
    f,
  ) {
    final $$GoalLifecycleEventsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.goalLifecycleEventsTable,
          getReferencedColumn: (t) => t.goalId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GoalLifecycleEventsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.goalLifecycleEventsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GoalsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTableTable,
          DbGoal,
          $$GoalsTableTableFilterComposer,
          $$GoalsTableTableOrderingComposer,
          $$GoalsTableTableAnnotationComposer,
          $$GoalsTableTableCreateCompanionBuilder,
          $$GoalsTableTableUpdateCompanionBuilder,
          (DbGoal, $$GoalsTableTableReferences),
          DbGoal,
          PrefetchHooks Function({
            bool reserveAccountId,
            bool goalRevisionsTableRefs,
            bool goalMovementsTableRefs,
            bool goalLifecycleEventsTableRefs,
          })
        > {
  $$GoalsTableTableTableManager(_$AppDatabase db, $GoalsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> reserveAccountId = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> idempotencyPayload = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<String?> archivedAt = const Value.absent(),
                Value<String?> earlyCompletionReason = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsTableCompanion(
                id: id,
                householdId: householdId,
                reserveAccountId: reserveAccountId,
                currencyCode: currencyCode,
                status: status,
                idempotencyKey: idempotencyKey,
                idempotencyPayload: idempotencyPayload,
                createdAt: createdAt,
                completedAt: completedAt,
                archivedAt: archivedAt,
                earlyCompletionReason: earlyCompletionReason,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String reserveAccountId,
                required String currencyCode,
                required String status,
                required String idempotencyKey,
                required String idempotencyPayload,
                required String createdAt,
                Value<String?> completedAt = const Value.absent(),
                Value<String?> archivedAt = const Value.absent(),
                Value<String?> earlyCompletionReason = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsTableCompanion.insert(
                id: id,
                householdId: householdId,
                reserveAccountId: reserveAccountId,
                currencyCode: currencyCode,
                status: status,
                idempotencyKey: idempotencyKey,
                idempotencyPayload: idempotencyPayload,
                createdAt: createdAt,
                completedAt: completedAt,
                archivedAt: archivedAt,
                earlyCompletionReason: earlyCompletionReason,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GoalsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                reserveAccountId = false,
                goalRevisionsTableRefs = false,
                goalMovementsTableRefs = false,
                goalLifecycleEventsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (goalRevisionsTableRefs) db.goalRevisionsTable,
                    if (goalMovementsTableRefs) db.goalMovementsTable,
                    if (goalLifecycleEventsTableRefs)
                      db.goalLifecycleEventsTable,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (reserveAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.reserveAccountId,
                                    referencedTable: $$GoalsTableTableReferences
                                        ._reserveAccountIdTable(db),
                                    referencedColumn:
                                        $$GoalsTableTableReferences
                                            ._reserveAccountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (goalRevisionsTableRefs)
                        await $_getPrefetchedData<
                          DbGoal,
                          $GoalsTableTable,
                          DbGoalRevision
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableTableReferences
                              ._goalRevisionsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).goalRevisionsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (goalMovementsTableRefs)
                        await $_getPrefetchedData<
                          DbGoal,
                          $GoalsTableTable,
                          DbGoalMovement
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableTableReferences
                              ._goalMovementsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).goalMovementsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (goalLifecycleEventsTableRefs)
                        await $_getPrefetchedData<
                          DbGoal,
                          $GoalsTableTable,
                          DbGoalLifecycleEvent
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableTableReferences
                              ._goalLifecycleEventsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).goalLifecycleEventsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GoalsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTableTable,
      DbGoal,
      $$GoalsTableTableFilterComposer,
      $$GoalsTableTableOrderingComposer,
      $$GoalsTableTableAnnotationComposer,
      $$GoalsTableTableCreateCompanionBuilder,
      $$GoalsTableTableUpdateCompanionBuilder,
      (DbGoal, $$GoalsTableTableReferences),
      DbGoal,
      PrefetchHooks Function({
        bool reserveAccountId,
        bool goalRevisionsTableRefs,
        bool goalMovementsTableRefs,
        bool goalLifecycleEventsTableRefs,
      })
    >;
typedef $$GoalRevisionsTableTableCreateCompanionBuilder =
    GoalRevisionsTableCompanion Function({
      required String id,
      required String goalId,
      required String householdId,
      required String name,
      required String purposeCode,
      required int targetMinorUnits,
      required String currencyCode,
      required String createdAt,
      required String revisionReason,
      Value<String?> targetDate,
      Value<String?> beneficiaryMemberId,
      Value<int> schemaVersion,
      Value<int> rowid,
    });
typedef $$GoalRevisionsTableTableUpdateCompanionBuilder =
    GoalRevisionsTableCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<String> householdId,
      Value<String> name,
      Value<String> purposeCode,
      Value<int> targetMinorUnits,
      Value<String> currencyCode,
      Value<String> createdAt,
      Value<String> revisionReason,
      Value<String?> targetDate,
      Value<String?> beneficiaryMemberId,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$GoalRevisionsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GoalRevisionsTableTable,
          DbGoalRevision
        > {
  $$GoalRevisionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GoalsTableTable _goalIdTable(_$AppDatabase db) =>
      db.goalsTable.createAlias('goal_revisions__goal_id__goals__id');

  $$GoalsTableTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableTableManager(
      $_db,
      $_db.goalsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalRevisionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GoalRevisionsTableTable> {
  $$GoalRevisionsTableTableFilterComposer({
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

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purposeCode => $composableBuilder(
    column: $table.purposeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetMinorUnits => $composableBuilder(
    column: $table.targetMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionReason => $composableBuilder(
    column: $table.revisionReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beneficiaryMemberId => $composableBuilder(
    column: $table.beneficiaryMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$GoalsTableTableFilterComposer get goalId {
    final $$GoalsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableFilterComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalRevisionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalRevisionsTableTable> {
  $$GoalRevisionsTableTableOrderingComposer({
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

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purposeCode => $composableBuilder(
    column: $table.purposeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetMinorUnits => $composableBuilder(
    column: $table.targetMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionReason => $composableBuilder(
    column: $table.revisionReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beneficiaryMemberId => $composableBuilder(
    column: $table.beneficiaryMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableTableOrderingComposer get goalId {
    final $$GoalsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableOrderingComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalRevisionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalRevisionsTableTable> {
  $$GoalRevisionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get purposeCode => $composableBuilder(
    column: $table.purposeCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetMinorUnits => $composableBuilder(
    column: $table.targetMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get revisionReason => $composableBuilder(
    column: $table.revisionReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get beneficiaryMemberId => $composableBuilder(
    column: $table.beneficiaryMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$GoalsTableTableAnnotationComposer get goalId {
    final $$GoalsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalRevisionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalRevisionsTableTable,
          DbGoalRevision,
          $$GoalRevisionsTableTableFilterComposer,
          $$GoalRevisionsTableTableOrderingComposer,
          $$GoalRevisionsTableTableAnnotationComposer,
          $$GoalRevisionsTableTableCreateCompanionBuilder,
          $$GoalRevisionsTableTableUpdateCompanionBuilder,
          (DbGoalRevision, $$GoalRevisionsTableTableReferences),
          DbGoalRevision,
          PrefetchHooks Function({bool goalId})
        > {
  $$GoalRevisionsTableTableTableManager(
    _$AppDatabase db,
    $GoalRevisionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalRevisionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalRevisionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalRevisionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> purposeCode = const Value.absent(),
                Value<int> targetMinorUnits = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> revisionReason = const Value.absent(),
                Value<String?> targetDate = const Value.absent(),
                Value<String?> beneficiaryMemberId = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalRevisionsTableCompanion(
                id: id,
                goalId: goalId,
                householdId: householdId,
                name: name,
                purposeCode: purposeCode,
                targetMinorUnits: targetMinorUnits,
                currencyCode: currencyCode,
                createdAt: createdAt,
                revisionReason: revisionReason,
                targetDate: targetDate,
                beneficiaryMemberId: beneficiaryMemberId,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String householdId,
                required String name,
                required String purposeCode,
                required int targetMinorUnits,
                required String currencyCode,
                required String createdAt,
                required String revisionReason,
                Value<String?> targetDate = const Value.absent(),
                Value<String?> beneficiaryMemberId = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalRevisionsTableCompanion.insert(
                id: id,
                goalId: goalId,
                householdId: householdId,
                name: name,
                purposeCode: purposeCode,
                targetMinorUnits: targetMinorUnits,
                currencyCode: currencyCode,
                createdAt: createdAt,
                revisionReason: revisionReason,
                targetDate: targetDate,
                beneficiaryMemberId: beneficiaryMemberId,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GoalRevisionsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (goalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.goalId,
                                referencedTable:
                                    $$GoalRevisionsTableTableReferences
                                        ._goalIdTable(db),
                                referencedColumn:
                                    $$GoalRevisionsTableTableReferences
                                        ._goalIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GoalRevisionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalRevisionsTableTable,
      DbGoalRevision,
      $$GoalRevisionsTableTableFilterComposer,
      $$GoalRevisionsTableTableOrderingComposer,
      $$GoalRevisionsTableTableAnnotationComposer,
      $$GoalRevisionsTableTableCreateCompanionBuilder,
      $$GoalRevisionsTableTableUpdateCompanionBuilder,
      (DbGoalRevision, $$GoalRevisionsTableTableReferences),
      DbGoalRevision,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$GoalMovementsTableTableCreateCompanionBuilder =
    GoalMovementsTableCompanion Function({
      required String id,
      required String goalId,
      required String householdId,
      required String transferOperationId,
      required String movementType,
      required String createdAt,
      Value<String?> releaseReason,
      Value<String?> reversalOfMovementId,
      Value<int> schemaVersion,
      Value<int> rowid,
    });
typedef $$GoalMovementsTableTableUpdateCompanionBuilder =
    GoalMovementsTableCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<String> householdId,
      Value<String> transferOperationId,
      Value<String> movementType,
      Value<String> createdAt,
      Value<String?> releaseReason,
      Value<String?> reversalOfMovementId,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$GoalMovementsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GoalMovementsTableTable,
          DbGoalMovement
        > {
  $$GoalMovementsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GoalsTableTable _goalIdTable(_$AppDatabase db) =>
      db.goalsTable.createAlias('goal_movements__goal_id__goals__id');

  $$GoalsTableTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableTableManager(
      $_db,
      $_db.goalsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalMovementsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GoalMovementsTableTable> {
  $$GoalMovementsTableTableFilterComposer({
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

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferOperationId => $composableBuilder(
    column: $table.transferOperationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseReason => $composableBuilder(
    column: $table.releaseReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reversalOfMovementId => $composableBuilder(
    column: $table.reversalOfMovementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$GoalsTableTableFilterComposer get goalId {
    final $$GoalsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableFilterComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalMovementsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalMovementsTableTable> {
  $$GoalMovementsTableTableOrderingComposer({
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

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferOperationId => $composableBuilder(
    column: $table.transferOperationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseReason => $composableBuilder(
    column: $table.releaseReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reversalOfMovementId => $composableBuilder(
    column: $table.reversalOfMovementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableTableOrderingComposer get goalId {
    final $$GoalsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableOrderingComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalMovementsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalMovementsTableTable> {
  $$GoalMovementsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transferOperationId => $composableBuilder(
    column: $table.transferOperationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get movementType => $composableBuilder(
    column: $table.movementType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get releaseReason => $composableBuilder(
    column: $table.releaseReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reversalOfMovementId => $composableBuilder(
    column: $table.reversalOfMovementId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$GoalsTableTableAnnotationComposer get goalId {
    final $$GoalsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalMovementsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalMovementsTableTable,
          DbGoalMovement,
          $$GoalMovementsTableTableFilterComposer,
          $$GoalMovementsTableTableOrderingComposer,
          $$GoalMovementsTableTableAnnotationComposer,
          $$GoalMovementsTableTableCreateCompanionBuilder,
          $$GoalMovementsTableTableUpdateCompanionBuilder,
          (DbGoalMovement, $$GoalMovementsTableTableReferences),
          DbGoalMovement,
          PrefetchHooks Function({bool goalId})
        > {
  $$GoalMovementsTableTableTableManager(
    _$AppDatabase db,
    $GoalMovementsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalMovementsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalMovementsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalMovementsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> transferOperationId = const Value.absent(),
                Value<String> movementType = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> releaseReason = const Value.absent(),
                Value<String?> reversalOfMovementId = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalMovementsTableCompanion(
                id: id,
                goalId: goalId,
                householdId: householdId,
                transferOperationId: transferOperationId,
                movementType: movementType,
                createdAt: createdAt,
                releaseReason: releaseReason,
                reversalOfMovementId: reversalOfMovementId,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String householdId,
                required String transferOperationId,
                required String movementType,
                required String createdAt,
                Value<String?> releaseReason = const Value.absent(),
                Value<String?> reversalOfMovementId = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalMovementsTableCompanion.insert(
                id: id,
                goalId: goalId,
                householdId: householdId,
                transferOperationId: transferOperationId,
                movementType: movementType,
                createdAt: createdAt,
                releaseReason: releaseReason,
                reversalOfMovementId: reversalOfMovementId,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GoalMovementsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (goalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.goalId,
                                referencedTable:
                                    $$GoalMovementsTableTableReferences
                                        ._goalIdTable(db),
                                referencedColumn:
                                    $$GoalMovementsTableTableReferences
                                        ._goalIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GoalMovementsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalMovementsTableTable,
      DbGoalMovement,
      $$GoalMovementsTableTableFilterComposer,
      $$GoalMovementsTableTableOrderingComposer,
      $$GoalMovementsTableTableAnnotationComposer,
      $$GoalMovementsTableTableCreateCompanionBuilder,
      $$GoalMovementsTableTableUpdateCompanionBuilder,
      (DbGoalMovement, $$GoalMovementsTableTableReferences),
      DbGoalMovement,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$GoalLifecycleEventsTableTableCreateCompanionBuilder =
    GoalLifecycleEventsTableCompanion Function({
      required String id,
      required String goalId,
      required String householdId,
      required String eventType,
      Value<String?> completionType,
      Value<String?> earlyCompletionReason,
      Value<int> earlyCompletionConfirmed,
      Value<String?> idempotencyKey,
      Value<String?> actorMetadata,
      required String effectiveAt,
      required String createdAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });
typedef $$GoalLifecycleEventsTableTableUpdateCompanionBuilder =
    GoalLifecycleEventsTableCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<String> householdId,
      Value<String> eventType,
      Value<String?> completionType,
      Value<String?> earlyCompletionReason,
      Value<int> earlyCompletionConfirmed,
      Value<String?> idempotencyKey,
      Value<String?> actorMetadata,
      Value<String> effectiveAt,
      Value<String> createdAt,
      Value<int> schemaVersion,
      Value<int> rowid,
    });

final class $$GoalLifecycleEventsTableTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GoalLifecycleEventsTableTable,
          DbGoalLifecycleEvent
        > {
  $$GoalLifecycleEventsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GoalsTableTable _goalIdTable(_$AppDatabase db) =>
      db.goalsTable.createAlias('goal_lifecycle_events__goal_id__goals__id');

  $$GoalsTableTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableTableManager(
      $_db,
      $_db.goalsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalLifecycleEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GoalLifecycleEventsTableTable> {
  $$GoalLifecycleEventsTableTableFilterComposer({
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

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completionType => $composableBuilder(
    column: $table.completionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get earlyCompletionReason => $composableBuilder(
    column: $table.earlyCompletionReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get earlyCompletionConfirmed => $composableBuilder(
    column: $table.earlyCompletionConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorMetadata => $composableBuilder(
    column: $table.actorMetadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get effectiveAt => $composableBuilder(
    column: $table.effectiveAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$GoalsTableTableFilterComposer get goalId {
    final $$GoalsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableFilterComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalLifecycleEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalLifecycleEventsTableTable> {
  $$GoalLifecycleEventsTableTableOrderingComposer({
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

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completionType => $composableBuilder(
    column: $table.completionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get earlyCompletionReason => $composableBuilder(
    column: $table.earlyCompletionReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get earlyCompletionConfirmed => $composableBuilder(
    column: $table.earlyCompletionConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorMetadata => $composableBuilder(
    column: $table.actorMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get effectiveAt => $composableBuilder(
    column: $table.effectiveAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableTableOrderingComposer get goalId {
    final $$GoalsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableOrderingComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalLifecycleEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalLifecycleEventsTableTable> {
  $$GoalLifecycleEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get completionType => $composableBuilder(
    column: $table.completionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get earlyCompletionReason => $composableBuilder(
    column: $table.earlyCompletionReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get earlyCompletionConfirmed => $composableBuilder(
    column: $table.earlyCompletionConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actorMetadata => $composableBuilder(
    column: $table.actorMetadata,
    builder: (column) => column,
  );

  GeneratedColumn<String> get effectiveAt => $composableBuilder(
    column: $table.effectiveAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  $$GoalsTableTableAnnotationComposer get goalId {
    final $$GoalsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goalsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.goalsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalLifecycleEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalLifecycleEventsTableTable,
          DbGoalLifecycleEvent,
          $$GoalLifecycleEventsTableTableFilterComposer,
          $$GoalLifecycleEventsTableTableOrderingComposer,
          $$GoalLifecycleEventsTableTableAnnotationComposer,
          $$GoalLifecycleEventsTableTableCreateCompanionBuilder,
          $$GoalLifecycleEventsTableTableUpdateCompanionBuilder,
          (DbGoalLifecycleEvent, $$GoalLifecycleEventsTableTableReferences),
          DbGoalLifecycleEvent,
          PrefetchHooks Function({bool goalId})
        > {
  $$GoalLifecycleEventsTableTableTableManager(
    _$AppDatabase db,
    $GoalLifecycleEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalLifecycleEventsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$GoalLifecycleEventsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GoalLifecycleEventsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> completionType = const Value.absent(),
                Value<String?> earlyCompletionReason = const Value.absent(),
                Value<int> earlyCompletionConfirmed = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String?> actorMetadata = const Value.absent(),
                Value<String> effectiveAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalLifecycleEventsTableCompanion(
                id: id,
                goalId: goalId,
                householdId: householdId,
                eventType: eventType,
                completionType: completionType,
                earlyCompletionReason: earlyCompletionReason,
                earlyCompletionConfirmed: earlyCompletionConfirmed,
                idempotencyKey: idempotencyKey,
                actorMetadata: actorMetadata,
                effectiveAt: effectiveAt,
                createdAt: createdAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String householdId,
                required String eventType,
                Value<String?> completionType = const Value.absent(),
                Value<String?> earlyCompletionReason = const Value.absent(),
                Value<int> earlyCompletionConfirmed = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String?> actorMetadata = const Value.absent(),
                required String effectiveAt,
                required String createdAt,
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalLifecycleEventsTableCompanion.insert(
                id: id,
                goalId: goalId,
                householdId: householdId,
                eventType: eventType,
                completionType: completionType,
                earlyCompletionReason: earlyCompletionReason,
                earlyCompletionConfirmed: earlyCompletionConfirmed,
                idempotencyKey: idempotencyKey,
                actorMetadata: actorMetadata,
                effectiveAt: effectiveAt,
                createdAt: createdAt,
                schemaVersion: schemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GoalLifecycleEventsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (goalId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.goalId,
                                referencedTable:
                                    $$GoalLifecycleEventsTableTableReferences
                                        ._goalIdTable(db),
                                referencedColumn:
                                    $$GoalLifecycleEventsTableTableReferences
                                        ._goalIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GoalLifecycleEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalLifecycleEventsTableTable,
      DbGoalLifecycleEvent,
      $$GoalLifecycleEventsTableTableFilterComposer,
      $$GoalLifecycleEventsTableTableOrderingComposer,
      $$GoalLifecycleEventsTableTableAnnotationComposer,
      $$GoalLifecycleEventsTableTableCreateCompanionBuilder,
      $$GoalLifecycleEventsTableTableUpdateCompanionBuilder,
      (DbGoalLifecycleEvent, $$GoalLifecycleEventsTableTableReferences),
      DbGoalLifecycleEvent,
      PrefetchHooks Function({bool goalId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db, _db.households);
  $$HouseholdMembersTableTableManager get householdMembers =>
      $$HouseholdMembersTableTableManager(_db, _db.householdMembers);
  $$FinancialAccountsTableTableManager get financialAccounts =>
      $$FinancialAccountsTableTableManager(_db, _db.financialAccounts);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$OperationsTableTableManager get operations =>
      $$OperationsTableTableManager(_db, _db.operations);
  $$ChildWithdrawalAuditsTableTableManager get childWithdrawalAudits =>
      $$ChildWithdrawalAuditsTableTableManager(_db, _db.childWithdrawalAudits);
  $$OperationContextsTableTableManager get operationContexts =>
      $$OperationContextsTableTableManager(_db, _db.operationContexts);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$GoalsTableTableTableManager get goalsTable =>
      $$GoalsTableTableTableManager(_db, _db.goalsTable);
  $$GoalRevisionsTableTableTableManager get goalRevisionsTable =>
      $$GoalRevisionsTableTableTableManager(_db, _db.goalRevisionsTable);
  $$GoalMovementsTableTableTableManager get goalMovementsTable =>
      $$GoalMovementsTableTableTableManager(_db, _db.goalMovementsTable);
  $$GoalLifecycleEventsTableTableTableManager get goalLifecycleEventsTable =>
      $$GoalLifecycleEventsTableTableTableManager(
        _db,
        _db.goalLifecycleEventsTable,
      );
}
