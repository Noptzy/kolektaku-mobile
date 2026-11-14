import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/settings/about_content.dart';

String pubspecVersion() {
  final text = File('pubspec.yaml').readAsStringSync();
  return RegExp(
    r'^version:\s*([^\s+]+)',
    multiLine: true,
  ).firstMatch(text)!.group(1)!;
}

void main() {
  test('the notes belong to the version in pubspec', () {
    expect(aboutNotes.version, pubspecVersion());
  });

  test('every note is a real sentence', () {
    expect(aboutNotes.lines, isNotEmpty);
    for (final line in aboutNotes.lines) {
      expect(line.trim(), isNotEmpty);
      expect(line, endsWith('.'));
    }
  });

  test('the notes show only for the version they describe', () {
    expect(notesFor(aboutNotes.version), aboutNotes.lines);
    expect(notesFor('0.0.1'), isEmpty);
    expect(notesFor(null), isEmpty);
  });

  test('the credits name the data providers and the update host', () {
    final text = aboutLines.join(' ');
    expect(text, contains('AniList'));
    expect(text, contains('MyAnimeList'));
    expect(text, contains('trace.moe'));
    expect(text, contains('GitHub'));
  });
}
