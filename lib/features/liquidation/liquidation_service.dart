import '../../core/domain/attachment_ref.dart';
import '../../core/domain/identity.dart';
import '../../core/domain/money.dart';
import '../../core/domain/stable_id_generator.dart';
import '../../core/domain/validation_result.dart';
import '../audit/data/audit_repository.dart';
import '../audit/domain/audit_models.dart';
import '../audit/domain/audit_rules.dart';
import '../events/event_service.dart';
import '../treasury/treasury_formatters.dart';

class LiquidationService {
  const LiquidationService({
    required this.repository,
    required this.idGenerator,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuditRepository repository;
  final StableIdGenerator idGenerator;
  final DateTime Function() _now;

  Future<LiquidationWorkspaceSnapshot> loadSnapshot({
    required DateTime asOf,
  }) async {
    final events = await repository.listAuditEvents();
    final receipts = await repository.listLiquidationReceipts();
    final lines = await repository.listLiquidationLines();
    final claims = await repository.listReimbursementClaims();
    final officers = await repository.listOfficers();
    final movements = await repository.listFundMovements();

    final eventById = {for (final event in events) event.id: event};
    final officerById = {for (final officer in officers) officer.id: officer};
    final linesByReceipt = <StableId, List<LiquidationLine>>{};
    for (final line in lines) {
      linesByReceipt.putIfAbsent(line.receiptId, () => []).add(line);
    }
    final receiptTotals = {
      for (final receipt in receipts)
        receipt.id: _sumMoney(
          linesByReceipt[receipt.id]?.map((line) => line.total) ?? const [],
        ),
    };

    final sortedEvents = [...events]
      ..sort((a, b) => b.endDate.compareTo(a.endDate));
    final sortedReceipts = [...receipts]
      ..sort((a, b) => b.date.compareTo(a.date));
    final sortedClaims = [...claims]
      ..sort((a, b) {
        final eventCompare = (eventById[b.eventId]?.endDate ?? DateTime(0))
            .compareTo(eventById[a.eventId]?.endDate ?? DateTime(0));
        if (eventCompare != 0) {
          return eventCompare;
        }
        return a.id.compareTo(b.id);
      });
    final sortedOfficers =
        officers.where((officer) => !officer.isArchived).toList(growable: false)
          ..sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );

    return LiquidationWorkspaceSnapshot(
      events: sortedEvents
          .map(
            (event) => LiquidationEventView(
              id: event.id,
              name: event.name,
              type: event.type,
              startDate: event.startDate,
              endDate: event.endDate,
              approvedBudgetBalance: event.approvedBudgetBalance,
              status: EventRules.calculateStatus(event: event, asOf: asOf),
              receiptCount: receipts
                  .where((receipt) => receipt.eventId == event.id)
                  .length,
              pendingClaimCount: claims
                  .where(
                    (claim) =>
                        claim.eventId == event.id &&
                        claim.status == ReimbursementStatus.pending,
                  )
                  .length,
            ),
          )
          .toList(growable: false),
      receipts: sortedReceipts
          .map(
            (receipt) => LiquidationReceiptView(
              id: receipt.id,
              eventId: receipt.eventId,
              eventName: eventById[receipt.eventId]?.name ?? 'Unknown event',
              payeeOrMerchant: receipt.payeeOrMerchant,
              date: receipt.date,
              evidenceNumber: receipt.evidenceNumber,
              receiptType: receipt.receiptType,
              fundingMode: receipt.fundingMode,
              accountableOfficerName:
                  officerById[receipt.accountableOfficerId]?.fullName ??
                  'Unknown officer',
              total: receiptTotals[receipt.id] ?? Money.zero,
            ),
          )
          .toList(growable: false),
      reimbursementClaims: sortedClaims
          .map((claim) {
            final event = eventById[claim.eventId];
            final projected = event == null
                ? Money.zero
                : event.approvedBudgetBalance - claim.amount;
            return ReimbursementClaimView(
              id: claim.id,
              eventId: claim.eventId,
              eventName: event?.name ?? 'Unknown event',
              officerName:
                  officerById[claim.officerId]?.fullName ?? 'Unknown officer',
              amount: claim.amount,
              status: claim.status,
              approvedBudgetBalance: event?.approvedBudgetBalance ?? Money.zero,
              projectedRemaining: projected,
            );
          })
          .toList(growable: false),
      officerOptions: sortedOfficers
          .map(
            (officer) => OfficerOption(
              id: officer.id,
              fullName: officer.fullName,
              position: officer.position,
              committee: officer.committee,
              fundCustodyBalance: _officerCustodyBalance(
                movements: movements,
                officerId: officer.id,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<List<OfficerOption>> listOfficerOptionsForEvent(
    StableId eventId,
  ) async {
    final officers = await repository.listOfficers();
    final movements = await repository.listFundMovements();
    final sortedOfficers =
        officers.where((officer) => !officer.isArchived).toList(growable: false)
          ..sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );

    return sortedOfficers
        .map(
          (officer) => OfficerOption(
            id: officer.id,
            fullName: officer.fullName,
            position: officer.position,
            committee: officer.committee,
            fundCustodyBalance: _officerCustodyBalance(
              movements: movements,
              officerId: officer.id,
              eventId: eventId,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<ValidationResult> createOfficer(CreateOfficerCommand command) async {
    final name = command.fullName.trim();
    if (name.isEmpty) {
      return ValidationResult.failure('Officer name is required.');
    }
    return repository.saveOfficers([
      Officer(
        id: idGenerator.nextId('officer'),
        fullName: name,
        position: command.position,
        committee: command.committee,
      ),
    ]);
  }

  Future<ValidationResult> submitLiquidation(
    SubmitLiquidationCommand command,
  ) async {
    final events = await repository.listAuditEvents();
    final event = _eventById(events, command.eventId);
    final officers = await repository.listOfficers();
    final movements = await repository.listFundMovements();
    final status = event == null
        ? null
        : EventRules.calculateStatus(event: event, asOf: _now());
    final officerCustodyBalance = _officerCustodyBalance(
      movements: movements,
      officerId: command.accountableOfficerId,
      eventId: command.eventId,
    );
    final validation = _validateLiquidationCommand(
      command: command,
      event: event,
      status: status,
      officerIds: officers.map((officer) => officer.id).toSet(),
      officerCustodyBalance: officerCustodyBalance,
    );
    if (validation.isInvalid) {
      return validation;
    }

    final receiptId = idGenerator.nextId('receipt');
    final receipt = LiquidationReceipt(
      id: receiptId,
      eventId: command.eventId,
      payeeOrMerchant: command.payeeOrMerchant.trim(),
      date: command.date,
      evidenceNumber: command.evidenceNumber.trim(),
      receiptType: command.receiptType,
      fundingMode: command.fundingMode,
      accountableOfficerId: command.accountableOfficerId,
      attachment: command.attachment!,
    );
    final lines = command.lines
        .map(
          (line) => LiquidationLine(
            id: idGenerator.nextId('line'),
            receiptId: receiptId,
            description: line.description.trim(),
            quantity: line.quantity,
            unitCost: line.unitCost,
          ),
        )
        .toList(growable: false);
    final total = _sumMoney(lines.map((line) => line.total));

    await repository.saveLiquidationReceipt(receipt);
    for (final line in lines) {
      await repository.saveLiquidationLine(line);
    }

    if (LiquidationRules.createsLiquidationSubmittedMovement(
      command.fundingMode,
    )) {
      final movementId = idGenerator.nextId('movement');
      final movement = FundMovement(
        id: movementId,
        reference: _movementReference(command.date, movementId),
        type: FundMovementType.liquidationSubmitted,
        date: command.date,
        amount: total,
        purpose: 'Liquidation submitted: ${event!.name}',
        remarks: command.remarks?.trim().isEmpty ?? true
            ? null
            : command.remarks!.trim(),
        eventId: event.id,
        holderOfficerId: command.accountableOfficerId,
        isSystemGenerated: true,
      );
      final movementResult = await repository.saveFundMovement(
        movement: movement,
      );
      if (movementResult.isInvalid) {
        return movementResult;
      }
    }

    if (LiquidationRules.createsReimbursementClaim(command.fundingMode)) {
      for (final line in lines) {
        final claimResult = await repository.saveReimbursementClaim(
          ReimbursementClaim(
            id: idGenerator.nextId('claim'),
            eventId: command.eventId,
            officerId: command.accountableOfficerId,
            amount: line.total,
            status: ReimbursementStatus.pending,
            sourceLiquidationLineId: line.id,
          ),
        );
        if (claimResult.isInvalid) {
          return claimResult;
        }
      }
    }

    await _appendAuditLog(
      action: 'liquidation.submit',
      targetRecordId: receipt.id,
      amount: total,
      reference: receipt.evidenceNumber,
      metadata: {
        'eventId': command.eventId,
        'fundingMode': command.fundingMode.name,
        'lineCount': lines.length,
      },
    );
    return const ValidationResult.valid();
  }

  Future<ValidationResult> payReimbursement(
    PayReimbursementCommand command,
  ) async {
    final claims = await repository.listReimbursementClaims();
    final claim = _claimById(claims, command.claimId);
    if (claim == null) {
      return ValidationResult.failure(
        'Selected reimbursement claim does not exist.',
      );
    }
    final events = await repository.listAuditEvents();
    final event = _eventById(events, claim.eventId);
    if (event == null) {
      return ValidationResult.failure(
        'Selected reimbursement event does not exist.',
      );
    }

    final validation = ReimbursementRules.validatePayment(
      claim: claim,
      approvedBudgetBalance: event.approvedBudgetBalance,
    );
    if (validation.isInvalid) {
      return validation;
    }

    final movementId = idGenerator.nextId('movement');
    final movement = FundMovement(
      id: movementId,
      reference: _movementReference(command.paymentDate, movementId),
      type: FundMovementType.reimbursementPayment,
      date: command.paymentDate,
      amount: claim.amount,
      purpose: 'Reimbursement payment: ${event.name}',
      remarks: command.remarks?.trim().isEmpty ?? true
          ? null
          : command.remarks!.trim(),
      eventId: event.id,
      holderOfficerId: claim.officerId,
      isSystemGenerated: true,
    );
    final movementResult = await repository.saveFundMovement(
      movement: movement,
    );
    if (movementResult.isInvalid) {
      return movementResult;
    }
    await repository.saveReimbursementClaim(
      ReimbursementClaim(
        id: claim.id,
        eventId: claim.eventId,
        officerId: claim.officerId,
        amount: claim.amount,
        status: ReimbursementStatus.paid,
        sourceLiquidationLineId: claim.sourceLiquidationLineId,
      ),
    );
    await repository.updateAuditEvent(
      _copyEvent(
        event,
        approvedBudgetBalance: event.approvedBudgetBalance - claim.amount,
      ),
    );
    await _appendAuditLog(
      action: 'reimbursement.pay',
      targetRecordId: claim.id,
      amount: claim.amount,
      reference: movement.reference,
      metadata: {'eventId': event.id, 'officerId': claim.officerId},
    );
    return const ValidationResult.valid();
  }

  Future<ValidationResult> markEventLiquidated(StableId eventId) async {
    final events = await repository.listAuditEvents();
    final event = _eventById(events, eventId);
    if (event == null) {
      return ValidationResult.failure('Selected event does not exist.');
    }
    final status = EventRules.calculateStatus(event: event, asOf: _now());
    if (status == AuditEventStatus.ongoing) {
      return ValidationResult.failure(
        'Only completed events can be marked liquidated.',
      );
    }
    if (status == AuditEventStatus.liquidated) {
      return ValidationResult.failure('Event is already liquidated.');
    }

    final receipts = await repository.listLiquidationReceipts();
    final hasReceipt = receipts.any((receipt) => receipt.eventId == eventId);
    if (!hasReceipt) {
      return ValidationResult.failure(
        'At least one liquidation receipt is required before marking liquidated.',
      );
    }
    final claims = await repository.listReimbursementClaims();
    final hasPendingClaim = claims.any(
      (claim) =>
          claim.eventId == eventId &&
          claim.status == ReimbursementStatus.pending,
    );
    if (hasPendingClaim) {
      return ValidationResult.failure(
        'Pending reimbursement claims must be paid before marking liquidated.',
      );
    }

    await repository.updateAuditEvent(_copyEvent(event, isLiquidated: true));
    await _appendAuditLog(
      action: 'events.mark_liquidated',
      targetRecordId: event.id,
      amount: event.approvedBudgetBalance,
      reference: event.resolutionNumber,
      metadata: {'eventName': event.name},
    );
    return const ValidationResult.valid();
  }

  ValidationResult _validateLiquidationCommand({
    required SubmitLiquidationCommand command,
    required AuditEvent? event,
    required AuditEventStatus? status,
    required Set<StableId> officerIds,
    required Money officerCustodyBalance,
  }) {
    final messages = <String>[];
    if (event == null) {
      messages.add('Selected event does not exist.');
    } else if (status == AuditEventStatus.liquidated) {
      messages.add('Liquidated events cannot receive new liquidation entries.');
    }
    if (command.payeeOrMerchant.trim().isEmpty) {
      messages.add('Payee or merchant is required.');
    }
    if (command.evidenceNumber.trim().isEmpty) {
      messages.add('Evidence number is required.');
    }
    if (!officerIds.contains(command.accountableOfficerId)) {
      messages.add('Select an accountable officer.');
    }
    final attachment = command.attachment;
    if (attachment == null) {
      messages.add('Liquidation receipt attachment is required.');
    } else {
      if (attachment.fileName.trim().isEmpty) {
        messages.add('Attachment file name is required.');
      }
      if (attachment.localPath.trim().isEmpty) {
        messages.add('Attachment local path is required.');
      }
    }
    if (command.lines.isEmpty) {
      messages.add('At least one liquidation line item is required.');
    }
    for (final line in command.lines) {
      if (line.description.trim().isEmpty) {
        messages.add('Line item description is required.');
      }
      if (line.quantity <= 0) {
        messages.add('Line item quantity must be greater than zero.');
      }
      if (!line.unitCost.isPositive) {
        messages.add('Line item unit cost must be greater than zero.');
      }
    }

    final total = _sumMoney(
      command.lines.map(
        (line) => Money.centavos(line.unitCost.centavos * line.quantity),
      ),
    );
    if (event != null &&
        command.fundingMode == FundingMode.releasedFunds &&
        total > officerCustodyBalance) {
      messages.add(
        'Released-funds liquidation is blocked because the selected accountable officer has insufficient held funds.',
      );
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

class SubmitLiquidationCommand {
  const SubmitLiquidationCommand({
    required this.eventId,
    required this.payeeOrMerchant,
    required this.date,
    required this.evidenceNumber,
    required this.receiptType,
    required this.fundingMode,
    required this.accountableOfficerId,
    required this.lines,
    this.attachment,
    this.remarks,
  });

  final StableId eventId;
  final String payeeOrMerchant;
  final DateTime date;
  final String evidenceNumber;
  final ReceiptType receiptType;
  final FundingMode fundingMode;
  final StableId accountableOfficerId;
  final AttachmentRef? attachment;
  final List<SubmitLiquidationLineDraft> lines;
  final String? remarks;
}

class SubmitLiquidationLineDraft {
  const SubmitLiquidationLineDraft({
    required this.description,
    required this.quantity,
    required this.unitCost,
  });

  final String description;
  final int quantity;
  final Money unitCost;

  Money get total => Money.centavos(unitCost.centavos * quantity);
}

class PayReimbursementCommand {
  const PayReimbursementCommand({
    required this.claimId,
    required this.paymentDate,
    this.remarks,
  });

  final StableId claimId;
  final DateTime paymentDate;
  final String? remarks;
}

class CreateOfficerCommand {
  const CreateOfficerCommand({
    required this.fullName,
    this.position = OfficerPosition.member,
    this.committee,
  });

  final String fullName;
  final OfficerPosition position;
  final Committee? committee;
}

class LiquidationWorkspaceSnapshot {
  const LiquidationWorkspaceSnapshot({
    required this.events,
    required this.receipts,
    required this.reimbursementClaims,
    required this.officerOptions,
  });

  final List<LiquidationEventView> events;
  final List<LiquidationReceiptView> receipts;
  final List<ReimbursementClaimView> reimbursementClaims;
  final List<OfficerOption> officerOptions;
}

class LiquidationEventView {
  const LiquidationEventView({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.approvedBudgetBalance,
    required this.status,
    required this.receiptCount,
    required this.pendingClaimCount,
  });

  final StableId id;
  final String name;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final Money approvedBudgetBalance;
  final AuditEventStatus status;
  final int receiptCount;
  final int pendingClaimCount;

  bool get canSubmitLiquidation =>
      status == AuditEventStatus.ongoing ||
      status == AuditEventStatus.forLiquidation ||
      status == AuditEventStatus.due;
  String get statusLabel => auditEventStatusLabel(status);
  String get dateRangeLabel =>
      '${formatDate(startDate)} - ${formatDate(endDate)}';
  String get approvedBudgetBalanceLabel =>
      formatPhpMoney(approvedBudgetBalance);
}

class LiquidationReceiptView {
  const LiquidationReceiptView({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.payeeOrMerchant,
    required this.date,
    required this.evidenceNumber,
    required this.receiptType,
    required this.fundingMode,
    required this.accountableOfficerName,
    required this.total,
  });

  final StableId id;
  final StableId eventId;
  final String eventName;
  final String payeeOrMerchant;
  final DateTime date;
  final String evidenceNumber;
  final ReceiptType receiptType;
  final FundingMode fundingMode;
  final String accountableOfficerName;
  final Money total;

  String get dateLabel => formatDate(date);
  String get totalLabel => formatPhpMoney(total);
  String get receiptTypeLabel => receiptTypeDisplayLabel(receiptType);
  String get fundingModeLabel => fundingModeDisplayLabel(fundingMode);
}

class ReimbursementClaimView {
  const ReimbursementClaimView({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.officerName,
    required this.amount,
    required this.status,
    required this.approvedBudgetBalance,
    required this.projectedRemaining,
  });

  final StableId id;
  final StableId eventId;
  final String eventName;
  final String officerName;
  final Money amount;
  final ReimbursementStatus status;
  final Money approvedBudgetBalance;
  final Money projectedRemaining;

  bool get canPay => status == ReimbursementStatus.pending;
  bool get hasInsufficientBudget => amount > approvedBudgetBalance;
  String get amountLabel => formatPhpMoney(amount);
  String get approvedBudgetBalanceLabel =>
      formatPhpMoney(approvedBudgetBalance);
  String get projectedRemainingLabel => formatPhpMoney(projectedRemaining);
  String get statusLabel => reimbursementStatusDisplayLabel(status);
}

class OfficerOption {
  const OfficerOption({
    required this.id,
    required this.fullName,
    required this.position,
    this.fundCustodyBalance = Money.zero,
    this.committee,
  });

  final StableId id;
  final String fullName;
  final OfficerPosition position;
  final Committee? committee;
  final Money fundCustodyBalance;

  bool get hasFundCustody => fundCustodyBalance.isPositive;
  String get fundCustodyBalanceLabel => formatPhpMoney(fundCustodyBalance);
}

Money _officerCustodyBalance({
  required List<FundMovement> movements,
  required StableId officerId,
  StableId? eventId,
}) {
  var balance = Money.zero;
  for (final movement in movements) {
    if (movement.holderOfficerId != officerId) {
      continue;
    }
    if (eventId != null && movement.eventId != eventId) {
      continue;
    }
    switch (movement.type) {
      case FundMovementType.fundRelease:
        balance += movement.amount;
      case FundMovementType.liquidationSubmitted:
      case FundMovementType.returnRefund:
        balance -= movement.amount;
      case FundMovementType.addFund:
      case FundMovementType.budgetAllocation:
      case FundMovementType.budgetAdjustment:
      case FundMovementType.transfer:
      case FundMovementType.reimbursementPayment:
        break;
    }
  }
  return balance;
}

String receiptTypeDisplayLabel(ReceiptType type) {
  return switch (type) {
    ReceiptType.officialReceipt => 'Official Receipt',
    ReceiptType.reimbursementExpenseReceipt => 'Reimbursement Expense Receipt',
    ReceiptType.paymentAgreement => 'Payment Agreement',
    ReceiptType.acknowledgementReceipt => 'Acknowledgement Receipt',
    ReceiptType.salesInvoice => 'Sales Invoice',
  };
}

String fundingModeDisplayLabel(FundingMode mode) {
  return switch (mode) {
    FundingMode.releasedFunds => 'Released Funds',
    FundingMode.outOfPocket => 'Out of Pocket',
  };
}

String reimbursementStatusDisplayLabel(ReimbursementStatus status) {
  return switch (status) {
    ReimbursementStatus.pending => 'Pending',
    ReimbursementStatus.paid => 'Paid',
  };
}

AuditEvent? _eventById(List<AuditEvent> events, StableId id) {
  for (final event in events) {
    if (event.id == id) {
      return event;
    }
  }
  return null;
}

ReimbursementClaim? _claimById(List<ReimbursementClaim> claims, StableId id) {
  for (final claim in claims) {
    if (claim.id == id) {
      return claim;
    }
  }
  return null;
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
