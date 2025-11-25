import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

/// Service class for fetching live USD to INR exchange rates
/// Uses ExchangeRate-API (free, no API key required)
/// Caches rates for 1 hour to minimize API calls (1,500 requests/month limit)
class ExchangeRateService {
  static const String _baseUrl =
      'https://api.exchangerate-api.com/v4/latest/USD';

  // Cache the exchange rate for 1 hour to reduce API calls
  static double? _cachedRate;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Gets live USD to INR exchange rate
  /// Returns cached rate if less than 1 hour old
  /// Falls back to 84.5 if API fails
  static Future<double> getUsdToInrRate() async {
    // Check if cache is still valid
    if (_cachedRate != null && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheDuration) {
        developer.log(
          'Using cached USD to INR rate: $_cachedRate (age: ${timeSinceLastFetch.inMinutes} minutes)',
          name: 'ExchangeRateService',
        );
        return _cachedRate!;
      }
    }

    try {
      developer.log(
        'Fetching live USD to INR rate from API',
        name: 'ExchangeRateService',
      );

      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ExchangeRate-API response structure:
        // {
        //   "rates": {
        //     "INR": 83.25,
        //     ...
        //   }
        // }
        if (data['rates'] != null && data['rates']['INR'] != null) {
          final rate = (data['rates']['INR'] as num).toDouble();

          // Update cache
          _cachedRate = rate;
          _lastFetchTime = DateTime.now();

          developer.log(
            'Successfully fetched USD to INR rate: $rate',
            name: 'ExchangeRateService',
          );

          return rate;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch rate: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Error fetching exchange rate: $e. Using fallback rate: 84.5',
        name: 'ExchangeRateService',
      );

      // Return fallback rate if API fails
      return _cachedRate ?? 84.5;
    }
  }

  /// Clears the cached rate (useful for testing or manual refresh)
  static void clearCache() {
    _cachedRate = null;
    _lastFetchTime = null;
    developer.log('Exchange rate cache cleared', name: 'ExchangeRateService');
  }

  /// Gets the age of cached rate in minutes
  /// Returns null if no cache
  static int? getCacheAge() {
    if (_lastFetchTime == null) return null;
    return DateTime.now().difference(_lastFetchTime!).inMinutes;
  }

  /// Checks if cache is valid
  static bool isCacheValid() {
    if (_cachedRate == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }
}
