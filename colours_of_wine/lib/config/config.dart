/* configuration parameters for .dart-files  */

// URL for our cloud functions; default is for testing, for production use: flutter run --dart-define=API_BASE_URL=https://us-central1-colours-of-wine.cloudfunctions.net

final baseURL = const String.fromEnvironment(
'API_BASE_URL', defaultValue: 'http://localhost:5001/colours-of-wine/us-central1',
);