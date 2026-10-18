import 'dart:js_interop';

import 'app_update_gateway.dart';

@JS('tycoonUpdates.check')
external JSPromise<JSString> _check();
@JS('tycoonUpdates.sync')
external JSPromise<JSString> _sync(JSString version);

AppUpdateGateway createAppUpdateGateway() => _WebAppUpdate();

class _WebAppUpdate implements AppUpdateGateway {
  @override
  bool get supported => true;
  @override
  String get currentVersion =>
      const String.fromEnvironment('APP_BUILD', defaultValue: 'development');
  @override
  Future<String> check() async => (await _check().toDart).toDart;
  @override
  Future<String> sync(String version) async =>
      (await _sync(version.toJS).toDart).toDart;
}
