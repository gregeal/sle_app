// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $VocabCardsTable extends VocabCards
    with TableInfo<$VocabCardsTable, VocabCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleFrMeta = const VerificationMeta(
    'exampleFr',
  );
  @override
  late final GeneratedColumn<String> exampleFr = GeneratedColumn<String>(
    'example_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    front,
    back,
    exampleFr,
    domain,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocab_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    if (data.containsKey('example_fr')) {
      context.handle(
        _exampleFrMeta,
        exampleFr.isAcceptableOrUnknown(data['example_fr']!, _exampleFrMeta),
      );
    } else if (isInserting) {
      context.missing(_exampleFrMeta);
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
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
  VocabCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      )!,
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      )!,
      exampleFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_fr'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VocabCardsTable createAlias(String alias) {
    return $VocabCardsTable(attachedDatabase, alias);
  }
}

class VocabCard extends DataClass implements Insertable<VocabCard> {
  final int id;
  final String front;
  final String back;
  final String exampleFr;
  final String domain;
  final DateTime createdAt;
  const VocabCard({
    required this.id,
    required this.front,
    required this.back,
    required this.exampleFr,
    required this.domain,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    map['example_fr'] = Variable<String>(exampleFr);
    map['domain'] = Variable<String>(domain);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VocabCardsCompanion toCompanion(bool nullToAbsent) {
    return VocabCardsCompanion(
      id: Value(id),
      front: Value(front),
      back: Value(back),
      exampleFr: Value(exampleFr),
      domain: Value(domain),
      createdAt: Value(createdAt),
    );
  }

  factory VocabCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabCard(
      id: serializer.fromJson<int>(json['id']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
      exampleFr: serializer.fromJson<String>(json['exampleFr']),
      domain: serializer.fromJson<String>(json['domain']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
      'exampleFr': serializer.toJson<String>(exampleFr),
      'domain': serializer.toJson<String>(domain),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VocabCard copyWith({
    int? id,
    String? front,
    String? back,
    String? exampleFr,
    String? domain,
    DateTime? createdAt,
  }) => VocabCard(
    id: id ?? this.id,
    front: front ?? this.front,
    back: back ?? this.back,
    exampleFr: exampleFr ?? this.exampleFr,
    domain: domain ?? this.domain,
    createdAt: createdAt ?? this.createdAt,
  );
  VocabCard copyWithCompanion(VocabCardsCompanion data) {
    return VocabCard(
      id: data.id.present ? data.id.value : this.id,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      exampleFr: data.exampleFr.present ? data.exampleFr.value : this.exampleFr,
      domain: data.domain.present ? data.domain.value : this.domain,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabCard(')
          ..write('id: $id, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('exampleFr: $exampleFr, ')
          ..write('domain: $domain, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, front, back, exampleFr, domain, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabCard &&
          other.id == this.id &&
          other.front == this.front &&
          other.back == this.back &&
          other.exampleFr == this.exampleFr &&
          other.domain == this.domain &&
          other.createdAt == this.createdAt);
}

class VocabCardsCompanion extends UpdateCompanion<VocabCard> {
  final Value<int> id;
  final Value<String> front;
  final Value<String> back;
  final Value<String> exampleFr;
  final Value<String> domain;
  final Value<DateTime> createdAt;
  const VocabCardsCompanion({
    this.id = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.exampleFr = const Value.absent(),
    this.domain = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  VocabCardsCompanion.insert({
    this.id = const Value.absent(),
    required String front,
    required String back,
    required String exampleFr,
    required String domain,
    this.createdAt = const Value.absent(),
  }) : front = Value(front),
       back = Value(back),
       exampleFr = Value(exampleFr),
       domain = Value(domain);
  static Insertable<VocabCard> custom({
    Expression<int>? id,
    Expression<String>? front,
    Expression<String>? back,
    Expression<String>? exampleFr,
    Expression<String>? domain,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (exampleFr != null) 'example_fr': exampleFr,
      if (domain != null) 'domain': domain,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  VocabCardsCompanion copyWith({
    Value<int>? id,
    Value<String>? front,
    Value<String>? back,
    Value<String>? exampleFr,
    Value<String>? domain,
    Value<DateTime>? createdAt,
  }) {
    return VocabCardsCompanion(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      exampleFr: exampleFr ?? this.exampleFr,
      domain: domain ?? this.domain,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (exampleFr.present) {
      map['example_fr'] = Variable<String>(exampleFr.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabCardsCompanion(')
          ..write('id: $id, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('exampleFr: $exampleFr, ')
          ..write('domain: $domain, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReviewStatesTable extends ReviewStates
    with TableInfo<$ReviewStatesTable, ReviewState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cardId,
    easeFactor,
    intervalDays,
    repetitions,
    lapses,
    dueDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId};
  @override
  ReviewState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewState(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_id'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
    );
  }

  @override
  $ReviewStatesTable createAlias(String alias) {
    return $ReviewStatesTable(attachedDatabase, alias);
  }
}

class ReviewState extends DataClass implements Insertable<ReviewState> {
  final int cardId;
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final int lapses;
  final DateTime dueDate;
  const ReviewState({
    required this.cardId,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    required this.dueDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<int>(cardId);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['lapses'] = Variable<int>(lapses);
    map['due_date'] = Variable<DateTime>(dueDate);
    return map;
  }

  ReviewStatesCompanion toCompanion(bool nullToAbsent) {
    return ReviewStatesCompanion(
      cardId: Value(cardId),
      easeFactor: Value(easeFactor),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      lapses: Value(lapses),
      dueDate: Value(dueDate),
    );
  }

  factory ReviewState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewState(
      cardId: serializer.fromJson<int>(json['cardId']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      lapses: serializer.fromJson<int>(json['lapses']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<int>(cardId),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'lapses': serializer.toJson<int>(lapses),
      'dueDate': serializer.toJson<DateTime>(dueDate),
    };
  }

  ReviewState copyWith({
    int? cardId,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    int? lapses,
    DateTime? dueDate,
  }) => ReviewState(
    cardId: cardId ?? this.cardId,
    easeFactor: easeFactor ?? this.easeFactor,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    lapses: lapses ?? this.lapses,
    dueDate: dueDate ?? this.dueDate,
  );
  ReviewState copyWithCompanion(ReviewStatesCompanion data) {
    return ReviewState(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewState(')
          ..write('cardId: $cardId, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('dueDate: $dueDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cardId,
    easeFactor,
    intervalDays,
    repetitions,
    lapses,
    dueDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewState &&
          other.cardId == this.cardId &&
          other.easeFactor == this.easeFactor &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.lapses == this.lapses &&
          other.dueDate == this.dueDate);
}

class ReviewStatesCompanion extends UpdateCompanion<ReviewState> {
  final Value<int> cardId;
  final Value<double> easeFactor;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<int> lapses;
  final Value<DateTime> dueDate;
  const ReviewStatesCompanion({
    this.cardId = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    this.dueDate = const Value.absent(),
  });
  ReviewStatesCompanion.insert({
    this.cardId = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    required DateTime dueDate,
  }) : dueDate = Value(dueDate);
  static Insertable<ReviewState> custom({
    Expression<int>? cardId,
    Expression<double>? easeFactor,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<int>? lapses,
    Expression<DateTime>? dueDate,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (lapses != null) 'lapses': lapses,
      if (dueDate != null) 'due_date': dueDate,
    });
  }

  ReviewStatesCompanion copyWith({
    Value<int>? cardId,
    Value<double>? easeFactor,
    Value<int>? intervalDays,
    Value<int>? repetitions,
    Value<int>? lapses,
    Value<DateTime>? dueDate,
  }) {
    return ReviewStatesCompanion(
      cardId: cardId ?? this.cardId,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewStatesCompanion(')
          ..write('cardId: $cardId, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('dueDate: $dueDate')
          ..write(')'))
        .toString();
  }
}

class $DrillItemsTable extends DrillItems
    with TableInfo<$DrillItemsTable, DrillItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrillItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsMeta = const VerificationMeta(
    'options',
  );
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
    'options',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctIndexMeta = const VerificationMeta(
    'correctIndex',
  );
  @override
  late final GeneratedColumn<int> correctIndex = GeneratedColumn<int>(
    'correct_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationFrMeta = const VerificationMeta(
    'explanationFr',
  );
  @override
  late final GeneratedColumn<String> explanationFr = GeneratedColumn<String>(
    'explanation_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('seed'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topic,
    prompt,
    options,
    correctIndex,
    explanationFr,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drill_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<DrillItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('options')) {
      context.handle(
        _optionsMeta,
        options.isAcceptableOrUnknown(data['options']!, _optionsMeta),
      );
    } else if (isInserting) {
      context.missing(_optionsMeta);
    }
    if (data.containsKey('correct_index')) {
      context.handle(
        _correctIndexMeta,
        correctIndex.isAcceptableOrUnknown(
          data['correct_index']!,
          _correctIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctIndexMeta);
    }
    if (data.containsKey('explanation_fr')) {
      context.handle(
        _explanationFrMeta,
        explanationFr.isAcceptableOrUnknown(
          data['explanation_fr']!,
          _explanationFrMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationFrMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DrillItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DrillItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      options: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options'],
      )!,
      correctIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_index'],
      )!,
      explanationFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation_fr'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $DrillItemsTable createAlias(String alias) {
    return $DrillItemsTable(attachedDatabase, alias);
  }
}

class DrillItem extends DataClass implements Insertable<DrillItem> {
  final int id;
  final String topic;
  final String prompt;

  /// JSON-encoded list of exactly four answer strings.
  final String options;
  final int correctIndex;
  final String explanationFr;
  final String source;
  const DrillItem({
    required this.id,
    required this.topic,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanationFr,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['topic'] = Variable<String>(topic);
    map['prompt'] = Variable<String>(prompt);
    map['options'] = Variable<String>(options);
    map['correct_index'] = Variable<int>(correctIndex);
    map['explanation_fr'] = Variable<String>(explanationFr);
    map['source'] = Variable<String>(source);
    return map;
  }

  DrillItemsCompanion toCompanion(bool nullToAbsent) {
    return DrillItemsCompanion(
      id: Value(id),
      topic: Value(topic),
      prompt: Value(prompt),
      options: Value(options),
      correctIndex: Value(correctIndex),
      explanationFr: Value(explanationFr),
      source: Value(source),
    );
  }

  factory DrillItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DrillItem(
      id: serializer.fromJson<int>(json['id']),
      topic: serializer.fromJson<String>(json['topic']),
      prompt: serializer.fromJson<String>(json['prompt']),
      options: serializer.fromJson<String>(json['options']),
      correctIndex: serializer.fromJson<int>(json['correctIndex']),
      explanationFr: serializer.fromJson<String>(json['explanationFr']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'topic': serializer.toJson<String>(topic),
      'prompt': serializer.toJson<String>(prompt),
      'options': serializer.toJson<String>(options),
      'correctIndex': serializer.toJson<int>(correctIndex),
      'explanationFr': serializer.toJson<String>(explanationFr),
      'source': serializer.toJson<String>(source),
    };
  }

  DrillItem copyWith({
    int? id,
    String? topic,
    String? prompt,
    String? options,
    int? correctIndex,
    String? explanationFr,
    String? source,
  }) => DrillItem(
    id: id ?? this.id,
    topic: topic ?? this.topic,
    prompt: prompt ?? this.prompt,
    options: options ?? this.options,
    correctIndex: correctIndex ?? this.correctIndex,
    explanationFr: explanationFr ?? this.explanationFr,
    source: source ?? this.source,
  );
  DrillItem copyWithCompanion(DrillItemsCompanion data) {
    return DrillItem(
      id: data.id.present ? data.id.value : this.id,
      topic: data.topic.present ? data.topic.value : this.topic,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      options: data.options.present ? data.options.value : this.options,
      correctIndex: data.correctIndex.present
          ? data.correctIndex.value
          : this.correctIndex,
      explanationFr: data.explanationFr.present
          ? data.explanationFr.value
          : this.explanationFr,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DrillItem(')
          ..write('id: $id, ')
          ..write('topic: $topic, ')
          ..write('prompt: $prompt, ')
          ..write('options: $options, ')
          ..write('correctIndex: $correctIndex, ')
          ..write('explanationFr: $explanationFr, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    topic,
    prompt,
    options,
    correctIndex,
    explanationFr,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrillItem &&
          other.id == this.id &&
          other.topic == this.topic &&
          other.prompt == this.prompt &&
          other.options == this.options &&
          other.correctIndex == this.correctIndex &&
          other.explanationFr == this.explanationFr &&
          other.source == this.source);
}

class DrillItemsCompanion extends UpdateCompanion<DrillItem> {
  final Value<int> id;
  final Value<String> topic;
  final Value<String> prompt;
  final Value<String> options;
  final Value<int> correctIndex;
  final Value<String> explanationFr;
  final Value<String> source;
  const DrillItemsCompanion({
    this.id = const Value.absent(),
    this.topic = const Value.absent(),
    this.prompt = const Value.absent(),
    this.options = const Value.absent(),
    this.correctIndex = const Value.absent(),
    this.explanationFr = const Value.absent(),
    this.source = const Value.absent(),
  });
  DrillItemsCompanion.insert({
    this.id = const Value.absent(),
    required String topic,
    required String prompt,
    required String options,
    required int correctIndex,
    required String explanationFr,
    this.source = const Value.absent(),
  }) : topic = Value(topic),
       prompt = Value(prompt),
       options = Value(options),
       correctIndex = Value(correctIndex),
       explanationFr = Value(explanationFr);
  static Insertable<DrillItem> custom({
    Expression<int>? id,
    Expression<String>? topic,
    Expression<String>? prompt,
    Expression<String>? options,
    Expression<int>? correctIndex,
    Expression<String>? explanationFr,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topic != null) 'topic': topic,
      if (prompt != null) 'prompt': prompt,
      if (options != null) 'options': options,
      if (correctIndex != null) 'correct_index': correctIndex,
      if (explanationFr != null) 'explanation_fr': explanationFr,
      if (source != null) 'source': source,
    });
  }

  DrillItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? topic,
    Value<String>? prompt,
    Value<String>? options,
    Value<int>? correctIndex,
    Value<String>? explanationFr,
    Value<String>? source,
  }) {
    return DrillItemsCompanion(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanationFr: explanationFr ?? this.explanationFr,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (correctIndex.present) {
      map['correct_index'] = Variable<int>(correctIndex.value);
    }
    if (explanationFr.present) {
      map['explanation_fr'] = Variable<String>(explanationFr.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrillItemsCompanion(')
          ..write('id: $id, ')
          ..write('topic: $topic, ')
          ..write('prompt: $prompt, ')
          ..write('options: $options, ')
          ..write('correctIndex: $correctIndex, ')
          ..write('explanationFr: $explanationFr, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $DrillAttemptsTable extends DrillAttempts
    with TableInfo<$DrillAttemptsTable, DrillAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrillAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wasCorrectMeta = const VerificationMeta(
    'wasCorrect',
  );
  @override
  late final GeneratedColumn<bool> wasCorrect = GeneratedColumn<bool>(
    'was_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, itemId, wasCorrect, answeredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drill_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DrillAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('was_correct')) {
      context.handle(
        _wasCorrectMeta,
        wasCorrect.isAcceptableOrUnknown(data['was_correct']!, _wasCorrectMeta),
      );
    } else if (isInserting) {
      context.missing(_wasCorrectMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DrillAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DrillAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      wasCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_correct'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}answered_at'],
      )!,
    );
  }

  @override
  $DrillAttemptsTable createAlias(String alias) {
    return $DrillAttemptsTable(attachedDatabase, alias);
  }
}

class DrillAttempt extends DataClass implements Insertable<DrillAttempt> {
  final int id;
  final int itemId;
  final bool wasCorrect;
  final DateTime answeredAt;
  const DrillAttempt({
    required this.id,
    required this.itemId,
    required this.wasCorrect,
    required this.answeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['was_correct'] = Variable<bool>(wasCorrect);
    map['answered_at'] = Variable<DateTime>(answeredAt);
    return map;
  }

  DrillAttemptsCompanion toCompanion(bool nullToAbsent) {
    return DrillAttemptsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      wasCorrect: Value(wasCorrect),
      answeredAt: Value(answeredAt),
    );
  }

  factory DrillAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DrillAttempt(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      wasCorrect: serializer.fromJson<bool>(json['wasCorrect']),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'wasCorrect': serializer.toJson<bool>(wasCorrect),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
    };
  }

  DrillAttempt copyWith({
    int? id,
    int? itemId,
    bool? wasCorrect,
    DateTime? answeredAt,
  }) => DrillAttempt(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    wasCorrect: wasCorrect ?? this.wasCorrect,
    answeredAt: answeredAt ?? this.answeredAt,
  );
  DrillAttempt copyWithCompanion(DrillAttemptsCompanion data) {
    return DrillAttempt(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      wasCorrect: data.wasCorrect.present
          ? data.wasCorrect.value
          : this.wasCorrect,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DrillAttempt(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, wasCorrect, answeredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrillAttempt &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.wasCorrect == this.wasCorrect &&
          other.answeredAt == this.answeredAt);
}

class DrillAttemptsCompanion extends UpdateCompanion<DrillAttempt> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<bool> wasCorrect;
  final Value<DateTime> answeredAt;
  const DrillAttemptsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.wasCorrect = const Value.absent(),
    this.answeredAt = const Value.absent(),
  });
  DrillAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required bool wasCorrect,
    required DateTime answeredAt,
  }) : itemId = Value(itemId),
       wasCorrect = Value(wasCorrect),
       answeredAt = Value(answeredAt);
  static Insertable<DrillAttempt> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<bool>? wasCorrect,
    Expression<DateTime>? answeredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (wasCorrect != null) 'was_correct': wasCorrect,
      if (answeredAt != null) 'answered_at': answeredAt,
    });
  }

  DrillAttemptsCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<bool>? wasCorrect,
    Value<DateTime>? answeredAt,
  }) {
    return DrillAttemptsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      wasCorrect: wasCorrect ?? this.wasCorrect,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (wasCorrect.present) {
      map['was_correct'] = Variable<bool>(wasCorrect.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrillAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }
}

class $CurriculumWeeksTable extends CurriculumWeeks
    with TableInfo<$CurriculumWeeksTable, CurriculumWeek> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurriculumWeeksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _weekNumberMeta = const VerificationMeta(
    'weekNumber',
  );
  @override
  late final GeneratedColumn<int> weekNumber = GeneratedColumn<int>(
    'week_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themeFrMeta = const VerificationMeta(
    'themeFr',
  );
  @override
  late final GeneratedColumn<String> themeFr = GeneratedColumn<String>(
    'theme_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _themeEnMeta = const VerificationMeta(
    'themeEn',
  );
  @override
  late final GeneratedColumn<String> themeEn = GeneratedColumn<String>(
    'theme_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grammarTopicsMeta = const VerificationMeta(
    'grammarTopics',
  );
  @override
  late final GeneratedColumn<String> grammarTopics = GeneratedColumn<String>(
    'grammar_topics',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vocabDomainMeta = const VerificationMeta(
    'vocabDomain',
  );
  @override
  late final GeneratedColumn<String> vocabDomain = GeneratedColumn<String>(
    'vocab_domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resourceSlotsMeta = const VerificationMeta(
    'resourceSlots',
  );
  @override
  late final GeneratedColumn<String> resourceSlots = GeneratedColumn<String>(
    'resource_slots',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    weekNumber,
    themeFr,
    themeEn,
    grammarTopics,
    vocabDomain,
    resourceSlots,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'curriculum_weeks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CurriculumWeek> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('week_number')) {
      context.handle(
        _weekNumberMeta,
        weekNumber.isAcceptableOrUnknown(data['week_number']!, _weekNumberMeta),
      );
    }
    if (data.containsKey('theme_fr')) {
      context.handle(
        _themeFrMeta,
        themeFr.isAcceptableOrUnknown(data['theme_fr']!, _themeFrMeta),
      );
    } else if (isInserting) {
      context.missing(_themeFrMeta);
    }
    if (data.containsKey('theme_en')) {
      context.handle(
        _themeEnMeta,
        themeEn.isAcceptableOrUnknown(data['theme_en']!, _themeEnMeta),
      );
    } else if (isInserting) {
      context.missing(_themeEnMeta);
    }
    if (data.containsKey('grammar_topics')) {
      context.handle(
        _grammarTopicsMeta,
        grammarTopics.isAcceptableOrUnknown(
          data['grammar_topics']!,
          _grammarTopicsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grammarTopicsMeta);
    }
    if (data.containsKey('vocab_domain')) {
      context.handle(
        _vocabDomainMeta,
        vocabDomain.isAcceptableOrUnknown(
          data['vocab_domain']!,
          _vocabDomainMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vocabDomainMeta);
    }
    if (data.containsKey('resource_slots')) {
      context.handle(
        _resourceSlotsMeta,
        resourceSlots.isAcceptableOrUnknown(
          data['resource_slots']!,
          _resourceSlotsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resourceSlotsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {weekNumber};
  @override
  CurriculumWeek map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurriculumWeek(
      weekNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_number'],
      )!,
      themeFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_fr'],
      )!,
      themeEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_en'],
      )!,
      grammarTopics: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grammar_topics'],
      )!,
      vocabDomain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vocab_domain'],
      )!,
      resourceSlots: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_slots'],
      )!,
    );
  }

  @override
  $CurriculumWeeksTable createAlias(String alias) {
    return $CurriculumWeeksTable(attachedDatabase, alias);
  }
}

class CurriculumWeek extends DataClass implements Insertable<CurriculumWeek> {
  final int weekNumber;
  final String themeFr;
  final String themeEn;

  /// JSON-encoded list of grammar topic keys.
  final String grammarTopics;
  final String vocabDomain;

  /// JSON-encoded list of {label, url} objects.
  final String resourceSlots;
  const CurriculumWeek({
    required this.weekNumber,
    required this.themeFr,
    required this.themeEn,
    required this.grammarTopics,
    required this.vocabDomain,
    required this.resourceSlots,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['week_number'] = Variable<int>(weekNumber);
    map['theme_fr'] = Variable<String>(themeFr);
    map['theme_en'] = Variable<String>(themeEn);
    map['grammar_topics'] = Variable<String>(grammarTopics);
    map['vocab_domain'] = Variable<String>(vocabDomain);
    map['resource_slots'] = Variable<String>(resourceSlots);
    return map;
  }

  CurriculumWeeksCompanion toCompanion(bool nullToAbsent) {
    return CurriculumWeeksCompanion(
      weekNumber: Value(weekNumber),
      themeFr: Value(themeFr),
      themeEn: Value(themeEn),
      grammarTopics: Value(grammarTopics),
      vocabDomain: Value(vocabDomain),
      resourceSlots: Value(resourceSlots),
    );
  }

  factory CurriculumWeek.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurriculumWeek(
      weekNumber: serializer.fromJson<int>(json['weekNumber']),
      themeFr: serializer.fromJson<String>(json['themeFr']),
      themeEn: serializer.fromJson<String>(json['themeEn']),
      grammarTopics: serializer.fromJson<String>(json['grammarTopics']),
      vocabDomain: serializer.fromJson<String>(json['vocabDomain']),
      resourceSlots: serializer.fromJson<String>(json['resourceSlots']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'weekNumber': serializer.toJson<int>(weekNumber),
      'themeFr': serializer.toJson<String>(themeFr),
      'themeEn': serializer.toJson<String>(themeEn),
      'grammarTopics': serializer.toJson<String>(grammarTopics),
      'vocabDomain': serializer.toJson<String>(vocabDomain),
      'resourceSlots': serializer.toJson<String>(resourceSlots),
    };
  }

  CurriculumWeek copyWith({
    int? weekNumber,
    String? themeFr,
    String? themeEn,
    String? grammarTopics,
    String? vocabDomain,
    String? resourceSlots,
  }) => CurriculumWeek(
    weekNumber: weekNumber ?? this.weekNumber,
    themeFr: themeFr ?? this.themeFr,
    themeEn: themeEn ?? this.themeEn,
    grammarTopics: grammarTopics ?? this.grammarTopics,
    vocabDomain: vocabDomain ?? this.vocabDomain,
    resourceSlots: resourceSlots ?? this.resourceSlots,
  );
  CurriculumWeek copyWithCompanion(CurriculumWeeksCompanion data) {
    return CurriculumWeek(
      weekNumber: data.weekNumber.present
          ? data.weekNumber.value
          : this.weekNumber,
      themeFr: data.themeFr.present ? data.themeFr.value : this.themeFr,
      themeEn: data.themeEn.present ? data.themeEn.value : this.themeEn,
      grammarTopics: data.grammarTopics.present
          ? data.grammarTopics.value
          : this.grammarTopics,
      vocabDomain: data.vocabDomain.present
          ? data.vocabDomain.value
          : this.vocabDomain,
      resourceSlots: data.resourceSlots.present
          ? data.resourceSlots.value
          : this.resourceSlots,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurriculumWeek(')
          ..write('weekNumber: $weekNumber, ')
          ..write('themeFr: $themeFr, ')
          ..write('themeEn: $themeEn, ')
          ..write('grammarTopics: $grammarTopics, ')
          ..write('vocabDomain: $vocabDomain, ')
          ..write('resourceSlots: $resourceSlots')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    weekNumber,
    themeFr,
    themeEn,
    grammarTopics,
    vocabDomain,
    resourceSlots,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurriculumWeek &&
          other.weekNumber == this.weekNumber &&
          other.themeFr == this.themeFr &&
          other.themeEn == this.themeEn &&
          other.grammarTopics == this.grammarTopics &&
          other.vocabDomain == this.vocabDomain &&
          other.resourceSlots == this.resourceSlots);
}

class CurriculumWeeksCompanion extends UpdateCompanion<CurriculumWeek> {
  final Value<int> weekNumber;
  final Value<String> themeFr;
  final Value<String> themeEn;
  final Value<String> grammarTopics;
  final Value<String> vocabDomain;
  final Value<String> resourceSlots;
  const CurriculumWeeksCompanion({
    this.weekNumber = const Value.absent(),
    this.themeFr = const Value.absent(),
    this.themeEn = const Value.absent(),
    this.grammarTopics = const Value.absent(),
    this.vocabDomain = const Value.absent(),
    this.resourceSlots = const Value.absent(),
  });
  CurriculumWeeksCompanion.insert({
    this.weekNumber = const Value.absent(),
    required String themeFr,
    required String themeEn,
    required String grammarTopics,
    required String vocabDomain,
    required String resourceSlots,
  }) : themeFr = Value(themeFr),
       themeEn = Value(themeEn),
       grammarTopics = Value(grammarTopics),
       vocabDomain = Value(vocabDomain),
       resourceSlots = Value(resourceSlots);
  static Insertable<CurriculumWeek> custom({
    Expression<int>? weekNumber,
    Expression<String>? themeFr,
    Expression<String>? themeEn,
    Expression<String>? grammarTopics,
    Expression<String>? vocabDomain,
    Expression<String>? resourceSlots,
  }) {
    return RawValuesInsertable({
      if (weekNumber != null) 'week_number': weekNumber,
      if (themeFr != null) 'theme_fr': themeFr,
      if (themeEn != null) 'theme_en': themeEn,
      if (grammarTopics != null) 'grammar_topics': grammarTopics,
      if (vocabDomain != null) 'vocab_domain': vocabDomain,
      if (resourceSlots != null) 'resource_slots': resourceSlots,
    });
  }

  CurriculumWeeksCompanion copyWith({
    Value<int>? weekNumber,
    Value<String>? themeFr,
    Value<String>? themeEn,
    Value<String>? grammarTopics,
    Value<String>? vocabDomain,
    Value<String>? resourceSlots,
  }) {
    return CurriculumWeeksCompanion(
      weekNumber: weekNumber ?? this.weekNumber,
      themeFr: themeFr ?? this.themeFr,
      themeEn: themeEn ?? this.themeEn,
      grammarTopics: grammarTopics ?? this.grammarTopics,
      vocabDomain: vocabDomain ?? this.vocabDomain,
      resourceSlots: resourceSlots ?? this.resourceSlots,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (weekNumber.present) {
      map['week_number'] = Variable<int>(weekNumber.value);
    }
    if (themeFr.present) {
      map['theme_fr'] = Variable<String>(themeFr.value);
    }
    if (themeEn.present) {
      map['theme_en'] = Variable<String>(themeEn.value);
    }
    if (grammarTopics.present) {
      map['grammar_topics'] = Variable<String>(grammarTopics.value);
    }
    if (vocabDomain.present) {
      map['vocab_domain'] = Variable<String>(vocabDomain.value);
    }
    if (resourceSlots.present) {
      map['resource_slots'] = Variable<String>(resourceSlots.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurriculumWeeksCompanion(')
          ..write('weekNumber: $weekNumber, ')
          ..write('themeFr: $themeFr, ')
          ..write('themeEn: $themeEn, ')
          ..write('grammarTopics: $grammarTopics, ')
          ..write('vocabDomain: $vocabDomain, ')
          ..write('resourceSlots: $resourceSlots')
          ..write(')'))
        .toString();
  }
}

class $SessionLogsTable extends SessionLogs
    with TableInfo<$SessionLogsTable, SessionLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blocksPlannedMeta = const VerificationMeta(
    'blocksPlanned',
  );
  @override
  late final GeneratedColumn<String> blocksPlanned = GeneratedColumn<String>(
    'blocks_planned',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blocksCompletedMeta = const VerificationMeta(
    'blocksCompleted',
  );
  @override
  late final GeneratedColumn<String> blocksCompleted = GeneratedColumn<String>(
    'blocks_completed',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesActiveMeta = const VerificationMeta(
    'minutesActive',
  );
  @override
  late final GeneratedColumn<int> minutesActive = GeneratedColumn<int>(
    'minutes_active',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    blocksPlanned,
    blocksCompleted,
    minutesActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('blocks_planned')) {
      context.handle(
        _blocksPlannedMeta,
        blocksPlanned.isAcceptableOrUnknown(
          data['blocks_planned']!,
          _blocksPlannedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_blocksPlannedMeta);
    }
    if (data.containsKey('blocks_completed')) {
      context.handle(
        _blocksCompletedMeta,
        blocksCompleted.isAcceptableOrUnknown(
          data['blocks_completed']!,
          _blocksCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_blocksCompletedMeta);
    }
    if (data.containsKey('minutes_active')) {
      context.handle(
        _minutesActiveMeta,
        minutesActive.isAcceptableOrUnknown(
          data['minutes_active']!,
          _minutesActiveMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  SessionLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionLog(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      blocksPlanned: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocks_planned'],
      )!,
      blocksCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocks_completed'],
      )!,
      minutesActive: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes_active'],
      )!,
    );
  }

  @override
  $SessionLogsTable createAlias(String alias) {
    return $SessionLogsTable(attachedDatabase, alias);
  }
}

class SessionLog extends DataClass implements Insertable<SessionLog> {
  /// Date-only key, yyyy-MM-dd.
  final String date;

  /// JSON-encoded lists of block type names.
  final String blocksPlanned;
  final String blocksCompleted;
  final int minutesActive;
  const SessionLog({
    required this.date,
    required this.blocksPlanned,
    required this.blocksCompleted,
    required this.minutesActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['blocks_planned'] = Variable<String>(blocksPlanned);
    map['blocks_completed'] = Variable<String>(blocksCompleted);
    map['minutes_active'] = Variable<int>(minutesActive);
    return map;
  }

  SessionLogsCompanion toCompanion(bool nullToAbsent) {
    return SessionLogsCompanion(
      date: Value(date),
      blocksPlanned: Value(blocksPlanned),
      blocksCompleted: Value(blocksCompleted),
      minutesActive: Value(minutesActive),
    );
  }

  factory SessionLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionLog(
      date: serializer.fromJson<String>(json['date']),
      blocksPlanned: serializer.fromJson<String>(json['blocksPlanned']),
      blocksCompleted: serializer.fromJson<String>(json['blocksCompleted']),
      minutesActive: serializer.fromJson<int>(json['minutesActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'blocksPlanned': serializer.toJson<String>(blocksPlanned),
      'blocksCompleted': serializer.toJson<String>(blocksCompleted),
      'minutesActive': serializer.toJson<int>(minutesActive),
    };
  }

  SessionLog copyWith({
    String? date,
    String? blocksPlanned,
    String? blocksCompleted,
    int? minutesActive,
  }) => SessionLog(
    date: date ?? this.date,
    blocksPlanned: blocksPlanned ?? this.blocksPlanned,
    blocksCompleted: blocksCompleted ?? this.blocksCompleted,
    minutesActive: minutesActive ?? this.minutesActive,
  );
  SessionLog copyWithCompanion(SessionLogsCompanion data) {
    return SessionLog(
      date: data.date.present ? data.date.value : this.date,
      blocksPlanned: data.blocksPlanned.present
          ? data.blocksPlanned.value
          : this.blocksPlanned,
      blocksCompleted: data.blocksCompleted.present
          ? data.blocksCompleted.value
          : this.blocksCompleted,
      minutesActive: data.minutesActive.present
          ? data.minutesActive.value
          : this.minutesActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionLog(')
          ..write('date: $date, ')
          ..write('blocksPlanned: $blocksPlanned, ')
          ..write('blocksCompleted: $blocksCompleted, ')
          ..write('minutesActive: $minutesActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(date, blocksPlanned, blocksCompleted, minutesActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionLog &&
          other.date == this.date &&
          other.blocksPlanned == this.blocksPlanned &&
          other.blocksCompleted == this.blocksCompleted &&
          other.minutesActive == this.minutesActive);
}

class SessionLogsCompanion extends UpdateCompanion<SessionLog> {
  final Value<String> date;
  final Value<String> blocksPlanned;
  final Value<String> blocksCompleted;
  final Value<int> minutesActive;
  final Value<int> rowid;
  const SessionLogsCompanion({
    this.date = const Value.absent(),
    this.blocksPlanned = const Value.absent(),
    this.blocksCompleted = const Value.absent(),
    this.minutesActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionLogsCompanion.insert({
    required String date,
    required String blocksPlanned,
    required String blocksCompleted,
    this.minutesActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       blocksPlanned = Value(blocksPlanned),
       blocksCompleted = Value(blocksCompleted);
  static Insertable<SessionLog> custom({
    Expression<String>? date,
    Expression<String>? blocksPlanned,
    Expression<String>? blocksCompleted,
    Expression<int>? minutesActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (blocksPlanned != null) 'blocks_planned': blocksPlanned,
      if (blocksCompleted != null) 'blocks_completed': blocksCompleted,
      if (minutesActive != null) 'minutes_active': minutesActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionLogsCompanion copyWith({
    Value<String>? date,
    Value<String>? blocksPlanned,
    Value<String>? blocksCompleted,
    Value<int>? minutesActive,
    Value<int>? rowid,
  }) {
    return SessionLogsCompanion(
      date: date ?? this.date,
      blocksPlanned: blocksPlanned ?? this.blocksPlanned,
      blocksCompleted: blocksCompleted ?? this.blocksCompleted,
      minutesActive: minutesActive ?? this.minutesActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (blocksPlanned.present) {
      map['blocks_planned'] = Variable<String>(blocksPlanned.value);
    }
    if (blocksCompleted.present) {
      map['blocks_completed'] = Variable<String>(blocksCompleted.value);
    }
    if (minutesActive.present) {
      map['minutes_active'] = Variable<int>(minutesActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionLogsCompanion(')
          ..write('date: $date, ')
          ..write('blocksPlanned: $blocksPlanned, ')
          ..write('blocksCompleted: $blocksCompleted, ')
          ..write('minutesActive: $minutesActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingSetsTable extends ReadingSets
    with TableInfo<$ReadingSetsTable, ReadingSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyFrMeta = const VerificationMeta('bodyFr');
  @override
  late final GeneratedColumn<String> bodyFr = GeneratedColumn<String>(
    'body_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionsMeta = const VerificationMeta(
    'questions',
  );
  @override
  late final GeneratedColumn<String> questions = GeneratedColumn<String>(
    'questions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('seed'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    kind,
    bodyFr,
    questions,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('body_fr')) {
      context.handle(
        _bodyFrMeta,
        bodyFr.isAcceptableOrUnknown(data['body_fr']!, _bodyFrMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyFrMeta);
    }
    if (data.containsKey('questions')) {
      context.handle(
        _questionsMeta,
        questions.isAcceptableOrUnknown(data['questions']!, _questionsMeta),
      );
    } else if (isInserting) {
      context.missing(_questionsMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      bodyFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_fr'],
      )!,
      questions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}questions'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $ReadingSetsTable createAlias(String alias) {
    return $ReadingSetsTable(attachedDatabase, alias);
  }
}

class ReadingSet extends DataClass implements Insertable<ReadingSet> {
  final int id;
  final String title;

  /// Passage genre: note_service, courriel, politique, article.
  final String kind;
  final String bodyFr;

  /// JSON list of {prompt, options[4], correctIndex, explanationFr}.
  final String questions;
  final String source;
  const ReadingSet({
    required this.id,
    required this.title,
    required this.kind,
    required this.bodyFr,
    required this.questions,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['kind'] = Variable<String>(kind);
    map['body_fr'] = Variable<String>(bodyFr);
    map['questions'] = Variable<String>(questions);
    map['source'] = Variable<String>(source);
    return map;
  }

  ReadingSetsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSetsCompanion(
      id: Value(id),
      title: Value(title),
      kind: Value(kind),
      bodyFr: Value(bodyFr),
      questions: Value(questions),
      source: Value(source),
    );
  }

  factory ReadingSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSet(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      kind: serializer.fromJson<String>(json['kind']),
      bodyFr: serializer.fromJson<String>(json['bodyFr']),
      questions: serializer.fromJson<String>(json['questions']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'kind': serializer.toJson<String>(kind),
      'bodyFr': serializer.toJson<String>(bodyFr),
      'questions': serializer.toJson<String>(questions),
      'source': serializer.toJson<String>(source),
    };
  }

  ReadingSet copyWith({
    int? id,
    String? title,
    String? kind,
    String? bodyFr,
    String? questions,
    String? source,
  }) => ReadingSet(
    id: id ?? this.id,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    bodyFr: bodyFr ?? this.bodyFr,
    questions: questions ?? this.questions,
    source: source ?? this.source,
  );
  ReadingSet copyWithCompanion(ReadingSetsCompanion data) {
    return ReadingSet(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      bodyFr: data.bodyFr.present ? data.bodyFr.value : this.bodyFr,
      questions: data.questions.present ? data.questions.value : this.questions,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSet(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('bodyFr: $bodyFr, ')
          ..write('questions: $questions, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, kind, bodyFr, questions, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSet &&
          other.id == this.id &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.bodyFr == this.bodyFr &&
          other.questions == this.questions &&
          other.source == this.source);
}

class ReadingSetsCompanion extends UpdateCompanion<ReadingSet> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> kind;
  final Value<String> bodyFr;
  final Value<String> questions;
  final Value<String> source;
  const ReadingSetsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.bodyFr = const Value.absent(),
    this.questions = const Value.absent(),
    this.source = const Value.absent(),
  });
  ReadingSetsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String kind,
    required String bodyFr,
    required String questions,
    this.source = const Value.absent(),
  }) : title = Value(title),
       kind = Value(kind),
       bodyFr = Value(bodyFr),
       questions = Value(questions);
  static Insertable<ReadingSet> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<String>? bodyFr,
    Expression<String>? questions,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (bodyFr != null) 'body_fr': bodyFr,
      if (questions != null) 'questions': questions,
      if (source != null) 'source': source,
    });
  }

  ReadingSetsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? kind,
    Value<String>? bodyFr,
    Value<String>? questions,
    Value<String>? source,
  }) {
    return ReadingSetsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      bodyFr: bodyFr ?? this.bodyFr,
      questions: questions ?? this.questions,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (bodyFr.present) {
      map['body_fr'] = Variable<String>(bodyFr.value);
    }
    if (questions.present) {
      map['questions'] = Variable<String>(questions.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSetsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('bodyFr: $bodyFr, ')
          ..write('questions: $questions, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $ReadingAttemptsTable extends ReadingAttempts
    with TableInfo<$ReadingAttemptsTable, ReadingAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<int> setId = GeneratedColumn<int>(
    'set_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    setId,
    correct,
    total,
    seconds,
    answeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('set_id')) {
      context.handle(
        _setIdMeta,
        setId.isAcceptableOrUnknown(data['set_id']!, _setIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      setId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_id'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}answered_at'],
      )!,
    );
  }

  @override
  $ReadingAttemptsTable createAlias(String alias) {
    return $ReadingAttemptsTable(attachedDatabase, alias);
  }
}

class ReadingAttempt extends DataClass implements Insertable<ReadingAttempt> {
  final int id;
  final int setId;
  final int correct;
  final int total;

  /// Reading + answering time, for the timed mode.
  final int seconds;
  final DateTime answeredAt;
  const ReadingAttempt({
    required this.id,
    required this.setId,
    required this.correct,
    required this.total,
    required this.seconds,
    required this.answeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['set_id'] = Variable<int>(setId);
    map['correct'] = Variable<int>(correct);
    map['total'] = Variable<int>(total);
    map['seconds'] = Variable<int>(seconds);
    map['answered_at'] = Variable<DateTime>(answeredAt);
    return map;
  }

  ReadingAttemptsCompanion toCompanion(bool nullToAbsent) {
    return ReadingAttemptsCompanion(
      id: Value(id),
      setId: Value(setId),
      correct: Value(correct),
      total: Value(total),
      seconds: Value(seconds),
      answeredAt: Value(answeredAt),
    );
  }

  factory ReadingAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingAttempt(
      id: serializer.fromJson<int>(json['id']),
      setId: serializer.fromJson<int>(json['setId']),
      correct: serializer.fromJson<int>(json['correct']),
      total: serializer.fromJson<int>(json['total']),
      seconds: serializer.fromJson<int>(json['seconds']),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'setId': serializer.toJson<int>(setId),
      'correct': serializer.toJson<int>(correct),
      'total': serializer.toJson<int>(total),
      'seconds': serializer.toJson<int>(seconds),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
    };
  }

  ReadingAttempt copyWith({
    int? id,
    int? setId,
    int? correct,
    int? total,
    int? seconds,
    DateTime? answeredAt,
  }) => ReadingAttempt(
    id: id ?? this.id,
    setId: setId ?? this.setId,
    correct: correct ?? this.correct,
    total: total ?? this.total,
    seconds: seconds ?? this.seconds,
    answeredAt: answeredAt ?? this.answeredAt,
  );
  ReadingAttempt copyWithCompanion(ReadingAttemptsCompanion data) {
    return ReadingAttempt(
      id: data.id.present ? data.id.value : this.id,
      setId: data.setId.present ? data.setId.value : this.setId,
      correct: data.correct.present ? data.correct.value : this.correct,
      total: data.total.present ? data.total.value : this.total,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingAttempt(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('correct: $correct, ')
          ..write('total: $total, ')
          ..write('seconds: $seconds, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, setId, correct, total, seconds, answeredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingAttempt &&
          other.id == this.id &&
          other.setId == this.setId &&
          other.correct == this.correct &&
          other.total == this.total &&
          other.seconds == this.seconds &&
          other.answeredAt == this.answeredAt);
}

class ReadingAttemptsCompanion extends UpdateCompanion<ReadingAttempt> {
  final Value<int> id;
  final Value<int> setId;
  final Value<int> correct;
  final Value<int> total;
  final Value<int> seconds;
  final Value<DateTime> answeredAt;
  const ReadingAttemptsCompanion({
    this.id = const Value.absent(),
    this.setId = const Value.absent(),
    this.correct = const Value.absent(),
    this.total = const Value.absent(),
    this.seconds = const Value.absent(),
    this.answeredAt = const Value.absent(),
  });
  ReadingAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required int setId,
    required int correct,
    required int total,
    required int seconds,
    required DateTime answeredAt,
  }) : setId = Value(setId),
       correct = Value(correct),
       total = Value(total),
       seconds = Value(seconds),
       answeredAt = Value(answeredAt);
  static Insertable<ReadingAttempt> custom({
    Expression<int>? id,
    Expression<int>? setId,
    Expression<int>? correct,
    Expression<int>? total,
    Expression<int>? seconds,
    Expression<DateTime>? answeredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setId != null) 'set_id': setId,
      if (correct != null) 'correct': correct,
      if (total != null) 'total': total,
      if (seconds != null) 'seconds': seconds,
      if (answeredAt != null) 'answered_at': answeredAt,
    });
  }

  ReadingAttemptsCompanion copyWith({
    Value<int>? id,
    Value<int>? setId,
    Value<int>? correct,
    Value<int>? total,
    Value<int>? seconds,
    Value<DateTime>? answeredAt,
  }) {
    return ReadingAttemptsCompanion(
      id: id ?? this.id,
      setId: setId ?? this.setId,
      correct: correct ?? this.correct,
      total: total ?? this.total,
      seconds: seconds ?? this.seconds,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (setId.present) {
      map['set_id'] = Variable<int>(setId.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('correct: $correct, ')
          ..write('total: $total, ')
          ..write('seconds: $seconds, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }
}

class $WritingAttemptsTable extends WritingAttempts
    with TableInfo<$WritingAttemptsTable, WritingAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WritingAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _promptFrMeta = const VerificationMeta(
    'promptFr',
  );
  @override
  late final GeneratedColumn<String> promptFr = GeneratedColumn<String>(
    'prompt_fr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userTextMeta = const VerificationMeta(
    'userText',
  );
  @override
  late final GeneratedColumn<String> userText = GeneratedColumn<String>(
    'user_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedbackMeta = const VerificationMeta(
    'feedback',
  );
  @override
  late final GeneratedColumn<String> feedback = GeneratedColumn<String>(
    'feedback',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    promptFr,
    userText,
    feedback,
    answeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'writing_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<WritingAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prompt_fr')) {
      context.handle(
        _promptFrMeta,
        promptFr.isAcceptableOrUnknown(data['prompt_fr']!, _promptFrMeta),
      );
    } else if (isInserting) {
      context.missing(_promptFrMeta);
    }
    if (data.containsKey('user_text')) {
      context.handle(
        _userTextMeta,
        userText.isAcceptableOrUnknown(data['user_text']!, _userTextMeta),
      );
    } else if (isInserting) {
      context.missing(_userTextMeta);
    }
    if (data.containsKey('feedback')) {
      context.handle(
        _feedbackMeta,
        feedback.isAcceptableOrUnknown(data['feedback']!, _feedbackMeta),
      );
    } else if (isInserting) {
      context.missing(_feedbackMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WritingAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WritingAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      promptFr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_fr'],
      )!,
      userText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_text'],
      )!,
      feedback: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feedback'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}answered_at'],
      )!,
    );
  }

  @override
  $WritingAttemptsTable createAlias(String alias) {
    return $WritingAttemptsTable(attachedDatabase, alias);
  }
}

class WritingAttempt extends DataClass implements Insertable<WritingAttempt> {
  final int id;
  final String promptFr;
  final String userText;

  /// JSON feedback from the writing coach (corrections, level, tips).
  final String feedback;
  final DateTime answeredAt;
  const WritingAttempt({
    required this.id,
    required this.promptFr,
    required this.userText,
    required this.feedback,
    required this.answeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prompt_fr'] = Variable<String>(promptFr);
    map['user_text'] = Variable<String>(userText);
    map['feedback'] = Variable<String>(feedback);
    map['answered_at'] = Variable<DateTime>(answeredAt);
    return map;
  }

  WritingAttemptsCompanion toCompanion(bool nullToAbsent) {
    return WritingAttemptsCompanion(
      id: Value(id),
      promptFr: Value(promptFr),
      userText: Value(userText),
      feedback: Value(feedback),
      answeredAt: Value(answeredAt),
    );
  }

  factory WritingAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WritingAttempt(
      id: serializer.fromJson<int>(json['id']),
      promptFr: serializer.fromJson<String>(json['promptFr']),
      userText: serializer.fromJson<String>(json['userText']),
      feedback: serializer.fromJson<String>(json['feedback']),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'promptFr': serializer.toJson<String>(promptFr),
      'userText': serializer.toJson<String>(userText),
      'feedback': serializer.toJson<String>(feedback),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
    };
  }

  WritingAttempt copyWith({
    int? id,
    String? promptFr,
    String? userText,
    String? feedback,
    DateTime? answeredAt,
  }) => WritingAttempt(
    id: id ?? this.id,
    promptFr: promptFr ?? this.promptFr,
    userText: userText ?? this.userText,
    feedback: feedback ?? this.feedback,
    answeredAt: answeredAt ?? this.answeredAt,
  );
  WritingAttempt copyWithCompanion(WritingAttemptsCompanion data) {
    return WritingAttempt(
      id: data.id.present ? data.id.value : this.id,
      promptFr: data.promptFr.present ? data.promptFr.value : this.promptFr,
      userText: data.userText.present ? data.userText.value : this.userText,
      feedback: data.feedback.present ? data.feedback.value : this.feedback,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WritingAttempt(')
          ..write('id: $id, ')
          ..write('promptFr: $promptFr, ')
          ..write('userText: $userText, ')
          ..write('feedback: $feedback, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, promptFr, userText, feedback, answeredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WritingAttempt &&
          other.id == this.id &&
          other.promptFr == this.promptFr &&
          other.userText == this.userText &&
          other.feedback == this.feedback &&
          other.answeredAt == this.answeredAt);
}

class WritingAttemptsCompanion extends UpdateCompanion<WritingAttempt> {
  final Value<int> id;
  final Value<String> promptFr;
  final Value<String> userText;
  final Value<String> feedback;
  final Value<DateTime> answeredAt;
  const WritingAttemptsCompanion({
    this.id = const Value.absent(),
    this.promptFr = const Value.absent(),
    this.userText = const Value.absent(),
    this.feedback = const Value.absent(),
    this.answeredAt = const Value.absent(),
  });
  WritingAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String promptFr,
    required String userText,
    required String feedback,
    required DateTime answeredAt,
  }) : promptFr = Value(promptFr),
       userText = Value(userText),
       feedback = Value(feedback),
       answeredAt = Value(answeredAt);
  static Insertable<WritingAttempt> custom({
    Expression<int>? id,
    Expression<String>? promptFr,
    Expression<String>? userText,
    Expression<String>? feedback,
    Expression<DateTime>? answeredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (promptFr != null) 'prompt_fr': promptFr,
      if (userText != null) 'user_text': userText,
      if (feedback != null) 'feedback': feedback,
      if (answeredAt != null) 'answered_at': answeredAt,
    });
  }

  WritingAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? promptFr,
    Value<String>? userText,
    Value<String>? feedback,
    Value<DateTime>? answeredAt,
  }) {
    return WritingAttemptsCompanion(
      id: id ?? this.id,
      promptFr: promptFr ?? this.promptFr,
      userText: userText ?? this.userText,
      feedback: feedback ?? this.feedback,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (promptFr.present) {
      map['prompt_fr'] = Variable<String>(promptFr.value);
    }
    if (userText.present) {
      map['user_text'] = Variable<String>(userText.value);
    }
    if (feedback.present) {
      map['feedback'] = Variable<String>(feedback.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WritingAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('promptFr: $promptFr, ')
          ..write('userText: $userText, ')
          ..write('feedback: $feedback, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VocabCardsTable vocabCards = $VocabCardsTable(this);
  late final $ReviewStatesTable reviewStates = $ReviewStatesTable(this);
  late final $DrillItemsTable drillItems = $DrillItemsTable(this);
  late final $DrillAttemptsTable drillAttempts = $DrillAttemptsTable(this);
  late final $CurriculumWeeksTable curriculumWeeks = $CurriculumWeeksTable(
    this,
  );
  late final $SessionLogsTable sessionLogs = $SessionLogsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $ReadingSetsTable readingSets = $ReadingSetsTable(this);
  late final $ReadingAttemptsTable readingAttempts = $ReadingAttemptsTable(
    this,
  );
  late final $WritingAttemptsTable writingAttempts = $WritingAttemptsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vocabCards,
    reviewStates,
    drillItems,
    drillAttempts,
    curriculumWeeks,
    sessionLogs,
    appSettings,
    readingSets,
    readingAttempts,
    writingAttempts,
  ];
}

typedef $$VocabCardsTableCreateCompanionBuilder =
    VocabCardsCompanion Function({
      Value<int> id,
      required String front,
      required String back,
      required String exampleFr,
      required String domain,
      Value<DateTime> createdAt,
    });
typedef $$VocabCardsTableUpdateCompanionBuilder =
    VocabCardsCompanion Function({
      Value<int> id,
      Value<String> front,
      Value<String> back,
      Value<String> exampleFr,
      Value<String> domain,
      Value<DateTime> createdAt,
    });

class $$VocabCardsTableFilterComposer
    extends Composer<_$AppDatabase, $VocabCardsTable> {
  $$VocabCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleFr => $composableBuilder(
    column: $table.exampleFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VocabCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabCardsTable> {
  $$VocabCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleFr => $composableBuilder(
    column: $table.exampleFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VocabCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabCardsTable> {
  $$VocabCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<String> get exampleFr =>
      $composableBuilder(column: $table.exampleFr, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VocabCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabCardsTable,
          VocabCard,
          $$VocabCardsTableFilterComposer,
          $$VocabCardsTableOrderingComposer,
          $$VocabCardsTableAnnotationComposer,
          $$VocabCardsTableCreateCompanionBuilder,
          $$VocabCardsTableUpdateCompanionBuilder,
          (
            VocabCard,
            BaseReferences<_$AppDatabase, $VocabCardsTable, VocabCard>,
          ),
          VocabCard,
          PrefetchHooks Function()
        > {
  $$VocabCardsTableTableManager(_$AppDatabase db, $VocabCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> front = const Value.absent(),
                Value<String> back = const Value.absent(),
                Value<String> exampleFr = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => VocabCardsCompanion(
                id: id,
                front: front,
                back: back,
                exampleFr: exampleFr,
                domain: domain,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String front,
                required String back,
                required String exampleFr,
                required String domain,
                Value<DateTime> createdAt = const Value.absent(),
              }) => VocabCardsCompanion.insert(
                id: id,
                front: front,
                back: back,
                exampleFr: exampleFr,
                domain: domain,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VocabCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabCardsTable,
      VocabCard,
      $$VocabCardsTableFilterComposer,
      $$VocabCardsTableOrderingComposer,
      $$VocabCardsTableAnnotationComposer,
      $$VocabCardsTableCreateCompanionBuilder,
      $$VocabCardsTableUpdateCompanionBuilder,
      (VocabCard, BaseReferences<_$AppDatabase, $VocabCardsTable, VocabCard>),
      VocabCard,
      PrefetchHooks Function()
    >;
typedef $$ReviewStatesTableCreateCompanionBuilder =
    ReviewStatesCompanion Function({
      Value<int> cardId,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<int> lapses,
      required DateTime dueDate,
    });
typedef $$ReviewStatesTableUpdateCompanionBuilder =
    ReviewStatesCompanion Function({
      Value<int> cardId,
      Value<double> easeFactor,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<int> lapses,
      Value<DateTime> dueDate,
    });

class $$ReviewStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewStatesTable> {
  $$ReviewStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewStatesTable> {
  $$ReviewStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewStatesTable> {
  $$ReviewStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);
}

class $$ReviewStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewStatesTable,
          ReviewState,
          $$ReviewStatesTableFilterComposer,
          $$ReviewStatesTableOrderingComposer,
          $$ReviewStatesTableAnnotationComposer,
          $$ReviewStatesTableCreateCompanionBuilder,
          $$ReviewStatesTableUpdateCompanionBuilder,
          (
            ReviewState,
            BaseReferences<_$AppDatabase, $ReviewStatesTable, ReviewState>,
          ),
          ReviewState,
          PrefetchHooks Function()
        > {
  $$ReviewStatesTableTableManager(_$AppDatabase db, $ReviewStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> cardId = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
              }) => ReviewStatesCompanion(
                cardId: cardId,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                lapses: lapses,
                dueDate: dueDate,
              ),
          createCompanionCallback:
              ({
                Value<int> cardId = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                required DateTime dueDate,
              }) => ReviewStatesCompanion.insert(
                cardId: cardId,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                repetitions: repetitions,
                lapses: lapses,
                dueDate: dueDate,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewStatesTable,
      ReviewState,
      $$ReviewStatesTableFilterComposer,
      $$ReviewStatesTableOrderingComposer,
      $$ReviewStatesTableAnnotationComposer,
      $$ReviewStatesTableCreateCompanionBuilder,
      $$ReviewStatesTableUpdateCompanionBuilder,
      (
        ReviewState,
        BaseReferences<_$AppDatabase, $ReviewStatesTable, ReviewState>,
      ),
      ReviewState,
      PrefetchHooks Function()
    >;
typedef $$DrillItemsTableCreateCompanionBuilder =
    DrillItemsCompanion Function({
      Value<int> id,
      required String topic,
      required String prompt,
      required String options,
      required int correctIndex,
      required String explanationFr,
      Value<String> source,
    });
typedef $$DrillItemsTableUpdateCompanionBuilder =
    DrillItemsCompanion Function({
      Value<int> id,
      Value<String> topic,
      Value<String> prompt,
      Value<String> options,
      Value<int> correctIndex,
      Value<String> explanationFr,
      Value<String> source,
    });

class $$DrillItemsTableFilterComposer
    extends Composer<_$AppDatabase, $DrillItemsTable> {
  $$DrillItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctIndex => $composableBuilder(
    column: $table.correctIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanationFr => $composableBuilder(
    column: $table.explanationFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DrillItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $DrillItemsTable> {
  $$DrillItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get options => $composableBuilder(
    column: $table.options,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctIndex => $composableBuilder(
    column: $table.correctIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanationFr => $composableBuilder(
    column: $table.explanationFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DrillItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DrillItemsTable> {
  $$DrillItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<int> get correctIndex => $composableBuilder(
    column: $table.correctIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanationFr => $composableBuilder(
    column: $table.explanationFr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$DrillItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DrillItemsTable,
          DrillItem,
          $$DrillItemsTableFilterComposer,
          $$DrillItemsTableOrderingComposer,
          $$DrillItemsTableAnnotationComposer,
          $$DrillItemsTableCreateCompanionBuilder,
          $$DrillItemsTableUpdateCompanionBuilder,
          (
            DrillItem,
            BaseReferences<_$AppDatabase, $DrillItemsTable, DrillItem>,
          ),
          DrillItem,
          PrefetchHooks Function()
        > {
  $$DrillItemsTableTableManager(_$AppDatabase db, $DrillItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrillItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrillItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrillItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> options = const Value.absent(),
                Value<int> correctIndex = const Value.absent(),
                Value<String> explanationFr = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => DrillItemsCompanion(
                id: id,
                topic: topic,
                prompt: prompt,
                options: options,
                correctIndex: correctIndex,
                explanationFr: explanationFr,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String topic,
                required String prompt,
                required String options,
                required int correctIndex,
                required String explanationFr,
                Value<String> source = const Value.absent(),
              }) => DrillItemsCompanion.insert(
                id: id,
                topic: topic,
                prompt: prompt,
                options: options,
                correctIndex: correctIndex,
                explanationFr: explanationFr,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DrillItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DrillItemsTable,
      DrillItem,
      $$DrillItemsTableFilterComposer,
      $$DrillItemsTableOrderingComposer,
      $$DrillItemsTableAnnotationComposer,
      $$DrillItemsTableCreateCompanionBuilder,
      $$DrillItemsTableUpdateCompanionBuilder,
      (DrillItem, BaseReferences<_$AppDatabase, $DrillItemsTable, DrillItem>),
      DrillItem,
      PrefetchHooks Function()
    >;
typedef $$DrillAttemptsTableCreateCompanionBuilder =
    DrillAttemptsCompanion Function({
      Value<int> id,
      required int itemId,
      required bool wasCorrect,
      required DateTime answeredAt,
    });
typedef $$DrillAttemptsTableUpdateCompanionBuilder =
    DrillAttemptsCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<bool> wasCorrect,
      Value<DateTime> answeredAt,
    });

class $$DrillAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $DrillAttemptsTable> {
  $$DrillAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DrillAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $DrillAttemptsTable> {
  $$DrillAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DrillAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DrillAttemptsTable> {
  $$DrillAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<bool> get wasCorrect => $composableBuilder(
    column: $table.wasCorrect,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );
}

class $$DrillAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DrillAttemptsTable,
          DrillAttempt,
          $$DrillAttemptsTableFilterComposer,
          $$DrillAttemptsTableOrderingComposer,
          $$DrillAttemptsTableAnnotationComposer,
          $$DrillAttemptsTableCreateCompanionBuilder,
          $$DrillAttemptsTableUpdateCompanionBuilder,
          (
            DrillAttempt,
            BaseReferences<_$AppDatabase, $DrillAttemptsTable, DrillAttempt>,
          ),
          DrillAttempt,
          PrefetchHooks Function()
        > {
  $$DrillAttemptsTableTableManager(_$AppDatabase db, $DrillAttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrillAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrillAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrillAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<bool> wasCorrect = const Value.absent(),
                Value<DateTime> answeredAt = const Value.absent(),
              }) => DrillAttemptsCompanion(
                id: id,
                itemId: itemId,
                wasCorrect: wasCorrect,
                answeredAt: answeredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required bool wasCorrect,
                required DateTime answeredAt,
              }) => DrillAttemptsCompanion.insert(
                id: id,
                itemId: itemId,
                wasCorrect: wasCorrect,
                answeredAt: answeredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DrillAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DrillAttemptsTable,
      DrillAttempt,
      $$DrillAttemptsTableFilterComposer,
      $$DrillAttemptsTableOrderingComposer,
      $$DrillAttemptsTableAnnotationComposer,
      $$DrillAttemptsTableCreateCompanionBuilder,
      $$DrillAttemptsTableUpdateCompanionBuilder,
      (
        DrillAttempt,
        BaseReferences<_$AppDatabase, $DrillAttemptsTable, DrillAttempt>,
      ),
      DrillAttempt,
      PrefetchHooks Function()
    >;
typedef $$CurriculumWeeksTableCreateCompanionBuilder =
    CurriculumWeeksCompanion Function({
      Value<int> weekNumber,
      required String themeFr,
      required String themeEn,
      required String grammarTopics,
      required String vocabDomain,
      required String resourceSlots,
    });
typedef $$CurriculumWeeksTableUpdateCompanionBuilder =
    CurriculumWeeksCompanion Function({
      Value<int> weekNumber,
      Value<String> themeFr,
      Value<String> themeEn,
      Value<String> grammarTopics,
      Value<String> vocabDomain,
      Value<String> resourceSlots,
    });

class $$CurriculumWeeksTableFilterComposer
    extends Composer<_$AppDatabase, $CurriculumWeeksTable> {
  $$CurriculumWeeksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get weekNumber => $composableBuilder(
    column: $table.weekNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeFr => $composableBuilder(
    column: $table.themeFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeEn => $composableBuilder(
    column: $table.themeEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grammarTopics => $composableBuilder(
    column: $table.grammarTopics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vocabDomain => $composableBuilder(
    column: $table.vocabDomain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceSlots => $composableBuilder(
    column: $table.resourceSlots,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CurriculumWeeksTableOrderingComposer
    extends Composer<_$AppDatabase, $CurriculumWeeksTable> {
  $$CurriculumWeeksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get weekNumber => $composableBuilder(
    column: $table.weekNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeFr => $composableBuilder(
    column: $table.themeFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeEn => $composableBuilder(
    column: $table.themeEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grammarTopics => $composableBuilder(
    column: $table.grammarTopics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vocabDomain => $composableBuilder(
    column: $table.vocabDomain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceSlots => $composableBuilder(
    column: $table.resourceSlots,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CurriculumWeeksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CurriculumWeeksTable> {
  $$CurriculumWeeksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get weekNumber => $composableBuilder(
    column: $table.weekNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeFr =>
      $composableBuilder(column: $table.themeFr, builder: (column) => column);

  GeneratedColumn<String> get themeEn =>
      $composableBuilder(column: $table.themeEn, builder: (column) => column);

  GeneratedColumn<String> get grammarTopics => $composableBuilder(
    column: $table.grammarTopics,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vocabDomain => $composableBuilder(
    column: $table.vocabDomain,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resourceSlots => $composableBuilder(
    column: $table.resourceSlots,
    builder: (column) => column,
  );
}

class $$CurriculumWeeksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CurriculumWeeksTable,
          CurriculumWeek,
          $$CurriculumWeeksTableFilterComposer,
          $$CurriculumWeeksTableOrderingComposer,
          $$CurriculumWeeksTableAnnotationComposer,
          $$CurriculumWeeksTableCreateCompanionBuilder,
          $$CurriculumWeeksTableUpdateCompanionBuilder,
          (
            CurriculumWeek,
            BaseReferences<
              _$AppDatabase,
              $CurriculumWeeksTable,
              CurriculumWeek
            >,
          ),
          CurriculumWeek,
          PrefetchHooks Function()
        > {
  $$CurriculumWeeksTableTableManager(
    _$AppDatabase db,
    $CurriculumWeeksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurriculumWeeksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurriculumWeeksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CurriculumWeeksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> weekNumber = const Value.absent(),
                Value<String> themeFr = const Value.absent(),
                Value<String> themeEn = const Value.absent(),
                Value<String> grammarTopics = const Value.absent(),
                Value<String> vocabDomain = const Value.absent(),
                Value<String> resourceSlots = const Value.absent(),
              }) => CurriculumWeeksCompanion(
                weekNumber: weekNumber,
                themeFr: themeFr,
                themeEn: themeEn,
                grammarTopics: grammarTopics,
                vocabDomain: vocabDomain,
                resourceSlots: resourceSlots,
              ),
          createCompanionCallback:
              ({
                Value<int> weekNumber = const Value.absent(),
                required String themeFr,
                required String themeEn,
                required String grammarTopics,
                required String vocabDomain,
                required String resourceSlots,
              }) => CurriculumWeeksCompanion.insert(
                weekNumber: weekNumber,
                themeFr: themeFr,
                themeEn: themeEn,
                grammarTopics: grammarTopics,
                vocabDomain: vocabDomain,
                resourceSlots: resourceSlots,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CurriculumWeeksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CurriculumWeeksTable,
      CurriculumWeek,
      $$CurriculumWeeksTableFilterComposer,
      $$CurriculumWeeksTableOrderingComposer,
      $$CurriculumWeeksTableAnnotationComposer,
      $$CurriculumWeeksTableCreateCompanionBuilder,
      $$CurriculumWeeksTableUpdateCompanionBuilder,
      (
        CurriculumWeek,
        BaseReferences<_$AppDatabase, $CurriculumWeeksTable, CurriculumWeek>,
      ),
      CurriculumWeek,
      PrefetchHooks Function()
    >;
typedef $$SessionLogsTableCreateCompanionBuilder =
    SessionLogsCompanion Function({
      required String date,
      required String blocksPlanned,
      required String blocksCompleted,
      Value<int> minutesActive,
      Value<int> rowid,
    });
typedef $$SessionLogsTableUpdateCompanionBuilder =
    SessionLogsCompanion Function({
      Value<String> date,
      Value<String> blocksPlanned,
      Value<String> blocksCompleted,
      Value<int> minutesActive,
      Value<int> rowid,
    });

class $$SessionLogsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionLogsTable> {
  $$SessionLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blocksPlanned => $composableBuilder(
    column: $table.blocksPlanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blocksCompleted => $composableBuilder(
    column: $table.blocksCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutesActive => $composableBuilder(
    column: $table.minutesActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionLogsTable> {
  $$SessionLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blocksPlanned => $composableBuilder(
    column: $table.blocksPlanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blocksCompleted => $composableBuilder(
    column: $table.blocksCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesActive => $composableBuilder(
    column: $table.minutesActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionLogsTable> {
  $$SessionLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get blocksPlanned => $composableBuilder(
    column: $table.blocksPlanned,
    builder: (column) => column,
  );

  GeneratedColumn<String> get blocksCompleted => $composableBuilder(
    column: $table.blocksCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minutesActive => $composableBuilder(
    column: $table.minutesActive,
    builder: (column) => column,
  );
}

class $$SessionLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionLogsTable,
          SessionLog,
          $$SessionLogsTableFilterComposer,
          $$SessionLogsTableOrderingComposer,
          $$SessionLogsTableAnnotationComposer,
          $$SessionLogsTableCreateCompanionBuilder,
          $$SessionLogsTableUpdateCompanionBuilder,
          (
            SessionLog,
            BaseReferences<_$AppDatabase, $SessionLogsTable, SessionLog>,
          ),
          SessionLog,
          PrefetchHooks Function()
        > {
  $$SessionLogsTableTableManager(_$AppDatabase db, $SessionLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> blocksPlanned = const Value.absent(),
                Value<String> blocksCompleted = const Value.absent(),
                Value<int> minutesActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionLogsCompanion(
                date: date,
                blocksPlanned: blocksPlanned,
                blocksCompleted: blocksCompleted,
                minutesActive: minutesActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String blocksPlanned,
                required String blocksCompleted,
                Value<int> minutesActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionLogsCompanion.insert(
                date: date,
                blocksPlanned: blocksPlanned,
                blocksCompleted: blocksCompleted,
                minutesActive: minutesActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionLogsTable,
      SessionLog,
      $$SessionLogsTableFilterComposer,
      $$SessionLogsTableOrderingComposer,
      $$SessionLogsTableAnnotationComposer,
      $$SessionLogsTableCreateCompanionBuilder,
      $$SessionLogsTableUpdateCompanionBuilder,
      (
        SessionLog,
        BaseReferences<_$AppDatabase, $SessionLogsTable, SessionLog>,
      ),
      SessionLog,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$ReadingSetsTableCreateCompanionBuilder =
    ReadingSetsCompanion Function({
      Value<int> id,
      required String title,
      required String kind,
      required String bodyFr,
      required String questions,
      Value<String> source,
    });
typedef $$ReadingSetsTableUpdateCompanionBuilder =
    ReadingSetsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> kind,
      Value<String> bodyFr,
      Value<String> questions,
      Value<String> source,
    });

class $$ReadingSetsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingSetsTable> {
  $$ReadingSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyFr => $composableBuilder(
    column: $table.bodyFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questions => $composableBuilder(
    column: $table.questions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingSetsTable> {
  $$ReadingSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyFr => $composableBuilder(
    column: $table.bodyFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questions => $composableBuilder(
    column: $table.questions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingSetsTable> {
  $$ReadingSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get bodyFr =>
      $composableBuilder(column: $table.bodyFr, builder: (column) => column);

  GeneratedColumn<String> get questions =>
      $composableBuilder(column: $table.questions, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$ReadingSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingSetsTable,
          ReadingSet,
          $$ReadingSetsTableFilterComposer,
          $$ReadingSetsTableOrderingComposer,
          $$ReadingSetsTableAnnotationComposer,
          $$ReadingSetsTableCreateCompanionBuilder,
          $$ReadingSetsTableUpdateCompanionBuilder,
          (
            ReadingSet,
            BaseReferences<_$AppDatabase, $ReadingSetsTable, ReadingSet>,
          ),
          ReadingSet,
          PrefetchHooks Function()
        > {
  $$ReadingSetsTableTableManager(_$AppDatabase db, $ReadingSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> bodyFr = const Value.absent(),
                Value<String> questions = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => ReadingSetsCompanion(
                id: id,
                title: title,
                kind: kind,
                bodyFr: bodyFr,
                questions: questions,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String kind,
                required String bodyFr,
                required String questions,
                Value<String> source = const Value.absent(),
              }) => ReadingSetsCompanion.insert(
                id: id,
                title: title,
                kind: kind,
                bodyFr: bodyFr,
                questions: questions,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingSetsTable,
      ReadingSet,
      $$ReadingSetsTableFilterComposer,
      $$ReadingSetsTableOrderingComposer,
      $$ReadingSetsTableAnnotationComposer,
      $$ReadingSetsTableCreateCompanionBuilder,
      $$ReadingSetsTableUpdateCompanionBuilder,
      (
        ReadingSet,
        BaseReferences<_$AppDatabase, $ReadingSetsTable, ReadingSet>,
      ),
      ReadingSet,
      PrefetchHooks Function()
    >;
typedef $$ReadingAttemptsTableCreateCompanionBuilder =
    ReadingAttemptsCompanion Function({
      Value<int> id,
      required int setId,
      required int correct,
      required int total,
      required int seconds,
      required DateTime answeredAt,
    });
typedef $$ReadingAttemptsTableUpdateCompanionBuilder =
    ReadingAttemptsCompanion Function({
      Value<int> id,
      Value<int> setId,
      Value<int> correct,
      Value<int> total,
      Value<int> seconds,
      Value<DateTime> answeredAt,
    });

class $$ReadingAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingAttemptsTable> {
  $$ReadingAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setId => $composableBuilder(
    column: $table.setId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingAttemptsTable> {
  $$ReadingAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setId => $composableBuilder(
    column: $table.setId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingAttemptsTable> {
  $$ReadingAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get setId =>
      $composableBuilder(column: $table.setId, builder: (column) => column);

  GeneratedColumn<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );
}

class $$ReadingAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingAttemptsTable,
          ReadingAttempt,
          $$ReadingAttemptsTableFilterComposer,
          $$ReadingAttemptsTableOrderingComposer,
          $$ReadingAttemptsTableAnnotationComposer,
          $$ReadingAttemptsTableCreateCompanionBuilder,
          $$ReadingAttemptsTableUpdateCompanionBuilder,
          (
            ReadingAttempt,
            BaseReferences<
              _$AppDatabase,
              $ReadingAttemptsTable,
              ReadingAttempt
            >,
          ),
          ReadingAttempt,
          PrefetchHooks Function()
        > {
  $$ReadingAttemptsTableTableManager(
    _$AppDatabase db,
    $ReadingAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> setId = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<DateTime> answeredAt = const Value.absent(),
              }) => ReadingAttemptsCompanion(
                id: id,
                setId: setId,
                correct: correct,
                total: total,
                seconds: seconds,
                answeredAt: answeredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int setId,
                required int correct,
                required int total,
                required int seconds,
                required DateTime answeredAt,
              }) => ReadingAttemptsCompanion.insert(
                id: id,
                setId: setId,
                correct: correct,
                total: total,
                seconds: seconds,
                answeredAt: answeredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingAttemptsTable,
      ReadingAttempt,
      $$ReadingAttemptsTableFilterComposer,
      $$ReadingAttemptsTableOrderingComposer,
      $$ReadingAttemptsTableAnnotationComposer,
      $$ReadingAttemptsTableCreateCompanionBuilder,
      $$ReadingAttemptsTableUpdateCompanionBuilder,
      (
        ReadingAttempt,
        BaseReferences<_$AppDatabase, $ReadingAttemptsTable, ReadingAttempt>,
      ),
      ReadingAttempt,
      PrefetchHooks Function()
    >;
typedef $$WritingAttemptsTableCreateCompanionBuilder =
    WritingAttemptsCompanion Function({
      Value<int> id,
      required String promptFr,
      required String userText,
      required String feedback,
      required DateTime answeredAt,
    });
typedef $$WritingAttemptsTableUpdateCompanionBuilder =
    WritingAttemptsCompanion Function({
      Value<int> id,
      Value<String> promptFr,
      Value<String> userText,
      Value<String> feedback,
      Value<DateTime> answeredAt,
    });

class $$WritingAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $WritingAttemptsTable> {
  $$WritingAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptFr => $composableBuilder(
    column: $table.promptFr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userText => $composableBuilder(
    column: $table.userText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedback => $composableBuilder(
    column: $table.feedback,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WritingAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $WritingAttemptsTable> {
  $$WritingAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptFr => $composableBuilder(
    column: $table.promptFr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userText => $composableBuilder(
    column: $table.userText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedback => $composableBuilder(
    column: $table.feedback,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WritingAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WritingAttemptsTable> {
  $$WritingAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get promptFr =>
      $composableBuilder(column: $table.promptFr, builder: (column) => column);

  GeneratedColumn<String> get userText =>
      $composableBuilder(column: $table.userText, builder: (column) => column);

  GeneratedColumn<String> get feedback =>
      $composableBuilder(column: $table.feedback, builder: (column) => column);

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );
}

class $$WritingAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WritingAttemptsTable,
          WritingAttempt,
          $$WritingAttemptsTableFilterComposer,
          $$WritingAttemptsTableOrderingComposer,
          $$WritingAttemptsTableAnnotationComposer,
          $$WritingAttemptsTableCreateCompanionBuilder,
          $$WritingAttemptsTableUpdateCompanionBuilder,
          (
            WritingAttempt,
            BaseReferences<
              _$AppDatabase,
              $WritingAttemptsTable,
              WritingAttempt
            >,
          ),
          WritingAttempt,
          PrefetchHooks Function()
        > {
  $$WritingAttemptsTableTableManager(
    _$AppDatabase db,
    $WritingAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WritingAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WritingAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WritingAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> promptFr = const Value.absent(),
                Value<String> userText = const Value.absent(),
                Value<String> feedback = const Value.absent(),
                Value<DateTime> answeredAt = const Value.absent(),
              }) => WritingAttemptsCompanion(
                id: id,
                promptFr: promptFr,
                userText: userText,
                feedback: feedback,
                answeredAt: answeredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String promptFr,
                required String userText,
                required String feedback,
                required DateTime answeredAt,
              }) => WritingAttemptsCompanion.insert(
                id: id,
                promptFr: promptFr,
                userText: userText,
                feedback: feedback,
                answeredAt: answeredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WritingAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WritingAttemptsTable,
      WritingAttempt,
      $$WritingAttemptsTableFilterComposer,
      $$WritingAttemptsTableOrderingComposer,
      $$WritingAttemptsTableAnnotationComposer,
      $$WritingAttemptsTableCreateCompanionBuilder,
      $$WritingAttemptsTableUpdateCompanionBuilder,
      (
        WritingAttempt,
        BaseReferences<_$AppDatabase, $WritingAttemptsTable, WritingAttempt>,
      ),
      WritingAttempt,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VocabCardsTableTableManager get vocabCards =>
      $$VocabCardsTableTableManager(_db, _db.vocabCards);
  $$ReviewStatesTableTableManager get reviewStates =>
      $$ReviewStatesTableTableManager(_db, _db.reviewStates);
  $$DrillItemsTableTableManager get drillItems =>
      $$DrillItemsTableTableManager(_db, _db.drillItems);
  $$DrillAttemptsTableTableManager get drillAttempts =>
      $$DrillAttemptsTableTableManager(_db, _db.drillAttempts);
  $$CurriculumWeeksTableTableManager get curriculumWeeks =>
      $$CurriculumWeeksTableTableManager(_db, _db.curriculumWeeks);
  $$SessionLogsTableTableManager get sessionLogs =>
      $$SessionLogsTableTableManager(_db, _db.sessionLogs);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$ReadingSetsTableTableManager get readingSets =>
      $$ReadingSetsTableTableManager(_db, _db.readingSets);
  $$ReadingAttemptsTableTableManager get readingAttempts =>
      $$ReadingAttemptsTableTableManager(_db, _db.readingAttempts);
  $$WritingAttemptsTableTableManager get writingAttempts =>
      $$WritingAttemptsTableTableManager(_db, _db.writingAttempts);
}
