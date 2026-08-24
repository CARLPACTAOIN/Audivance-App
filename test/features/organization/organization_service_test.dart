import 'package:audivance/core/domain/identity.dart';
import 'package:audivance/core/domain/money.dart';
import 'package:audivance/core/domain/stable_id_generator.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:audivance/features/export/export_service.dart';
import 'package:audivance/features/organization/organization_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuditDatabase database;
  late DriftAuditRepository repository;
  late OrganizationService service;
  late _DeterministicIdGenerator idGenerator;

  setUp(() {
    database = AuditDatabase(NativeDatabase.memory());
    repository = DriftAuditRepository(database);
    idGenerator = _DeterministicIdGenerator();
    service = OrganizationService(
      repository: repository,
      idGenerator: idGenerator,
      now: () => DateTime(2026, 8, 18, 10),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'loads organization profile with active and archived officers',
    () async {
      await _seedOrganization(repository);
      await repository.saveOfficers(const [
        Officer(
          id: 'officer-active',
          fullName: 'Bea Reyes',
          position: OfficerPosition.head,
          committee: Committee.finance,
        ),
        Officer(
          id: 'officer-archived',
          fullName: 'Ari Santos',
          position: OfficerPosition.member,
          isArchived: true,
        ),
      ]);

      final snapshot = await service.loadSnapshot();

      expect(snapshot.organizationName, 'JPIA');
      expect(snapshot.activeOfficers.single.fullName, 'Bea Reyes');
      expect(snapshot.archivedOfficers.single.fullName, 'Ari Santos');
      expect(snapshot.committeeSummaries.first.headName, 'Bea Reyes');
      expect(snapshot.readinessHints, isEmpty);
    },
  );

  test('rejects incomplete organization profile updates', () async {
    final result = await service.updateOrganization(
      const UpdateOrganizationCommand(
        name: '',
        type: '',
        adviser: '',
        semester: '',
        schoolYear: '',
        signatoryNamesText: '',
      ),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Organization name is required'));
    expect(result.summary, contains('At least one signatory is required'));
    expect(await repository.listOrganizations(), isEmpty);
  });

  test('saves valid organization update and audit log', () async {
    await _seedOrganization(repository);

    final result = await service.updateOrganization(
      const UpdateOrganizationCommand(
        name: 'Updated JPIA',
        type: 'Academic',
        adviser: 'Prof. Cruz',
        semester: '2nd Semester',
        schoolYear: '2026-2027',
        signatoryNamesText: 'Ari Santos\nBea Reyes',
      ),
    );

    final organization = (await repository.listOrganizations()).single;
    final logs = await repository.listAuditLogs();

    expect(result.isValid, isTrue);
    expect(organization.id, 'org-1');
    expect(organization.name, 'Updated JPIA');
    expect(organization.signatoryNames, ['Ari Santos', 'Bea Reyes']);
    expect(logs.single.action, 'organization.update');
    expect(logs.single.targetRecordId, 'org-1');
  });

  test('rejects blank officer name', () async {
    final result = await service.saveOfficer(
      const SaveOfficerCommand(fullName: ' ', position: OfficerPosition.member),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Officer name is required'));
  });

  test('rejects head officer without committee', () async {
    final result = await service.saveOfficer(
      const SaveOfficerCommand(fullName: 'Ari', position: OfficerPosition.head),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Committee heads'));
  });

  test('rejects duplicate active heads for the same committee', () async {
    await service.saveOfficer(
      const SaveOfficerCommand(
        fullName: 'Ari Santos',
        position: OfficerPosition.head,
        committee: Committee.finance,
      ),
    );

    final result = await service.saveOfficer(
      const SaveOfficerCommand(
        fullName: 'Bea Reyes',
        position: OfficerPosition.head,
        committee: Committee.finance,
      ),
    );

    expect(result.isInvalid, isTrue);
    expect(result.summary, contains('Only one active head'));
  });

  test(
    'allows a new committee head after the prior head is archived',
    () async {
      await service.saveOfficer(
        const SaveOfficerCommand(
          fullName: 'Ari Santos',
          position: OfficerPosition.head,
          committee: Committee.finance,
        ),
      );
      final firstOfficer = (await repository.listOfficers()).single;
      await service.setOfficerArchived(
        officerId: firstOfficer.id,
        isArchived: true,
      );

      final result = await service.saveOfficer(
        const SaveOfficerCommand(
          fullName: 'Bea Reyes',
          position: OfficerPosition.head,
          committee: Committee.finance,
        ),
      );
      final officers = await repository.listOfficers();

      expect(result.isValid, isTrue);
      expect(officers.where((officer) => officer.isArchived), hasLength(1));
      expect(
        officers.where(
          (officer) =>
              !officer.isArchived &&
              officer.position == OfficerPosition.head &&
              officer.committee == Committee.finance,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'archives and restores officers without deleting historical records',
    () async {
      await service.saveOfficer(
        const SaveOfficerCommand(
          fullName: 'Ari Santos',
          position: OfficerPosition.member,
        ),
      );
      final officer = (await repository.listOfficers()).single;

      final archive = await service.setOfficerArchived(
        officerId: officer.id,
        isArchived: true,
      );
      final restore = await service.setOfficerArchived(
        officerId: officer.id,
        isArchived: false,
      );
      final officers = await repository.listOfficers();
      final logs = await repository.listAuditLogs();

      expect(archive.isValid, isTrue);
      expect(restore.isValid, isTrue);
      expect(officers, hasLength(1));
      expect(officers.single.isArchived, isFalse);
      expect(logs.map((log) => log.action), contains('officer.archive'));
      expect(logs.map((log) => log.action), contains('officer.restore'));
    },
  );

  test('export readiness clears only when an active officer exists', () async {
    await _seedOrganization(repository);
    await repository.updateTreasuryFundSource(
      const TreasuryFundSource(
        id: 'source-1',
        type: TreasuryFundSourceType.studentCollections,
        label: 'Student Collections',
        balance: Money.zero,
      ),
    );
    await service.saveOfficer(
      const SaveOfficerCommand(
        fullName: 'Ari Santos',
        position: OfficerPosition.member,
      ),
    );
    final officer = (await repository.listOfficers()).single;

    var exportSnapshot = await ExportService(repository: repository)
        .loadSnapshot(asOf: DateTime(2026, 8, 18));
    expect(
      exportSnapshot.issues.map((issue) => issue.id),
      isNot(contains('missing-officers')),
    );

    await service.setOfficerArchived(officerId: officer.id, isArchived: true);
    exportSnapshot = await ExportService(repository: repository)
        .loadSnapshot(asOf: DateTime(2026, 8, 18));

    expect(
      exportSnapshot.issues.map((issue) => issue.id),
      contains('missing-officers'),
    );
  });
}

Future<void> _seedOrganization(DriftAuditRepository repository) {
  return repository.saveOrganization(
    const OrganizationProfile(
      id: 'org-1',
      name: 'JPIA',
      type: 'Academic',
      adviser: 'Prof. Santos',
      semester: '1st Semester',
      schoolYear: '2026-2027',
      signatoryNames: ['Ari Santos'],
    ),
  );
}

class _DeterministicIdGenerator implements StableIdGenerator {
  var _counter = 0;

  @override
  StableId nextId(String prefix) {
    _counter += 1;
    return '$prefix-$_counter';
  }
}
