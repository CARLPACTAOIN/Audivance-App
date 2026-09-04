import '../../core/domain/identity.dart';
import '../../core/domain/stable_id_generator.dart';
import '../../core/domain/validation_result.dart';
import '../audit/data/audit_repository.dart';
import '../audit/domain/audit_models.dart';
import '../audit/domain/audit_rules.dart';

class OrganizationService {
  OrganizationService({
    required this.repository,
    required this.idGenerator,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuditRepository repository;
  final StableIdGenerator idGenerator;
  final DateTime Function() _now;

  Future<OrganizationWorkspaceSnapshot> loadSnapshot() async {
    final organizations = await repository.listOrganizations();
    final officers = await repository.listOfficers();
    final organization = organizations.isEmpty ? null : organizations.first;
    final sortedOfficers = [...officers]
      ..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
    final activeOfficers = sortedOfficers
        .where((officer) => !officer.isArchived)
        .map(OfficerRowView.fromOfficer)
        .toList(growable: false);
    final archivedOfficers = sortedOfficers
        .where((officer) => officer.isArchived)
        .map(OfficerRowView.fromOfficer)
        .toList(growable: false);

    return OrganizationWorkspaceSnapshot(
      organization: organization,
      activeOfficers: activeOfficers,
      archivedOfficers: archivedOfficers,
      committeeSummaries: [
        _committeeSummary(Committee.finance, sortedOfficers),
        _committeeSummary(Committee.audit, sortedOfficers),
      ],
      readinessHints: _readinessHints(organization, activeOfficers),
    );
  }

  Future<ValidationResult> updateOrganization(
    UpdateOrganizationCommand command,
  ) async {
    final validation = _validateOrganization(command);
    if (validation.isInvalid) {
      return validation;
    }

    final organizations = await repository.listOrganizations();
    final existing = organizations.isEmpty ? null : organizations.first;
    final organization = OrganizationProfile(
      id: existing?.id ?? idGenerator.nextId('organization'),
      name: command.name.trim(),
      type: command.type.trim(),
      adviser: command.adviser.trim(),
      semester: command.semester.trim(),
      schoolYear: command.schoolYear.trim(),
      treasurerSignatory: command.effectiveTreasurerSignatory,
      auditorSignatory: command.effectiveAuditorSignatory,
      headSignatory: command.effectiveHeadSignatory,
    );

    await repository.saveOrganization(organization);
    await _appendAuditLog(
      action: existing == null ? 'organization.create' : 'organization.update',
      targetRecordId: organization.id,
      reference: organization.name,
      beforeSnapshot: existing == null ? null : _organizationSnapshot(existing),
      afterSnapshot: _organizationSnapshot(organization),
    );
    return const ValidationResult.valid();
  }

  Future<ValidationResult> saveOfficer(SaveOfficerCommand command) async {
    final name = command.fullName.trim();
    if (name.isEmpty) {
      return ValidationResult.failure('Officer name is required.');
    }

    final officers = await repository.listOfficers();
    final existing = _officerById(officers, command.id);
    final officer = Officer(
      id: existing?.id ?? command.id ?? idGenerator.nextId('officer'),
      fullName: name,
      position: command.position,
      committee: command.committee,
      isArchived: existing?.isArchived ?? false,
    );
    final result = await repository.saveOfficers([officer]);
    if (result.isInvalid) {
      return result;
    }

    await _appendAuditLog(
      action: existing == null ? 'officer.create' : 'officer.update',
      targetRecordId: officer.id,
      reference: officer.fullName,
      beforeSnapshot: existing == null ? null : _officerSnapshot(existing),
      afterSnapshot: _officerSnapshot(officer),
    );
    return const ValidationResult.valid();
  }

  Future<ValidationResult> setOfficerArchived({
    required StableId officerId,
    required bool isArchived,
  }) async {
    final officers = await repository.listOfficers();
    final existing = _officerById(officers, officerId);
    if (existing == null) {
      return ValidationResult.failure('Selected officer does not exist.');
    }
    if (existing.isArchived == isArchived) {
      return const ValidationResult.valid();
    }

    final updated = Officer(
      id: existing.id,
      fullName: existing.fullName,
      position: existing.position,
      committee: existing.committee,
      isArchived: isArchived,
    );
    final result = await repository.saveOfficers([updated]);
    if (result.isInvalid) {
      return result;
    }

    await _appendAuditLog(
      action: isArchived ? 'officer.archive' : 'officer.restore',
      targetRecordId: updated.id,
      reference: updated.fullName,
      beforeSnapshot: _officerSnapshot(existing),
      afterSnapshot: _officerSnapshot(updated),
    );
    return const ValidationResult.valid();
  }

  Future<void> _appendAuditLog({
    required String action,
    required StableId targetRecordId,
    required String reference,
    Map<String, Object?>? beforeSnapshot,
    Map<String, Object?>? afterSnapshot,
  }) {
    return repository.appendAuditLog(
      AuditLogEntry(
        id: idGenerator.nextId('audit-log'),
        action: action,
        actor: 'local-account',
        targetRecordId: targetRecordId,
        occurredAt: _now(),
        reference: reference,
        beforeSnapshot: beforeSnapshot,
        afterSnapshot: afterSnapshot,
      ),
    );
  }
}

class UpdateOrganizationCommand {
  const UpdateOrganizationCommand({
    required this.name,
    required this.type,
    required this.adviser,
    required this.semester,
    required this.schoolYear,
    this.treasurerSignatory = '',
    this.auditorSignatory = '',
    this.headSignatory = '',
    String? signatoryNamesText,
  }) : _legacySignatoryNamesText = signatoryNamesText;

  final String name;
  final String type;
  final String adviser;
  final String semester;
  final String schoolYear;
  final String treasurerSignatory;
  final String auditorSignatory;
  final String headSignatory;
  final String? _legacySignatoryNamesText;

  String get effectiveTreasurerSignatory {
    if (treasurerSignatory.trim().isNotEmpty) return treasurerSignatory.trim();
    final legacy = _legacyList;
    return legacy.isNotEmpty ? legacy[0] : '';
  }

  String get effectiveAuditorSignatory {
    if (auditorSignatory.trim().isNotEmpty) return auditorSignatory.trim();
    final legacy = _legacyList;
    return legacy.length > 1 ? legacy[1] : '';
  }

  String get effectiveHeadSignatory {
    if (headSignatory.trim().isNotEmpty) return headSignatory.trim();
    final legacy = _legacyList;
    return legacy.length > 2 ? legacy[2] : '';
  }

  List<String> get _legacyList {
    if (_legacySignatoryNamesText == null ||
        _legacySignatoryNamesText.trim().isEmpty) {
      return const [];
    }
    return parseSignatoryNames(_legacySignatoryNamesText);
  }

  String get signatoryNamesText => _legacySignatoryNamesText ?? '';
}

class SaveOfficerCommand {
  const SaveOfficerCommand({
    this.id,
    required this.fullName,
    required this.position,
    this.committee,
  });

  final StableId? id;
  final String fullName;
  final OfficerPosition position;
  final Committee? committee;
}

class OrganizationWorkspaceSnapshot {
  const OrganizationWorkspaceSnapshot({
    required this.organization,
    required this.activeOfficers,
    required this.archivedOfficers,
    required this.committeeSummaries,
    required this.readinessHints,
  });

  final OrganizationProfile? organization;
  final List<OfficerRowView> activeOfficers;
  final List<OfficerRowView> archivedOfficers;
  final List<CommitteeSummaryView> committeeSummaries;
  final List<OrganizationReadinessHint> readinessHints;

  bool get hasOrganization => organization != null;
  bool get hasActiveOfficers => activeOfficers.isNotEmpty;
  String get organizationName =>
      organization?.name ?? 'No organization profile';
  String get termLabel => organization == null
      ? 'No active term'
      : '${organization!.semester}, SY ${organization!.schoolYear}';
}

class OfficerRowView {
  const OfficerRowView({
    required this.id,
    required this.fullName,
    required this.position,
    required this.positionLabel,
    required this.committee,
    required this.committeeLabel,
    required this.isArchived,
  });

  factory OfficerRowView.fromOfficer(Officer officer) {
    return OfficerRowView(
      id: officer.id,
      fullName: officer.fullName,
      position: officer.position,
      positionLabel: officerPositionLabel(officer.position),
      committee: officer.committee,
      committeeLabel: officer.committee?.label ?? 'No committee',
      isArchived: officer.isArchived,
    );
  }

  final StableId id;
  final String fullName;
  final OfficerPosition position;
  final String positionLabel;
  final Committee? committee;
  final String committeeLabel;
  final bool isArchived;
}

class CommitteeSummaryView {
  const CommitteeSummaryView({
    required this.committee,
    required this.committeeLabel,
    required this.headName,
    required this.memberCount,
  });

  final Committee committee;
  final String committeeLabel;
  final String? headName;
  final int memberCount;
}

class OrganizationReadinessHint {
  const OrganizationReadinessHint({
    required this.message,
    required this.isBlocking,
  });

  final String message;
  final bool isBlocking;
}

String officerPositionLabel(OfficerPosition position) {
  return switch (position) {
    OfficerPosition.head => 'Head',
    OfficerPosition.member => 'Member',
  };
}

List<String> parseSignatoryNames(String value) {
  return value
      .split(RegExp(r'[,\n]'))
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
}

ValidationResult _validateOrganization(
  UpdateOrganizationCommand command,
) {
  final messages = <String>[];
  if (command.name.trim().isEmpty) {
    messages.add('Organization name is required.');
  }
  if (command.type.trim().isEmpty) {
    messages.add('Organization type is required.');
  }
  if (command.adviser.trim().isEmpty) {
    messages.add('Adviser is required.');
  }
  if (command.semester.trim().isEmpty) {
    messages.add('Semester is required.');
  }
  if (command.schoolYear.trim().isEmpty) {
    messages.add('School year is required.');
  }
  if (command.effectiveTreasurerSignatory.isEmpty &&
      command.effectiveAuditorSignatory.isEmpty &&
      command.effectiveHeadSignatory.isEmpty) {
    messages.add('At least one signatory is required.');
  }
  return ValidationResult.invalid(messages);
}

CommitteeSummaryView _committeeSummary(
  Committee committee,
  List<Officer> officers,
) {
  final active = officers
      .where((officer) => !officer.isArchived && officer.committee == committee)
      .toList(growable: false);
  final heads = active.where(
    (officer) => officer.position == OfficerPosition.head,
  );
  final members = active.where(
    (officer) => officer.position == OfficerPosition.member,
  );
  return CommitteeSummaryView(
    committee: committee,
    committeeLabel: committee.label,
    headName: heads.isEmpty ? null : heads.first.fullName,
    memberCount: members.length,
  );
}

List<OrganizationReadinessHint> _readinessHints(
  OrganizationProfile? organization,
  List<OfficerRowView> activeOfficers,
) {
  final hints = <OrganizationReadinessHint>[];
  if (organization == null) {
    hints.add(
      const OrganizationReadinessHint(
        message: 'Organization profile is required before COA export.',
        isBlocking: true,
      ),
    );
  }
  if (activeOfficers.isEmpty) {
    hints.add(
      const OrganizationReadinessHint(
        message:
            'At least one active officer should be encoded for COA review.',
        isBlocking: true,
      ),
    );
  }
  return hints;
}

Officer? _officerById(List<Officer> officers, StableId? id) {
  if (id == null) {
    return null;
  }
  for (final officer in officers) {
    if (officer.id == id) {
      return officer;
    }
  }
  return null;
}

Map<String, Object?> _organizationSnapshot(OrganizationProfile organization) {
  return {
    'id': organization.id,
    'name': organization.name,
    'type': organization.type,
    'adviser': organization.adviser,
    'semester': organization.semester,
    'schoolYear': organization.schoolYear,
    'treasurerSignatory': organization.effectiveTreasurerSignatory,
    'auditorSignatory': organization.effectiveAuditorSignatory,
    'headSignatory': organization.effectiveHeadSignatory,
    'signatoryNames': organization.signatoryNames,
  };
}

Map<String, Object?> _officerSnapshot(Officer officer) {
  return {
    'id': officer.id,
    'fullName': officer.fullName,
    'position': officer.position.name,
    'committee': officer.committee?.name,
    'isArchived': officer.isArchived,
  };
}
