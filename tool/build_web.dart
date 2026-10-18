import 'dart:convert';
import 'dart:io';

/// Build self-hosted Web resources and the offline cache manifest.
Future<void> main() async {
  final version = DateTime.now()
      .toUtc()
      .toIso8601String()
      .replaceAll(RegExp(r'\D'), '')
      .substring(0, 17);
  final local = Platform.isWindows
      ? '.tools/flutter/bin/flutter.bat'
      : '.tools/flutter/bin/flutter';
  final flutter = File(local).existsSync()
      ? File(local).absolute.path.replaceAll('/', Platform.pathSeparator)
      : 'flutter';
  final process = await Process.start(
    flutter,
    [
      'build',
      'web',
      '--release',
      '--dart-define=APP_BUILD=$version',
      '--target',
      'lib/main.dart',
      '--no-web-resources-cdn',
    ],
    runInShell: Platform.isWindows,
    environment: {'PUB_CACHE': Directory('.tools/pub-cache').absolute.path},
    mode: ProcessStartMode.inheritStdio,
  );
  final result = await process.exitCode;
  if (result != 0) exit(result);

  final output = Directory('build/web');
  final index = File('build/web/index.html');
  index.writeAsStringSync(
    index.readAsStringSync().replaceFirst(
      '<!-- OFFLINE_REGISTRATION -->',
      '<script src="app_update.js"></script>',
    ),
  );
  File('build/web/app-version.json')
      .writeAsStringSync(jsonEncode({'version': version}));
  File('build/web/app_update.js').writeAsStringSync(
    File('web/app_update.js')
        .readAsStringSync()
        .replaceAll('__BUILD_VERSION__', version),
  );
  final worker = File('web/offline_worker.js')
      .readAsStringSync()
      .replaceAll('__BUILD_VERSION__', version);
  File('build/web/offline_worker.js').writeAsStringSync(worker);
  final resources =
      output
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) {
            return file.path
                .replaceAll('\\', '/')
                .substring('build/web/'.length);
          })
          .where(
            (name) =>
                !name.endsWith('.map') &&
                ![
                  'offline-assets.json',
                  'app-version.json',
                  'offline_worker.js',
                ].contains(name),
          )
          .toList()
        ..sort();
  File('build/web/offline-assets.json')
      .writeAsStringSync(jsonEncode(resources));
  stdout.writeln(
    'Prepared ${resources.length} local resources for offline use. Version $version UTC.',
  );
}
