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
    this.backupService,
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
  final BackupService? backupService;
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
  Object? _startupError;

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
      _startupState =
          AppStartupService(
            repository: _repository!,
            unlockService: _unlockService,
          ).resolveStartupState().asControlledStartup(
            onError: (error) => _startupError = error,
          );
    } else {
      _startupState = _resolveProductionStartupState().asControlledStartup(
        onError: (error) => _startupError = error,
      );
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
          final Widget child;
          if (snapshot.connectionState != ConnectionState.done) {
            child = const _StartupLoadingScreen(key: ValueKey('loading'));
          } else {
            final startupError = _startupError ?? snapshot.error;
            if (startupError != null) {
              child = _StartupErrorScreen(
                key: const ValueKey('error'),
                error: startupError,
                onRetry: _retryStartup,
              );
            } else {
              final state = snapshot.data ?? AppStartupState.needsSetup;
              child = KeyedSubtree(
                key: ValueKey(state),
                child: switch (state) {
                  AppStartupState.needsSetup => SetupScreen(
                    idGenerator: _idGenerator,
                    onSubmitWorkspace: _submitSetupWorkspace,
                    onSetupComplete: _showDashboard,
                  ),
                  AppStartupState.needsCredentialUpgrade =>
                    CredentialUpgradeScreen(
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
                    backupService: widget.backupService,
                    backupPackageWriter: widget.backupPackageWriter,
                    backupPackageReader: widget.backupPackageReader,
                    onRestoreBackup:
                        widget.backupRestoreHandler ?? _restoreBackupAndReload,
                    asOf: widget.asOf,
                    storagePaths: _storagePaths,
                  ),
                },
              );
            }
          }
          return AppCrossfade(child: child);
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

  void _retryStartup() {
    setState(() {
      _startupError = null;
      if (_ownsDatabase) {
        _startupState = _resolveProductionStartupState().asControlledStartup(
          onError: (error) => _startupError = error,
        );
      } else {
        _startupState =
            AppStartupService(
              repository: _repository!,
              unlockService: _unlockService,
            ).resolveStartupState().asControlledStartup(
              onError: (error) => _startupError = error,
            );
      }
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
      brightness: Brightness.dark,
      primary: AppColors.brand,
      onPrimary: AppColors.onBrand,
      primaryContainer: Color(0xFF451A03),
      onPrimaryContainer: Color(0xFFFDE68A),
      secondary: AppColors.success,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF064E3B),
      onSecondaryContainer: Color(0xFFA7F3D0),
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderStrong,
      outlineVariant: AppColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF111620),
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.onBrand,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.brandLight),
        helperStyle: const TextStyle(color: AppColors.textMuted),
        errorStyle: const TextStyle(color: Color(0xFFF87171)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.brandContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.brandLight);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.brandLight,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSubtle,
        disabledColor: AppColors.surface,
        selectedColor: AppColors.brandContainer,
        secondarySelectedColor: const Color(0xFF064E3B),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderSm,
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.brandLight,
          fontSize: 13,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: AppColors.textPrimary,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: Color(0xFFCBD5E1),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: AppColors.textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen({super.key});

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
  const _StartupErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppStateView.error(
          title: 'Audivance could not open the local workspace',
          message: _startupErrorMessage(error),
          onAction: onRetry,
        ),
      ),
    );
  }
}

String _startupErrorMessage(Object? error) {
  final details = error?.toString().trim();
  if (error is EncryptedDatabaseOpenException) {
    final message = error.message;
    if (message.contains('SQLite encryption support')) {
      return 'This Android build does not include the SQLite encryption engine needed for Audivance. Install a current Audivance build and try again.\n\nDetails: $message';
    }
    if (message.contains('stored key') ||
        message.contains('key is missing') ||
        message.contains('stored database key')) {
      return 'The secure workspace key is missing or does not match this device. Do not uninstall the app. Try again, then use a verified same-device backup if support asks for recovery steps.\n\nDetails: $message';
    }
    if (message.contains('migration')) {
      return 'Audivance could not finish securing the local database. Keep the app installed and retry before making any backup or restore changes.\n\nDetails: $message';
    }
    return 'The encrypted local database could not be opened. Keep the app installed, retry, and use the latest same-device backup if support asks for recovery steps.\n\nDetails: $message';
  }

  if (details == null || details.isEmpty) {
    return 'The local workspace could not be loaded. Keep the app installed and try again.';
  }
  return 'The local workspace could not be loaded. Keep the app installed and try again.\n\nDetails: $details';
}

extension on Future<AppStartupState> {
  Future<AppStartupState> asControlledStartup({
    required void Function(Object error) onError,
  }) async {
    try {
      return await this;
    } on Object catch (error) {
      onError(error);
      return AppStartupState.needsSetup;
    }
  }
}
