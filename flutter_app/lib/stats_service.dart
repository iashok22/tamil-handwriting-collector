import 'dart:convert';

import 'package:http/http.dart' as http;

const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

class LetterStats {
  const LetterStats({required this.total, required this.counts});

  final int total;

  /// Letter slug -> number of handwriting samples collected.
  final Map<String, int> counts;
}

class StatsException implements Exception {
  StatsException(this.message);
  final String message;

  @override
  String toString() => message;
}

class StatsService {
  Future<LetterStats> fetchStats() async {
    final uri = Uri.parse('$_apiBaseUrl/api/stats');
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StatsException('Failed to load stats (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawCounts = (decoded['counts'] as Map<String, dynamic>? ?? {});
    return LetterStats(
      total: decoded['total'] as int? ?? 0,
      counts: rawCounts.map((slug, count) => MapEntry(slug, count as int)),
    );
  }
}
