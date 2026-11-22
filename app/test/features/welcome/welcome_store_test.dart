import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/welcome/welcome_store.dart';

void main() {
  late Directory folder;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('welcome_store');
  });

  tearDown(() {
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });

  FileWelcomeStore store() => FileWelcomeStore(() async => folder);

  test('a fresh install has not seen the welcome yet', () async {
    expect(await store().seen(), isFalse);
  });

  test(
    'marking it seen is remembered by a new store on the same folder',
    () async {
      await store().markSeen();
      expect(await store().seen(), isTrue);
    },
  );

  test('marking it twice is harmless', () async {
    await store().markSeen();
    await store().markSeen();
    expect(await store().seen(), isTrue);
  });

  test(
    'a folder that cannot be reached counts as seen so nobody is nagged',
    () async {
      final broken = FileWelcomeStore(
        () async => throw const FileSystemException('x'),
      );
      expect(await broken.seen(), isTrue);
    },
  );

  test('a folder that cannot be written does not crash the app', () async {
    final broken = FileWelcomeStore(
      () async => throw const FileSystemException('x'),
    );
    await broken.markSeen();
  });

  test('a missing folder is reported as unwritable, not thrown', () async {
    final missing = FileWelcomeStore(
      () async => Directory('${folder.path}${Platform.pathSeparator}nope'),
    );
    await missing.markSeen();
    expect(await missing.seen(), isFalse);
  });
}
