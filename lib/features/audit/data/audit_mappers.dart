import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/domain/attachment_ref.dart';
import '../../../core/domain/money.dart';
import '../domain/audit_models.dart' as domain;
import 'audit_database.dart';

extension LocalAccountProfileMapper on domain.LocalAccountProfile {
  LocalAccountsCompanion toCompanion() {
    return LocalAccountsCompanion.insert(
      id: id,
      displayName: displayName,
      emailOrStudentId: emailOrStudentId,
      createdAt: createdAt,
      isCredentialConfigured: isCredentialConfigured,
    );
  }
}

extension LocalAccountRecordMapper on LocalAccountRecord {
  domain.LocalAccountProfile toDomain() {
    return domain.LocalAccountProfile(
      id: id,
      displayName: displayName,
      emailOrStudentId: emailOrStudentId,
      createdAt: createdAt,
      isCredentialConfigured: isCredentialConfigured,
    );
  }
}

extension OrganizationProfileMapper on domain.OrganizationProfile {
  OrganizationsCompanion toCompanion() {
    return OrganizationsCompanion.insert(
      id: id,
      name: name,
      type: type,
      adviser: adviser,
      semester: semester,
      schoolYear: schoolYear,
      signatoryNamesJson: jsonEncode({
        'treasurer': effectiveTreasurerSignatory,
        'auditor': effectiveAuditorSignatory,
        'head': effectiveHeadSignatory,
      }),
    );
  }
}

extension OrganizationRecordMapper on OrganizationRecord {
  domain.OrganizationProfile toDomain() {
    final signatories = _parseSignatories(signatoryNamesJson);
    return domain.OrganizationProfile(
      id: id,
      name: name,
      type: type,
      adviser: adviser,
      semester: semester,
      schoolYear: schoolYear,
      treasurerSignatory: signatories.treasurer,
      auditorSignatory: signatories.auditor,
      headSignatory: signatories.head,
    );
  }
}

extension OfficerMapper on domain.Officer {
  OfficersCompanion toCompanion() {
    return OfficersCompanion.insert(
      id: id,
      fullName: fullName,
      position: position.name,
      committee: Value(committee?.name),
      isArchived: Value(isArchived),
    );
  }
}

extension OfficerRecordMapper on OfficerRecord {
  domain.Officer toDomain() {
    return domain.Officer(
      id: id,
      fullName: fullName,
      position: _enumByName(domain.OfficerPosition.values, position),
      committee: _nullableEnumByName(domain.Committee.values, committee),
      isArchived: isArchived,
    );
  }
}

extension TreasuryFundSourceMapper on domain.TreasuryFundSource {
  TreasuryFundSourcesCompanion toCompanion() {
    return TreasuryFundSourcesCompanion.insert(
      id: id,
      type: type.name,
      label: label,
      balanceCentavos: balance.centavos,
      supportingAttachmentId: Value(supportingAttachment?.id),
      supportingAttachmentFileName: Value(supportingAttachment?.fileName),
      supportingAttachmentLocalPath: Value(supportingAttachment?.localPath),
      supportingAttachmentSizeBytes: Value(supportingAttachment?.sizeBytes),
      supportingAttachmentChecksum: Value(supportingAttachment?.checksum),
    );
  }
}

extension TreasuryFundSourceRecordMapper on TreasuryFundSourceRecord {
  domain.TreasuryFundSource toDomain() {
    return domain.TreasuryFundSource(
      id: id,
      type: _enumByName(domain.TreasuryFundSourceType.values, type),
      label: label,
      balance: Money.centavos(balanceCentavos),
      supportingAttachment: _nullableAttachment(
        id: supportingAttachmentId,
        fileName: supportingAttachmentFileName,
        localPath: supportingAttachmentLocalPath,
        sizeBytes: supportingAttachmentSizeBytes,
        checksum: supportingAttachmentChecksum,
      ),
    );
  }
}

extension AuditEventMapper on domain.AuditEvent {
  AuditEventsCompanion toCompanion() {
    return AuditEventsCompanion.insert(
      id: id,
      name: name,
      type: type,
      semester: semester,
      schoolYear: schoolYear,
      startDate: startDate,
      endDate: endDate,
      permitApprovalDate: Value(permitApprovalDate),
      resolutionNumber: resolutionNumber,
      budgetCentavos: budget.centavos,
      approvedBudgetBalanceCentavos: approvedBudgetBalance.centavos,
      resolutionAttachmentId: Value(resolutionAttachment?.id),
      resolutionAttachmentFileName: Value(resolutionAttachment?.fileName),
      resolutionAttachmentLocalPath: Value(resolutionAttachment?.localPath),
      resolutionAttachmentSizeBytes: Value(resolutionAttachment?.sizeBytes),
      resolutionAttachmentChecksum: Value(resolutionAttachment?.checksum),
      isLiquidated: Value(isLiquidated),
    );
  }
}

extension AuditEventRecordMapper on AuditEventRecord {
  domain.AuditEvent toDomain() {
    return domain.AuditEvent(
      id: id,
      name: name,
      type: type,
      semester: semester,
      schoolYear: schoolYear,
      startDate: startDate,
      endDate: endDate,
      permitApprovalDate: permitApprovalDate,
      resolutionNumber: resolutionNumber,
      budget: Money.centavos(budgetCentavos),
      approvedBudgetBalance: Money.centavos(approvedBudgetBalanceCentavos),
      resolutionAttachment: _nullableAttachment(
        id: resolutionAttachmentId,
        fileName: resolutionAttachmentFileName,
        localPath: resolutionAttachmentLocalPath,
        sizeBytes: resolutionAttachmentSizeBytes,
        checksum: resolutionAttachmentChecksum,
      ),
      isLiquidated: isLiquidated,
    );
  }
}

extension EventFundingAllocationMapper on domain.EventFundingAllocation {
  EventFundingAllocationsCompanion toCompanion() {
    return EventFundingAllocationsCompanion.insert(
      eventId: eventId,
      fundSourceId: fundSourceId,
      amountCentavos: amount.centavos,
    );
  }
}

extension EventFundingAllocationRecordMapper on EventFundingAllocationRecord {
  domain.EventFundingAllocation toDomain() {
    return domain.EventFundingAllocation(
      eventId: eventId,
      fundSourceId: fundSourceId,
      amount: Money.centavos(amountCentavos),
    );
  }
}

extension FundMovementMapper on domain.FundMovement {
  FundMovementsCompanion toCompanion() {
    return FundMovementsCompanion.insert(
      id: id,
      reference: reference,
      type: type.name,
      date: date,
      amountCentavos: amount.centavos,
      purpose: purpose,
      remarks: Value(remarks),
      eventId: Value(eventId),
      fromFundSourceId: Value(fromFundSourceId),
      toFundSourceId: Value(toFundSourceId),
      holderOfficerId: Value(holderOfficerId),
      isSystemGenerated: isSystemGenerated,
    );
  }
}

extension FundMovementRecordMapper on FundMovementRecord {
  domain.FundMovement toDomain() {
    return domain.FundMovement(
      id: id,
      reference: reference,
      type: _enumByName(domain.FundMovementType.values, type),
      date: date,
      amount: Money.centavos(amountCentavos),
      purpose: purpose,
      remarks: remarks,
      eventId: eventId,
      fromFundSourceId: fromFundSourceId,
      toFundSourceId: toFundSourceId,
      holderOfficerId: holderOfficerId,
      isSystemGenerated: isSystemGenerated,
    );
  }
}

extension LiquidationReceiptMapper on domain.LiquidationReceipt {
  LiquidationReceiptsCompanion toCompanion() {
    return LiquidationReceiptsCompanion.insert(
      id: id,
      eventId: eventId,
      payeeOrMerchant: payeeOrMerchant,
      date: date,
      evidenceNumber: evidenceNumber,
      receiptType: receiptType.name,
      fundingMode: fundingMode.name,
      accountableOfficerId: accountableOfficerId,
      attachmentId: attachment.id,
      attachmentFileName: attachment.fileName,
      attachmentLocalPath: attachment.localPath,
      attachmentSizeBytes: Value(attachment.sizeBytes),
      attachmentChecksum: Value(attachment.checksum),
    );
  }
}

extension LiquidationReceiptRecordMapper on LiquidationReceiptRecord {
  domain.LiquidationReceipt toDomain() {
    return domain.LiquidationReceipt(
      id: id,
      eventId: eventId,
      payeeOrMerchant: payeeOrMerchant,
      date: date,
      evidenceNumber: evidenceNumber,
      receiptType: _enumByName(domain.ReceiptType.values, receiptType),
      fundingMode: _enumByName(domain.FundingMode.values, fundingMode),
      accountableOfficerId: accountableOfficerId,
      attachment: AttachmentRef(
        id: attachmentId,
        fileName: attachmentFileName,
        localPath: attachmentLocalPath,
        sizeBytes: attachmentSizeBytes,
        checksum: attachmentChecksum,
      ),
    );
  }
}

extension LiquidationLineMapper on domain.LiquidationLine {
  LiquidationLinesCompanion toCompanion() {
    return LiquidationLinesCompanion.insert(
      id: id,
      receiptId: receiptId,
      description: description,
      quantity: quantity,
      unitCostCentavos: unitCost.centavos,
    );
  }
}

extension LiquidationLineRecordMapper on LiquidationLineRecord {
  domain.LiquidationLine toDomain() {
    return domain.LiquidationLine(
      id: id,
      receiptId: receiptId,
      description: description,
      quantity: quantity,
      unitCost: Money.centavos(unitCostCentavos),
    );
  }
}

extension ReimbursementClaimMapper on domain.ReimbursementClaim {
  ReimbursementClaimsCompanion toCompanion() {
    return ReimbursementClaimsCompanion.insert(
      id: id,
      eventId: eventId,
      officerId: officerId,
      amountCentavos: amount.centavos,
      status: status.name,
      sourceLiquidationLineId: sourceLiquidationLineId,
    );
  }
}

extension ReimbursementClaimRecordMapper on ReimbursementClaimRecord {
  domain.ReimbursementClaim toDomain() {
    return domain.ReimbursementClaim(
      id: id,
      eventId: eventId,
      officerId: officerId,
      amount: Money.centavos(amountCentavos),
      status: _enumByName(domain.ReimbursementStatus.values, status),
      sourceLiquidationLineId: sourceLiquidationLineId,
    );
  }
}

extension AuditorReviewSnapshotMapper on domain.AuditorReviewSnapshot {
  AuditorReviewsCompanion toCompanion() {
    return AuditorReviewsCompanion.insert(
      id: id,
      eventId: eventId,
      findings: findings,
      cause: cause,
      recommendation: recommendation,
      budgetCentavos: budget.centavos,
      actualCentavos: actual.centavos,
      varianceCentavos: variance.centavos,
      utilizationBasisPoints: utilizationBasisPoints,
      health: health.name,
      createdAt: createdAt,
    );
  }
}

extension AuditorReviewRecordMapper on AuditorReviewRecord {
  domain.AuditorReviewSnapshot toDomain() {
    return domain.AuditorReviewSnapshot(
      id: id,
      eventId: eventId,
      findings: findings,
      cause: cause,
      recommendation: recommendation,
      budget: Money.centavos(budgetCentavos),
      actual: Money.centavos(actualCentavos),
      variance: Money.centavos(varianceCentavos),
      utilizationBasisPoints: utilizationBasisPoints,
      health: _enumByName(domain.BudgetHealth.values, health),
      createdAt: createdAt,
    );
  }
}

extension AuditLogEntryMapper on domain.AuditLogEntry {
  AuditLogEntriesCompanion toCompanion() {
    return AuditLogEntriesCompanion.insert(
      id: id,
      action: action,
      actor: actor,
      targetRecordId: targetRecordId,
      occurredAt: occurredAt,
      amountCentavos: Value(amount?.centavos),
      reference: Value(reference),
      beforeSnapshotJson: Value(_encodeNullableObject(beforeSnapshot)),
      afterSnapshotJson: Value(_encodeNullableObject(afterSnapshot)),
      metadataJson: Value(jsonEncode(metadata)),
    );
  }
}

extension AuditLogRecordMapper on AuditLogRecord {
  domain.AuditLogEntry toDomain() {
    return domain.AuditLogEntry(
      id: id,
      action: action,
      actor: actor,
      targetRecordId: targetRecordId,
      occurredAt: occurredAt,
      amount: amountCentavos == null ? null : Money.centavos(amountCentavos!),
      reference: reference,
      beforeSnapshot: _decodeNullableObject(beforeSnapshotJson),
      afterSnapshot: _decodeNullableObject(afterSnapshotJson),
      metadata: _decodeObject(metadataJson) ?? const {},
    );
  }
}

extension ExportHistoryEntryMapper on domain.ExportHistoryEntry {
  ExportHistoryEntriesCompanion toCompanion() {
    return ExportHistoryEntriesCompanion.insert(
      id: id,
      fileName: fileName,
      generatedAt: generatedAt,
      byteLength: byteLength,
      checksum: checksum,
      destinationUri: Value(destinationUri),
      status: status.name,
      backupReminderStatus: backupReminderStatus.name,
      sameDayBackupFound: sameDayBackupFound,
      blockerCount: blockerCount,
      warningCount: warningCount,
      createdAt: createdAt,
      errorMessage: Value(errorMessage),
    );
  }
}

extension ExportHistoryRecordMapper on ExportHistoryRecord {
  domain.ExportHistoryEntry toDomain() {
    return domain.ExportHistoryEntry(
      id: id,
      fileName: fileName,
      generatedAt: generatedAt,
      byteLength: byteLength,
      checksum: checksum,
      destinationUri: destinationUri,
      status: _enumByName(domain.ExportHistoryStatus.values, status),
      backupReminderStatus: _enumByName(
        domain.BackupReminderStatus.values,
        backupReminderStatus,
      ),
      sameDayBackupFound: sameDayBackupFound,
      blockerCount: blockerCount,
      warningCount: warningCount,
      createdAt: createdAt,
      errorMessage: errorMessage,
    );
  }
}

extension BackupHistoryEntryMapper on domain.BackupHistoryEntry {
  BackupHistoryEntriesCompanion toCompanion() {
    return BackupHistoryEntriesCompanion.insert(
      id: id,
      fileName: fileName,
      generatedAt: generatedAt,
      byteLength: byteLength,
      checksum: checksum,
      destinationUri: Value(destinationUri),
      status: status.name,
      createdAt: createdAt,
      errorMessage: Value(errorMessage),
    );
  }
}

extension BackupHistoryRecordMapper on BackupHistoryRecord {
  domain.BackupHistoryEntry toDomain() {
    return domain.BackupHistoryEntry(
      id: id,
      fileName: fileName,
      generatedAt: generatedAt,
      byteLength: byteLength,
      checksum: checksum,
      destinationUri: destinationUri,
      status: _enumByName(domain.BackupHistoryStatus.values, status),
      createdAt: createdAt,
      errorMessage: errorMessage,
    );
  }
}

String? _encodeNullableObject(Map<String, Object?>? value) {
  return value == null ? null : jsonEncode(value);
}

Map<String, Object?>? _decodeNullableObject(String? value) {
  return value == null ? null : _decodeObject(value);
}

Map<String, Object?>? _decodeObject(String value) {
  final decoded = jsonDecode(value);
  if (decoded == null) {
    return null;
  }
  return (decoded as Map<String, dynamic>).cast<String, Object?>();
}

T _enumByName<T extends Enum>(List<T> values, String name) {
  return values.byName(name);
}

T? _nullableEnumByName<T extends Enum>(List<T> values, String? name) {
  return name == null ? null : values.byName(name);
}

AttachmentRef? _nullableAttachment({
  required String? id,
  required String? fileName,
  required String? localPath,
  required int? sizeBytes,
  required String? checksum,
}) {
  if (id == null || fileName == null || localPath == null) {
    return null;
  }
  return AttachmentRef(
    id: id,
    fileName: fileName,
    localPath: localPath,
    sizeBytes: sizeBytes,
    checksum: checksum,
  );
}

({String treasurer, String auditor, String head}) _parseSignatories(
  String value,
) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is List) {
      final names = decoded.map((e) => e?.toString() ?? '').toList();
      return (
        treasurer: names.isNotEmpty ? names[0].trim() : '',
        auditor: names.length > 1 ? names[1].trim() : '',
        head: names.length > 2 ? names[2].trim() : '',
      );
    }
    if (decoded is Map) {
      return (
        treasurer: (decoded['treasurer']?.toString() ?? '').trim(),
        auditor: (decoded['auditor']?.toString() ?? '').trim(),
        head: (decoded['head']?.toString() ?? '').trim(),
      );
    }
  } catch (_) {}
  return (treasurer: '', auditor: '', head: '');
}
