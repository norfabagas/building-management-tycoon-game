import 'app_update_gateway.dart';

AppUpdateGateway createAppUpdateGateway() => _LocalAppUpdate();

class _LocalAppUpdate implements AppUpdateGateway {
  @override
  bool get supported => false;
  @override
  String get currentVersion =>
      const String.fromEnvironment('APP_BUILD', defaultValue: 'development');
  @override
  Future<String> check() async => currentVersion;
  @override
  Future<String> sync(String version) async => 'unsupported';
}
