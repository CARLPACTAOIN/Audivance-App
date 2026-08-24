import 'package:drift/drift.dart';

part 'audit_database.g.dart';

@DataClassName('LocalAccountRecord')
class LocalAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get emailOrStudentId => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isCredentialConfigured => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrganizationRecord')
class Organizations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get adviser => text()();
  TextColumn get semester => text()();
  TextColumn get schoolYear => text()();
  TextColumn get signatoryNamesJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OfficerRecord')
class Officers extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get position => text()();
  TextColumn get committee => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TreasuryFundSourceRecord')
class TreasuryFundSources extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get label => text()();
  IntColumn get balanceCentavos => integer()();
  TextColumn get supportingAttachmentId => text().nullable()();
  TextColumn get supportingAttachmentFileName => text().nullable()();
  TextColumn get supportingAttachmentLocalPath => text().nullable()();
  IntColumn get supportingAttachmentSizeBytes => integer().nullable()();
  TextColumn get supportingAttachmentChecksum => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AuditEventRecord')
class AuditEvents extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get semester => text()();
  TextColumn get schoolYear => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  DateTimeColumn get permitApprovalDate => dateTime().nullable()();
  TextColumn get resolutionNumber => text()();
  IntColumn get budgetCentavos => integer()();
  IntColumn get approvedBudgetBalanceCentavos => integer()();
  TextColumn get resolutionAttachmentId => text().nullable()();
  TextColumn get resolutionAttachmentFileName => text().nullable()();
  TextColumn get resolutionAttachmentLocalPath => text().nullable()();
  IntColumn get resolutionAttachmentSizeBytes => integer().nullable()();
  TextColumn get resolutionAttachmentChecksum => text().nullable()();
  BoolColumn get isLiquidated => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EventFundingAllocationRecord')
class EventFundingAllocations extends Table {
  TextColumn get eventId => text()();
  TextColumn get fundSourceId => text()();
  IntColumn get amountCentavos => integer()();

  @override
  Set<Column> get primaryKey => {eventId, fundSourceId};
}

@DataClassName('FundMovementRecord')
class FundMovements extends Table {
  TextColumn get id => text()();
  TextColumn get reference => text()();
  TextColumn get type => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get amountCentavos => integer()();
  TextColumn get purpose => text()();
  TextColumn get remarks => text().nullable()();
  TextColumn get eventId => text().nullable()();
  TextColumn get fromFundSourceId => text().nullable()();
  TextColumn get toFundSourceId => text().nullable()();
  TextColumn get holderOfficerId => text().nullable()();
  BoolColumn get isSystemGenerated => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LiquidationReceiptRecord')
class LiquidationReceipts extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get payeeOrMerchant => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get evidenceNumber => text()();
  TextColumn get receiptType => text()();
  TextColumn get fundingMode => text()();
  TextColumn get accountableOfficerId => text()();
  TextColumn get attachmentId => text()();
  TextColumn get attachmentFileName => text()();
  TextColumn get attachmentLocalPath => text()();
  IntColumn get attachmentSizeBytes => integer().nullable()();
  TextColumn get attachmentChecksum => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LiquidationLineRecord')
class LiquidationLines extends Table {
  TextColumn get id => text()();
  TextColumn get receiptId => text()();
  TextColumn get description => text()();
  IntColumn get quantity => integer()();
  IntColumn get unitCostCentavos => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReimbursementClaimRecord')
class ReimbursementClaims extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get officerId => text()();
  IntColumn get amountCentavos => integer()();
  TextColumn get status => text()();
  TextColumn get sourceLiquidationLineId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AuditorReviewRecord')
class AuditorReviews extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get findings => text()();
  TextColumn get cause => text()();
  TextColumn get recommendation => text()();
  IntColumn get budgetCentavos => integer()();
  IntColumn get actualCentavos => integer()();
  IntColumn get varianceCentavos => integer()();
  IntColumn get utilizationBasisPoints => integer()();
  TextColumn get health => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AuditLogRecord')
class AuditLogEntries extends Table {
  TextColumn get id => text()();
  TextColumn get action => text()();
  TextColumn get actor => text()();
  TextColumn get targetRecordId => text()();
  DateTimeColumn get occurredAt => dateTime()();
  IntColumn get amountCentavos => integer().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get beforeSnapshotJson => text().nullable()();
  TextColumn get afterSnapshotJson => text().nullable()();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LocalAccounts,
    Organizations,
    Officers,
    TreasuryFundSources,
    AuditEvents,
    EventFundingAllocations,
    FundMovements,
    LiquidationReceipts,
    LiquidationLines,
    ReimbursementClaims,
    AuditorReviews,
    AuditLogEntries,
  ],
)
class AuditDatabase extends _$AuditDatabase {
  AuditDatabase(super.executor);

  static const currentSchemaVersion = 3;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(localAccounts);
        }
        if (from < 3) {
          await migrator.createTable(auditorReviews);
        }
      },
    );
  }
}
