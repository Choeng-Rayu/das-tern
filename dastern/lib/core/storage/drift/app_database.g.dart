// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OutboxOpType, String> op =
      GeneratedColumn<String>(
        'op',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OutboxOpType>($OutboxEntriesTable.$converterop);
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    op,
    payload,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      op: $OutboxEntriesTable.$converterop.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}op'],
        )!,
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OutboxOpType, String, String> $converterop =
      const EnumNameConverter<OutboxOpType>(OutboxOpType.values);
}

class OutboxEntry extends DataClass implements Insertable<OutboxEntry> {
  /// ULID string — sortable, collision-free, generated client-side.
  final String id;

  /// Target Supabase table name (e.g. `'prescriptions'`).
  final String targetTable;

  /// Operation type serialised as string.
  final OutboxOpType op;

  /// JSON-encoded payload (row data for create/update, `{id}` for delete).
  final String payload;

  /// How many times the SyncEngine has attempted this entry.
  final int attempts;

  /// Earliest time the SyncEngine may retry (exponential backoff).
  final DateTime nextAttemptAt;

  /// Last error message, if any.
  final String? lastError;
  final DateTime createdAt;
  const OutboxEntry({
    required this.id,
    required this.targetTable,
    required this.op,
    required this.payload,
    required this.attempts,
    required this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_table'] = Variable<String>(targetTable);
    {
      map['op'] = Variable<String>($OutboxEntriesTable.$converterop.toSql(op));
    }
    map['payload'] = Variable<String>(payload);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      op: Value(op),
      payload: Value(payload),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntry(
      id: serializer.fromJson<String>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      op: $OutboxEntriesTable.$converterop.fromJson(
        serializer.fromJson<String>(json['op']),
      ),
      payload: serializer.fromJson<String>(json['payload']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'op': serializer.toJson<String>(
        $OutboxEntriesTable.$converterop.toJson(op),
      ),
      'payload': serializer.toJson<String>(payload),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxEntry copyWith({
    String? id,
    String? targetTable,
    OutboxOpType? op,
    String? payload,
    int? attempts,
    DateTime? nextAttemptAt,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => OutboxEntry(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxEntry copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxEntry(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntry(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetTable,
    op,
    payload,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntry &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxEntry> {
  final Value<String> id;
  final Value<String> targetTable;
  final Value<OutboxOpType> op;
  final Value<String> payload;
  final Value<int> attempts;
  final Value<DateTime> nextAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OutboxEntriesCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    required String id,
    required String targetTable,
    required OutboxOpType op,
    required String payload,
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetTable = Value(targetTable),
       op = Value(op),
       payload = Value(payload);
  static Insertable<OutboxEntry> custom({
    Expression<String>? id,
    Expression<String>? targetTable,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? targetTable,
    Value<OutboxOpType>? op,
    Value<String>? payload,
    Value<int>? attempts,
    Value<DateTime>? nextAttemptAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return OutboxEntriesCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
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
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(
        $OutboxEntriesTable.$converterop.toSql(op.value),
      );
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
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
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTableTable extends ProfilesTable
    with TableInfo<$ProfilesTableTable, ProfilesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    requiredDuringInsert: false,
    defaultValue: const Constant('PATIENT'),
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KHMER'),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LIGHT'),
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Asia/Phnom_Penh'),
  );
  static const VerificationMeta _gracePeriodMinutesMeta =
      const VerificationMeta('gracePeriodMinutes');
  @override
  late final GeneratedColumn<int> gracePeriodMinutes = GeneratedColumn<int>(
    'grace_period_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _accountStatusMeta = const VerificationMeta(
    'accountStatus',
  );
  @override
  late final GeneratedColumn<String> accountStatus = GeneratedColumn<String>(
    'account_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _profilePictureUrlMeta = const VerificationMeta(
    'profilePictureUrl',
  );
  @override
  late final GeneratedColumn<String> profilePictureUrl =
      GeneratedColumn<String>(
        'profile_picture_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _hospitalClinicMeta = const VerificationMeta(
    'hospitalClinic',
  );
  @override
  late final GeneratedColumn<String> hospitalClinic = GeneratedColumn<String>(
    'hospital_clinic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _specialtyMeta = const VerificationMeta(
    'specialty',
  );
  @override
  late final GeneratedColumn<String> specialty = GeneratedColumn<String>(
    'specialty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _licenseNumberMeta = const VerificationMeta(
    'licenseNumber',
  );
  @override
  late final GeneratedColumn<String> licenseNumber = GeneratedColumn<String>(
    'license_number',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    role,
    firstName,
    lastName,
    fullName,
    phoneNumber,
    email,
    language,
    theme,
    timezone,
    gracePeriodMinutes,
    accountStatus,
    profilePictureUrl,
    hospitalClinic,
    specialty,
    licenseNumber,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfilesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('grace_period_minutes')) {
      context.handle(
        _gracePeriodMinutesMeta,
        gracePeriodMinutes.isAcceptableOrUnknown(
          data['grace_period_minutes']!,
          _gracePeriodMinutesMeta,
        ),
      );
    }
    if (data.containsKey('account_status')) {
      context.handle(
        _accountStatusMeta,
        accountStatus.isAcceptableOrUnknown(
          data['account_status']!,
          _accountStatusMeta,
        ),
      );
    }
    if (data.containsKey('profile_picture_url')) {
      context.handle(
        _profilePictureUrlMeta,
        profilePictureUrl.isAcceptableOrUnknown(
          data['profile_picture_url']!,
          _profilePictureUrlMeta,
        ),
      );
    }
    if (data.containsKey('hospital_clinic')) {
      context.handle(
        _hospitalClinicMeta,
        hospitalClinic.isAcceptableOrUnknown(
          data['hospital_clinic']!,
          _hospitalClinicMeta,
        ),
      );
    }
    if (data.containsKey('specialty')) {
      context.handle(
        _specialtyMeta,
        specialty.isAcceptableOrUnknown(data['specialty']!, _specialtyMeta),
      );
    }
    if (data.containsKey('license_number')) {
      context.handle(
        _licenseNumberMeta,
        licenseNumber.isAcceptableOrUnknown(
          data['license_number']!,
          _licenseNumberMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfilesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfilesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      ),
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      gracePeriodMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grace_period_minutes'],
      )!,
      accountStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_status'],
      )!,
      profilePictureUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_picture_url'],
      ),
      hospitalClinic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hospital_clinic'],
      ),
      specialty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specialty'],
      ),
      licenseNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_number'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfilesTableTable createAlias(String alias) {
    return $ProfilesTableTable(attachedDatabase, alias);
  }
}

class ProfilesTableData extends DataClass
    implements Insertable<ProfilesTableData> {
  final String id;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final String language;
  final String theme;
  final String timezone;
  final int gracePeriodMinutes;
  final String accountStatus;
  final String? profilePictureUrl;
  final String? hospitalClinic;
  final String? specialty;
  final String? licenseNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProfilesTableData({
    required this.id,
    required this.role,
    this.firstName,
    this.lastName,
    this.fullName,
    this.phoneNumber,
    this.email,
    required this.language,
    required this.theme,
    required this.timezone,
    required this.gracePeriodMinutes,
    required this.accountStatus,
    this.profilePictureUrl,
    this.hospitalClinic,
    this.specialty,
    this.licenseNumber,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || firstName != null) {
      map['first_name'] = Variable<String>(firstName);
    }
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = Variable<String>(lastName);
    }
    if (!nullToAbsent || fullName != null) {
      map['full_name'] = Variable<String>(fullName);
    }
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['language'] = Variable<String>(language);
    map['theme'] = Variable<String>(theme);
    map['timezone'] = Variable<String>(timezone);
    map['grace_period_minutes'] = Variable<int>(gracePeriodMinutes);
    map['account_status'] = Variable<String>(accountStatus);
    if (!nullToAbsent || profilePictureUrl != null) {
      map['profile_picture_url'] = Variable<String>(profilePictureUrl);
    }
    if (!nullToAbsent || hospitalClinic != null) {
      map['hospital_clinic'] = Variable<String>(hospitalClinic);
    }
    if (!nullToAbsent || specialty != null) {
      map['specialty'] = Variable<String>(specialty);
    }
    if (!nullToAbsent || licenseNumber != null) {
      map['license_number'] = Variable<String>(licenseNumber);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfilesTableCompanion toCompanion(bool nullToAbsent) {
    return ProfilesTableCompanion(
      id: Value(id),
      role: Value(role),
      firstName: firstName == null && nullToAbsent
          ? const Value.absent()
          : Value(firstName),
      lastName: lastName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastName),
      fullName: fullName == null && nullToAbsent
          ? const Value.absent()
          : Value(fullName),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      language: Value(language),
      theme: Value(theme),
      timezone: Value(timezone),
      gracePeriodMinutes: Value(gracePeriodMinutes),
      accountStatus: Value(accountStatus),
      profilePictureUrl: profilePictureUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePictureUrl),
      hospitalClinic: hospitalClinic == null && nullToAbsent
          ? const Value.absent()
          : Value(hospitalClinic),
      specialty: specialty == null && nullToAbsent
          ? const Value.absent()
          : Value(specialty),
      licenseNumber: licenseNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(licenseNumber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfilesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfilesTableData(
      id: serializer.fromJson<String>(json['id']),
      role: serializer.fromJson<String>(json['role']),
      firstName: serializer.fromJson<String?>(json['firstName']),
      lastName: serializer.fromJson<String?>(json['lastName']),
      fullName: serializer.fromJson<String?>(json['fullName']),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      email: serializer.fromJson<String?>(json['email']),
      language: serializer.fromJson<String>(json['language']),
      theme: serializer.fromJson<String>(json['theme']),
      timezone: serializer.fromJson<String>(json['timezone']),
      gracePeriodMinutes: serializer.fromJson<int>(json['gracePeriodMinutes']),
      accountStatus: serializer.fromJson<String>(json['accountStatus']),
      profilePictureUrl: serializer.fromJson<String?>(
        json['profilePictureUrl'],
      ),
      hospitalClinic: serializer.fromJson<String?>(json['hospitalClinic']),
      specialty: serializer.fromJson<String?>(json['specialty']),
      licenseNumber: serializer.fromJson<String?>(json['licenseNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'role': serializer.toJson<String>(role),
      'firstName': serializer.toJson<String?>(firstName),
      'lastName': serializer.toJson<String?>(lastName),
      'fullName': serializer.toJson<String?>(fullName),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'email': serializer.toJson<String?>(email),
      'language': serializer.toJson<String>(language),
      'theme': serializer.toJson<String>(theme),
      'timezone': serializer.toJson<String>(timezone),
      'gracePeriodMinutes': serializer.toJson<int>(gracePeriodMinutes),
      'accountStatus': serializer.toJson<String>(accountStatus),
      'profilePictureUrl': serializer.toJson<String?>(profilePictureUrl),
      'hospitalClinic': serializer.toJson<String?>(hospitalClinic),
      'specialty': serializer.toJson<String?>(specialty),
      'licenseNumber': serializer.toJson<String?>(licenseNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProfilesTableData copyWith({
    String? id,
    String? role,
    Value<String?> firstName = const Value.absent(),
    Value<String?> lastName = const Value.absent(),
    Value<String?> fullName = const Value.absent(),
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> email = const Value.absent(),
    String? language,
    String? theme,
    String? timezone,
    int? gracePeriodMinutes,
    String? accountStatus,
    Value<String?> profilePictureUrl = const Value.absent(),
    Value<String?> hospitalClinic = const Value.absent(),
    Value<String?> specialty = const Value.absent(),
    Value<String?> licenseNumber = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProfilesTableData(
    id: id ?? this.id,
    role: role ?? this.role,
    firstName: firstName.present ? firstName.value : this.firstName,
    lastName: lastName.present ? lastName.value : this.lastName,
    fullName: fullName.present ? fullName.value : this.fullName,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    email: email.present ? email.value : this.email,
    language: language ?? this.language,
    theme: theme ?? this.theme,
    timezone: timezone ?? this.timezone,
    gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
    accountStatus: accountStatus ?? this.accountStatus,
    profilePictureUrl: profilePictureUrl.present
        ? profilePictureUrl.value
        : this.profilePictureUrl,
    hospitalClinic: hospitalClinic.present
        ? hospitalClinic.value
        : this.hospitalClinic,
    specialty: specialty.present ? specialty.value : this.specialty,
    licenseNumber: licenseNumber.present
        ? licenseNumber.value
        : this.licenseNumber,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfilesTableData copyWithCompanion(ProfilesTableCompanion data) {
    return ProfilesTableData(
      id: data.id.present ? data.id.value : this.id,
      role: data.role.present ? data.role.value : this.role,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      email: data.email.present ? data.email.value : this.email,
      language: data.language.present ? data.language.value : this.language,
      theme: data.theme.present ? data.theme.value : this.theme,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      gracePeriodMinutes: data.gracePeriodMinutes.present
          ? data.gracePeriodMinutes.value
          : this.gracePeriodMinutes,
      accountStatus: data.accountStatus.present
          ? data.accountStatus.value
          : this.accountStatus,
      profilePictureUrl: data.profilePictureUrl.present
          ? data.profilePictureUrl.value
          : this.profilePictureUrl,
      hospitalClinic: data.hospitalClinic.present
          ? data.hospitalClinic.value
          : this.hospitalClinic,
      specialty: data.specialty.present ? data.specialty.value : this.specialty,
      licenseNumber: data.licenseNumber.present
          ? data.licenseNumber.value
          : this.licenseNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesTableData(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('fullName: $fullName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('email: $email, ')
          ..write('language: $language, ')
          ..write('theme: $theme, ')
          ..write('timezone: $timezone, ')
          ..write('gracePeriodMinutes: $gracePeriodMinutes, ')
          ..write('accountStatus: $accountStatus, ')
          ..write('profilePictureUrl: $profilePictureUrl, ')
          ..write('hospitalClinic: $hospitalClinic, ')
          ..write('specialty: $specialty, ')
          ..write('licenseNumber: $licenseNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    role,
    firstName,
    lastName,
    fullName,
    phoneNumber,
    email,
    language,
    theme,
    timezone,
    gracePeriodMinutes,
    accountStatus,
    profilePictureUrl,
    hospitalClinic,
    specialty,
    licenseNumber,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfilesTableData &&
          other.id == this.id &&
          other.role == this.role &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.fullName == this.fullName &&
          other.phoneNumber == this.phoneNumber &&
          other.email == this.email &&
          other.language == this.language &&
          other.theme == this.theme &&
          other.timezone == this.timezone &&
          other.gracePeriodMinutes == this.gracePeriodMinutes &&
          other.accountStatus == this.accountStatus &&
          other.profilePictureUrl == this.profilePictureUrl &&
          other.hospitalClinic == this.hospitalClinic &&
          other.specialty == this.specialty &&
          other.licenseNumber == this.licenseNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProfilesTableCompanion extends UpdateCompanion<ProfilesTableData> {
  final Value<String> id;
  final Value<String> role;
  final Value<String?> firstName;
  final Value<String?> lastName;
  final Value<String?> fullName;
  final Value<String?> phoneNumber;
  final Value<String?> email;
  final Value<String> language;
  final Value<String> theme;
  final Value<String> timezone;
  final Value<int> gracePeriodMinutes;
  final Value<String> accountStatus;
  final Value<String?> profilePictureUrl;
  final Value<String?> hospitalClinic;
  final Value<String?> specialty;
  final Value<String?> licenseNumber;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProfilesTableCompanion({
    this.id = const Value.absent(),
    this.role = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.language = const Value.absent(),
    this.theme = const Value.absent(),
    this.timezone = const Value.absent(),
    this.gracePeriodMinutes = const Value.absent(),
    this.accountStatus = const Value.absent(),
    this.profilePictureUrl = const Value.absent(),
    this.hospitalClinic = const Value.absent(),
    this.specialty = const Value.absent(),
    this.licenseNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesTableCompanion.insert({
    required String id,
    this.role = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.fullName = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.language = const Value.absent(),
    this.theme = const Value.absent(),
    this.timezone = const Value.absent(),
    this.gracePeriodMinutes = const Value.absent(),
    this.accountStatus = const Value.absent(),
    this.profilePictureUrl = const Value.absent(),
    this.hospitalClinic = const Value.absent(),
    this.specialty = const Value.absent(),
    this.licenseNumber = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProfilesTableData> custom({
    Expression<String>? id,
    Expression<String>? role,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? fullName,
    Expression<String>? phoneNumber,
    Expression<String>? email,
    Expression<String>? language,
    Expression<String>? theme,
    Expression<String>? timezone,
    Expression<int>? gracePeriodMinutes,
    Expression<String>? accountStatus,
    Expression<String>? profilePictureUrl,
    Expression<String>? hospitalClinic,
    Expression<String>? specialty,
    Expression<String>? licenseNumber,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (role != null) 'role': role,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (fullName != null) 'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (email != null) 'email': email,
      if (language != null) 'language': language,
      if (theme != null) 'theme': theme,
      if (timezone != null) 'timezone': timezone,
      if (gracePeriodMinutes != null)
        'grace_period_minutes': gracePeriodMinutes,
      if (accountStatus != null) 'account_status': accountStatus,
      if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      if (hospitalClinic != null) 'hospital_clinic': hospitalClinic,
      if (specialty != null) 'specialty': specialty,
      if (licenseNumber != null) 'license_number': licenseNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? role,
    Value<String?>? firstName,
    Value<String?>? lastName,
    Value<String?>? fullName,
    Value<String?>? phoneNumber,
    Value<String?>? email,
    Value<String>? language,
    Value<String>? theme,
    Value<String>? timezone,
    Value<int>? gracePeriodMinutes,
    Value<String>? accountStatus,
    Value<String?>? profilePictureUrl,
    Value<String?>? hospitalClinic,
    Value<String?>? specialty,
    Value<String?>? licenseNumber,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfilesTableCompanion(
      id: id ?? this.id,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      timezone: timezone ?? this.timezone,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      accountStatus: accountStatus ?? this.accountStatus,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      hospitalClinic: hospitalClinic ?? this.hospitalClinic,
      specialty: specialty ?? this.specialty,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (gracePeriodMinutes.present) {
      map['grace_period_minutes'] = Variable<int>(gracePeriodMinutes.value);
    }
    if (accountStatus.present) {
      map['account_status'] = Variable<String>(accountStatus.value);
    }
    if (profilePictureUrl.present) {
      map['profile_picture_url'] = Variable<String>(profilePictureUrl.value);
    }
    if (hospitalClinic.present) {
      map['hospital_clinic'] = Variable<String>(hospitalClinic.value);
    }
    if (specialty.present) {
      map['specialty'] = Variable<String>(specialty.value);
    }
    if (licenseNumber.present) {
      map['license_number'] = Variable<String>(licenseNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesTableCompanion(')
          ..write('id: $id, ')
          ..write('role: $role, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('fullName: $fullName, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('email: $email, ')
          ..write('language: $language, ')
          ..write('theme: $theme, ')
          ..write('timezone: $timezone, ')
          ..write('gracePeriodMinutes: $gracePeriodMinutes, ')
          ..write('accountStatus: $accountStatus, ')
          ..write('profilePictureUrl: $profilePictureUrl, ')
          ..write('hospitalClinic: $hospitalClinic, ')
          ..write('specialty: $specialty, ')
          ..write('licenseNumber: $licenseNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConnectionsTableTable extends ConnectionsTable
    with TableInfo<$ConnectionsTableTable, ConnectionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initiatorIdMeta = const VerificationMeta(
    'initiatorId',
  );
  @override
  late final GeneratedColumn<String> initiatorId = GeneratedColumn<String>(
    'initiator_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientIdMeta = const VerificationMeta(
    'recipientId',
  );
  @override
  late final GeneratedColumn<String> recipientId = GeneratedColumn<String>(
    'recipient_id',
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
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _permissionLevelMeta = const VerificationMeta(
    'permissionLevel',
  );
  @override
  late final GeneratedColumn<String> permissionLevel = GeneratedColumn<String>(
    'permission_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ALLOWED'),
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
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<DateTime> requestedAt = GeneratedColumn<DateTime>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acceptedAtMeta = const VerificationMeta(
    'acceptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> acceptedAt = GeneratedColumn<DateTime>(
    'accepted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<DateTime> revokedAt = GeneratedColumn<DateTime>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    initiatorId,
    recipientId,
    status,
    permissionLevel,
    metadata,
    requestedAt,
    acceptedAt,
    revokedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConnectionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('initiator_id')) {
      context.handle(
        _initiatorIdMeta,
        initiatorId.isAcceptableOrUnknown(
          data['initiator_id']!,
          _initiatorIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initiatorIdMeta);
    }
    if (data.containsKey('recipient_id')) {
      context.handle(
        _recipientIdMeta,
        recipientId.isAcceptableOrUnknown(
          data['recipient_id']!,
          _recipientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('permission_level')) {
      context.handle(
        _permissionLevelMeta,
        permissionLevel.isAcceptableOrUnknown(
          data['permission_level']!,
          _permissionLevelMeta,
        ),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
        _acceptedAtMeta,
        acceptedAt.isAcceptableOrUnknown(data['accepted_at']!, _acceptedAtMeta),
      );
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      initiatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initiator_id'],
      )!,
      recipientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      permissionLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permission_level'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_at'],
      )!,
      acceptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}accepted_at'],
      ),
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revoked_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ConnectionsTableTable createAlias(String alias) {
    return $ConnectionsTableTable(attachedDatabase, alias);
  }
}

class ConnectionsTableData extends DataClass
    implements Insertable<ConnectionsTableData> {
  final String id;
  final String initiatorId;
  final String recipientId;
  final String status;
  final String permissionLevel;
  final String? metadata;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ConnectionsTableData({
    required this.id,
    required this.initiatorId,
    required this.recipientId,
    required this.status,
    required this.permissionLevel,
    this.metadata,
    required this.requestedAt,
    this.acceptedAt,
    this.revokedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['initiator_id'] = Variable<String>(initiatorId);
    map['recipient_id'] = Variable<String>(recipientId);
    map['status'] = Variable<String>(status);
    map['permission_level'] = Variable<String>(permissionLevel);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['requested_at'] = Variable<DateTime>(requestedAt);
    if (!nullToAbsent || acceptedAt != null) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt);
    }
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<DateTime>(revokedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ConnectionsTableCompanion toCompanion(bool nullToAbsent) {
    return ConnectionsTableCompanion(
      id: Value(id),
      initiatorId: Value(initiatorId),
      recipientId: Value(recipientId),
      status: Value(status),
      permissionLevel: Value(permissionLevel),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      requestedAt: Value(requestedAt),
      acceptedAt: acceptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptedAt),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConnectionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionsTableData(
      id: serializer.fromJson<String>(json['id']),
      initiatorId: serializer.fromJson<String>(json['initiatorId']),
      recipientId: serializer.fromJson<String>(json['recipientId']),
      status: serializer.fromJson<String>(json['status']),
      permissionLevel: serializer.fromJson<String>(json['permissionLevel']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      requestedAt: serializer.fromJson<DateTime>(json['requestedAt']),
      acceptedAt: serializer.fromJson<DateTime?>(json['acceptedAt']),
      revokedAt: serializer.fromJson<DateTime?>(json['revokedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'initiatorId': serializer.toJson<String>(initiatorId),
      'recipientId': serializer.toJson<String>(recipientId),
      'status': serializer.toJson<String>(status),
      'permissionLevel': serializer.toJson<String>(permissionLevel),
      'metadata': serializer.toJson<String?>(metadata),
      'requestedAt': serializer.toJson<DateTime>(requestedAt),
      'acceptedAt': serializer.toJson<DateTime?>(acceptedAt),
      'revokedAt': serializer.toJson<DateTime?>(revokedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ConnectionsTableData copyWith({
    String? id,
    String? initiatorId,
    String? recipientId,
    String? status,
    String? permissionLevel,
    Value<String?> metadata = const Value.absent(),
    DateTime? requestedAt,
    Value<DateTime?> acceptedAt = const Value.absent(),
    Value<DateTime?> revokedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ConnectionsTableData(
    id: id ?? this.id,
    initiatorId: initiatorId ?? this.initiatorId,
    recipientId: recipientId ?? this.recipientId,
    status: status ?? this.status,
    permissionLevel: permissionLevel ?? this.permissionLevel,
    metadata: metadata.present ? metadata.value : this.metadata,
    requestedAt: requestedAt ?? this.requestedAt,
    acceptedAt: acceptedAt.present ? acceptedAt.value : this.acceptedAt,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ConnectionsTableData copyWithCompanion(ConnectionsTableCompanion data) {
    return ConnectionsTableData(
      id: data.id.present ? data.id.value : this.id,
      initiatorId: data.initiatorId.present
          ? data.initiatorId.value
          : this.initiatorId,
      recipientId: data.recipientId.present
          ? data.recipientId.value
          : this.recipientId,
      status: data.status.present ? data.status.value : this.status,
      permissionLevel: data.permissionLevel.present
          ? data.permissionLevel.value
          : this.permissionLevel,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
      acceptedAt: data.acceptedAt.present
          ? data.acceptedAt.value
          : this.acceptedAt,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionsTableData(')
          ..write('id: $id, ')
          ..write('initiatorId: $initiatorId, ')
          ..write('recipientId: $recipientId, ')
          ..write('status: $status, ')
          ..write('permissionLevel: $permissionLevel, ')
          ..write('metadata: $metadata, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    initiatorId,
    recipientId,
    status,
    permissionLevel,
    metadata,
    requestedAt,
    acceptedAt,
    revokedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionsTableData &&
          other.id == this.id &&
          other.initiatorId == this.initiatorId &&
          other.recipientId == this.recipientId &&
          other.status == this.status &&
          other.permissionLevel == this.permissionLevel &&
          other.metadata == this.metadata &&
          other.requestedAt == this.requestedAt &&
          other.acceptedAt == this.acceptedAt &&
          other.revokedAt == this.revokedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConnectionsTableCompanion extends UpdateCompanion<ConnectionsTableData> {
  final Value<String> id;
  final Value<String> initiatorId;
  final Value<String> recipientId;
  final Value<String> status;
  final Value<String> permissionLevel;
  final Value<String?> metadata;
  final Value<DateTime> requestedAt;
  final Value<DateTime?> acceptedAt;
  final Value<DateTime?> revokedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ConnectionsTableCompanion({
    this.id = const Value.absent(),
    this.initiatorId = const Value.absent(),
    this.recipientId = const Value.absent(),
    this.status = const Value.absent(),
    this.permissionLevel = const Value.absent(),
    this.metadata = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectionsTableCompanion.insert({
    required String id,
    required String initiatorId,
    required String recipientId,
    this.status = const Value.absent(),
    this.permissionLevel = const Value.absent(),
    this.metadata = const Value.absent(),
    required DateTime requestedAt,
    this.acceptedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       initiatorId = Value(initiatorId),
       recipientId = Value(recipientId),
       requestedAt = Value(requestedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ConnectionsTableData> custom({
    Expression<String>? id,
    Expression<String>? initiatorId,
    Expression<String>? recipientId,
    Expression<String>? status,
    Expression<String>? permissionLevel,
    Expression<String>? metadata,
    Expression<DateTime>? requestedAt,
    Expression<DateTime>? acceptedAt,
    Expression<DateTime>? revokedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (initiatorId != null) 'initiator_id': initiatorId,
      if (recipientId != null) 'recipient_id': recipientId,
      if (status != null) 'status': status,
      if (permissionLevel != null) 'permission_level': permissionLevel,
      if (metadata != null) 'metadata': metadata,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? initiatorId,
    Value<String>? recipientId,
    Value<String>? status,
    Value<String>? permissionLevel,
    Value<String?>? metadata,
    Value<DateTime>? requestedAt,
    Value<DateTime?>? acceptedAt,
    Value<DateTime?>? revokedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ConnectionsTableCompanion(
      id: id ?? this.id,
      initiatorId: initiatorId ?? this.initiatorId,
      recipientId: recipientId ?? this.recipientId,
      status: status ?? this.status,
      permissionLevel: permissionLevel ?? this.permissionLevel,
      metadata: metadata ?? this.metadata,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (initiatorId.present) {
      map['initiator_id'] = Variable<String>(initiatorId.value);
    }
    if (recipientId.present) {
      map['recipient_id'] = Variable<String>(recipientId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (permissionLevel.present) {
      map['permission_level'] = Variable<String>(permissionLevel.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<DateTime>(requestedAt.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<DateTime>(revokedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionsTableCompanion(')
          ..write('id: $id, ')
          ..write('initiatorId: $initiatorId, ')
          ..write('recipientId: $recipientId, ')
          ..write('status: $status, ')
          ..write('permissionLevel: $permissionLevel, ')
          ..write('metadata: $metadata, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConnectionTokensTableTable extends ConnectionTokensTable
    with TableInfo<$ConnectionTokensTableTable, ConnectionTokensTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionTokensTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionLevelMeta = const VerificationMeta(
    'permissionLevel',
  );
  @override
  late final GeneratedColumn<String> permissionLevel = GeneratedColumn<String>(
    'permission_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ALLOWED'),
  );
  static const VerificationMeta _intendedRoleMeta = const VerificationMeta(
    'intendedRole',
  );
  @override
  late final GeneratedColumn<String> intendedRole = GeneratedColumn<String>(
    'intended_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PATIENT'),
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<DateTime> usedAt = GeneratedColumn<DateTime>(
    'used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usedByIdMeta = const VerificationMeta(
    'usedById',
  );
  @override
  late final GeneratedColumn<String> usedById = GeneratedColumn<String>(
    'used_by_id',
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
    id,
    patientId,
    token,
    permissionLevel,
    intendedRole,
    expiresAt,
    usedAt,
    usedById,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connection_tokens';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConnectionTokensTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('permission_level')) {
      context.handle(
        _permissionLevelMeta,
        permissionLevel.isAcceptableOrUnknown(
          data['permission_level']!,
          _permissionLevelMeta,
        ),
      );
    }
    if (data.containsKey('intended_role')) {
      context.handle(
        _intendedRoleMeta,
        intendedRole.isAcceptableOrUnknown(
          data['intended_role']!,
          _intendedRoleMeta,
        ),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('used_at')) {
      context.handle(
        _usedAtMeta,
        usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta),
      );
    }
    if (data.containsKey('used_by_id')) {
      context.handle(
        _usedByIdMeta,
        usedById.isAcceptableOrUnknown(data['used_by_id']!, _usedByIdMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionTokensTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionTokensTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      permissionLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permission_level'],
      )!,
      intendedRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intended_role'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      usedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}used_at'],
      ),
      usedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}used_by_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ConnectionTokensTableTable createAlias(String alias) {
    return $ConnectionTokensTableTable(attachedDatabase, alias);
  }
}

class ConnectionTokensTableData extends DataClass
    implements Insertable<ConnectionTokensTableData> {
  final String id;
  final String patientId;
  final String token;
  final String permissionLevel;
  final String intendedRole;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? usedById;
  final DateTime createdAt;
  const ConnectionTokensTableData({
    required this.id,
    required this.patientId,
    required this.token,
    required this.permissionLevel,
    required this.intendedRole,
    required this.expiresAt,
    this.usedAt,
    this.usedById,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['token'] = Variable<String>(token);
    map['permission_level'] = Variable<String>(permissionLevel);
    map['intended_role'] = Variable<String>(intendedRole);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    if (!nullToAbsent || usedAt != null) {
      map['used_at'] = Variable<DateTime>(usedAt);
    }
    if (!nullToAbsent || usedById != null) {
      map['used_by_id'] = Variable<String>(usedById);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ConnectionTokensTableCompanion toCompanion(bool nullToAbsent) {
    return ConnectionTokensTableCompanion(
      id: Value(id),
      patientId: Value(patientId),
      token: Value(token),
      permissionLevel: Value(permissionLevel),
      intendedRole: Value(intendedRole),
      expiresAt: Value(expiresAt),
      usedAt: usedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(usedAt),
      usedById: usedById == null && nullToAbsent
          ? const Value.absent()
          : Value(usedById),
      createdAt: Value(createdAt),
    );
  }

  factory ConnectionTokensTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionTokensTableData(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      token: serializer.fromJson<String>(json['token']),
      permissionLevel: serializer.fromJson<String>(json['permissionLevel']),
      intendedRole: serializer.fromJson<String>(json['intendedRole']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      usedAt: serializer.fromJson<DateTime?>(json['usedAt']),
      usedById: serializer.fromJson<String?>(json['usedById']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'token': serializer.toJson<String>(token),
      'permissionLevel': serializer.toJson<String>(permissionLevel),
      'intendedRole': serializer.toJson<String>(intendedRole),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'usedAt': serializer.toJson<DateTime?>(usedAt),
      'usedById': serializer.toJson<String?>(usedById),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ConnectionTokensTableData copyWith({
    String? id,
    String? patientId,
    String? token,
    String? permissionLevel,
    String? intendedRole,
    DateTime? expiresAt,
    Value<DateTime?> usedAt = const Value.absent(),
    Value<String?> usedById = const Value.absent(),
    DateTime? createdAt,
  }) => ConnectionTokensTableData(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    token: token ?? this.token,
    permissionLevel: permissionLevel ?? this.permissionLevel,
    intendedRole: intendedRole ?? this.intendedRole,
    expiresAt: expiresAt ?? this.expiresAt,
    usedAt: usedAt.present ? usedAt.value : this.usedAt,
    usedById: usedById.present ? usedById.value : this.usedById,
    createdAt: createdAt ?? this.createdAt,
  );
  ConnectionTokensTableData copyWithCompanion(
    ConnectionTokensTableCompanion data,
  ) {
    return ConnectionTokensTableData(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      token: data.token.present ? data.token.value : this.token,
      permissionLevel: data.permissionLevel.present
          ? data.permissionLevel.value
          : this.permissionLevel,
      intendedRole: data.intendedRole.present
          ? data.intendedRole.value
          : this.intendedRole,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
      usedById: data.usedById.present ? data.usedById.value : this.usedById,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionTokensTableData(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('token: $token, ')
          ..write('permissionLevel: $permissionLevel, ')
          ..write('intendedRole: $intendedRole, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('usedAt: $usedAt, ')
          ..write('usedById: $usedById, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    token,
    permissionLevel,
    intendedRole,
    expiresAt,
    usedAt,
    usedById,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionTokensTableData &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.token == this.token &&
          other.permissionLevel == this.permissionLevel &&
          other.intendedRole == this.intendedRole &&
          other.expiresAt == this.expiresAt &&
          other.usedAt == this.usedAt &&
          other.usedById == this.usedById &&
          other.createdAt == this.createdAt);
}

class ConnectionTokensTableCompanion
    extends UpdateCompanion<ConnectionTokensTableData> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> token;
  final Value<String> permissionLevel;
  final Value<String> intendedRole;
  final Value<DateTime> expiresAt;
  final Value<DateTime?> usedAt;
  final Value<String?> usedById;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ConnectionTokensTableCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.token = const Value.absent(),
    this.permissionLevel = const Value.absent(),
    this.intendedRole = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.usedById = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectionTokensTableCompanion.insert({
    required String id,
    required String patientId,
    required String token,
    this.permissionLevel = const Value.absent(),
    this.intendedRole = const Value.absent(),
    required DateTime expiresAt,
    this.usedAt = const Value.absent(),
    this.usedById = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       token = Value(token),
       expiresAt = Value(expiresAt),
       createdAt = Value(createdAt);
  static Insertable<ConnectionTokensTableData> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? token,
    Expression<String>? permissionLevel,
    Expression<String>? intendedRole,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? usedAt,
    Expression<String>? usedById,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (token != null) 'token': token,
      if (permissionLevel != null) 'permission_level': permissionLevel,
      if (intendedRole != null) 'intended_role': intendedRole,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (usedAt != null) 'used_at': usedAt,
      if (usedById != null) 'used_by_id': usedById,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectionTokensTableCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? token,
    Value<String>? permissionLevel,
    Value<String>? intendedRole,
    Value<DateTime>? expiresAt,
    Value<DateTime?>? usedAt,
    Value<String?>? usedById,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ConnectionTokensTableCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      token: token ?? this.token,
      permissionLevel: permissionLevel ?? this.permissionLevel,
      intendedRole: intendedRole ?? this.intendedRole,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedById: usedById ?? this.usedById,
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
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (permissionLevel.present) {
      map['permission_level'] = Variable<String>(permissionLevel.value);
    }
    if (intendedRole.present) {
      map['intended_role'] = Variable<String>(intendedRole.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<DateTime>(usedAt.value);
    }
    if (usedById.present) {
      map['used_by_id'] = Variable<String>(usedById.value);
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
    return (StringBuffer('ConnectionTokensTableCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('token: $token, ')
          ..write('permissionLevel: $permissionLevel, ')
          ..write('intendedRole: $intendedRole, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('usedAt: $usedAt, ')
          ..write('usedById: $usedById, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrescriptionsTableTable extends PrescriptionsTable
    with TableInfo<$PrescriptionsTableTable, PrescriptionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrescriptionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doctorIdMeta = const VerificationMeta(
    'doctorId',
  );
  @override
  late final GeneratedColumn<String> doctorId = GeneratedColumn<String>(
    'doctor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _patientNameMeta = const VerificationMeta(
    'patientName',
  );
  @override
  late final GeneratedColumn<String> patientName = GeneratedColumn<String>(
    'patient_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientGenderMeta = const VerificationMeta(
    'patientGender',
  );
  @override
  late final GeneratedColumn<String> patientGender = GeneratedColumn<String>(
    'patient_gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientAgeMeta = const VerificationMeta(
    'patientAge',
  );
  @override
  late final GeneratedColumn<int> patientAge = GeneratedColumn<int>(
    'patient_age',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symptomsMeta = const VerificationMeta(
    'symptoms',
  );
  @override
  late final GeneratedColumn<String> symptoms = GeneratedColumn<String>(
    'symptoms',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _diagnosisMeta = const VerificationMeta(
    'diagnosis',
  );
  @override
  late final GeneratedColumn<String> diagnosis = GeneratedColumn<String>(
    'diagnosis',
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
    defaultValue: const Constant('DRAFT'),
  );
  static const VerificationMeta _currentVersionMeta = const VerificationMeta(
    'currentVersion',
  );
  @override
  late final GeneratedColumn<int> currentVersion = GeneratedColumn<int>(
    'current_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isUrgentMeta = const VerificationMeta(
    'isUrgent',
  );
  @override
  late final GeneratedColumn<bool> isUrgent = GeneratedColumn<bool>(
    'is_urgent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_urgent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _urgentReasonMeta = const VerificationMeta(
    'urgentReason',
  );
  @override
  late final GeneratedColumn<String> urgentReason = GeneratedColumn<String>(
    'urgent_reason',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    doctorId,
    patientName,
    patientGender,
    patientAge,
    symptoms,
    diagnosis,
    status,
    currentVersion,
    isUrgent,
    urgentReason,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prescriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrescriptionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('doctor_id')) {
      context.handle(
        _doctorIdMeta,
        doctorId.isAcceptableOrUnknown(data['doctor_id']!, _doctorIdMeta),
      );
    }
    if (data.containsKey('patient_name')) {
      context.handle(
        _patientNameMeta,
        patientName.isAcceptableOrUnknown(
          data['patient_name']!,
          _patientNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_patientNameMeta);
    }
    if (data.containsKey('patient_gender')) {
      context.handle(
        _patientGenderMeta,
        patientGender.isAcceptableOrUnknown(
          data['patient_gender']!,
          _patientGenderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_patientGenderMeta);
    }
    if (data.containsKey('patient_age')) {
      context.handle(
        _patientAgeMeta,
        patientAge.isAcceptableOrUnknown(data['patient_age']!, _patientAgeMeta),
      );
    } else if (isInserting) {
      context.missing(_patientAgeMeta);
    }
    if (data.containsKey('symptoms')) {
      context.handle(
        _symptomsMeta,
        symptoms.isAcceptableOrUnknown(data['symptoms']!, _symptomsMeta),
      );
    }
    if (data.containsKey('diagnosis')) {
      context.handle(
        _diagnosisMeta,
        diagnosis.isAcceptableOrUnknown(data['diagnosis']!, _diagnosisMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('current_version')) {
      context.handle(
        _currentVersionMeta,
        currentVersion.isAcceptableOrUnknown(
          data['current_version']!,
          _currentVersionMeta,
        ),
      );
    }
    if (data.containsKey('is_urgent')) {
      context.handle(
        _isUrgentMeta,
        isUrgent.isAcceptableOrUnknown(data['is_urgent']!, _isUrgentMeta),
      );
    }
    if (data.containsKey('urgent_reason')) {
      context.handle(
        _urgentReasonMeta,
        urgentReason.isAcceptableOrUnknown(
          data['urgent_reason']!,
          _urgentReasonMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrescriptionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrescriptionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      doctorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor_id'],
      ),
      patientName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_name'],
      )!,
      patientGender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_gender'],
      )!,
      patientAge: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}patient_age'],
      )!,
      symptoms: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symptoms'],
      )!,
      diagnosis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnosis'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      currentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_version'],
      )!,
      isUrgent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_urgent'],
      )!,
      urgentReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}urgent_reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PrescriptionsTableTable createAlias(String alias) {
    return $PrescriptionsTableTable(attachedDatabase, alias);
  }
}

class PrescriptionsTableData extends DataClass
    implements Insertable<PrescriptionsTableData> {
  final String id;
  final String patientId;
  final String? doctorId;
  final String patientName;
  final String patientGender;
  final int patientAge;
  final String symptoms;
  final String? diagnosis;
  final String status;
  final int currentVersion;
  final bool isUrgent;
  final String? urgentReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PrescriptionsTableData({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.patientName,
    required this.patientGender,
    required this.patientAge,
    required this.symptoms,
    this.diagnosis,
    required this.status,
    required this.currentVersion,
    required this.isUrgent,
    this.urgentReason,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    if (!nullToAbsent || doctorId != null) {
      map['doctor_id'] = Variable<String>(doctorId);
    }
    map['patient_name'] = Variable<String>(patientName);
    map['patient_gender'] = Variable<String>(patientGender);
    map['patient_age'] = Variable<int>(patientAge);
    map['symptoms'] = Variable<String>(symptoms);
    if (!nullToAbsent || diagnosis != null) {
      map['diagnosis'] = Variable<String>(diagnosis);
    }
    map['status'] = Variable<String>(status);
    map['current_version'] = Variable<int>(currentVersion);
    map['is_urgent'] = Variable<bool>(isUrgent);
    if (!nullToAbsent || urgentReason != null) {
      map['urgent_reason'] = Variable<String>(urgentReason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PrescriptionsTableCompanion toCompanion(bool nullToAbsent) {
    return PrescriptionsTableCompanion(
      id: Value(id),
      patientId: Value(patientId),
      doctorId: doctorId == null && nullToAbsent
          ? const Value.absent()
          : Value(doctorId),
      patientName: Value(patientName),
      patientGender: Value(patientGender),
      patientAge: Value(patientAge),
      symptoms: Value(symptoms),
      diagnosis: diagnosis == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosis),
      status: Value(status),
      currentVersion: Value(currentVersion),
      isUrgent: Value(isUrgent),
      urgentReason: urgentReason == null && nullToAbsent
          ? const Value.absent()
          : Value(urgentReason),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PrescriptionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrescriptionsTableData(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      doctorId: serializer.fromJson<String?>(json['doctorId']),
      patientName: serializer.fromJson<String>(json['patientName']),
      patientGender: serializer.fromJson<String>(json['patientGender']),
      patientAge: serializer.fromJson<int>(json['patientAge']),
      symptoms: serializer.fromJson<String>(json['symptoms']),
      diagnosis: serializer.fromJson<String?>(json['diagnosis']),
      status: serializer.fromJson<String>(json['status']),
      currentVersion: serializer.fromJson<int>(json['currentVersion']),
      isUrgent: serializer.fromJson<bool>(json['isUrgent']),
      urgentReason: serializer.fromJson<String?>(json['urgentReason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'doctorId': serializer.toJson<String?>(doctorId),
      'patientName': serializer.toJson<String>(patientName),
      'patientGender': serializer.toJson<String>(patientGender),
      'patientAge': serializer.toJson<int>(patientAge),
      'symptoms': serializer.toJson<String>(symptoms),
      'diagnosis': serializer.toJson<String?>(diagnosis),
      'status': serializer.toJson<String>(status),
      'currentVersion': serializer.toJson<int>(currentVersion),
      'isUrgent': serializer.toJson<bool>(isUrgent),
      'urgentReason': serializer.toJson<String?>(urgentReason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PrescriptionsTableData copyWith({
    String? id,
    String? patientId,
    Value<String?> doctorId = const Value.absent(),
    String? patientName,
    String? patientGender,
    int? patientAge,
    String? symptoms,
    Value<String?> diagnosis = const Value.absent(),
    String? status,
    int? currentVersion,
    bool? isUrgent,
    Value<String?> urgentReason = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PrescriptionsTableData(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    doctorId: doctorId.present ? doctorId.value : this.doctorId,
    patientName: patientName ?? this.patientName,
    patientGender: patientGender ?? this.patientGender,
    patientAge: patientAge ?? this.patientAge,
    symptoms: symptoms ?? this.symptoms,
    diagnosis: diagnosis.present ? diagnosis.value : this.diagnosis,
    status: status ?? this.status,
    currentVersion: currentVersion ?? this.currentVersion,
    isUrgent: isUrgent ?? this.isUrgent,
    urgentReason: urgentReason.present ? urgentReason.value : this.urgentReason,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PrescriptionsTableData copyWithCompanion(PrescriptionsTableCompanion data) {
    return PrescriptionsTableData(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      doctorId: data.doctorId.present ? data.doctorId.value : this.doctorId,
      patientName: data.patientName.present
          ? data.patientName.value
          : this.patientName,
      patientGender: data.patientGender.present
          ? data.patientGender.value
          : this.patientGender,
      patientAge: data.patientAge.present
          ? data.patientAge.value
          : this.patientAge,
      symptoms: data.symptoms.present ? data.symptoms.value : this.symptoms,
      diagnosis: data.diagnosis.present ? data.diagnosis.value : this.diagnosis,
      status: data.status.present ? data.status.value : this.status,
      currentVersion: data.currentVersion.present
          ? data.currentVersion.value
          : this.currentVersion,
      isUrgent: data.isUrgent.present ? data.isUrgent.value : this.isUrgent,
      urgentReason: data.urgentReason.present
          ? data.urgentReason.value
          : this.urgentReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionsTableData(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('doctorId: $doctorId, ')
          ..write('patientName: $patientName, ')
          ..write('patientGender: $patientGender, ')
          ..write('patientAge: $patientAge, ')
          ..write('symptoms: $symptoms, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('status: $status, ')
          ..write('currentVersion: $currentVersion, ')
          ..write('isUrgent: $isUrgent, ')
          ..write('urgentReason: $urgentReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    doctorId,
    patientName,
    patientGender,
    patientAge,
    symptoms,
    diagnosis,
    status,
    currentVersion,
    isUrgent,
    urgentReason,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrescriptionsTableData &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.doctorId == this.doctorId &&
          other.patientName == this.patientName &&
          other.patientGender == this.patientGender &&
          other.patientAge == this.patientAge &&
          other.symptoms == this.symptoms &&
          other.diagnosis == this.diagnosis &&
          other.status == this.status &&
          other.currentVersion == this.currentVersion &&
          other.isUrgent == this.isUrgent &&
          other.urgentReason == this.urgentReason &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PrescriptionsTableCompanion
    extends UpdateCompanion<PrescriptionsTableData> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String?> doctorId;
  final Value<String> patientName;
  final Value<String> patientGender;
  final Value<int> patientAge;
  final Value<String> symptoms;
  final Value<String?> diagnosis;
  final Value<String> status;
  final Value<int> currentVersion;
  final Value<bool> isUrgent;
  final Value<String?> urgentReason;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PrescriptionsTableCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.doctorId = const Value.absent(),
    this.patientName = const Value.absent(),
    this.patientGender = const Value.absent(),
    this.patientAge = const Value.absent(),
    this.symptoms = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.status = const Value.absent(),
    this.currentVersion = const Value.absent(),
    this.isUrgent = const Value.absent(),
    this.urgentReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrescriptionsTableCompanion.insert({
    required String id,
    required String patientId,
    this.doctorId = const Value.absent(),
    required String patientName,
    required String patientGender,
    required int patientAge,
    this.symptoms = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.status = const Value.absent(),
    this.currentVersion = const Value.absent(),
    this.isUrgent = const Value.absent(),
    this.urgentReason = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       patientName = Value(patientName),
       patientGender = Value(patientGender),
       patientAge = Value(patientAge),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PrescriptionsTableData> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? doctorId,
    Expression<String>? patientName,
    Expression<String>? patientGender,
    Expression<int>? patientAge,
    Expression<String>? symptoms,
    Expression<String>? diagnosis,
    Expression<String>? status,
    Expression<int>? currentVersion,
    Expression<bool>? isUrgent,
    Expression<String>? urgentReason,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (doctorId != null) 'doctor_id': doctorId,
      if (patientName != null) 'patient_name': patientName,
      if (patientGender != null) 'patient_gender': patientGender,
      if (patientAge != null) 'patient_age': patientAge,
      if (symptoms != null) 'symptoms': symptoms,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (status != null) 'status': status,
      if (currentVersion != null) 'current_version': currentVersion,
      if (isUrgent != null) 'is_urgent': isUrgent,
      if (urgentReason != null) 'urgent_reason': urgentReason,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrescriptionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String?>? doctorId,
    Value<String>? patientName,
    Value<String>? patientGender,
    Value<int>? patientAge,
    Value<String>? symptoms,
    Value<String?>? diagnosis,
    Value<String>? status,
    Value<int>? currentVersion,
    Value<bool>? isUrgent,
    Value<String?>? urgentReason,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PrescriptionsTableCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      patientGender: patientGender ?? this.patientGender,
      patientAge: patientAge ?? this.patientAge,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      isUrgent: isUrgent ?? this.isUrgent,
      urgentReason: urgentReason ?? this.urgentReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (doctorId.present) {
      map['doctor_id'] = Variable<String>(doctorId.value);
    }
    if (patientName.present) {
      map['patient_name'] = Variable<String>(patientName.value);
    }
    if (patientGender.present) {
      map['patient_gender'] = Variable<String>(patientGender.value);
    }
    if (patientAge.present) {
      map['patient_age'] = Variable<int>(patientAge.value);
    }
    if (symptoms.present) {
      map['symptoms'] = Variable<String>(symptoms.value);
    }
    if (diagnosis.present) {
      map['diagnosis'] = Variable<String>(diagnosis.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (currentVersion.present) {
      map['current_version'] = Variable<int>(currentVersion.value);
    }
    if (isUrgent.present) {
      map['is_urgent'] = Variable<bool>(isUrgent.value);
    }
    if (urgentReason.present) {
      map['urgent_reason'] = Variable<String>(urgentReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionsTableCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('doctorId: $doctorId, ')
          ..write('patientName: $patientName, ')
          ..write('patientGender: $patientGender, ')
          ..write('patientAge: $patientAge, ')
          ..write('symptoms: $symptoms, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('status: $status, ')
          ..write('currentVersion: $currentVersion, ')
          ..write('isUrgent: $isUrgent, ')
          ..write('urgentReason: $urgentReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrescriptionVersionsTableTable extends PrescriptionVersionsTable
    with
        TableInfo<
          $PrescriptionVersionsTableTable,
          PrescriptionVersionsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrescriptionVersionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prescriptionIdMeta = const VerificationMeta(
    'prescriptionId',
  );
  @override
  late final GeneratedColumn<String> prescriptionId = GeneratedColumn<String>(
    'prescription_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionNumberMeta = const VerificationMeta(
    'versionNumber',
  );
  @override
  late final GeneratedColumn<int> versionNumber = GeneratedColumn<int>(
    'version_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changeReasonMeta = const VerificationMeta(
    'changeReason',
  );
  @override
  late final GeneratedColumn<String> changeReason = GeneratedColumn<String>(
    'change_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicationsSnapshotMeta =
      const VerificationMeta('medicationsSnapshot');
  @override
  late final GeneratedColumn<String> medicationsSnapshot =
      GeneratedColumn<String>(
        'medications_snapshot',
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
    prescriptionId,
    versionNumber,
    authorId,
    changeReason,
    medicationsSnapshot,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prescription_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrescriptionVersionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('prescription_id')) {
      context.handle(
        _prescriptionIdMeta,
        prescriptionId.isAcceptableOrUnknown(
          data['prescription_id']!,
          _prescriptionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prescriptionIdMeta);
    }
    if (data.containsKey('version_number')) {
      context.handle(
        _versionNumberMeta,
        versionNumber.isAcceptableOrUnknown(
          data['version_number']!,
          _versionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionNumberMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    }
    if (data.containsKey('change_reason')) {
      context.handle(
        _changeReasonMeta,
        changeReason.isAcceptableOrUnknown(
          data['change_reason']!,
          _changeReasonMeta,
        ),
      );
    }
    if (data.containsKey('medications_snapshot')) {
      context.handle(
        _medicationsSnapshotMeta,
        medicationsSnapshot.isAcceptableOrUnknown(
          data['medications_snapshot']!,
          _medicationsSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationsSnapshotMeta);
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
  PrescriptionVersionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrescriptionVersionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      prescriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescription_id'],
      )!,
      versionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_number'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      ),
      changeReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_reason'],
      ),
      medicationsSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medications_snapshot'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PrescriptionVersionsTableTable createAlias(String alias) {
    return $PrescriptionVersionsTableTable(attachedDatabase, alias);
  }
}

class PrescriptionVersionsTableData extends DataClass
    implements Insertable<PrescriptionVersionsTableData> {
  final String id;
  final String prescriptionId;
  final int versionNumber;
  final String? authorId;
  final String? changeReason;
  final String medicationsSnapshot;
  final DateTime createdAt;
  const PrescriptionVersionsTableData({
    required this.id,
    required this.prescriptionId,
    required this.versionNumber,
    this.authorId,
    this.changeReason,
    required this.medicationsSnapshot,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['prescription_id'] = Variable<String>(prescriptionId);
    map['version_number'] = Variable<int>(versionNumber);
    if (!nullToAbsent || authorId != null) {
      map['author_id'] = Variable<String>(authorId);
    }
    if (!nullToAbsent || changeReason != null) {
      map['change_reason'] = Variable<String>(changeReason);
    }
    map['medications_snapshot'] = Variable<String>(medicationsSnapshot);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PrescriptionVersionsTableCompanion toCompanion(bool nullToAbsent) {
    return PrescriptionVersionsTableCompanion(
      id: Value(id),
      prescriptionId: Value(prescriptionId),
      versionNumber: Value(versionNumber),
      authorId: authorId == null && nullToAbsent
          ? const Value.absent()
          : Value(authorId),
      changeReason: changeReason == null && nullToAbsent
          ? const Value.absent()
          : Value(changeReason),
      medicationsSnapshot: Value(medicationsSnapshot),
      createdAt: Value(createdAt),
    );
  }

  factory PrescriptionVersionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrescriptionVersionsTableData(
      id: serializer.fromJson<String>(json['id']),
      prescriptionId: serializer.fromJson<String>(json['prescriptionId']),
      versionNumber: serializer.fromJson<int>(json['versionNumber']),
      authorId: serializer.fromJson<String?>(json['authorId']),
      changeReason: serializer.fromJson<String?>(json['changeReason']),
      medicationsSnapshot: serializer.fromJson<String>(
        json['medicationsSnapshot'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'prescriptionId': serializer.toJson<String>(prescriptionId),
      'versionNumber': serializer.toJson<int>(versionNumber),
      'authorId': serializer.toJson<String?>(authorId),
      'changeReason': serializer.toJson<String?>(changeReason),
      'medicationsSnapshot': serializer.toJson<String>(medicationsSnapshot),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PrescriptionVersionsTableData copyWith({
    String? id,
    String? prescriptionId,
    int? versionNumber,
    Value<String?> authorId = const Value.absent(),
    Value<String?> changeReason = const Value.absent(),
    String? medicationsSnapshot,
    DateTime? createdAt,
  }) => PrescriptionVersionsTableData(
    id: id ?? this.id,
    prescriptionId: prescriptionId ?? this.prescriptionId,
    versionNumber: versionNumber ?? this.versionNumber,
    authorId: authorId.present ? authorId.value : this.authorId,
    changeReason: changeReason.present ? changeReason.value : this.changeReason,
    medicationsSnapshot: medicationsSnapshot ?? this.medicationsSnapshot,
    createdAt: createdAt ?? this.createdAt,
  );
  PrescriptionVersionsTableData copyWithCompanion(
    PrescriptionVersionsTableCompanion data,
  ) {
    return PrescriptionVersionsTableData(
      id: data.id.present ? data.id.value : this.id,
      prescriptionId: data.prescriptionId.present
          ? data.prescriptionId.value
          : this.prescriptionId,
      versionNumber: data.versionNumber.present
          ? data.versionNumber.value
          : this.versionNumber,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      changeReason: data.changeReason.present
          ? data.changeReason.value
          : this.changeReason,
      medicationsSnapshot: data.medicationsSnapshot.present
          ? data.medicationsSnapshot.value
          : this.medicationsSnapshot,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionVersionsTableData(')
          ..write('id: $id, ')
          ..write('prescriptionId: $prescriptionId, ')
          ..write('versionNumber: $versionNumber, ')
          ..write('authorId: $authorId, ')
          ..write('changeReason: $changeReason, ')
          ..write('medicationsSnapshot: $medicationsSnapshot, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    prescriptionId,
    versionNumber,
    authorId,
    changeReason,
    medicationsSnapshot,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrescriptionVersionsTableData &&
          other.id == this.id &&
          other.prescriptionId == this.prescriptionId &&
          other.versionNumber == this.versionNumber &&
          other.authorId == this.authorId &&
          other.changeReason == this.changeReason &&
          other.medicationsSnapshot == this.medicationsSnapshot &&
          other.createdAt == this.createdAt);
}

class PrescriptionVersionsTableCompanion
    extends UpdateCompanion<PrescriptionVersionsTableData> {
  final Value<String> id;
  final Value<String> prescriptionId;
  final Value<int> versionNumber;
  final Value<String?> authorId;
  final Value<String?> changeReason;
  final Value<String> medicationsSnapshot;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PrescriptionVersionsTableCompanion({
    this.id = const Value.absent(),
    this.prescriptionId = const Value.absent(),
    this.versionNumber = const Value.absent(),
    this.authorId = const Value.absent(),
    this.changeReason = const Value.absent(),
    this.medicationsSnapshot = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrescriptionVersionsTableCompanion.insert({
    required String id,
    required String prescriptionId,
    required int versionNumber,
    this.authorId = const Value.absent(),
    this.changeReason = const Value.absent(),
    required String medicationsSnapshot,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       prescriptionId = Value(prescriptionId),
       versionNumber = Value(versionNumber),
       medicationsSnapshot = Value(medicationsSnapshot),
       createdAt = Value(createdAt);
  static Insertable<PrescriptionVersionsTableData> custom({
    Expression<String>? id,
    Expression<String>? prescriptionId,
    Expression<int>? versionNumber,
    Expression<String>? authorId,
    Expression<String>? changeReason,
    Expression<String>? medicationsSnapshot,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      if (versionNumber != null) 'version_number': versionNumber,
      if (authorId != null) 'author_id': authorId,
      if (changeReason != null) 'change_reason': changeReason,
      if (medicationsSnapshot != null)
        'medications_snapshot': medicationsSnapshot,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrescriptionVersionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? prescriptionId,
    Value<int>? versionNumber,
    Value<String?>? authorId,
    Value<String?>? changeReason,
    Value<String>? medicationsSnapshot,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PrescriptionVersionsTableCompanion(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      versionNumber: versionNumber ?? this.versionNumber,
      authorId: authorId ?? this.authorId,
      changeReason: changeReason ?? this.changeReason,
      medicationsSnapshot: medicationsSnapshot ?? this.medicationsSnapshot,
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
    if (prescriptionId.present) {
      map['prescription_id'] = Variable<String>(prescriptionId.value);
    }
    if (versionNumber.present) {
      map['version_number'] = Variable<int>(versionNumber.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (changeReason.present) {
      map['change_reason'] = Variable<String>(changeReason.value);
    }
    if (medicationsSnapshot.present) {
      map['medications_snapshot'] = Variable<String>(medicationsSnapshot.value);
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
    return (StringBuffer('PrescriptionVersionsTableCompanion(')
          ..write('id: $id, ')
          ..write('prescriptionId: $prescriptionId, ')
          ..write('versionNumber: $versionNumber, ')
          ..write('authorId: $authorId, ')
          ..write('changeReason: $changeReason, ')
          ..write('medicationsSnapshot: $medicationsSnapshot, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTableTable extends MedicationsTable
    with TableInfo<$MedicationsTableTable, MedicationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prescriptionIdMeta = const VerificationMeta(
    'prescriptionId',
  );
  @override
  late final GeneratedColumn<String> prescriptionId = GeneratedColumn<String>(
    'prescription_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowNumberMeta = const VerificationMeta(
    'rowNumber',
  );
  @override
  late final GeneratedColumn<int> rowNumber = GeneratedColumn<int>(
    'row_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicineNameMeta = const VerificationMeta(
    'medicineName',
  );
  @override
  late final GeneratedColumn<String> medicineName = GeneratedColumn<String>(
    'medicine_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicineNameKhmerMeta = const VerificationMeta(
    'medicineNameKhmer',
  );
  @override
  late final GeneratedColumn<String> medicineNameKhmer =
      GeneratedColumn<String>(
        'medicine_name_khmer',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicineTypeMeta = const VerificationMeta(
    'medicineType',
  );
  @override
  late final GeneratedColumn<String> medicineType = GeneratedColumn<String>(
    'medicine_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ORAL'),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('TABLET'),
  );
  static const VerificationMeta _dosageAmountMeta = const VerificationMeta(
    'dosageAmount',
  );
  @override
  late final GeneratedColumn<double> dosageAmount = GeneratedColumn<double>(
    'dosage_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
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
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrnMeta = const VerificationMeta('isPrn');
  @override
  late final GeneratedColumn<bool> isPrn = GeneratedColumn<bool>(
    'is_prn',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_prn" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _beforeMealMeta = const VerificationMeta(
    'beforeMeal',
  );
  @override
  late final GeneratedColumn<bool> beforeMeal = GeneratedColumn<bool>(
    'before_meal',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("before_meal" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    prescriptionId,
    rowNumber,
    batchId,
    medicineName,
    medicineNameKhmer,
    imageUrl,
    medicineType,
    unit,
    dosageAmount,
    description,
    frequency,
    duration,
    isPrn,
    beforeMeal,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('prescription_id')) {
      context.handle(
        _prescriptionIdMeta,
        prescriptionId.isAcceptableOrUnknown(
          data['prescription_id']!,
          _prescriptionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prescriptionIdMeta);
    }
    if (data.containsKey('row_number')) {
      context.handle(
        _rowNumberMeta,
        rowNumber.isAcceptableOrUnknown(data['row_number']!, _rowNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_rowNumberMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    if (data.containsKey('medicine_name')) {
      context.handle(
        _medicineNameMeta,
        medicineName.isAcceptableOrUnknown(
          data['medicine_name']!,
          _medicineNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicineNameMeta);
    }
    if (data.containsKey('medicine_name_khmer')) {
      context.handle(
        _medicineNameKhmerMeta,
        medicineNameKhmer.isAcceptableOrUnknown(
          data['medicine_name_khmer']!,
          _medicineNameKhmerMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('medicine_type')) {
      context.handle(
        _medicineTypeMeta,
        medicineType.isAcceptableOrUnknown(
          data['medicine_type']!,
          _medicineTypeMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('dosage_amount')) {
      context.handle(
        _dosageAmountMeta,
        dosageAmount.isAcceptableOrUnknown(
          data['dosage_amount']!,
          _dosageAmountMeta,
        ),
      );
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
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('is_prn')) {
      context.handle(
        _isPrnMeta,
        isPrn.isAcceptableOrUnknown(data['is_prn']!, _isPrnMeta),
      );
    }
    if (data.containsKey('before_meal')) {
      context.handle(
        _beforeMealMeta,
        beforeMeal.isAcceptableOrUnknown(data['before_meal']!, _beforeMealMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      prescriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescription_id'],
      )!,
      rowNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_number'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
      medicineName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medicine_name'],
      )!,
      medicineNameKhmer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medicine_name_khmer'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      medicineType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medicine_type'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      dosageAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dosage_amount'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      isPrn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_prn'],
      )!,
      beforeMeal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}before_meal'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MedicationsTableTable createAlias(String alias) {
    return $MedicationsTableTable(attachedDatabase, alias);
  }
}

class MedicationsTableData extends DataClass
    implements Insertable<MedicationsTableData> {
  final String id;
  final String prescriptionId;
  final int rowNumber;
  final String? batchId;
  final String medicineName;
  final String? medicineNameKhmer;
  final String? imageUrl;
  final String medicineType;
  final String unit;
  final double dosageAmount;
  final String? description;
  final String? frequency;
  final int? duration;
  final bool isPrn;
  final bool beforeMeal;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MedicationsTableData({
    required this.id,
    required this.prescriptionId,
    required this.rowNumber,
    this.batchId,
    required this.medicineName,
    this.medicineNameKhmer,
    this.imageUrl,
    required this.medicineType,
    required this.unit,
    required this.dosageAmount,
    this.description,
    this.frequency,
    this.duration,
    required this.isPrn,
    required this.beforeMeal,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['prescription_id'] = Variable<String>(prescriptionId);
    map['row_number'] = Variable<int>(rowNumber);
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    map['medicine_name'] = Variable<String>(medicineName);
    if (!nullToAbsent || medicineNameKhmer != null) {
      map['medicine_name_khmer'] = Variable<String>(medicineNameKhmer);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['medicine_type'] = Variable<String>(medicineType);
    map['unit'] = Variable<String>(unit);
    map['dosage_amount'] = Variable<double>(dosageAmount);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || frequency != null) {
      map['frequency'] = Variable<String>(frequency);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    map['is_prn'] = Variable<bool>(isPrn);
    map['before_meal'] = Variable<bool>(beforeMeal);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MedicationsTableCompanion toCompanion(bool nullToAbsent) {
    return MedicationsTableCompanion(
      id: Value(id),
      prescriptionId: Value(prescriptionId),
      rowNumber: Value(rowNumber),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      medicineName: Value(medicineName),
      medicineNameKhmer: medicineNameKhmer == null && nullToAbsent
          ? const Value.absent()
          : Value(medicineNameKhmer),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      medicineType: Value(medicineType),
      unit: Value(unit),
      dosageAmount: Value(dosageAmount),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      frequency: frequency == null && nullToAbsent
          ? const Value.absent()
          : Value(frequency),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      isPrn: Value(isPrn),
      beforeMeal: Value(beforeMeal),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MedicationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationsTableData(
      id: serializer.fromJson<String>(json['id']),
      prescriptionId: serializer.fromJson<String>(json['prescriptionId']),
      rowNumber: serializer.fromJson<int>(json['rowNumber']),
      batchId: serializer.fromJson<String?>(json['batchId']),
      medicineName: serializer.fromJson<String>(json['medicineName']),
      medicineNameKhmer: serializer.fromJson<String?>(
        json['medicineNameKhmer'],
      ),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      medicineType: serializer.fromJson<String>(json['medicineType']),
      unit: serializer.fromJson<String>(json['unit']),
      dosageAmount: serializer.fromJson<double>(json['dosageAmount']),
      description: serializer.fromJson<String?>(json['description']),
      frequency: serializer.fromJson<String?>(json['frequency']),
      duration: serializer.fromJson<int?>(json['duration']),
      isPrn: serializer.fromJson<bool>(json['isPrn']),
      beforeMeal: serializer.fromJson<bool>(json['beforeMeal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'prescriptionId': serializer.toJson<String>(prescriptionId),
      'rowNumber': serializer.toJson<int>(rowNumber),
      'batchId': serializer.toJson<String?>(batchId),
      'medicineName': serializer.toJson<String>(medicineName),
      'medicineNameKhmer': serializer.toJson<String?>(medicineNameKhmer),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'medicineType': serializer.toJson<String>(medicineType),
      'unit': serializer.toJson<String>(unit),
      'dosageAmount': serializer.toJson<double>(dosageAmount),
      'description': serializer.toJson<String?>(description),
      'frequency': serializer.toJson<String?>(frequency),
      'duration': serializer.toJson<int?>(duration),
      'isPrn': serializer.toJson<bool>(isPrn),
      'beforeMeal': serializer.toJson<bool>(beforeMeal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MedicationsTableData copyWith({
    String? id,
    String? prescriptionId,
    int? rowNumber,
    Value<String?> batchId = const Value.absent(),
    String? medicineName,
    Value<String?> medicineNameKhmer = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
    String? medicineType,
    String? unit,
    double? dosageAmount,
    Value<String?> description = const Value.absent(),
    Value<String?> frequency = const Value.absent(),
    Value<int?> duration = const Value.absent(),
    bool? isPrn,
    bool? beforeMeal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MedicationsTableData(
    id: id ?? this.id,
    prescriptionId: prescriptionId ?? this.prescriptionId,
    rowNumber: rowNumber ?? this.rowNumber,
    batchId: batchId.present ? batchId.value : this.batchId,
    medicineName: medicineName ?? this.medicineName,
    medicineNameKhmer: medicineNameKhmer.present
        ? medicineNameKhmer.value
        : this.medicineNameKhmer,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    medicineType: medicineType ?? this.medicineType,
    unit: unit ?? this.unit,
    dosageAmount: dosageAmount ?? this.dosageAmount,
    description: description.present ? description.value : this.description,
    frequency: frequency.present ? frequency.value : this.frequency,
    duration: duration.present ? duration.value : this.duration,
    isPrn: isPrn ?? this.isPrn,
    beforeMeal: beforeMeal ?? this.beforeMeal,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MedicationsTableData copyWithCompanion(MedicationsTableCompanion data) {
    return MedicationsTableData(
      id: data.id.present ? data.id.value : this.id,
      prescriptionId: data.prescriptionId.present
          ? data.prescriptionId.value
          : this.prescriptionId,
      rowNumber: data.rowNumber.present ? data.rowNumber.value : this.rowNumber,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      medicineName: data.medicineName.present
          ? data.medicineName.value
          : this.medicineName,
      medicineNameKhmer: data.medicineNameKhmer.present
          ? data.medicineNameKhmer.value
          : this.medicineNameKhmer,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      medicineType: data.medicineType.present
          ? data.medicineType.value
          : this.medicineType,
      unit: data.unit.present ? data.unit.value : this.unit,
      dosageAmount: data.dosageAmount.present
          ? data.dosageAmount.value
          : this.dosageAmount,
      description: data.description.present
          ? data.description.value
          : this.description,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      duration: data.duration.present ? data.duration.value : this.duration,
      isPrn: data.isPrn.present ? data.isPrn.value : this.isPrn,
      beforeMeal: data.beforeMeal.present
          ? data.beforeMeal.value
          : this.beforeMeal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsTableData(')
          ..write('id: $id, ')
          ..write('prescriptionId: $prescriptionId, ')
          ..write('rowNumber: $rowNumber, ')
          ..write('batchId: $batchId, ')
          ..write('medicineName: $medicineName, ')
          ..write('medicineNameKhmer: $medicineNameKhmer, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('medicineType: $medicineType, ')
          ..write('unit: $unit, ')
          ..write('dosageAmount: $dosageAmount, ')
          ..write('description: $description, ')
          ..write('frequency: $frequency, ')
          ..write('duration: $duration, ')
          ..write('isPrn: $isPrn, ')
          ..write('beforeMeal: $beforeMeal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    prescriptionId,
    rowNumber,
    batchId,
    medicineName,
    medicineNameKhmer,
    imageUrl,
    medicineType,
    unit,
    dosageAmount,
    description,
    frequency,
    duration,
    isPrn,
    beforeMeal,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationsTableData &&
          other.id == this.id &&
          other.prescriptionId == this.prescriptionId &&
          other.rowNumber == this.rowNumber &&
          other.batchId == this.batchId &&
          other.medicineName == this.medicineName &&
          other.medicineNameKhmer == this.medicineNameKhmer &&
          other.imageUrl == this.imageUrl &&
          other.medicineType == this.medicineType &&
          other.unit == this.unit &&
          other.dosageAmount == this.dosageAmount &&
          other.description == this.description &&
          other.frequency == this.frequency &&
          other.duration == this.duration &&
          other.isPrn == this.isPrn &&
          other.beforeMeal == this.beforeMeal &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MedicationsTableCompanion extends UpdateCompanion<MedicationsTableData> {
  final Value<String> id;
  final Value<String> prescriptionId;
  final Value<int> rowNumber;
  final Value<String?> batchId;
  final Value<String> medicineName;
  final Value<String?> medicineNameKhmer;
  final Value<String?> imageUrl;
  final Value<String> medicineType;
  final Value<String> unit;
  final Value<double> dosageAmount;
  final Value<String?> description;
  final Value<String?> frequency;
  final Value<int?> duration;
  final Value<bool> isPrn;
  final Value<bool> beforeMeal;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MedicationsTableCompanion({
    this.id = const Value.absent(),
    this.prescriptionId = const Value.absent(),
    this.rowNumber = const Value.absent(),
    this.batchId = const Value.absent(),
    this.medicineName = const Value.absent(),
    this.medicineNameKhmer = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.medicineType = const Value.absent(),
    this.unit = const Value.absent(),
    this.dosageAmount = const Value.absent(),
    this.description = const Value.absent(),
    this.frequency = const Value.absent(),
    this.duration = const Value.absent(),
    this.isPrn = const Value.absent(),
    this.beforeMeal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsTableCompanion.insert({
    required String id,
    required String prescriptionId,
    required int rowNumber,
    this.batchId = const Value.absent(),
    required String medicineName,
    this.medicineNameKhmer = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.medicineType = const Value.absent(),
    this.unit = const Value.absent(),
    this.dosageAmount = const Value.absent(),
    this.description = const Value.absent(),
    this.frequency = const Value.absent(),
    this.duration = const Value.absent(),
    this.isPrn = const Value.absent(),
    this.beforeMeal = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       prescriptionId = Value(prescriptionId),
       rowNumber = Value(rowNumber),
       medicineName = Value(medicineName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MedicationsTableData> custom({
    Expression<String>? id,
    Expression<String>? prescriptionId,
    Expression<int>? rowNumber,
    Expression<String>? batchId,
    Expression<String>? medicineName,
    Expression<String>? medicineNameKhmer,
    Expression<String>? imageUrl,
    Expression<String>? medicineType,
    Expression<String>? unit,
    Expression<double>? dosageAmount,
    Expression<String>? description,
    Expression<String>? frequency,
    Expression<int>? duration,
    Expression<bool>? isPrn,
    Expression<bool>? beforeMeal,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      if (rowNumber != null) 'row_number': rowNumber,
      if (batchId != null) 'batch_id': batchId,
      if (medicineName != null) 'medicine_name': medicineName,
      if (medicineNameKhmer != null) 'medicine_name_khmer': medicineNameKhmer,
      if (imageUrl != null) 'image_url': imageUrl,
      if (medicineType != null) 'medicine_type': medicineType,
      if (unit != null) 'unit': unit,
      if (dosageAmount != null) 'dosage_amount': dosageAmount,
      if (description != null) 'description': description,
      if (frequency != null) 'frequency': frequency,
      if (duration != null) 'duration': duration,
      if (isPrn != null) 'is_prn': isPrn,
      if (beforeMeal != null) 'before_meal': beforeMeal,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? prescriptionId,
    Value<int>? rowNumber,
    Value<String?>? batchId,
    Value<String>? medicineName,
    Value<String?>? medicineNameKhmer,
    Value<String?>? imageUrl,
    Value<String>? medicineType,
    Value<String>? unit,
    Value<double>? dosageAmount,
    Value<String?>? description,
    Value<String?>? frequency,
    Value<int?>? duration,
    Value<bool>? isPrn,
    Value<bool>? beforeMeal,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MedicationsTableCompanion(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      rowNumber: rowNumber ?? this.rowNumber,
      batchId: batchId ?? this.batchId,
      medicineName: medicineName ?? this.medicineName,
      medicineNameKhmer: medicineNameKhmer ?? this.medicineNameKhmer,
      imageUrl: imageUrl ?? this.imageUrl,
      medicineType: medicineType ?? this.medicineType,
      unit: unit ?? this.unit,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      isPrn: isPrn ?? this.isPrn,
      beforeMeal: beforeMeal ?? this.beforeMeal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (prescriptionId.present) {
      map['prescription_id'] = Variable<String>(prescriptionId.value);
    }
    if (rowNumber.present) {
      map['row_number'] = Variable<int>(rowNumber.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (medicineName.present) {
      map['medicine_name'] = Variable<String>(medicineName.value);
    }
    if (medicineNameKhmer.present) {
      map['medicine_name_khmer'] = Variable<String>(medicineNameKhmer.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (medicineType.present) {
      map['medicine_type'] = Variable<String>(medicineType.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (dosageAmount.present) {
      map['dosage_amount'] = Variable<double>(dosageAmount.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (isPrn.present) {
      map['is_prn'] = Variable<bool>(isPrn.value);
    }
    if (beforeMeal.present) {
      map['before_meal'] = Variable<bool>(beforeMeal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsTableCompanion(')
          ..write('id: $id, ')
          ..write('prescriptionId: $prescriptionId, ')
          ..write('rowNumber: $rowNumber, ')
          ..write('batchId: $batchId, ')
          ..write('medicineName: $medicineName, ')
          ..write('medicineNameKhmer: $medicineNameKhmer, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('medicineType: $medicineType, ')
          ..write('unit: $unit, ')
          ..write('dosageAmount: $dosageAmount, ')
          ..write('description: $description, ')
          ..write('frequency: $frequency, ')
          ..write('duration: $duration, ')
          ..write('isPrn: $isPrn, ')
          ..write('beforeMeal: $beforeMeal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DoseEventsTableTable extends DoseEventsTable
    with TableInfo<$DoseEventsTableTable, DoseEventsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DoseEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prescriptionIdMeta = const VerificationMeta(
    'prescriptionId',
  );
  @override
  late final GeneratedColumn<String> prescriptionId = GeneratedColumn<String>(
    'prescription_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledTimeMeta = const VerificationMeta(
    'scheduledTime',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledTime =
      GeneratedColumn<DateTime>(
        'scheduled_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _timePeriodMeta = const VerificationMeta(
    'timePeriod',
  );
  @override
  late final GeneratedColumn<String> timePeriod = GeneratedColumn<String>(
    'time_period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
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
    defaultValue: const Constant('DUE'),
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skipReasonMeta = const VerificationMeta(
    'skipReason',
  );
  @override
  late final GeneratedColumn<String> skipReason = GeneratedColumn<String>(
    'skip_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wasOfflineMeta = const VerificationMeta(
    'wasOffline',
  );
  @override
  late final GeneratedColumn<bool> wasOffline = GeneratedColumn<bool>(
    'was_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    prescriptionId,
    medicationId,
    patientId,
    scheduledTime,
    timePeriod,
    reminderTime,
    status,
    takenAt,
    skipReason,
    wasOffline,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dose_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DoseEventsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('prescription_id')) {
      context.handle(
        _prescriptionIdMeta,
        prescriptionId.isAcceptableOrUnknown(
          data['prescription_id']!,
          _prescriptionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prescriptionIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('scheduled_time')) {
      context.handle(
        _scheduledTimeMeta,
        scheduledTime.isAcceptableOrUnknown(
          data['scheduled_time']!,
          _scheduledTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledTimeMeta);
    }
    if (data.containsKey('time_period')) {
      context.handle(
        _timePeriodMeta,
        timePeriod.isAcceptableOrUnknown(data['time_period']!, _timePeriodMeta),
      );
    } else if (isInserting) {
      context.missing(_timePeriodMeta);
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    if (data.containsKey('skip_reason')) {
      context.handle(
        _skipReasonMeta,
        skipReason.isAcceptableOrUnknown(data['skip_reason']!, _skipReasonMeta),
      );
    }
    if (data.containsKey('was_offline')) {
      context.handle(
        _wasOfflineMeta,
        wasOffline.isAcceptableOrUnknown(data['was_offline']!, _wasOfflineMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DoseEventsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoseEventsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      prescriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prescription_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      scheduledTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_time'],
      )!,
      timePeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_period'],
      )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      ),
      skipReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skip_reason'],
      ),
      wasOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_offline'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DoseEventsTableTable createAlias(String alias) {
    return $DoseEventsTableTable(attachedDatabase, alias);
  }
}

class DoseEventsTableData extends DataClass
    implements Insertable<DoseEventsTableData> {
  final String id;
  final String prescriptionId;
  final String medicationId;
  final String patientId;
  final DateTime scheduledTime;
  final String timePeriod;
  final String? reminderTime;
  final String status;
  final DateTime? takenAt;
  final String? skipReason;
  final bool wasOffline;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DoseEventsTableData({
    required this.id,
    required this.prescriptionId,
    required this.medicationId,
    required this.patientId,
    required this.scheduledTime,
    required this.timePeriod,
    this.reminderTime,
    required this.status,
    this.takenAt,
    this.skipReason,
    required this.wasOffline,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['prescription_id'] = Variable<String>(prescriptionId);
    map['medication_id'] = Variable<String>(medicationId);
    map['patient_id'] = Variable<String>(patientId);
    map['scheduled_time'] = Variable<DateTime>(scheduledTime);
    map['time_period'] = Variable<String>(timePeriod);
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<DateTime>(takenAt);
    }
    if (!nullToAbsent || skipReason != null) {
      map['skip_reason'] = Variable<String>(skipReason);
    }
    map['was_offline'] = Variable<bool>(wasOffline);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DoseEventsTableCompanion toCompanion(bool nullToAbsent) {
    return DoseEventsTableCompanion(
      id: Value(id),
      prescriptionId: Value(prescriptionId),
      medicationId: Value(medicationId),
      patientId: Value(patientId),
      scheduledTime: Value(scheduledTime),
      timePeriod: Value(timePeriod),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      status: Value(status),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      skipReason: skipReason == null && nullToAbsent
          ? const Value.absent()
          : Value(skipReason),
      wasOffline: Value(wasOffline),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DoseEventsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoseEventsTableData(
      id: serializer.fromJson<String>(json['id']),
      prescriptionId: serializer.fromJson<String>(json['prescriptionId']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      scheduledTime: serializer.fromJson<DateTime>(json['scheduledTime']),
      timePeriod: serializer.fromJson<String>(json['timePeriod']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      status: serializer.fromJson<String>(json['status']),
      takenAt: serializer.fromJson<DateTime?>(json['takenAt']),
      skipReason: serializer.fromJson<String?>(json['skipReason']),
      wasOffline: serializer.fromJson<bool>(json['wasOffline']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'prescriptionId': serializer.toJson<String>(prescriptionId),
      'medicationId': serializer.toJson<String>(medicationId),
      'patientId': serializer.toJson<String>(patientId),
      'scheduledTime': serializer.toJson<DateTime>(scheduledTime),
      'timePeriod': serializer.toJson<String>(timePeriod),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'status': serializer.toJson<String>(status),
      'takenAt': serializer.toJson<DateTime?>(takenAt),
      'skipReason': serializer.toJson<String?>(skipReason),
      'wasOffline': serializer.toJson<bool>(wasOffline),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DoseEventsTableData copyWith({
    String? id,
    String? prescriptionId,
    String? medicationId,
    String? patientId,
    DateTime? scheduledTime,
    String? timePeriod,
    Value<String?> reminderTime = const Value.absent(),
    String? status,
    Value<DateTime?> takenAt = const Value.absent(),
    Value<String?> skipReason = const Value.absent(),
    bool? wasOffline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DoseEventsTableData(
    id: id ?? this.id,
    prescriptionId: prescriptionId ?? this.prescriptionId,
    medicationId: medicationId ?? this.medicationId,
    patientId: patientId ?? this.patientId,
    scheduledTime: scheduledTime ?? this.scheduledTime,
    timePeriod: timePeriod ?? this.timePeriod,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    status: status ?? this.status,
    takenAt: takenAt.present ? takenAt.value : this.takenAt,
    skipReason: skipReason.present ? skipReason.value : this.skipReason,
    wasOffline: wasOffline ?? this.wasOffline,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DoseEventsTableData copyWithCompanion(DoseEventsTableCompanion data) {
    return DoseEventsTableData(
      id: data.id.present ? data.id.value : this.id,
      prescriptionId: data.prescriptionId.present
          ? data.prescriptionId.value
          : this.prescriptionId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      scheduledTime: data.scheduledTime.present
          ? data.scheduledTime.value
          : this.scheduledTime,
      timePeriod: data.timePeriod.present
          ? data.timePeriod.value
          : this.timePeriod,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      status: data.status.present ? data.status.value : this.status,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      skipReason: data.skipReason.present
          ? data.skipReason.value
          : this.skipReason,
      wasOffline: data.wasOffline.present
          ? data.wasOffline.value
          : this.wasOffline,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoseEventsTableData(')
          ..write('id: $id, ')
          ..write('prescriptionId: $prescriptionId, ')
          ..write('medicationId: $medicationId, ')
          ..write('patientId: $patientId, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('timePeriod: $timePeriod, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('status: $status, ')
          ..write('takenAt: $takenAt, ')
          ..write('skipReason: $skipReason, ')
          ..write('wasOffline: $wasOffline, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    prescriptionId,
    medicationId,
    patientId,
    scheduledTime,
    timePeriod,
    reminderTime,
    status,
    takenAt,
    skipReason,
    wasOffline,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoseEventsTableData &&
          other.id == this.id &&
          other.prescriptionId == this.prescriptionId &&
          other.medicationId == this.medicationId &&
          other.patientId == this.patientId &&
          other.scheduledTime == this.scheduledTime &&
          other.timePeriod == this.timePeriod &&
          other.reminderTime == this.reminderTime &&
          other.status == this.status &&
          other.takenAt == this.takenAt &&
          other.skipReason == this.skipReason &&
          other.wasOffline == this.wasOffline &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DoseEventsTableCompanion extends UpdateCompanion<DoseEventsTableData> {
  final Value<String> id;
  final Value<String> prescriptionId;
  final Value<String> medicationId;
  final Value<String> patientId;
  final Value<DateTime> scheduledTime;
  final Value<String> timePeriod;
  final Value<String?> reminderTime;
  final Value<String> status;
  final Value<DateTime?> takenAt;
  final Value<String?> skipReason;
  final Value<bool> wasOffline;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DoseEventsTableCompanion({
    this.id = const Value.absent(),
    this.prescriptionId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.timePeriod = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.status = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.skipReason = const Value.absent(),
    this.wasOffline = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DoseEventsTableCompanion.insert({
    required String id,
    required String prescriptionId,
    required String medicationId,
    required String patientId,
    required DateTime scheduledTime,
    required String timePeriod,
    this.reminderTime = const Value.absent(),
    this.status = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.skipReason = const Value.absent(),
    this.wasOffline = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       prescriptionId = Value(prescriptionId),
       medicationId = Value(medicationId),
       patientId = Value(patientId),
       scheduledTime = Value(scheduledTime),
       timePeriod = Value(timePeriod),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DoseEventsTableData> custom({
    Expression<String>? id,
    Expression<String>? prescriptionId,
    Expression<String>? medicationId,
    Expression<String>? patientId,
    Expression<DateTime>? scheduledTime,
    Expression<String>? timePeriod,
    Expression<String>? reminderTime,
    Expression<String>? status,
    Expression<DateTime>? takenAt,
    Expression<String>? skipReason,
    Expression<bool>? wasOffline,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      if (medicationId != null) 'medication_id': medicationId,
      if (patientId != null) 'patient_id': patientId,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (timePeriod != null) 'time_period': timePeriod,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (status != null) 'status': status,
      if (takenAt != null) 'taken_at': takenAt,
      if (skipReason != null) 'skip_reason': skipReason,
      if (wasOffline != null) 'was_offline': wasOffline,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DoseEventsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? prescriptionId,
    Value<String>? medicationId,
    Value<String>? patientId,
    Value<DateTime>? scheduledTime,
    Value<String>? timePeriod,
    Value<String?>? reminderTime,
    Value<String>? status,
    Value<DateTime?>? takenAt,
    Value<String?>? skipReason,
    Value<bool>? wasOffline,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DoseEventsTableCompanion(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      medicationId: medicationId ?? this.medicationId,
      patientId: patientId ?? this.patientId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      timePeriod: timePeriod ?? this.timePeriod,
      reminderTime: reminderTime ?? this.reminderTime,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      skipReason: skipReason ?? this.skipReason,
      wasOffline: wasOffline ?? this.wasOffline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (prescriptionId.present) {
      map['prescription_id'] = Variable<String>(prescriptionId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (scheduledTime.present) {
      map['scheduled_time'] = Variable<DateTime>(scheduledTime.value);
    }
    if (timePeriod.present) {
      map['time_period'] = Variable<String>(timePeriod.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (skipReason.present) {
      map['skip_reason'] = Variable<String>(skipReason.value);
    }
    if (wasOffline.present) {
      map['was_offline'] = Variable<bool>(wasOffline.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoseEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('prescriptionId: $prescriptionId, ')
          ..write('medicationId: $medicationId, ')
          ..write('patientId: $patientId, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('timePeriod: $timePeriod, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('status: $status, ')
          ..write('takenAt: $takenAt, ')
          ..write('skipReason: $skipReason, ')
          ..write('wasOffline: $wasOffline, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationsTableTable extends NotificationsTable
    with TableInfo<$NotificationsTableTable, NotificationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipientIdMeta = const VerificationMeta(
    'recipientId',
  );
  @override
  late final GeneratedColumn<String> recipientId = GeneratedColumn<String>(
    'recipient_id',
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
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    id,
    recipientId,
    type,
    title,
    message,
    data,
    isRead,
    readAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipient_id')) {
      context.handle(
        _recipientIdMeta,
        recipientId.isAcceptableOrUnknown(
          data['recipient_id']!,
          _recipientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
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
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      ),
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NotificationsTableTable createAlias(String alias) {
    return $NotificationsTableTable(attachedDatabase, alias);
  }
}

class NotificationsTableData extends DataClass
    implements Insertable<NotificationsTableData> {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String message;
  final String? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  const NotificationsTableData({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['recipient_id'] = Variable<String>(recipientId);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<String>(data);
    }
    map['is_read'] = Variable<bool>(isRead);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NotificationsTableCompanion toCompanion(bool nullToAbsent) {
    return NotificationsTableCompanion(
      id: Value(id),
      recipientId: Value(recipientId),
      type: Value(type),
      title: Value(title),
      message: Value(message),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      isRead: Value(isRead),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      createdAt: Value(createdAt),
    );
  }

  factory NotificationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationsTableData(
      id: serializer.fromJson<String>(json['id']),
      recipientId: serializer.fromJson<String>(json['recipientId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      message: serializer.fromJson<String>(json['message']),
      data: serializer.fromJson<String?>(json['data']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipientId': serializer.toJson<String>(recipientId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'message': serializer.toJson<String>(message),
      'data': serializer.toJson<String?>(data),
      'isRead': serializer.toJson<bool>(isRead),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NotificationsTableData copyWith({
    String? id,
    String? recipientId,
    String? type,
    String? title,
    String? message,
    Value<String?> data = const Value.absent(),
    bool? isRead,
    Value<DateTime?> readAt = const Value.absent(),
    DateTime? createdAt,
  }) => NotificationsTableData(
    id: id ?? this.id,
    recipientId: recipientId ?? this.recipientId,
    type: type ?? this.type,
    title: title ?? this.title,
    message: message ?? this.message,
    data: data.present ? data.value : this.data,
    isRead: isRead ?? this.isRead,
    readAt: readAt.present ? readAt.value : this.readAt,
    createdAt: createdAt ?? this.createdAt,
  );
  NotificationsTableData copyWithCompanion(NotificationsTableCompanion data) {
    return NotificationsTableData(
      id: data.id.present ? data.id.value : this.id,
      recipientId: data.recipientId.present
          ? data.recipientId.value
          : this.recipientId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      message: data.message.present ? data.message.value : this.message,
      data: data.data.present ? data.data.value : this.data,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsTableData(')
          ..write('id: $id, ')
          ..write('recipientId: $recipientId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('data: $data, ')
          ..write('isRead: $isRead, ')
          ..write('readAt: $readAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recipientId,
    type,
    title,
    message,
    data,
    isRead,
    readAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationsTableData &&
          other.id == this.id &&
          other.recipientId == this.recipientId &&
          other.type == this.type &&
          other.title == this.title &&
          other.message == this.message &&
          other.data == this.data &&
          other.isRead == this.isRead &&
          other.readAt == this.readAt &&
          other.createdAt == this.createdAt);
}

class NotificationsTableCompanion
    extends UpdateCompanion<NotificationsTableData> {
  final Value<String> id;
  final Value<String> recipientId;
  final Value<String> type;
  final Value<String> title;
  final Value<String> message;
  final Value<String?> data;
  final Value<bool> isRead;
  final Value<DateTime?> readAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const NotificationsTableCompanion({
    this.id = const Value.absent(),
    this.recipientId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.message = const Value.absent(),
    this.data = const Value.absent(),
    this.isRead = const Value.absent(),
    this.readAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsTableCompanion.insert({
    required String id,
    required String recipientId,
    required String type,
    required String title,
    required String message,
    this.data = const Value.absent(),
    this.isRead = const Value.absent(),
    this.readAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recipientId = Value(recipientId),
       type = Value(type),
       title = Value(title),
       message = Value(message),
       createdAt = Value(createdAt);
  static Insertable<NotificationsTableData> custom({
    Expression<String>? id,
    Expression<String>? recipientId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? message,
    Expression<String>? data,
    Expression<bool>? isRead,
    Expression<DateTime>? readAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipientId != null) 'recipient_id': recipientId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (data != null) 'data': data,
      if (isRead != null) 'is_read': isRead,
      if (readAt != null) 'read_at': readAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? recipientId,
    Value<String>? type,
    Value<String>? title,
    Value<String>? message,
    Value<String?>? data,
    Value<bool>? isRead,
    Value<DateTime?>? readAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return NotificationsTableCompanion(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
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
    if (recipientId.present) {
      map['recipient_id'] = Variable<String>(recipientId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
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
    return (StringBuffer('NotificationsTableCompanion(')
          ..write('id: $id, ')
          ..write('recipientId: $recipientId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('message: $message, ')
          ..write('data: $data, ')
          ..write('isRead: $isRead, ')
          ..write('readAt: $readAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogsTableTable extends AuditLogsTable
    with TableInfo<$AuditLogsTableTable, AuditLogsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorIdMeta = const VerificationMeta(
    'actorId',
  );
  @override
  late final GeneratedColumn<String> actorId = GeneratedColumn<String>(
    'actor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorRoleMeta = const VerificationMeta(
    'actorRole',
  );
  @override
  late final GeneratedColumn<String> actorRole = GeneratedColumn<String>(
    'actor_role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resourceTypeMeta = const VerificationMeta(
    'resourceType',
  );
  @override
  late final GeneratedColumn<String> resourceType = GeneratedColumn<String>(
    'resource_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
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
    id,
    actorId,
    actorRole,
    actionType,
    resourceType,
    resourceId,
    details,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('actor_id')) {
      context.handle(
        _actorIdMeta,
        actorId.isAcceptableOrUnknown(data['actor_id']!, _actorIdMeta),
      );
    }
    if (data.containsKey('actor_role')) {
      context.handle(
        _actorRoleMeta,
        actorRole.isAcceptableOrUnknown(data['actor_role']!, _actorRoleMeta),
      );
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('resource_type')) {
      context.handle(
        _resourceTypeMeta,
        resourceType.isAcceptableOrUnknown(
          data['resource_type']!,
          _resourceTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resourceTypeMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      actorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_id'],
      ),
      actorRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_role'],
      ),
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      resourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_type'],
      )!,
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      ),
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AuditLogsTableTable createAlias(String alias) {
    return $AuditLogsTableTable(attachedDatabase, alias);
  }
}

class AuditLogsTableData extends DataClass
    implements Insertable<AuditLogsTableData> {
  final String id;
  final String? actorId;
  final String? actorRole;
  final String actionType;
  final String resourceType;
  final String? resourceId;
  final String? details;
  final DateTime createdAt;
  const AuditLogsTableData({
    required this.id,
    this.actorId,
    this.actorRole,
    required this.actionType,
    required this.resourceType,
    this.resourceId,
    this.details,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || actorId != null) {
      map['actor_id'] = Variable<String>(actorId);
    }
    if (!nullToAbsent || actorRole != null) {
      map['actor_role'] = Variable<String>(actorRole);
    }
    map['action_type'] = Variable<String>(actionType);
    map['resource_type'] = Variable<String>(resourceType);
    if (!nullToAbsent || resourceId != null) {
      map['resource_id'] = Variable<String>(resourceId);
    }
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuditLogsTableCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsTableCompanion(
      id: Value(id),
      actorId: actorId == null && nullToAbsent
          ? const Value.absent()
          : Value(actorId),
      actorRole: actorRole == null && nullToAbsent
          ? const Value.absent()
          : Value(actorRole),
      actionType: Value(actionType),
      resourceType: Value(resourceType),
      resourceId: resourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceId),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      createdAt: Value(createdAt),
    );
  }

  factory AuditLogsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogsTableData(
      id: serializer.fromJson<String>(json['id']),
      actorId: serializer.fromJson<String?>(json['actorId']),
      actorRole: serializer.fromJson<String?>(json['actorRole']),
      actionType: serializer.fromJson<String>(json['actionType']),
      resourceType: serializer.fromJson<String>(json['resourceType']),
      resourceId: serializer.fromJson<String?>(json['resourceId']),
      details: serializer.fromJson<String?>(json['details']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'actorId': serializer.toJson<String?>(actorId),
      'actorRole': serializer.toJson<String?>(actorRole),
      'actionType': serializer.toJson<String>(actionType),
      'resourceType': serializer.toJson<String>(resourceType),
      'resourceId': serializer.toJson<String?>(resourceId),
      'details': serializer.toJson<String?>(details),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuditLogsTableData copyWith({
    String? id,
    Value<String?> actorId = const Value.absent(),
    Value<String?> actorRole = const Value.absent(),
    String? actionType,
    String? resourceType,
    Value<String?> resourceId = const Value.absent(),
    Value<String?> details = const Value.absent(),
    DateTime? createdAt,
  }) => AuditLogsTableData(
    id: id ?? this.id,
    actorId: actorId.present ? actorId.value : this.actorId,
    actorRole: actorRole.present ? actorRole.value : this.actorRole,
    actionType: actionType ?? this.actionType,
    resourceType: resourceType ?? this.resourceType,
    resourceId: resourceId.present ? resourceId.value : this.resourceId,
    details: details.present ? details.value : this.details,
    createdAt: createdAt ?? this.createdAt,
  );
  AuditLogsTableData copyWithCompanion(AuditLogsTableCompanion data) {
    return AuditLogsTableData(
      id: data.id.present ? data.id.value : this.id,
      actorId: data.actorId.present ? data.actorId.value : this.actorId,
      actorRole: data.actorRole.present ? data.actorRole.value : this.actorRole,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      resourceType: data.resourceType.present
          ? data.resourceType.value
          : this.resourceType,
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      details: data.details.present ? data.details.value : this.details,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsTableData(')
          ..write('id: $id, ')
          ..write('actorId: $actorId, ')
          ..write('actorRole: $actorRole, ')
          ..write('actionType: $actionType, ')
          ..write('resourceType: $resourceType, ')
          ..write('resourceId: $resourceId, ')
          ..write('details: $details, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actorId,
    actorRole,
    actionType,
    resourceType,
    resourceId,
    details,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogsTableData &&
          other.id == this.id &&
          other.actorId == this.actorId &&
          other.actorRole == this.actorRole &&
          other.actionType == this.actionType &&
          other.resourceType == this.resourceType &&
          other.resourceId == this.resourceId &&
          other.details == this.details &&
          other.createdAt == this.createdAt);
}

class AuditLogsTableCompanion extends UpdateCompanion<AuditLogsTableData> {
  final Value<String> id;
  final Value<String?> actorId;
  final Value<String?> actorRole;
  final Value<String> actionType;
  final Value<String> resourceType;
  final Value<String?> resourceId;
  final Value<String?> details;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AuditLogsTableCompanion({
    this.id = const Value.absent(),
    this.actorId = const Value.absent(),
    this.actorRole = const Value.absent(),
    this.actionType = const Value.absent(),
    this.resourceType = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.details = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogsTableCompanion.insert({
    required String id,
    this.actorId = const Value.absent(),
    this.actorRole = const Value.absent(),
    required String actionType,
    required String resourceType,
    this.resourceId = const Value.absent(),
    this.details = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       actionType = Value(actionType),
       resourceType = Value(resourceType),
       createdAt = Value(createdAt);
  static Insertable<AuditLogsTableData> custom({
    Expression<String>? id,
    Expression<String>? actorId,
    Expression<String>? actorRole,
    Expression<String>? actionType,
    Expression<String>? resourceType,
    Expression<String>? resourceId,
    Expression<String>? details,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actorId != null) 'actor_id': actorId,
      if (actorRole != null) 'actor_role': actorRole,
      if (actionType != null) 'action_type': actionType,
      if (resourceType != null) 'resource_type': resourceType,
      if (resourceId != null) 'resource_id': resourceId,
      if (details != null) 'details': details,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogsTableCompanion copyWith({
    Value<String>? id,
    Value<String?>? actorId,
    Value<String?>? actorRole,
    Value<String>? actionType,
    Value<String>? resourceType,
    Value<String?>? resourceId,
    Value<String?>? details,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AuditLogsTableCompanion(
      id: id ?? this.id,
      actorId: actorId ?? this.actorId,
      actorRole: actorRole ?? this.actorRole,
      actionType: actionType ?? this.actionType,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      details: details ?? this.details,
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
    if (actorId.present) {
      map['actor_id'] = Variable<String>(actorId.value);
    }
    if (actorRole.present) {
      map['actor_role'] = Variable<String>(actorRole.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (resourceType.present) {
      map['resource_type'] = Variable<String>(resourceType.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
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
    return (StringBuffer('AuditLogsTableCompanion(')
          ..write('id: $id, ')
          ..write('actorId: $actorId, ')
          ..write('actorRole: $actorRole, ')
          ..write('actionType: $actionType, ')
          ..write('resourceType: $resourceType, ')
          ..write('resourceId: $resourceId, ')
          ..write('details: $details, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTableTable extends SubscriptionsTable
    with TableInfo<$SubscriptionsTableTable, SubscriptionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('FREEMIUM'),
  );
  static const VerificationMeta _storageQuotaMeta = const VerificationMeta(
    'storageQuota',
  );
  @override
  late final GeneratedColumn<BigInt> storageQuota = GeneratedColumn<BigInt>(
    'storage_quota',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
    defaultValue: Constant(BigInt.from(5368709120)),
  );
  static const VerificationMeta _storageUsedMeta = const VerificationMeta(
    'storageUsed',
  );
  @override
  late final GeneratedColumn<BigInt> storageUsed = GeneratedColumn<BigInt>(
    'storage_used',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: false,
    defaultValue: Constant(BigInt.from(0)),
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasUsedTrialMeta = const VerificationMeta(
    'hasUsedTrial',
  );
  @override
  late final GeneratedColumn<bool> hasUsedTrial = GeneratedColumn<bool>(
    'has_used_trial',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_used_trial" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _playStateMeta = const VerificationMeta(
    'playState',
  );
  @override
  late final GeneratedColumn<String> playState = GeneratedColumn<String>(
    'play_state',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    tier,
    storageQuota,
    storageUsed,
    expiresAt,
    hasUsedTrial,
    playState,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    }
    if (data.containsKey('storage_quota')) {
      context.handle(
        _storageQuotaMeta,
        storageQuota.isAcceptableOrUnknown(
          data['storage_quota']!,
          _storageQuotaMeta,
        ),
      );
    }
    if (data.containsKey('storage_used')) {
      context.handle(
        _storageUsedMeta,
        storageUsed.isAcceptableOrUnknown(
          data['storage_used']!,
          _storageUsedMeta,
        ),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('has_used_trial')) {
      context.handle(
        _hasUsedTrialMeta,
        hasUsedTrial.isAcceptableOrUnknown(
          data['has_used_trial']!,
          _hasUsedTrialMeta,
        ),
      );
    }
    if (data.containsKey('play_state')) {
      context.handle(
        _playStateMeta,
        playState.isAcceptableOrUnknown(data['play_state']!, _playStateMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubscriptionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier'],
      )!,
      storageQuota: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}storage_quota'],
      )!,
      storageUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}storage_used'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      hasUsedTrial: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_used_trial'],
      )!,
      playState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}play_state'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SubscriptionsTableTable createAlias(String alias) {
    return $SubscriptionsTableTable(attachedDatabase, alias);
  }
}

class SubscriptionsTableData extends DataClass
    implements Insertable<SubscriptionsTableData> {
  final String id;
  final String userId;
  final String tier;
  final BigInt storageQuota;
  final BigInt storageUsed;
  final DateTime? expiresAt;
  final bool hasUsedTrial;
  final String? playState;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SubscriptionsTableData({
    required this.id,
    required this.userId,
    required this.tier,
    required this.storageQuota,
    required this.storageUsed,
    this.expiresAt,
    required this.hasUsedTrial,
    this.playState,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['tier'] = Variable<String>(tier);
    map['storage_quota'] = Variable<BigInt>(storageQuota);
    map['storage_used'] = Variable<BigInt>(storageUsed);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['has_used_trial'] = Variable<bool>(hasUsedTrial);
    if (!nullToAbsent || playState != null) {
      map['play_state'] = Variable<String>(playState);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SubscriptionsTableCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsTableCompanion(
      id: Value(id),
      userId: Value(userId),
      tier: Value(tier),
      storageQuota: Value(storageQuota),
      storageUsed: Value(storageUsed),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      hasUsedTrial: Value(hasUsedTrial),
      playState: playState == null && nullToAbsent
          ? const Value.absent()
          : Value(playState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubscriptionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionsTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      tier: serializer.fromJson<String>(json['tier']),
      storageQuota: serializer.fromJson<BigInt>(json['storageQuota']),
      storageUsed: serializer.fromJson<BigInt>(json['storageUsed']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      hasUsedTrial: serializer.fromJson<bool>(json['hasUsedTrial']),
      playState: serializer.fromJson<String?>(json['playState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'tier': serializer.toJson<String>(tier),
      'storageQuota': serializer.toJson<BigInt>(storageQuota),
      'storageUsed': serializer.toJson<BigInt>(storageUsed),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'hasUsedTrial': serializer.toJson<bool>(hasUsedTrial),
      'playState': serializer.toJson<String?>(playState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SubscriptionsTableData copyWith({
    String? id,
    String? userId,
    String? tier,
    BigInt? storageQuota,
    BigInt? storageUsed,
    Value<DateTime?> expiresAt = const Value.absent(),
    bool? hasUsedTrial,
    Value<String?> playState = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SubscriptionsTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    tier: tier ?? this.tier,
    storageQuota: storageQuota ?? this.storageQuota,
    storageUsed: storageUsed ?? this.storageUsed,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    hasUsedTrial: hasUsedTrial ?? this.hasUsedTrial,
    playState: playState.present ? playState.value : this.playState,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SubscriptionsTableData copyWithCompanion(SubscriptionsTableCompanion data) {
    return SubscriptionsTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      tier: data.tier.present ? data.tier.value : this.tier,
      storageQuota: data.storageQuota.present
          ? data.storageQuota.value
          : this.storageQuota,
      storageUsed: data.storageUsed.present
          ? data.storageUsed.value
          : this.storageUsed,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      hasUsedTrial: data.hasUsedTrial.present
          ? data.hasUsedTrial.value
          : this.hasUsedTrial,
      playState: data.playState.present ? data.playState.value : this.playState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tier: $tier, ')
          ..write('storageQuota: $storageQuota, ')
          ..write('storageUsed: $storageUsed, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('hasUsedTrial: $hasUsedTrial, ')
          ..write('playState: $playState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    tier,
    storageQuota,
    storageUsed,
    expiresAt,
    hasUsedTrial,
    playState,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionsTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.tier == this.tier &&
          other.storageQuota == this.storageQuota &&
          other.storageUsed == this.storageUsed &&
          other.expiresAt == this.expiresAt &&
          other.hasUsedTrial == this.hasUsedTrial &&
          other.playState == this.playState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubscriptionsTableCompanion
    extends UpdateCompanion<SubscriptionsTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> tier;
  final Value<BigInt> storageQuota;
  final Value<BigInt> storageUsed;
  final Value<DateTime?> expiresAt;
  final Value<bool> hasUsedTrial;
  final Value<String?> playState;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SubscriptionsTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.tier = const Value.absent(),
    this.storageQuota = const Value.absent(),
    this.storageUsed = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.hasUsedTrial = const Value.absent(),
    this.playState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubscriptionsTableCompanion.insert({
    required String id,
    required String userId,
    this.tier = const Value.absent(),
    this.storageQuota = const Value.absent(),
    this.storageUsed = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.hasUsedTrial = const Value.absent(),
    this.playState = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SubscriptionsTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? tier,
    Expression<BigInt>? storageQuota,
    Expression<BigInt>? storageUsed,
    Expression<DateTime>? expiresAt,
    Expression<bool>? hasUsedTrial,
    Expression<String>? playState,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (tier != null) 'tier': tier,
      if (storageQuota != null) 'storage_quota': storageQuota,
      if (storageUsed != null) 'storage_used': storageUsed,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (hasUsedTrial != null) 'has_used_trial': hasUsedTrial,
      if (playState != null) 'play_state': playState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubscriptionsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? tier,
    Value<BigInt>? storageQuota,
    Value<BigInt>? storageUsed,
    Value<DateTime?>? expiresAt,
    Value<bool>? hasUsedTrial,
    Value<String?>? playState,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SubscriptionsTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      storageQuota: storageQuota ?? this.storageQuota,
      storageUsed: storageUsed ?? this.storageUsed,
      expiresAt: expiresAt ?? this.expiresAt,
      hasUsedTrial: hasUsedTrial ?? this.hasUsedTrial,
      playState: playState ?? this.playState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (storageQuota.present) {
      map['storage_quota'] = Variable<BigInt>(storageQuota.value);
    }
    if (storageUsed.present) {
      map['storage_used'] = Variable<BigInt>(storageUsed.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (hasUsedTrial.present) {
      map['has_used_trial'] = Variable<bool>(hasUsedTrial.value);
    }
    if (playState.present) {
      map['play_state'] = Variable<String>(playState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tier: $tier, ')
          ..write('storageQuota: $storageQuota, ')
          ..write('storageUsed: $storageUsed, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('hasUsedTrial: $hasUsedTrial, ')
          ..write('playState: $playState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyMembersTableTable extends FamilyMembersTable
    with TableInfo<$FamilyMembersTableTable, FamilyMembersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyMembersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subscriptionIdMeta = const VerificationMeta(
    'subscriptionId',
  );
  @override
  late final GeneratedColumn<String> subscriptionId = GeneratedColumn<String>(
    'subscription_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, subscriptionId, memberId, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyMembersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subscription_id')) {
      context.handle(
        _subscriptionIdMeta,
        subscriptionId.isAcceptableOrUnknown(
          data['subscription_id']!,
          _subscriptionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subscriptionIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyMembersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyMembersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      subscriptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subscription_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FamilyMembersTableTable createAlias(String alias) {
    return $FamilyMembersTableTable(attachedDatabase, alias);
  }
}

class FamilyMembersTableData extends DataClass
    implements Insertable<FamilyMembersTableData> {
  final String id;
  final String subscriptionId;
  final String memberId;
  final DateTime addedAt;
  const FamilyMembersTableData({
    required this.id,
    required this.subscriptionId,
    required this.memberId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subscription_id'] = Variable<String>(subscriptionId);
    map['member_id'] = Variable<String>(memberId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FamilyMembersTableCompanion toCompanion(bool nullToAbsent) {
    return FamilyMembersTableCompanion(
      id: Value(id),
      subscriptionId: Value(subscriptionId),
      memberId: Value(memberId),
      addedAt: Value(addedAt),
    );
  }

  factory FamilyMembersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyMembersTableData(
      id: serializer.fromJson<String>(json['id']),
      subscriptionId: serializer.fromJson<String>(json['subscriptionId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subscriptionId': serializer.toJson<String>(subscriptionId),
      'memberId': serializer.toJson<String>(memberId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  FamilyMembersTableData copyWith({
    String? id,
    String? subscriptionId,
    String? memberId,
    DateTime? addedAt,
  }) => FamilyMembersTableData(
    id: id ?? this.id,
    subscriptionId: subscriptionId ?? this.subscriptionId,
    memberId: memberId ?? this.memberId,
    addedAt: addedAt ?? this.addedAt,
  );
  FamilyMembersTableData copyWithCompanion(FamilyMembersTableCompanion data) {
    return FamilyMembersTableData(
      id: data.id.present ? data.id.value : this.id,
      subscriptionId: data.subscriptionId.present
          ? data.subscriptionId.value
          : this.subscriptionId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMembersTableData(')
          ..write('id: $id, ')
          ..write('subscriptionId: $subscriptionId, ')
          ..write('memberId: $memberId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, subscriptionId, memberId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyMembersTableData &&
          other.id == this.id &&
          other.subscriptionId == this.subscriptionId &&
          other.memberId == this.memberId &&
          other.addedAt == this.addedAt);
}

class FamilyMembersTableCompanion
    extends UpdateCompanion<FamilyMembersTableData> {
  final Value<String> id;
  final Value<String> subscriptionId;
  final Value<String> memberId;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const FamilyMembersTableCompanion({
    this.id = const Value.absent(),
    this.subscriptionId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyMembersTableCompanion.insert({
    required String id,
    required String subscriptionId,
    required String memberId,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subscriptionId = Value(subscriptionId),
       memberId = Value(memberId),
       addedAt = Value(addedAt);
  static Insertable<FamilyMembersTableData> custom({
    Expression<String>? id,
    Expression<String>? subscriptionId,
    Expression<String>? memberId,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (memberId != null) 'member_id': memberId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyMembersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? subscriptionId,
    Value<String>? memberId,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return FamilyMembersTableCompanion(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      memberId: memberId ?? this.memberId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subscriptionId.present) {
      map['subscription_id'] = Variable<String>(subscriptionId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMembersTableCompanion(')
          ..write('id: $id, ')
          ..write('subscriptionId: $subscriptionId, ')
          ..write('memberId: $memberId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealTimePreferencesTableTable extends MealTimePreferencesTable
    with
        TableInfo<
          $MealTimePreferencesTableTable,
          MealTimePreferencesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealTimePreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _morningMealMeta = const VerificationMeta(
    'morningMeal',
  );
  @override
  late final GeneratedColumn<String> morningMeal = GeneratedColumn<String>(
    'morning_meal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _afternoonMealMeta = const VerificationMeta(
    'afternoonMeal',
  );
  @override
  late final GeneratedColumn<String> afternoonMeal = GeneratedColumn<String>(
    'afternoon_meal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eveningMealMeta = const VerificationMeta(
    'eveningMeal',
  );
  @override
  late final GeneratedColumn<String> eveningMeal = GeneratedColumn<String>(
    'evening_meal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nightMealMeta = const VerificationMeta(
    'nightMeal',
  );
  @override
  late final GeneratedColumn<String> nightMeal = GeneratedColumn<String>(
    'night_meal',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    morningMeal,
    afternoonMeal,
    eveningMeal,
    nightMeal,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_time_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealTimePreferencesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('morning_meal')) {
      context.handle(
        _morningMealMeta,
        morningMeal.isAcceptableOrUnknown(
          data['morning_meal']!,
          _morningMealMeta,
        ),
      );
    }
    if (data.containsKey('afternoon_meal')) {
      context.handle(
        _afternoonMealMeta,
        afternoonMeal.isAcceptableOrUnknown(
          data['afternoon_meal']!,
          _afternoonMealMeta,
        ),
      );
    }
    if (data.containsKey('evening_meal')) {
      context.handle(
        _eveningMealMeta,
        eveningMeal.isAcceptableOrUnknown(
          data['evening_meal']!,
          _eveningMealMeta,
        ),
      );
    }
    if (data.containsKey('night_meal')) {
      context.handle(
        _nightMealMeta,
        nightMeal.isAcceptableOrUnknown(data['night_meal']!, _nightMealMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealTimePreferencesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealTimePreferencesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      morningMeal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}morning_meal'],
      ),
      afternoonMeal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}afternoon_meal'],
      ),
      eveningMeal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evening_meal'],
      ),
      nightMeal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}night_meal'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MealTimePreferencesTableTable createAlias(String alias) {
    return $MealTimePreferencesTableTable(attachedDatabase, alias);
  }
}

class MealTimePreferencesTableData extends DataClass
    implements Insertable<MealTimePreferencesTableData> {
  final String id;
  final String userId;
  final String? morningMeal;
  final String? afternoonMeal;
  final String? eveningMeal;
  final String? nightMeal;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MealTimePreferencesTableData({
    required this.id,
    required this.userId,
    this.morningMeal,
    this.afternoonMeal,
    this.eveningMeal,
    this.nightMeal,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || morningMeal != null) {
      map['morning_meal'] = Variable<String>(morningMeal);
    }
    if (!nullToAbsent || afternoonMeal != null) {
      map['afternoon_meal'] = Variable<String>(afternoonMeal);
    }
    if (!nullToAbsent || eveningMeal != null) {
      map['evening_meal'] = Variable<String>(eveningMeal);
    }
    if (!nullToAbsent || nightMeal != null) {
      map['night_meal'] = Variable<String>(nightMeal);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MealTimePreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return MealTimePreferencesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      morningMeal: morningMeal == null && nullToAbsent
          ? const Value.absent()
          : Value(morningMeal),
      afternoonMeal: afternoonMeal == null && nullToAbsent
          ? const Value.absent()
          : Value(afternoonMeal),
      eveningMeal: eveningMeal == null && nullToAbsent
          ? const Value.absent()
          : Value(eveningMeal),
      nightMeal: nightMeal == null && nullToAbsent
          ? const Value.absent()
          : Value(nightMeal),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MealTimePreferencesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealTimePreferencesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      morningMeal: serializer.fromJson<String?>(json['morningMeal']),
      afternoonMeal: serializer.fromJson<String?>(json['afternoonMeal']),
      eveningMeal: serializer.fromJson<String?>(json['eveningMeal']),
      nightMeal: serializer.fromJson<String?>(json['nightMeal']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'morningMeal': serializer.toJson<String?>(morningMeal),
      'afternoonMeal': serializer.toJson<String?>(afternoonMeal),
      'eveningMeal': serializer.toJson<String?>(eveningMeal),
      'nightMeal': serializer.toJson<String?>(nightMeal),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MealTimePreferencesTableData copyWith({
    String? id,
    String? userId,
    Value<String?> morningMeal = const Value.absent(),
    Value<String?> afternoonMeal = const Value.absent(),
    Value<String?> eveningMeal = const Value.absent(),
    Value<String?> nightMeal = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MealTimePreferencesTableData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    morningMeal: morningMeal.present ? morningMeal.value : this.morningMeal,
    afternoonMeal: afternoonMeal.present
        ? afternoonMeal.value
        : this.afternoonMeal,
    eveningMeal: eveningMeal.present ? eveningMeal.value : this.eveningMeal,
    nightMeal: nightMeal.present ? nightMeal.value : this.nightMeal,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MealTimePreferencesTableData copyWithCompanion(
    MealTimePreferencesTableCompanion data,
  ) {
    return MealTimePreferencesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      morningMeal: data.morningMeal.present
          ? data.morningMeal.value
          : this.morningMeal,
      afternoonMeal: data.afternoonMeal.present
          ? data.afternoonMeal.value
          : this.afternoonMeal,
      eveningMeal: data.eveningMeal.present
          ? data.eveningMeal.value
          : this.eveningMeal,
      nightMeal: data.nightMeal.present ? data.nightMeal.value : this.nightMeal,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealTimePreferencesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('morningMeal: $morningMeal, ')
          ..write('afternoonMeal: $afternoonMeal, ')
          ..write('eveningMeal: $eveningMeal, ')
          ..write('nightMeal: $nightMeal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    morningMeal,
    afternoonMeal,
    eveningMeal,
    nightMeal,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealTimePreferencesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.morningMeal == this.morningMeal &&
          other.afternoonMeal == this.afternoonMeal &&
          other.eveningMeal == this.eveningMeal &&
          other.nightMeal == this.nightMeal &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MealTimePreferencesTableCompanion
    extends UpdateCompanion<MealTimePreferencesTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> morningMeal;
  final Value<String?> afternoonMeal;
  final Value<String?> eveningMeal;
  final Value<String?> nightMeal;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MealTimePreferencesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.morningMeal = const Value.absent(),
    this.afternoonMeal = const Value.absent(),
    this.eveningMeal = const Value.absent(),
    this.nightMeal = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealTimePreferencesTableCompanion.insert({
    required String id,
    required String userId,
    this.morningMeal = const Value.absent(),
    this.afternoonMeal = const Value.absent(),
    this.eveningMeal = const Value.absent(),
    this.nightMeal = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MealTimePreferencesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? morningMeal,
    Expression<String>? afternoonMeal,
    Expression<String>? eveningMeal,
    Expression<String>? nightMeal,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (morningMeal != null) 'morning_meal': morningMeal,
      if (afternoonMeal != null) 'afternoon_meal': afternoonMeal,
      if (eveningMeal != null) 'evening_meal': eveningMeal,
      if (nightMeal != null) 'night_meal': nightMeal,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealTimePreferencesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? morningMeal,
    Value<String?>? afternoonMeal,
    Value<String?>? eveningMeal,
    Value<String?>? nightMeal,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MealTimePreferencesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      morningMeal: morningMeal ?? this.morningMeal,
      afternoonMeal: afternoonMeal ?? this.afternoonMeal,
      eveningMeal: eveningMeal ?? this.eveningMeal,
      nightMeal: nightMeal ?? this.nightMeal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (morningMeal.present) {
      map['morning_meal'] = Variable<String>(morningMeal.value);
    }
    if (afternoonMeal.present) {
      map['afternoon_meal'] = Variable<String>(afternoonMeal.value);
    }
    if (eveningMeal.present) {
      map['evening_meal'] = Variable<String>(eveningMeal.value);
    }
    if (nightMeal.present) {
      map['night_meal'] = Variable<String>(nightMeal.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealTimePreferencesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('morningMeal: $morningMeal, ')
          ..write('afternoonMeal: $afternoonMeal, ')
          ..write('eveningMeal: $eveningMeal, ')
          ..write('nightMeal: $nightMeal, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DoctorNotesTableTable extends DoctorNotesTable
    with TableInfo<$DoctorNotesTableTable, DoctorNotesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DoctorNotesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doctorIdMeta = const VerificationMeta(
    'doctorId',
  );
  @override
  late final GeneratedColumn<String> doctorId = GeneratedColumn<String>(
    'doctor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    doctorId,
    patientId,
    content,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'doctor_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DoctorNotesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('doctor_id')) {
      context.handle(
        _doctorIdMeta,
        doctorId.isAcceptableOrUnknown(data['doctor_id']!, _doctorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_doctorIdMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DoctorNotesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DoctorNotesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      doctorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}doctor_id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DoctorNotesTableTable createAlias(String alias) {
    return $DoctorNotesTableTable(attachedDatabase, alias);
  }
}

class DoctorNotesTableData extends DataClass
    implements Insertable<DoctorNotesTableData> {
  final String id;
  final String doctorId;
  final String patientId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DoctorNotesTableData({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['doctor_id'] = Variable<String>(doctorId);
    map['patient_id'] = Variable<String>(patientId);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DoctorNotesTableCompanion toCompanion(bool nullToAbsent) {
    return DoctorNotesTableCompanion(
      id: Value(id),
      doctorId: Value(doctorId),
      patientId: Value(patientId),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DoctorNotesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DoctorNotesTableData(
      id: serializer.fromJson<String>(json['id']),
      doctorId: serializer.fromJson<String>(json['doctorId']),
      patientId: serializer.fromJson<String>(json['patientId']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'doctorId': serializer.toJson<String>(doctorId),
      'patientId': serializer.toJson<String>(patientId),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DoctorNotesTableData copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DoctorNotesTableData(
    id: id ?? this.id,
    doctorId: doctorId ?? this.doctorId,
    patientId: patientId ?? this.patientId,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DoctorNotesTableData copyWithCompanion(DoctorNotesTableCompanion data) {
    return DoctorNotesTableData(
      id: data.id.present ? data.id.value : this.id,
      doctorId: data.doctorId.present ? data.doctorId.value : this.doctorId,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DoctorNotesTableData(')
          ..write('id: $id, ')
          ..write('doctorId: $doctorId, ')
          ..write('patientId: $patientId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, doctorId, patientId, content, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DoctorNotesTableData &&
          other.id == this.id &&
          other.doctorId == this.doctorId &&
          other.patientId == this.patientId &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DoctorNotesTableCompanion extends UpdateCompanion<DoctorNotesTableData> {
  final Value<String> id;
  final Value<String> doctorId;
  final Value<String> patientId;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DoctorNotesTableCompanion({
    this.id = const Value.absent(),
    this.doctorId = const Value.absent(),
    this.patientId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DoctorNotesTableCompanion.insert({
    required String id,
    required String doctorId,
    required String patientId,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       doctorId = Value(doctorId),
       patientId = Value(patientId),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DoctorNotesTableData> custom({
    Expression<String>? id,
    Expression<String>? doctorId,
    Expression<String>? patientId,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (doctorId != null) 'doctor_id': doctorId,
      if (patientId != null) 'patient_id': patientId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DoctorNotesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? doctorId,
    Value<String>? patientId,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DoctorNotesTableCompanion(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (doctorId.present) {
      map['doctor_id'] = Variable<String>(doctorId.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DoctorNotesTableCompanion(')
          ..write('id: $id, ')
          ..write('doctorId: $doctorId, ')
          ..write('patientId: $patientId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationBatchesTableTable extends MedicationBatchesTable
    with TableInfo<$MedicationBatchesTableTable, MedicationBatchesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationBatchesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _patientIdMeta = const VerificationMeta(
    'patientId',
  );
  @override
  late final GeneratedColumn<String> patientId = GeneratedColumn<String>(
    'patient_id',
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
  static const VerificationMeta _scheduledTimeMeta = const VerificationMeta(
    'scheduledTime',
  );
  @override
  late final GeneratedColumn<String> scheduledTime = GeneratedColumn<String>(
    'scheduled_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    patientId,
    name,
    scheduledTime,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationBatchesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('patient_id')) {
      context.handle(
        _patientIdMeta,
        patientId.isAcceptableOrUnknown(data['patient_id']!, _patientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_patientIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('scheduled_time')) {
      context.handle(
        _scheduledTimeMeta,
        scheduledTime.isAcceptableOrUnknown(
          data['scheduled_time']!,
          _scheduledTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledTimeMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationBatchesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationBatchesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      patientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}patient_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      scheduledTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_time'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MedicationBatchesTableTable createAlias(String alias) {
    return $MedicationBatchesTableTable(attachedDatabase, alias);
  }
}

class MedicationBatchesTableData extends DataClass
    implements Insertable<MedicationBatchesTableData> {
  final String id;
  final String patientId;
  final String name;
  final String scheduledTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MedicationBatchesTableData({
    required this.id,
    required this.patientId,
    required this.name,
    required this.scheduledTime,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['patient_id'] = Variable<String>(patientId);
    map['name'] = Variable<String>(name);
    map['scheduled_time'] = Variable<String>(scheduledTime);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MedicationBatchesTableCompanion toCompanion(bool nullToAbsent) {
    return MedicationBatchesTableCompanion(
      id: Value(id),
      patientId: Value(patientId),
      name: Value(name),
      scheduledTime: Value(scheduledTime),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MedicationBatchesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationBatchesTableData(
      id: serializer.fromJson<String>(json['id']),
      patientId: serializer.fromJson<String>(json['patientId']),
      name: serializer.fromJson<String>(json['name']),
      scheduledTime: serializer.fromJson<String>(json['scheduledTime']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'patientId': serializer.toJson<String>(patientId),
      'name': serializer.toJson<String>(name),
      'scheduledTime': serializer.toJson<String>(scheduledTime),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MedicationBatchesTableData copyWith({
    String? id,
    String? patientId,
    String? name,
    String? scheduledTime,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MedicationBatchesTableData(
    id: id ?? this.id,
    patientId: patientId ?? this.patientId,
    name: name ?? this.name,
    scheduledTime: scheduledTime ?? this.scheduledTime,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MedicationBatchesTableData copyWithCompanion(
    MedicationBatchesTableCompanion data,
  ) {
    return MedicationBatchesTableData(
      id: data.id.present ? data.id.value : this.id,
      patientId: data.patientId.present ? data.patientId.value : this.patientId,
      name: data.name.present ? data.name.value : this.name,
      scheduledTime: data.scheduledTime.present
          ? data.scheduledTime.value
          : this.scheduledTime,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationBatchesTableData(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('name: $name, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    patientId,
    name,
    scheduledTime,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationBatchesTableData &&
          other.id == this.id &&
          other.patientId == this.patientId &&
          other.name == this.name &&
          other.scheduledTime == this.scheduledTime &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MedicationBatchesTableCompanion
    extends UpdateCompanion<MedicationBatchesTableData> {
  final Value<String> id;
  final Value<String> patientId;
  final Value<String> name;
  final Value<String> scheduledTime;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MedicationBatchesTableCompanion({
    this.id = const Value.absent(),
    this.patientId = const Value.absent(),
    this.name = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationBatchesTableCompanion.insert({
    required String id,
    required String patientId,
    required String name,
    required String scheduledTime,
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       patientId = Value(patientId),
       name = Value(name),
       scheduledTime = Value(scheduledTime),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MedicationBatchesTableData> custom({
    Expression<String>? id,
    Expression<String>? patientId,
    Expression<String>? name,
    Expression<String>? scheduledTime,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (patientId != null) 'patient_id': patientId,
      if (name != null) 'name': name,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationBatchesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? patientId,
    Value<String>? name,
    Value<String>? scheduledTime,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MedicationBatchesTableCompanion(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (patientId.present) {
      map['patient_id'] = Variable<String>(patientId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scheduledTime.present) {
      map['scheduled_time'] = Variable<String>(scheduledTime.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationBatchesTableCompanion(')
          ..write('id: $id, ')
          ..write('patientId: $patientId, ')
          ..write('name: $name, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  late final $ProfilesTableTable profilesTable = $ProfilesTableTable(this);
  late final $ConnectionsTableTable connectionsTable = $ConnectionsTableTable(
    this,
  );
  late final $ConnectionTokensTableTable connectionTokensTable =
      $ConnectionTokensTableTable(this);
  late final $PrescriptionsTableTable prescriptionsTable =
      $PrescriptionsTableTable(this);
  late final $PrescriptionVersionsTableTable prescriptionVersionsTable =
      $PrescriptionVersionsTableTable(this);
  late final $MedicationsTableTable medicationsTable = $MedicationsTableTable(
    this,
  );
  late final $DoseEventsTableTable doseEventsTable = $DoseEventsTableTable(
    this,
  );
  late final $NotificationsTableTable notificationsTable =
      $NotificationsTableTable(this);
  late final $AuditLogsTableTable auditLogsTable = $AuditLogsTableTable(this);
  late final $SubscriptionsTableTable subscriptionsTable =
      $SubscriptionsTableTable(this);
  late final $FamilyMembersTableTable familyMembersTable =
      $FamilyMembersTableTable(this);
  late final $MealTimePreferencesTableTable mealTimePreferencesTable =
      $MealTimePreferencesTableTable(this);
  late final $DoctorNotesTableTable doctorNotesTable = $DoctorNotesTableTable(
    this,
  );
  late final $MedicationBatchesTableTable medicationBatchesTable =
      $MedicationBatchesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    outboxEntries,
    profilesTable,
    connectionsTable,
    connectionTokensTable,
    prescriptionsTable,
    prescriptionVersionsTable,
    medicationsTable,
    doseEventsTable,
    notificationsTable,
    auditLogsTable,
    subscriptionsTable,
    familyMembersTable,
    mealTimePreferencesTable,
    doctorNotesTable,
    medicationBatchesTable,
  ];
}

typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      required String id,
      required String targetTable,
      required OutboxOpType op,
      required String payload,
      Value<int> attempts,
      Value<DateTime> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<String> id,
      Value<String> targetTable,
      Value<OutboxOpType> op,
      Value<String> payload,
      Value<int> attempts,
      Value<DateTime> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
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

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OutboxOpType, OutboxOpType, String> get op =>
      $composableBuilder(
        column: $table.op,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<OutboxOpType, String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxEntriesTable,
          OutboxEntry,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (
            OutboxEntry,
            BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxEntry>,
          ),
          OutboxEntry,
          PrefetchHooks Function()
        > {
  $$OutboxEntriesTableTableManager(_$AppDatabase db, $OutboxEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<OutboxOpType> op = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntriesCompanion(
                id: id,
                targetTable: targetTable,
                op: op,
                payload: payload,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String targetTable,
                required OutboxOpType op,
                required String payload,
                Value<int> attempts = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntriesCompanion.insert(
                id: id,
                targetTable: targetTable,
                op: op,
                payload: payload,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
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

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxEntriesTable,
      OutboxEntry,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (
        OutboxEntry,
        BaseReferences<_$AppDatabase, $OutboxEntriesTable, OutboxEntry>,
      ),
      OutboxEntry,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableTableCreateCompanionBuilder =
    ProfilesTableCompanion Function({
      required String id,
      Value<String> role,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String?> fullName,
      Value<String?> phoneNumber,
      Value<String?> email,
      Value<String> language,
      Value<String> theme,
      Value<String> timezone,
      Value<int> gracePeriodMinutes,
      Value<String> accountStatus,
      Value<String?> profilePictureUrl,
      Value<String?> hospitalClinic,
      Value<String?> specialty,
      Value<String?> licenseNumber,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProfilesTableTableUpdateCompanionBuilder =
    ProfilesTableCompanion Function({
      Value<String> id,
      Value<String> role,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String?> fullName,
      Value<String?> phoneNumber,
      Value<String?> email,
      Value<String> language,
      Value<String> theme,
      Value<String> timezone,
      Value<int> gracePeriodMinutes,
      Value<String> accountStatus,
      Value<String?> profilePictureUrl,
      Value<String?> hospitalClinic,
      Value<String?> specialty,
      Value<String?> licenseNumber,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProfilesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTableTable> {
  $$ProfilesTableTableFilterComposer({
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

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gracePeriodMinutes => $composableBuilder(
    column: $table.gracePeriodMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountStatus => $composableBuilder(
    column: $table.accountStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profilePictureUrl => $composableBuilder(
    column: $table.profilePictureUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hospitalClinic => $composableBuilder(
    column: $table.hospitalClinic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialty => $composableBuilder(
    column: $table.specialty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get licenseNumber => $composableBuilder(
    column: $table.licenseNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTableTable> {
  $$ProfilesTableTableOrderingComposer({
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

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gracePeriodMinutes => $composableBuilder(
    column: $table.gracePeriodMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountStatus => $composableBuilder(
    column: $table.accountStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profilePictureUrl => $composableBuilder(
    column: $table.profilePictureUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hospitalClinic => $composableBuilder(
    column: $table.hospitalClinic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialty => $composableBuilder(
    column: $table.specialty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get licenseNumber => $composableBuilder(
    column: $table.licenseNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTableTable> {
  $$ProfilesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<int> get gracePeriodMinutes => $composableBuilder(
    column: $table.gracePeriodMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountStatus => $composableBuilder(
    column: $table.accountStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get profilePictureUrl => $composableBuilder(
    column: $table.profilePictureUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hospitalClinic => $composableBuilder(
    column: $table.hospitalClinic,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specialty =>
      $composableBuilder(column: $table.specialty, builder: (column) => column);

  GeneratedColumn<String> get licenseNumber => $composableBuilder(
    column: $table.licenseNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTableTable,
          ProfilesTableData,
          $$ProfilesTableTableFilterComposer,
          $$ProfilesTableTableOrderingComposer,
          $$ProfilesTableTableAnnotationComposer,
          $$ProfilesTableTableCreateCompanionBuilder,
          $$ProfilesTableTableUpdateCompanionBuilder,
          (
            ProfilesTableData,
            BaseReferences<
              _$AppDatabase,
              $ProfilesTableTable,
              ProfilesTableData
            >,
          ),
          ProfilesTableData,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableTableManager(_$AppDatabase db, $ProfilesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<int> gracePeriodMinutes = const Value.absent(),
                Value<String> accountStatus = const Value.absent(),
                Value<String?> profilePictureUrl = const Value.absent(),
                Value<String?> hospitalClinic = const Value.absent(),
                Value<String?> specialty = const Value.absent(),
                Value<String?> licenseNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesTableCompanion(
                id: id,
                role: role,
                firstName: firstName,
                lastName: lastName,
                fullName: fullName,
                phoneNumber: phoneNumber,
                email: email,
                language: language,
                theme: theme,
                timezone: timezone,
                gracePeriodMinutes: gracePeriodMinutes,
                accountStatus: accountStatus,
                profilePictureUrl: profilePictureUrl,
                hospitalClinic: hospitalClinic,
                specialty: specialty,
                licenseNumber: licenseNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> role = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> fullName = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<int> gracePeriodMinutes = const Value.absent(),
                Value<String> accountStatus = const Value.absent(),
                Value<String?> profilePictureUrl = const Value.absent(),
                Value<String?> hospitalClinic = const Value.absent(),
                Value<String?> specialty = const Value.absent(),
                Value<String?> licenseNumber = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProfilesTableCompanion.insert(
                id: id,
                role: role,
                firstName: firstName,
                lastName: lastName,
                fullName: fullName,
                phoneNumber: phoneNumber,
                email: email,
                language: language,
                theme: theme,
                timezone: timezone,
                gracePeriodMinutes: gracePeriodMinutes,
                accountStatus: accountStatus,
                profilePictureUrl: profilePictureUrl,
                hospitalClinic: hospitalClinic,
                specialty: specialty,
                licenseNumber: licenseNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTableTable,
      ProfilesTableData,
      $$ProfilesTableTableFilterComposer,
      $$ProfilesTableTableOrderingComposer,
      $$ProfilesTableTableAnnotationComposer,
      $$ProfilesTableTableCreateCompanionBuilder,
      $$ProfilesTableTableUpdateCompanionBuilder,
      (
        ProfilesTableData,
        BaseReferences<_$AppDatabase, $ProfilesTableTable, ProfilesTableData>,
      ),
      ProfilesTableData,
      PrefetchHooks Function()
    >;
typedef $$ConnectionsTableTableCreateCompanionBuilder =
    ConnectionsTableCompanion Function({
      required String id,
      required String initiatorId,
      required String recipientId,
      Value<String> status,
      Value<String> permissionLevel,
      Value<String?> metadata,
      required DateTime requestedAt,
      Value<DateTime?> acceptedAt,
      Value<DateTime?> revokedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ConnectionsTableTableUpdateCompanionBuilder =
    ConnectionsTableCompanion Function({
      Value<String> id,
      Value<String> initiatorId,
      Value<String> recipientId,
      Value<String> status,
      Value<String> permissionLevel,
      Value<String?> metadata,
      Value<DateTime> requestedAt,
      Value<DateTime?> acceptedAt,
      Value<DateTime?> revokedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ConnectionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectionsTableTable> {
  $$ConnectionsTableTableFilterComposer({
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

  ColumnFilters<String> get initiatorId => $composableBuilder(
    column: $table.initiatorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissionLevel => $composableBuilder(
    column: $table.permissionLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConnectionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectionsTableTable> {
  $$ConnectionsTableTableOrderingComposer({
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

  ColumnOrderings<String> get initiatorId => $composableBuilder(
    column: $table.initiatorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissionLevel => $composableBuilder(
    column: $table.permissionLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConnectionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectionsTableTable> {
  $$ConnectionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get initiatorId => $composableBuilder(
    column: $table.initiatorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get permissionLevel => $composableBuilder(
    column: $table.permissionLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConnectionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConnectionsTableTable,
          ConnectionsTableData,
          $$ConnectionsTableTableFilterComposer,
          $$ConnectionsTableTableOrderingComposer,
          $$ConnectionsTableTableAnnotationComposer,
          $$ConnectionsTableTableCreateCompanionBuilder,
          $$ConnectionsTableTableUpdateCompanionBuilder,
          (
            ConnectionsTableData,
            BaseReferences<
              _$AppDatabase,
              $ConnectionsTableTable,
              ConnectionsTableData
            >,
          ),
          ConnectionsTableData,
          PrefetchHooks Function()
        > {
  $$ConnectionsTableTableTableManager(
    _$AppDatabase db,
    $ConnectionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> initiatorId = const Value.absent(),
                Value<String> recipientId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> permissionLevel = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<DateTime> requestedAt = const Value.absent(),
                Value<DateTime?> acceptedAt = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConnectionsTableCompanion(
                id: id,
                initiatorId: initiatorId,
                recipientId: recipientId,
                status: status,
                permissionLevel: permissionLevel,
                metadata: metadata,
                requestedAt: requestedAt,
                acceptedAt: acceptedAt,
                revokedAt: revokedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String initiatorId,
                required String recipientId,
                Value<String> status = const Value.absent(),
                Value<String> permissionLevel = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                required DateTime requestedAt,
                Value<DateTime?> acceptedAt = const Value.absent(),
                Value<DateTime?> revokedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ConnectionsTableCompanion.insert(
                id: id,
                initiatorId: initiatorId,
                recipientId: recipientId,
                status: status,
                permissionLevel: permissionLevel,
                metadata: metadata,
                requestedAt: requestedAt,
                acceptedAt: acceptedAt,
                revokedAt: revokedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConnectionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConnectionsTableTable,
      ConnectionsTableData,
      $$ConnectionsTableTableFilterComposer,
      $$ConnectionsTableTableOrderingComposer,
      $$ConnectionsTableTableAnnotationComposer,
      $$ConnectionsTableTableCreateCompanionBuilder,
      $$ConnectionsTableTableUpdateCompanionBuilder,
      (
        ConnectionsTableData,
        BaseReferences<
          _$AppDatabase,
          $ConnectionsTableTable,
          ConnectionsTableData
        >,
      ),
      ConnectionsTableData,
      PrefetchHooks Function()
    >;
typedef $$ConnectionTokensTableTableCreateCompanionBuilder =
    ConnectionTokensTableCompanion Function({
      required String id,
      required String patientId,
      required String token,
      Value<String> permissionLevel,
      Value<String> intendedRole,
      required DateTime expiresAt,
      Value<DateTime?> usedAt,
      Value<String?> usedById,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ConnectionTokensTableTableUpdateCompanionBuilder =
    ConnectionTokensTableCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<String> token,
      Value<String> permissionLevel,
      Value<String> intendedRole,
      Value<DateTime> expiresAt,
      Value<DateTime?> usedAt,
      Value<String?> usedById,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ConnectionTokensTableTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectionTokensTableTable> {
  $$ConnectionTokensTableTableFilterComposer({
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

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissionLevel => $composableBuilder(
    column: $table.permissionLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intendedRole => $composableBuilder(
    column: $table.intendedRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usedById => $composableBuilder(
    column: $table.usedById,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConnectionTokensTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectionTokensTableTable> {
  $$ConnectionTokensTableTableOrderingComposer({
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

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissionLevel => $composableBuilder(
    column: $table.permissionLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intendedRole => $composableBuilder(
    column: $table.intendedRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usedById => $composableBuilder(
    column: $table.usedById,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConnectionTokensTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectionTokensTableTable> {
  $$ConnectionTokensTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumn<String> get permissionLevel => $composableBuilder(
    column: $table.permissionLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intendedRole => $composableBuilder(
    column: $table.intendedRole,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);

  GeneratedColumn<String> get usedById =>
      $composableBuilder(column: $table.usedById, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ConnectionTokensTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConnectionTokensTableTable,
          ConnectionTokensTableData,
          $$ConnectionTokensTableTableFilterComposer,
          $$ConnectionTokensTableTableOrderingComposer,
          $$ConnectionTokensTableTableAnnotationComposer,
          $$ConnectionTokensTableTableCreateCompanionBuilder,
          $$ConnectionTokensTableTableUpdateCompanionBuilder,
          (
            ConnectionTokensTableData,
            BaseReferences<
              _$AppDatabase,
              $ConnectionTokensTableTable,
              ConnectionTokensTableData
            >,
          ),
          ConnectionTokensTableData,
          PrefetchHooks Function()
        > {
  $$ConnectionTokensTableTableTableManager(
    _$AppDatabase db,
    $ConnectionTokensTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionTokensTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ConnectionTokensTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConnectionTokensTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> token = const Value.absent(),
                Value<String> permissionLevel = const Value.absent(),
                Value<String> intendedRole = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime?> usedAt = const Value.absent(),
                Value<String?> usedById = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConnectionTokensTableCompanion(
                id: id,
                patientId: patientId,
                token: token,
                permissionLevel: permissionLevel,
                intendedRole: intendedRole,
                expiresAt: expiresAt,
                usedAt: usedAt,
                usedById: usedById,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required String token,
                Value<String> permissionLevel = const Value.absent(),
                Value<String> intendedRole = const Value.absent(),
                required DateTime expiresAt,
                Value<DateTime?> usedAt = const Value.absent(),
                Value<String?> usedById = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ConnectionTokensTableCompanion.insert(
                id: id,
                patientId: patientId,
                token: token,
                permissionLevel: permissionLevel,
                intendedRole: intendedRole,
                expiresAt: expiresAt,
                usedAt: usedAt,
                usedById: usedById,
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

typedef $$ConnectionTokensTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConnectionTokensTableTable,
      ConnectionTokensTableData,
      $$ConnectionTokensTableTableFilterComposer,
      $$ConnectionTokensTableTableOrderingComposer,
      $$ConnectionTokensTableTableAnnotationComposer,
      $$ConnectionTokensTableTableCreateCompanionBuilder,
      $$ConnectionTokensTableTableUpdateCompanionBuilder,
      (
        ConnectionTokensTableData,
        BaseReferences<
          _$AppDatabase,
          $ConnectionTokensTableTable,
          ConnectionTokensTableData
        >,
      ),
      ConnectionTokensTableData,
      PrefetchHooks Function()
    >;
typedef $$PrescriptionsTableTableCreateCompanionBuilder =
    PrescriptionsTableCompanion Function({
      required String id,
      required String patientId,
      Value<String?> doctorId,
      required String patientName,
      required String patientGender,
      required int patientAge,
      Value<String> symptoms,
      Value<String?> diagnosis,
      Value<String> status,
      Value<int> currentVersion,
      Value<bool> isUrgent,
      Value<String?> urgentReason,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PrescriptionsTableTableUpdateCompanionBuilder =
    PrescriptionsTableCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<String?> doctorId,
      Value<String> patientName,
      Value<String> patientGender,
      Value<int> patientAge,
      Value<String> symptoms,
      Value<String?> diagnosis,
      Value<String> status,
      Value<int> currentVersion,
      Value<bool> isUrgent,
      Value<String?> urgentReason,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PrescriptionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PrescriptionsTableTable> {
  $$PrescriptionsTableTableFilterComposer({
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

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doctorId => $composableBuilder(
    column: $table.doctorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientName => $composableBuilder(
    column: $table.patientName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientGender => $composableBuilder(
    column: $table.patientGender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get patientAge => $composableBuilder(
    column: $table.patientAge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symptoms => $composableBuilder(
    column: $table.symptoms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diagnosis => $composableBuilder(
    column: $table.diagnosis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentVersion => $composableBuilder(
    column: $table.currentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUrgent => $composableBuilder(
    column: $table.isUrgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urgentReason => $composableBuilder(
    column: $table.urgentReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrescriptionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PrescriptionsTableTable> {
  $$PrescriptionsTableTableOrderingComposer({
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

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doctorId => $composableBuilder(
    column: $table.doctorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientName => $composableBuilder(
    column: $table.patientName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientGender => $composableBuilder(
    column: $table.patientGender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get patientAge => $composableBuilder(
    column: $table.patientAge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symptoms => $composableBuilder(
    column: $table.symptoms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diagnosis => $composableBuilder(
    column: $table.diagnosis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentVersion => $composableBuilder(
    column: $table.currentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUrgent => $composableBuilder(
    column: $table.isUrgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urgentReason => $composableBuilder(
    column: $table.urgentReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrescriptionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrescriptionsTableTable> {
  $$PrescriptionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get doctorId =>
      $composableBuilder(column: $table.doctorId, builder: (column) => column);

  GeneratedColumn<String> get patientName => $composableBuilder(
    column: $table.patientName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientGender => $composableBuilder(
    column: $table.patientGender,
    builder: (column) => column,
  );

  GeneratedColumn<int> get patientAge => $composableBuilder(
    column: $table.patientAge,
    builder: (column) => column,
  );

  GeneratedColumn<String> get symptoms =>
      $composableBuilder(column: $table.symptoms, builder: (column) => column);

  GeneratedColumn<String> get diagnosis =>
      $composableBuilder(column: $table.diagnosis, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get currentVersion => $composableBuilder(
    column: $table.currentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUrgent =>
      $composableBuilder(column: $table.isUrgent, builder: (column) => column);

  GeneratedColumn<String> get urgentReason => $composableBuilder(
    column: $table.urgentReason,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PrescriptionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrescriptionsTableTable,
          PrescriptionsTableData,
          $$PrescriptionsTableTableFilterComposer,
          $$PrescriptionsTableTableOrderingComposer,
          $$PrescriptionsTableTableAnnotationComposer,
          $$PrescriptionsTableTableCreateCompanionBuilder,
          $$PrescriptionsTableTableUpdateCompanionBuilder,
          (
            PrescriptionsTableData,
            BaseReferences<
              _$AppDatabase,
              $PrescriptionsTableTable,
              PrescriptionsTableData
            >,
          ),
          PrescriptionsTableData,
          PrefetchHooks Function()
        > {
  $$PrescriptionsTableTableTableManager(
    _$AppDatabase db,
    $PrescriptionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrescriptionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrescriptionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrescriptionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String?> doctorId = const Value.absent(),
                Value<String> patientName = const Value.absent(),
                Value<String> patientGender = const Value.absent(),
                Value<int> patientAge = const Value.absent(),
                Value<String> symptoms = const Value.absent(),
                Value<String?> diagnosis = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> currentVersion = const Value.absent(),
                Value<bool> isUrgent = const Value.absent(),
                Value<String?> urgentReason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrescriptionsTableCompanion(
                id: id,
                patientId: patientId,
                doctorId: doctorId,
                patientName: patientName,
                patientGender: patientGender,
                patientAge: patientAge,
                symptoms: symptoms,
                diagnosis: diagnosis,
                status: status,
                currentVersion: currentVersion,
                isUrgent: isUrgent,
                urgentReason: urgentReason,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                Value<String?> doctorId = const Value.absent(),
                required String patientName,
                required String patientGender,
                required int patientAge,
                Value<String> symptoms = const Value.absent(),
                Value<String?> diagnosis = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> currentVersion = const Value.absent(),
                Value<bool> isUrgent = const Value.absent(),
                Value<String?> urgentReason = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PrescriptionsTableCompanion.insert(
                id: id,
                patientId: patientId,
                doctorId: doctorId,
                patientName: patientName,
                patientGender: patientGender,
                patientAge: patientAge,
                symptoms: symptoms,
                diagnosis: diagnosis,
                status: status,
                currentVersion: currentVersion,
                isUrgent: isUrgent,
                urgentReason: urgentReason,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrescriptionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrescriptionsTableTable,
      PrescriptionsTableData,
      $$PrescriptionsTableTableFilterComposer,
      $$PrescriptionsTableTableOrderingComposer,
      $$PrescriptionsTableTableAnnotationComposer,
      $$PrescriptionsTableTableCreateCompanionBuilder,
      $$PrescriptionsTableTableUpdateCompanionBuilder,
      (
        PrescriptionsTableData,
        BaseReferences<
          _$AppDatabase,
          $PrescriptionsTableTable,
          PrescriptionsTableData
        >,
      ),
      PrescriptionsTableData,
      PrefetchHooks Function()
    >;
typedef $$PrescriptionVersionsTableTableCreateCompanionBuilder =
    PrescriptionVersionsTableCompanion Function({
      required String id,
      required String prescriptionId,
      required int versionNumber,
      Value<String?> authorId,
      Value<String?> changeReason,
      required String medicationsSnapshot,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PrescriptionVersionsTableTableUpdateCompanionBuilder =
    PrescriptionVersionsTableCompanion Function({
      Value<String> id,
      Value<String> prescriptionId,
      Value<int> versionNumber,
      Value<String?> authorId,
      Value<String?> changeReason,
      Value<String> medicationsSnapshot,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PrescriptionVersionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PrescriptionVersionsTableTable> {
  $$PrescriptionVersionsTableTableFilterComposer({
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

  ColumnFilters<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changeReason => $composableBuilder(
    column: $table.changeReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationsSnapshot => $composableBuilder(
    column: $table.medicationsSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrescriptionVersionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PrescriptionVersionsTableTable> {
  $$PrescriptionVersionsTableTableOrderingComposer({
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

  ColumnOrderings<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorId => $composableBuilder(
    column: $table.authorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changeReason => $composableBuilder(
    column: $table.changeReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationsSnapshot => $composableBuilder(
    column: $table.medicationsSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrescriptionVersionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrescriptionVersionsTableTable> {
  $$PrescriptionVersionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get versionNumber => $composableBuilder(
    column: $table.versionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorId =>
      $composableBuilder(column: $table.authorId, builder: (column) => column);

  GeneratedColumn<String> get changeReason => $composableBuilder(
    column: $table.changeReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medicationsSnapshot => $composableBuilder(
    column: $table.medicationsSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PrescriptionVersionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrescriptionVersionsTableTable,
          PrescriptionVersionsTableData,
          $$PrescriptionVersionsTableTableFilterComposer,
          $$PrescriptionVersionsTableTableOrderingComposer,
          $$PrescriptionVersionsTableTableAnnotationComposer,
          $$PrescriptionVersionsTableTableCreateCompanionBuilder,
          $$PrescriptionVersionsTableTableUpdateCompanionBuilder,
          (
            PrescriptionVersionsTableData,
            BaseReferences<
              _$AppDatabase,
              $PrescriptionVersionsTableTable,
              PrescriptionVersionsTableData
            >,
          ),
          PrescriptionVersionsTableData,
          PrefetchHooks Function()
        > {
  $$PrescriptionVersionsTableTableTableManager(
    _$AppDatabase db,
    $PrescriptionVersionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrescriptionVersionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PrescriptionVersionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PrescriptionVersionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> prescriptionId = const Value.absent(),
                Value<int> versionNumber = const Value.absent(),
                Value<String?> authorId = const Value.absent(),
                Value<String?> changeReason = const Value.absent(),
                Value<String> medicationsSnapshot = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrescriptionVersionsTableCompanion(
                id: id,
                prescriptionId: prescriptionId,
                versionNumber: versionNumber,
                authorId: authorId,
                changeReason: changeReason,
                medicationsSnapshot: medicationsSnapshot,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String prescriptionId,
                required int versionNumber,
                Value<String?> authorId = const Value.absent(),
                Value<String?> changeReason = const Value.absent(),
                required String medicationsSnapshot,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PrescriptionVersionsTableCompanion.insert(
                id: id,
                prescriptionId: prescriptionId,
                versionNumber: versionNumber,
                authorId: authorId,
                changeReason: changeReason,
                medicationsSnapshot: medicationsSnapshot,
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

typedef $$PrescriptionVersionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrescriptionVersionsTableTable,
      PrescriptionVersionsTableData,
      $$PrescriptionVersionsTableTableFilterComposer,
      $$PrescriptionVersionsTableTableOrderingComposer,
      $$PrescriptionVersionsTableTableAnnotationComposer,
      $$PrescriptionVersionsTableTableCreateCompanionBuilder,
      $$PrescriptionVersionsTableTableUpdateCompanionBuilder,
      (
        PrescriptionVersionsTableData,
        BaseReferences<
          _$AppDatabase,
          $PrescriptionVersionsTableTable,
          PrescriptionVersionsTableData
        >,
      ),
      PrescriptionVersionsTableData,
      PrefetchHooks Function()
    >;
typedef $$MedicationsTableTableCreateCompanionBuilder =
    MedicationsTableCompanion Function({
      required String id,
      required String prescriptionId,
      required int rowNumber,
      Value<String?> batchId,
      required String medicineName,
      Value<String?> medicineNameKhmer,
      Value<String?> imageUrl,
      Value<String> medicineType,
      Value<String> unit,
      Value<double> dosageAmount,
      Value<String?> description,
      Value<String?> frequency,
      Value<int?> duration,
      Value<bool> isPrn,
      Value<bool> beforeMeal,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MedicationsTableTableUpdateCompanionBuilder =
    MedicationsTableCompanion Function({
      Value<String> id,
      Value<String> prescriptionId,
      Value<int> rowNumber,
      Value<String?> batchId,
      Value<String> medicineName,
      Value<String?> medicineNameKhmer,
      Value<String?> imageUrl,
      Value<String> medicineType,
      Value<String> unit,
      Value<double> dosageAmount,
      Value<String?> description,
      Value<String?> frequency,
      Value<int?> duration,
      Value<bool> isPrn,
      Value<bool> beforeMeal,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MedicationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTableTable> {
  $$MedicationsTableTableFilterComposer({
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

  ColumnFilters<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowNumber => $composableBuilder(
    column: $table.rowNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicineName => $composableBuilder(
    column: $table.medicineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicineNameKhmer => $composableBuilder(
    column: $table.medicineNameKhmer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicineType => $composableBuilder(
    column: $table.medicineType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dosageAmount => $composableBuilder(
    column: $table.dosageAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrn => $composableBuilder(
    column: $table.isPrn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get beforeMeal => $composableBuilder(
    column: $table.beforeMeal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTableTable> {
  $$MedicationsTableTableOrderingComposer({
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

  ColumnOrderings<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowNumber => $composableBuilder(
    column: $table.rowNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicineName => $composableBuilder(
    column: $table.medicineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicineNameKhmer => $composableBuilder(
    column: $table.medicineNameKhmer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicineType => $composableBuilder(
    column: $table.medicineType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dosageAmount => $composableBuilder(
    column: $table.dosageAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrn => $composableBuilder(
    column: $table.isPrn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get beforeMeal => $composableBuilder(
    column: $table.beforeMeal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTableTable> {
  $$MedicationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowNumber =>
      $composableBuilder(column: $table.rowNumber, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get medicineName => $composableBuilder(
    column: $table.medicineName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medicineNameKhmer => $composableBuilder(
    column: $table.medicineNameKhmer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get medicineType => $composableBuilder(
    column: $table.medicineType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get dosageAmount => $composableBuilder(
    column: $table.dosageAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<bool> get isPrn =>
      $composableBuilder(column: $table.isPrn, builder: (column) => column);

  GeneratedColumn<bool> get beforeMeal => $composableBuilder(
    column: $table.beforeMeal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MedicationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationsTableTable,
          MedicationsTableData,
          $$MedicationsTableTableFilterComposer,
          $$MedicationsTableTableOrderingComposer,
          $$MedicationsTableTableAnnotationComposer,
          $$MedicationsTableTableCreateCompanionBuilder,
          $$MedicationsTableTableUpdateCompanionBuilder,
          (
            MedicationsTableData,
            BaseReferences<
              _$AppDatabase,
              $MedicationsTableTable,
              MedicationsTableData
            >,
          ),
          MedicationsTableData,
          PrefetchHooks Function()
        > {
  $$MedicationsTableTableTableManager(
    _$AppDatabase db,
    $MedicationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> prescriptionId = const Value.absent(),
                Value<int> rowNumber = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String> medicineName = const Value.absent(),
                Value<String?> medicineNameKhmer = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> medicineType = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> dosageAmount = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> frequency = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<bool> isPrn = const Value.absent(),
                Value<bool> beforeMeal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsTableCompanion(
                id: id,
                prescriptionId: prescriptionId,
                rowNumber: rowNumber,
                batchId: batchId,
                medicineName: medicineName,
                medicineNameKhmer: medicineNameKhmer,
                imageUrl: imageUrl,
                medicineType: medicineType,
                unit: unit,
                dosageAmount: dosageAmount,
                description: description,
                frequency: frequency,
                duration: duration,
                isPrn: isPrn,
                beforeMeal: beforeMeal,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String prescriptionId,
                required int rowNumber,
                Value<String?> batchId = const Value.absent(),
                required String medicineName,
                Value<String?> medicineNameKhmer = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> medicineType = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> dosageAmount = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> frequency = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<bool> isPrn = const Value.absent(),
                Value<bool> beforeMeal = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MedicationsTableCompanion.insert(
                id: id,
                prescriptionId: prescriptionId,
                rowNumber: rowNumber,
                batchId: batchId,
                medicineName: medicineName,
                medicineNameKhmer: medicineNameKhmer,
                imageUrl: imageUrl,
                medicineType: medicineType,
                unit: unit,
                dosageAmount: dosageAmount,
                description: description,
                frequency: frequency,
                duration: duration,
                isPrn: isPrn,
                beforeMeal: beforeMeal,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationsTableTable,
      MedicationsTableData,
      $$MedicationsTableTableFilterComposer,
      $$MedicationsTableTableOrderingComposer,
      $$MedicationsTableTableAnnotationComposer,
      $$MedicationsTableTableCreateCompanionBuilder,
      $$MedicationsTableTableUpdateCompanionBuilder,
      (
        MedicationsTableData,
        BaseReferences<
          _$AppDatabase,
          $MedicationsTableTable,
          MedicationsTableData
        >,
      ),
      MedicationsTableData,
      PrefetchHooks Function()
    >;
typedef $$DoseEventsTableTableCreateCompanionBuilder =
    DoseEventsTableCompanion Function({
      required String id,
      required String prescriptionId,
      required String medicationId,
      required String patientId,
      required DateTime scheduledTime,
      required String timePeriod,
      Value<String?> reminderTime,
      Value<String> status,
      Value<DateTime?> takenAt,
      Value<String?> skipReason,
      Value<bool> wasOffline,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DoseEventsTableTableUpdateCompanionBuilder =
    DoseEventsTableCompanion Function({
      Value<String> id,
      Value<String> prescriptionId,
      Value<String> medicationId,
      Value<String> patientId,
      Value<DateTime> scheduledTime,
      Value<String> timePeriod,
      Value<String?> reminderTime,
      Value<String> status,
      Value<DateTime?> takenAt,
      Value<String?> skipReason,
      Value<bool> wasOffline,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DoseEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DoseEventsTableTable> {
  $$DoseEventsTableTableFilterComposer({
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

  ColumnFilters<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timePeriod => $composableBuilder(
    column: $table.timePeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasOffline => $composableBuilder(
    column: $table.wasOffline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DoseEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DoseEventsTableTable> {
  $$DoseEventsTableTableOrderingComposer({
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

  ColumnOrderings<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timePeriod => $composableBuilder(
    column: $table.timePeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasOffline => $composableBuilder(
    column: $table.wasOffline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DoseEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DoseEventsTableTable> {
  $$DoseEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get prescriptionId => $composableBuilder(
    column: $table.prescriptionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timePeriod => $composableBuilder(
    column: $table.timePeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasOffline => $composableBuilder(
    column: $table.wasOffline,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DoseEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DoseEventsTableTable,
          DoseEventsTableData,
          $$DoseEventsTableTableFilterComposer,
          $$DoseEventsTableTableOrderingComposer,
          $$DoseEventsTableTableAnnotationComposer,
          $$DoseEventsTableTableCreateCompanionBuilder,
          $$DoseEventsTableTableUpdateCompanionBuilder,
          (
            DoseEventsTableData,
            BaseReferences<
              _$AppDatabase,
              $DoseEventsTableTable,
              DoseEventsTableData
            >,
          ),
          DoseEventsTableData,
          PrefetchHooks Function()
        > {
  $$DoseEventsTableTableTableManager(
    _$AppDatabase db,
    $DoseEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DoseEventsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DoseEventsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DoseEventsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> prescriptionId = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<DateTime> scheduledTime = const Value.absent(),
                Value<String> timePeriod = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> takenAt = const Value.absent(),
                Value<String?> skipReason = const Value.absent(),
                Value<bool> wasOffline = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DoseEventsTableCompanion(
                id: id,
                prescriptionId: prescriptionId,
                medicationId: medicationId,
                patientId: patientId,
                scheduledTime: scheduledTime,
                timePeriod: timePeriod,
                reminderTime: reminderTime,
                status: status,
                takenAt: takenAt,
                skipReason: skipReason,
                wasOffline: wasOffline,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String prescriptionId,
                required String medicationId,
                required String patientId,
                required DateTime scheduledTime,
                required String timePeriod,
                Value<String?> reminderTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> takenAt = const Value.absent(),
                Value<String?> skipReason = const Value.absent(),
                Value<bool> wasOffline = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DoseEventsTableCompanion.insert(
                id: id,
                prescriptionId: prescriptionId,
                medicationId: medicationId,
                patientId: patientId,
                scheduledTime: scheduledTime,
                timePeriod: timePeriod,
                reminderTime: reminderTime,
                status: status,
                takenAt: takenAt,
                skipReason: skipReason,
                wasOffline: wasOffline,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DoseEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DoseEventsTableTable,
      DoseEventsTableData,
      $$DoseEventsTableTableFilterComposer,
      $$DoseEventsTableTableOrderingComposer,
      $$DoseEventsTableTableAnnotationComposer,
      $$DoseEventsTableTableCreateCompanionBuilder,
      $$DoseEventsTableTableUpdateCompanionBuilder,
      (
        DoseEventsTableData,
        BaseReferences<
          _$AppDatabase,
          $DoseEventsTableTable,
          DoseEventsTableData
        >,
      ),
      DoseEventsTableData,
      PrefetchHooks Function()
    >;
typedef $$NotificationsTableTableCreateCompanionBuilder =
    NotificationsTableCompanion Function({
      required String id,
      required String recipientId,
      required String type,
      required String title,
      required String message,
      Value<String?> data,
      Value<bool> isRead,
      Value<DateTime?> readAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$NotificationsTableTableUpdateCompanionBuilder =
    NotificationsTableCompanion Function({
      Value<String> id,
      Value<String> recipientId,
      Value<String> type,
      Value<String> title,
      Value<String> message,
      Value<String?> data,
      Value<bool> isRead,
      Value<DateTime?> readAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$NotificationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsTableTable> {
  $$NotificationsTableTableFilterComposer({
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

  ColumnFilters<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
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

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsTableTable> {
  $$NotificationsTableTableOrderingComposer({
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

  ColumnOrderings<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
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

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsTableTable> {
  $$NotificationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recipientId => $composableBuilder(
    column: $table.recipientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NotificationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsTableTable,
          NotificationsTableData,
          $$NotificationsTableTableFilterComposer,
          $$NotificationsTableTableOrderingComposer,
          $$NotificationsTableTableAnnotationComposer,
          $$NotificationsTableTableCreateCompanionBuilder,
          $$NotificationsTableTableUpdateCompanionBuilder,
          (
            NotificationsTableData,
            BaseReferences<
              _$AppDatabase,
              $NotificationsTableTable,
              NotificationsTableData
            >,
          ),
          NotificationsTableData,
          PrefetchHooks Function()
        > {
  $$NotificationsTableTableTableManager(
    _$AppDatabase db,
    $NotificationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recipientId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> data = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsTableCompanion(
                id: id,
                recipientId: recipientId,
                type: type,
                title: title,
                message: message,
                data: data,
                isRead: isRead,
                readAt: readAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recipientId,
                required String type,
                required String title,
                required String message,
                Value<String?> data = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => NotificationsTableCompanion.insert(
                id: id,
                recipientId: recipientId,
                type: type,
                title: title,
                message: message,
                data: data,
                isRead: isRead,
                readAt: readAt,
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

typedef $$NotificationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsTableTable,
      NotificationsTableData,
      $$NotificationsTableTableFilterComposer,
      $$NotificationsTableTableOrderingComposer,
      $$NotificationsTableTableAnnotationComposer,
      $$NotificationsTableTableCreateCompanionBuilder,
      $$NotificationsTableTableUpdateCompanionBuilder,
      (
        NotificationsTableData,
        BaseReferences<
          _$AppDatabase,
          $NotificationsTableTable,
          NotificationsTableData
        >,
      ),
      NotificationsTableData,
      PrefetchHooks Function()
    >;
typedef $$AuditLogsTableTableCreateCompanionBuilder =
    AuditLogsTableCompanion Function({
      required String id,
      Value<String?> actorId,
      Value<String?> actorRole,
      required String actionType,
      required String resourceType,
      Value<String?> resourceId,
      Value<String?> details,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AuditLogsTableTableUpdateCompanionBuilder =
    AuditLogsTableCompanion Function({
      Value<String> id,
      Value<String?> actorId,
      Value<String?> actorRole,
      Value<String> actionType,
      Value<String> resourceType,
      Value<String?> resourceId,
      Value<String?> details,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AuditLogsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTableTable> {
  $$AuditLogsTableTableFilterComposer({
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

  ColumnFilters<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorRole => $composableBuilder(
    column: $table.actorRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceType => $composableBuilder(
    column: $table.resourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTableTable> {
  $$AuditLogsTableTableOrderingComposer({
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

  ColumnOrderings<String> get actorId => $composableBuilder(
    column: $table.actorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorRole => $composableBuilder(
    column: $table.actorRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceType => $composableBuilder(
    column: $table.resourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTableTable> {
  $$AuditLogsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actorId =>
      $composableBuilder(column: $table.actorId, builder: (column) => column);

  GeneratedColumn<String> get actorRole =>
      $composableBuilder(column: $table.actorRole, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resourceType => $composableBuilder(
    column: $table.resourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AuditLogsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogsTableTable,
          AuditLogsTableData,
          $$AuditLogsTableTableFilterComposer,
          $$AuditLogsTableTableOrderingComposer,
          $$AuditLogsTableTableAnnotationComposer,
          $$AuditLogsTableTableCreateCompanionBuilder,
          $$AuditLogsTableTableUpdateCompanionBuilder,
          (
            AuditLogsTableData,
            BaseReferences<
              _$AppDatabase,
              $AuditLogsTableTable,
              AuditLogsTableData
            >,
          ),
          AuditLogsTableData,
          PrefetchHooks Function()
        > {
  $$AuditLogsTableTableTableManager(
    _$AppDatabase db,
    $AuditLogsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> actorId = const Value.absent(),
                Value<String?> actorRole = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String> resourceType = const Value.absent(),
                Value<String?> resourceId = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsTableCompanion(
                id: id,
                actorId: actorId,
                actorRole: actorRole,
                actionType: actionType,
                resourceType: resourceType,
                resourceId: resourceId,
                details: details,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> actorId = const Value.absent(),
                Value<String?> actorRole = const Value.absent(),
                required String actionType,
                required String resourceType,
                Value<String?> resourceId = const Value.absent(),
                Value<String?> details = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsTableCompanion.insert(
                id: id,
                actorId: actorId,
                actorRole: actorRole,
                actionType: actionType,
                resourceType: resourceType,
                resourceId: resourceId,
                details: details,
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

typedef $$AuditLogsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogsTableTable,
      AuditLogsTableData,
      $$AuditLogsTableTableFilterComposer,
      $$AuditLogsTableTableOrderingComposer,
      $$AuditLogsTableTableAnnotationComposer,
      $$AuditLogsTableTableCreateCompanionBuilder,
      $$AuditLogsTableTableUpdateCompanionBuilder,
      (
        AuditLogsTableData,
        BaseReferences<_$AppDatabase, $AuditLogsTableTable, AuditLogsTableData>,
      ),
      AuditLogsTableData,
      PrefetchHooks Function()
    >;
typedef $$SubscriptionsTableTableCreateCompanionBuilder =
    SubscriptionsTableCompanion Function({
      required String id,
      required String userId,
      Value<String> tier,
      Value<BigInt> storageQuota,
      Value<BigInt> storageUsed,
      Value<DateTime?> expiresAt,
      Value<bool> hasUsedTrial,
      Value<String?> playState,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SubscriptionsTableTableUpdateCompanionBuilder =
    SubscriptionsTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> tier,
      Value<BigInt> storageQuota,
      Value<BigInt> storageUsed,
      Value<DateTime?> expiresAt,
      Value<bool> hasUsedTrial,
      Value<String?> playState,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SubscriptionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SubscriptionsTableTable> {
  $$SubscriptionsTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get storageQuota => $composableBuilder(
    column: $table.storageQuota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get storageUsed => $composableBuilder(
    column: $table.storageUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasUsedTrial => $composableBuilder(
    column: $table.hasUsedTrial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playState => $composableBuilder(
    column: $table.playState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubscriptionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SubscriptionsTableTable> {
  $$SubscriptionsTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get storageQuota => $composableBuilder(
    column: $table.storageQuota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get storageUsed => $composableBuilder(
    column: $table.storageUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasUsedTrial => $composableBuilder(
    column: $table.hasUsedTrial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playState => $composableBuilder(
    column: $table.playState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubscriptionsTableTable> {
  $$SubscriptionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<BigInt> get storageQuota => $composableBuilder(
    column: $table.storageQuota,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get storageUsed => $composableBuilder(
    column: $table.storageUsed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<bool> get hasUsedTrial => $composableBuilder(
    column: $table.hasUsedTrial,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playState =>
      $composableBuilder(column: $table.playState, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SubscriptionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubscriptionsTableTable,
          SubscriptionsTableData,
          $$SubscriptionsTableTableFilterComposer,
          $$SubscriptionsTableTableOrderingComposer,
          $$SubscriptionsTableTableAnnotationComposer,
          $$SubscriptionsTableTableCreateCompanionBuilder,
          $$SubscriptionsTableTableUpdateCompanionBuilder,
          (
            SubscriptionsTableData,
            BaseReferences<
              _$AppDatabase,
              $SubscriptionsTableTable,
              SubscriptionsTableData
            >,
          ),
          SubscriptionsTableData,
          PrefetchHooks Function()
        > {
  $$SubscriptionsTableTableTableManager(
    _$AppDatabase db,
    $SubscriptionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> tier = const Value.absent(),
                Value<BigInt> storageQuota = const Value.absent(),
                Value<BigInt> storageUsed = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<bool> hasUsedTrial = const Value.absent(),
                Value<String?> playState = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsTableCompanion(
                id: id,
                userId: userId,
                tier: tier,
                storageQuota: storageQuota,
                storageUsed: storageUsed,
                expiresAt: expiresAt,
                hasUsedTrial: hasUsedTrial,
                playState: playState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String> tier = const Value.absent(),
                Value<BigInt> storageQuota = const Value.absent(),
                Value<BigInt> storageUsed = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<bool> hasUsedTrial = const Value.absent(),
                Value<String?> playState = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SubscriptionsTableCompanion.insert(
                id: id,
                userId: userId,
                tier: tier,
                storageQuota: storageQuota,
                storageUsed: storageUsed,
                expiresAt: expiresAt,
                hasUsedTrial: hasUsedTrial,
                playState: playState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubscriptionsTableTable,
      SubscriptionsTableData,
      $$SubscriptionsTableTableFilterComposer,
      $$SubscriptionsTableTableOrderingComposer,
      $$SubscriptionsTableTableAnnotationComposer,
      $$SubscriptionsTableTableCreateCompanionBuilder,
      $$SubscriptionsTableTableUpdateCompanionBuilder,
      (
        SubscriptionsTableData,
        BaseReferences<
          _$AppDatabase,
          $SubscriptionsTableTable,
          SubscriptionsTableData
        >,
      ),
      SubscriptionsTableData,
      PrefetchHooks Function()
    >;
typedef $$FamilyMembersTableTableCreateCompanionBuilder =
    FamilyMembersTableCompanion Function({
      required String id,
      required String subscriptionId,
      required String memberId,
      required DateTime addedAt,
      Value<int> rowid,
    });
typedef $$FamilyMembersTableTableUpdateCompanionBuilder =
    FamilyMembersTableCompanion Function({
      Value<String> id,
      Value<String> subscriptionId,
      Value<String> memberId,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

class $$FamilyMembersTableTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyMembersTableTable> {
  $$FamilyMembersTableTableFilterComposer({
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

  ColumnFilters<String> get subscriptionId => $composableBuilder(
    column: $table.subscriptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FamilyMembersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyMembersTableTable> {
  $$FamilyMembersTableTableOrderingComposer({
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

  ColumnOrderings<String> get subscriptionId => $composableBuilder(
    column: $table.subscriptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamilyMembersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyMembersTableTable> {
  $$FamilyMembersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subscriptionId => $composableBuilder(
    column: $table.subscriptionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$FamilyMembersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamilyMembersTableTable,
          FamilyMembersTableData,
          $$FamilyMembersTableTableFilterComposer,
          $$FamilyMembersTableTableOrderingComposer,
          $$FamilyMembersTableTableAnnotationComposer,
          $$FamilyMembersTableTableCreateCompanionBuilder,
          $$FamilyMembersTableTableUpdateCompanionBuilder,
          (
            FamilyMembersTableData,
            BaseReferences<
              _$AppDatabase,
              $FamilyMembersTableTable,
              FamilyMembersTableData
            >,
          ),
          FamilyMembersTableData,
          PrefetchHooks Function()
        > {
  $$FamilyMembersTableTableTableManager(
    _$AppDatabase db,
    $FamilyMembersTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyMembersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyMembersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyMembersTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> subscriptionId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyMembersTableCompanion(
                id: id,
                subscriptionId: subscriptionId,
                memberId: memberId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String subscriptionId,
                required String memberId,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => FamilyMembersTableCompanion.insert(
                id: id,
                subscriptionId: subscriptionId,
                memberId: memberId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FamilyMembersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamilyMembersTableTable,
      FamilyMembersTableData,
      $$FamilyMembersTableTableFilterComposer,
      $$FamilyMembersTableTableOrderingComposer,
      $$FamilyMembersTableTableAnnotationComposer,
      $$FamilyMembersTableTableCreateCompanionBuilder,
      $$FamilyMembersTableTableUpdateCompanionBuilder,
      (
        FamilyMembersTableData,
        BaseReferences<
          _$AppDatabase,
          $FamilyMembersTableTable,
          FamilyMembersTableData
        >,
      ),
      FamilyMembersTableData,
      PrefetchHooks Function()
    >;
typedef $$MealTimePreferencesTableTableCreateCompanionBuilder =
    MealTimePreferencesTableCompanion Function({
      required String id,
      required String userId,
      Value<String?> morningMeal,
      Value<String?> afternoonMeal,
      Value<String?> eveningMeal,
      Value<String?> nightMeal,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MealTimePreferencesTableTableUpdateCompanionBuilder =
    MealTimePreferencesTableCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> morningMeal,
      Value<String?> afternoonMeal,
      Value<String?> eveningMeal,
      Value<String?> nightMeal,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MealTimePreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MealTimePreferencesTableTable> {
  $$MealTimePreferencesTableTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get morningMeal => $composableBuilder(
    column: $table.morningMeal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get afternoonMeal => $composableBuilder(
    column: $table.afternoonMeal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eveningMeal => $composableBuilder(
    column: $table.eveningMeal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nightMeal => $composableBuilder(
    column: $table.nightMeal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MealTimePreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MealTimePreferencesTableTable> {
  $$MealTimePreferencesTableTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get morningMeal => $composableBuilder(
    column: $table.morningMeal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get afternoonMeal => $composableBuilder(
    column: $table.afternoonMeal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eveningMeal => $composableBuilder(
    column: $table.eveningMeal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nightMeal => $composableBuilder(
    column: $table.nightMeal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealTimePreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealTimePreferencesTableTable> {
  $$MealTimePreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get morningMeal => $composableBuilder(
    column: $table.morningMeal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get afternoonMeal => $composableBuilder(
    column: $table.afternoonMeal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eveningMeal => $composableBuilder(
    column: $table.eveningMeal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nightMeal =>
      $composableBuilder(column: $table.nightMeal, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MealTimePreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealTimePreferencesTableTable,
          MealTimePreferencesTableData,
          $$MealTimePreferencesTableTableFilterComposer,
          $$MealTimePreferencesTableTableOrderingComposer,
          $$MealTimePreferencesTableTableAnnotationComposer,
          $$MealTimePreferencesTableTableCreateCompanionBuilder,
          $$MealTimePreferencesTableTableUpdateCompanionBuilder,
          (
            MealTimePreferencesTableData,
            BaseReferences<
              _$AppDatabase,
              $MealTimePreferencesTableTable,
              MealTimePreferencesTableData
            >,
          ),
          MealTimePreferencesTableData,
          PrefetchHooks Function()
        > {
  $$MealTimePreferencesTableTableTableManager(
    _$AppDatabase db,
    $MealTimePreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealTimePreferencesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MealTimePreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MealTimePreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> morningMeal = const Value.absent(),
                Value<String?> afternoonMeal = const Value.absent(),
                Value<String?> eveningMeal = const Value.absent(),
                Value<String?> nightMeal = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealTimePreferencesTableCompanion(
                id: id,
                userId: userId,
                morningMeal: morningMeal,
                afternoonMeal: afternoonMeal,
                eveningMeal: eveningMeal,
                nightMeal: nightMeal,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> morningMeal = const Value.absent(),
                Value<String?> afternoonMeal = const Value.absent(),
                Value<String?> eveningMeal = const Value.absent(),
                Value<String?> nightMeal = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MealTimePreferencesTableCompanion.insert(
                id: id,
                userId: userId,
                morningMeal: morningMeal,
                afternoonMeal: afternoonMeal,
                eveningMeal: eveningMeal,
                nightMeal: nightMeal,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MealTimePreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealTimePreferencesTableTable,
      MealTimePreferencesTableData,
      $$MealTimePreferencesTableTableFilterComposer,
      $$MealTimePreferencesTableTableOrderingComposer,
      $$MealTimePreferencesTableTableAnnotationComposer,
      $$MealTimePreferencesTableTableCreateCompanionBuilder,
      $$MealTimePreferencesTableTableUpdateCompanionBuilder,
      (
        MealTimePreferencesTableData,
        BaseReferences<
          _$AppDatabase,
          $MealTimePreferencesTableTable,
          MealTimePreferencesTableData
        >,
      ),
      MealTimePreferencesTableData,
      PrefetchHooks Function()
    >;
typedef $$DoctorNotesTableTableCreateCompanionBuilder =
    DoctorNotesTableCompanion Function({
      required String id,
      required String doctorId,
      required String patientId,
      required String content,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DoctorNotesTableTableUpdateCompanionBuilder =
    DoctorNotesTableCompanion Function({
      Value<String> id,
      Value<String> doctorId,
      Value<String> patientId,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DoctorNotesTableTableFilterComposer
    extends Composer<_$AppDatabase, $DoctorNotesTableTable> {
  $$DoctorNotesTableTableFilterComposer({
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

  ColumnFilters<String> get doctorId => $composableBuilder(
    column: $table.doctorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DoctorNotesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DoctorNotesTableTable> {
  $$DoctorNotesTableTableOrderingComposer({
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

  ColumnOrderings<String> get doctorId => $composableBuilder(
    column: $table.doctorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DoctorNotesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DoctorNotesTableTable> {
  $$DoctorNotesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get doctorId =>
      $composableBuilder(column: $table.doctorId, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DoctorNotesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DoctorNotesTableTable,
          DoctorNotesTableData,
          $$DoctorNotesTableTableFilterComposer,
          $$DoctorNotesTableTableOrderingComposer,
          $$DoctorNotesTableTableAnnotationComposer,
          $$DoctorNotesTableTableCreateCompanionBuilder,
          $$DoctorNotesTableTableUpdateCompanionBuilder,
          (
            DoctorNotesTableData,
            BaseReferences<
              _$AppDatabase,
              $DoctorNotesTableTable,
              DoctorNotesTableData
            >,
          ),
          DoctorNotesTableData,
          PrefetchHooks Function()
        > {
  $$DoctorNotesTableTableTableManager(
    _$AppDatabase db,
    $DoctorNotesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DoctorNotesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DoctorNotesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DoctorNotesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> doctorId = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DoctorNotesTableCompanion(
                id: id,
                doctorId: doctorId,
                patientId: patientId,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String doctorId,
                required String patientId,
                required String content,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DoctorNotesTableCompanion.insert(
                id: id,
                doctorId: doctorId,
                patientId: patientId,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DoctorNotesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DoctorNotesTableTable,
      DoctorNotesTableData,
      $$DoctorNotesTableTableFilterComposer,
      $$DoctorNotesTableTableOrderingComposer,
      $$DoctorNotesTableTableAnnotationComposer,
      $$DoctorNotesTableTableCreateCompanionBuilder,
      $$DoctorNotesTableTableUpdateCompanionBuilder,
      (
        DoctorNotesTableData,
        BaseReferences<
          _$AppDatabase,
          $DoctorNotesTableTable,
          DoctorNotesTableData
        >,
      ),
      DoctorNotesTableData,
      PrefetchHooks Function()
    >;
typedef $$MedicationBatchesTableTableCreateCompanionBuilder =
    MedicationBatchesTableCompanion Function({
      required String id,
      required String patientId,
      required String name,
      required String scheduledTime,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MedicationBatchesTableTableUpdateCompanionBuilder =
    MedicationBatchesTableCompanion Function({
      Value<String> id,
      Value<String> patientId,
      Value<String> name,
      Value<String> scheduledTime,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MedicationBatchesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationBatchesTableTable> {
  $$MedicationBatchesTableTableFilterComposer({
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

  ColumnFilters<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationBatchesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationBatchesTableTable> {
  $$MedicationBatchesTableTableOrderingComposer({
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

  ColumnOrderings<String> get patientId => $composableBuilder(
    column: $table.patientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationBatchesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationBatchesTableTable> {
  $$MedicationBatchesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get patientId =>
      $composableBuilder(column: $table.patientId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MedicationBatchesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationBatchesTableTable,
          MedicationBatchesTableData,
          $$MedicationBatchesTableTableFilterComposer,
          $$MedicationBatchesTableTableOrderingComposer,
          $$MedicationBatchesTableTableAnnotationComposer,
          $$MedicationBatchesTableTableCreateCompanionBuilder,
          $$MedicationBatchesTableTableUpdateCompanionBuilder,
          (
            MedicationBatchesTableData,
            BaseReferences<
              _$AppDatabase,
              $MedicationBatchesTableTable,
              MedicationBatchesTableData
            >,
          ),
          MedicationBatchesTableData,
          PrefetchHooks Function()
        > {
  $$MedicationBatchesTableTableTableManager(
    _$AppDatabase db,
    $MedicationBatchesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationBatchesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MedicationBatchesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationBatchesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> patientId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> scheduledTime = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationBatchesTableCompanion(
                id: id,
                patientId: patientId,
                name: name,
                scheduledTime: scheduledTime,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String patientId,
                required String name,
                required String scheduledTime,
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MedicationBatchesTableCompanion.insert(
                id: id,
                patientId: patientId,
                name: name,
                scheduledTime: scheduledTime,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationBatchesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationBatchesTableTable,
      MedicationBatchesTableData,
      $$MedicationBatchesTableTableFilterComposer,
      $$MedicationBatchesTableTableOrderingComposer,
      $$MedicationBatchesTableTableAnnotationComposer,
      $$MedicationBatchesTableTableCreateCompanionBuilder,
      $$MedicationBatchesTableTableUpdateCompanionBuilder,
      (
        MedicationBatchesTableData,
        BaseReferences<
          _$AppDatabase,
          $MedicationBatchesTableTable,
          MedicationBatchesTableData
        >,
      ),
      MedicationBatchesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
  $$ProfilesTableTableTableManager get profilesTable =>
      $$ProfilesTableTableTableManager(_db, _db.profilesTable);
  $$ConnectionsTableTableTableManager get connectionsTable =>
      $$ConnectionsTableTableTableManager(_db, _db.connectionsTable);
  $$ConnectionTokensTableTableTableManager get connectionTokensTable =>
      $$ConnectionTokensTableTableTableManager(_db, _db.connectionTokensTable);
  $$PrescriptionsTableTableTableManager get prescriptionsTable =>
      $$PrescriptionsTableTableTableManager(_db, _db.prescriptionsTable);
  $$PrescriptionVersionsTableTableTableManager get prescriptionVersionsTable =>
      $$PrescriptionVersionsTableTableTableManager(
        _db,
        _db.prescriptionVersionsTable,
      );
  $$MedicationsTableTableTableManager get medicationsTable =>
      $$MedicationsTableTableTableManager(_db, _db.medicationsTable);
  $$DoseEventsTableTableTableManager get doseEventsTable =>
      $$DoseEventsTableTableTableManager(_db, _db.doseEventsTable);
  $$NotificationsTableTableTableManager get notificationsTable =>
      $$NotificationsTableTableTableManager(_db, _db.notificationsTable);
  $$AuditLogsTableTableTableManager get auditLogsTable =>
      $$AuditLogsTableTableTableManager(_db, _db.auditLogsTable);
  $$SubscriptionsTableTableTableManager get subscriptionsTable =>
      $$SubscriptionsTableTableTableManager(_db, _db.subscriptionsTable);
  $$FamilyMembersTableTableTableManager get familyMembersTable =>
      $$FamilyMembersTableTableTableManager(_db, _db.familyMembersTable);
  $$MealTimePreferencesTableTableTableManager get mealTimePreferencesTable =>
      $$MealTimePreferencesTableTableTableManager(
        _db,
        _db.mealTimePreferencesTable,
      );
  $$DoctorNotesTableTableTableManager get doctorNotesTable =>
      $$DoctorNotesTableTableTableManager(_db, _db.doctorNotesTable);
  $$MedicationBatchesTableTableTableManager get medicationBatchesTable =>
      $$MedicationBatchesTableTableTableManager(
        _db,
        _db.medicationBatchesTable,
      );
}
