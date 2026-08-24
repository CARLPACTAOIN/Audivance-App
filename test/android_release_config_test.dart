import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android release identity and backup policy are hardened', () async {
    final manifest = await File('android/app/src/main/AndroidManifest.xml')
        .readAsString();
    final buildGradle = await File('android/app/build.gradle.kts')
        .readAsString();

    expect(buildGradle, contains('namespace = "com.audivance.app"'));
    expect(buildGradle, contains('applicationId = "com.audivance.app"'));
    expect(manifest, contains('android:label="Audivance"'));
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:fullBackupContent="false"'));
    expect(manifest, isNot(contains('android.permission.INTERNET')));
  });

  test('Android release signing secrets stay outside git', () async {
    final gitignore = await File('.gitignore').readAsString();
    final buildGradle = await File('android/app/build.gradle.kts')
        .readAsString();

    expect(gitignore, contains('/android/key.properties'));
    expect(gitignore, contains('/android/app/*.jks'));
    expect(gitignore, contains('/android/app/*.keystore'));
    expect(buildGradle, contains('rootProject.file("key.properties")'));
    expect(buildGradle, contains('hasReleaseSigningConfig'));
  });

  test('Android QA checklist documents release smoke coverage', () async {
    final checklist = await File('docs/ANDROID_QA_CHECKLIST.md').readAsString();

    expect(checklist, contains('Build Identity'));
    expect(checklist, contains('Install And Startup'));
    expect(checklist, contains('Android Storage And File Actions'));
    expect(checklist, contains('Export Center'));
    expect(checklist, contains('flutter build apk --release'));
  });
}
