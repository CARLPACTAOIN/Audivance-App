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
    final sortedSources = [...sources]
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    final sortedMovements = [...movements]
      ..sort((a, b) => b.date.compareTo(a.date));

    return TreasurySnapshot(
      totalBalance: _sumMoney(sortedSources.map((source) => source.balance)),
      sources: sortedSources
          .map(
            (source) => TreasurySourceView(
              id: source.id,
              type: source.type,
              label: source.label,
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
    );
  }

  Future<ValidationResult> addFund(AddFundCommand command) async {
    final label = command.label.trim();
    final validation = ValidationResult.combine([
      TreasuryRules.validateAddFund(
        amount: command.amount,
        supportingAttachment: command.supportingAttachment,
      ),
      if (label.isEmpty)
        ValidationResult.failure('Treasury source label is required.'),
    ]);
    if (validation.isInvalid) {
      return validation;
    }

    final existingSource = await _sourceForAddFund(command.existingSourceId);
    final source = existingSource == null
        ? TreasuryFundSource(
            id: idGenerator.nextId('source'),
            type: command.type,
            label: label,
            balance: command.amount,
            supportingAttachment: command.supportingAttachment,
          )
        : TreasuryFundSource(
            id: existingSource.id,
            type: existingSource.type,
            label: existingSource.label,
            balance: existingSource.balance + command.amount,
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
    final byId = {for (final source in sources) source.id: source};
    final fromSource = command.fromFundSourceId == null
        ? null
        : byId[command.fromFundSourceId];
    final toSource = command.toFundSourceId == null
        ? null
        : byId[command.toFundSourceId];
    final availableBalance = fromSource?.balance ?? command.amount;

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
      fromFundSourceId: command.fromFundSourceId,
      toFundSourceId: command.toFundSourceId,
      holderOfficerId: command.holderOfficerId,
      isSystemGenerated: false,
    );
    final movementResult = await repository.saveFundMovement(
      movement: movement,
      availableBalance: availableBalance,
    );
    if (movementResult.isInvalid) {
      return movementResult;
    }

    if (fromSource != null) {
      await repository.updateTreasuryFundSource(
        TreasuryFundSource(
          id: fromSource.id,
          type: fromSource.type,
          label: fromSource.label,
          balance: fromSource.balance - command.amount,
          supportingAttachment: fromSource.supportingAttachment,
        ),
      );
    }
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

    await _appendAuditLog(
      action: 'treasury.manual_movement',
      targetRecordId: movement.id,
      amount: command.amount,
      reference: movement.reference,
      metadata: {
        'movementType': movement.type.name,
        'fromFundSourceId': movement.fromFundSourceId,
        'toFundSourceId': movement.toFundSourceId,
      },
    );
    return const ValidationResult.valid();
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

  Future<ValidationResult> _validateManualCommand(
    ManualFundMovementCommand command,
  ) async {
    final messages = <String>[];
    if (!FundMovementRules.manualTypes.contains(command.type)) {
      messages.add(
        'Manual fund movements are limited to Fund Release, Transfer, and Return / Refund.',
      );
    }
    if (command.purpose.trim().isEmpty) {
      messages.add('Fund movement purpose is required.');
    }

    final sources = await repository.listTreasuryFundSources();
    final sourceIds = sources.map((source) => source.id).toSet();
    final fromId = command.fromFundSourceId;
    final toId = command.toFundSourceId;

    switch (command.type) {
      case FundMovementType.fundRelease:
        if (fromId == null) {
          messages.add('Fund Release requires a source fund.');
        }
      case FundMovementType.transfer:
        if (fromId == null) {
          messages.add('Transfer requires a source fund.');
        }
        if (toId == null) {
          messages.add('Transfer requires a target fund.');
        }
        if (fromId != null && fromId == toId) {
          messages.add('Transfer source and target funds must be different.');
        }
      case FundMovementType.returnRefund:
        if (toId == null) {
          messages.add('Return / Refund requires a target fund.');
        }
      case FundMovementType.addFund:
      case FundMovementType.budgetAllocation:
      case FundMovementType.budgetAdjustment:
      case FundMovementType.liquidationSubmitted:
      case FundMovementType.reimbursementPayment:
        break;
    }

    if (fromId != null && !sourceIds.contains(fromId)) {
      messages.add('Selected source fund does not exist.');
    }
    if (toId != null && !sourceIds.contains(toId)) {
      messages.add('Selected target fund does not exist.');
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
    required this.label,
    required this.amount,
    required this.date,
    this.existingSourceId,
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
  });

  final FundMovementType type;
  final Money amount;
  final DateTime date;
  final String purpose;
  final String? remarks;
  final StableId? fromFundSourceId;
  final StableId? toFundSourceId;
  final StableId? holderOfficerId;
}

class TreasurySnapshot {
  const TreasurySnapshot({
    required this.totalBalance,
    required this.sources,
    required this.ledgerRows,
  });

  final Money totalBalance;
  final List<TreasurySourceView> sources;
  final List<TreasuryLedgerRow> ledgerRows;
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
