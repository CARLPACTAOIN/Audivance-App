import 'dart:convert';
import 'dart:math';

import 'package:audivance/app/local_unlock_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PIN verifier is deterministic for the same PIN and salt', () async {
    const hasher = CredentialHasher(iterations: 1000);
    final envelope = await hasher.createEnvelope(
      '123456',
      createdAt: DateTime.utc(2026, 8, 23),
    );

    final matchingVerifier = await hasher.deriveVerifier(
      pin: '123456',
      salt: envelope.salt,
      iterations: envelope.iterations,
    );
    final wrongVerifier = await hasher.deriveVerifier(
      pin: '654321',
      salt: envelope.salt,
      iterations: envelope.iterations,
    );

    expect(matchingVerifier, envelope.verifier);
    expect(wrongVerifier, isNot(envelope.verifier));
    expect(await hasher.verify(pin: '123456', envelope: envelope), isTrue);
    expect(await hasher.verify(pin: '654321', envelope: envelope), isFalse);
  });

  test('secure unlock stores no raw PIN', () async {
    final store = InMemorySecureCredentialStore();
    final service = SecureLocalUnlockService(
      store: store,
      hasher: const CredentialHasher(iterations: 1000),
      random: Random(1),
    );

    final result = await service.configurePin('123456');

    expect(result.isValid, isTrue);
    expect(
      jsonEncode(store.credentialEnvelope!.toJson()),
      isNot(contains('123456')),
    );
  });

  test(
    'configure PIN persists credential envelope and generated database key',
    () async {
      final store = InMemorySecureCredentialStore();
      final service = SecureLocalUnlockService(
        store: store,
        hasher: const CredentialHasher(iterations: 1000),
        random: Random(2),
      );

      final result = await service.configurePin('123456');

      expect(result.isValid, isTrue);
      expect(await store.readCredentialEnvelope(), isNotNull);
      expect(await store.readDatabaseKey(), isNotNull);
      expect(await store.readDatabaseKey(), isNotEmpty);
    },
  );

  test('stored credential requires both envelope and database key', () async {
    final store = InMemorySecureCredentialStore();
    final service = SecureLocalUnlockService(
      store: store,
      hasher: const CredentialHasher(iterations: 1000),
      random: Random(7),
    );

    expect(await service.hasStoredCredential(), isFalse);

    await store.writeCredentialEnvelope(
      await const CredentialHasher(iterations: 1000).createEnvelope('123456'),
    );
    expect(await service.hasStoredCredential(), isFalse);

    await store.writeDatabaseKey('database-key');
    expect(await service.hasStoredCredential(), isTrue);
  });

  test(
    'new service instance can unlock with stored credential after restart',
    () async {
      final store = InMemorySecureCredentialStore();
      final first = SecureLocalUnlockService(
        store: store,
        hasher: const CredentialHasher(iterations: 1000),
        random: Random(3),
      );
      await first.configurePin('123456');

      final second = SecureLocalUnlockService(
        store: store,
        hasher: const CredentialHasher(iterations: 1000),
        random: Random(4),
      );
      final result = await second.unlock('123456');

      expect(await second.hasSessionCredential(), isTrue);
      expect(result.isUnlocked, isTrue);
    },
  );

  test(
    'session credential is false before unlock and true after unlock',
    () async {
      final store = InMemorySecureCredentialStore();
      final service = SecureLocalUnlockService(
        store: store,
        hasher: const CredentialHasher(iterations: 1000),
        random: Random(5),
      );
      await service.configurePin('123456');
      await service.lock();

      expect(await service.hasSessionCredential(), isFalse);

      final result = await service.unlock('123456');

      expect(result.isUnlocked, isTrue);
      expect(await service.hasSessionCredential(), isTrue);
    },
  );

  test(
    'secure database key provider returns session key only after unlock',
    () async {
      final store = InMemorySecureCredentialStore();
      final service = SecureLocalUnlockService(
        store: store,
        hasher: const CredentialHasher(iterations: 1000),
        random: Random(6),
      );
      final provider = SecureDatabaseKeyProvider(unlockService: service);
      await service.configurePin('123456');
      await service.lock();

      expect(await provider.databaseKey(), isNull);

      await service.unlock('123456');

      expect(await provider.databaseKey(), await store.readDatabaseKey());
    },
  );
}
