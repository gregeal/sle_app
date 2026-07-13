import 'dart:convert';
import 'dart:io';

import 'pwa_build_support.dart';

void main(List<String> args) {
  final build = Directory(args.isEmpty ? 'build/web' : args.single).absolute;
  final errors = <String>[];

  if (!build.existsSync()) {
    stderr.writeln('Web build does not exist: ${build.path}');
    exitCode = 1;
    return;
  }

  String read(String relativePath) {
    final file = File('${build.path}${Platform.pathSeparator}$relativePath');
    if (!file.existsSync()) {
      errors.add('Missing build output: $relativePath');
      return '';
    }
    return file.readAsStringSync();
  }

  final worker = read('sle_prep_sw.js');
  try {
    final entries = appShellPaths(worker);
    if (entries.any(
      (entry) =>
          entry == 'api' ||
          entry.startsWith('api/') ||
          entry == 'auth' ||
          entry.startsWith('auth/'),
    )) {
      errors.add('Private API/auth routes must never be in APP_SHELL');
    }
    final actualBuildId = currentBuildId(worker);
    final expectedBuildId = computePwaBuildId(build, worker);
    if (actualBuildId == buildIdPlaceholder) {
      errors.add('PWA build ID was not finalized');
    } else if (worker.contains(buildIdPlaceholder)) {
      errors.add('PWA build ID placeholder remains in the finalized worker');
    } else if (actualBuildId != expectedBuildId) {
      errors.add(
        'PWA build ID is stale: expected $expectedBuildId, '
        'found $actualBuildId',
      );
    }
  } on Object catch (error) {
    errors.add('Invalid service worker: $error');
  }

  final bootstrap = read('flutter_bootstrap.js');
  if (bootstrap.contains('{{flutter_js}}') ||
      bootstrap.contains('{{flutter_build_config}}')) {
    errors.add('Flutter bootstrap placeholders were not expanded');
  }
  if (!bootstrap.contains('sle_prep_sw.js')) {
    errors.add(
      'Custom service worker is not registered by flutter_bootstrap.js',
    );
  }

  final index = read('index.html');
  if (index.contains(r'$FLUTTER_BASE_HREF')) {
    errors.add('Flutter base-href placeholder was not expanded');
  }
  if (!index.contains('flutter_bootstrap.js') ||
      !index.contains('manifest.json')) {
    errors.add('index.html is missing its bootstrap or manifest reference');
  }

  final manifestText = read('manifest.json');
  try {
    final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
    final icons = manifest['icons'] as List<dynamic>? ?? const [];
    for (final icon in icons.whereType<Map<String, dynamic>>()) {
      final source = icon['src'];
      if (source is! String || source.isEmpty) {
        errors.add('Manifest contains an icon without a valid src');
        continue;
      }
      final iconPath =
          '${build.path}${Platform.pathSeparator}'
          '${source.replaceAll('/', Platform.pathSeparator)}';
      if (!File(iconPath).existsSync()) {
        errors.add('Manifest icon is missing: $source');
      }
    }
  } on Object catch (error) {
    errors.add('manifest.json is invalid: $error');
  }

  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln('PWA build validated: ${build.path}');
}
