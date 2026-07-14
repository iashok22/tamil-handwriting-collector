import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// API base URL. Empty (the default) means "same origin, relative /api" —
/// correct for the production Vercel deployment where the Flutter web build
/// and the serverless function share a domain. For local dev, pass
/// --dart-define=API_BASE_URL=http://localhost:3000 to point at `vercel dev`.
const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

class UploadException implements Exception {
  UploadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Uploads a captured drawing (PNG bytes) labeled with the Tamil letter it
/// depicts to the backend, which stores it in Vercel Blob under the
/// letter's slug.
class UploadService {
  Future<void> upload({
    required String letterSlug,
    required String letterDisplay,
    required Uint8List imageBytes,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/api/upload');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'letterSlug': letterSlug,
        'letterDisplay': letterDisplay,
        'imageBase64': base64Encode(imageBytes),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UploadException(
        'Upload failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
