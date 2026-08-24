import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AuditStoragePaths {
  const AuditStoragePaths({
    this.databaseName = 'audivance.sqlite',
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  final String databaseName;
  final Future<Directory> Function() _supportDirectoryProvider;

  Future<Directory> supportDirectory() => _supportDirectoryProvider();

  Future<File> databaseFile() async {
    final directory = await supportDirectory();
    return File(p.join(directory.path, databaseName));
  }

  Future<List<File>> databaseFiles() async {
    final database = await databaseFile();
    final candidates = [
      database,
      File('${database.path}-wal'),
      File('${database.path}-shm'),
    ];
    final existing = <File>[];
    for (final file in candidates) {
      if (await file.exists()) {
        existing.add(file);
      }
    }
    return existing;
  }

  Future<Directory> attachmentsDirectory() async {
    final directory = await supportDirectory();
    return Directory(p.join(directory.path, 'attachments'));
  }

  Future<File> resolveRelativeFile(String relativePath) async {
    final directory = await supportDirectory();
    return File(p.joinAll([directory.path, ...p.posix.split(relativePath)]));
  }
}
