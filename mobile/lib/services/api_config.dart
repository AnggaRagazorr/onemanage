import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    // Read from .env, fallback to emulator if missing
    return dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/api';
  }
}
