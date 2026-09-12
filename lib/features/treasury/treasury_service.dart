import '../../core/domain/attachment_ref.dart';
import '../../core/domain/identity.dart';
import '../../core/domain/money.dart';
import '../../core/domain/stable_id_generator.dart';
import '../../core/domain/validation_result.dart';
import '../audit/data/audit_repository.dart';
import '../audit/domain/audit_models.dart';
import '../audit/domain/audit_rules.dart';
import 'treasury_formatters.dart';

class TreasuryService {
  const TreasuryService({
    required this.repository,
    required this.idGenerator,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuditRepository repository;
  final StableIdGenerator idGenerator;
  final DateTime Function() _now;

  Future<TreasurySnapshot> loadSnapshot() async {
    final sources = await repository.listTreasuryFundSources();
    final movements = await repository.listFundMovements();
    final events = await repository.listAuditEvents();
    final officers = await repository.listOfficers();
    final sortedSources = [...sources]
      ..sort(
        (a, b) =>
            treasurySourceTypeLabel(a.type)
                .toLowerCase()
                .compareTo(treasurySourceTypeLabel(b.type).toLowerCase()),
      );
    final sortedMovements = [...movements]
      ..sort((a, b) => b.date.compareTo(a.date));
    final sortedEvents = [...events]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final sortedOfficers =
        officers.where((officer) => !officer.isArchived).toList(growable: false)
          ..sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );

    return TreasurySnapshot(
      totalBalance: _sumMoney(sortedSources.map((source) => source.balance)),
      sources: sortedSources
          .map(
            (source) => TreasurySourceView(
              id: source.id,
              type: source.type,
              label: treasurySourceTypeLabel(source.type),
              balance: source.balance,
              supportingAttachment: source.supportingAttachment,
            ),
          )
          .toList(growable: false),
      ledgerRows: sortedMovements
          .map(
            (movement) => TreasuryLedgerRow(
              id: movement.id,
              reference: movement.reference,
              type: movement.type,
              date: movement.date,
              amount: movement.amount,
              purpose: movement.purpose,
              remarks: movement.remarks,
              fromFundSourceId: movement.fromFundSourceId,
              toFundSourceId: movement.toFundSourceId,
              holderOfficerId: movement.holderOfficerId,
              isSystemGenerated: movement.isSystemGenerated,
            ),
          )
          .toList(growable: false),
      eventOptions: sortedEvents
          .where((event) => !event.isLiquidated)
          .map(
            (event) => TreasuryEventOption(
              id: event.id,
              name: event.name,
              approvedBudgetBalance: event.approvedBudgetBalance,
              status: EventRules.calculateStatus(event: event, asOf: _now()),
            ),
          )
          .toList(growable: false),
      officerOptions: sortedOfficers
          .map(
            (officer) => TreasuryOfficerOption(
              id: officer.id,
              fullName: officer.fullName,
              custodyBalance: _officerCustodyBalance(
                movements: movements,
                officerId: officer.id,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<ValidationResult> addFund(AddFundCommand command) async {
    final validation = ValidationResult.combine([
      TreasuryRules.validateAddFund(
        amount: command.amount,
        supportingAttachment: command.supportingAttachment,
      ),
    ]);
    if (validation.isInvalid) {
      return validation;
    }

    final existingSource = await _sourceForAddFund(command.existingSourceId);
    final sourceForType = existingSource ?? await _sourceForType(command.type);
    final label = treasurySourceTypeLabel(sourceForType?.type ?? command.type);
    final source = sourceForType == null
        ? TreasuryFundSource(
            id: idGenerator.nextId('source'),
            type: command.type,
            label: label,
            balance: command.amount,
            supportingAttachment: command.supportingAttachment,
          )
        : TreasuryFundSource(
            id: sourceForType.id,
            type: sourceForType.type,
            label: treasurySourceTypeLabel(sourceForType.type),
            balance: sourceForType.balance + command.amount,
            supportingAttachment: command.supportingAttachment,
          );

    final movementId = idGenerator.nextId('movement');
    final movement = FundMovement(
      id: movementId,
      reference: _movementReference(command.date, movementId),
      type: FundMovementType.addFund,
      date: command.date,
      amount: command.amount,
      purpose: 'Add Fund: ${source.label}',
      remarks: command.remarks?.trim().isEmpty ?? true
          ? null
          : command.remarks!.trim(),
      toFundSourceId: source.id,
      isSystemGenerated: true,
    );

    await repository.updateTreasuryFundSource(source);
    final movementResult = await repository.saveFundMovement(
      movement: movement,
    );
    if (movementResult.isInvalid) {
      return movementResult;
    }
    await _appendAuditLog(
      action: 'treasury.add_fund',
      targetRecordId: source.id,
      amount: command.amount,
      reference: movement.reference,
      metadata: {'sourceLabel': source.label, 'sourceType': source.type.name},
    );
    return const ValidationResult.valid();
  }

  Future<ValidationResult> recordManualMovement(
    ManualFundMovementCommand command,
  ) async {
    final validation = await _validateManualCommand(command);
    if (validation.isInvalid) {
      return validation;
    }

    final sources = await repository.listTreasuryFundSources();
    final events = await repository.listAuditEvents();
    final movements = await repository.listFundMovements();
    final bySourceId = {for (final s in sources) s.id: s};
    final byEventId = {for (final e in events) e.id: e};

    final toSource = command.toFundSourceId == null
        ? null
        : bySourceId[command.toFundSourceId];
    final event = command.eventId == null ? null : byEventId[command.eventId];

    // Determine available balance for the balance-check pass.
    final Money availableBalance;
    switch (command.type) {
      case FundMovementType.fundRelease:
        availableBalance = event?.approvedBudgetBalance ?? Money.zero;
      case FundMovementType.transfer:
        // Officer-to-officer: check from-officer custody for this event.
        availableBalance = _officerCustodyBalance(
          movements: movements,
          officerId: command.holderOfficerId,
          eventId: command.eventId,
        );
      case FundMovementType.returnRefund:
        // Return/Refund: deduct from event Approved Budget.
        availableBalance = event?.approvedBudgetBalance ?? Money.zero;
      case FundMovementType.officerReturn:
        // Officer return: check officer custody for this event.
        availableBalance = _officerCustodyBalance(
          movements: movements,
          officerId: command.holderOfficerId,
          eventId: command.eventId,
        );
      default:
        availableBalance = Money.zero;
    }

    final movementValidation = FundMovementRules.validateManualMovement(
      type: command.type,
      amount: command.amount,
      availableBalance: availableBalance,
    );
    if (movementValidation.isInvalid) {
      return movementValidation;
    }

    final movementId = idGenerator.nextId('movement');
    final movement = FundMovement(
      id: movementId,
      reference: _movementReference(command.date, movementId),
      type: command.type,
      date: command.date,
      amount: command.amount,
      purpose: command.purpose.trim(),
      remarks: command.remarks?.trim().isEmpty ?? true
          ? null
          : command.remarks!.trim(),
      eventId: command.eventId,
      holderOfficerId: command.holderOfficerId,
      toHolderOfficerId: command.toHolderOfficerId,
      toFundSourceId: command.type == FundMovementType.returnRefund
          ? command.toFundSourceId
          : null,
      isSystemGenerated: false,
    );
    final movementResult = await repository.saveFundMovement(
      movement: movement,
      availableBalance: availableBalance,
    );
    if (movementResult.isInvalid) {
      return movementResult;
    }

    // --- Balance effects per movement type ---

    if (command.type == FundMovementType.fundRelease && event != null) {
      // Fund Release: deduct from event Approved Budget.
      await repository.updateAuditEvent(
        _copyEvent(event, approvedBudgetBalance: event.approvedBudgetBalance - command.amount),
      );
    }

    if (command.type == FundMovementType.officerReturn && event != null) {
      // Officer Return: return unused custody back to event Approved Budget.
      await repository.updateAuditEvent(
        _copyEvent(event, approvedBudgetBalance: event.approvedBudgetBalance + command.amount),
      );
    }

    if (command.type == FundMovementType.returnRefund && event != null) {
      // Return/Refund to Treasury: deduct from event Approved Budget.
      await repository.updateAuditEvent(
        _copyEvent(event, approvedBudgetBalance: event.approvedBudgetBalance - command.amount),
      );
      // Credit the treasury source fund.
      if (toSource != null) {
        await repository.updateTreasuryFundSource(
          TreasuryFundSource(
            id: toSource.id,
            type: toSource.type,
            label: toSource.label,
            balance: toSource.balance + command.amount,
            supportingAttachment: toSource.supportingAttachment,
          ),
        );
      }
    }

    // Officer-to-officer transfer has no treasury or event balance effect;
    // custody is tracked through movement history (_officerCustodyBalance).

    final auditMetadata = <String, Object?>{
      'movementType': movement.type.name,
      'eventId': movement.eventId?.toString(),
      'holderOfficerId': movement.holderOfficerId?.toString(),
      'toHolderOfficerId': movement.toHolderOfficerId?.toString(),
      'toFundSourceId': movement.toFundSourceId?.toString(),
    };

    await _appendAuditLog(
      action: switch (command.type) {
        FundMovementType.transfer => 'treasury.officer_transfer',
        FundMovementType.officerReturn => 'treasury.officer_return_to_budget',
        FundMovementType.returnRefund => 'treasury.return_refund_to_source',
        _ => 'treasury.manual_movement',
      },
      targetRecordId: movement.id,
      amount: command.amount,
      reference: movement.reference,
      metadata: auditMetadata,
    );
    return const ValidationResult.valid();
  }

  /// Returns the total outstanding officer custody across all movements
  /// for the given event. Used to surface a warning before Return/Refund.
  Future<Money> totalOfficerCustodyForEvent(StableId eventId) async {
    final movements = await repository.listFundMovements();
    final officers = await repository.listOfficers();
    var total = Money.zero;
    for (final officer in officers) {
      if (officer.isArchived) continue;
      total += _officerCustodyBalance(
        movements: movements,
        officerId: officer.id,
        eventId: eventId,
      );
    }
    return total;
  }


  Future<TreasuryFundSource?> _sourceForAddFund(StableId? id) async {
    if (id == null) {
      return null;
    }
    for (final source in await repository.listTreasuryFundSources()) {
      if (source.id == id) {
        return source;
      }
    }
    return null;
  }

  Future<TreasuryFundSource?> _sourceForType(
    TreasuryFundSourceType type,
  ) async {
    for (final source in await repository.listTreasuryFundSources()) {
      if (source.type == type) {
        return source;
      }
    }
    return null;
  }

  Future<ValidationResult> _validateManualCommand(
    ManualFundMovementCommand command,
  ) async {
    final messages = <String>[];
    if (!FundMovementRules.manualTypes.contains(command.type)) {
      messages.add(
        'Manual fund movements are limited to Fund Release, Officer-to-Officer Transfer, Return to Event Budget, and Return / Refund to Treasury.',
      );
    }
    if (command.purpose.trim().isEmpty) {
      messages.add('Fund movement purpose is required.');
    }

    final sources = await repository.listTreasuryFundSources();
    final events = await repository.listAuditEvents();
    final officers = await repository.listOfficers();
    final sourceIds = sources.map((source) => source.id).toSet();
    final eventIds = events.map((event) => event.id).toSet();
    final officerIds = officers
        .where((officer) => !officer.isArchived)
        .map((officer) => officer.id)
        .toSet();
    final toId = command.toFundSourceId;

    switch (command.type) {
      case FundMovementType.fundRelease:
        if (command.eventId == null) {
          messages.add('Fund Release requires an event Approved Budget.');
        }
        if (command.holderOfficerId == null) {
          messages.add('Fund Release requires a fund custodian officer.');
        }
      case FundMovementType.transfer:
        // Officer-to-officer transfer.
        if (command.holderOfficerId == null) {
          messages.add('Transfer requires a From officer.');
        }
        if (command.toHolderOfficerId == null) {
          messages.add('Transfer requires a To officer.');
        }
        if (command.holderOfficerId != null &&
            command.toHolderOfficerId != null &&
            command.holderOfficerId == command.toHolderOfficerId) {
          messages.add('Transfer From and To officers must be different.');
        }
        if (command.eventId == null) {
          messages.add('Transfer requires an event.');
        }
      case FundMovementType.returnRefund:
        // Return/Refund to Treasury: requires event source and target fund.
        if (command.eventId == null) {
          messages.add('Return / Refund requires the event being refunded.');
        }
        if (toId == null) {
          messages.add('Return / Refund requires a target treasury fund.');
        }
      case FundMovementType.officerReturn:
        // Officer returns custody back to event Approved Budget.
        if (command.holderOfficerId == null) {
          messages.add('Return to Event Budget requires an officer.');
        }
        if (command.eventId == null) {
          messages.add('Return to Event Budget requires an event.');
        }
      case FundMovementType.addFund:
      case FundMovementType.budgetAllocation:
      case FundMovementType.budgetAdjustment:
      case FundMovementType.liquidationSubmitted:
      case FundMovementType.reimbursementPayment:
        break;
    }

    if (toId != null && !sourceIds.contains(toId)) {
      messages.add('Selected target fund does not exist.');
    }
    if (command.eventId != null && !eventIds.contains(command.eventId)) {
      messages.add('Selected event does not exist.');
    }
    if (command.holderOfficerId != null &&
        !officerIds.contains(command.holderOfficerId)) {
      messages.add('Selected From officer does not exist.');
    }
    if (command.toHolderOfficerId != null &&
        !officerIds.contains(command.toHolderOfficerId)) {
      messages.add('Selected To officer does not exist.');
    }

    return ValidationResult.invalid(messages);
  }

  Future<void> _appendAuditLog({
    required String action,
    required StableId targetRecordId,
    required Money amount,
    required String reference,
    required Map<String, Object?> metadata,
  }) {
    return repository.appendAuditLog(
      AuditLogEntry(
        id: idGenerator.nextId('audit-log'),
        action: action,
        actor: 'local-account',
        targetRecordId: targetRecordId,
        occurredAt: _now(),
        amount: amount,
        reference: reference,
        metadata: metadata,
      ),
    );
  }
}

class AddFundCommand {
  const AddFundCommand({
    required this.type,
    required this.amount,
    required this.date,
    this.existingSourceId,
    this.label = '',
    this.supportingAttachment,
    this.remarks,
  });

  final TreasuryFundSourceType type;
  final String label;
  final Money amount;
  final DateTime date;
  final StableId? existingSourceId;
  final AttachmentRef? supportingAttachment;
  final String? remarks;
}

class ManualFundMovementCommand {
  const ManualFundMovementCommand({
    required this.type,
    required this.amount,
    required this.date,
    required this.purpose,
    this.remarks,
    this.fromFundSourceId,
    this.toFundSourceId,
    this.holderOfficerId,
    this.toHolderOfficerId,
    this.eventId,
  });

  final FundMovementType type;
  final Money amount;
  final DateTime date;
  final String purpose;
  final String? remarks;
  /// For Return/Refund: not used (kept for potential future use).
  final StableId? fromFundSourceId;
  /// For Return/Refund: target treasury source. For Transfer: not used.
  final StableId? toFundSourceId;
  /// For Fund Release, Transfer (from), Officer Return: the officer holding.
  final StableId? holderOfficerId;
  /// For Transfer only: the receiving officer.
  final StableId? toHolderOfficerId;
  final StableId? eventId;
}

class TreasurySnapshot {
  const TreasurySnapshot({
    required this.totalBalance,
    required this.sources,
    required this.ledgerRows,
    required this.eventOptions,
    required this.officerOptions,
  });

  final Money totalBalance;
  final List<TreasurySourceView> sources;
  final List<TreasuryLedgerRow> ledgerRows;
  final List<TreasuryEventOption> eventOptions;
  final List<TreasuryOfficerOption> officerOptions;
}

class TreasurySourceView {
  const TreasurySourceView({
    required this.id,
    required this.type,
    required this.label,
    required this.balance,
    this.supportingAttachment,
  });

  final StableId id;
  final TreasuryFundSourceType type;
  final String label;
  final Money balance;
  final AttachmentRef? supportingAttachment;

  String get typeLabel => treasurySourceTypeLabel(type);
  String get balanceLabel => formatPhpMoney(balance);
}

class TreasuryEventOption {
  const TreasuryEventOption({
    required this.id,
    required this.name,
    required this.approvedBudgetBalance,
    required this.status,
  });

  final StableId id;
  final String name;
  final Money approvedBudgetBalance;
  final AuditEventStatus status;

  String get approvedBudgetBalanceLabel =>
      formatPhpMoney(approvedBudgetBalance);
}

class TreasuryOfficerOption {
  const TreasuryOfficerOption({
    required this.id,
    required this.fullName,
    this.custodyBalance = Money.zero,
  });

  final StableId id;
  final String fullName;
  /// Across all events — used to flag officers with outstanding custody.
  final Money custodyBalance;

  bool get hasCustody => custodyBalance.isPositive;
  String get custodyLabel => formatPhpMoney(custodyBalance);
}

class TreasuryLedgerRow {
  const TreasuryLedgerRow({
    required this.id,
    required this.reference,
    required this.type,
    required this.date,
    required this.amount,
    required this.purpose,
    required this.isSystemGenerated,
    this.remarks,
    this.fromFundSourceId,
    this.toFundSourceId,
    this.holderOfficerId,
  });

  final StableId id;
  final String reference;
  final FundMovementType type;
  final DateTime date;
  final Money amount;
  final String purpose;
  final String? remarks;
  final StableId? fromFundSourceId;
  final StableId? toFundSourceId;
  final StableId? holderOfficerId;
  final bool isSystemGenerated;

  String get typeLabel => fundMovementTypeLabel(type);
  String get amountLabel => formatPhpMoney(amount);
  String get dateLabel => formatDate(date);
}

Money _sumMoney(Iterable<Money> amounts) {
  return amounts.fold(Money.zero, (total, amount) => total + amount);
}

String _movementReference(DateTime date, StableId seed) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  final hash = seed.hashCode.toUnsigned(32).toRadixString(16).toUpperCase();
  return 'FM-$y$m$d-${hash.padLeft(8, '0').substring(0, 8)}';
}

/// Computes net officer custody balance from fund movements.
/// Optionally scoped to a single event.
Money _officerCustodyBalance({
  required List<FundMovement> movements,
  required StableId? officerId,
  StableId? eventId,
}) {
  if (officerId == null) return Money.zero;
  var balance = Money.zero;
  for (final movement in movements) {
    if (movement.holderOfficerId != officerId) continue;
    if (eventId != null && movement.eventId != eventId) continue;
    switch (movement.type) {
      case FundMovementType.fundRelease:
        balance += movement.amount;
      case FundMovementType.liquidationSubmitted:
      case FundMovementType.returnRefund:
      case FundMovementType.officerReturn:
        balance -= movement.amount;
      case FundMovementType.transfer:
        // Sending officer loses custody.
        balance -= movement.amount;
      case FundMovementType.addFund:
      case FundMovementType.budgetAllocation:
      case FundMovementType.budgetAdjustment:
      case FundMovementType.reimbursementPayment:
        break;
    }
    // Receiving officer gains custody from a transfer.
    if (movement.type == FundMovementType.transfer &&
        movement.toHolderOfficerId == officerId) {
      balance += movement.amount;
    }
  }
  return balance;
}

AuditEvent _copyEvent(
  AuditEvent event, {
  Money? approvedBudgetBalance,
  bool? isLiquidated,
}) {
  return AuditEvent(
    id: event.id,
    name: event.name,
    type: event.type,
    semester: event.semester,
    schoolYear: event.schoolYear,
    startDate: event.startDate,
    endDate: event.endDate,
    permitApprovalDate: event.permitApprovalDate,
    resolutionNumber: event.resolutionNumber,
    budget: event.budget,
    approvedBudgetBalance: approvedBudgetBalance ?? event.approvedBudgetBalance,
    resolutionAttachment: event.resolutionAttachment,
    isLiquidated: isLiquidated ?? event.isLiquidated,
  );
}
