import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../../core/storage/audit_storage_paths.dart';
import 'audit_database.dart';
import 'audit_database_encryption_service.dart';

abstract class DatabaseKeyProvider {
  Future<String?> databaseKey();
}

class NoDatabaseKeyProvider implements DatabaseKeyProvider {
  const NoDatabaseKeyProvider();

  @override
  Future<String?> databaseKey() async => null;
}

class AuditDatabaseOpener {
  const AuditDatabaseOpener({
    required this.keyProvider,
    this.storagePaths = const AuditStoragePaths(),
    this.encryptionService,
    this.allowPlaintext = false,
  });

  const AuditDatabaseOpener.plaintext({
    this.storagePaths = const AuditStoragePaths(),
  }) : keyProvider = const NoDatabaseKeyProvider(),
       encryptionService = null,
       allowPlaintext = true;

  final DatabaseKeyProvider keyProvider;
  final AuditStoragePaths storagePaths;
  final AuditDatabaseEncryptionService? encryptionService;
  final bool allowPlaintext;

  AuditDatabase open() {
    return AuditDatabase(
      LazyDatabase(() async {
        final key = await keyProvider.databaseKey();
        final file = await storagePaths.databaseFile();
        await file.parent.create(recursive: true);
        if (allowPlaintext) {
          return NativeDatabase.createInBackground(file);
        }
        if (key == null || key.isEmpty) {
          throw const EncryptedDatabaseOpenException(
            'Encrypted database key is missing.',
          );
        }

        final service =
            encryptionService ??
            AuditDatabaseEncryptionService(storagePaths: storagePaths);
        await service.migrateIfNeeded(key: key);
        return NativeDatabase.createInBackground(
          file,
          setup: (rawDb) => service.applyKey(rawDb, key),
        );
      }),
    );
  }
}
