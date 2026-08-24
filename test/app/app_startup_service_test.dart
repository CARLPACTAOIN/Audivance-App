import 'package:audivance/app/app_startup_service.dart';
import 'package:audivance/app/local_unlock_service.dart';
import 'package:audivance/features/audit/data/audit_database.dart';
import 'package:audivance/features/audit/data/audit_repository.dart';
import 'package:audivance/features/audit/data/drift_audit_repository.dart';
import 'package:audivance/features/audit/domain/audit_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuditDatabase database;
  late DriftAuditRepository repository;
  late InMemoryLocalUnlockService unlockService;
  late AppStartupService startupService;

  setUp(() {
    database = AuditDatabase(NativeDatabase.memory());
    repository = DriftAuditRepository(database);
    unlockService = InMemoryLocalUnlockService();
    startupService = AppStartupService(
      repository: repository,
      unlockService: unlockService,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('routes to setup when no persisted profile exists', () async {
    expect(
      await startupService.resolveStartupState(),
      AppStartupState.needsSetup,
    );
  });

  test(
    'routes to credential upgrade when setup exists without stored credential',
    () async {
      await _seedSetup(repository);

      expect(
        await startupService.resolveStartupState(),
        AppStartupState.needsCredentialUpgrade,
      );
    },
  );

  test('routes to unlock when setup exists with stored credential', () async {
    await _seedSetup(repository);
    await unlockService.configurePin('123456');
    await unlockService.lock();

    expect(
      await startupService.resolveStartupState(),
      AppStartupState.needsUnlock,
    );
  });

  test('routes to ready after unlock succeeds', () async {
    await _seedSetup(repository);
    await unlockService.configurePin('123456');
    await unlockService.lock();
    final unlockResult = await unlockService.unlock('123456');

    expect(unlockResult.isUnlocked, isTrue);
    expect(await startupService.resolveStartupState(), AppStartupState.ready);
  });

  test('does not check repository setup before unlock', () async {
    final countingRepository = _CountingRepository();
    await unlockService.configurePin('123456');
    await unlockService.lock();
    final service = AppStartupService(
      repository: countingRepository,
      unlockService: unlockService,
    );

    expect(await service.resolveStartupState(), AppStartupState.needsUnlock);
    expect(countingRepository.setupChecks, 0);
  });
}

Future<void> _seedSetup(DriftAuditRepository repository) async {
  await repository.saveLocalAccount(
    LocalAccountProfile(
      id: 'account-1',
      displayName: 'Local Auditor',
      emailOrStudentId: 'auditor@example.test',
      createdAt: DateTime(2026, 8, 18, 9),
      isCredentialConfigured: true,
    ),
  );
  await repository.saveOrganization(
    const OrganizationProfile(
      id: 'org-1',
      name: 'Junior Philippine Institute of Accountants',
      type: 'Academic',
      adviser: 'Prof. Santos',
      semester: '1st Semester',
      schoolYear: '2026-2027',
      signatoryNames: ['Ari Santos', 'Bea Reyes'],
    ),
  );
}

class _CountingRepository implements AuditRepository {
  var setupChecks = 0;

  @override
  Future<bool> isSetupComplete() async {
    setupChecks += 1;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
