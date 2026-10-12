import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:building_management_tycoon/app/production_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'production catalog assets are included in the offline Flutter bundle',
    () async {
      final manifest = jsonDecode(
        await rootBundle.loadString(ProductionAssets.manifest),
      ) as Map<String, dynamic>;
      final assets = manifest['assets'] as List<dynamic>;
      expect(manifest['version'], 1);
      expect(assets, isNotEmpty);
      for (final raw in assets) {
        final asset = raw as Map<String, dynamic>;
        final path = asset['path'] as String;
        final bytes = await rootBundle.load(path);
        expect(bytes.lengthInBytes, asset['bytes'], reason: path);
      }
    },
  );
}
