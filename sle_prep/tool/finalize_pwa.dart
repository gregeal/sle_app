import 'dart:io';

import 'pwa_build_support.dart';

void main(List<String> args) {
  if (args.length > 1) {
    stderr.writeln('Usage: dart run tool/finalize_pwa.dart [build/web]');
    exitCode = 64;
    return;
  }
  final build = Directory(args.isEmpty ? 'build/web' : args.single).absolute;
  final workerFile = File(pathInBuild(build, 'sle_prep_sw.js'));
  if (!workerFile.existsSync()) {
    stderr.writeln('Missing custom service worker: ${workerFile.path}');
    exitCode = 1;
    return;
  }

  try {
    final worker = workerFile.readAsStringSync();
    final normalizedWorker = normalizeWorkerBuildId(worker);
    final buildId = computePwaBuildId(build, normalizedWorker);
    final finalizedWorker = normalizedWorker.replaceFirst(
      buildIdPlaceholder,
      buildId,
    );
    if (finalizedWorker != worker) {
      workerFile.writeAsStringSync(finalizedWorker, flush: true);
    }
    stdout.writeln('PWA build finalized: $buildId');
  } on Object catch (error) {
    stderr.writeln('Could not finalize PWA build: $error');
    exitCode = 1;
  }
}
