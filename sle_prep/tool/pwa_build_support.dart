import 'dart:convert';
import 'dart:io';

const buildIdPlaceholder = '__SLE_PREP_BUILD_ID__';

final _appShellPattern = RegExp(r'const APP_SHELL = \[(.*?)\];', dotAll: true);
final _cacheVersionPattern = RegExp(
  r'const CACHE_VERSION = `\$\{CACHE_PREFIX\}([^`]+)`;',
);

String currentBuildId(String worker) {
  final match = _cacheVersionPattern.firstMatch(worker);
  if (match == null) {
    throw const FormatException('Could not parse CACHE_VERSION');
  }
  return match.group(1)!;
}

String normalizeWorkerBuildId(String worker) {
  final match = _cacheVersionPattern.firstMatch(worker);
  if (match == null) {
    throw const FormatException('Could not parse CACHE_VERSION');
  }
  final normalizedDeclaration = match
      .group(0)!
      .replaceFirst(match.group(1)!, buildIdPlaceholder);
  return worker.replaceRange(match.start, match.end, normalizedDeclaration);
}

Set<String> appShellPaths(String worker) {
  final match = _appShellPattern.firstMatch(worker);
  if (match == null) {
    throw const FormatException('Could not parse APP_SHELL');
  }
  final paths = <String>{};
  for (final entry in RegExp(r'"(\./[^"?]*)"').allMatches(match.group(1)!)) {
    var path = entry.group(1)!.substring(2);
    if (path.isEmpty) path = 'index.html';
    final uri = Uri.tryParse(path);
    if (uri == null ||
        uri.isAbsolute ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.pathSegments.contains('..')) {
      throw FormatException('Unsafe APP_SHELL entry: $path');
    }
    paths.add(path);
  }
  if (paths.isEmpty) throw const FormatException('APP_SHELL is empty');
  return paths;
}

String pathInBuild(Directory build, String relativePath) =>
    '${build.path}${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}';

String computePwaBuildId(Directory build, String worker) {
  final normalizedWorker = normalizeWorkerBuildId(worker);
  final paths = appShellPaths(normalizedWorker).toList()..sort();
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = BigInt.parse('ffffffffffffffff', radix: 16);

  void addBytes(List<int> bytes) {
    for (final byte in bytes) {
      hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
    }
  }

  addBytes(utf8.encode(normalizedWorker));
  for (final path in paths) {
    final file = File(pathInBuild(build, path));
    if (!file.existsSync()) {
      throw FileSystemException('APP_SHELL file is missing', file.path);
    }
    addBytes(utf8.encode('\u0000$path\u0000'));
    addBytes(file.readAsBytesSync());
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
