import 'package:flutter/material.dart';

import '../core/attachments/attachment_picker.dart';
import '../core/attachments/attachment_storage_service.dart';
import '../core/domain/stable_id_generator.dart';
import '../core/domain/validation_result.dart';
import '../core/storage/audit_storage_paths.dart';
import '../features/audit/data/audit_database.dart';
import '../features/audit/data/audit_database_encryption_service.dart';
import '../features/audit/data/audit_database_opener.dart';
import '../features/audit/data/audit_repository.dart';
import '../features/audit/data/drift_audit_repository.dart';
import '../features/audit/domain/audit_models.dart';
import '../features/backup/backup_package_io.dart';
import '../features/backup/backup_restore_coordinator.dart';
import '../features/backup/backup_service.dart';
import '../features/export/export_package_writer.dart';
import '../features/setup/setup_screen.dart';
import 'app_startup_service.dart';
import 'brand_logo.dart';
import 'credential_upgrade_screen.dart';
import 'local_unlock_service.dart';
import 'ui/app_ui.dart';
import 'unlock_screen.dart';
import 'workspace_shell.dart';

class AudivanceApp extends StatefulWidget {
  const AudivanceApp({
    super.key,
    this.database,
    this.repository,
    this.unlockService,
    this.idGenerator,
    this.attachmentPicker,
    this.attachmentStorage,
    this.exportPackageWriter,
    this.backupPackageWriter,
    this.backupPackageReader,
    this.backupRestoreHandler,
    this.asOf,
    this.storagePaths,
  });

  final AuditDatabase? database;
  final AuditRepository? repository;
  final LocalUnlockService? unlockService;
  final StableIdGenerator? idGenerator;
  final AttachmentPicker? attachmentPicker;
  final AttachmentStorageService? attachmentStorage;
  final ExportPackageWriter? exportPackageWriter;
  final BackupPackageWriter? backupPackageWriter;
  final BackupPackageReader? backupPackageReader;
  final BackupRestoreHandler? backupRestoreHandler;
  final DateTime? asOf;
  final AuditStoragePaths? storagePaths;

  @override
  State<AudivanceApp> createState() => _AudivanceAppState();
}

class _AudivanceAppState extends State<AudivanceApp> {
  late final LocalUnlockService _unlockService;
  late final StableIdGenerator _idGenerator;
  late final AttachmentPicker _attachmentPicker;
  late final AttachmentStorageService _attachmentStorage;
  late final AuditStoragePaths _storagePaths;
  late Future<AppStartupState> _startupState;
  late final bool _ownsDatabase;
  AuditDatabase? _database;
  AuditRepository? _repository;
  AuditDatabase? _bootstrapDatabase;
  AuditRepository? _bootstrapRepository;

  @override
  void initState() {
    super.initState();
    _storagePaths = widget.storagePaths ?? const AuditStoragePaths();
    _unlockService =
        widget.unlockService ??
        SecureLocalUnlockService(store: const FlutterSecureCredentialStore());
    _idGenerator = widget.idGenerator ?? TimestampStableIdGenerator();
    _attachmentPicker =
        widget.attachmentPicker ?? const FilePickerAttachmentPicker();
    _attachmentStorage =
        widget.attachmentStorage ??
        FileSystemAttachmentStorageService(idGenerator: _idGenerator);
    final usesInjectedWorkspace =
        widget.database != null || widget.repository != null;
    _ownsDatabase = !usesInjectedWorkspace;
    if (usesInjectedWorkspace) {
      _database = widget.database;
      _repository =
          widget.repository ??
          DriftAuditRepository(
            _database ??
                AuditDatabaseOpener.plaintext(storagePaths: _storagePaths)
                    .open(),
          );
      _startupState = AppStartupService(
        repository: _repository!,
        unlockService: _unlockService,
      ).resolveStartupState();
    } else {
      _startupState = _resolveProductionStartupState();
    }
  }

  @override
  void dispose() {
    _bootstrapDatabase?.close();
    if (_ownsDatabase) {
      _database?.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audivance',
      theme: _buildTheme(),
      home: FutureBuilder<AppStartupState>(
        future: _startupState,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _StartupLoadingScreen();
          }
          if (snapshot.hasError) {
            return _StartupErrorScreen(error: snapshot.error);
          }

          return switch (snapshot.data ?? AppStartupState.needsSetup) {
            AppStartupState.needsSetup => SetupScreen(
              idGenerator: _idGenerator,
              onSubmitWorkspace: _submitSetupWorkspace,
              onSetupComplete: _showDashboard,
            ),
            AppStartupState.needsCredentialUpgrade => CredentialUpgradeScreen(
              onSubmitCredential: _submitCredentialUpgrade,
              onConfigured: _showDashboard,
            ),
            AppStartupState.needsUnlock => UnlockScreen(
              unlockService: _unlockService,
              onUnlocked: _unlockAndShowDashboard,
            ),
            AppStartupState.ready => WorkspaceShell(
              repository: _repository!,
              idGenerator: _idGenerator,
              attachmentPicker: _attachmentPicker,
              attachmentStorage: _attachmentStorage,
              exportPackageWriter: widget.exportPackageWriter,
              backupPackageWriter: widget.backupPackageWriter,
              backupPackageReader: widget.backupPackageReader,
              onRestoreBackup:
                  widget.backupRestoreHandler ?? _restoreBackupAndReload,
              asOf: widget.asOf,
              storagePaths: _storagePaths,
            ),
          };
        },
      ),
    );
  }

  Future<AppStartupState> _resolveProductionStartupState() async {
    final hasStoredCredential = await _unlockService.hasStoredCredential();
    if (hasStoredCredential) {
      final hasSessionCredential = await _unlockService.hasSessionCredential();
      if (!hasSessionCredential) {
        return AppStartupState.needsUnlock;
      }
      await _openEncryptedWorkspace();
      return await _repository!.isSetupComplete()
          ? AppStartupState.ready
          : AppStartupState.needsSetup;
    }

    final databaseFile = await _storagePaths.databaseFile();
    if (!await databaseFile.exists() || await databaseFile.length() == 0) {
      return AppStartupState.needsSetup;
    }

    await _openPlaintextBootstrapWorkspace();
    final setupComplete = await _bootstrapRepository!.isSetupComplete();
    return setupComplete
        ? AppStartupState.needsCredentialUpgrade
        : AppStartupState.needsSetup;
  }

  Future<ValidationResult> _submitSetupWorkspace(
    SetupWorkspaceDraft draft,
  ) async {
    final credentialResult = await _unlockService.configurePin(draft.pin);
    if (credentialResult.isInvalid) {
      return credentialResult;
    }

    await _openEncryptedWorkspace();
    await _repository!.saveLocalAccount(draft.account);
    await _repository!.saveOrganization(draft.organization);
    return const ValidationResult.valid();
  }

  Future<String?> _submitCredentialUpgrade(String pin) async {
    final sourceRepository = _repository ?? _bootstrapRepository;
    final credentialResult = await _unlockService.configurePin(pin);
    if (credentialResult.isInvalid) {
      return credentialResult.summary;
    }

    if (sourceRepository != null) {
      final account = await sourceRepository.getLocalAccount();
      if (account != null) {
        await sourceRepository.saveLocalAccount(
          LocalAccountProfile(
            id: account.id,
            displayName: account.displayName,
            emailOrStudentId: account.emailOrStudentId,
            createdAt: account.createdAt,
            isCredentialConfigured: true,
          ),
        );
      }
    }

    if (_ownsDatabase) {
      await _closePlaintextBootstrapWorkspace();
      await _openEncryptedWorkspace();
    }
    return null;
  }

  Future<void> _unlockAndShowDashboard() async {
    await _openEncryptedWorkspace();
    _showDashboard();
  }

  void _showDashboard() {
    setState(() {
      _startupState = Future.value(AppStartupState.ready);
    });
  }

  Future<void> _openPlaintextBootstrapWorkspace() async {
    if (_bootstrapRepository != null) {
      return;
    }
    _bootstrapDatabase = AuditDatabaseOpener.plaintext(
      storagePaths: _storagePaths,
    ).open();
    _bootstrapRepository = DriftAuditRepository(_bootstrapDatabase!);
  }

  Future<void> _closePlaintextBootstrapWorkspace() async {
    final database = _bootstrapDatabase;
    _bootstrapRepository = null;
    _bootstrapDatabase = null;
    await database?.close();
  }

  Future<void> _openEncryptedWorkspace() async {
    if (_repository != null && _database != null) {
      return;
    }
    if (_unlockService is! SecureLocalUnlockService) {
      throw const EncryptedDatabaseOpenException(
        'Secure unlock service is required to open the encrypted database.',
      );
    }
    await _closePlaintextBootstrapWorkspace();
    final unlockService = _unlockService;
    _database = AuditDatabaseOpener(
      keyProvider: SecureDatabaseKeyProvider(unlockService: unlockService),
      storagePaths: _storagePaths,
    ).open();
    _repository = DriftAuditRepository(_database!);
    await _repository!.isSetupComplete();
  }

  Future<void> _closeEncryptedWorkspace() async {
    final database = _database;
    _repository = null;
    _database = null;
    if (_ownsDatabase) {
      await database?.close();
    }
  }

  Future<RestoreExecutionResult> _restoreBackupAndReload(
    PickedBackupPackage package,
  ) async {
    if (!_ownsDatabase) {
      return const RestoreExecutionResult.restoreFailed(
        'Active restore is only available for file-backed app workspaces.',
      );
    }
    final coordinator = BackupRestoreCoordinator(
      service: BackupService(storagePaths: _storagePaths),
      closeActiveWorkspace: _closeEncryptedWorkspace,
      reopenWorkspace: _openEncryptedWorkspace,
    );
    final result = await coordinator.restoreBackup(package);
    if (mounted && result.isSuccess) {
      setState(() {
        _startupState = Future.value(AppStartupState.ready);
      });
    } else if (mounted &&
        result.status == RestoreExecutionStatus.reopenFailed) {
      setState(() {
        _startupState = Future.error(StateError(result.message));
      });
    }
    return result;
  }

  ThemeData _buildTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0F172A),
      onPrimary: Colors.white,
      secondary: Color(0xFF1E3A8A),
      onSecondary: Colors.white,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF020617),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: const Color(0xFFA16207),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: const Color(0xFF0F172A),
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.18,
          color: Color(0xFF020617),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: Color(0xFF020617),
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.35,
          color: Color(0xFF0F172A),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Color(0xFF334155),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: Color(0xFF475569),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(key: Key('startupBrandLogo'), size: 88),
              const SizedBox(height: 20),
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Opening local workspace',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppStateView.error(
          title: 'Audivance could not open the local workspace',
          message: error.toString(),
        ),
      ),
    );
  }
}
