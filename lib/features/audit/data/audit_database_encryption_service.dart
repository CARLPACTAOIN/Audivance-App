import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../../../core/storage/audit_storage_paths.dart';

enum DatabaseEncryptionStatus { missing, plaintext, encrypted, invalidKey }

class DatabaseEncryptionMigrationResult {
  const DatabaseEncryptionMigrationResult({
    required this.statusBefore,
    required this.statusAfter,
    required this.didMigrate,
  });

  final DatabaseEncryptionStatus statusBefore;
  final DatabaseEncryptionStatus statusAfter;
  final bool didMigrate;
}

class EncryptedDatabaseOpenException implements Exception {
  const EncryptedDatabaseOpenException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuditDatabaseEncryptionService {
  const AuditDatabaseEncryptionService({
    this.storagePaths = const AuditStoragePaths(),
  });

  final AuditStoragePaths storagePaths;

  Future<DatabaseEncryptionStatus> inspect({String? key}) async {
    final file = await storagePaths.databaseFile();
    if (!await file.exists() || await file.length() == 0) {
      return DatabaseEncryptionStatus.missing;
    }

    if (key != null && key.isNotEmpty && _canReadWithKey(file, key)) {
      return DatabaseEncryptionStatus.encrypted;
    }
    if (_canReadPlaintext(file)) {
      return DatabaseEncryptionStatus.plaintext;
    }
    return DatabaseEncryptionStatus.invalidKey;
  }

  Future<DatabaseEncryptionMigrationResult> migrateIfNeeded({
    required String key,
  }) async {
    if (key.isEmpty) {
      throw const EncryptedDatabaseOpenException(
        'Encrypted database key is missing.',
      );
    }

    final file = await storagePaths.databaseFile();
    final before = await inspect(key: key);
    await _deleteStaleMigrationFiles(file);

    if (before == DatabaseEncryptionStatus.missing ||
        before == DatabaseEncryptionStatus.encrypted) {
      return DatabaseEncryptionMigrationResult(
        statusBefore: before,
        statusAfter: before,
        didMigrate: false,
      );
    }

    if (before == DatabaseEncryptionStatus.invalidKey) {
      throw const EncryptedDatabaseOpenException(
        'The local database could not be opened with the stored key.',
      );
    }

    await _migratePlaintextDatabase(file: file, key: key);
    final after = await inspect(key: key);
    if (after != DatabaseEncryptionStatus.encrypted) {
      throw const EncryptedDatabaseOpenException(
        'The local database encryption migration could not be verified.',
      );
    }

    return DatabaseEncryptionMigrationResult(
      statusBefore: before,
      statusAfter: after,
      didMigrate: true,
    );
  }

  void applyKey(Database database, String key) {
    if (key.isEmpty) {
      throw const EncryptedDatabaseOpenException(
        'Encrypted database key is missing.',
      );
    }
    _ensureCipherAvailable(database);
    database.execute("PRAGMA key = '${_escapeSqlString(key)}';");
    _verifyReadable(database);
  }

  bool hasCipherSupport(Database database) {
    try {
      return database.select('PRAGMA cipher;').isNotEmpty;
    } on Object {
      return false;
    }
  }

  Future<void> _migratePlaintextDatabase({
    required File file,
    required String key,
  }) async {
    final tmp = File('${file.path}.encrypted.tmp');
    final backup = File('${file.path}.plaintext.bak');
    await _deleteIfExists(tmp);
    await _deleteIfExists(backup);

    Database? plaintextDb;
    try {
      plaintextDb = sqlite3.open(file.path);
      try {
        plaintextDb.execute('PRAGMA wal_checkpoint(FULL);');
      } on Object {
        // Databases not using WAL can ignore checkpoint failures.
      }
      plaintextDb.execute("VACUUM INTO '${_escapeSqlString(tmp.path)}';");
    } finally {
      plaintextDb?.close();
    }

    Database? encryptedDb;
    try {
      encryptedDb = sqlite3.open(tmp.path);
      _ensureCipherAvailable(encryptedDb);
      encryptedDb.execute("PRAGMA rekey = '${_escapeSqlString(key)}';");
    } finally {
      encryptedDb?.close();
    }

    if (!_canReadWithKey(tmp, key) || _canReadPlaintext(tmp)) {
      await _deleteIfExists(tmp);
      throw const EncryptedDatabaseOpenException(
        'The encrypted database copy could not be verified.',
      );
    }

    await file.rename(backup.path);
    await _deleteDatabaseSidecars(file);
    try {
      await tmp.rename(file.path);
      if (!_canReadWithKey(file, key)) {
        throw const EncryptedDatabaseOpenException(
          'The encrypted database could not be reopened after migration.',
        );
      }
      await _deleteIfExists(backup);
    } on Object {
      await _deleteIfExists(file);
      if (await backup.exists()) {
        await backup.rename(file.path);
      }
      rethrow;
    }
  }

  Future<void> _deleteStaleMigrationFiles(File database) async {
    await _deleteIfExists(File('${database.path}.encrypted.tmp'));
    await _deleteIfExists(File('${database.path}.plaintext.bak'));
  }

  Future<void> _deleteDatabaseSidecars(File database) async {
    await _deleteIfExists(File('${database.path}-wal'));
    await _deleteIfExists(File('${database.path}-shm'));
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  bool _canReadWithKey(File file, String key) {
    Database? database;
    try {
      database = sqlite3.open(file.path);
      applyKey(database, key);
      return true;
    } on Object {
      return false;
    } finally {
      database?.close();
    }
  }

  bool _canReadPlaintext(File file) {
    Database? database;
    try {
      database = sqlite3.open(file.path);
      _verifyReadable(database);
      return true;
    } on Object {
      return false;
    } finally {
      database?.close();
    }
  }

  void _ensureCipherAvailable(Database database) {
    if (!hasCipherSupport(database)) {
      throw const EncryptedDatabaseOpenException(
        'SQLite encryption support is not available in this build.',
      );
    }
  }

  void _verifyReadable(Database database) {
    database.select('SELECT count(*) AS count FROM sqlite_master;');
  }
}

String _escapeSqlString(String source) {
  return source.replaceAll("'", "''");
}
