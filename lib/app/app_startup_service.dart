import '../features/audit/data/audit_repository.dart';
import 'local_unlock_service.dart';

enum AppStartupState { needsSetup, needsCredentialUpgrade, needsUnlock, ready }

class AppStartupService {
  const AppStartupService({
    required this.repository,
    required this.unlockService,
  });

  final AuditRepository repository;
  final LocalUnlockService unlockService;

  Future<AppStartupState> resolveStartupState() async {
    final hasStoredCredential = await unlockService.hasStoredCredential();
    if (hasStoredCredential) {
      final hasSessionCredential = await unlockService.hasSessionCredential();
      if (!hasSessionCredential) {
        return AppStartupState.needsUnlock;
      }
    }

    final setupComplete = await repository.isSetupComplete();
    if (!setupComplete) {
      return AppStartupState.needsSetup;
    }

    if (!hasStoredCredential) {
      return AppStartupState.needsCredentialUpgrade;
    }

    return AppStartupState.ready;
  }
}
