import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const highestEarlierBuild = 4004;

int buildNumber() {
  final text = File('pubspec.yaml').readAsStringSync();
  final match = RegExp(
    r'^version:\s*[^\s+]+\+(\d+)',
    multiLine: true,
  ).firstMatch(text)!;
  return int.parse(match.group(1)!);
}

void main() {
  test('the build number is above every earlier per-abi build', () {
    expect(buildNumber(), greaterThan(highestEarlierBuild));
  });

  test('a phone with an older split build can update to this one', () {
    const arm64Of022 = 2004;
    const arm32Of022 = 1004;
    const x86Of022 = 4004;
    for (final installed in [arm64Of022, arm32Of022, x86Of022]) {
      expect(buildNumber(), greaterThan(installed));
    }
  });
}
