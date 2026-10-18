/// Laravel backend base URL (no trailing slash).
class ApiConfig {
  /// Production API from Postman collection `linkupvibes.com`.
  /// Override for local dev: `flutter run --dart-define=LINKUP_API_URL=http://10.0.2.2:8000`
  /// (Android emulator) or your machine's LAN IP on a physical device.
  static const String baseUrl = String.fromEnvironment(
    'LINKUP_API_URL',
    defaultValue: 'https://linkupvibes.com',
  );

  static const String apiPrefix = '/api';
}
