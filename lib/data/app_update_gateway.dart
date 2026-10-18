abstract interface class AppUpdateGateway {
  bool get supported;
  String get currentVersion;
  Future<String> check();
  Future<String> sync(String version);
}
