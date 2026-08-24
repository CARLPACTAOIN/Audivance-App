import '../../core/domain/attachment_ref.dart';
import '../../core/domain/identity.dart';
import '../../core/domain/money.dart';
import '../../core/domain/stable_id_generator.dart';
import '../../core/domain/validation_result.dart';
import '../audit/data/audit_repository.dart';
import '../audit/domain/audit_models.dart';
import '../audit/domain/audit_rules.dart';
import '../treasury/treasury_formatters.dart';

class EventService {
  const EventService({
    required this.repository,
    required this.idGenerator,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuditRepository repository;
  final StableIdGenerator idGenerator;
  final DateTime Function() _now;

  Future<EventWorkspaceSnapshot> loadSnapshot({required DateTime asOf}) async {
    final events = await repository.listAuditEvents();
    final sources = await repository.listTreasuryFundSources();
    final sortedEvents = [...events]
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final sortedSources = [...sources]
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    return EventWorkspaceSnapshot(
      events: sortedEvents
          .map(
            (event) => EventCardView(
              id: event.id,
              name: event.name,
              type: event.type,
              semester: event.semester,
              schoolYear: event.schoolYear,
              startDate: event.startDate,
              endDate: event.endDate,
              resolutionNumber: event.resolutionNumber,
              budget: event.budget,
              approvedBudgetBalance: event.approvedBudgetBalance,
              status: EventRules.calculateStatus(event: event, asOf: asOf),
            ),
          )
          .toList(growable: false),
      sourceOptions: sortedSources
          .map(
            (source) => TreasurySourceAllocationOption(
              id: source.id,
              type: source.type,
              label: source.label,
              balance: source.balance,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<ValidationResult> createEvent(CreateEventCommand command) async {
    final sources = await repository.listTreasuryFundSources();
    final sourceBalances = {
      for (final source in sources) source.id: source.balance,
    };
    final byId = {for (final source in sources) source.id: source};
    final eventId = idGenerator.nextId('event');
    final event = AuditEvent(
      id: eventId,
      name: command.name.trim(),
      type: command.type.trim(),
      semester: command.semester.trim(),
      schoolYear: command.schoolYear.trim(),
      startDate: command.startDate,
      endDate: command.endDate,
      permitApprovalDate: command.permitApprovalDate,
      resolutionNumber: command.resolutionNumber.trim(),
      budget: command.budget,
      approvedBudgetBalance: command.budget,
      resolutionAttachment: command.resolutionAttachment,
    );
    final allocations = command.allocations
        .map(
          (draft) => EventFundingAllocation(
            eventId: eventId,
            fundSourceId: draft.fundSourceId,
            amount: draft.amount,
          ),
        )
        .toList(growable: false);
    final validation = ValidationResult.combine([
      _validateCommand(command, sourceBalances.keys.toSet()),
      EventRules.validateEventBudget(
        event: event,
        allocations: allocations,
        sourceBalances: sourceBalances,
      ),
    ]);
    if (validation.isInvalid) {
      return validation;
    }

    final saveResult = await repository.saveAuditEvent(
      event: event,
      allocations: allocations,
    );
    if (saveResult.isInvalid) {
      return saveResult;
    }

    final allocatedBySource = <StableId, Money>{};
    for (final allocation in allocations) {
      allocatedBySource.update(
        allocation.fundSourceId,
        (current) => current + allocation.amount,
        ifAbsent: () => allocation.amount,
      );
    }
    for (final entry in allocatedBySource.entries) {
      final source = byId[entry.key]!;
      await repository.updateTreasuryFundSource(
        TreasuryFundSource(
          id: source.id,
          type: source.type,
          label: source.label,
          balance: source.balance - entry.value,
          supportingAttachment: source.supportingAttachment,
        ),
      );
    }

    for (final allocation in allocations) {
      final source = byId[allocation.fundSourceId]!;
      final movementId = idGenerator.nextId('movement');
      final movement = FundMovement(
        id: movementId,
        reference: _movementReference(_now(), movementId),
        type: FundMovementType.budgetAllocation,
        date: _now(),
        amount: allocation.amount,
        purpose: 'Budget allocation: ${event.name}',
        eventId: event.id,
        fromFundSourceId: source.id,
        isSystemGenerated: true,
      );
      final movementResult = await repository.saveFundMovement(
        movement: movement,
      );
      if (movementResult.isInvalid) {
        return movementResult;
      }
    }

    await repository.appendAuditLog(
      AuditLogEntry(
        id: idGenerator.nextId('audit-log'),
        action: 'events.create',
        actor: 'local-account',
        targetRecordId: event.id,
        occurredAt: _now(),
        amount: event.budget,
        reference: event.resolutionNumber,
        metadata: {
          'eventName': event.name,
          'allocationCount': allocations.length,
        },
      ),
    );
    return const ValidationResult.valid();
  }

  Future<ValidationResult> adjustEventBudget(
    AdjustEventBudgetCommand command,
  ) async {
    final events = await repository.listAuditEvents();
    AuditEvent? event;
    for (final candidate in events) {
      if (candidate.id == command.eventId) {
        event = candidate;
        break;
      }
    }
    if (event == null) {
      return ValidationResult.failure('Selected event does not exist.');
    }

    final sources = await repository.listTreasuryFundSources();
    TreasuryFundSource? source;
    for (final candidate in sources) {
      if (candidate.id == command.treasurySourceId) {
        source = candidate;
        break;
      }
    }

    final validation = ValidationResult.combine([
      _validateBudgetAdjustmentCommand(command, event, source),
      if (source != null)
        switch (command.direction) {
          BudgetAdjustmentDirection.increase =>
            EventRules.validateBudgetIncrease(
              increaseAmount: command.amount,
              sourceBalance: source.balance,
            ),
          BudgetAdjustmentDirection.decrease =>
            EventRules.validateBudgetDecrease(
              decreaseAmount: command.amount,
              approvedBudgetBalance: event.approvedBudgetBalance,
            ),
        },
    ]);
    if (validation.isInvalid) {
      return validation;
    }

    final isIncrease = command.direction == BudgetAdjustmentDirection.increase;
    final adjustedEvent = AuditEvent(
      id: event.id,
      name: event.name,
      type: event.type,
      semester: event.semester,
      schoolYear: event.schoolYear,
      startDate: event.startDate,
      endDate: event.endDate,
      permitApprovalDate: event.permitApprovalDate,
      resolutionNumber: event.resolutionNumber,
      budget: isIncrease
          ? event.budget + command.amount
          : event.budget - command.amount,
      approvedBudgetBalance: isIncrease
          ? event.approvedBudgetBalance + command.amount
          : event.approvedBudgetBalance - command.amount,
      resolutionAttachment: event.resolutionAttachment,
      isLiquidated: event.isLiquidated,
    );
    final adjustedSource = TreasuryFundSource(
      id: source!.id,
      type: source.type,
      label: source.label,
      balance: isIncrease
          ? source.balance - command.amount
          : source.balance + command.amount,
      supportingAttachment: source.supportingAttachment,
    );

    await repository.updateAuditEvent(adjustedEvent);
    await repository.updateTreasuryFundSource(adjustedSource);

    final movementId = idGenerator.nextId('movement');
    final movement = FundMovement(
      id: movementId,
      reference: _movementReference(command.adjustmentDate, movementId),
      type: FundMovementType.budgetAdjustment,
      date: command.adjustmentDate,
      amount: command.amount,
      purpose: isIncrease
          ? 'Budget increase: ${event.name}'
          : 'Budget decrease: ${event.name}',
      remarks: command.remarks.trim(),
      eventId: event.id,
      fromFundSourceId: isIncrease ? source.id : null,
      toFundSourceId: isIncrease ? null : source.id,
      isSystemGenerated: true,
    );
    final movementResult = await repository.saveFundMovement(
      movement: movement,
    );
    if (movementResult.isInvalid) {
      return movementResult;
    }

    await repository.appendAuditLog(
      AuditLogEntry(
        id: idGenerator.nextId('audit-log'),
        action: isIncrease ? 'events.budgetIncrease' : 'events.budgetDecrease',
        actor: 'local-account',
        targetRecordId: event.id,
        occurredAt: _now(),
        amount: command.amount,
        reference: movement.reference,
        beforeSnapshot: {
          'budgetCentavos': event.budget.centavos,
          'approvedBudgetBalanceCentavos': event.approvedBudgetBalance.centavos,
          'sourceBalanceCentavos': source.balance.centavos,
        },
        afterSnapshot: {
          'budgetCentavos': adjustedEvent.budget.centavos,
          'approvedBudgetBalanceCentavos':
              adjustedEvent.approvedBudgetBalance.centavos,
          'sourceBalanceCentavos': adjustedSource.balance.centavos,
        },
        metadata: {
          'eventName': event.name,
          'direction': command.direction.name,
          'treasurySourceId': source.id,
          'remarks': command.remarks.trim(),
        },
      ),
    );
    return const ValidationResult.valid();
  }

  Future<BudgetActualSnapshot?> loadBudgetActual(
    StableId eventId, {
    required DateTime asOf,
  }) async {
    final events = await repository.listAuditEvents();
    AuditEvent? event;
    for (final candidate in events) {
      if (candidate.id == eventId) {
        event = candidate;
        break;
      }
    }
    if (event == null) {
      return null;
    }
    final selectedEvent = event;
    final receiptIds = <StableId>{};
    for (final receipt in await repository.listLiquidationReceipts()) {
      if (receipt.eventId == selectedEvent.id) {
        receiptIds.add(receipt.id);
      }
    }
    final lines = (await repository.listLiquidationLines())
        .where((line) => receiptIds.contains(line.receiptId))
        .toList(growable: false);
    final claims = (await repository.listReimbursementClaims())
        .where((claim) => claim.eventId == selectedEvent.id)
        .toList(growable: false);
    final reviews = await repository.listAuditorReviewsForEvent(
      selectedEvent.id,
    );
    final sortedReviews = [...reviews]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final actual = lines.fold(Money.zero, (total, line) => total + line.total);
    final pendingReimbursementTotal = claims
        .where((claim) => claim.status == ReimbursementStatus.pending)
        .fold(Money.zero, (total, claim) => total + claim.amount);
    final paidReimbursementTotal = claims
        .where((claim) => claim.status == ReimbursementStatus.paid)
        .fold(Money.zero, (total, claim) => total + claim.amount);
    final utilizationBasisPoints = _utilizationBasisPoints(
      actual: actual,
      budget: selectedEvent.budget,
    );
    final health = _budgetHealth(
      budget: selectedEvent.budget,
      utilizationBasisPoints: utilizationBasisPoints,
    );

    return BudgetActualSnapshot(
      eventId: selectedEvent.id,
      eventName: selectedEvent.name,
      status: EventRules.calculateStatus(event: selectedEvent, asOf: asOf),
      budget: selectedEvent.budget,
      approvedBudgetBalance: selectedEvent.approvedBudgetBalance,
      actual: actual,
      variance: selectedEvent.budget - actual,
      pendingReimbursementTotal: pendingReimbursementTotal,
      paidReimbursementTotal: paidReimbursementTotal,
      utilizationBasisPoints: utilizationBasisPoints,
      health: health,
      reviews: sortedReviews
          .map(AuditorReviewView.fromDomain)
          .toList(growable: false),
    );
  }

  Future<ValidationResult> createAuditorReview(
    CreateAuditorReviewCommand command,
  ) async {
    final snapshot = await loadBudgetActual(
      command.eventId,
      asOf: command.createdAt ?? _now(),
    );
    if (snapshot == null) {
      return ValidationResult.failure('Selected event does not exist.');
    }
    final validation = _validateAuditorReviewCommand(command);
    if (validation.isInvalid) {
      return validation;
    }

    final review = AuditorReviewSnapshot(
      id: idGenerator.nextId('auditor-review'),
      eventId: command.eventId,
      findings: command.findings.trim(),
      cause: command.cause.trim(),
      recommendation: command.recommendation.trim(),
      budget: snapshot.budget,
      actual: snapshot.actual,
      variance: snapshot.variance,
      utilizationBasisPoints: snapshot.utilizationBasisPoints,
      health: snapshot.health,
      createdAt: command.createdAt ?? _now(),
    );
    await repository.saveAuditorReview(review);
    await repository.appendAuditLog(
      AuditLogEntry(
        id: idGenerator.nextId('audit-log'),
        action: 'events.auditorReview',
        actor: 'local-account',
        targetRecordId: command.eventId,
        occurredAt: review.createdAt,
        amount: review.actual,
        metadata: {
          'eventName': snapshot.eventName,
          'budgetCentavos': review.budget.centavos,
          'actualCentavos': review.actual.centavos,
          'varianceCentavos': review.variance.centavos,
          'utilizationBasisPoints': review.utilizationBasisPoints,
          'health': review.health.name,
        },
      ),
    );
    return const ValidationResult.valid();
  }

  ValidationResult _validateCommand(
    CreateEventCommand command,
    Set<StableId> sourceIds,
  ) {
    final messages = <String>[];
    if (sourceIds.isEmpty) {
      messages.add('Create at least one Treasury source before adding events.');
    }
    if (command.name.trim().isEmpty) {
      messages.add('Event name is required.');
    }
    if (command.type.trim().isEmpty) {
      messages.add('Event type is required.');
    }
    if (command.semester.trim().isEmpty) {
      messages.add('Semester is required.');
    }
    if (command.schoolYear.trim().isEmpty) {
      messages.add('School year is required.');
    }
    if (command.resolutionNumber.trim().isEmpty) {
      messages.add('Resolution number is required.');
    }
    if (!command.budget.isPositive) {
      messages.add('Event budget must be greater than zero.');
    }
    if (command.endDate.isBefore(command.startDate)) {
      messages.add('Event end date cannot be before the start date.');
    }
    if (command.resolutionAttachment == null) {
      messages.add('Event resolution attachment is required.');
    }
    if (command.allocations.isEmpty) {
      messages.add('At least one funding allocation is required.');
    }
    for (final allocation in command.allocations) {
      if (!allocation.amount.isPositive) {
        messages.add('Funding allocation amounts must be greater than zero.');
      }
      if (!sourceIds.contains(allocation.fundSourceId)) {
        messages.add('Selected funding source does not exist.');
      }
    }
    return ValidationResult.invalid(messages);
  }

  ValidationResult _validateBudgetAdjustmentCommand(
    AdjustEventBudgetCommand command,
    AuditEvent event,
    TreasuryFundSource? source,
  ) {
    final messages = <String>[];
    if (!command.amount.isPositive) {
      messages.add('Budget adjustment amount must be greater than zero.');
    }
    if (command.remarks.trim().isEmpty) {
      messages.add('Budget adjustment remarks are required.');
    }
    if (event.isLiquidated) {
      messages.add('Liquidated events cannot be adjusted.');
    }
    if (source == null) {
      messages.add('Selected Treasury source does not exist.');
    }
    if (command.direction == BudgetAdjustmentDirection.decrease &&
        command.amount > event.budget) {
      messages.add('Budget decrease cannot make the event budget negative.');
    }
    return ValidationResult.invalid(messages);
  }

  ValidationResult _validateAuditorReviewCommand(
    CreateAuditorReviewCommand command,
  ) {
    final messages = <String>[];
    if (command.findings.trim().isEmpty) {
      messages.add('Findings are required.');
    }
    if (command.cause.trim().isEmpty) {
      messages.add('Cause is required.');
    }
    if (command.recommendation.trim().isEmpty) {
      messages.add('Recommendation is required.');
    }
    return ValidationResult.invalid(messages);
  }
}

class CreateEventCommand {
  const CreateEventCommand({
    required this.name,
    required this.type,
    required this.semester,
    required this.schoolYear,
    required this.startDate,
    required this.endDate,
    required this.resolutionNumber,
    required this.budget,
    required this.allocations,
    this.permitApprovalDate,
    this.resolutionAttachment,
  });

  final String name;
  final String type;
  final String semester;
  final String schoolYear;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? permitApprovalDate;
  final String resolutionNumber;
  final Money budget;
  final AttachmentRef? resolutionAttachment;
  final List<EventAllocationDraft> allocations;
}

class EventAllocationDraft {
  const EventAllocationDraft({
    required this.fundSourceId,
    required this.amount,
  });

  final StableId fundSourceId;
  final Money amount;
}

class AdjustEventBudgetCommand {
  const AdjustEventBudgetCommand({
    required this.eventId,
    required this.direction,
    required this.amount,
    required this.treasurySourceId,
    required this.adjustmentDate,
    required this.remarks,
  });

  final StableId eventId;
  final BudgetAdjustmentDirection direction;
  final Money amount;
  final StableId treasurySourceId;
  final DateTime adjustmentDate;
  final String remarks;
}

enum BudgetAdjustmentDirection { increase, decrease }

class CreateAuditorReviewCommand {
  const CreateAuditorReviewCommand({
    required this.eventId,
    required this.findings,
    required this.cause,
    required this.recommendation,
    this.createdAt,
  });

  final StableId eventId;
  final String findings;
  final String cause;
  final String recommendation;
  final DateTime? createdAt;
}

class BudgetAdjustmentReview {
  const BudgetAdjustmentReview({
    required this.currentBudget,
    required this.currentApprovedBudgetBalance,
    required this.sourceBalance,
    required this.projectedBudget,
    required this.projectedApprovedBudgetBalance,
    required this.projectedSourceBalance,
  });

  final Money currentBudget;
  final Money currentApprovedBudgetBalance;
  final Money sourceBalance;
  final Money projectedBudget;
  final Money projectedApprovedBudgetBalance;
  final Money projectedSourceBalance;

  String get currentBudgetLabel => formatPhpMoney(currentBudget);
  String get currentApprovedBudgetBalanceLabel =>
      formatPhpMoney(currentApprovedBudgetBalance);
  String get sourceBalanceLabel => formatPhpMoney(sourceBalance);
  String get projectedBudgetLabel => formatPhpMoney(projectedBudget);
  String get projectedApprovedBudgetBalanceLabel =>
      formatPhpMoney(projectedApprovedBudgetBalance);
  String get projectedSourceBalanceLabel =>
      formatPhpMoney(projectedSourceBalance);
}

class BudgetActualSnapshot {
  const BudgetActualSnapshot({
    required this.eventId,
    required this.eventName,
    required this.status,
    required this.budget,
    required this.approvedBudgetBalance,
    required this.actual,
    required this.variance,
    required this.pendingReimbursementTotal,
    required this.paidReimbursementTotal,
    required this.utilizationBasisPoints,
    required this.health,
    required this.reviews,
  });

  final StableId eventId;
  final String eventName;
  final AuditEventStatus status;
  final Money budget;
  final Money approvedBudgetBalance;
  final Money actual;
  final Money variance;
  final Money pendingReimbursementTotal;
  final Money paidReimbursementTotal;
  final int utilizationBasisPoints;
  final BudgetHealth health;
  final List<AuditorReviewView> reviews;

  String get budgetLabel => formatPhpMoney(budget);
  String get approvedBudgetBalanceLabel =>
      formatPhpMoney(approvedBudgetBalance);
  String get actualLabel => formatPhpMoney(actual);
  String get varianceLabel => formatPhpMoney(variance);
  String get pendingReimbursementTotalLabel =>
      formatPhpMoney(pendingReimbursementTotal);
  String get paidReimbursementTotalLabel =>
      formatPhpMoney(paidReimbursementTotal);
  String get utilizationLabel =>
      '${(utilizationBasisPoints ~/ 100).toString()}.${(utilizationBasisPoints % 100).toString().padLeft(2, '0')}%';
  String get healthLabel => budgetHealthLabel(health);
  bool get isOverBudget => variance.isNegative;
}

class AuditorReviewView {
  const AuditorReviewView({
    required this.id,
    required this.eventId,
    required this.findings,
    required this.cause,
    required this.recommendation,
    required this.budget,
    required this.actual,
    required this.variance,
    required this.utilizationBasisPoints,
    required this.health,
    required this.createdAt,
  });

  factory AuditorReviewView.fromDomain(AuditorReviewSnapshot review) {
    return AuditorReviewView(
      id: review.id,
      eventId: review.eventId,
      findings: review.findings,
      cause: review.cause,
      recommendation: review.recommendation,
      budget: review.budget,
      actual: review.actual,
      variance: review.variance,
      utilizationBasisPoints: review.utilizationBasisPoints,
      health: review.health,
      createdAt: review.createdAt,
    );
  }

  final StableId id;
  final StableId eventId;
  final String findings;
  final String cause;
  final String recommendation;
  final Money budget;
  final Money actual;
  final Money variance;
  final int utilizationBasisPoints;
  final BudgetHealth health;
  final DateTime createdAt;

  String get budgetLabel => formatPhpMoney(budget);
  String get actualLabel => formatPhpMoney(actual);
  String get varianceLabel => formatPhpMoney(variance);
  String get utilizationLabel =>
      '${(utilizationBasisPoints ~/ 100).toString()}.${(utilizationBasisPoints % 100).toString().padLeft(2, '0')}%';
  String get healthLabel => budgetHealthLabel(health);
  String get createdAtLabel => formatDate(createdAt);
}

class EventWorkspaceSnapshot {
  const EventWorkspaceSnapshot({
    required this.events,
    required this.sourceOptions,
  });

  final List<EventCardView> events;
  final List<TreasurySourceAllocationOption> sourceOptions;
}

class EventCardView {
  const EventCardView({
    required this.id,
    required this.name,
    required this.type,
    required this.semester,
    required this.schoolYear,
    required this.startDate,
    required this.endDate,
    required this.resolutionNumber,
    required this.budget,
    required this.approvedBudgetBalance,
    required this.status,
  });

  final StableId id;
  final String name;
  final String type;
  final String semester;
  final String schoolYear;
  final DateTime startDate;
  final DateTime endDate;
  final String resolutionNumber;
  final Money budget;
  final Money approvedBudgetBalance;
  final AuditEventStatus status;

  String get budgetLabel => formatPhpMoney(budget);
  String get approvedBudgetBalanceLabel =>
      formatPhpMoney(approvedBudgetBalance);
  String get dateRangeLabel =>
      '${formatDate(startDate)} - ${formatDate(endDate)}';
  String get statusLabel => auditEventStatusLabel(status);
  bool get canAdjustBudget => status != AuditEventStatus.liquidated;
}

class TreasurySourceAllocationOption {
  const TreasurySourceAllocationOption({
    required this.id,
    required this.type,
    required this.label,
    required this.balance,
  });

  final StableId id;
  final TreasuryFundSourceType type;
  final String label;
  final Money balance;

  String get balanceLabel => formatPhpMoney(balance);
  String get typeLabel => treasurySourceTypeLabel(type);
}

String auditEventStatusLabel(AuditEventStatus status) {
  return switch (status) {
    AuditEventStatus.ongoing => 'Ongoing',
    AuditEventStatus.forLiquidation => 'For Liquidation',
    AuditEventStatus.due => 'Due',
    AuditEventStatus.liquidated => 'Liquidated',
  };
}

String budgetHealthLabel(BudgetHealth health) {
  return switch (health) {
    BudgetHealth.noBudget => 'No Budget',
    BudgetHealth.healthy => 'Healthy',
    BudgetHealth.watch => 'Watch',
    BudgetHealth.overBudget => 'Over Budget',
    BudgetHealth.critical => 'Critical',
  };
}

int _utilizationBasisPoints({required Money actual, required Money budget}) {
  if (budget.centavos <= 0) {
    return 0;
  }
  return (actual.centavos * 10000) ~/ budget.centavos;
}

BudgetHealth _budgetHealth({
  required Money budget,
  required int utilizationBasisPoints,
}) {
  if (budget.centavos <= 0) {
    return BudgetHealth.noBudget;
  }
  if (utilizationBasisPoints <= 8000) {
    return BudgetHealth.healthy;
  }
  if (utilizationBasisPoints <= 10000) {
    return BudgetHealth.watch;
  }
  if (utilizationBasisPoints <= 12000) {
    return BudgetHealth.overBudget;
  }
  return BudgetHealth.critical;
}

String _movementReference(DateTime date, StableId seed) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  final hash = seed.hashCode.toUnsigned(32).toRadixString(16).toUpperCase();
  return 'FM-$y$m$d-${hash.padLeft(8, '0').substring(0, 8)}';
}
