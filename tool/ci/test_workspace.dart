import 'dart:io';

import 'package:yaml/yaml.dart';

Future<void> main() async {
  final root = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  var tested = 0;
  for (final path in root['workspace'] as YamlList) {
    final directory = Directory('$path/test');
    if (!directory.existsSync() ||
        !directory
            .listSync(recursive: true)
            .any((file) => file is File && file.path.endsWith('_test.dart'))) {
      continue;
    }
    stdout.writeln('Testing $path');
    final process = await Process.start(
      'flutter',
      ['test', '--no-pub'],
      workingDirectory: path as String,
      mode: ProcessStartMode.inheritStdio,
    );
    final result = await process.exitCode;
    if (result != 0) {
      exitCode = result;
      return;
    }
    tested++;
  }
  if (tested == 0) throw StateError('No workspace tests found.');
  stdout.writeln('Passed tests in $tested packages.');
}
