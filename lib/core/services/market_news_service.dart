import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class MarketNewsService {
  final List<String> baseUrls;
  MarketNewsService({List<String>? baseUrls})
    : baseUrls = baseUrls ?? MarketNewsService.defaultCandidates();

  static List<String> defaultCandidates() {
    // Prefer Android emulator loopback when on Android
    if (kIsWeb) {
      return ['http://localhost:8080'];
    }
    try {
      if (Platform.isAndroid) {
        return ['http://10.0.2.2:8080', 'http://localhost:8080'];
      }
    } catch (_) {
      // Platform may throw in some environments; fall back to localhost
    }
    return ['http://localhost:8080'];
  }

  Future<List<String>> fetchHighlights({int limit = 5}) async {
    Exception? lastError;
    for (final base in baseUrls) {
      final uri = Uri.parse('$base/market-news?limit=$limit');
      try {
        final resp = await http
            .get(uri, headers: {"Accept": "application/json"})
            .timeout(const Duration(seconds: 12));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final List<dynamic> list = (data['highlights'] as List?) ?? [];
          return list.map((e) => e.toString()).toList();
        }
        lastError = Exception('HTTP ${resp.statusCode} from $uri');
      } catch (e) {
        lastError = Exception('Failed on $uri: $e');
        // Try next candidate
        continue;
      }
    }
    throw lastError ??
        Exception('All endpoints unreachable: ${baseUrls.join(", ")}');
  }
}
