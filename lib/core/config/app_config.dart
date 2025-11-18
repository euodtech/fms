class AppConfig {
  AppConfig._();

  // Provide GOOGLE_MAPS_API_KEY via: --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  static bool get hasGoogleMapsKey => googleMapsApiKey.trim().isNotEmpty;
}
