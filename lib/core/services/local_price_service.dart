import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:developer' as developer;

class LocalPriceService {
  // Configure asset paths here; supports JSON or CSV (future)
  // Example JSON structure: [{"symbol":"RELIANCE","price": 2500.0}, ...]
  static const String stockJsonPath =
      'assets/Stock Prices/stock_prices_2min_nov26.json';

  Map<String, double>? _stockPrices;

  Future<void> _ensureLoaded() async {
    // Reload once per app run or on demand
    if (_stockPrices != null) return;
    try {
      final raw = await rootBundle.loadString(stockJsonPath);
      final data = json.decode(raw);
      final Map<String, double> map = {};
      if (data is List) {
        for (final item in data) {
          final symbol = (item['symbol'] ?? item['Symbol'] ?? '')
              .toString()
              .toUpperCase();
          final priceVal = item['price'] ?? item['Close'] ?? item['close'];
          if (symbol.isEmpty || priceVal == null) continue;
          map[symbol] = (priceVal as num).toDouble();
        }
      } else if (data is Map) {
        data.forEach((key, value) {
          if (value == null) return;
          map[key.toString().toUpperCase()] = (value as num).toDouble();
        });
      }
      _stockPrices = map;
      developer.log(
        'LocalPriceService: Loaded ${map.length} symbols from assets',
        name: 'LocalPriceService',
      );
    } catch (e, st) {
      developer.log(
        'LocalPriceService: Failed to load local prices',
        error: e,
        stackTrace: st,
        name: 'LocalPriceService',
      );
      _stockPrices = {};
    }
  }

  Future<double?> getStockPrice(String symbol) async {
    await _ensureLoaded();
    if (_stockPrices == null) return null;
    return _stockPrices![symbol.toUpperCase()];
  }

  Future<Map<String, double>> getBatchStockPrices(List<String> symbols) async {
    await _ensureLoaded();
    final Map<String, double> out = {};
    if (_stockPrices == null) return out;
    for (final s in symbols) {
      final p = _stockPrices![s.toUpperCase()];
      if (p != null) out[s] = p;
    }
    return out;
  }
}
