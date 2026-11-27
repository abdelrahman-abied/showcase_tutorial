// pub.dev gives the screenshots section 0 points when a screenshot
// description is 160 characters or longer (it happened in 2.0.1).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec screenshots exist and have pub.dev-valid descriptions', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final section = RegExp(r'^screenshots:\n((?:[ \t]+.*\n|\n)*)', multiLine: true).firstMatch(pubspec);
    expect(section, isNotNull, reason: 'pubspec.yaml lists screenshots');

    final descriptions = RegExp(r'description:\s*"(.*)"').allMatches(section!.group(1)!).map((m) => m.group(1)!);
    final paths = RegExp(r'path:\s*(\S+)').allMatches(section.group(1)!).map((m) => m.group(1)!);
    expect(descriptions, isNotEmpty);
    expect(paths.length, descriptions.length);

    for (final description in descriptions) {
      expect(description.length, lessThan(160), reason: '"$description" is too long for pub.dev');
    }
    for (final path in paths) {
      expect(File(path).existsSync(), isTrue, reason: '$path is listed but missing');
      expect(File(path).lengthSync(), lessThan(4 * 1024 * 1024), reason: '$path is over pub.dev\'s 4 MB limit');
    }
  });
}
