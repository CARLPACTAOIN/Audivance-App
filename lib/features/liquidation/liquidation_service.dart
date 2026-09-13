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
import 'domain/receipt_edit_models.dart';

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
                  .where(
                    (receipt) =>
                        receipt.eventId == event.id && !receipt.isVoided,
                  )
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
          .where((receipt) => !receipt.isVoided)
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
              accountableOfficerId: receipt.accountableOfficerId,
              accountableOfficerName:
                  officerById[receipt.accountableOfficerId]?.fullName ??
                  'Unknown officer',
              total: receiptTotals[receipt.id] ?? Money.zero,
              isVoided: receipt.isVoided,
              attachment: receipt.attachment,
              voidReason: receipt.voidReason,
              remarks: receipt.remarks,
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

    // Compute the funding split for this receipt.
    final total = _sumMoney(
      command.lines.map(
        (line) => Money.centavos(line.unitCost.centavos * line.quantity),
      ),
    );
    final FundingMode resolvedFundingMode;
    final Money releasedPortion;
    final Money oopPortion;

    if (command.fundingMode == FundingMode.releasedFunds) {
      if (officerCustodyBalance >= total) {
        // Full coverage from custody.
        resolvedFundingMode = FundingMode.releasedFunds;
        releasedPortion = total;
        oopPortion = Money.zero;
      } else if (officerCustodyBalance.isPositive) {
        // Partial coverage: auto-split into released + out-of-pocket.
        final split = FundMovementRules.computeMixedSplit(
          receiptTotal: total,
          officerCustody: officerCustodyBalance,
        );
        resolvedFundingMode = FundingMode.mixed;
        releasedPortion = split.released;
        oopPortion = split.outOfPocket;
      } else {
        // No custody at all: fully out-of-pocket.
        resolvedFundingMode = FundingMode.outOfPocket;
        releasedPortion = Money.zero;
        oopPortion = total;
      }
    } else {
      // Pure out-of-pocket (user's explicit choice).
      resolvedFundingMode = FundingMode.outOfPocket;
      releasedPortion = Money.zero;
      oopPortion = total;
    }

    final receipt = LiquidationReceipt(
      id: receiptId,
      eventId: command.eventId,
      payeeOrMerchant: command.payeeOrMerchant.trim(),
      date: command.date,
      evidenceNumber: command.evidenceNumber.trim(),
      receiptType: command.receiptType,
      fundingMode: resolvedFundingMode,
      accountableOfficerId: command.accountableOfficerId,
      attachment: command.attachment!,
      releasedFundsAmount: resolvedFundingMode == FundingMode.mixed
          ? releasedPortion
          : null,
      outOfPocketAmount: resolvedFundingMode == FundingMode.mixed
          ? oopPortion
          : null,
      remarks: command.remarks?.trim().isEmpty ?? true
          ? null
          : command.remarks!.trim(),
    );
    // Build lines.
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

    // Build optional liquidationSubmitted movement.
    FundMovement? submittedMovement;
    if (LiquidationRules.createsLiquidationSubmittedMovement(
      resolvedFundingMode,
    )) {
      final liquidationAmount = resolvedFundingMode == FundingMode.mixed
          ? releasedPortion
          : total;
      final movementId = idGenerator.nextId('movement');
      submittedMovement = FundMovement(
        id: movementId,
        reference: _movementReference(command.date, movementId),
        type: FundMovementType.liquidationSubmitted,
        date: command.date,
        amount: liquidationAmount,
        purpose: 'Liquidation submitted: ${event!.name}',
        eventId: event.id,
        holderOfficerId: command.accountableOfficerId,
        isSystemGenerated: true,
        sourceLiquidationReceiptId: receiptId,
      );
    }

    // Build optional reimbursement claims.
    final claims = <ReimbursementClaim>[];
    if (LiquidationRules.createsReimbursementClaim(resolvedFundingMode)) {
      if (resolvedFundingMode == FundingMode.mixed) {
        claims.add(
          ReimbursementClaim(
            id: idGenerator.nextId('claim'),
            eventId: command.eventId,
            officerId: command.accountableOfficerId,
            amount: oopPortion,
            status: ReimbursementStatus.pending,
            sourceLiquidationLineId: lines.first.id,
          ),
        );
      } else {
        for (final line in lines) {
          claims.add(
            ReimbursementClaim(
              id: idGenerator.nextId('claim'),
              eventId: command.eventId,
              officerId: command.accountableOfficerId,
              amount: line.total,
              status: ReimbursementStatus.pending,
              sourceLiquidationLineId: line.id,
            ),
          );
        }
      }
    }

    // Build audit log entry.
    final auditLog = AuditLogEntry(
      id: idGenerator.nextId('audit-log'),
      action: 'liquidation.post',
      actor: 'local-account',
      targetRecordId: receipt.id,
      occurredAt: _now(),
      amount: total,
      reference: receipt.evidenceNumber,
      afterSnapshot: receiptSnapshot(receipt, lines),
      metadata: {
        'eventId': command.eventId,
        'fundingMode': resolvedFundingMode.name,
        'lineCount': lines.length,
        if (resolvedFundingMode == FundingMode.mixed) ...{
          'releasedFundsAmount': releasedPortion.centavos,
          'outOfPocketAmount': oopPortion.centavos,
        },
      },
    );

    return repository.postReceiptAtomically(
      receipt: receipt,
      lines: lines,
      submittedMovement: submittedMovement,
      claims: claims,
      auditLog: auditLog,
    );
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

    // Allow released-funds mode even when officer custody is insufficient:
    // submitLiquidation auto-splits into mixed/outOfPocket as needed.
    // Only block if custody is zero AND mode is releasedFunds explicitly
    // (in that case, submitLiquidation will auto-switch to outOfPocket anyway,
    //  so no hard error needed here).
    return ValidationResult.invalid(messages);
  }

  /// Edits a posted receipt in place.
  ///
  /// Classifies the change as metadata or financial. Metadata edits update
  /// fields only; financial edits additionally reverse the old released-funds
  /// movement, recompute the split, create a new submitted movement, supersede
  /// pending claims, and create replacement claims. All changes are atomic.
  Future<ValidationResult> editReceipt(EditReceiptCommand command) async {
    final allReceipts = await repository.listLiquidationReceipts();
    final receipt = _receiptById(allReceipts, command.receiptId);
    if (receipt == null) {
      return ValidationResult.failure('Receipt not found.');
    }
    if (receipt.isVoided) {
      return ValidationResult.failure('Voided receipts cannot be edited.');
    }

    final events = await repository.listAuditEvents();
    final event = _eventById(events, receipt.eventId);
    if (event == null) {
      return ValidationResult.failure('Associated event not found.');
    }

    final allLines = await repository.listLiquidationLines();
    final beforeLines = allLines
        .where((l) => l.receiptId == receipt.id)
        .toList();

    // Build updated receipt with new fields.
    final correctionId = idGenerator.nextId('correction');
    final updatedReceipt = LiquidationReceipt(
      id: receipt.id,
      eventId: command.eventId ?? receipt.eventId,
      payeeOrMerchant:
          command.payeeOrMerchant?.trim() ?? receipt.payeeOrMerchant,
      date: command.date ?? receipt.date,
      evidenceNumber: command.evidenceNumber?.trim() ?? receipt.evidenceNumber,
      receiptType: command.receiptType ?? receipt.receiptType,
      fundingMode: command.fundingMode ?? receipt.fundingMode,
      accountableOfficerId:
          command.accountableOfficerId ?? receipt.accountableOfficerId,
      attachment: command.attachment ?? receipt.attachment,
      remarks: command.remarks != null
          ? (command.remarks!.trim().isEmpty ? null : command.remarks!.trim())
          : receipt.remarks,
      isVoided: false,
    );

    // Build updated lines (keep existing IDs for unchanged lines).
    final updatedLines = <LiquidationLine>[];
    final lineIdsToDelete = <StableId>[];
    if (command.lines != null) {
      final commandLines = command.lines!;
      // Delete lines that are no longer in the command.
      for (final bl in beforeLines) {
        final inCommand = commandLines.any((cl) => cl.existingLineId == bl.id);
        if (!inCommand) lineIdsToDelete.add(bl.id);
      }
      for (final cl in commandLines) {
        updatedLines.add(
          LiquidationLine(
            id: cl.existingLineId ?? idGenerator.nextId('line'),
            receiptId: receipt.id,
            description: cl.description.trim(),
            quantity: cl.quantity,
            unitCost: cl.unitCost,
          ),
        );
      }
    } else {
      updatedLines.addAll(beforeLines);
    }

    final afterTotal = _sumMoney(updatedLines.map((l) => l.total));

    // Classify.
    final classification = LiquidationRules.classifyEdit(
      before: receipt,
      beforeLines: beforeLines,
      after: updatedReceipt,
      afterLines: updatedLines,
    );

    // Validate eligibility.
    final allClaims = await repository.listReimbursementClaims();
    final eligibilityResult = LiquidationRules.validateEdit(
      classification: classification,
      receipt: receipt,
      event: event,
      allClaims: allClaims,
      receiptLines: beforeLines,
    );
    if (eligibilityResult.isInvalid) return eligibilityResult;

    // Build snapshots.
    final beforeSnap = receiptSnapshot(receipt, beforeLines);
    final afterSnap = receiptSnapshot(updatedReceipt, updatedLines);

    FundMovement? reversalMovement;
    FundMovement? newSubmittedMovement;
    final claimsToSupersede = <ReimbursementClaim>[];
    final replacementClaims = <ReimbursementClaim>[];

    if (classification == ReceiptEditClassification.financial) {
      final movements = await repository.listFundMovements();

      // 1. Reverse original released portion.
      final originalReleased =
          receipt.releasedFundsAmount ??
          (receipt.fundingMode == FundingMode.releasedFunds
              ? _sumMoney(beforeLines.map((l) => l.total))
              : Money.zero);
      if (originalReleased.isPositive) {
        final reversalId = idGenerator.nextId('movement');
        reversalMovement = FundMovement(
          id: reversalId,
          reference: _movementReference(_now(), reversalId),
          type: FundMovementType.liquidationReversal,
          date: _now(),
          amount: originalReleased,
          purpose: 'Liquidation reversal (edit): ${event.name}',
          eventId: event.id,
          holderOfficerId: receipt.accountableOfficerId,
          isSystemGenerated: true,
          sourceLiquidationReceiptId: receipt.id,
          correctionId: correctionId,
        );
      }

      // 2. Recompute split using custody AFTER the reversal.
      final custodyAfterReversal =
          _officerCustodyBalance(
            movements: movements,
            officerId: updatedReceipt.accountableOfficerId,
            eventId: updatedReceipt.eventId,
          ) +
          (reversalMovement?.amount ?? Money.zero);

      final FundingMode resolvedMode;
      final Money releasedPortion;
      final Money oopPortion;

      if (updatedReceipt.fundingMode == FundingMode.releasedFunds) {
        if (custodyAfterReversal >= afterTotal) {
          resolvedMode = FundingMode.releasedFunds;
          releasedPortion = afterTotal;
          oopPortion = Money.zero;
        } else if (custodyAfterReversal.isPositive) {
          final split = FundMovementRules.computeMixedSplit(
            receiptTotal: afterTotal,
            officerCustody: custodyAfterReversal,
          );
          resolvedMode = FundingMode.mixed;
          releasedPortion = split.released;
          oopPortion = split.outOfPocket;
        } else {
          resolvedMode = FundingMode.outOfPocket;
          releasedPortion = Money.zero;
          oopPortion = afterTotal;
        }
      } else {
        resolvedMode = FundingMode.outOfPocket;
        releasedPortion = Money.zero;
        oopPortion = afterTotal;
      }

      // Update receipt funding fields.
      final finalReceipt = LiquidationReceipt(
        id: updatedReceipt.id,
        eventId: updatedReceipt.eventId,
        payeeOrMerchant: updatedReceipt.payeeOrMerchant,
        date: updatedReceipt.date,
        evidenceNumber: updatedReceipt.evidenceNumber,
        receiptType: updatedReceipt.receiptType,
        fundingMode: resolvedMode,
        accountableOfficerId: updatedReceipt.accountableOfficerId,
        attachment: updatedReceipt.attachment,
        releasedFundsAmount: resolvedMode == FundingMode.mixed
            ? releasedPortion
            : null,
        outOfPocketAmount: resolvedMode == FundingMode.mixed
            ? oopPortion
            : null,
        remarks: updatedReceipt.remarks,
      );

      // 3. New submitted movement.
      if (LiquidationRules.createsLiquidationSubmittedMovement(resolvedMode)) {
        final liquidationAmount = resolvedMode == FundingMode.mixed
            ? releasedPortion
            : afterTotal;
        final newMovId = idGenerator.nextId('movement');
        newSubmittedMovement = FundMovement(
          id: newMovId,
          reference: _movementReference(_now(), newMovId),
          type: FundMovementType.liquidationSubmitted,
          date: _now(),
          amount: liquidationAmount,
          purpose: 'Liquidation resubmitted (edit): ${event.name}',
          eventId: event.id,
          holderOfficerId: updatedReceipt.accountableOfficerId,
          isSystemGenerated: true,
          sourceLiquidationReceiptId: receipt.id,
          correctionId: correctionId,
        );
      }

      // 4. Supersede pending claims.
      final lineIds = beforeLines.map((l) => l.id).toSet();
      for (final claim in allClaims) {
        if (lineIds.contains(claim.sourceLiquidationLineId) &&
            claim.status == ReimbursementStatus.pending) {
          claimsToSupersede.add(
            ReimbursementClaim(
              id: claim.id,
              eventId: claim.eventId,
              officerId: claim.officerId,
              amount: claim.amount,
              status: ReimbursementStatus.superseded,
              sourceLiquidationLineId: claim.sourceLiquidationLineId,
              correctionId: correctionId,
            ),
          );
        }
      }

      // 5. Create replacement claims.
      if (LiquidationRules.createsReimbursementClaim(resolvedMode)) {
        if (resolvedMode == FundingMode.mixed) {
          replacementClaims.add(
            ReimbursementClaim(
              id: idGenerator.nextId('claim'),
              eventId: updatedReceipt.eventId,
              officerId: updatedReceipt.accountableOfficerId,
              amount: oopPortion,
              status: ReimbursementStatus.pending,
              sourceLiquidationLineId: updatedLines.first.id,
              correctionId: correctionId,
            ),
          );
        } else {
          for (final line in updatedLines) {
            replacementClaims.add(
              ReimbursementClaim(
                id: idGenerator.nextId('claim'),
                eventId: updatedReceipt.eventId,
                officerId: updatedReceipt.accountableOfficerId,
                amount: line.total,
                status: ReimbursementStatus.pending,
                sourceLiquidationLineId: line.id,
                correctionId: correctionId,
              ),
            );
          }
        }
      }

      final auditLog = AuditLogEntry(
        id: idGenerator.nextId('audit-log'),
        action: 'liquidation.edit',
        actor: 'local-account',
        targetRecordId: receipt.id,
        occurredAt: _now(),
        amount: afterTotal,
        reference: finalReceipt.evidenceNumber,
        beforeSnapshot: beforeSnap,
        afterSnapshot: receiptSnapshot(finalReceipt, updatedLines),
        metadata: {
          'correctionId': correctionId,
          'classification': classification.name,
          'reversalAmount': originalReleased.centavos,
          'newReleasedAmount': releasedPortion.centavos,
          'newOopAmount': oopPortion.centavos,
        },
      );

      return repository.editReceiptAtomically(
        updatedReceipt: finalReceipt,
        updatedLines: updatedLines,
        lineIdsToDelete: lineIdsToDelete,
        reversalMovement: reversalMovement,
        newSubmittedMovement: newSubmittedMovement,
        claimsToSupersede: claimsToSupersede,
        replacementClaims: replacementClaims,
        auditLog: auditLog,
      );
    } else {
      // Metadata-only edit.
      final auditLog = AuditLogEntry(
        id: idGenerator.nextId('audit-log'),
        action: 'liquidation.edit',
        actor: 'local-account',
        targetRecordId: receipt.id,
        occurredAt: _now(),
        amount: afterTotal,
        reference: updatedReceipt.evidenceNumber,
        beforeSnapshot: beforeSnap,
        afterSnapshot: afterSnap,
        metadata: {
          'correctionId': correctionId,
          'classification': classification.name,
        },
      );

      return repository.editReceiptAtomically(
        updatedReceipt: updatedReceipt,
        updatedLines: updatedLines,
        lineIdsToDelete: lineIdsToDelete,
        auditLog: auditLog,
      );
    }
  }

  /// Voids a posted receipt, reversing released funds and superseding claims.
  Future<ValidationResult> voidReceipt(VoidReceiptCommand command) async {
    final allReceipts = await repository.listLiquidationReceipts();
    final receipt = _receiptById(allReceipts, command.receiptId);
    if (receipt == null) {
      return ValidationResult.failure('Receipt not found.');
    }

    final events = await repository.listAuditEvents();
    final event = _eventById(events, receipt.eventId);
    if (event == null) {
      return ValidationResult.failure('Associated event not found.');
    }

    final allLines = await repository.listLiquidationLines();
    final receiptLines = allLines
        .where((l) => l.receiptId == receipt.id)
        .toList();
    final allClaims = await repository.listReimbursementClaims();

    final eligibilityResult = LiquidationRules.validateVoid(
      receipt: receipt,
      event: event,
      allClaims: allClaims,
      receiptLines: receiptLines,
    );
    if (eligibilityResult.isInvalid) return eligibilityResult;

    if (command.reason.trim().isEmpty) {
      return ValidationResult.failure('A void reason is required.');
    }

    final correctionId = idGenerator.nextId('correction');
    final now = _now();

    // Mark receipt voided.
    final voidedReceipt = LiquidationReceipt(
      id: receipt.id,
      eventId: receipt.eventId,
      payeeOrMerchant: receipt.payeeOrMerchant,
      date: receipt.date,
      evidenceNumber: receipt.evidenceNumber,
      receiptType: receipt.receiptType,
      fundingMode: receipt.fundingMode,
      accountableOfficerId: receipt.accountableOfficerId,
      attachment: receipt.attachment,
      releasedFundsAmount: receipt.releasedFundsAmount,
      outOfPocketAmount: receipt.outOfPocketAmount,
      remarks: receipt.remarks,
      isVoided: true,
      voidedAt: now,
      voidReason: command.reason.trim(),
    );

    // Reversal movement for the released portion.
    FundMovement? reversalMovement;
    final originalReleased =
        receipt.releasedFundsAmount ??
        (receipt.fundingMode == FundingMode.releasedFunds
            ? _sumMoney(receiptLines.map((l) => l.total))
            : Money.zero);
    if (originalReleased.isPositive) {
      final reversalId = idGenerator.nextId('movement');
      reversalMovement = FundMovement(
        id: reversalId,
        reference: _movementReference(now, reversalId),
        type: FundMovementType.liquidationReversal,
        date: now,
        amount: originalReleased,
        purpose: 'Liquidation reversal (void): ${event.name}',
        eventId: event.id,
        holderOfficerId: receipt.accountableOfficerId,
        isSystemGenerated: true,
        sourceLiquidationReceiptId: receipt.id,
        correctionId: correctionId,
      );
    }

    // Supersede pending claims.
    final lineIds = receiptLines.map((l) => l.id).toSet();
    final claimsToSupersede = allClaims
        .where(
          (c) =>
              lineIds.contains(c.sourceLiquidationLineId) &&
              c.status == ReimbursementStatus.pending,
        )
        .map(
          (c) => ReimbursementClaim(
            id: c.id,
            eventId: c.eventId,
            officerId: c.officerId,
            amount: c.amount,
            status: ReimbursementStatus.superseded,
            sourceLiquidationLineId: c.sourceLiquidationLineId,
            correctionId: correctionId,
          ),
        )
        .toList();

    final auditLog = AuditLogEntry(
      id: idGenerator.nextId('audit-log'),
      action: 'liquidation.void',
      actor: 'local-account',
      targetRecordId: receipt.id,
      occurredAt: now,
      amount: _sumMoney(receiptLines.map((l) => l.total)),
      reference: receipt.evidenceNumber,
      beforeSnapshot: receiptSnapshot(receipt, receiptLines),
      metadata: {
        'correctionId': correctionId,
        'reason': command.reason.trim(),
        if (reversalMovement != null)
          'reversalAmount': originalReleased.centavos,
        'supersededClaimCount': claimsToSupersede.length,
      },
    );

    return repository.voidReceiptAtomically(
      voidedReceipt: voidedReceipt,
      reversalMovement: reversalMovement,
      claimsToSupersede: claimsToSupersede,
      auditLog: auditLog,
    );
  }

  /// Returns the audit-log edit history for a specific receipt, newest last.
  Future<List<AuditLogEntry>> loadReceiptEditHistory(StableId receiptId) {
    return repository.listAuditLogsForReceipt(receiptId);
  }

  /// Returns the line items belonging to [receiptId].
  Future<List<LiquidationLine>> loadReceiptLines(StableId receiptId) async {
    final allLines = await repository.listLiquidationLines();
    return allLines.where((line) => line.receiptId == receiptId).toList();
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

/// Command for editing an existing posted receipt.
class EditReceiptCommand {
  const EditReceiptCommand({
    required this.receiptId,
    this.eventId,
    this.payeeOrMerchant,
    this.date,
    this.evidenceNumber,
    this.receiptType,
    this.fundingMode,
    this.accountableOfficerId,
    this.attachment,
    this.remarks,
    this.lines,
  });

  final StableId receiptId;
  final StableId? eventId;
  final String? payeeOrMerchant;
  final DateTime? date;
  final String? evidenceNumber;
  final ReceiptType? receiptType;
  final FundingMode? fundingMode;
  final StableId? accountableOfficerId;
  final AttachmentRef? attachment;
  final String? remarks;

  /// Null means keep existing lines unchanged.
  final List<EditReceiptLineDraft>? lines;
}

/// A line item within an [EditReceiptCommand].
class EditReceiptLineDraft {
  const EditReceiptLineDraft({
    required this.description,
    required this.quantity,
    required this.unitCost,
    this.existingLineId,
  });

  /// When non-null, the existing line is updated in place.
  /// When null, a new line is created.
  final StableId? existingLineId;
  final String description;
  final int quantity;
  final Money unitCost;

  Money get total => Money.centavos(unitCost.centavos * quantity);
}

/// Command for voiding a posted receipt.
class VoidReceiptCommand {
  const VoidReceiptCommand({required this.receiptId, required this.reason});

  final StableId receiptId;
  final String reason;
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
    required this.isVoided,
    this.accountableOfficerId = '',
    this.attachment,
    this.voidReason,
    this.remarks,
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
  final StableId accountableOfficerId;
  final Money total;
  final AttachmentRef? attachment;
  final bool isVoided;
  final String? voidReason;
  final String? remarks;

  String get dateLabel => formatDate(date);
  String get totalLabel => formatPhpMoney(total);
  String get receiptTypeLabel => receiptTypeDisplayLabel(receiptType);
  String get fundingModeLabel => fundingModeDisplayLabel(fundingMode);
  String get statusLabel => isVoided ? 'Voided' : 'Posted';
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
  return OfficerRules.calculateOfficerCustodyBalance(
    movements: movements,
    officerId: officerId,
    eventId: eventId,
  );
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
    FundingMode.mixed => 'Mixed (Auto-split)',
  };
}

String reimbursementStatusDisplayLabel(ReimbursementStatus status) {
  return switch (status) {
    ReimbursementStatus.pending => 'Pending',
    ReimbursementStatus.paid => 'Paid',
    ReimbursementStatus.superseded => 'Superseded',
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

LiquidationReceipt? _receiptById(
  List<LiquidationReceipt> receipts,
  StableId id,
) {
  for (final receipt in receipts) {
    if (receipt.id == id) {
      return receipt;
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
