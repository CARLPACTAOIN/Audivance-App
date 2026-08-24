// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_database.dart';

// ignore_for_file: type=lint
class $LocalAccountsTable extends LocalAccounts
    with TableInfo<$LocalAccountsTable, LocalAccountRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _emailOrStudentIdMeta = const VerificationMeta(
    'emailOrStudentId',
  );
  @override
  late final GeneratedColumn<String> emailOrStudentId = GeneratedColumn<String>(
    'email_or_student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _isCredentialConfiguredMeta =
      const VerificationMeta('isCredentialConfigured');
  @override
  late final GeneratedColumn<bool> isCredentialConfigured =
      GeneratedColumn<bool>(
        'is_credential_configured',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_credential_configured" IN (0, 1))',
        ),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    emailOrStudentId,
    createdAt,
    isCredentialConfigured,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAccountRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
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
    if (data.containsKey('email_or_student_id')) {
      context.handle(
        _emailOrStudentIdMeta,
        emailOrStudentId.isAcceptableOrUnknown(
          data['email_or_student_id']!,
          _emailOrStudentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_emailOrStudentIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_credential_configured')) {
      context.handle(
        _isCredentialConfiguredMeta,
        isCredentialConfigured.isAcceptableOrUnknown(
          data['is_credential_configured']!,
          _isCredentialConfiguredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isCredentialConfiguredMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAccountRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAccountRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      emailOrStudentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email_or_student_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isCredentialConfigured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_credential_configured'],
      )!,
    );
  }

  @override
  $LocalAccountsTable createAlias(String alias) {
    return $LocalAccountsTable(attachedDatabase, alias);
  }
}

class LocalAccountRecord extends DataClass
    implements Insertable<LocalAccountRecord> {
  final String id;
  final String displayName;
  final String emailOrStudentId;
  final DateTime createdAt;
  final bool isCredentialConfigured;
  const LocalAccountRecord({
    required this.id,
    required this.displayName,
    required this.emailOrStudentId,
    required this.createdAt,
    required this.isCredentialConfigured,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['email_or_student_id'] = Variable<String>(emailOrStudentId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_credential_configured'] = Variable<bool>(isCredentialConfigured);
    return map;
  }

  LocalAccountsCompanion toCompanion(bool nullToAbsent) {
    return LocalAccountsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      emailOrStudentId: Value(emailOrStudentId),
      createdAt: Value(createdAt),
      isCredentialConfigured: Value(isCredentialConfigured),
    );
  }

  factory LocalAccountRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAccountRecord(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      emailOrStudentId: serializer.fromJson<String>(json['emailOrStudentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isCredentialConfigured: serializer.fromJson<bool>(
        json['isCredentialConfigured'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'emailOrStudentId': serializer.toJson<String>(emailOrStudentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isCredentialConfigured': serializer.toJson<bool>(isCredentialConfigured),
    };
  }

  LocalAccountRecord copyWith({
    String? id,
    String? displayName,
    String? emailOrStudentId,
    DateTime? createdAt,
    bool? isCredentialConfigured,
  }) => LocalAccountRecord(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    emailOrStudentId: emailOrStudentId ?? this.emailOrStudentId,
    createdAt: createdAt ?? this.createdAt,
    isCredentialConfigured:
        isCredentialConfigured ?? this.isCredentialConfigured,
  );
  LocalAccountRecord copyWithCompanion(LocalAccountsCompanion data) {
    return LocalAccountRecord(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      emailOrStudentId: data.emailOrStudentId.present
          ? data.emailOrStudentId.value
          : this.emailOrStudentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isCredentialConfigured: data.isCredentialConfigured.present
          ? data.isCredentialConfigured.value
          : this.isCredentialConfigured,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccountRecord(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('emailOrStudentId: $emailOrStudentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isCredentialConfigured: $isCredentialConfigured')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    emailOrStudentId,
    createdAt,
    isCredentialConfigured,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAccountRecord &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.emailOrStudentId == this.emailOrStudentId &&
          other.createdAt == this.createdAt &&
          other.isCredentialConfigured == this.isCredentialConfigured);
}

class LocalAccountsCompanion extends UpdateCompanion<LocalAccountRecord> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> emailOrStudentId;
  final Value<DateTime> createdAt;
  final Value<bool> isCredentialConfigured;
  final Value<int> rowid;
  const LocalAccountsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.emailOrStudentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isCredentialConfigured = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAccountsCompanion.insert({
    required String id,
    required String displayName,
    required String emailOrStudentId,
    required DateTime createdAt,
    required bool isCredentialConfigured,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       emailOrStudentId = Value(emailOrStudentId),
       createdAt = Value(createdAt),
       isCredentialConfigured = Value(isCredentialConfigured);
  static Insertable<LocalAccountRecord> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? emailOrStudentId,
    Expression<DateTime>? createdAt,
    Expression<bool>? isCredentialConfigured,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (emailOrStudentId != null) 'email_or_student_id': emailOrStudentId,
      if (createdAt != null) 'created_at': createdAt,
      if (isCredentialConfigured != null)
        'is_credential_configured': isCredentialConfigured,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? emailOrStudentId,
    Value<DateTime>? createdAt,
    Value<bool>? isCredentialConfigured,
    Value<int>? rowid,
  }) {
    return LocalAccountsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      emailOrStudentId: emailOrStudentId ?? this.emailOrStudentId,
      createdAt: createdAt ?? this.createdAt,
      isCredentialConfigured:
          isCredentialConfigured ?? this.isCredentialConfigured,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (emailOrStudentId.present) {
      map['email_or_student_id'] = Variable<String>(emailOrStudentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isCredentialConfigured.present) {
      map['is_credential_configured'] = Variable<bool>(
        isCredentialConfigured.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccountsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('emailOrStudentId: $emailOrStudentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('isCredentialConfigured: $isCredentialConfigured, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrganizationsTable extends Organizations
    with TableInfo<$OrganizationsTable, OrganizationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrganizationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adviserMeta = const VerificationMeta(
    'adviser',
  );
  @override
  late final GeneratedColumn<String> adviser = GeneratedColumn<String>(
    'adviser',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta(
    'semester',
  );
  @override
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schoolYearMeta = const VerificationMeta(
    'schoolYear',
  );
  @override
  late final GeneratedColumn<String> schoolYear = GeneratedColumn<String>(
    'school_year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatoryNamesJsonMeta =
      const VerificationMeta('signatoryNamesJson');
  @override
  late final GeneratedColumn<String> signatoryNamesJson =
      GeneratedColumn<String>(
        'signatory_names_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    adviser,
    semester,
    schoolYear,
    signatoryNamesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'organizations';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrganizationRecord> instance, {
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('adviser')) {
      context.handle(
        _adviserMeta,
        adviser.isAcceptableOrUnknown(data['adviser']!, _adviserMeta),
      );
    } else if (isInserting) {
      context.missing(_adviserMeta);
    }
    if (data.containsKey('semester')) {
      context.handle(
        _semesterMeta,
        semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterMeta);
    }
    if (data.containsKey('school_year')) {
      context.handle(
        _schoolYearMeta,
        schoolYear.isAcceptableOrUnknown(data['school_year']!, _schoolYearMeta),
      );
    } else if (isInserting) {
      context.missing(_schoolYearMeta);
    }
    if (data.containsKey('signatory_names_json')) {
      context.handle(
        _signatoryNamesJsonMeta,
        signatoryNamesJson.isAcceptableOrUnknown(
          data['signatory_names_json']!,
          _signatoryNamesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_signatoryNamesJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrganizationRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrganizationRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      adviser: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adviser'],
      )!,
      semester: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester'],
      )!,
      schoolYear: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school_year'],
      )!,
      signatoryNamesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signatory_names_json'],
      )!,
    );
  }

  @override
  $OrganizationsTable createAlias(String alias) {
    return $OrganizationsTable(attachedDatabase, alias);
  }
}

class OrganizationRecord extends DataClass
    implements Insertable<OrganizationRecord> {
  final String id;
  final String name;
  final String type;
  final String adviser;
  final String semester;
  final String schoolYear;
  final String signatoryNamesJson;
  const OrganizationRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.adviser,
    required this.semester,
    required this.schoolYear,
    required this.signatoryNamesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['adviser'] = Variable<String>(adviser);
    map['semester'] = Variable<String>(semester);
    map['school_year'] = Variable<String>(schoolYear);
    map['signatory_names_json'] = Variable<String>(signatoryNamesJson);
    return map;
  }

  OrganizationsCompanion toCompanion(bool nullToAbsent) {
    return OrganizationsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      adviser: Value(adviser),
      semester: Value(semester),
      schoolYear: Value(schoolYear),
      signatoryNamesJson: Value(signatoryNamesJson),
    );
  }

  factory OrganizationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrganizationRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      adviser: serializer.fromJson<String>(json['adviser']),
      semester: serializer.fromJson<String>(json['semester']),
      schoolYear: serializer.fromJson<String>(json['schoolYear']),
      signatoryNamesJson: serializer.fromJson<String>(
        json['signatoryNamesJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'adviser': serializer.toJson<String>(adviser),
      'semester': serializer.toJson<String>(semester),
      'schoolYear': serializer.toJson<String>(schoolYear),
      'signatoryNamesJson': serializer.toJson<String>(signatoryNamesJson),
    };
  }

  OrganizationRecord copyWith({
    String? id,
    String? name,
    String? type,
    String? adviser,
    String? semester,
    String? schoolYear,
    String? signatoryNamesJson,
  }) => OrganizationRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    adviser: adviser ?? this.adviser,
    semester: semester ?? this.semester,
    schoolYear: schoolYear ?? this.schoolYear,
    signatoryNamesJson: signatoryNamesJson ?? this.signatoryNamesJson,
  );
  OrganizationRecord copyWithCompanion(OrganizationsCompanion data) {
    return OrganizationRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      adviser: data.adviser.present ? data.adviser.value : this.adviser,
      semester: data.semester.present ? data.semester.value : this.semester,
      schoolYear: data.schoolYear.present
          ? data.schoolYear.value
          : this.schoolYear,
      signatoryNamesJson: data.signatoryNamesJson.present
          ? data.signatoryNamesJson.value
          : this.signatoryNamesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrganizationRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('adviser: $adviser, ')
          ..write('semester: $semester, ')
          ..write('schoolYear: $schoolYear, ')
          ..write('signatoryNamesJson: $signatoryNamesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    adviser,
    semester,
    schoolYear,
    signatoryNamesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrganizationRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.adviser == this.adviser &&
          other.semester == this.semester &&
          other.schoolYear == this.schoolYear &&
          other.signatoryNamesJson == this.signatoryNamesJson);
}

class OrganizationsCompanion extends UpdateCompanion<OrganizationRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> adviser;
  final Value<String> semester;
  final Value<String> schoolYear;
  final Value<String> signatoryNamesJson;
  final Value<int> rowid;
  const OrganizationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.adviser = const Value.absent(),
    this.semester = const Value.absent(),
    this.schoolYear = const Value.absent(),
    this.signatoryNamesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrganizationsCompanion.insert({
    required String id,
    required String name,
    required String type,
    required String adviser,
    required String semester,
    required String schoolYear,
    required String signatoryNamesJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       adviser = Value(adviser),
       semester = Value(semester),
       schoolYear = Value(schoolYear),
       signatoryNamesJson = Value(signatoryNamesJson);
  static Insertable<OrganizationRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? adviser,
    Expression<String>? semester,
    Expression<String>? schoolYear,
    Expression<String>? signatoryNamesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (adviser != null) 'adviser': adviser,
      if (semester != null) 'semester': semester,
      if (schoolYear != null) 'school_year': schoolYear,
      if (signatoryNamesJson != null)
        'signatory_names_json': signatoryNamesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrganizationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? adviser,
    Value<String>? semester,
    Value<String>? schoolYear,
    Value<String>? signatoryNamesJson,
    Value<int>? rowid,
  }) {
    return OrganizationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      adviser: adviser ?? this.adviser,
      semester: semester ?? this.semester,
      schoolYear: schoolYear ?? this.schoolYear,
      signatoryNamesJson: signatoryNamesJson ?? this.signatoryNamesJson,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (adviser.present) {
      map['adviser'] = Variable<String>(adviser.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (schoolYear.present) {
      map['school_year'] = Variable<String>(schoolYear.value);
    }
    if (signatoryNamesJson.present) {
      map['signatory_names_json'] = Variable<String>(signatoryNamesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrganizationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('adviser: $adviser, ')
          ..write('semester: $semester, ')
          ..write('schoolYear: $schoolYear, ')
          ..write('signatoryNamesJson: $signatoryNamesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfficersTable extends Officers
    with TableInfo<$OfficersTable, OfficerRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfficersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _committeeMeta = const VerificationMeta(
    'committee',
  );
  @override
  late final GeneratedColumn<String> committee = GeneratedColumn<String>(
    'committee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    fullName,
    position,
    committee,
    isArchived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'officers';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfficerRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('committee')) {
      context.handle(
        _committeeMeta,
        committee.isAcceptableOrUnknown(data['committee']!, _committeeMeta),
      );
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
  OfficerRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfficerRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position'],
      )!,
      committee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}committee'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
    );
  }

  @override
  $OfficersTable createAlias(String alias) {
    return $OfficersTable(attachedDatabase, alias);
  }
}

class OfficerRecord extends DataClass implements Insertable<OfficerRecord> {
  final String id;
  final String fullName;
  final String position;
  final String? committee;
  final bool isArchived;
  const OfficerRecord({
    required this.id,
    required this.fullName,
    required this.position,
    this.committee,
    required this.isArchived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['full_name'] = Variable<String>(fullName);
    map['position'] = Variable<String>(position);
    if (!nullToAbsent || committee != null) {
      map['committee'] = Variable<String>(committee);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  OfficersCompanion toCompanion(bool nullToAbsent) {
    return OfficersCompanion(
      id: Value(id),
      fullName: Value(fullName),
      position: Value(position),
      committee: committee == null && nullToAbsent
          ? const Value.absent()
          : Value(committee),
      isArchived: Value(isArchived),
    );
  }

  factory OfficerRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfficerRecord(
      id: serializer.fromJson<String>(json['id']),
      fullName: serializer.fromJson<String>(json['fullName']),
      position: serializer.fromJson<String>(json['position']),
      committee: serializer.fromJson<String?>(json['committee']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fullName': serializer.toJson<String>(fullName),
      'position': serializer.toJson<String>(position),
      'committee': serializer.toJson<String?>(committee),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  OfficerRecord copyWith({
    String? id,
    String? fullName,
    String? position,
    Value<String?> committee = const Value.absent(),
    bool? isArchived,
  }) => OfficerRecord(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    position: position ?? this.position,
    committee: committee.present ? committee.value : this.committee,
    isArchived: isArchived ?? this.isArchived,
  );
  OfficerRecord copyWithCompanion(OfficersCompanion data) {
    return OfficerRecord(
      id: data.id.present ? data.id.value : this.id,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      position: data.position.present ? data.position.value : this.position,
      committee: data.committee.present ? data.committee.value : this.committee,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfficerRecord(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('position: $position, ')
          ..write('committee: $committee, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fullName, position, committee, isArchived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfficerRecord &&
          other.id == this.id &&
          other.fullName == this.fullName &&
          other.position == this.position &&
          other.committee == this.committee &&
          other.isArchived == this.isArchived);
}

class OfficersCompanion extends UpdateCompanion<OfficerRecord> {
  final Value<String> id;
  final Value<String> fullName;
  final Value<String> position;
  final Value<String?> committee;
  final Value<bool> isArchived;
  final Value<int> rowid;
  const OfficersCompanion({
    this.id = const Value.absent(),
    this.fullName = const Value.absent(),
    this.position = const Value.absent(),
    this.committee = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfficersCompanion.insert({
    required String id,
    required String fullName,
    required String position,
    this.committee = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fullName = Value(fullName),
       position = Value(position);
  static Insertable<OfficerRecord> custom({
    Expression<String>? id,
    Expression<String>? fullName,
    Expression<String>? position,
    Expression<String>? committee,
    Expression<bool>? isArchived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fullName != null) 'full_name': fullName,
      if (position != null) 'position': position,
      if (committee != null) 'committee': committee,
      if (isArchived != null) 'is_archived': isArchived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfficersCompanion copyWith({
    Value<String>? id,
    Value<String>? fullName,
    Value<String>? position,
    Value<String?>? committee,
    Value<bool>? isArchived,
    Value<int>? rowid,
  }) {
    return OfficersCompanion(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      position: position ?? this.position,
      committee: committee ?? this.committee,
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
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (committee.present) {
      map['committee'] = Variable<String>(committee.value);
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
    return (StringBuffer('OfficersCompanion(')
          ..write('id: $id, ')
          ..write('fullName: $fullName, ')
          ..write('position: $position, ')
          ..write('committee: $committee, ')
          ..write('isArchived: $isArchived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TreasuryFundSourcesTable extends TreasuryFundSources
    with TableInfo<$TreasuryFundSourcesTable, TreasuryFundSourceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TreasuryFundSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceCentavosMeta = const VerificationMeta(
    'balanceCentavos',
  );
  @override
  late final GeneratedColumn<int> balanceCentavos = GeneratedColumn<int>(
    'balance_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supportingAttachmentIdMeta =
      const VerificationMeta('supportingAttachmentId');
  @override
  late final GeneratedColumn<String> supportingAttachmentId =
      GeneratedColumn<String>(
        'supporting_attachment_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _supportingAttachmentFileNameMeta =
      const VerificationMeta('supportingAttachmentFileName');
  @override
  late final GeneratedColumn<String> supportingAttachmentFileName =
      GeneratedColumn<String>(
        'supporting_attachment_file_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _supportingAttachmentLocalPathMeta =
      const VerificationMeta('supportingAttachmentLocalPath');
  @override
  late final GeneratedColumn<String> supportingAttachmentLocalPath =
      GeneratedColumn<String>(
        'supporting_attachment_local_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _supportingAttachmentSizeBytesMeta =
      const VerificationMeta('supportingAttachmentSizeBytes');
  @override
  late final GeneratedColumn<int> supportingAttachmentSizeBytes =
      GeneratedColumn<int>(
        'supporting_attachment_size_bytes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _supportingAttachmentChecksumMeta =
      const VerificationMeta('supportingAttachmentChecksum');
  @override
  late final GeneratedColumn<String> supportingAttachmentChecksum =
      GeneratedColumn<String>(
        'supporting_attachment_checksum',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    label,
    balanceCentavos,
    supportingAttachmentId,
    supportingAttachmentFileName,
    supportingAttachmentLocalPath,
    supportingAttachmentSizeBytes,
    supportingAttachmentChecksum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'treasury_fund_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<TreasuryFundSourceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('balance_centavos')) {
      context.handle(
        _balanceCentavosMeta,
        balanceCentavos.isAcceptableOrUnknown(
          data['balance_centavos']!,
          _balanceCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceCentavosMeta);
    }
    if (data.containsKey('supporting_attachment_id')) {
      context.handle(
        _supportingAttachmentIdMeta,
        supportingAttachmentId.isAcceptableOrUnknown(
          data['supporting_attachment_id']!,
          _supportingAttachmentIdMeta,
        ),
      );
    }
    if (data.containsKey('supporting_attachment_file_name')) {
      context.handle(
        _supportingAttachmentFileNameMeta,
        supportingAttachmentFileName.isAcceptableOrUnknown(
          data['supporting_attachment_file_name']!,
          _supportingAttachmentFileNameMeta,
        ),
      );
    }
    if (data.containsKey('supporting_attachment_local_path')) {
      context.handle(
        _supportingAttachmentLocalPathMeta,
        supportingAttachmentLocalPath.isAcceptableOrUnknown(
          data['supporting_attachment_local_path']!,
          _supportingAttachmentLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('supporting_attachment_size_bytes')) {
      context.handle(
        _supportingAttachmentSizeBytesMeta,
        supportingAttachmentSizeBytes.isAcceptableOrUnknown(
          data['supporting_attachment_size_bytes']!,
          _supportingAttachmentSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('supporting_attachment_checksum')) {
      context.handle(
        _supportingAttachmentChecksumMeta,
        supportingAttachmentChecksum.isAcceptableOrUnknown(
          data['supporting_attachment_checksum']!,
          _supportingAttachmentChecksumMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TreasuryFundSourceRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TreasuryFundSourceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      balanceCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_centavos'],
      )!,
      supportingAttachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supporting_attachment_id'],
      ),
      supportingAttachmentFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supporting_attachment_file_name'],
      ),
      supportingAttachmentLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supporting_attachment_local_path'],
      ),
      supportingAttachmentSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}supporting_attachment_size_bytes'],
      ),
      supportingAttachmentChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supporting_attachment_checksum'],
      ),
    );
  }

  @override
  $TreasuryFundSourcesTable createAlias(String alias) {
    return $TreasuryFundSourcesTable(attachedDatabase, alias);
  }
}

class TreasuryFundSourceRecord extends DataClass
    implements Insertable<TreasuryFundSourceRecord> {
  final String id;
  final String type;
  final String label;
  final int balanceCentavos;
  final String? supportingAttachmentId;
  final String? supportingAttachmentFileName;
  final String? supportingAttachmentLocalPath;
  final int? supportingAttachmentSizeBytes;
  final String? supportingAttachmentChecksum;
  const TreasuryFundSourceRecord({
    required this.id,
    required this.type,
    required this.label,
    required this.balanceCentavos,
    this.supportingAttachmentId,
    this.supportingAttachmentFileName,
    this.supportingAttachmentLocalPath,
    this.supportingAttachmentSizeBytes,
    this.supportingAttachmentChecksum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['label'] = Variable<String>(label);
    map['balance_centavos'] = Variable<int>(balanceCentavos);
    if (!nullToAbsent || supportingAttachmentId != null) {
      map['supporting_attachment_id'] = Variable<String>(
        supportingAttachmentId,
      );
    }
    if (!nullToAbsent || supportingAttachmentFileName != null) {
      map['supporting_attachment_file_name'] = Variable<String>(
        supportingAttachmentFileName,
      );
    }
    if (!nullToAbsent || supportingAttachmentLocalPath != null) {
      map['supporting_attachment_local_path'] = Variable<String>(
        supportingAttachmentLocalPath,
      );
    }
    if (!nullToAbsent || supportingAttachmentSizeBytes != null) {
      map['supporting_attachment_size_bytes'] = Variable<int>(
        supportingAttachmentSizeBytes,
      );
    }
    if (!nullToAbsent || supportingAttachmentChecksum != null) {
      map['supporting_attachment_checksum'] = Variable<String>(
        supportingAttachmentChecksum,
      );
    }
    return map;
  }

  TreasuryFundSourcesCompanion toCompanion(bool nullToAbsent) {
    return TreasuryFundSourcesCompanion(
      id: Value(id),
      type: Value(type),
      label: Value(label),
      balanceCentavos: Value(balanceCentavos),
      supportingAttachmentId: supportingAttachmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(supportingAttachmentId),
      supportingAttachmentFileName:
          supportingAttachmentFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(supportingAttachmentFileName),
      supportingAttachmentLocalPath:
          supportingAttachmentLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(supportingAttachmentLocalPath),
      supportingAttachmentSizeBytes:
          supportingAttachmentSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(supportingAttachmentSizeBytes),
      supportingAttachmentChecksum:
          supportingAttachmentChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(supportingAttachmentChecksum),
    );
  }

  factory TreasuryFundSourceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TreasuryFundSourceRecord(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      label: serializer.fromJson<String>(json['label']),
      balanceCentavos: serializer.fromJson<int>(json['balanceCentavos']),
      supportingAttachmentId: serializer.fromJson<String?>(
        json['supportingAttachmentId'],
      ),
      supportingAttachmentFileName: serializer.fromJson<String?>(
        json['supportingAttachmentFileName'],
      ),
      supportingAttachmentLocalPath: serializer.fromJson<String?>(
        json['supportingAttachmentLocalPath'],
      ),
      supportingAttachmentSizeBytes: serializer.fromJson<int?>(
        json['supportingAttachmentSizeBytes'],
      ),
      supportingAttachmentChecksum: serializer.fromJson<String?>(
        json['supportingAttachmentChecksum'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'label': serializer.toJson<String>(label),
      'balanceCentavos': serializer.toJson<int>(balanceCentavos),
      'supportingAttachmentId': serializer.toJson<String?>(
        supportingAttachmentId,
      ),
      'supportingAttachmentFileName': serializer.toJson<String?>(
        supportingAttachmentFileName,
      ),
      'supportingAttachmentLocalPath': serializer.toJson<String?>(
        supportingAttachmentLocalPath,
      ),
      'supportingAttachmentSizeBytes': serializer.toJson<int?>(
        supportingAttachmentSizeBytes,
      ),
      'supportingAttachmentChecksum': serializer.toJson<String?>(
        supportingAttachmentChecksum,
      ),
    };
  }

  TreasuryFundSourceRecord copyWith({
    String? id,
    String? type,
    String? label,
    int? balanceCentavos,
    Value<String?> supportingAttachmentId = const Value.absent(),
    Value<String?> supportingAttachmentFileName = const Value.absent(),
    Value<String?> supportingAttachmentLocalPath = const Value.absent(),
    Value<int?> supportingAttachmentSizeBytes = const Value.absent(),
    Value<String?> supportingAttachmentChecksum = const Value.absent(),
  }) => TreasuryFundSourceRecord(
    id: id ?? this.id,
    type: type ?? this.type,
    label: label ?? this.label,
    balanceCentavos: balanceCentavos ?? this.balanceCentavos,
    supportingAttachmentId: supportingAttachmentId.present
        ? supportingAttachmentId.value
        : this.supportingAttachmentId,
    supportingAttachmentFileName: supportingAttachmentFileName.present
        ? supportingAttachmentFileName.value
        : this.supportingAttachmentFileName,
    supportingAttachmentLocalPath: supportingAttachmentLocalPath.present
        ? supportingAttachmentLocalPath.value
        : this.supportingAttachmentLocalPath,
    supportingAttachmentSizeBytes: supportingAttachmentSizeBytes.present
        ? supportingAttachmentSizeBytes.value
        : this.supportingAttachmentSizeBytes,
    supportingAttachmentChecksum: supportingAttachmentChecksum.present
        ? supportingAttachmentChecksum.value
        : this.supportingAttachmentChecksum,
  );
  TreasuryFundSourceRecord copyWithCompanion(
    TreasuryFundSourcesCompanion data,
  ) {
    return TreasuryFundSourceRecord(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      label: data.label.present ? data.label.value : this.label,
      balanceCentavos: data.balanceCentavos.present
          ? data.balanceCentavos.value
          : this.balanceCentavos,
      supportingAttachmentId: data.supportingAttachmentId.present
          ? data.supportingAttachmentId.value
          : this.supportingAttachmentId,
      supportingAttachmentFileName: data.supportingAttachmentFileName.present
          ? data.supportingAttachmentFileName.value
          : this.supportingAttachmentFileName,
      supportingAttachmentLocalPath: data.supportingAttachmentLocalPath.present
          ? data.supportingAttachmentLocalPath.value
          : this.supportingAttachmentLocalPath,
      supportingAttachmentSizeBytes: data.supportingAttachmentSizeBytes.present
          ? data.supportingAttachmentSizeBytes.value
          : this.supportingAttachmentSizeBytes,
      supportingAttachmentChecksum: data.supportingAttachmentChecksum.present
          ? data.supportingAttachmentChecksum.value
          : this.supportingAttachmentChecksum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TreasuryFundSourceRecord(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('balanceCentavos: $balanceCentavos, ')
          ..write('supportingAttachmentId: $supportingAttachmentId, ')
          ..write(
            'supportingAttachmentFileName: $supportingAttachmentFileName, ',
          )
          ..write(
            'supportingAttachmentLocalPath: $supportingAttachmentLocalPath, ',
          )
          ..write(
            'supportingAttachmentSizeBytes: $supportingAttachmentSizeBytes, ',
          )
          ..write('supportingAttachmentChecksum: $supportingAttachmentChecksum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    label,
    balanceCentavos,
    supportingAttachmentId,
    supportingAttachmentFileName,
    supportingAttachmentLocalPath,
    supportingAttachmentSizeBytes,
    supportingAttachmentChecksum,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TreasuryFundSourceRecord &&
          other.id == this.id &&
          other.type == this.type &&
          other.label == this.label &&
          other.balanceCentavos == this.balanceCentavos &&
          other.supportingAttachmentId == this.supportingAttachmentId &&
          other.supportingAttachmentFileName ==
              this.supportingAttachmentFileName &&
          other.supportingAttachmentLocalPath ==
              this.supportingAttachmentLocalPath &&
          other.supportingAttachmentSizeBytes ==
              this.supportingAttachmentSizeBytes &&
          other.supportingAttachmentChecksum ==
              this.supportingAttachmentChecksum);
}

class TreasuryFundSourcesCompanion
    extends UpdateCompanion<TreasuryFundSourceRecord> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> label;
  final Value<int> balanceCentavos;
  final Value<String?> supportingAttachmentId;
  final Value<String?> supportingAttachmentFileName;
  final Value<String?> supportingAttachmentLocalPath;
  final Value<int?> supportingAttachmentSizeBytes;
  final Value<String?> supportingAttachmentChecksum;
  final Value<int> rowid;
  const TreasuryFundSourcesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.label = const Value.absent(),
    this.balanceCentavos = const Value.absent(),
    this.supportingAttachmentId = const Value.absent(),
    this.supportingAttachmentFileName = const Value.absent(),
    this.supportingAttachmentLocalPath = const Value.absent(),
    this.supportingAttachmentSizeBytes = const Value.absent(),
    this.supportingAttachmentChecksum = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TreasuryFundSourcesCompanion.insert({
    required String id,
    required String type,
    required String label,
    required int balanceCentavos,
    this.supportingAttachmentId = const Value.absent(),
    this.supportingAttachmentFileName = const Value.absent(),
    this.supportingAttachmentLocalPath = const Value.absent(),
    this.supportingAttachmentSizeBytes = const Value.absent(),
    this.supportingAttachmentChecksum = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       label = Value(label),
       balanceCentavos = Value(balanceCentavos);
  static Insertable<TreasuryFundSourceRecord> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? label,
    Expression<int>? balanceCentavos,
    Expression<String>? supportingAttachmentId,
    Expression<String>? supportingAttachmentFileName,
    Expression<String>? supportingAttachmentLocalPath,
    Expression<int>? supportingAttachmentSizeBytes,
    Expression<String>? supportingAttachmentChecksum,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (label != null) 'label': label,
      if (balanceCentavos != null) 'balance_centavos': balanceCentavos,
      if (supportingAttachmentId != null)
        'supporting_attachment_id': supportingAttachmentId,
      if (supportingAttachmentFileName != null)
        'supporting_attachment_file_name': supportingAttachmentFileName,
      if (supportingAttachmentLocalPath != null)
        'supporting_attachment_local_path': supportingAttachmentLocalPath,
      if (supportingAttachmentSizeBytes != null)
        'supporting_attachment_size_bytes': supportingAttachmentSizeBytes,
      if (supportingAttachmentChecksum != null)
        'supporting_attachment_checksum': supportingAttachmentChecksum,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TreasuryFundSourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? label,
    Value<int>? balanceCentavos,
    Value<String?>? supportingAttachmentId,
    Value<String?>? supportingAttachmentFileName,
    Value<String?>? supportingAttachmentLocalPath,
    Value<int?>? supportingAttachmentSizeBytes,
    Value<String?>? supportingAttachmentChecksum,
    Value<int>? rowid,
  }) {
    return TreasuryFundSourcesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      balanceCentavos: balanceCentavos ?? this.balanceCentavos,
      supportingAttachmentId:
          supportingAttachmentId ?? this.supportingAttachmentId,
      supportingAttachmentFileName:
          supportingAttachmentFileName ?? this.supportingAttachmentFileName,
      supportingAttachmentLocalPath:
          supportingAttachmentLocalPath ?? this.supportingAttachmentLocalPath,
      supportingAttachmentSizeBytes:
          supportingAttachmentSizeBytes ?? this.supportingAttachmentSizeBytes,
      supportingAttachmentChecksum:
          supportingAttachmentChecksum ?? this.supportingAttachmentChecksum,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (balanceCentavos.present) {
      map['balance_centavos'] = Variable<int>(balanceCentavos.value);
    }
    if (supportingAttachmentId.present) {
      map['supporting_attachment_id'] = Variable<String>(
        supportingAttachmentId.value,
      );
    }
    if (supportingAttachmentFileName.present) {
      map['supporting_attachment_file_name'] = Variable<String>(
        supportingAttachmentFileName.value,
      );
    }
    if (supportingAttachmentLocalPath.present) {
      map['supporting_attachment_local_path'] = Variable<String>(
        supportingAttachmentLocalPath.value,
      );
    }
    if (supportingAttachmentSizeBytes.present) {
      map['supporting_attachment_size_bytes'] = Variable<int>(
        supportingAttachmentSizeBytes.value,
      );
    }
    if (supportingAttachmentChecksum.present) {
      map['supporting_attachment_checksum'] = Variable<String>(
        supportingAttachmentChecksum.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TreasuryFundSourcesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('balanceCentavos: $balanceCentavos, ')
          ..write('supportingAttachmentId: $supportingAttachmentId, ')
          ..write(
            'supportingAttachmentFileName: $supportingAttachmentFileName, ',
          )
          ..write(
            'supportingAttachmentLocalPath: $supportingAttachmentLocalPath, ',
          )
          ..write(
            'supportingAttachmentSizeBytes: $supportingAttachmentSizeBytes, ',
          )
          ..write(
            'supportingAttachmentChecksum: $supportingAttachmentChecksum, ',
          )
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditEventsTable extends AuditEvents
    with TableInfo<$AuditEventsTable, AuditEventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _semesterMeta = const VerificationMeta(
    'semester',
  );
  @override
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
    'semester',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schoolYearMeta = const VerificationMeta(
    'schoolYear',
  );
  @override
  late final GeneratedColumn<String> schoolYear = GeneratedColumn<String>(
    'school_year',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permitApprovalDateMeta =
      const VerificationMeta('permitApprovalDate');
  @override
  late final GeneratedColumn<DateTime> permitApprovalDate =
      GeneratedColumn<DateTime>(
        'permit_approval_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resolutionNumberMeta = const VerificationMeta(
    'resolutionNumber',
  );
  @override
  late final GeneratedColumn<String> resolutionNumber = GeneratedColumn<String>(
    'resolution_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _budgetCentavosMeta = const VerificationMeta(
    'budgetCentavos',
  );
  @override
  late final GeneratedColumn<int> budgetCentavos = GeneratedColumn<int>(
    'budget_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _approvedBudgetBalanceCentavosMeta =
      const VerificationMeta('approvedBudgetBalanceCentavos');
  @override
  late final GeneratedColumn<int> approvedBudgetBalanceCentavos =
      GeneratedColumn<int>(
        'approved_budget_balance_centavos',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _resolutionAttachmentIdMeta =
      const VerificationMeta('resolutionAttachmentId');
  @override
  late final GeneratedColumn<String> resolutionAttachmentId =
      GeneratedColumn<String>(
        'resolution_attachment_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resolutionAttachmentFileNameMeta =
      const VerificationMeta('resolutionAttachmentFileName');
  @override
  late final GeneratedColumn<String> resolutionAttachmentFileName =
      GeneratedColumn<String>(
        'resolution_attachment_file_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resolutionAttachmentLocalPathMeta =
      const VerificationMeta('resolutionAttachmentLocalPath');
  @override
  late final GeneratedColumn<String> resolutionAttachmentLocalPath =
      GeneratedColumn<String>(
        'resolution_attachment_local_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resolutionAttachmentSizeBytesMeta =
      const VerificationMeta('resolutionAttachmentSizeBytes');
  @override
  late final GeneratedColumn<int> resolutionAttachmentSizeBytes =
      GeneratedColumn<int>(
        'resolution_attachment_size_bytes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resolutionAttachmentChecksumMeta =
      const VerificationMeta('resolutionAttachmentChecksum');
  @override
  late final GeneratedColumn<String> resolutionAttachmentChecksum =
      GeneratedColumn<String>(
        'resolution_attachment_checksum',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isLiquidatedMeta = const VerificationMeta(
    'isLiquidated',
  );
  @override
  late final GeneratedColumn<bool> isLiquidated = GeneratedColumn<bool>(
    'is_liquidated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_liquidated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    semester,
    schoolYear,
    startDate,
    endDate,
    permitApprovalDate,
    resolutionNumber,
    budgetCentavos,
    approvedBudgetBalanceCentavos,
    resolutionAttachmentId,
    resolutionAttachmentFileName,
    resolutionAttachmentLocalPath,
    resolutionAttachmentSizeBytes,
    resolutionAttachmentChecksum,
    isLiquidated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditEventRecord> instance, {
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('semester')) {
      context.handle(
        _semesterMeta,
        semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta),
      );
    } else if (isInserting) {
      context.missing(_semesterMeta);
    }
    if (data.containsKey('school_year')) {
      context.handle(
        _schoolYearMeta,
        schoolYear.isAcceptableOrUnknown(data['school_year']!, _schoolYearMeta),
      );
    } else if (isInserting) {
      context.missing(_schoolYearMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('permit_approval_date')) {
      context.handle(
        _permitApprovalDateMeta,
        permitApprovalDate.isAcceptableOrUnknown(
          data['permit_approval_date']!,
          _permitApprovalDateMeta,
        ),
      );
    }
    if (data.containsKey('resolution_number')) {
      context.handle(
        _resolutionNumberMeta,
        resolutionNumber.isAcceptableOrUnknown(
          data['resolution_number']!,
          _resolutionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolutionNumberMeta);
    }
    if (data.containsKey('budget_centavos')) {
      context.handle(
        _budgetCentavosMeta,
        budgetCentavos.isAcceptableOrUnknown(
          data['budget_centavos']!,
          _budgetCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_budgetCentavosMeta);
    }
    if (data.containsKey('approved_budget_balance_centavos')) {
      context.handle(
        _approvedBudgetBalanceCentavosMeta,
        approvedBudgetBalanceCentavos.isAcceptableOrUnknown(
          data['approved_budget_balance_centavos']!,
          _approvedBudgetBalanceCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_approvedBudgetBalanceCentavosMeta);
    }
    if (data.containsKey('resolution_attachment_id')) {
      context.handle(
        _resolutionAttachmentIdMeta,
        resolutionAttachmentId.isAcceptableOrUnknown(
          data['resolution_attachment_id']!,
          _resolutionAttachmentIdMeta,
        ),
      );
    }
    if (data.containsKey('resolution_attachment_file_name')) {
      context.handle(
        _resolutionAttachmentFileNameMeta,
        resolutionAttachmentFileName.isAcceptableOrUnknown(
          data['resolution_attachment_file_name']!,
          _resolutionAttachmentFileNameMeta,
        ),
      );
    }
    if (data.containsKey('resolution_attachment_local_path')) {
      context.handle(
        _resolutionAttachmentLocalPathMeta,
        resolutionAttachmentLocalPath.isAcceptableOrUnknown(
          data['resolution_attachment_local_path']!,
          _resolutionAttachmentLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('resolution_attachment_size_bytes')) {
      context.handle(
        _resolutionAttachmentSizeBytesMeta,
        resolutionAttachmentSizeBytes.isAcceptableOrUnknown(
          data['resolution_attachment_size_bytes']!,
          _resolutionAttachmentSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('resolution_attachment_checksum')) {
      context.handle(
        _resolutionAttachmentChecksumMeta,
        resolutionAttachmentChecksum.isAcceptableOrUnknown(
          data['resolution_attachment_checksum']!,
          _resolutionAttachmentChecksumMeta,
        ),
      );
    }
    if (data.containsKey('is_liquidated')) {
      context.handle(
        _isLiquidatedMeta,
        isLiquidated.isAcceptableOrUnknown(
          data['is_liquidated']!,
          _isLiquidatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditEventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditEventRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      semester: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}semester'],
      )!,
      schoolYear: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school_year'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
      permitApprovalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}permit_approval_date'],
      ),
      resolutionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_number'],
      )!,
      budgetCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_centavos'],
      )!,
      approvedBudgetBalanceCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}approved_budget_balance_centavos'],
      )!,
      resolutionAttachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_attachment_id'],
      ),
      resolutionAttachmentFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_attachment_file_name'],
      ),
      resolutionAttachmentLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_attachment_local_path'],
      ),
      resolutionAttachmentSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolution_attachment_size_bytes'],
      ),
      resolutionAttachmentChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_attachment_checksum'],
      ),
      isLiquidated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_liquidated'],
      )!,
    );
  }

  @override
  $AuditEventsTable createAlias(String alias) {
    return $AuditEventsTable(attachedDatabase, alias);
  }
}

class AuditEventRecord extends DataClass
    implements Insertable<AuditEventRecord> {
  final String id;
  final String name;
  final String type;
  final String semester;
  final String schoolYear;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? permitApprovalDate;
  final String resolutionNumber;
  final int budgetCentavos;
  final int approvedBudgetBalanceCentavos;
  final String? resolutionAttachmentId;
  final String? resolutionAttachmentFileName;
  final String? resolutionAttachmentLocalPath;
  final int? resolutionAttachmentSizeBytes;
  final String? resolutionAttachmentChecksum;
  final bool isLiquidated;
  const AuditEventRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.semester,
    required this.schoolYear,
    required this.startDate,
    required this.endDate,
    this.permitApprovalDate,
    required this.resolutionNumber,
    required this.budgetCentavos,
    required this.approvedBudgetBalanceCentavos,
    this.resolutionAttachmentId,
    this.resolutionAttachmentFileName,
    this.resolutionAttachmentLocalPath,
    this.resolutionAttachmentSizeBytes,
    this.resolutionAttachmentChecksum,
    required this.isLiquidated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['semester'] = Variable<String>(semester);
    map['school_year'] = Variable<String>(schoolYear);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    if (!nullToAbsent || permitApprovalDate != null) {
      map['permit_approval_date'] = Variable<DateTime>(permitApprovalDate);
    }
    map['resolution_number'] = Variable<String>(resolutionNumber);
    map['budget_centavos'] = Variable<int>(budgetCentavos);
    map['approved_budget_balance_centavos'] = Variable<int>(
      approvedBudgetBalanceCentavos,
    );
    if (!nullToAbsent || resolutionAttachmentId != null) {
      map['resolution_attachment_id'] = Variable<String>(
        resolutionAttachmentId,
      );
    }
    if (!nullToAbsent || resolutionAttachmentFileName != null) {
      map['resolution_attachment_file_name'] = Variable<String>(
        resolutionAttachmentFileName,
      );
    }
    if (!nullToAbsent || resolutionAttachmentLocalPath != null) {
      map['resolution_attachment_local_path'] = Variable<String>(
        resolutionAttachmentLocalPath,
      );
    }
    if (!nullToAbsent || resolutionAttachmentSizeBytes != null) {
      map['resolution_attachment_size_bytes'] = Variable<int>(
        resolutionAttachmentSizeBytes,
      );
    }
    if (!nullToAbsent || resolutionAttachmentChecksum != null) {
      map['resolution_attachment_checksum'] = Variable<String>(
        resolutionAttachmentChecksum,
      );
    }
    map['is_liquidated'] = Variable<bool>(isLiquidated);
    return map;
  }

  AuditEventsCompanion toCompanion(bool nullToAbsent) {
    return AuditEventsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      semester: Value(semester),
      schoolYear: Value(schoolYear),
      startDate: Value(startDate),
      endDate: Value(endDate),
      permitApprovalDate: permitApprovalDate == null && nullToAbsent
          ? const Value.absent()
          : Value(permitApprovalDate),
      resolutionNumber: Value(resolutionNumber),
      budgetCentavos: Value(budgetCentavos),
      approvedBudgetBalanceCentavos: Value(approvedBudgetBalanceCentavos),
      resolutionAttachmentId: resolutionAttachmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionAttachmentId),
      resolutionAttachmentFileName:
          resolutionAttachmentFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionAttachmentFileName),
      resolutionAttachmentLocalPath:
          resolutionAttachmentLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionAttachmentLocalPath),
      resolutionAttachmentSizeBytes:
          resolutionAttachmentSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionAttachmentSizeBytes),
      resolutionAttachmentChecksum:
          resolutionAttachmentChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(resolutionAttachmentChecksum),
      isLiquidated: Value(isLiquidated),
    );
  }

  factory AuditEventRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditEventRecord(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      semester: serializer.fromJson<String>(json['semester']),
      schoolYear: serializer.fromJson<String>(json['schoolYear']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      permitApprovalDate: serializer.fromJson<DateTime?>(
        json['permitApprovalDate'],
      ),
      resolutionNumber: serializer.fromJson<String>(json['resolutionNumber']),
      budgetCentavos: serializer.fromJson<int>(json['budgetCentavos']),
      approvedBudgetBalanceCentavos: serializer.fromJson<int>(
        json['approvedBudgetBalanceCentavos'],
      ),
      resolutionAttachmentId: serializer.fromJson<String?>(
        json['resolutionAttachmentId'],
      ),
      resolutionAttachmentFileName: serializer.fromJson<String?>(
        json['resolutionAttachmentFileName'],
      ),
      resolutionAttachmentLocalPath: serializer.fromJson<String?>(
        json['resolutionAttachmentLocalPath'],
      ),
      resolutionAttachmentSizeBytes: serializer.fromJson<int?>(
        json['resolutionAttachmentSizeBytes'],
      ),
      resolutionAttachmentChecksum: serializer.fromJson<String?>(
        json['resolutionAttachmentChecksum'],
      ),
      isLiquidated: serializer.fromJson<bool>(json['isLiquidated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'semester': serializer.toJson<String>(semester),
      'schoolYear': serializer.toJson<String>(schoolYear),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'permitApprovalDate': serializer.toJson<DateTime?>(permitApprovalDate),
      'resolutionNumber': serializer.toJson<String>(resolutionNumber),
      'budgetCentavos': serializer.toJson<int>(budgetCentavos),
      'approvedBudgetBalanceCentavos': serializer.toJson<int>(
        approvedBudgetBalanceCentavos,
      ),
      'resolutionAttachmentId': serializer.toJson<String?>(
        resolutionAttachmentId,
      ),
      'resolutionAttachmentFileName': serializer.toJson<String?>(
        resolutionAttachmentFileName,
      ),
      'resolutionAttachmentLocalPath': serializer.toJson<String?>(
        resolutionAttachmentLocalPath,
      ),
      'resolutionAttachmentSizeBytes': serializer.toJson<int?>(
        resolutionAttachmentSizeBytes,
      ),
      'resolutionAttachmentChecksum': serializer.toJson<String?>(
        resolutionAttachmentChecksum,
      ),
      'isLiquidated': serializer.toJson<bool>(isLiquidated),
    };
  }

  AuditEventRecord copyWith({
    String? id,
    String? name,
    String? type,
    String? semester,
    String? schoolYear,
    DateTime? startDate,
    DateTime? endDate,
    Value<DateTime?> permitApprovalDate = const Value.absent(),
    String? resolutionNumber,
    int? budgetCentavos,
    int? approvedBudgetBalanceCentavos,
    Value<String?> resolutionAttachmentId = const Value.absent(),
    Value<String?> resolutionAttachmentFileName = const Value.absent(),
    Value<String?> resolutionAttachmentLocalPath = const Value.absent(),
    Value<int?> resolutionAttachmentSizeBytes = const Value.absent(),
    Value<String?> resolutionAttachmentChecksum = const Value.absent(),
    bool? isLiquidated,
  }) => AuditEventRecord(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    semester: semester ?? this.semester,
    schoolYear: schoolYear ?? this.schoolYear,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    permitApprovalDate: permitApprovalDate.present
        ? permitApprovalDate.value
        : this.permitApprovalDate,
    resolutionNumber: resolutionNumber ?? this.resolutionNumber,
    budgetCentavos: budgetCentavos ?? this.budgetCentavos,
    approvedBudgetBalanceCentavos:
        approvedBudgetBalanceCentavos ?? this.approvedBudgetBalanceCentavos,
    resolutionAttachmentId: resolutionAttachmentId.present
        ? resolutionAttachmentId.value
        : this.resolutionAttachmentId,
    resolutionAttachmentFileName: resolutionAttachmentFileName.present
        ? resolutionAttachmentFileName.value
        : this.resolutionAttachmentFileName,
    resolutionAttachmentLocalPath: resolutionAttachmentLocalPath.present
        ? resolutionAttachmentLocalPath.value
        : this.resolutionAttachmentLocalPath,
    resolutionAttachmentSizeBytes: resolutionAttachmentSizeBytes.present
        ? resolutionAttachmentSizeBytes.value
        : this.resolutionAttachmentSizeBytes,
    resolutionAttachmentChecksum: resolutionAttachmentChecksum.present
        ? resolutionAttachmentChecksum.value
        : this.resolutionAttachmentChecksum,
    isLiquidated: isLiquidated ?? this.isLiquidated,
  );
  AuditEventRecord copyWithCompanion(AuditEventsCompanion data) {
    return AuditEventRecord(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      semester: data.semester.present ? data.semester.value : this.semester,
      schoolYear: data.schoolYear.present
          ? data.schoolYear.value
          : this.schoolYear,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      permitApprovalDate: data.permitApprovalDate.present
          ? data.permitApprovalDate.value
          : this.permitApprovalDate,
      resolutionNumber: data.resolutionNumber.present
          ? data.resolutionNumber.value
          : this.resolutionNumber,
      budgetCentavos: data.budgetCentavos.present
          ? data.budgetCentavos.value
          : this.budgetCentavos,
      approvedBudgetBalanceCentavos: data.approvedBudgetBalanceCentavos.present
          ? data.approvedBudgetBalanceCentavos.value
          : this.approvedBudgetBalanceCentavos,
      resolutionAttachmentId: data.resolutionAttachmentId.present
          ? data.resolutionAttachmentId.value
          : this.resolutionAttachmentId,
      resolutionAttachmentFileName: data.resolutionAttachmentFileName.present
          ? data.resolutionAttachmentFileName.value
          : this.resolutionAttachmentFileName,
      resolutionAttachmentLocalPath: data.resolutionAttachmentLocalPath.present
          ? data.resolutionAttachmentLocalPath.value
          : this.resolutionAttachmentLocalPath,
      resolutionAttachmentSizeBytes: data.resolutionAttachmentSizeBytes.present
          ? data.resolutionAttachmentSizeBytes.value
          : this.resolutionAttachmentSizeBytes,
      resolutionAttachmentChecksum: data.resolutionAttachmentChecksum.present
          ? data.resolutionAttachmentChecksum.value
          : this.resolutionAttachmentChecksum,
      isLiquidated: data.isLiquidated.present
          ? data.isLiquidated.value
          : this.isLiquidated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditEventRecord(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('semester: $semester, ')
          ..write('schoolYear: $schoolYear, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('permitApprovalDate: $permitApprovalDate, ')
          ..write('resolutionNumber: $resolutionNumber, ')
          ..write('budgetCentavos: $budgetCentavos, ')
          ..write(
            'approvedBudgetBalanceCentavos: $approvedBudgetBalanceCentavos, ',
          )
          ..write('resolutionAttachmentId: $resolutionAttachmentId, ')
          ..write(
            'resolutionAttachmentFileName: $resolutionAttachmentFileName, ',
          )
          ..write(
            'resolutionAttachmentLocalPath: $resolutionAttachmentLocalPath, ',
          )
          ..write(
            'resolutionAttachmentSizeBytes: $resolutionAttachmentSizeBytes, ',
          )
          ..write(
            'resolutionAttachmentChecksum: $resolutionAttachmentChecksum, ',
          )
          ..write('isLiquidated: $isLiquidated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    semester,
    schoolYear,
    startDate,
    endDate,
    permitApprovalDate,
    resolutionNumber,
    budgetCentavos,
    approvedBudgetBalanceCentavos,
    resolutionAttachmentId,
    resolutionAttachmentFileName,
    resolutionAttachmentLocalPath,
    resolutionAttachmentSizeBytes,
    resolutionAttachmentChecksum,
    isLiquidated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditEventRecord &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.semester == this.semester &&
          other.schoolYear == this.schoolYear &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.permitApprovalDate == this.permitApprovalDate &&
          other.resolutionNumber == this.resolutionNumber &&
          other.budgetCentavos == this.budgetCentavos &&
          other.approvedBudgetBalanceCentavos ==
              this.approvedBudgetBalanceCentavos &&
          other.resolutionAttachmentId == this.resolutionAttachmentId &&
          other.resolutionAttachmentFileName ==
              this.resolutionAttachmentFileName &&
          other.resolutionAttachmentLocalPath ==
              this.resolutionAttachmentLocalPath &&
          other.resolutionAttachmentSizeBytes ==
              this.resolutionAttachmentSizeBytes &&
          other.resolutionAttachmentChecksum ==
              this.resolutionAttachmentChecksum &&
          other.isLiquidated == this.isLiquidated);
}

class AuditEventsCompanion extends UpdateCompanion<AuditEventRecord> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> semester;
  final Value<String> schoolYear;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<DateTime?> permitApprovalDate;
  final Value<String> resolutionNumber;
  final Value<int> budgetCentavos;
  final Value<int> approvedBudgetBalanceCentavos;
  final Value<String?> resolutionAttachmentId;
  final Value<String?> resolutionAttachmentFileName;
  final Value<String?> resolutionAttachmentLocalPath;
  final Value<int?> resolutionAttachmentSizeBytes;
  final Value<String?> resolutionAttachmentChecksum;
  final Value<bool> isLiquidated;
  final Value<int> rowid;
  const AuditEventsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.semester = const Value.absent(),
    this.schoolYear = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.permitApprovalDate = const Value.absent(),
    this.resolutionNumber = const Value.absent(),
    this.budgetCentavos = const Value.absent(),
    this.approvedBudgetBalanceCentavos = const Value.absent(),
    this.resolutionAttachmentId = const Value.absent(),
    this.resolutionAttachmentFileName = const Value.absent(),
    this.resolutionAttachmentLocalPath = const Value.absent(),
    this.resolutionAttachmentSizeBytes = const Value.absent(),
    this.resolutionAttachmentChecksum = const Value.absent(),
    this.isLiquidated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditEventsCompanion.insert({
    required String id,
    required String name,
    required String type,
    required String semester,
    required String schoolYear,
    required DateTime startDate,
    required DateTime endDate,
    this.permitApprovalDate = const Value.absent(),
    required String resolutionNumber,
    required int budgetCentavos,
    required int approvedBudgetBalanceCentavos,
    this.resolutionAttachmentId = const Value.absent(),
    this.resolutionAttachmentFileName = const Value.absent(),
    this.resolutionAttachmentLocalPath = const Value.absent(),
    this.resolutionAttachmentSizeBytes = const Value.absent(),
    this.resolutionAttachmentChecksum = const Value.absent(),
    this.isLiquidated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       semester = Value(semester),
       schoolYear = Value(schoolYear),
       startDate = Value(startDate),
       endDate = Value(endDate),
       resolutionNumber = Value(resolutionNumber),
       budgetCentavos = Value(budgetCentavos),
       approvedBudgetBalanceCentavos = Value(approvedBudgetBalanceCentavos);
  static Insertable<AuditEventRecord> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? semester,
    Expression<String>? schoolYear,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? permitApprovalDate,
    Expression<String>? resolutionNumber,
    Expression<int>? budgetCentavos,
    Expression<int>? approvedBudgetBalanceCentavos,
    Expression<String>? resolutionAttachmentId,
    Expression<String>? resolutionAttachmentFileName,
    Expression<String>? resolutionAttachmentLocalPath,
    Expression<int>? resolutionAttachmentSizeBytes,
    Expression<String>? resolutionAttachmentChecksum,
    Expression<bool>? isLiquidated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (semester != null) 'semester': semester,
      if (schoolYear != null) 'school_year': schoolYear,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (permitApprovalDate != null)
        'permit_approval_date': permitApprovalDate,
      if (resolutionNumber != null) 'resolution_number': resolutionNumber,
      if (budgetCentavos != null) 'budget_centavos': budgetCentavos,
      if (approvedBudgetBalanceCentavos != null)
        'approved_budget_balance_centavos': approvedBudgetBalanceCentavos,
      if (resolutionAttachmentId != null)
        'resolution_attachment_id': resolutionAttachmentId,
      if (resolutionAttachmentFileName != null)
        'resolution_attachment_file_name': resolutionAttachmentFileName,
      if (resolutionAttachmentLocalPath != null)
        'resolution_attachment_local_path': resolutionAttachmentLocalPath,
      if (resolutionAttachmentSizeBytes != null)
        'resolution_attachment_size_bytes': resolutionAttachmentSizeBytes,
      if (resolutionAttachmentChecksum != null)
        'resolution_attachment_checksum': resolutionAttachmentChecksum,
      if (isLiquidated != null) 'is_liquidated': isLiquidated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? semester,
    Value<String>? schoolYear,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<DateTime?>? permitApprovalDate,
    Value<String>? resolutionNumber,
    Value<int>? budgetCentavos,
    Value<int>? approvedBudgetBalanceCentavos,
    Value<String?>? resolutionAttachmentId,
    Value<String?>? resolutionAttachmentFileName,
    Value<String?>? resolutionAttachmentLocalPath,
    Value<int?>? resolutionAttachmentSizeBytes,
    Value<String?>? resolutionAttachmentChecksum,
    Value<bool>? isLiquidated,
    Value<int>? rowid,
  }) {
    return AuditEventsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      semester: semester ?? this.semester,
      schoolYear: schoolYear ?? this.schoolYear,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      permitApprovalDate: permitApprovalDate ?? this.permitApprovalDate,
      resolutionNumber: resolutionNumber ?? this.resolutionNumber,
      budgetCentavos: budgetCentavos ?? this.budgetCentavos,
      approvedBudgetBalanceCentavos:
          approvedBudgetBalanceCentavos ?? this.approvedBudgetBalanceCentavos,
      resolutionAttachmentId:
          resolutionAttachmentId ?? this.resolutionAttachmentId,
      resolutionAttachmentFileName:
          resolutionAttachmentFileName ?? this.resolutionAttachmentFileName,
      resolutionAttachmentLocalPath:
          resolutionAttachmentLocalPath ?? this.resolutionAttachmentLocalPath,
      resolutionAttachmentSizeBytes:
          resolutionAttachmentSizeBytes ?? this.resolutionAttachmentSizeBytes,
      resolutionAttachmentChecksum:
          resolutionAttachmentChecksum ?? this.resolutionAttachmentChecksum,
      isLiquidated: isLiquidated ?? this.isLiquidated,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (schoolYear.present) {
      map['school_year'] = Variable<String>(schoolYear.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (permitApprovalDate.present) {
      map['permit_approval_date'] = Variable<DateTime>(
        permitApprovalDate.value,
      );
    }
    if (resolutionNumber.present) {
      map['resolution_number'] = Variable<String>(resolutionNumber.value);
    }
    if (budgetCentavos.present) {
      map['budget_centavos'] = Variable<int>(budgetCentavos.value);
    }
    if (approvedBudgetBalanceCentavos.present) {
      map['approved_budget_balance_centavos'] = Variable<int>(
        approvedBudgetBalanceCentavos.value,
      );
    }
    if (resolutionAttachmentId.present) {
      map['resolution_attachment_id'] = Variable<String>(
        resolutionAttachmentId.value,
      );
    }
    if (resolutionAttachmentFileName.present) {
      map['resolution_attachment_file_name'] = Variable<String>(
        resolutionAttachmentFileName.value,
      );
    }
    if (resolutionAttachmentLocalPath.present) {
      map['resolution_attachment_local_path'] = Variable<String>(
        resolutionAttachmentLocalPath.value,
      );
    }
    if (resolutionAttachmentSizeBytes.present) {
      map['resolution_attachment_size_bytes'] = Variable<int>(
        resolutionAttachmentSizeBytes.value,
      );
    }
    if (resolutionAttachmentChecksum.present) {
      map['resolution_attachment_checksum'] = Variable<String>(
        resolutionAttachmentChecksum.value,
      );
    }
    if (isLiquidated.present) {
      map['is_liquidated'] = Variable<bool>(isLiquidated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditEventsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('semester: $semester, ')
          ..write('schoolYear: $schoolYear, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('permitApprovalDate: $permitApprovalDate, ')
          ..write('resolutionNumber: $resolutionNumber, ')
          ..write('budgetCentavos: $budgetCentavos, ')
          ..write(
            'approvedBudgetBalanceCentavos: $approvedBudgetBalanceCentavos, ',
          )
          ..write('resolutionAttachmentId: $resolutionAttachmentId, ')
          ..write(
            'resolutionAttachmentFileName: $resolutionAttachmentFileName, ',
          )
          ..write(
            'resolutionAttachmentLocalPath: $resolutionAttachmentLocalPath, ',
          )
          ..write(
            'resolutionAttachmentSizeBytes: $resolutionAttachmentSizeBytes, ',
          )
          ..write(
            'resolutionAttachmentChecksum: $resolutionAttachmentChecksum, ',
          )
          ..write('isLiquidated: $isLiquidated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventFundingAllocationsTable extends EventFundingAllocations
    with
        TableInfo<$EventFundingAllocationsTable, EventFundingAllocationRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventFundingAllocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fundSourceIdMeta = const VerificationMeta(
    'fundSourceId',
  );
  @override
  late final GeneratedColumn<String> fundSourceId = GeneratedColumn<String>(
    'fund_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentavosMeta = const VerificationMeta(
    'amountCentavos',
  );
  @override
  late final GeneratedColumn<int> amountCentavos = GeneratedColumn<int>(
    'amount_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [eventId, fundSourceId, amountCentavos];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_funding_allocations';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventFundingAllocationRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('fund_source_id')) {
      context.handle(
        _fundSourceIdMeta,
        fundSourceId.isAcceptableOrUnknown(
          data['fund_source_id']!,
          _fundSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fundSourceIdMeta);
    }
    if (data.containsKey('amount_centavos')) {
      context.handle(
        _amountCentavosMeta,
        amountCentavos.isAcceptableOrUnknown(
          data['amount_centavos']!,
          _amountCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentavosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, fundSourceId};
  @override
  EventFundingAllocationRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventFundingAllocationRecord(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      fundSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fund_source_id'],
      )!,
      amountCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_centavos'],
      )!,
    );
  }

  @override
  $EventFundingAllocationsTable createAlias(String alias) {
    return $EventFundingAllocationsTable(attachedDatabase, alias);
  }
}

class EventFundingAllocationRecord extends DataClass
    implements Insertable<EventFundingAllocationRecord> {
  final String eventId;
  final String fundSourceId;
  final int amountCentavos;
  const EventFundingAllocationRecord({
    required this.eventId,
    required this.fundSourceId,
    required this.amountCentavos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['fund_source_id'] = Variable<String>(fundSourceId);
    map['amount_centavos'] = Variable<int>(amountCentavos);
    return map;
  }

  EventFundingAllocationsCompanion toCompanion(bool nullToAbsent) {
    return EventFundingAllocationsCompanion(
      eventId: Value(eventId),
      fundSourceId: Value(fundSourceId),
      amountCentavos: Value(amountCentavos),
    );
  }

  factory EventFundingAllocationRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventFundingAllocationRecord(
      eventId: serializer.fromJson<String>(json['eventId']),
      fundSourceId: serializer.fromJson<String>(json['fundSourceId']),
      amountCentavos: serializer.fromJson<int>(json['amountCentavos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'fundSourceId': serializer.toJson<String>(fundSourceId),
      'amountCentavos': serializer.toJson<int>(amountCentavos),
    };
  }

  EventFundingAllocationRecord copyWith({
    String? eventId,
    String? fundSourceId,
    int? amountCentavos,
  }) => EventFundingAllocationRecord(
    eventId: eventId ?? this.eventId,
    fundSourceId: fundSourceId ?? this.fundSourceId,
    amountCentavos: amountCentavos ?? this.amountCentavos,
  );
  EventFundingAllocationRecord copyWithCompanion(
    EventFundingAllocationsCompanion data,
  ) {
    return EventFundingAllocationRecord(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      fundSourceId: data.fundSourceId.present
          ? data.fundSourceId.value
          : this.fundSourceId,
      amountCentavos: data.amountCentavos.present
          ? data.amountCentavos.value
          : this.amountCentavos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventFundingAllocationRecord(')
          ..write('eventId: $eventId, ')
          ..write('fundSourceId: $fundSourceId, ')
          ..write('amountCentavos: $amountCentavos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, fundSourceId, amountCentavos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventFundingAllocationRecord &&
          other.eventId == this.eventId &&
          other.fundSourceId == this.fundSourceId &&
          other.amountCentavos == this.amountCentavos);
}

class EventFundingAllocationsCompanion
    extends UpdateCompanion<EventFundingAllocationRecord> {
  final Value<String> eventId;
  final Value<String> fundSourceId;
  final Value<int> amountCentavos;
  final Value<int> rowid;
  const EventFundingAllocationsCompanion({
    this.eventId = const Value.absent(),
    this.fundSourceId = const Value.absent(),
    this.amountCentavos = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventFundingAllocationsCompanion.insert({
    required String eventId,
    required String fundSourceId,
    required int amountCentavos,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       fundSourceId = Value(fundSourceId),
       amountCentavos = Value(amountCentavos);
  static Insertable<EventFundingAllocationRecord> custom({
    Expression<String>? eventId,
    Expression<String>? fundSourceId,
    Expression<int>? amountCentavos,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (fundSourceId != null) 'fund_source_id': fundSourceId,
      if (amountCentavos != null) 'amount_centavos': amountCentavos,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventFundingAllocationsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? fundSourceId,
    Value<int>? amountCentavos,
    Value<int>? rowid,
  }) {
    return EventFundingAllocationsCompanion(
      eventId: eventId ?? this.eventId,
      fundSourceId: fundSourceId ?? this.fundSourceId,
      amountCentavos: amountCentavos ?? this.amountCentavos,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (fundSourceId.present) {
      map['fund_source_id'] = Variable<String>(fundSourceId.value);
    }
    if (amountCentavos.present) {
      map['amount_centavos'] = Variable<int>(amountCentavos.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventFundingAllocationsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('fundSourceId: $fundSourceId, ')
          ..write('amountCentavos: $amountCentavos, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FundMovementsTable extends FundMovements
    with TableInfo<$FundMovementsTable, FundMovementRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FundMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentavosMeta = const VerificationMeta(
    'amountCentavos',
  );
  @override
  late final GeneratedColumn<int> amountCentavos = GeneratedColumn<int>(
    'amount_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purposeMeta = const VerificationMeta(
    'purpose',
  );
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromFundSourceIdMeta = const VerificationMeta(
    'fromFundSourceId',
  );
  @override
  late final GeneratedColumn<String> fromFundSourceId = GeneratedColumn<String>(
    'from_fund_source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toFundSourceIdMeta = const VerificationMeta(
    'toFundSourceId',
  );
  @override
  late final GeneratedColumn<String> toFundSourceId = GeneratedColumn<String>(
    'to_fund_source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _holderOfficerIdMeta = const VerificationMeta(
    'holderOfficerId',
  );
  @override
  late final GeneratedColumn<String> holderOfficerId = GeneratedColumn<String>(
    'holder_officer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSystemGeneratedMeta = const VerificationMeta(
    'isSystemGenerated',
  );
  @override
  late final GeneratedColumn<bool> isSystemGenerated = GeneratedColumn<bool>(
    'is_system_generated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system_generated" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reference,
    type,
    date,
    amountCentavos,
    purpose,
    remarks,
    eventId,
    fromFundSourceId,
    toFundSourceId,
    holderOfficerId,
    isSystemGenerated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fund_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<FundMovementRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount_centavos')) {
      context.handle(
        _amountCentavosMeta,
        amountCentavos.isAcceptableOrUnknown(
          data['amount_centavos']!,
          _amountCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentavosMeta);
    }
    if (data.containsKey('purpose')) {
      context.handle(
        _purposeMeta,
        purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta),
      );
    } else if (isInserting) {
      context.missing(_purposeMeta);
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    }
    if (data.containsKey('from_fund_source_id')) {
      context.handle(
        _fromFundSourceIdMeta,
        fromFundSourceId.isAcceptableOrUnknown(
          data['from_fund_source_id']!,
          _fromFundSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('to_fund_source_id')) {
      context.handle(
        _toFundSourceIdMeta,
        toFundSourceId.isAcceptableOrUnknown(
          data['to_fund_source_id']!,
          _toFundSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('holder_officer_id')) {
      context.handle(
        _holderOfficerIdMeta,
        holderOfficerId.isAcceptableOrUnknown(
          data['holder_officer_id']!,
          _holderOfficerIdMeta,
        ),
      );
    }
    if (data.containsKey('is_system_generated')) {
      context.handle(
        _isSystemGeneratedMeta,
        isSystemGenerated.isAcceptableOrUnknown(
          data['is_system_generated']!,
          _isSystemGeneratedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isSystemGeneratedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FundMovementRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FundMovementRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      amountCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_centavos'],
      )!,
      purpose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose'],
      )!,
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      ),
      fromFundSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_fund_source_id'],
      ),
      toFundSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_fund_source_id'],
      ),
      holderOfficerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}holder_officer_id'],
      ),
      isSystemGenerated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system_generated'],
      )!,
    );
  }

  @override
  $FundMovementsTable createAlias(String alias) {
    return $FundMovementsTable(attachedDatabase, alias);
  }
}

class FundMovementRecord extends DataClass
    implements Insertable<FundMovementRecord> {
  final String id;
  final String reference;
  final String type;
  final DateTime date;
  final int amountCentavos;
  final String purpose;
  final String? remarks;
  final String? eventId;
  final String? fromFundSourceId;
  final String? toFundSourceId;
  final String? holderOfficerId;
  final bool isSystemGenerated;
  const FundMovementRecord({
    required this.id,
    required this.reference,
    required this.type,
    required this.date,
    required this.amountCentavos,
    required this.purpose,
    this.remarks,
    this.eventId,
    this.fromFundSourceId,
    this.toFundSourceId,
    this.holderOfficerId,
    required this.isSystemGenerated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['reference'] = Variable<String>(reference);
    map['type'] = Variable<String>(type);
    map['date'] = Variable<DateTime>(date);
    map['amount_centavos'] = Variable<int>(amountCentavos);
    map['purpose'] = Variable<String>(purpose);
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || eventId != null) {
      map['event_id'] = Variable<String>(eventId);
    }
    if (!nullToAbsent || fromFundSourceId != null) {
      map['from_fund_source_id'] = Variable<String>(fromFundSourceId);
    }
    if (!nullToAbsent || toFundSourceId != null) {
      map['to_fund_source_id'] = Variable<String>(toFundSourceId);
    }
    if (!nullToAbsent || holderOfficerId != null) {
      map['holder_officer_id'] = Variable<String>(holderOfficerId);
    }
    map['is_system_generated'] = Variable<bool>(isSystemGenerated);
    return map;
  }

  FundMovementsCompanion toCompanion(bool nullToAbsent) {
    return FundMovementsCompanion(
      id: Value(id),
      reference: Value(reference),
      type: Value(type),
      date: Value(date),
      amountCentavos: Value(amountCentavos),
      purpose: Value(purpose),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      eventId: eventId == null && nullToAbsent
          ? const Value.absent()
          : Value(eventId),
      fromFundSourceId: fromFundSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromFundSourceId),
      toFundSourceId: toFundSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(toFundSourceId),
      holderOfficerId: holderOfficerId == null && nullToAbsent
          ? const Value.absent()
          : Value(holderOfficerId),
      isSystemGenerated: Value(isSystemGenerated),
    );
  }

  factory FundMovementRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FundMovementRecord(
      id: serializer.fromJson<String>(json['id']),
      reference: serializer.fromJson<String>(json['reference']),
      type: serializer.fromJson<String>(json['type']),
      date: serializer.fromJson<DateTime>(json['date']),
      amountCentavos: serializer.fromJson<int>(json['amountCentavos']),
      purpose: serializer.fromJson<String>(json['purpose']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      eventId: serializer.fromJson<String?>(json['eventId']),
      fromFundSourceId: serializer.fromJson<String?>(json['fromFundSourceId']),
      toFundSourceId: serializer.fromJson<String?>(json['toFundSourceId']),
      holderOfficerId: serializer.fromJson<String?>(json['holderOfficerId']),
      isSystemGenerated: serializer.fromJson<bool>(json['isSystemGenerated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reference': serializer.toJson<String>(reference),
      'type': serializer.toJson<String>(type),
      'date': serializer.toJson<DateTime>(date),
      'amountCentavos': serializer.toJson<int>(amountCentavos),
      'purpose': serializer.toJson<String>(purpose),
      'remarks': serializer.toJson<String?>(remarks),
      'eventId': serializer.toJson<String?>(eventId),
      'fromFundSourceId': serializer.toJson<String?>(fromFundSourceId),
      'toFundSourceId': serializer.toJson<String?>(toFundSourceId),
      'holderOfficerId': serializer.toJson<String?>(holderOfficerId),
      'isSystemGenerated': serializer.toJson<bool>(isSystemGenerated),
    };
  }

  FundMovementRecord copyWith({
    String? id,
    String? reference,
    String? type,
    DateTime? date,
    int? amountCentavos,
    String? purpose,
    Value<String?> remarks = const Value.absent(),
    Value<String?> eventId = const Value.absent(),
    Value<String?> fromFundSourceId = const Value.absent(),
    Value<String?> toFundSourceId = const Value.absent(),
    Value<String?> holderOfficerId = const Value.absent(),
    bool? isSystemGenerated,
  }) => FundMovementRecord(
    id: id ?? this.id,
    reference: reference ?? this.reference,
    type: type ?? this.type,
    date: date ?? this.date,
    amountCentavos: amountCentavos ?? this.amountCentavos,
    purpose: purpose ?? this.purpose,
    remarks: remarks.present ? remarks.value : this.remarks,
    eventId: eventId.present ? eventId.value : this.eventId,
    fromFundSourceId: fromFundSourceId.present
        ? fromFundSourceId.value
        : this.fromFundSourceId,
    toFundSourceId: toFundSourceId.present
        ? toFundSourceId.value
        : this.toFundSourceId,
    holderOfficerId: holderOfficerId.present
        ? holderOfficerId.value
        : this.holderOfficerId,
    isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
  );
  FundMovementRecord copyWithCompanion(FundMovementsCompanion data) {
    return FundMovementRecord(
      id: data.id.present ? data.id.value : this.id,
      reference: data.reference.present ? data.reference.value : this.reference,
      type: data.type.present ? data.type.value : this.type,
      date: data.date.present ? data.date.value : this.date,
      amountCentavos: data.amountCentavos.present
          ? data.amountCentavos.value
          : this.amountCentavos,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      fromFundSourceId: data.fromFundSourceId.present
          ? data.fromFundSourceId.value
          : this.fromFundSourceId,
      toFundSourceId: data.toFundSourceId.present
          ? data.toFundSourceId.value
          : this.toFundSourceId,
      holderOfficerId: data.holderOfficerId.present
          ? data.holderOfficerId.value
          : this.holderOfficerId,
      isSystemGenerated: data.isSystemGenerated.present
          ? data.isSystemGenerated.value
          : this.isSystemGenerated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FundMovementRecord(')
          ..write('id: $id, ')
          ..write('reference: $reference, ')
          ..write('type: $type, ')
          ..write('date: $date, ')
          ..write('amountCentavos: $amountCentavos, ')
          ..write('purpose: $purpose, ')
          ..write('remarks: $remarks, ')
          ..write('eventId: $eventId, ')
          ..write('fromFundSourceId: $fromFundSourceId, ')
          ..write('toFundSourceId: $toFundSourceId, ')
          ..write('holderOfficerId: $holderOfficerId, ')
          ..write('isSystemGenerated: $isSystemGenerated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reference,
    type,
    date,
    amountCentavos,
    purpose,
    remarks,
    eventId,
    fromFundSourceId,
    toFundSourceId,
    holderOfficerId,
    isSystemGenerated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FundMovementRecord &&
          other.id == this.id &&
          other.reference == this.reference &&
          other.type == this.type &&
          other.date == this.date &&
          other.amountCentavos == this.amountCentavos &&
          other.purpose == this.purpose &&
          other.remarks == this.remarks &&
          other.eventId == this.eventId &&
          other.fromFundSourceId == this.fromFundSourceId &&
          other.toFundSourceId == this.toFundSourceId &&
          other.holderOfficerId == this.holderOfficerId &&
          other.isSystemGenerated == this.isSystemGenerated);
}

class FundMovementsCompanion extends UpdateCompanion<FundMovementRecord> {
  final Value<String> id;
  final Value<String> reference;
  final Value<String> type;
  final Value<DateTime> date;
  final Value<int> amountCentavos;
  final Value<String> purpose;
  final Value<String?> remarks;
  final Value<String?> eventId;
  final Value<String?> fromFundSourceId;
  final Value<String?> toFundSourceId;
  final Value<String?> holderOfficerId;
  final Value<bool> isSystemGenerated;
  final Value<int> rowid;
  const FundMovementsCompanion({
    this.id = const Value.absent(),
    this.reference = const Value.absent(),
    this.type = const Value.absent(),
    this.date = const Value.absent(),
    this.amountCentavos = const Value.absent(),
    this.purpose = const Value.absent(),
    this.remarks = const Value.absent(),
    this.eventId = const Value.absent(),
    this.fromFundSourceId = const Value.absent(),
    this.toFundSourceId = const Value.absent(),
    this.holderOfficerId = const Value.absent(),
    this.isSystemGenerated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FundMovementsCompanion.insert({
    required String id,
    required String reference,
    required String type,
    required DateTime date,
    required int amountCentavos,
    required String purpose,
    this.remarks = const Value.absent(),
    this.eventId = const Value.absent(),
    this.fromFundSourceId = const Value.absent(),
    this.toFundSourceId = const Value.absent(),
    this.holderOfficerId = const Value.absent(),
    required bool isSystemGenerated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       reference = Value(reference),
       type = Value(type),
       date = Value(date),
       amountCentavos = Value(amountCentavos),
       purpose = Value(purpose),
       isSystemGenerated = Value(isSystemGenerated);
  static Insertable<FundMovementRecord> custom({
    Expression<String>? id,
    Expression<String>? reference,
    Expression<String>? type,
    Expression<DateTime>? date,
    Expression<int>? amountCentavos,
    Expression<String>? purpose,
    Expression<String>? remarks,
    Expression<String>? eventId,
    Expression<String>? fromFundSourceId,
    Expression<String>? toFundSourceId,
    Expression<String>? holderOfficerId,
    Expression<bool>? isSystemGenerated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reference != null) 'reference': reference,
      if (type != null) 'type': type,
      if (date != null) 'date': date,
      if (amountCentavos != null) 'amount_centavos': amountCentavos,
      if (purpose != null) 'purpose': purpose,
      if (remarks != null) 'remarks': remarks,
      if (eventId != null) 'event_id': eventId,
      if (fromFundSourceId != null) 'from_fund_source_id': fromFundSourceId,
      if (toFundSourceId != null) 'to_fund_source_id': toFundSourceId,
      if (holderOfficerId != null) 'holder_officer_id': holderOfficerId,
      if (isSystemGenerated != null) 'is_system_generated': isSystemGenerated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FundMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? reference,
    Value<String>? type,
    Value<DateTime>? date,
    Value<int>? amountCentavos,
    Value<String>? purpose,
    Value<String?>? remarks,
    Value<String?>? eventId,
    Value<String?>? fromFundSourceId,
    Value<String?>? toFundSourceId,
    Value<String?>? holderOfficerId,
    Value<bool>? isSystemGenerated,
    Value<int>? rowid,
  }) {
    return FundMovementsCompanion(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      type: type ?? this.type,
      date: date ?? this.date,
      amountCentavos: amountCentavos ?? this.amountCentavos,
      purpose: purpose ?? this.purpose,
      remarks: remarks ?? this.remarks,
      eventId: eventId ?? this.eventId,
      fromFundSourceId: fromFundSourceId ?? this.fromFundSourceId,
      toFundSourceId: toFundSourceId ?? this.toFundSourceId,
      holderOfficerId: holderOfficerId ?? this.holderOfficerId,
      isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (amountCentavos.present) {
      map['amount_centavos'] = Variable<int>(amountCentavos.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (fromFundSourceId.present) {
      map['from_fund_source_id'] = Variable<String>(fromFundSourceId.value);
    }
    if (toFundSourceId.present) {
      map['to_fund_source_id'] = Variable<String>(toFundSourceId.value);
    }
    if (holderOfficerId.present) {
      map['holder_officer_id'] = Variable<String>(holderOfficerId.value);
    }
    if (isSystemGenerated.present) {
      map['is_system_generated'] = Variable<bool>(isSystemGenerated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FundMovementsCompanion(')
          ..write('id: $id, ')
          ..write('reference: $reference, ')
          ..write('type: $type, ')
          ..write('date: $date, ')
          ..write('amountCentavos: $amountCentavos, ')
          ..write('purpose: $purpose, ')
          ..write('remarks: $remarks, ')
          ..write('eventId: $eventId, ')
          ..write('fromFundSourceId: $fromFundSourceId, ')
          ..write('toFundSourceId: $toFundSourceId, ')
          ..write('holderOfficerId: $holderOfficerId, ')
          ..write('isSystemGenerated: $isSystemGenerated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LiquidationReceiptsTable extends LiquidationReceipts
    with TableInfo<$LiquidationReceiptsTable, LiquidationReceiptRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiquidationReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payeeOrMerchantMeta = const VerificationMeta(
    'payeeOrMerchant',
  );
  @override
  late final GeneratedColumn<String> payeeOrMerchant = GeneratedColumn<String>(
    'payee_or_merchant',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceNumberMeta = const VerificationMeta(
    'evidenceNumber',
  );
  @override
  late final GeneratedColumn<String> evidenceNumber = GeneratedColumn<String>(
    'evidence_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptTypeMeta = const VerificationMeta(
    'receiptType',
  );
  @override
  late final GeneratedColumn<String> receiptType = GeneratedColumn<String>(
    'receipt_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fundingModeMeta = const VerificationMeta(
    'fundingMode',
  );
  @override
  late final GeneratedColumn<String> fundingMode = GeneratedColumn<String>(
    'funding_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountableOfficerIdMeta =
      const VerificationMeta('accountableOfficerId');
  @override
  late final GeneratedColumn<String> accountableOfficerId =
      GeneratedColumn<String>(
        'accountable_officer_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attachmentFileNameMeta =
      const VerificationMeta('attachmentFileName');
  @override
  late final GeneratedColumn<String> attachmentFileName =
      GeneratedColumn<String>(
        'attachment_file_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _attachmentLocalPathMeta =
      const VerificationMeta('attachmentLocalPath');
  @override
  late final GeneratedColumn<String> attachmentLocalPath =
      GeneratedColumn<String>(
        'attachment_local_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _attachmentSizeBytesMeta =
      const VerificationMeta('attachmentSizeBytes');
  @override
  late final GeneratedColumn<int> attachmentSizeBytes = GeneratedColumn<int>(
    'attachment_size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentChecksumMeta =
      const VerificationMeta('attachmentChecksum');
  @override
  late final GeneratedColumn<String> attachmentChecksum =
      GeneratedColumn<String>(
        'attachment_checksum',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    payeeOrMerchant,
    date,
    evidenceNumber,
    receiptType,
    fundingMode,
    accountableOfficerId,
    attachmentId,
    attachmentFileName,
    attachmentLocalPath,
    attachmentSizeBytes,
    attachmentChecksum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'liquidation_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiquidationReceiptRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('payee_or_merchant')) {
      context.handle(
        _payeeOrMerchantMeta,
        payeeOrMerchant.isAcceptableOrUnknown(
          data['payee_or_merchant']!,
          _payeeOrMerchantMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payeeOrMerchantMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('evidence_number')) {
      context.handle(
        _evidenceNumberMeta,
        evidenceNumber.isAcceptableOrUnknown(
          data['evidence_number']!,
          _evidenceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evidenceNumberMeta);
    }
    if (data.containsKey('receipt_type')) {
      context.handle(
        _receiptTypeMeta,
        receiptType.isAcceptableOrUnknown(
          data['receipt_type']!,
          _receiptTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receiptTypeMeta);
    }
    if (data.containsKey('funding_mode')) {
      context.handle(
        _fundingModeMeta,
        fundingMode.isAcceptableOrUnknown(
          data['funding_mode']!,
          _fundingModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fundingModeMeta);
    }
    if (data.containsKey('accountable_officer_id')) {
      context.handle(
        _accountableOfficerIdMeta,
        accountableOfficerId.isAcceptableOrUnknown(
          data['accountable_officer_id']!,
          _accountableOfficerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountableOfficerIdMeta);
    }
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('attachment_file_name')) {
      context.handle(
        _attachmentFileNameMeta,
        attachmentFileName.isAcceptableOrUnknown(
          data['attachment_file_name']!,
          _attachmentFileNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentFileNameMeta);
    }
    if (data.containsKey('attachment_local_path')) {
      context.handle(
        _attachmentLocalPathMeta,
        attachmentLocalPath.isAcceptableOrUnknown(
          data['attachment_local_path']!,
          _attachmentLocalPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentLocalPathMeta);
    }
    if (data.containsKey('attachment_size_bytes')) {
      context.handle(
        _attachmentSizeBytesMeta,
        attachmentSizeBytes.isAcceptableOrUnknown(
          data['attachment_size_bytes']!,
          _attachmentSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('attachment_checksum')) {
      context.handle(
        _attachmentChecksumMeta,
        attachmentChecksum.isAcceptableOrUnknown(
          data['attachment_checksum']!,
          _attachmentChecksumMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LiquidationReceiptRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiquidationReceiptRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      payeeOrMerchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payee_or_merchant'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      evidenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_number'],
      )!,
      receiptType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_type'],
      )!,
      fundingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}funding_mode'],
      )!,
      accountableOfficerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accountable_officer_id'],
      )!,
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      )!,
      attachmentFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_file_name'],
      )!,
      attachmentLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_local_path'],
      )!,
      attachmentSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attachment_size_bytes'],
      ),
      attachmentChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_checksum'],
      ),
    );
  }

  @override
  $LiquidationReceiptsTable createAlias(String alias) {
    return $LiquidationReceiptsTable(attachedDatabase, alias);
  }
}

class LiquidationReceiptRecord extends DataClass
    implements Insertable<LiquidationReceiptRecord> {
  final String id;
  final String eventId;
  final String payeeOrMerchant;
  final DateTime date;
  final String evidenceNumber;
  final String receiptType;
  final String fundingMode;
  final String accountableOfficerId;
  final String attachmentId;
  final String attachmentFileName;
  final String attachmentLocalPath;
  final int? attachmentSizeBytes;
  final String? attachmentChecksum;
  const LiquidationReceiptRecord({
    required this.id,
    required this.eventId,
    required this.payeeOrMerchant,
    required this.date,
    required this.evidenceNumber,
    required this.receiptType,
    required this.fundingMode,
    required this.accountableOfficerId,
    required this.attachmentId,
    required this.attachmentFileName,
    required this.attachmentLocalPath,
    this.attachmentSizeBytes,
    this.attachmentChecksum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['payee_or_merchant'] = Variable<String>(payeeOrMerchant);
    map['date'] = Variable<DateTime>(date);
    map['evidence_number'] = Variable<String>(evidenceNumber);
    map['receipt_type'] = Variable<String>(receiptType);
    map['funding_mode'] = Variable<String>(fundingMode);
    map['accountable_officer_id'] = Variable<String>(accountableOfficerId);
    map['attachment_id'] = Variable<String>(attachmentId);
    map['attachment_file_name'] = Variable<String>(attachmentFileName);
    map['attachment_local_path'] = Variable<String>(attachmentLocalPath);
    if (!nullToAbsent || attachmentSizeBytes != null) {
      map['attachment_size_bytes'] = Variable<int>(attachmentSizeBytes);
    }
    if (!nullToAbsent || attachmentChecksum != null) {
      map['attachment_checksum'] = Variable<String>(attachmentChecksum);
    }
    return map;
  }

  LiquidationReceiptsCompanion toCompanion(bool nullToAbsent) {
    return LiquidationReceiptsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      payeeOrMerchant: Value(payeeOrMerchant),
      date: Value(date),
      evidenceNumber: Value(evidenceNumber),
      receiptType: Value(receiptType),
      fundingMode: Value(fundingMode),
      accountableOfficerId: Value(accountableOfficerId),
      attachmentId: Value(attachmentId),
      attachmentFileName: Value(attachmentFileName),
      attachmentLocalPath: Value(attachmentLocalPath),
      attachmentSizeBytes: attachmentSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentSizeBytes),
      attachmentChecksum: attachmentChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentChecksum),
    );
  }

  factory LiquidationReceiptRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiquidationReceiptRecord(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      payeeOrMerchant: serializer.fromJson<String>(json['payeeOrMerchant']),
      date: serializer.fromJson<DateTime>(json['date']),
      evidenceNumber: serializer.fromJson<String>(json['evidenceNumber']),
      receiptType: serializer.fromJson<String>(json['receiptType']),
      fundingMode: serializer.fromJson<String>(json['fundingMode']),
      accountableOfficerId: serializer.fromJson<String>(
        json['accountableOfficerId'],
      ),
      attachmentId: serializer.fromJson<String>(json['attachmentId']),
      attachmentFileName: serializer.fromJson<String>(
        json['attachmentFileName'],
      ),
      attachmentLocalPath: serializer.fromJson<String>(
        json['attachmentLocalPath'],
      ),
      attachmentSizeBytes: serializer.fromJson<int?>(
        json['attachmentSizeBytes'],
      ),
      attachmentChecksum: serializer.fromJson<String?>(
        json['attachmentChecksum'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'payeeOrMerchant': serializer.toJson<String>(payeeOrMerchant),
      'date': serializer.toJson<DateTime>(date),
      'evidenceNumber': serializer.toJson<String>(evidenceNumber),
      'receiptType': serializer.toJson<String>(receiptType),
      'fundingMode': serializer.toJson<String>(fundingMode),
      'accountableOfficerId': serializer.toJson<String>(accountableOfficerId),
      'attachmentId': serializer.toJson<String>(attachmentId),
      'attachmentFileName': serializer.toJson<String>(attachmentFileName),
      'attachmentLocalPath': serializer.toJson<String>(attachmentLocalPath),
      'attachmentSizeBytes': serializer.toJson<int?>(attachmentSizeBytes),
      'attachmentChecksum': serializer.toJson<String?>(attachmentChecksum),
    };
  }

  LiquidationReceiptRecord copyWith({
    String? id,
    String? eventId,
    String? payeeOrMerchant,
    DateTime? date,
    String? evidenceNumber,
    String? receiptType,
    String? fundingMode,
    String? accountableOfficerId,
    String? attachmentId,
    String? attachmentFileName,
    String? attachmentLocalPath,
    Value<int?> attachmentSizeBytes = const Value.absent(),
    Value<String?> attachmentChecksum = const Value.absent(),
  }) => LiquidationReceiptRecord(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    payeeOrMerchant: payeeOrMerchant ?? this.payeeOrMerchant,
    date: date ?? this.date,
    evidenceNumber: evidenceNumber ?? this.evidenceNumber,
    receiptType: receiptType ?? this.receiptType,
    fundingMode: fundingMode ?? this.fundingMode,
    accountableOfficerId: accountableOfficerId ?? this.accountableOfficerId,
    attachmentId: attachmentId ?? this.attachmentId,
    attachmentFileName: attachmentFileName ?? this.attachmentFileName,
    attachmentLocalPath: attachmentLocalPath ?? this.attachmentLocalPath,
    attachmentSizeBytes: attachmentSizeBytes.present
        ? attachmentSizeBytes.value
        : this.attachmentSizeBytes,
    attachmentChecksum: attachmentChecksum.present
        ? attachmentChecksum.value
        : this.attachmentChecksum,
  );
  LiquidationReceiptRecord copyWithCompanion(
    LiquidationReceiptsCompanion data,
  ) {
    return LiquidationReceiptRecord(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      payeeOrMerchant: data.payeeOrMerchant.present
          ? data.payeeOrMerchant.value
          : this.payeeOrMerchant,
      date: data.date.present ? data.date.value : this.date,
      evidenceNumber: data.evidenceNumber.present
          ? data.evidenceNumber.value
          : this.evidenceNumber,
      receiptType: data.receiptType.present
          ? data.receiptType.value
          : this.receiptType,
      fundingMode: data.fundingMode.present
          ? data.fundingMode.value
          : this.fundingMode,
      accountableOfficerId: data.accountableOfficerId.present
          ? data.accountableOfficerId.value
          : this.accountableOfficerId,
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      attachmentFileName: data.attachmentFileName.present
          ? data.attachmentFileName.value
          : this.attachmentFileName,
      attachmentLocalPath: data.attachmentLocalPath.present
          ? data.attachmentLocalPath.value
          : this.attachmentLocalPath,
      attachmentSizeBytes: data.attachmentSizeBytes.present
          ? data.attachmentSizeBytes.value
          : this.attachmentSizeBytes,
      attachmentChecksum: data.attachmentChecksum.present
          ? data.attachmentChecksum.value
          : this.attachmentChecksum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiquidationReceiptRecord(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('payeeOrMerchant: $payeeOrMerchant, ')
          ..write('date: $date, ')
          ..write('evidenceNumber: $evidenceNumber, ')
          ..write('receiptType: $receiptType, ')
          ..write('fundingMode: $fundingMode, ')
          ..write('accountableOfficerId: $accountableOfficerId, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('attachmentFileName: $attachmentFileName, ')
          ..write('attachmentLocalPath: $attachmentLocalPath, ')
          ..write('attachmentSizeBytes: $attachmentSizeBytes, ')
          ..write('attachmentChecksum: $attachmentChecksum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventId,
    payeeOrMerchant,
    date,
    evidenceNumber,
    receiptType,
    fundingMode,
    accountableOfficerId,
    attachmentId,
    attachmentFileName,
    attachmentLocalPath,
    attachmentSizeBytes,
    attachmentChecksum,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiquidationReceiptRecord &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.payeeOrMerchant == this.payeeOrMerchant &&
          other.date == this.date &&
          other.evidenceNumber == this.evidenceNumber &&
          other.receiptType == this.receiptType &&
          other.fundingMode == this.fundingMode &&
          other.accountableOfficerId == this.accountableOfficerId &&
          other.attachmentId == this.attachmentId &&
          other.attachmentFileName == this.attachmentFileName &&
          other.attachmentLocalPath == this.attachmentLocalPath &&
          other.attachmentSizeBytes == this.attachmentSizeBytes &&
          other.attachmentChecksum == this.attachmentChecksum);
}

class LiquidationReceiptsCompanion
    extends UpdateCompanion<LiquidationReceiptRecord> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<String> payeeOrMerchant;
  final Value<DateTime> date;
  final Value<String> evidenceNumber;
  final Value<String> receiptType;
  final Value<String> fundingMode;
  final Value<String> accountableOfficerId;
  final Value<String> attachmentId;
  final Value<String> attachmentFileName;
  final Value<String> attachmentLocalPath;
  final Value<int?> attachmentSizeBytes;
  final Value<String?> attachmentChecksum;
  final Value<int> rowid;
  const LiquidationReceiptsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.payeeOrMerchant = const Value.absent(),
    this.date = const Value.absent(),
    this.evidenceNumber = const Value.absent(),
    this.receiptType = const Value.absent(),
    this.fundingMode = const Value.absent(),
    this.accountableOfficerId = const Value.absent(),
    this.attachmentId = const Value.absent(),
    this.attachmentFileName = const Value.absent(),
    this.attachmentLocalPath = const Value.absent(),
    this.attachmentSizeBytes = const Value.absent(),
    this.attachmentChecksum = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiquidationReceiptsCompanion.insert({
    required String id,
    required String eventId,
    required String payeeOrMerchant,
    required DateTime date,
    required String evidenceNumber,
    required String receiptType,
    required String fundingMode,
    required String accountableOfficerId,
    required String attachmentId,
    required String attachmentFileName,
    required String attachmentLocalPath,
    this.attachmentSizeBytes = const Value.absent(),
    this.attachmentChecksum = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventId = Value(eventId),
       payeeOrMerchant = Value(payeeOrMerchant),
       date = Value(date),
       evidenceNumber = Value(evidenceNumber),
       receiptType = Value(receiptType),
       fundingMode = Value(fundingMode),
       accountableOfficerId = Value(accountableOfficerId),
       attachmentId = Value(attachmentId),
       attachmentFileName = Value(attachmentFileName),
       attachmentLocalPath = Value(attachmentLocalPath);
  static Insertable<LiquidationReceiptRecord> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? payeeOrMerchant,
    Expression<DateTime>? date,
    Expression<String>? evidenceNumber,
    Expression<String>? receiptType,
    Expression<String>? fundingMode,
    Expression<String>? accountableOfficerId,
    Expression<String>? attachmentId,
    Expression<String>? attachmentFileName,
    Expression<String>? attachmentLocalPath,
    Expression<int>? attachmentSizeBytes,
    Expression<String>? attachmentChecksum,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (payeeOrMerchant != null) 'payee_or_merchant': payeeOrMerchant,
      if (date != null) 'date': date,
      if (evidenceNumber != null) 'evidence_number': evidenceNumber,
      if (receiptType != null) 'receipt_type': receiptType,
      if (fundingMode != null) 'funding_mode': fundingMode,
      if (accountableOfficerId != null)
        'accountable_officer_id': accountableOfficerId,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (attachmentFileName != null)
        'attachment_file_name': attachmentFileName,
      if (attachmentLocalPath != null)
        'attachment_local_path': attachmentLocalPath,
      if (attachmentSizeBytes != null)
        'attachment_size_bytes': attachmentSizeBytes,
      if (attachmentChecksum != null) 'attachment_checksum': attachmentChecksum,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiquidationReceiptsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventId,
    Value<String>? payeeOrMerchant,
    Value<DateTime>? date,
    Value<String>? evidenceNumber,
    Value<String>? receiptType,
    Value<String>? fundingMode,
    Value<String>? accountableOfficerId,
    Value<String>? attachmentId,
    Value<String>? attachmentFileName,
    Value<String>? attachmentLocalPath,
    Value<int?>? attachmentSizeBytes,
    Value<String?>? attachmentChecksum,
    Value<int>? rowid,
  }) {
    return LiquidationReceiptsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      payeeOrMerchant: payeeOrMerchant ?? this.payeeOrMerchant,
      date: date ?? this.date,
      evidenceNumber: evidenceNumber ?? this.evidenceNumber,
      receiptType: receiptType ?? this.receiptType,
      fundingMode: fundingMode ?? this.fundingMode,
      accountableOfficerId: accountableOfficerId ?? this.accountableOfficerId,
      attachmentId: attachmentId ?? this.attachmentId,
      attachmentFileName: attachmentFileName ?? this.attachmentFileName,
      attachmentLocalPath: attachmentLocalPath ?? this.attachmentLocalPath,
      attachmentSizeBytes: attachmentSizeBytes ?? this.attachmentSizeBytes,
      attachmentChecksum: attachmentChecksum ?? this.attachmentChecksum,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (payeeOrMerchant.present) {
      map['payee_or_merchant'] = Variable<String>(payeeOrMerchant.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (evidenceNumber.present) {
      map['evidence_number'] = Variable<String>(evidenceNumber.value);
    }
    if (receiptType.present) {
      map['receipt_type'] = Variable<String>(receiptType.value);
    }
    if (fundingMode.present) {
      map['funding_mode'] = Variable<String>(fundingMode.value);
    }
    if (accountableOfficerId.present) {
      map['accountable_officer_id'] = Variable<String>(
        accountableOfficerId.value,
      );
    }
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (attachmentFileName.present) {
      map['attachment_file_name'] = Variable<String>(attachmentFileName.value);
    }
    if (attachmentLocalPath.present) {
      map['attachment_local_path'] = Variable<String>(
        attachmentLocalPath.value,
      );
    }
    if (attachmentSizeBytes.present) {
      map['attachment_size_bytes'] = Variable<int>(attachmentSizeBytes.value);
    }
    if (attachmentChecksum.present) {
      map['attachment_checksum'] = Variable<String>(attachmentChecksum.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiquidationReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('payeeOrMerchant: $payeeOrMerchant, ')
          ..write('date: $date, ')
          ..write('evidenceNumber: $evidenceNumber, ')
          ..write('receiptType: $receiptType, ')
          ..write('fundingMode: $fundingMode, ')
          ..write('accountableOfficerId: $accountableOfficerId, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('attachmentFileName: $attachmentFileName, ')
          ..write('attachmentLocalPath: $attachmentLocalPath, ')
          ..write('attachmentSizeBytes: $attachmentSizeBytes, ')
          ..write('attachmentChecksum: $attachmentChecksum, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LiquidationLinesTable extends LiquidationLines
    with TableInfo<$LiquidationLinesTable, LiquidationLineRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiquidationLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<String> receiptId = GeneratedColumn<String>(
    'receipt_id',
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
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitCostCentavosMeta = const VerificationMeta(
    'unitCostCentavos',
  );
  @override
  late final GeneratedColumn<int> unitCostCentavos = GeneratedColumn<int>(
    'unit_cost_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    receiptId,
    description,
    quantity,
    unitCostCentavos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'liquidation_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiquidationLineRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
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
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_cost_centavos')) {
      context.handle(
        _unitCostCentavosMeta,
        unitCostCentavos.isAcceptableOrUnknown(
          data['unit_cost_centavos']!,
          _unitCostCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitCostCentavosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LiquidationLineRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiquidationLineRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitCostCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_cost_centavos'],
      )!,
    );
  }

  @override
  $LiquidationLinesTable createAlias(String alias) {
    return $LiquidationLinesTable(attachedDatabase, alias);
  }
}

class LiquidationLineRecord extends DataClass
    implements Insertable<LiquidationLineRecord> {
  final String id;
  final String receiptId;
  final String description;
  final int quantity;
  final int unitCostCentavos;
  const LiquidationLineRecord({
    required this.id,
    required this.receiptId,
    required this.description,
    required this.quantity,
    required this.unitCostCentavos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['receipt_id'] = Variable<String>(receiptId);
    map['description'] = Variable<String>(description);
    map['quantity'] = Variable<int>(quantity);
    map['unit_cost_centavos'] = Variable<int>(unitCostCentavos);
    return map;
  }

  LiquidationLinesCompanion toCompanion(bool nullToAbsent) {
    return LiquidationLinesCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      description: Value(description),
      quantity: Value(quantity),
      unitCostCentavos: Value(unitCostCentavos),
    );
  }

  factory LiquidationLineRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiquidationLineRecord(
      id: serializer.fromJson<String>(json['id']),
      receiptId: serializer.fromJson<String>(json['receiptId']),
      description: serializer.fromJson<String>(json['description']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitCostCentavos: serializer.fromJson<int>(json['unitCostCentavos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'receiptId': serializer.toJson<String>(receiptId),
      'description': serializer.toJson<String>(description),
      'quantity': serializer.toJson<int>(quantity),
      'unitCostCentavos': serializer.toJson<int>(unitCostCentavos),
    };
  }

  LiquidationLineRecord copyWith({
    String? id,
    String? receiptId,
    String? description,
    int? quantity,
    int? unitCostCentavos,
  }) => LiquidationLineRecord(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    description: description ?? this.description,
    quantity: quantity ?? this.quantity,
    unitCostCentavos: unitCostCentavos ?? this.unitCostCentavos,
  );
  LiquidationLineRecord copyWithCompanion(LiquidationLinesCompanion data) {
    return LiquidationLineRecord(
      id: data.id.present ? data.id.value : this.id,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      description: data.description.present
          ? data.description.value
          : this.description,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitCostCentavos: data.unitCostCentavos.present
          ? data.unitCostCentavos.value
          : this.unitCostCentavos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiquidationLineRecord(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('description: $description, ')
          ..write('quantity: $quantity, ')
          ..write('unitCostCentavos: $unitCostCentavos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, receiptId, description, quantity, unitCostCentavos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiquidationLineRecord &&
          other.id == this.id &&
          other.receiptId == this.receiptId &&
          other.description == this.description &&
          other.quantity == this.quantity &&
          other.unitCostCentavos == this.unitCostCentavos);
}

class LiquidationLinesCompanion extends UpdateCompanion<LiquidationLineRecord> {
  final Value<String> id;
  final Value<String> receiptId;
  final Value<String> description;
  final Value<int> quantity;
  final Value<int> unitCostCentavos;
  final Value<int> rowid;
  const LiquidationLinesCompanion({
    this.id = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.description = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCostCentavos = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiquidationLinesCompanion.insert({
    required String id,
    required String receiptId,
    required String description,
    required int quantity,
    required int unitCostCentavos,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       receiptId = Value(receiptId),
       description = Value(description),
       quantity = Value(quantity),
       unitCostCentavos = Value(unitCostCentavos);
  static Insertable<LiquidationLineRecord> custom({
    Expression<String>? id,
    Expression<String>? receiptId,
    Expression<String>? description,
    Expression<int>? quantity,
    Expression<int>? unitCostCentavos,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (receiptId != null) 'receipt_id': receiptId,
      if (description != null) 'description': description,
      if (quantity != null) 'quantity': quantity,
      if (unitCostCentavos != null) 'unit_cost_centavos': unitCostCentavos,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiquidationLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? receiptId,
    Value<String>? description,
    Value<int>? quantity,
    Value<int>? unitCostCentavos,
    Value<int>? rowid,
  }) {
    return LiquidationLinesCompanion(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitCostCentavos: unitCostCentavos ?? this.unitCostCentavos,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<String>(receiptId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitCostCentavos.present) {
      map['unit_cost_centavos'] = Variable<int>(unitCostCentavos.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiquidationLinesCompanion(')
          ..write('id: $id, ')
          ..write('receiptId: $receiptId, ')
          ..write('description: $description, ')
          ..write('quantity: $quantity, ')
          ..write('unitCostCentavos: $unitCostCentavos, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReimbursementClaimsTable extends ReimbursementClaims
    with TableInfo<$ReimbursementClaimsTable, ReimbursementClaimRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReimbursementClaimsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _officerIdMeta = const VerificationMeta(
    'officerId',
  );
  @override
  late final GeneratedColumn<String> officerId = GeneratedColumn<String>(
    'officer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentavosMeta = const VerificationMeta(
    'amountCentavos',
  );
  @override
  late final GeneratedColumn<int> amountCentavos = GeneratedColumn<int>(
    'amount_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _sourceLiquidationLineIdMeta =
      const VerificationMeta('sourceLiquidationLineId');
  @override
  late final GeneratedColumn<String> sourceLiquidationLineId =
      GeneratedColumn<String>(
        'source_liquidation_line_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    officerId,
    amountCentavos,
    status,
    sourceLiquidationLineId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reimbursement_claims';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReimbursementClaimRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('officer_id')) {
      context.handle(
        _officerIdMeta,
        officerId.isAcceptableOrUnknown(data['officer_id']!, _officerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_officerIdMeta);
    }
    if (data.containsKey('amount_centavos')) {
      context.handle(
        _amountCentavosMeta,
        amountCentavos.isAcceptableOrUnknown(
          data['amount_centavos']!,
          _amountCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentavosMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('source_liquidation_line_id')) {
      context.handle(
        _sourceLiquidationLineIdMeta,
        sourceLiquidationLineId.isAcceptableOrUnknown(
          data['source_liquidation_line_id']!,
          _sourceLiquidationLineIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceLiquidationLineIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReimbursementClaimRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReimbursementClaimRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      officerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}officer_id'],
      )!,
      amountCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_centavos'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sourceLiquidationLineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_liquidation_line_id'],
      )!,
    );
  }

  @override
  $ReimbursementClaimsTable createAlias(String alias) {
    return $ReimbursementClaimsTable(attachedDatabase, alias);
  }
}

class ReimbursementClaimRecord extends DataClass
    implements Insertable<ReimbursementClaimRecord> {
  final String id;
  final String eventId;
  final String officerId;
  final int amountCentavos;
  final String status;
  final String sourceLiquidationLineId;
  const ReimbursementClaimRecord({
    required this.id,
    required this.eventId,
    required this.officerId,
    required this.amountCentavos,
    required this.status,
    required this.sourceLiquidationLineId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['officer_id'] = Variable<String>(officerId);
    map['amount_centavos'] = Variable<int>(amountCentavos);
    map['status'] = Variable<String>(status);
    map['source_liquidation_line_id'] = Variable<String>(
      sourceLiquidationLineId,
    );
    return map;
  }

  ReimbursementClaimsCompanion toCompanion(bool nullToAbsent) {
    return ReimbursementClaimsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      officerId: Value(officerId),
      amountCentavos: Value(amountCentavos),
      status: Value(status),
      sourceLiquidationLineId: Value(sourceLiquidationLineId),
    );
  }

  factory ReimbursementClaimRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReimbursementClaimRecord(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      officerId: serializer.fromJson<String>(json['officerId']),
      amountCentavos: serializer.fromJson<int>(json['amountCentavos']),
      status: serializer.fromJson<String>(json['status']),
      sourceLiquidationLineId: serializer.fromJson<String>(
        json['sourceLiquidationLineId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'officerId': serializer.toJson<String>(officerId),
      'amountCentavos': serializer.toJson<int>(amountCentavos),
      'status': serializer.toJson<String>(status),
      'sourceLiquidationLineId': serializer.toJson<String>(
        sourceLiquidationLineId,
      ),
    };
  }

  ReimbursementClaimRecord copyWith({
    String? id,
    String? eventId,
    String? officerId,
    int? amountCentavos,
    String? status,
    String? sourceLiquidationLineId,
  }) => ReimbursementClaimRecord(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    officerId: officerId ?? this.officerId,
    amountCentavos: amountCentavos ?? this.amountCentavos,
    status: status ?? this.status,
    sourceLiquidationLineId:
        sourceLiquidationLineId ?? this.sourceLiquidationLineId,
  );
  ReimbursementClaimRecord copyWithCompanion(
    ReimbursementClaimsCompanion data,
  ) {
    return ReimbursementClaimRecord(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      officerId: data.officerId.present ? data.officerId.value : this.officerId,
      amountCentavos: data.amountCentavos.present
          ? data.amountCentavos.value
          : this.amountCentavos,
      status: data.status.present ? data.status.value : this.status,
      sourceLiquidationLineId: data.sourceLiquidationLineId.present
          ? data.sourceLiquidationLineId.value
          : this.sourceLiquidationLineId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReimbursementClaimRecord(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('officerId: $officerId, ')
          ..write('amountCentavos: $amountCentavos, ')
          ..write('status: $status, ')
          ..write('sourceLiquidationLineId: $sourceLiquidationLineId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventId,
    officerId,
    amountCentavos,
    status,
    sourceLiquidationLineId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReimbursementClaimRecord &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.officerId == this.officerId &&
          other.amountCentavos == this.amountCentavos &&
          other.status == this.status &&
          other.sourceLiquidationLineId == this.sourceLiquidationLineId);
}

class ReimbursementClaimsCompanion
    extends UpdateCompanion<ReimbursementClaimRecord> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<String> officerId;
  final Value<int> amountCentavos;
  final Value<String> status;
  final Value<String> sourceLiquidationLineId;
  final Value<int> rowid;
  const ReimbursementClaimsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.officerId = const Value.absent(),
    this.amountCentavos = const Value.absent(),
    this.status = const Value.absent(),
    this.sourceLiquidationLineId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReimbursementClaimsCompanion.insert({
    required String id,
    required String eventId,
    required String officerId,
    required int amountCentavos,
    required String status,
    required String sourceLiquidationLineId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventId = Value(eventId),
       officerId = Value(officerId),
       amountCentavos = Value(amountCentavos),
       status = Value(status),
       sourceLiquidationLineId = Value(sourceLiquidationLineId);
  static Insertable<ReimbursementClaimRecord> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? officerId,
    Expression<int>? amountCentavos,
    Expression<String>? status,
    Expression<String>? sourceLiquidationLineId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (officerId != null) 'officer_id': officerId,
      if (amountCentavos != null) 'amount_centavos': amountCentavos,
      if (status != null) 'status': status,
      if (sourceLiquidationLineId != null)
        'source_liquidation_line_id': sourceLiquidationLineId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReimbursementClaimsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventId,
    Value<String>? officerId,
    Value<int>? amountCentavos,
    Value<String>? status,
    Value<String>? sourceLiquidationLineId,
    Value<int>? rowid,
  }) {
    return ReimbursementClaimsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      officerId: officerId ?? this.officerId,
      amountCentavos: amountCentavos ?? this.amountCentavos,
      status: status ?? this.status,
      sourceLiquidationLineId:
          sourceLiquidationLineId ?? this.sourceLiquidationLineId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (officerId.present) {
      map['officer_id'] = Variable<String>(officerId.value);
    }
    if (amountCentavos.present) {
      map['amount_centavos'] = Variable<int>(amountCentavos.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sourceLiquidationLineId.present) {
      map['source_liquidation_line_id'] = Variable<String>(
        sourceLiquidationLineId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReimbursementClaimsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('officerId: $officerId, ')
          ..write('amountCentavos: $amountCentavos, ')
          ..write('status: $status, ')
          ..write('sourceLiquidationLineId: $sourceLiquidationLineId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditorReviewsTable extends AuditorReviews
    with TableInfo<$AuditorReviewsTable, AuditorReviewRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditorReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _findingsMeta = const VerificationMeta(
    'findings',
  );
  @override
  late final GeneratedColumn<String> findings = GeneratedColumn<String>(
    'findings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _causeMeta = const VerificationMeta('cause');
  @override
  late final GeneratedColumn<String> cause = GeneratedColumn<String>(
    'cause',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendationMeta = const VerificationMeta(
    'recommendation',
  );
  @override
  late final GeneratedColumn<String> recommendation = GeneratedColumn<String>(
    'recommendation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _budgetCentavosMeta = const VerificationMeta(
    'budgetCentavos',
  );
  @override
  late final GeneratedColumn<int> budgetCentavos = GeneratedColumn<int>(
    'budget_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualCentavosMeta = const VerificationMeta(
    'actualCentavos',
  );
  @override
  late final GeneratedColumn<int> actualCentavos = GeneratedColumn<int>(
    'actual_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _varianceCentavosMeta = const VerificationMeta(
    'varianceCentavos',
  );
  @override
  late final GeneratedColumn<int> varianceCentavos = GeneratedColumn<int>(
    'variance_centavos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _utilizationBasisPointsMeta =
      const VerificationMeta('utilizationBasisPoints');
  @override
  late final GeneratedColumn<int> utilizationBasisPoints = GeneratedColumn<int>(
    'utilization_basis_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthMeta = const VerificationMeta('health');
  @override
  late final GeneratedColumn<String> health = GeneratedColumn<String>(
    'health',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    id,
    eventId,
    findings,
    cause,
    recommendation,
    budgetCentavos,
    actualCentavos,
    varianceCentavos,
    utilizationBasisPoints,
    health,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'auditor_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditorReviewRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('findings')) {
      context.handle(
        _findingsMeta,
        findings.isAcceptableOrUnknown(data['findings']!, _findingsMeta),
      );
    } else if (isInserting) {
      context.missing(_findingsMeta);
    }
    if (data.containsKey('cause')) {
      context.handle(
        _causeMeta,
        cause.isAcceptableOrUnknown(data['cause']!, _causeMeta),
      );
    } else if (isInserting) {
      context.missing(_causeMeta);
    }
    if (data.containsKey('recommendation')) {
      context.handle(
        _recommendationMeta,
        recommendation.isAcceptableOrUnknown(
          data['recommendation']!,
          _recommendationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendationMeta);
    }
    if (data.containsKey('budget_centavos')) {
      context.handle(
        _budgetCentavosMeta,
        budgetCentavos.isAcceptableOrUnknown(
          data['budget_centavos']!,
          _budgetCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_budgetCentavosMeta);
    }
    if (data.containsKey('actual_centavos')) {
      context.handle(
        _actualCentavosMeta,
        actualCentavos.isAcceptableOrUnknown(
          data['actual_centavos']!,
          _actualCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualCentavosMeta);
    }
    if (data.containsKey('variance_centavos')) {
      context.handle(
        _varianceCentavosMeta,
        varianceCentavos.isAcceptableOrUnknown(
          data['variance_centavos']!,
          _varianceCentavosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_varianceCentavosMeta);
    }
    if (data.containsKey('utilization_basis_points')) {
      context.handle(
        _utilizationBasisPointsMeta,
        utilizationBasisPoints.isAcceptableOrUnknown(
          data['utilization_basis_points']!,
          _utilizationBasisPointsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_utilizationBasisPointsMeta);
    }
    if (data.containsKey('health')) {
      context.handle(
        _healthMeta,
        health.isAcceptableOrUnknown(data['health']!, _healthMeta),
      );
    } else if (isInserting) {
      context.missing(_healthMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditorReviewRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditorReviewRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      findings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}findings'],
      )!,
      cause: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cause'],
      )!,
      recommendation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommendation'],
      )!,
      budgetCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_centavos'],
      )!,
      actualCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_centavos'],
      )!,
      varianceCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}variance_centavos'],
      )!,
      utilizationBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}utilization_basis_points'],
      )!,
      health: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AuditorReviewsTable createAlias(String alias) {
    return $AuditorReviewsTable(attachedDatabase, alias);
  }
}

class AuditorReviewRecord extends DataClass
    implements Insertable<AuditorReviewRecord> {
  final String id;
  final String eventId;
  final String findings;
  final String cause;
  final String recommendation;
  final int budgetCentavos;
  final int actualCentavos;
  final int varianceCentavos;
  final int utilizationBasisPoints;
  final String health;
  final DateTime createdAt;
  const AuditorReviewRecord({
    required this.id,
    required this.eventId,
    required this.findings,
    required this.cause,
    required this.recommendation,
    required this.budgetCentavos,
    required this.actualCentavos,
    required this.varianceCentavos,
    required this.utilizationBasisPoints,
    required this.health,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['findings'] = Variable<String>(findings);
    map['cause'] = Variable<String>(cause);
    map['recommendation'] = Variable<String>(recommendation);
    map['budget_centavos'] = Variable<int>(budgetCentavos);
    map['actual_centavos'] = Variable<int>(actualCentavos);
    map['variance_centavos'] = Variable<int>(varianceCentavos);
    map['utilization_basis_points'] = Variable<int>(utilizationBasisPoints);
    map['health'] = Variable<String>(health);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuditorReviewsCompanion toCompanion(bool nullToAbsent) {
    return AuditorReviewsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      findings: Value(findings),
      cause: Value(cause),
      recommendation: Value(recommendation),
      budgetCentavos: Value(budgetCentavos),
      actualCentavos: Value(actualCentavos),
      varianceCentavos: Value(varianceCentavos),
      utilizationBasisPoints: Value(utilizationBasisPoints),
      health: Value(health),
      createdAt: Value(createdAt),
    );
  }

  factory AuditorReviewRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditorReviewRecord(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      findings: serializer.fromJson<String>(json['findings']),
      cause: serializer.fromJson<String>(json['cause']),
      recommendation: serializer.fromJson<String>(json['recommendation']),
      budgetCentavos: serializer.fromJson<int>(json['budgetCentavos']),
      actualCentavos: serializer.fromJson<int>(json['actualCentavos']),
      varianceCentavos: serializer.fromJson<int>(json['varianceCentavos']),
      utilizationBasisPoints: serializer.fromJson<int>(
        json['utilizationBasisPoints'],
      ),
      health: serializer.fromJson<String>(json['health']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventId': serializer.toJson<String>(eventId),
      'findings': serializer.toJson<String>(findings),
      'cause': serializer.toJson<String>(cause),
      'recommendation': serializer.toJson<String>(recommendation),
      'budgetCentavos': serializer.toJson<int>(budgetCentavos),
      'actualCentavos': serializer.toJson<int>(actualCentavos),
      'varianceCentavos': serializer.toJson<int>(varianceCentavos),
      'utilizationBasisPoints': serializer.toJson<int>(utilizationBasisPoints),
      'health': serializer.toJson<String>(health),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuditorReviewRecord copyWith({
    String? id,
    String? eventId,
    String? findings,
    String? cause,
    String? recommendation,
    int? budgetCentavos,
    int? actualCentavos,
    int? varianceCentavos,
    int? utilizationBasisPoints,
    String? health,
    DateTime? createdAt,
  }) => AuditorReviewRecord(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    findings: findings ?? this.findings,
    cause: cause ?? this.cause,
    recommendation: recommendation ?? this.recommendation,
    budgetCentavos: budgetCentavos ?? this.budgetCentavos,
    actualCentavos: actualCentavos ?? this.actualCentavos,
    varianceCentavos: varianceCentavos ?? this.varianceCentavos,
    utilizationBasisPoints:
        utilizationBasisPoints ?? this.utilizationBasisPoints,
    health: health ?? this.health,
    createdAt: createdAt ?? this.createdAt,
  );
  AuditorReviewRecord copyWithCompanion(AuditorReviewsCompanion data) {
    return AuditorReviewRecord(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      findings: data.findings.present ? data.findings.value : this.findings,
      cause: data.cause.present ? data.cause.value : this.cause,
      recommendation: data.recommendation.present
          ? data.recommendation.value
          : this.recommendation,
      budgetCentavos: data.budgetCentavos.present
          ? data.budgetCentavos.value
          : this.budgetCentavos,
      actualCentavos: data.actualCentavos.present
          ? data.actualCentavos.value
          : this.actualCentavos,
      varianceCentavos: data.varianceCentavos.present
          ? data.varianceCentavos.value
          : this.varianceCentavos,
      utilizationBasisPoints: data.utilizationBasisPoints.present
          ? data.utilizationBasisPoints.value
          : this.utilizationBasisPoints,
      health: data.health.present ? data.health.value : this.health,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditorReviewRecord(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('findings: $findings, ')
          ..write('cause: $cause, ')
          ..write('recommendation: $recommendation, ')
          ..write('budgetCentavos: $budgetCentavos, ')
          ..write('actualCentavos: $actualCentavos, ')
          ..write('varianceCentavos: $varianceCentavos, ')
          ..write('utilizationBasisPoints: $utilizationBasisPoints, ')
          ..write('health: $health, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventId,
    findings,
    cause,
    recommendation,
    budgetCentavos,
    actualCentavos,
    varianceCentavos,
    utilizationBasisPoints,
    health,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditorReviewRecord &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.findings == this.findings &&
          other.cause == this.cause &&
          other.recommendation == this.recommendation &&
          other.budgetCentavos == this.budgetCentavos &&
          other.actualCentavos == this.actualCentavos &&
          other.varianceCentavos == this.varianceCentavos &&
          other.utilizationBasisPoints == this.utilizationBasisPoints &&
          other.health == this.health &&
          other.createdAt == this.createdAt);
}

class AuditorReviewsCompanion extends UpdateCompanion<AuditorReviewRecord> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<String> findings;
  final Value<String> cause;
  final Value<String> recommendation;
  final Value<int> budgetCentavos;
  final Value<int> actualCentavos;
  final Value<int> varianceCentavos;
  final Value<int> utilizationBasisPoints;
  final Value<String> health;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AuditorReviewsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.findings = const Value.absent(),
    this.cause = const Value.absent(),
    this.recommendation = const Value.absent(),
    this.budgetCentavos = const Value.absent(),
    this.actualCentavos = const Value.absent(),
    this.varianceCentavos = const Value.absent(),
    this.utilizationBasisPoints = const Value.absent(),
    this.health = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditorReviewsCompanion.insert({
    required String id,
    required String eventId,
    required String findings,
    required String cause,
    required String recommendation,
    required int budgetCentavos,
    required int actualCentavos,
    required int varianceCentavos,
    required int utilizationBasisPoints,
    required String health,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventId = Value(eventId),
       findings = Value(findings),
       cause = Value(cause),
       recommendation = Value(recommendation),
       budgetCentavos = Value(budgetCentavos),
       actualCentavos = Value(actualCentavos),
       varianceCentavos = Value(varianceCentavos),
       utilizationBasisPoints = Value(utilizationBasisPoints),
       health = Value(health),
       createdAt = Value(createdAt);
  static Insertable<AuditorReviewRecord> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<String>? findings,
    Expression<String>? cause,
    Expression<String>? recommendation,
    Expression<int>? budgetCentavos,
    Expression<int>? actualCentavos,
    Expression<int>? varianceCentavos,
    Expression<int>? utilizationBasisPoints,
    Expression<String>? health,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (findings != null) 'findings': findings,
      if (cause != null) 'cause': cause,
      if (recommendation != null) 'recommendation': recommendation,
      if (budgetCentavos != null) 'budget_centavos': budgetCentavos,
      if (actualCentavos != null) 'actual_centavos': actualCentavos,
      if (varianceCentavos != null) 'variance_centavos': varianceCentavos,
      if (utilizationBasisPoints != null)
        'utilization_basis_points': utilizationBasisPoints,
      if (health != null) 'health': health,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditorReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventId,
    Value<String>? findings,
    Value<String>? cause,
    Value<String>? recommendation,
    Value<int>? budgetCentavos,
    Value<int>? actualCentavos,
    Value<int>? varianceCentavos,
    Value<int>? utilizationBasisPoints,
    Value<String>? health,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AuditorReviewsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      findings: findings ?? this.findings,
      cause: cause ?? this.cause,
      recommendation: recommendation ?? this.recommendation,
      budgetCentavos: budgetCentavos ?? this.budgetCentavos,
      actualCentavos: actualCentavos ?? this.actualCentavos,
      varianceCentavos: varianceCentavos ?? this.varianceCentavos,
      utilizationBasisPoints:
          utilizationBasisPoints ?? this.utilizationBasisPoints,
      health: health ?? this.health,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (findings.present) {
      map['findings'] = Variable<String>(findings.value);
    }
    if (cause.present) {
      map['cause'] = Variable<String>(cause.value);
    }
    if (recommendation.present) {
      map['recommendation'] = Variable<String>(recommendation.value);
    }
    if (budgetCentavos.present) {
      map['budget_centavos'] = Variable<int>(budgetCentavos.value);
    }
    if (actualCentavos.present) {
      map['actual_centavos'] = Variable<int>(actualCentavos.value);
    }
    if (varianceCentavos.present) {
      map['variance_centavos'] = Variable<int>(varianceCentavos.value);
    }
    if (utilizationBasisPoints.present) {
      map['utilization_basis_points'] = Variable<int>(
        utilizationBasisPoints.value,
      );
    }
    if (health.present) {
      map['health'] = Variable<String>(health.value);
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
    return (StringBuffer('AuditorReviewsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('findings: $findings, ')
          ..write('cause: $cause, ')
          ..write('recommendation: $recommendation, ')
          ..write('budgetCentavos: $budgetCentavos, ')
          ..write('actualCentavos: $actualCentavos, ')
          ..write('varianceCentavos: $varianceCentavos, ')
          ..write('utilizationBasisPoints: $utilizationBasisPoints, ')
          ..write('health: $health, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogEntriesTable extends AuditLogEntries
    with TableInfo<$AuditLogEntriesTable, AuditLogRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetRecordIdMeta = const VerificationMeta(
    'targetRecordId',
  );
  @override
  late final GeneratedColumn<String> targetRecordId = GeneratedColumn<String>(
    'target_record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentavosMeta = const VerificationMeta(
    'amountCentavos',
  );
  @override
  late final GeneratedColumn<int> amountCentavos = GeneratedColumn<int>(
    'amount_centavos',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beforeSnapshotJsonMeta =
      const VerificationMeta('beforeSnapshotJson');
  @override
  late final GeneratedColumn<String> beforeSnapshotJson =
      GeneratedColumn<String>(
        'before_snapshot_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _afterSnapshotJsonMeta = const VerificationMeta(
    'afterSnapshotJson',
  );
  @override
  late final GeneratedColumn<String> afterSnapshotJson =
      GeneratedColumn<String>(
        'after_snapshot_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    action,
    actor,
    targetRecordId,
    occurredAt,
    amountCentavos,
    reference,
    beforeSnapshotJson,
    afterSnapshotJson,
    metadataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    } else if (isInserting) {
      context.missing(_actorMeta);
    }
    if (data.containsKey('target_record_id')) {
      context.handle(
        _targetRecordIdMeta,
        targetRecordId.isAcceptableOrUnknown(
          data['target_record_id']!,
          _targetRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetRecordIdMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('amount_centavos')) {
      context.handle(
        _amountCentavosMeta,
        amountCentavos.isAcceptableOrUnknown(
          data['amount_centavos']!,
          _amountCentavosMeta,
        ),
      );
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('before_snapshot_json')) {
      context.handle(
        _beforeSnapshotJsonMeta,
        beforeSnapshotJson.isAcceptableOrUnknown(
          data['before_snapshot_json']!,
          _beforeSnapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('after_snapshot_json')) {
      context.handle(
        _afterSnapshotJsonMeta,
        afterSnapshotJson.isAcceptableOrUnknown(
          data['after_snapshot_json']!,
          _afterSnapshotJsonMeta,
        ),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      )!,
      targetRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_record_id'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      amountCentavos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_centavos'],
      ),
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      beforeSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}before_snapshot_json'],
      ),
      afterSnapshotJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}after_snapshot_json'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
    );
  }

  @override
  $AuditLogEntriesTable createAlias(String alias) {
    return $AuditLogEntriesTable(attachedDatabase, alias);
  }
}

class AuditLogRecord extends DataClass implements Insertable<AuditLogRecord> {
  final String id;
  final String action;
  final String actor;
  final String targetRecordId;
  final DateTime occurredAt;
  final int? amountCentavos;
  final String? reference;
  final String? beforeSnapshotJson;
  final String? afterSnapshotJson;
  final String metadataJson;
  const AuditLogRecord({
    required this.id,
    required this.action,
    required this.actor,
    required this.targetRecordId,
    required this.occurredAt,
    this.amountCentavos,
    this.reference,
    this.beforeSnapshotJson,
    this.afterSnapshotJson,
    required this.metadataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['action'] = Variable<String>(action);
    map['actor'] = Variable<String>(actor);
    map['target_record_id'] = Variable<String>(targetRecordId);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || amountCentavos != null) {
      map['amount_centavos'] = Variable<int>(amountCentavos);
    }
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || beforeSnapshotJson != null) {
      map['before_snapshot_json'] = Variable<String>(beforeSnapshotJson);
    }
    if (!nullToAbsent || afterSnapshotJson != null) {
      map['after_snapshot_json'] = Variable<String>(afterSnapshotJson);
    }
    map['metadata_json'] = Variable<String>(metadataJson);
    return map;
  }

  AuditLogEntriesCompanion toCompanion(bool nullToAbsent) {
    return AuditLogEntriesCompanion(
      id: Value(id),
      action: Value(action),
      actor: Value(actor),
      targetRecordId: Value(targetRecordId),
      occurredAt: Value(occurredAt),
      amountCentavos: amountCentavos == null && nullToAbsent
          ? const Value.absent()
          : Value(amountCentavos),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      beforeSnapshotJson: beforeSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(beforeSnapshotJson),
      afterSnapshotJson: afterSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(afterSnapshotJson),
      metadataJson: Value(metadataJson),
    );
  }

  factory AuditLogRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogRecord(
      id: serializer.fromJson<String>(json['id']),
      action: serializer.fromJson<String>(json['action']),
      actor: serializer.fromJson<String>(json['actor']),
      targetRecordId: serializer.fromJson<String>(json['targetRecordId']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      amountCentavos: serializer.fromJson<int?>(json['amountCentavos']),
      reference: serializer.fromJson<String?>(json['reference']),
      beforeSnapshotJson: serializer.fromJson<String?>(
        json['beforeSnapshotJson'],
      ),
      afterSnapshotJson: serializer.fromJson<String?>(
        json['afterSnapshotJson'],
      ),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'action': serializer.toJson<String>(action),
      'actor': serializer.toJson<String>(actor),
      'targetRecordId': serializer.toJson<String>(targetRecordId),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'amountCentavos': serializer.toJson<int?>(amountCentavos),
      'reference': serializer.toJson<String?>(reference),
      'beforeSnapshotJson': serializer.toJson<String?>(beforeSnapshotJson),
      'afterSnapshotJson': serializer.toJson<String?>(afterSnapshotJson),
      'metadataJson': serializer.toJson<String>(metadataJson),
    };
  }

  AuditLogRecord copyWith({
    String? id,
    String? action,
    String? actor,
    String? targetRecordId,
    DateTime? occurredAt,
    Value<int?> amountCentavos = const Value.absent(),
    Value<String?> reference = const Value.absent(),
    Value<String?> beforeSnapshotJson = const Value.absent(),
    Value<String?> afterSnapshotJson = const Value.absent(),
    String? metadataJson,
  }) => AuditLogRecord(
    id: id ?? this.id,
    action: action ?? this.action,
    actor: actor ?? this.actor,
    targetRecordId: targetRecordId ?? this.targetRecordId,
    occurredAt: occurredAt ?? this.occurredAt,
    amountCentavos: amountCentavos.present
        ? amountCentavos.value
        : this.amountCentavos,
    reference: reference.present ? reference.value : this.reference,
    beforeSnapshotJson: beforeSnapshotJson.present
        ? beforeSnapshotJson.value
        : this.beforeSnapshotJson,
    afterSnapshotJson: afterSnapshotJson.present
        ? afterSnapshotJson.value
        : this.afterSnapshotJson,
    metadataJson: metadataJson ?? this.metadataJson,
  );
  AuditLogRecord copyWithCompanion(AuditLogEntriesCompanion data) {
    return AuditLogRecord(
      id: data.id.present ? data.id.value : this.id,
      action: data.action.present ? data.action.value : this.action,
      actor: data.actor.present ? data.actor.value : this.actor,
      targetRecordId: data.targetRecordId.present
          ? data.targetRecordId.value
          : this.targetRecordId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      amountCentavos: data.amountCentavos.present
          ? data.amountCentavos.value
          : this.amountCentavos,
      reference: data.reference.present ? data.reference.value : this.reference,
      beforeSnapshotJson: data.beforeSnapshotJson.present
          ? data.beforeSnapshotJson.value
          : this.beforeSnapshotJson,
      afterSnapshotJson: data.afterSnapshotJson.present
          ? data.afterSnapshotJson.value
          : this.afterSnapshotJson,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogRecord(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('actor: $actor, ')
          ..write('targetRecordId: $targetRecordId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('amountCentavos: $amountCentavos, ')
          ..write('reference: $reference, ')
          ..write('beforeSnapshotJson: $beforeSnapshotJson, ')
          ..write('afterSnapshotJson: $afterSnapshotJson, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    action,
    actor,
    targetRecordId,
    occurredAt,
    amountCentavos,
    reference,
    beforeSnapshotJson,
    afterSnapshotJson,
    metadataJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogRecord &&
          other.id == this.id &&
          other.action == this.action &&
          other.actor == this.actor &&
          other.targetRecordId == this.targetRecordId &&
          other.occurredAt == this.occurredAt &&
          other.amountCentavos == this.amountCentavos &&
          other.reference == this.reference &&
          other.beforeSnapshotJson == this.beforeSnapshotJson &&
          other.afterSnapshotJson == this.afterSnapshotJson &&
          other.metadataJson == this.metadataJson);
}

class AuditLogEntriesCompanion extends UpdateCompanion<AuditLogRecord> {
  final Value<String> id;
  final Value<String> action;
  final Value<String> actor;
  final Value<String> targetRecordId;
  final Value<DateTime> occurredAt;
  final Value<int?> amountCentavos;
  final Value<String?> reference;
  final Value<String?> beforeSnapshotJson;
  final Value<String?> afterSnapshotJson;
  final Value<String> metadataJson;
  final Value<int> rowid;
  const AuditLogEntriesCompanion({
    this.id = const Value.absent(),
    this.action = const Value.absent(),
    this.actor = const Value.absent(),
    this.targetRecordId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.amountCentavos = const Value.absent(),
    this.reference = const Value.absent(),
    this.beforeSnapshotJson = const Value.absent(),
    this.afterSnapshotJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogEntriesCompanion.insert({
    required String id,
    required String action,
    required String actor,
    required String targetRecordId,
    required DateTime occurredAt,
    this.amountCentavos = const Value.absent(),
    this.reference = const Value.absent(),
    this.beforeSnapshotJson = const Value.absent(),
    this.afterSnapshotJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       action = Value(action),
       actor = Value(actor),
       targetRecordId = Value(targetRecordId),
       occurredAt = Value(occurredAt);
  static Insertable<AuditLogRecord> custom({
    Expression<String>? id,
    Expression<String>? action,
    Expression<String>? actor,
    Expression<String>? targetRecordId,
    Expression<DateTime>? occurredAt,
    Expression<int>? amountCentavos,
    Expression<String>? reference,
    Expression<String>? beforeSnapshotJson,
    Expression<String>? afterSnapshotJson,
    Expression<String>? metadataJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (action != null) 'action': action,
      if (actor != null) 'actor': actor,
      if (targetRecordId != null) 'target_record_id': targetRecordId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (amountCentavos != null) 'amount_centavos': amountCentavos,
      if (reference != null) 'reference': reference,
      if (beforeSnapshotJson != null)
        'before_snapshot_json': beforeSnapshotJson,
      if (afterSnapshotJson != null) 'after_snapshot_json': afterSnapshotJson,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? action,
    Value<String>? actor,
    Value<String>? targetRecordId,
    Value<DateTime>? occurredAt,
    Value<int?>? amountCentavos,
    Value<String?>? reference,
    Value<String?>? beforeSnapshotJson,
    Value<String?>? afterSnapshotJson,
    Value<String>? metadataJson,
    Value<int>? rowid,
  }) {
    return AuditLogEntriesCompanion(
      id: id ?? this.id,
      action: action ?? this.action,
      actor: actor ?? this.actor,
      targetRecordId: targetRecordId ?? this.targetRecordId,
      occurredAt: occurredAt ?? this.occurredAt,
      amountCentavos: amountCentavos ?? this.amountCentavos,
      reference: reference ?? this.reference,
      beforeSnapshotJson: beforeSnapshotJson ?? this.beforeSnapshotJson,
      afterSnapshotJson: afterSnapshotJson ?? this.afterSnapshotJson,
      metadataJson: metadataJson ?? this.metadataJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (targetRecordId.present) {
      map['target_record_id'] = Variable<String>(targetRecordId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (amountCentavos.present) {
      map['amount_centavos'] = Variable<int>(amountCentavos.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (beforeSnapshotJson.present) {
      map['before_snapshot_json'] = Variable<String>(beforeSnapshotJson.value);
    }
    if (afterSnapshotJson.present) {
      map['after_snapshot_json'] = Variable<String>(afterSnapshotJson.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('action: $action, ')
          ..write('actor: $actor, ')
          ..write('targetRecordId: $targetRecordId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('amountCentavos: $amountCentavos, ')
          ..write('reference: $reference, ')
          ..write('beforeSnapshotJson: $beforeSnapshotJson, ')
          ..write('afterSnapshotJson: $afterSnapshotJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AuditDatabase extends GeneratedDatabase {
  _$AuditDatabase(QueryExecutor e) : super(e);
  $AuditDatabaseManager get managers => $AuditDatabaseManager(this);
  late final $LocalAccountsTable localAccounts = $LocalAccountsTable(this);
  late final $OrganizationsTable organizations = $OrganizationsTable(this);
  late final $OfficersTable officers = $OfficersTable(this);
  late final $TreasuryFundSourcesTable treasuryFundSources =
      $TreasuryFundSourcesTable(this);
  late final $AuditEventsTable auditEvents = $AuditEventsTable(this);
  late final $EventFundingAllocationsTable eventFundingAllocations =
      $EventFundingAllocationsTable(this);
  late final $FundMovementsTable fundMovements = $FundMovementsTable(this);
  late final $LiquidationReceiptsTable liquidationReceipts =
      $LiquidationReceiptsTable(this);
  late final $LiquidationLinesTable liquidationLines = $LiquidationLinesTable(
    this,
  );
  late final $ReimbursementClaimsTable reimbursementClaims =
      $ReimbursementClaimsTable(this);
  late final $AuditorReviewsTable auditorReviews = $AuditorReviewsTable(this);
  late final $AuditLogEntriesTable auditLogEntries = $AuditLogEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localAccounts,
    organizations,
    officers,
    treasuryFundSources,
    auditEvents,
    eventFundingAllocations,
    fundMovements,
    liquidationReceipts,
    liquidationLines,
    reimbursementClaims,
    auditorReviews,
    auditLogEntries,
  ];
}

typedef $$LocalAccountsTableCreateCompanionBuilder =
    LocalAccountsCompanion Function({
      required String id,
      required String displayName,
      required String emailOrStudentId,
      required DateTime createdAt,
      required bool isCredentialConfigured,
      Value<int> rowid,
    });
typedef $$LocalAccountsTableUpdateCompanionBuilder =
    LocalAccountsCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> emailOrStudentId,
      Value<DateTime> createdAt,
      Value<bool> isCredentialConfigured,
      Value<int> rowid,
    });

class $$LocalAccountsTableFilterComposer
    extends Composer<_$AuditDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableFilterComposer({
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

  ColumnFilters<String> get emailOrStudentId => $composableBuilder(
    column: $table.emailOrStudentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCredentialConfigured => $composableBuilder(
    column: $table.isCredentialConfigured,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAccountsTableOrderingComposer
    extends Composer<_$AuditDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableOrderingComposer({
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

  ColumnOrderings<String> get emailOrStudentId => $composableBuilder(
    column: $table.emailOrStudentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCredentialConfigured => $composableBuilder(
    column: $table.isCredentialConfigured,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAccountsTableAnnotationComposer
    extends Composer<_$AuditDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableAnnotationComposer({
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

  GeneratedColumn<String> get emailOrStudentId => $composableBuilder(
    column: $table.emailOrStudentId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isCredentialConfigured => $composableBuilder(
    column: $table.isCredentialConfigured,
    builder: (column) => column,
  );
}

class $$LocalAccountsTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $LocalAccountsTable,
          LocalAccountRecord,
          $$LocalAccountsTableFilterComposer,
          $$LocalAccountsTableOrderingComposer,
          $$LocalAccountsTableAnnotationComposer,
          $$LocalAccountsTableCreateCompanionBuilder,
          $$LocalAccountsTableUpdateCompanionBuilder,
          (
            LocalAccountRecord,
            BaseReferences<
              _$AuditDatabase,
              $LocalAccountsTable,
              LocalAccountRecord
            >,
          ),
          LocalAccountRecord,
          PrefetchHooks Function()
        > {
  $$LocalAccountsTableTableManager(
    _$AuditDatabase db,
    $LocalAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> emailOrStudentId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isCredentialConfigured = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAccountsCompanion(
                id: id,
                displayName: displayName,
                emailOrStudentId: emailOrStudentId,
                createdAt: createdAt,
                isCredentialConfigured: isCredentialConfigured,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String emailOrStudentId,
                required DateTime createdAt,
                required bool isCredentialConfigured,
                Value<int> rowid = const Value.absent(),
              }) => LocalAccountsCompanion.insert(
                id: id,
                displayName: displayName,
                emailOrStudentId: emailOrStudentId,
                createdAt: createdAt,
                isCredentialConfigured: isCredentialConfigured,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $LocalAccountsTable,
      LocalAccountRecord,
      $$LocalAccountsTableFilterComposer,
      $$LocalAccountsTableOrderingComposer,
      $$LocalAccountsTableAnnotationComposer,
      $$LocalAccountsTableCreateCompanionBuilder,
      $$LocalAccountsTableUpdateCompanionBuilder,
      (
        LocalAccountRecord,
        BaseReferences<
          _$AuditDatabase,
          $LocalAccountsTable,
          LocalAccountRecord
        >,
      ),
      LocalAccountRecord,
      PrefetchHooks Function()
    >;
typedef $$OrganizationsTableCreateCompanionBuilder =
    OrganizationsCompanion Function({
      required String id,
      required String name,
      required String type,
      required String adviser,
      required String semester,
      required String schoolYear,
      required String signatoryNamesJson,
      Value<int> rowid,
    });
typedef $$OrganizationsTableUpdateCompanionBuilder =
    OrganizationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<String> adviser,
      Value<String> semester,
      Value<String> schoolYear,
      Value<String> signatoryNamesJson,
      Value<int> rowid,
    });

class $$OrganizationsTableFilterComposer
    extends Composer<_$AuditDatabase, $OrganizationsTable> {
  $$OrganizationsTableFilterComposer({
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

  ColumnFilters<String> get adviser => $composableBuilder(
    column: $table.adviser,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schoolYear => $composableBuilder(
    column: $table.schoolYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signatoryNamesJson => $composableBuilder(
    column: $table.signatoryNamesJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrganizationsTableOrderingComposer
    extends Composer<_$AuditDatabase, $OrganizationsTable> {
  $$OrganizationsTableOrderingComposer({
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

  ColumnOrderings<String> get adviser => $composableBuilder(
    column: $table.adviser,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schoolYear => $composableBuilder(
    column: $table.schoolYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signatoryNamesJson => $composableBuilder(
    column: $table.signatoryNamesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrganizationsTableAnnotationComposer
    extends Composer<_$AuditDatabase, $OrganizationsTable> {
  $$OrganizationsTableAnnotationComposer({
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

  GeneratedColumn<String> get adviser =>
      $composableBuilder(column: $table.adviser, builder: (column) => column);

  GeneratedColumn<String> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  GeneratedColumn<String> get schoolYear => $composableBuilder(
    column: $table.schoolYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signatoryNamesJson => $composableBuilder(
    column: $table.signatoryNamesJson,
    builder: (column) => column,
  );
}

class $$OrganizationsTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $OrganizationsTable,
          OrganizationRecord,
          $$OrganizationsTableFilterComposer,
          $$OrganizationsTableOrderingComposer,
          $$OrganizationsTableAnnotationComposer,
          $$OrganizationsTableCreateCompanionBuilder,
          $$OrganizationsTableUpdateCompanionBuilder,
          (
            OrganizationRecord,
            BaseReferences<
              _$AuditDatabase,
              $OrganizationsTable,
              OrganizationRecord
            >,
          ),
          OrganizationRecord,
          PrefetchHooks Function()
        > {
  $$OrganizationsTableTableManager(
    _$AuditDatabase db,
    $OrganizationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrganizationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrganizationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrganizationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> adviser = const Value.absent(),
                Value<String> semester = const Value.absent(),
                Value<String> schoolYear = const Value.absent(),
                Value<String> signatoryNamesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrganizationsCompanion(
                id: id,
                name: name,
                type: type,
                adviser: adviser,
                semester: semester,
                schoolYear: schoolYear,
                signatoryNamesJson: signatoryNamesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                required String adviser,
                required String semester,
                required String schoolYear,
                required String signatoryNamesJson,
                Value<int> rowid = const Value.absent(),
              }) => OrganizationsCompanion.insert(
                id: id,
                name: name,
                type: type,
                adviser: adviser,
                semester: semester,
                schoolYear: schoolYear,
                signatoryNamesJson: signatoryNamesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrganizationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $OrganizationsTable,
      OrganizationRecord,
      $$OrganizationsTableFilterComposer,
      $$OrganizationsTableOrderingComposer,
      $$OrganizationsTableAnnotationComposer,
      $$OrganizationsTableCreateCompanionBuilder,
      $$OrganizationsTableUpdateCompanionBuilder,
      (
        OrganizationRecord,
        BaseReferences<
          _$AuditDatabase,
          $OrganizationsTable,
          OrganizationRecord
        >,
      ),
      OrganizationRecord,
      PrefetchHooks Function()
    >;
typedef $$OfficersTableCreateCompanionBuilder = OfficersCompanion Function({
  required String id,
  required String fullName,
  required String position,
  Value<String?> committee,
  Value<bool> isArchived,
  Value<int> rowid,
});
typedef $$OfficersTableUpdateCompanionBuilder = OfficersCompanion Function({
  Value<String> id,
  Value<String> fullName,
  Value<String> position,
  Value<String?> committee,
  Value<bool> isArchived,
  Value<int> rowid,
});

class $$OfficersTableFilterComposer
    extends Composer<_$AuditDatabase, $OfficersTable> {
  $$OfficersTableFilterComposer({
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

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get committee => $composableBuilder(
    column: $table.committee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfficersTableOrderingComposer
    extends Composer<_$AuditDatabase, $OfficersTable> {
  $$OfficersTableOrderingComposer({
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

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get committee => $composableBuilder(
    column: $table.committee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfficersTableAnnotationComposer
    extends Composer<_$AuditDatabase, $OfficersTable> {
  $$OfficersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get committee =>
      $composableBuilder(column: $table.committee, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );
}

class $$OfficersTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $OfficersTable,
          OfficerRecord,
          $$OfficersTableFilterComposer,
          $$OfficersTableOrderingComposer,
          $$OfficersTableAnnotationComposer,
          $$OfficersTableCreateCompanionBuilder,
          $$OfficersTableUpdateCompanionBuilder,
          (
            OfficerRecord,
            BaseReferences<_$AuditDatabase, $OfficersTable, OfficerRecord>,
          ),
          OfficerRecord,
          PrefetchHooks Function()
        > {
  $$OfficersTableTableManager(_$AuditDatabase db, $OfficersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfficersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfficersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfficersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String> position = const Value.absent(),
                Value<String?> committee = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfficersCompanion(
                id: id,
                fullName: fullName,
                position: position,
                committee: committee,
                isArchived: isArchived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fullName,
                required String position,
                Value<String?> committee = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfficersCompanion.insert(
                id: id,
                fullName: fullName,
                position: position,
                committee: committee,
                isArchived: isArchived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfficersTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $OfficersTable,
      OfficerRecord,
      $$OfficersTableFilterComposer,
      $$OfficersTableOrderingComposer,
      $$OfficersTableAnnotationComposer,
      $$OfficersTableCreateCompanionBuilder,
      $$OfficersTableUpdateCompanionBuilder,
      (
        OfficerRecord,
        BaseReferences<_$AuditDatabase, $OfficersTable, OfficerRecord>,
      ),
      OfficerRecord,
      PrefetchHooks Function()
    >;
typedef $$TreasuryFundSourcesTableCreateCompanionBuilder =
    TreasuryFundSourcesCompanion Function({
      required String id,
      required String type,
      required String label,
      required int balanceCentavos,
      Value<String?> supportingAttachmentId,
      Value<String?> supportingAttachmentFileName,
      Value<String?> supportingAttachmentLocalPath,
      Value<int?> supportingAttachmentSizeBytes,
      Value<String?> supportingAttachmentChecksum,
      Value<int> rowid,
    });
typedef $$TreasuryFundSourcesTableUpdateCompanionBuilder =
    TreasuryFundSourcesCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> label,
      Value<int> balanceCentavos,
      Value<String?> supportingAttachmentId,
      Value<String?> supportingAttachmentFileName,
      Value<String?> supportingAttachmentLocalPath,
      Value<int?> supportingAttachmentSizeBytes,
      Value<String?> supportingAttachmentChecksum,
      Value<int> rowid,
    });

class $$TreasuryFundSourcesTableFilterComposer
    extends Composer<_$AuditDatabase, $TreasuryFundSourcesTable> {
  $$TreasuryFundSourcesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceCentavos => $composableBuilder(
    column: $table.balanceCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supportingAttachmentId => $composableBuilder(
    column: $table.supportingAttachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supportingAttachmentFileName => $composableBuilder(
    column: $table.supportingAttachmentFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supportingAttachmentLocalPath => $composableBuilder(
    column: $table.supportingAttachmentLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get supportingAttachmentSizeBytes => $composableBuilder(
    column: $table.supportingAttachmentSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supportingAttachmentChecksum => $composableBuilder(
    column: $table.supportingAttachmentChecksum,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TreasuryFundSourcesTableOrderingComposer
    extends Composer<_$AuditDatabase, $TreasuryFundSourcesTable> {
  $$TreasuryFundSourcesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceCentavos => $composableBuilder(
    column: $table.balanceCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supportingAttachmentId => $composableBuilder(
    column: $table.supportingAttachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supportingAttachmentFileName =>
      $composableBuilder(
        column: $table.supportingAttachmentFileName,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get supportingAttachmentLocalPath =>
      $composableBuilder(
        column: $table.supportingAttachmentLocalPath,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get supportingAttachmentSizeBytes => $composableBuilder(
    column: $table.supportingAttachmentSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supportingAttachmentChecksum =>
      $composableBuilder(
        column: $table.supportingAttachmentChecksum,
        builder: (column) => ColumnOrderings(column),
      );
}

class $$TreasuryFundSourcesTableAnnotationComposer
    extends Composer<_$AuditDatabase, $TreasuryFundSourcesTable> {
  $$TreasuryFundSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get balanceCentavos => $composableBuilder(
    column: $table.balanceCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supportingAttachmentId => $composableBuilder(
    column: $table.supportingAttachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supportingAttachmentFileName =>
      $composableBuilder(
        column: $table.supportingAttachmentFileName,
        builder: (column) => column,
      );

  GeneratedColumn<String> get supportingAttachmentLocalPath =>
      $composableBuilder(
        column: $table.supportingAttachmentLocalPath,
        builder: (column) => column,
      );

  GeneratedColumn<int> get supportingAttachmentSizeBytes => $composableBuilder(
    column: $table.supportingAttachmentSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supportingAttachmentChecksum =>
      $composableBuilder(
        column: $table.supportingAttachmentChecksum,
        builder: (column) => column,
      );
}

class $$TreasuryFundSourcesTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $TreasuryFundSourcesTable,
          TreasuryFundSourceRecord,
          $$TreasuryFundSourcesTableFilterComposer,
          $$TreasuryFundSourcesTableOrderingComposer,
          $$TreasuryFundSourcesTableAnnotationComposer,
          $$TreasuryFundSourcesTableCreateCompanionBuilder,
          $$TreasuryFundSourcesTableUpdateCompanionBuilder,
          (
            TreasuryFundSourceRecord,
            BaseReferences<
              _$AuditDatabase,
              $TreasuryFundSourcesTable,
              TreasuryFundSourceRecord
            >,
          ),
          TreasuryFundSourceRecord,
          PrefetchHooks Function()
        > {
  $$TreasuryFundSourcesTableTableManager(
    _$AuditDatabase db,
    $TreasuryFundSourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TreasuryFundSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TreasuryFundSourcesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TreasuryFundSourcesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> balanceCentavos = const Value.absent(),
                Value<String?> supportingAttachmentId = const Value.absent(),
                Value<String?> supportingAttachmentFileName =
                    const Value.absent(),
                Value<String?> supportingAttachmentLocalPath =
                    const Value.absent(),
                Value<int?> supportingAttachmentSizeBytes =
                    const Value.absent(),
                Value<String?> supportingAttachmentChecksum =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TreasuryFundSourcesCompanion(
                id: id,
                type: type,
                label: label,
                balanceCentavos: balanceCentavos,
                supportingAttachmentId: supportingAttachmentId,
                supportingAttachmentFileName: supportingAttachmentFileName,
                supportingAttachmentLocalPath: supportingAttachmentLocalPath,
                supportingAttachmentSizeBytes: supportingAttachmentSizeBytes,
                supportingAttachmentChecksum: supportingAttachmentChecksum,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String label,
                required int balanceCentavos,
                Value<String?> supportingAttachmentId = const Value.absent(),
                Value<String?> supportingAttachmentFileName =
                    const Value.absent(),
                Value<String?> supportingAttachmentLocalPath =
                    const Value.absent(),
                Value<int?> supportingAttachmentSizeBytes =
                    const Value.absent(),
                Value<String?> supportingAttachmentChecksum =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TreasuryFundSourcesCompanion.insert(
                id: id,
                type: type,
                label: label,
                balanceCentavos: balanceCentavos,
                supportingAttachmentId: supportingAttachmentId,
                supportingAttachmentFileName: supportingAttachmentFileName,
                supportingAttachmentLocalPath: supportingAttachmentLocalPath,
                supportingAttachmentSizeBytes: supportingAttachmentSizeBytes,
                supportingAttachmentChecksum: supportingAttachmentChecksum,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TreasuryFundSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $TreasuryFundSourcesTable,
      TreasuryFundSourceRecord,
      $$TreasuryFundSourcesTableFilterComposer,
      $$TreasuryFundSourcesTableOrderingComposer,
      $$TreasuryFundSourcesTableAnnotationComposer,
      $$TreasuryFundSourcesTableCreateCompanionBuilder,
      $$TreasuryFundSourcesTableUpdateCompanionBuilder,
      (
        TreasuryFundSourceRecord,
        BaseReferences<
          _$AuditDatabase,
          $TreasuryFundSourcesTable,
          TreasuryFundSourceRecord
        >,
      ),
      TreasuryFundSourceRecord,
      PrefetchHooks Function()
    >;
typedef $$AuditEventsTableCreateCompanionBuilder =
    AuditEventsCompanion Function({
      required String id,
      required String name,
      required String type,
      required String semester,
      required String schoolYear,
      required DateTime startDate,
      required DateTime endDate,
      Value<DateTime?> permitApprovalDate,
      required String resolutionNumber,
      required int budgetCentavos,
      required int approvedBudgetBalanceCentavos,
      Value<String?> resolutionAttachmentId,
      Value<String?> resolutionAttachmentFileName,
      Value<String?> resolutionAttachmentLocalPath,
      Value<int?> resolutionAttachmentSizeBytes,
      Value<String?> resolutionAttachmentChecksum,
      Value<bool> isLiquidated,
      Value<int> rowid,
    });
typedef $$AuditEventsTableUpdateCompanionBuilder =
    AuditEventsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<String> semester,
      Value<String> schoolYear,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<DateTime?> permitApprovalDate,
      Value<String> resolutionNumber,
      Value<int> budgetCentavos,
      Value<int> approvedBudgetBalanceCentavos,
      Value<String?> resolutionAttachmentId,
      Value<String?> resolutionAttachmentFileName,
      Value<String?> resolutionAttachmentLocalPath,
      Value<int?> resolutionAttachmentSizeBytes,
      Value<String?> resolutionAttachmentChecksum,
      Value<bool> isLiquidated,
      Value<int> rowid,
    });

class $$AuditEventsTableFilterComposer
    extends Composer<_$AuditDatabase, $AuditEventsTable> {
  $$AuditEventsTableFilterComposer({
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

  ColumnFilters<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get schoolYear => $composableBuilder(
    column: $table.schoolYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get permitApprovalDate => $composableBuilder(
    column: $table.permitApprovalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolutionNumber => $composableBuilder(
    column: $table.resolutionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get budgetCentavos => $composableBuilder(
    column: $table.budgetCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get approvedBudgetBalanceCentavos => $composableBuilder(
    column: $table.approvedBudgetBalanceCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolutionAttachmentId => $composableBuilder(
    column: $table.resolutionAttachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolutionAttachmentFileName => $composableBuilder(
    column: $table.resolutionAttachmentFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolutionAttachmentLocalPath => $composableBuilder(
    column: $table.resolutionAttachmentLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resolutionAttachmentSizeBytes => $composableBuilder(
    column: $table.resolutionAttachmentSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolutionAttachmentChecksum => $composableBuilder(
    column: $table.resolutionAttachmentChecksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLiquidated => $composableBuilder(
    column: $table.isLiquidated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditEventsTableOrderingComposer
    extends Composer<_$AuditDatabase, $AuditEventsTable> {
  $$AuditEventsTableOrderingComposer({
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

  ColumnOrderings<String> get semester => $composableBuilder(
    column: $table.semester,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get schoolYear => $composableBuilder(
    column: $table.schoolYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get permitApprovalDate => $composableBuilder(
    column: $table.permitApprovalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolutionNumber => $composableBuilder(
    column: $table.resolutionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get budgetCentavos => $composableBuilder(
    column: $table.budgetCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get approvedBudgetBalanceCentavos => $composableBuilder(
    column: $table.approvedBudgetBalanceCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolutionAttachmentId => $composableBuilder(
    column: $table.resolutionAttachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolutionAttachmentFileName =>
      $composableBuilder(
        column: $table.resolutionAttachmentFileName,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<String> get resolutionAttachmentLocalPath =>
      $composableBuilder(
        column: $table.resolutionAttachmentLocalPath,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<int> get resolutionAttachmentSizeBytes => $composableBuilder(
    column: $table.resolutionAttachmentSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolutionAttachmentChecksum =>
      $composableBuilder(
        column: $table.resolutionAttachmentChecksum,
        builder: (column) => ColumnOrderings(column),
      );

  ColumnOrderings<bool> get isLiquidated => $composableBuilder(
    column: $table.isLiquidated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditEventsTableAnnotationComposer
    extends Composer<_$AuditDatabase, $AuditEventsTable> {
  $$AuditEventsTableAnnotationComposer({
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

  GeneratedColumn<String> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  GeneratedColumn<String> get schoolYear => $composableBuilder(
    column: $table.schoolYear,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get permitApprovalDate => $composableBuilder(
    column: $table.permitApprovalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolutionNumber => $composableBuilder(
    column: $table.resolutionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get budgetCentavos => $composableBuilder(
    column: $table.budgetCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get approvedBudgetBalanceCentavos => $composableBuilder(
    column: $table.approvedBudgetBalanceCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolutionAttachmentId => $composableBuilder(
    column: $table.resolutionAttachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolutionAttachmentFileName =>
      $composableBuilder(
        column: $table.resolutionAttachmentFileName,
        builder: (column) => column,
      );

  GeneratedColumn<String> get resolutionAttachmentLocalPath =>
      $composableBuilder(
        column: $table.resolutionAttachmentLocalPath,
        builder: (column) => column,
      );

  GeneratedColumn<int> get resolutionAttachmentSizeBytes => $composableBuilder(
    column: $table.resolutionAttachmentSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolutionAttachmentChecksum =>
      $composableBuilder(
        column: $table.resolutionAttachmentChecksum,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get isLiquidated => $composableBuilder(
    column: $table.isLiquidated,
    builder: (column) => column,
  );
}

class $$AuditEventsTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $AuditEventsTable,
          AuditEventRecord,
          $$AuditEventsTableFilterComposer,
          $$AuditEventsTableOrderingComposer,
          $$AuditEventsTableAnnotationComposer,
          $$AuditEventsTableCreateCompanionBuilder,
          $$AuditEventsTableUpdateCompanionBuilder,
          (
            AuditEventRecord,
            BaseReferences<
              _$AuditDatabase,
              $AuditEventsTable,
              AuditEventRecord
            >,
          ),
          AuditEventRecord,
          PrefetchHooks Function()
        > {
  $$AuditEventsTableTableManager(_$AuditDatabase db, $AuditEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> semester = const Value.absent(),
                Value<String> schoolYear = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<DateTime?> permitApprovalDate = const Value.absent(),
                Value<String> resolutionNumber = const Value.absent(),
                Value<int> budgetCentavos = const Value.absent(),
                Value<int> approvedBudgetBalanceCentavos = const Value.absent(),
                Value<String?> resolutionAttachmentId = const Value.absent(),
                Value<String?> resolutionAttachmentFileName =
                    const Value.absent(),
                Value<String?> resolutionAttachmentLocalPath =
                    const Value.absent(),
                Value<int?> resolutionAttachmentSizeBytes =
                    const Value.absent(),
                Value<String?> resolutionAttachmentChecksum =
                    const Value.absent(),
                Value<bool> isLiquidated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditEventsCompanion(
                id: id,
                name: name,
                type: type,
                semester: semester,
                schoolYear: schoolYear,
                startDate: startDate,
                endDate: endDate,
                permitApprovalDate: permitApprovalDate,
                resolutionNumber: resolutionNumber,
                budgetCentavos: budgetCentavos,
                approvedBudgetBalanceCentavos: approvedBudgetBalanceCentavos,
                resolutionAttachmentId: resolutionAttachmentId,
                resolutionAttachmentFileName: resolutionAttachmentFileName,
                resolutionAttachmentLocalPath: resolutionAttachmentLocalPath,
                resolutionAttachmentSizeBytes: resolutionAttachmentSizeBytes,
                resolutionAttachmentChecksum: resolutionAttachmentChecksum,
                isLiquidated: isLiquidated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                required String semester,
                required String schoolYear,
                required DateTime startDate,
                required DateTime endDate,
                Value<DateTime?> permitApprovalDate = const Value.absent(),
                required String resolutionNumber,
                required int budgetCentavos,
                required int approvedBudgetBalanceCentavos,
                Value<String?> resolutionAttachmentId = const Value.absent(),
                Value<String?> resolutionAttachmentFileName =
                    const Value.absent(),
                Value<String?> resolutionAttachmentLocalPath =
                    const Value.absent(),
                Value<int?> resolutionAttachmentSizeBytes =
                    const Value.absent(),
                Value<String?> resolutionAttachmentChecksum =
                    const Value.absent(),
                Value<bool> isLiquidated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditEventsCompanion.insert(
                id: id,
                name: name,
                type: type,
                semester: semester,
                schoolYear: schoolYear,
                startDate: startDate,
                endDate: endDate,
                permitApprovalDate: permitApprovalDate,
                resolutionNumber: resolutionNumber,
                budgetCentavos: budgetCentavos,
                approvedBudgetBalanceCentavos: approvedBudgetBalanceCentavos,
                resolutionAttachmentId: resolutionAttachmentId,
                resolutionAttachmentFileName: resolutionAttachmentFileName,
                resolutionAttachmentLocalPath: resolutionAttachmentLocalPath,
                resolutionAttachmentSizeBytes: resolutionAttachmentSizeBytes,
                resolutionAttachmentChecksum: resolutionAttachmentChecksum,
                isLiquidated: isLiquidated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $AuditEventsTable,
      AuditEventRecord,
      $$AuditEventsTableFilterComposer,
      $$AuditEventsTableOrderingComposer,
      $$AuditEventsTableAnnotationComposer,
      $$AuditEventsTableCreateCompanionBuilder,
      $$AuditEventsTableUpdateCompanionBuilder,
      (
        AuditEventRecord,
        BaseReferences<_$AuditDatabase, $AuditEventsTable, AuditEventRecord>,
      ),
      AuditEventRecord,
      PrefetchHooks Function()
    >;
typedef $$EventFundingAllocationsTableCreateCompanionBuilder =
    EventFundingAllocationsCompanion Function({
      required String eventId,
      required String fundSourceId,
      required int amountCentavos,
      Value<int> rowid,
    });
typedef $$EventFundingAllocationsTableUpdateCompanionBuilder =
    EventFundingAllocationsCompanion Function({
      Value<String> eventId,
      Value<String> fundSourceId,
      Value<int> amountCentavos,
      Value<int> rowid,
    });

class $$EventFundingAllocationsTableFilterComposer
    extends Composer<_$AuditDatabase, $EventFundingAllocationsTable> {
  $$EventFundingAllocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fundSourceId => $composableBuilder(
    column: $table.fundSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventFundingAllocationsTableOrderingComposer
    extends Composer<_$AuditDatabase, $EventFundingAllocationsTable> {
  $$EventFundingAllocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fundSourceId => $composableBuilder(
    column: $table.fundSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventFundingAllocationsTableAnnotationComposer
    extends Composer<_$AuditDatabase, $EventFundingAllocationsTable> {
  $$EventFundingAllocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get fundSourceId => $composableBuilder(
    column: $table.fundSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => column,
  );
}

class $$EventFundingAllocationsTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $EventFundingAllocationsTable,
          EventFundingAllocationRecord,
          $$EventFundingAllocationsTableFilterComposer,
          $$EventFundingAllocationsTableOrderingComposer,
          $$EventFundingAllocationsTableAnnotationComposer,
          $$EventFundingAllocationsTableCreateCompanionBuilder,
          $$EventFundingAllocationsTableUpdateCompanionBuilder,
          (
            EventFundingAllocationRecord,
            BaseReferences<
              _$AuditDatabase,
              $EventFundingAllocationsTable,
              EventFundingAllocationRecord
            >,
          ),
          EventFundingAllocationRecord,
          PrefetchHooks Function()
        > {
  $$EventFundingAllocationsTableTableManager(
    _$AuditDatabase db,
    $EventFundingAllocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventFundingAllocationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$EventFundingAllocationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EventFundingAllocationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> fundSourceId = const Value.absent(),
                Value<int> amountCentavos = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventFundingAllocationsCompanion(
                eventId: eventId,
                fundSourceId: fundSourceId,
                amountCentavos: amountCentavos,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String fundSourceId,
                required int amountCentavos,
                Value<int> rowid = const Value.absent(),
              }) => EventFundingAllocationsCompanion.insert(
                eventId: eventId,
                fundSourceId: fundSourceId,
                amountCentavos: amountCentavos,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventFundingAllocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $EventFundingAllocationsTable,
      EventFundingAllocationRecord,
      $$EventFundingAllocationsTableFilterComposer,
      $$EventFundingAllocationsTableOrderingComposer,
      $$EventFundingAllocationsTableAnnotationComposer,
      $$EventFundingAllocationsTableCreateCompanionBuilder,
      $$EventFundingAllocationsTableUpdateCompanionBuilder,
      (
        EventFundingAllocationRecord,
        BaseReferences<
          _$AuditDatabase,
          $EventFundingAllocationsTable,
          EventFundingAllocationRecord
        >,
      ),
      EventFundingAllocationRecord,
      PrefetchHooks Function()
    >;
typedef $$FundMovementsTableCreateCompanionBuilder =
    FundMovementsCompanion Function({
      required String id,
      required String reference,
      required String type,
      required DateTime date,
      required int amountCentavos,
      required String purpose,
      Value<String?> remarks,
      Value<String?> eventId,
      Value<String?> fromFundSourceId,
      Value<String?> toFundSourceId,
      Value<String?> holderOfficerId,
      required bool isSystemGenerated,
      Value<int> rowid,
    });
typedef $$FundMovementsTableUpdateCompanionBuilder =
    FundMovementsCompanion Function({
      Value<String> id,
      Value<String> reference,
      Value<String> type,
      Value<DateTime> date,
      Value<int> amountCentavos,
      Value<String> purpose,
      Value<String?> remarks,
      Value<String?> eventId,
      Value<String?> fromFundSourceId,
      Value<String?> toFundSourceId,
      Value<String?> holderOfficerId,
      Value<bool> isSystemGenerated,
      Value<int> rowid,
    });

class $$FundMovementsTableFilterComposer
    extends Composer<_$AuditDatabase, $FundMovementsTable> {
  $$FundMovementsTableFilterComposer({
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

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromFundSourceId => $composableBuilder(
    column: $table.fromFundSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toFundSourceId => $composableBuilder(
    column: $table.toFundSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get holderOfficerId => $composableBuilder(
    column: $table.holderOfficerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystemGenerated => $composableBuilder(
    column: $table.isSystemGenerated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FundMovementsTableOrderingComposer
    extends Composer<_$AuditDatabase, $FundMovementsTable> {
  $$FundMovementsTableOrderingComposer({
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

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromFundSourceId => $composableBuilder(
    column: $table.fromFundSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toFundSourceId => $composableBuilder(
    column: $table.toFundSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get holderOfficerId => $composableBuilder(
    column: $table.holderOfficerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystemGenerated => $composableBuilder(
    column: $table.isSystemGenerated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FundMovementsTableAnnotationComposer
    extends Composer<_$AuditDatabase, $FundMovementsTable> {
  $$FundMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get fromFundSourceId => $composableBuilder(
    column: $table.fromFundSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toFundSourceId => $composableBuilder(
    column: $table.toFundSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get holderOfficerId => $composableBuilder(
    column: $table.holderOfficerId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSystemGenerated => $composableBuilder(
    column: $table.isSystemGenerated,
    builder: (column) => column,
  );
}

class $$FundMovementsTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $FundMovementsTable,
          FundMovementRecord,
          $$FundMovementsTableFilterComposer,
          $$FundMovementsTableOrderingComposer,
          $$FundMovementsTableAnnotationComposer,
          $$FundMovementsTableCreateCompanionBuilder,
          $$FundMovementsTableUpdateCompanionBuilder,
          (
            FundMovementRecord,
            BaseReferences<
              _$AuditDatabase,
              $FundMovementsTable,
              FundMovementRecord
            >,
          ),
          FundMovementRecord,
          PrefetchHooks Function()
        > {
  $$FundMovementsTableTableManager(
    _$AuditDatabase db,
    $FundMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FundMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FundMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FundMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> amountCentavos = const Value.absent(),
                Value<String> purpose = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<String?> fromFundSourceId = const Value.absent(),
                Value<String?> toFundSourceId = const Value.absent(),
                Value<String?> holderOfficerId = const Value.absent(),
                Value<bool> isSystemGenerated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FundMovementsCompanion(
                id: id,
                reference: reference,
                type: type,
                date: date,
                amountCentavos: amountCentavos,
                purpose: purpose,
                remarks: remarks,
                eventId: eventId,
                fromFundSourceId: fromFundSourceId,
                toFundSourceId: toFundSourceId,
                holderOfficerId: holderOfficerId,
                isSystemGenerated: isSystemGenerated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String reference,
                required String type,
                required DateTime date,
                required int amountCentavos,
                required String purpose,
                Value<String?> remarks = const Value.absent(),
                Value<String?> eventId = const Value.absent(),
                Value<String?> fromFundSourceId = const Value.absent(),
                Value<String?> toFundSourceId = const Value.absent(),
                Value<String?> holderOfficerId = const Value.absent(),
                required bool isSystemGenerated,
                Value<int> rowid = const Value.absent(),
              }) => FundMovementsCompanion.insert(
                id: id,
                reference: reference,
                type: type,
                date: date,
                amountCentavos: amountCentavos,
                purpose: purpose,
                remarks: remarks,
                eventId: eventId,
                fromFundSourceId: fromFundSourceId,
                toFundSourceId: toFundSourceId,
                holderOfficerId: holderOfficerId,
                isSystemGenerated: isSystemGenerated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FundMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $FundMovementsTable,
      FundMovementRecord,
      $$FundMovementsTableFilterComposer,
      $$FundMovementsTableOrderingComposer,
      $$FundMovementsTableAnnotationComposer,
      $$FundMovementsTableCreateCompanionBuilder,
      $$FundMovementsTableUpdateCompanionBuilder,
      (
        FundMovementRecord,
        BaseReferences<
          _$AuditDatabase,
          $FundMovementsTable,
          FundMovementRecord
        >,
      ),
      FundMovementRecord,
      PrefetchHooks Function()
    >;
typedef $$LiquidationReceiptsTableCreateCompanionBuilder =
    LiquidationReceiptsCompanion Function({
      required String id,
      required String eventId,
      required String payeeOrMerchant,
      required DateTime date,
      required String evidenceNumber,
      required String receiptType,
      required String fundingMode,
      required String accountableOfficerId,
      required String attachmentId,
      required String attachmentFileName,
      required String attachmentLocalPath,
      Value<int?> attachmentSizeBytes,
      Value<String?> attachmentChecksum,
      Value<int> rowid,
    });
typedef $$LiquidationReceiptsTableUpdateCompanionBuilder =
    LiquidationReceiptsCompanion Function({
      Value<String> id,
      Value<String> eventId,
      Value<String> payeeOrMerchant,
      Value<DateTime> date,
      Value<String> evidenceNumber,
      Value<String> receiptType,
      Value<String> fundingMode,
      Value<String> accountableOfficerId,
      Value<String> attachmentId,
      Value<String> attachmentFileName,
      Value<String> attachmentLocalPath,
      Value<int?> attachmentSizeBytes,
      Value<String?> attachmentChecksum,
      Value<int> rowid,
    });

class $$LiquidationReceiptsTableFilterComposer
    extends Composer<_$AuditDatabase, $LiquidationReceiptsTable> {
  $$LiquidationReceiptsTableFilterComposer({
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

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payeeOrMerchant => $composableBuilder(
    column: $table.payeeOrMerchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidenceNumber => $composableBuilder(
    column: $table.evidenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptType => $composableBuilder(
    column: $table.receiptType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fundingMode => $composableBuilder(
    column: $table.fundingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountableOfficerId => $composableBuilder(
    column: $table.accountableOfficerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentFileName => $composableBuilder(
    column: $table.attachmentFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentLocalPath => $composableBuilder(
    column: $table.attachmentLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attachmentSizeBytes => $composableBuilder(
    column: $table.attachmentSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentChecksum => $composableBuilder(
    column: $table.attachmentChecksum,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LiquidationReceiptsTableOrderingComposer
    extends Composer<_$AuditDatabase, $LiquidationReceiptsTable> {
  $$LiquidationReceiptsTableOrderingComposer({
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

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payeeOrMerchant => $composableBuilder(
    column: $table.payeeOrMerchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidenceNumber => $composableBuilder(
    column: $table.evidenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptType => $composableBuilder(
    column: $table.receiptType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fundingMode => $composableBuilder(
    column: $table.fundingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountableOfficerId => $composableBuilder(
    column: $table.accountableOfficerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentFileName => $composableBuilder(
    column: $table.attachmentFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentLocalPath => $composableBuilder(
    column: $table.attachmentLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attachmentSizeBytes => $composableBuilder(
    column: $table.attachmentSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentChecksum => $composableBuilder(
    column: $table.attachmentChecksum,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LiquidationReceiptsTableAnnotationComposer
    extends Composer<_$AuditDatabase, $LiquidationReceiptsTable> {
  $$LiquidationReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get payeeOrMerchant => $composableBuilder(
    column: $table.payeeOrMerchant,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get evidenceNumber => $composableBuilder(
    column: $table.evidenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptType => $composableBuilder(
    column: $table.receiptType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fundingMode => $composableBuilder(
    column: $table.fundingMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountableOfficerId => $composableBuilder(
    column: $table.accountableOfficerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentFileName => $composableBuilder(
    column: $table.attachmentFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentLocalPath => $composableBuilder(
    column: $table.attachmentLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attachmentSizeBytes => $composableBuilder(
    column: $table.attachmentSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentChecksum => $composableBuilder(
    column: $table.attachmentChecksum,
    builder: (column) => column,
  );
}

class $$LiquidationReceiptsTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $LiquidationReceiptsTable,
          LiquidationReceiptRecord,
          $$LiquidationReceiptsTableFilterComposer,
          $$LiquidationReceiptsTableOrderingComposer,
          $$LiquidationReceiptsTableAnnotationComposer,
          $$LiquidationReceiptsTableCreateCompanionBuilder,
          $$LiquidationReceiptsTableUpdateCompanionBuilder,
          (
            LiquidationReceiptRecord,
            BaseReferences<
              _$AuditDatabase,
              $LiquidationReceiptsTable,
              LiquidationReceiptRecord
            >,
          ),
          LiquidationReceiptRecord,
          PrefetchHooks Function()
        > {
  $$LiquidationReceiptsTableTableManager(
    _$AuditDatabase db,
    $LiquidationReceiptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiquidationReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiquidationReceiptsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LiquidationReceiptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> payeeOrMerchant = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> evidenceNumber = const Value.absent(),
                Value<String> receiptType = const Value.absent(),
                Value<String> fundingMode = const Value.absent(),
                Value<String> accountableOfficerId = const Value.absent(),
                Value<String> attachmentId = const Value.absent(),
                Value<String> attachmentFileName = const Value.absent(),
                Value<String> attachmentLocalPath = const Value.absent(),
                Value<int?> attachmentSizeBytes = const Value.absent(),
                Value<String?> attachmentChecksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiquidationReceiptsCompanion(
                id: id,
                eventId: eventId,
                payeeOrMerchant: payeeOrMerchant,
                date: date,
                evidenceNumber: evidenceNumber,
                receiptType: receiptType,
                fundingMode: fundingMode,
                accountableOfficerId: accountableOfficerId,
                attachmentId: attachmentId,
                attachmentFileName: attachmentFileName,
                attachmentLocalPath: attachmentLocalPath,
                attachmentSizeBytes: attachmentSizeBytes,
                attachmentChecksum: attachmentChecksum,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventId,
                required String payeeOrMerchant,
                required DateTime date,
                required String evidenceNumber,
                required String receiptType,
                required String fundingMode,
                required String accountableOfficerId,
                required String attachmentId,
                required String attachmentFileName,
                required String attachmentLocalPath,
                Value<int?> attachmentSizeBytes = const Value.absent(),
                Value<String?> attachmentChecksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiquidationReceiptsCompanion.insert(
                id: id,
                eventId: eventId,
                payeeOrMerchant: payeeOrMerchant,
                date: date,
                evidenceNumber: evidenceNumber,
                receiptType: receiptType,
                fundingMode: fundingMode,
                accountableOfficerId: accountableOfficerId,
                attachmentId: attachmentId,
                attachmentFileName: attachmentFileName,
                attachmentLocalPath: attachmentLocalPath,
                attachmentSizeBytes: attachmentSizeBytes,
                attachmentChecksum: attachmentChecksum,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LiquidationReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $LiquidationReceiptsTable,
      LiquidationReceiptRecord,
      $$LiquidationReceiptsTableFilterComposer,
      $$LiquidationReceiptsTableOrderingComposer,
      $$LiquidationReceiptsTableAnnotationComposer,
      $$LiquidationReceiptsTableCreateCompanionBuilder,
      $$LiquidationReceiptsTableUpdateCompanionBuilder,
      (
        LiquidationReceiptRecord,
        BaseReferences<
          _$AuditDatabase,
          $LiquidationReceiptsTable,
          LiquidationReceiptRecord
        >,
      ),
      LiquidationReceiptRecord,
      PrefetchHooks Function()
    >;
typedef $$LiquidationLinesTableCreateCompanionBuilder =
    LiquidationLinesCompanion Function({
      required String id,
      required String receiptId,
      required String description,
      required int quantity,
      required int unitCostCentavos,
      Value<int> rowid,
    });
typedef $$LiquidationLinesTableUpdateCompanionBuilder =
    LiquidationLinesCompanion Function({
      Value<String> id,
      Value<String> receiptId,
      Value<String> description,
      Value<int> quantity,
      Value<int> unitCostCentavos,
      Value<int> rowid,
    });

class $$LiquidationLinesTableFilterComposer
    extends Composer<_$AuditDatabase, $LiquidationLinesTable> {
  $$LiquidationLinesTableFilterComposer({
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

  ColumnFilters<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitCostCentavos => $composableBuilder(
    column: $table.unitCostCentavos,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LiquidationLinesTableOrderingComposer
    extends Composer<_$AuditDatabase, $LiquidationLinesTable> {
  $$LiquidationLinesTableOrderingComposer({
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

  ColumnOrderings<String> get receiptId => $composableBuilder(
    column: $table.receiptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitCostCentavos => $composableBuilder(
    column: $table.unitCostCentavos,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LiquidationLinesTableAnnotationComposer
    extends Composer<_$AuditDatabase, $LiquidationLinesTable> {
  $$LiquidationLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get receiptId =>
      $composableBuilder(column: $table.receiptId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get unitCostCentavos => $composableBuilder(
    column: $table.unitCostCentavos,
    builder: (column) => column,
  );
}

class $$LiquidationLinesTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $LiquidationLinesTable,
          LiquidationLineRecord,
          $$LiquidationLinesTableFilterComposer,
          $$LiquidationLinesTableOrderingComposer,
          $$LiquidationLinesTableAnnotationComposer,
          $$LiquidationLinesTableCreateCompanionBuilder,
          $$LiquidationLinesTableUpdateCompanionBuilder,
          (
            LiquidationLineRecord,
            BaseReferences<
              _$AuditDatabase,
              $LiquidationLinesTable,
              LiquidationLineRecord
            >,
          ),
          LiquidationLineRecord,
          PrefetchHooks Function()
        > {
  $$LiquidationLinesTableTableManager(
    _$AuditDatabase db,
    $LiquidationLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiquidationLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiquidationLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiquidationLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> receiptId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> unitCostCentavos = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiquidationLinesCompanion(
                id: id,
                receiptId: receiptId,
                description: description,
                quantity: quantity,
                unitCostCentavos: unitCostCentavos,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String receiptId,
                required String description,
                required int quantity,
                required int unitCostCentavos,
                Value<int> rowid = const Value.absent(),
              }) => LiquidationLinesCompanion.insert(
                id: id,
                receiptId: receiptId,
                description: description,
                quantity: quantity,
                unitCostCentavos: unitCostCentavos,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LiquidationLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $LiquidationLinesTable,
      LiquidationLineRecord,
      $$LiquidationLinesTableFilterComposer,
      $$LiquidationLinesTableOrderingComposer,
      $$LiquidationLinesTableAnnotationComposer,
      $$LiquidationLinesTableCreateCompanionBuilder,
      $$LiquidationLinesTableUpdateCompanionBuilder,
      (
        LiquidationLineRecord,
        BaseReferences<
          _$AuditDatabase,
          $LiquidationLinesTable,
          LiquidationLineRecord
        >,
      ),
      LiquidationLineRecord,
      PrefetchHooks Function()
    >;
typedef $$ReimbursementClaimsTableCreateCompanionBuilder =
    ReimbursementClaimsCompanion Function({
      required String id,
      required String eventId,
      required String officerId,
      required int amountCentavos,
      required String status,
      required String sourceLiquidationLineId,
      Value<int> rowid,
    });
typedef $$ReimbursementClaimsTableUpdateCompanionBuilder =
    ReimbursementClaimsCompanion Function({
      Value<String> id,
      Value<String> eventId,
      Value<String> officerId,
      Value<int> amountCentavos,
      Value<String> status,
      Value<String> sourceLiquidationLineId,
      Value<int> rowid,
    });

class $$ReimbursementClaimsTableFilterComposer
    extends Composer<_$AuditDatabase, $ReimbursementClaimsTable> {
  $$ReimbursementClaimsTableFilterComposer({
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

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get officerId => $composableBuilder(
    column: $table.officerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLiquidationLineId => $composableBuilder(
    column: $table.sourceLiquidationLineId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReimbursementClaimsTableOrderingComposer
    extends Composer<_$AuditDatabase, $ReimbursementClaimsTable> {
  $$ReimbursementClaimsTableOrderingComposer({
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

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get officerId => $composableBuilder(
    column: $table.officerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLiquidationLineId => $composableBuilder(
    column: $table.sourceLiquidationLineId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReimbursementClaimsTableAnnotationComposer
    extends Composer<_$AuditDatabase, $ReimbursementClaimsTable> {
  $$ReimbursementClaimsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get officerId =>
      $composableBuilder(column: $table.officerId, builder: (column) => column);

  GeneratedColumn<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get sourceLiquidationLineId => $composableBuilder(
    column: $table.sourceLiquidationLineId,
    builder: (column) => column,
  );
}

class $$ReimbursementClaimsTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $ReimbursementClaimsTable,
          ReimbursementClaimRecord,
          $$ReimbursementClaimsTableFilterComposer,
          $$ReimbursementClaimsTableOrderingComposer,
          $$ReimbursementClaimsTableAnnotationComposer,
          $$ReimbursementClaimsTableCreateCompanionBuilder,
          $$ReimbursementClaimsTableUpdateCompanionBuilder,
          (
            ReimbursementClaimRecord,
            BaseReferences<
              _$AuditDatabase,
              $ReimbursementClaimsTable,
              ReimbursementClaimRecord
            >,
          ),
          ReimbursementClaimRecord,
          PrefetchHooks Function()
        > {
  $$ReimbursementClaimsTableTableManager(
    _$AuditDatabase db,
    $ReimbursementClaimsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReimbursementClaimsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReimbursementClaimsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReimbursementClaimsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> officerId = const Value.absent(),
                Value<int> amountCentavos = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> sourceLiquidationLineId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReimbursementClaimsCompanion(
                id: id,
                eventId: eventId,
                officerId: officerId,
                amountCentavos: amountCentavos,
                status: status,
                sourceLiquidationLineId: sourceLiquidationLineId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventId,
                required String officerId,
                required int amountCentavos,
                required String status,
                required String sourceLiquidationLineId,
                Value<int> rowid = const Value.absent(),
              }) => ReimbursementClaimsCompanion.insert(
                id: id,
                eventId: eventId,
                officerId: officerId,
                amountCentavos: amountCentavos,
                status: status,
                sourceLiquidationLineId: sourceLiquidationLineId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReimbursementClaimsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $ReimbursementClaimsTable,
      ReimbursementClaimRecord,
      $$ReimbursementClaimsTableFilterComposer,
      $$ReimbursementClaimsTableOrderingComposer,
      $$ReimbursementClaimsTableAnnotationComposer,
      $$ReimbursementClaimsTableCreateCompanionBuilder,
      $$ReimbursementClaimsTableUpdateCompanionBuilder,
      (
        ReimbursementClaimRecord,
        BaseReferences<
          _$AuditDatabase,
          $ReimbursementClaimsTable,
          ReimbursementClaimRecord
        >,
      ),
      ReimbursementClaimRecord,
      PrefetchHooks Function()
    >;
typedef $$AuditorReviewsTableCreateCompanionBuilder =
    AuditorReviewsCompanion Function({
      required String id,
      required String eventId,
      required String findings,
      required String cause,
      required String recommendation,
      required int budgetCentavos,
      required int actualCentavos,
      required int varianceCentavos,
      required int utilizationBasisPoints,
      required String health,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AuditorReviewsTableUpdateCompanionBuilder =
    AuditorReviewsCompanion Function({
      Value<String> id,
      Value<String> eventId,
      Value<String> findings,
      Value<String> cause,
      Value<String> recommendation,
      Value<int> budgetCentavos,
      Value<int> actualCentavos,
      Value<int> varianceCentavos,
      Value<int> utilizationBasisPoints,
      Value<String> health,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AuditorReviewsTableFilterComposer
    extends Composer<_$AuditDatabase, $AuditorReviewsTable> {
  $$AuditorReviewsTableFilterComposer({
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

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get findings => $composableBuilder(
    column: $table.findings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cause => $composableBuilder(
    column: $table.cause,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendation => $composableBuilder(
    column: $table.recommendation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get budgetCentavos => $composableBuilder(
    column: $table.budgetCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualCentavos => $composableBuilder(
    column: $table.actualCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get varianceCentavos => $composableBuilder(
    column: $table.varianceCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get utilizationBasisPoints => $composableBuilder(
    column: $table.utilizationBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get health => $composableBuilder(
    column: $table.health,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditorReviewsTableOrderingComposer
    extends Composer<_$AuditDatabase, $AuditorReviewsTable> {
  $$AuditorReviewsTableOrderingComposer({
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

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get findings => $composableBuilder(
    column: $table.findings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cause => $composableBuilder(
    column: $table.cause,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendation => $composableBuilder(
    column: $table.recommendation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get budgetCentavos => $composableBuilder(
    column: $table.budgetCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualCentavos => $composableBuilder(
    column: $table.actualCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get varianceCentavos => $composableBuilder(
    column: $table.varianceCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get utilizationBasisPoints => $composableBuilder(
    column: $table.utilizationBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get health => $composableBuilder(
    column: $table.health,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditorReviewsTableAnnotationComposer
    extends Composer<_$AuditDatabase, $AuditorReviewsTable> {
  $$AuditorReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get findings =>
      $composableBuilder(column: $table.findings, builder: (column) => column);

  GeneratedColumn<String> get cause =>
      $composableBuilder(column: $table.cause, builder: (column) => column);

  GeneratedColumn<String> get recommendation => $composableBuilder(
    column: $table.recommendation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get budgetCentavos => $composableBuilder(
    column: $table.budgetCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualCentavos => $composableBuilder(
    column: $table.actualCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get varianceCentavos => $composableBuilder(
    column: $table.varianceCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<int> get utilizationBasisPoints => $composableBuilder(
    column: $table.utilizationBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumn<String> get health =>
      $composableBuilder(column: $table.health, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AuditorReviewsTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $AuditorReviewsTable,
          AuditorReviewRecord,
          $$AuditorReviewsTableFilterComposer,
          $$AuditorReviewsTableOrderingComposer,
          $$AuditorReviewsTableAnnotationComposer,
          $$AuditorReviewsTableCreateCompanionBuilder,
          $$AuditorReviewsTableUpdateCompanionBuilder,
          (
            AuditorReviewRecord,
            BaseReferences<
              _$AuditDatabase,
              $AuditorReviewsTable,
              AuditorReviewRecord
            >,
          ),
          AuditorReviewRecord,
          PrefetchHooks Function()
        > {
  $$AuditorReviewsTableTableManager(
    _$AuditDatabase db,
    $AuditorReviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditorReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditorReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditorReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> findings = const Value.absent(),
                Value<String> cause = const Value.absent(),
                Value<String> recommendation = const Value.absent(),
                Value<int> budgetCentavos = const Value.absent(),
                Value<int> actualCentavos = const Value.absent(),
                Value<int> varianceCentavos = const Value.absent(),
                Value<int> utilizationBasisPoints = const Value.absent(),
                Value<String> health = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditorReviewsCompanion(
                id: id,
                eventId: eventId,
                findings: findings,
                cause: cause,
                recommendation: recommendation,
                budgetCentavos: budgetCentavos,
                actualCentavos: actualCentavos,
                varianceCentavos: varianceCentavos,
                utilizationBasisPoints: utilizationBasisPoints,
                health: health,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventId,
                required String findings,
                required String cause,
                required String recommendation,
                required int budgetCentavos,
                required int actualCentavos,
                required int varianceCentavos,
                required int utilizationBasisPoints,
                required String health,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AuditorReviewsCompanion.insert(
                id: id,
                eventId: eventId,
                findings: findings,
                cause: cause,
                recommendation: recommendation,
                budgetCentavos: budgetCentavos,
                actualCentavos: actualCentavos,
                varianceCentavos: varianceCentavos,
                utilizationBasisPoints: utilizationBasisPoints,
                health: health,
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

typedef $$AuditorReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $AuditorReviewsTable,
      AuditorReviewRecord,
      $$AuditorReviewsTableFilterComposer,
      $$AuditorReviewsTableOrderingComposer,
      $$AuditorReviewsTableAnnotationComposer,
      $$AuditorReviewsTableCreateCompanionBuilder,
      $$AuditorReviewsTableUpdateCompanionBuilder,
      (
        AuditorReviewRecord,
        BaseReferences<
          _$AuditDatabase,
          $AuditorReviewsTable,
          AuditorReviewRecord
        >,
      ),
      AuditorReviewRecord,
      PrefetchHooks Function()
    >;
typedef $$AuditLogEntriesTableCreateCompanionBuilder =
    AuditLogEntriesCompanion Function({
      required String id,
      required String action,
      required String actor,
      required String targetRecordId,
      required DateTime occurredAt,
      Value<int?> amountCentavos,
      Value<String?> reference,
      Value<String?> beforeSnapshotJson,
      Value<String?> afterSnapshotJson,
      Value<String> metadataJson,
      Value<int> rowid,
    });
typedef $$AuditLogEntriesTableUpdateCompanionBuilder =
    AuditLogEntriesCompanion Function({
      Value<String> id,
      Value<String> action,
      Value<String> actor,
      Value<String> targetRecordId,
      Value<DateTime> occurredAt,
      Value<int?> amountCentavos,
      Value<String?> reference,
      Value<String?> beforeSnapshotJson,
      Value<String?> afterSnapshotJson,
      Value<String> metadataJson,
      Value<int> rowid,
    });

class $$AuditLogEntriesTableFilterComposer
    extends Composer<_$AuditDatabase, $AuditLogEntriesTable> {
  $$AuditLogEntriesTableFilterComposer({
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

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetRecordId => $composableBuilder(
    column: $table.targetRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beforeSnapshotJson => $composableBuilder(
    column: $table.beforeSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get afterSnapshotJson => $composableBuilder(
    column: $table.afterSnapshotJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogEntriesTableOrderingComposer
    extends Composer<_$AuditDatabase, $AuditLogEntriesTable> {
  $$AuditLogEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetRecordId => $composableBuilder(
    column: $table.targetRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beforeSnapshotJson => $composableBuilder(
    column: $table.beforeSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get afterSnapshotJson => $composableBuilder(
    column: $table.afterSnapshotJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogEntriesTableAnnotationComposer
    extends Composer<_$AuditDatabase, $AuditLogEntriesTable> {
  $$AuditLogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);

  GeneratedColumn<String> get targetRecordId => $composableBuilder(
    column: $table.targetRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountCentavos => $composableBuilder(
    column: $table.amountCentavos,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get beforeSnapshotJson => $composableBuilder(
    column: $table.beforeSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get afterSnapshotJson => $composableBuilder(
    column: $table.afterSnapshotJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );
}

class $$AuditLogEntriesTableTableManager
    extends
        RootTableManager<
          _$AuditDatabase,
          $AuditLogEntriesTable,
          AuditLogRecord,
          $$AuditLogEntriesTableFilterComposer,
          $$AuditLogEntriesTableOrderingComposer,
          $$AuditLogEntriesTableAnnotationComposer,
          $$AuditLogEntriesTableCreateCompanionBuilder,
          $$AuditLogEntriesTableUpdateCompanionBuilder,
          (
            AuditLogRecord,
            BaseReferences<
              _$AuditDatabase,
              $AuditLogEntriesTable,
              AuditLogRecord
            >,
          ),
          AuditLogRecord,
          PrefetchHooks Function()
        > {
  $$AuditLogEntriesTableTableManager(
    _$AuditDatabase db,
    $AuditLogEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> actor = const Value.absent(),
                Value<String> targetRecordId = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int?> amountCentavos = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> beforeSnapshotJson = const Value.absent(),
                Value<String?> afterSnapshotJson = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogEntriesCompanion(
                id: id,
                action: action,
                actor: actor,
                targetRecordId: targetRecordId,
                occurredAt: occurredAt,
                amountCentavos: amountCentavos,
                reference: reference,
                beforeSnapshotJson: beforeSnapshotJson,
                afterSnapshotJson: afterSnapshotJson,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String action,
                required String actor,
                required String targetRecordId,
                required DateTime occurredAt,
                Value<int?> amountCentavos = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> beforeSnapshotJson = const Value.absent(),
                Value<String?> afterSnapshotJson = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogEntriesCompanion.insert(
                id: id,
                action: action,
                actor: actor,
                targetRecordId: targetRecordId,
                occurredAt: occurredAt,
                amountCentavos: amountCentavos,
                reference: reference,
                beforeSnapshotJson: beforeSnapshotJson,
                afterSnapshotJson: afterSnapshotJson,
                metadataJson: metadataJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AuditDatabase,
      $AuditLogEntriesTable,
      AuditLogRecord,
      $$AuditLogEntriesTableFilterComposer,
      $$AuditLogEntriesTableOrderingComposer,
      $$AuditLogEntriesTableAnnotationComposer,
      $$AuditLogEntriesTableCreateCompanionBuilder,
      $$AuditLogEntriesTableUpdateCompanionBuilder,
      (
        AuditLogRecord,
        BaseReferences<_$AuditDatabase, $AuditLogEntriesTable, AuditLogRecord>,
      ),
      AuditLogRecord,
      PrefetchHooks Function()
    >;

class $AuditDatabaseManager {
  final _$AuditDatabase _db;
  $AuditDatabaseManager(this._db);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db, _db.localAccounts);
  $$OrganizationsTableTableManager get organizations =>
      $$OrganizationsTableTableManager(_db, _db.organizations);
  $$OfficersTableTableManager get officers =>
      $$OfficersTableTableManager(_db, _db.officers);
  $$TreasuryFundSourcesTableTableManager get treasuryFundSources =>
      $$TreasuryFundSourcesTableTableManager(_db, _db.treasuryFundSources);
  $$AuditEventsTableTableManager get auditEvents =>
      $$AuditEventsTableTableManager(_db, _db.auditEvents);
  $$EventFundingAllocationsTableTableManager get eventFundingAllocations =>
      $$EventFundingAllocationsTableTableManager(
        _db,
        _db.eventFundingAllocations,
      );
  $$FundMovementsTableTableManager get fundMovements =>
      $$FundMovementsTableTableManager(_db, _db.fundMovements);
  $$LiquidationReceiptsTableTableManager get liquidationReceipts =>
      $$LiquidationReceiptsTableTableManager(_db, _db.liquidationReceipts);
  $$LiquidationLinesTableTableManager get liquidationLines =>
      $$LiquidationLinesTableTableManager(_db, _db.liquidationLines);
  $$ReimbursementClaimsTableTableManager get reimbursementClaims =>
      $$ReimbursementClaimsTableTableManager(_db, _db.reimbursementClaims);
  $$AuditorReviewsTableTableManager get auditorReviews =>
      $$AuditorReviewsTableTableManager(_db, _db.auditorReviews);
  $$AuditLogEntriesTableTableManager get auditLogEntries =>
      $$AuditLogEntriesTableTableManager(_db, _db.auditLogEntries);
}
