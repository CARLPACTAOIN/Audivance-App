import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/domain/validation_result.dart';
import '../features/audit/data/audit_database_opener.dart';

abstract class LocalUnlockService {
  Future<ValidationResult> configurePin(String pin);
  Future<UnlockResult> unlock(String pin);
  Future<bool> hasSessionCredential();
  Future<bool> hasStoredCredential();
  Future<void> lock();
}

class UnlockResult {
  const UnlockResult({required this.isUnlocked, required this.message});

  const UnlockResult.success()
    : isUnlocked = true,
      message = 'Workspace unlocked.';

  const UnlockResult.failure(this.message) : isUnlocked = false;

  final bool isUnlocked;
  final String message;
}

class CredentialEnvelope {
  const CredentialEnvelope({
    required this.version,
    required this.algorithm,
    required this.salt,
    required this.verifier,
    required this.iterations,
    required this.createdAt,
  });

  factory CredentialEnvelope.fromJson(Map<String, Object?> json) {
    return CredentialEnvelope(
      version: json['version'] as int,
      algorithm: json['algorithm'] as String,
      salt: json['salt'] as String,
      verifier: json['verifier'] as String,
      iterations: json['iterations'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int version;
  final String algorithm;
  final String salt;
  final String verifier;
  final int iterations;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'version': version,
      'algorithm': algorithm,
      'salt': salt,
      'verifier': verifier,
      'iterations': iterations,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

abstract class SecureCredentialStore {
  Future<void> writeCredentialEnvelope(CredentialEnvelope envelope);
  Future<CredentialEnvelope?> readCredentialEnvelope();
  Future<void> writeDatabaseKey(String key);
  Future<String?> readDatabaseKey();
  Future<void> clear();
}

class FlutterSecureCredentialStore implements SecureCredentialStore {
  const FlutterSecureCredentialStore({
    this.storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(migrateWithBackup: true),
    ),
  });

  static const _credentialKey = 'audivance.credential.v1';
  static const _databaseKey = 'audivance.database_key.v1';

  final FlutterSecureStorage storage;

  @override
  Future<void> writeCredentialEnvelope(CredentialEnvelope envelope) {
    return storage.write(
      key: _credentialKey,
      value: jsonEncode(envelope.toJson()),
    );
  }

  @override
  Future<CredentialEnvelope?> readCredentialEnvelope() async {
    final value = await storage.read(key: _credentialKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return CredentialEnvelope.fromJson(
      (jsonDecode(value) as Map<String, dynamic>).cast<String, Object?>(),
    );
  }

  @override
  Future<void> writeDatabaseKey(String key) {
    return storage.write(key: _databaseKey, value: key);
  }

  @override
  Future<String?> readDatabaseKey() {
    return storage.read(key: _databaseKey);
  }

  @override
  Future<void> clear() async {
    await storage.delete(key: _credentialKey);
    await storage.delete(key: _databaseKey);
  }
}

class InMemorySecureCredentialStore implements SecureCredentialStore {
  CredentialEnvelope? credentialEnvelope;
  String? databaseKey;

  @override
  Future<void> writeCredentialEnvelope(CredentialEnvelope envelope) async {
    credentialEnvelope = envelope;
  }

  @override
  Future<CredentialEnvelope?> readCredentialEnvelope() async {
    return credentialEnvelope;
  }

  @override
  Future<void> writeDatabaseKey(String key) async {
    databaseKey = key;
  }

  @override
  Future<String?> readDatabaseKey() async {
    return databaseKey;
  }

  @override
  Future<void> clear() async {
    credentialEnvelope = null;
    databaseKey = null;
  }
}

class CredentialHasher {
  const CredentialHasher({
    this.iterations = productionIterations,
    this.saltByteLength = 16,
    this.keyBits = 256,
    this.random,
  });

  static const productionIterations = 210000;
  static const algorithm = 'PBKDF2-HMAC-SHA256';

  final int iterations;
  final int saltByteLength;
  final int keyBits;
  final Random? random;

  Future<CredentialEnvelope> createEnvelope(
    String pin, {
    DateTime? createdAt,
  }) async {
    final salt = _randomBytes(saltByteLength);
    final verifier = await deriveVerifier(
      pin: pin,
      salt: base64Encode(salt),
      iterations: iterations,
    );
    return CredentialEnvelope(
      version: 1,
      algorithm: algorithm,
      salt: base64Encode(salt),
      verifier: verifier,
      iterations: iterations,
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
  }

  Future<String> deriveVerifier({
    required String pin,
    required String salt,
    required int iterations,
  }) async {
    final pbkdf2 = Pbkdf2.hmacSha256(iterations: iterations, bits: keyBits);
    final key = await pbkdf2.deriveKeyFromPassword(
      password: pin,
      nonce: base64Decode(salt),
    );
    return base64Encode(await key.extractBytes());
  }

  Future<bool> verify({
    required String pin,
    required CredentialEnvelope envelope,
  }) async {
    if (envelope.algorithm != algorithm || envelope.version != 1) {
      return false;
    }
    final candidate = await deriveVerifier(
      pin: pin,
      salt: envelope.salt,
      iterations: envelope.iterations,
    );
    return _constantTimeEquals(candidate, envelope.verifier);
  }

  List<int> _randomBytes(int length) {
    final randomSource = random ?? Random.secure();
    return List<int>.generate(length, (_) => randomSource.nextInt(256));
  }
}

class SecureLocalUnlockService implements LocalUnlockService {
  SecureLocalUnlockService({
    required this.store,
    this.hasher = const CredentialHasher(),
    this.databaseKeyByteLength = 32,
    this.random,
  });

  final SecureCredentialStore store;
  final CredentialHasher hasher;
  final int databaseKeyByteLength;
  final Random? random;

  String? _sessionDatabaseKey;

  @override
  Future<ValidationResult> configurePin(String pin) async {
    final validation = _validatePin(pin);
    if (validation.isInvalid) {
      return validation;
    }
    final envelope = await hasher.createEnvelope(pin);
    await store.writeCredentialEnvelope(envelope);
    var databaseKey = await store.readDatabaseKey();
    databaseKey ??= _generateDatabaseKey();
    await store.writeDatabaseKey(databaseKey);
    _sessionDatabaseKey = databaseKey;
    return const ValidationResult.valid();
  }

  @override
  Future<UnlockResult> unlock(String pin) async {
    final envelope = await store.readCredentialEnvelope();
    if (envelope == null) {
      _sessionDatabaseKey = null;
      return const UnlockResult.failure(
        'Secure credential is not configured for this workspace.',
      );
    }
    final didUnlock = await hasher.verify(pin: pin, envelope: envelope);
    if (!didUnlock) {
      _sessionDatabaseKey = null;
      return const UnlockResult.failure('PIN does not match this workspace.');
    }
    _sessionDatabaseKey = await store.readDatabaseKey();
    return const UnlockResult.success();
  }

  @override
  Future<bool> hasSessionCredential() async {
    return _sessionDatabaseKey != null;
  }

  @override
  Future<bool> hasStoredCredential() async {
    final envelope = await store.readCredentialEnvelope();
    final databaseKey = await store.readDatabaseKey();
    return envelope != null && databaseKey != null && databaseKey.isNotEmpty;
  }

  @override
  Future<void> lock() async {
    _sessionDatabaseKey = null;
  }

  String? get sessionDatabaseKey => _sessionDatabaseKey;

  String _generateDatabaseKey() {
    final randomSource = random ?? Random.secure();
    final bytes = List<int>.generate(
      databaseKeyByteLength,
      (_) => randomSource.nextInt(256),
    );
    return base64Encode(bytes);
  }
}

class InMemoryLocalUnlockService extends SecureLocalUnlockService {
  InMemoryLocalUnlockService({
    InMemorySecureCredentialStore? store,
    CredentialHasher hasher = const CredentialHasher(iterations: 1000),
  }) : this._(store ?? InMemorySecureCredentialStore(), hasher);

  InMemoryLocalUnlockService._(this.credentialStore, CredentialHasher hasher)
    : super(store: credentialStore, hasher: hasher);

  final InMemorySecureCredentialStore credentialStore;
}

class SecureDatabaseKeyProvider implements DatabaseKeyProvider {
  const SecureDatabaseKeyProvider({required this.unlockService});

  final SecureLocalUnlockService unlockService;

  @override
  Future<String?> databaseKey() async {
    return unlockService.sessionDatabaseKey;
  }
}

ValidationResult _validatePin(String pin) {
  if (pin.trim().isEmpty) {
    return ValidationResult.failure('PIN is required.');
  }
  if (!RegExp(r'^\d+$').hasMatch(pin)) {
    return ValidationResult.failure('PIN must use digits only.');
  }
  if (pin.length < 6) {
    return ValidationResult.failure('PIN must be at least 6 digits.');
  }
  return const ValidationResult.valid();
}

bool _constantTimeEquals(String a, String b) {
  final aBytes = utf8.encode(a);
  final bBytes = utf8.encode(b);
  var difference = aBytes.length ^ bBytes.length;
  final maxLength = max(aBytes.length, bBytes.length);
  for (var i = 0; i < maxLength; i += 1) {
    final aByte = i < aBytes.length ? aBytes[i] : 0;
    final bByte = i < bBytes.length ? bBytes[i] : 0;
    difference |= aByte ^ bByte;
  }
  return difference == 0;
}
