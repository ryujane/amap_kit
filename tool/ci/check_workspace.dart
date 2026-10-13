import 'dart:io';

import 'package:yaml/yaml.dart';

/// Checks declared workspace dependencies without loading native SDKs.
void main() {
  final root = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
  final packages = <String, YamlMap>{};
  for (final path in root['workspace'] as YamlList) {
    final spec =
        loadYaml(File('$path/pubspec.yaml').readAsStringSync()) as YamlMap;
    packages[spec['name'] as String] = spec;
  }
  final errors = <String>[];
  if (root['publish_to'] != 'none') {
    errors.add('The workspace root must not be published.');
  }
  if (packages.containsKey('amap_kit_platform_interface')) {
    errors.add('Use product-specific platform interfaces.');
  }
  for (final entry in packages.entries) {
    final name = entry.key;
    final dependencies = entry.value['dependencies'] as YamlMap?;
    for (final dependency in dependencies?.keys ?? <String>[]) {
      if (!packages.containsKey(dependency)) continue;
      final target = dependency as String;
      if (name == 'amap_kit_core' ||
          (name.endsWith('_platform_interface') && target != 'amap_kit_core') ||
          ((name.endsWith('_android') || name.endsWith('_ios')) &&
              target != 'amap_kit_core' &&
              target !=
                  '${name.replaceFirst(RegExp(r'_(android|ios)$'), '')}_platform_interface')) {
        errors.add('Forbidden dependency: $name -> $target');
      }
    }
  }
  // Audit current declarations. Android and iOS have independent SDK versions.
  final baseline =
      loadYaml(File('tool/ci/native_sdks.yaml').readAsStringSync()) as YamlMap;
  for (final entry in baseline.entries) {
    if (!File(entry.key as String)
        .readAsLinesSync()
        .map((line) => line.trim())
        .contains(entry.value as String)) {
      errors.add(
        'Native SDK declaration changed: ${entry.key}. Review and update the audit baseline.',
      );
    }
  }
  if (errors.isNotEmpty) {
    stderr.writeln(errors.join('\n'));
    exitCode = 1;
  } else {
    stdout.writeln('Workspace boundaries and native SDK declarations passed.');
  }
}
