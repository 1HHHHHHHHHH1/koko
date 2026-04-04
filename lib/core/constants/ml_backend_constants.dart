class MLBackendConstants {
  const MLBackendConstants._();

  // Change only this line to switch between matching engines.
  static const String activeBaseUrl = legacyBaseUrl;

  // Existing keyword/rules-based engine.
  static const String legacyBaseUrl = 'https://ml-backend-aq54.onrender.com';

  // Deploy the new semantic backend, then paste its URL here when ready.
  static const String semanticBaseUrl =
      'https://your-semantic-backend.onrender.com';
}
