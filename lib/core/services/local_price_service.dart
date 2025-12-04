import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Price point data model
class PricePoint {
  final String time;
  final double price;

  PricePoint({required this.time, required this.price});

  @override
  String toString() => 'PricePoint(time: $time, price: $price)';
}

/// Service to load stock prices from local JSON file
/// Uses assets/Stock Prices/stock_prices_2min_nov26.json
class LocalPriceService {
  static final LocalPriceService _instance = LocalPriceService._internal();
  factory LocalPriceService() => _instance;
  LocalPriceService._internal();

  Map<String, List<PricePoint>>? _priceData;
  bool _isLoaded = false;

  /// Load the JSON file once
  Future<void> loadPrices() async {
    if (_isLoaded) return;

    try {
      developer.log(
        'Loading local stock prices from JSON...',
        name: 'LocalPriceService',
      );
      final String jsonString = await rootBundle.loadString(
        'assets/Stock Prices/stock_prices_2min_nov26.json',
      );

      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> stocks = jsonData['stocks'] as List;

      _priceData = {};
      for (var stock in stocks) {
        final String symbol = stock['symbol'] as String;
        final List<dynamic> dataPoints = stock['data'] as List;

        _priceData![symbol] = dataPoints.map((point) {
          return PricePoint(
            time: point['time'] as String,
            price: (point['price'] as num).toDouble(),
          );
        }).toList();
      }

      _isLoaded = true;
      developer.log(
        'Loaded prices for ${_priceData!.length} stocks',
        name: 'LocalPriceService',
      );
    } catch (e, st) {
      developer.log(
        'Error loading local prices',
        name: 'LocalPriceService',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Get current (latest) price for a symbol
  double? getCurrentPrice(String symbol) {
    if (!_isLoaded || _priceData == null) return null;

    final prices = _priceData![symbol];
    if (prices == null || prices.isEmpty) return null;

    // Return the latest price
    return prices.last.price;
  }

  /// Get price at a specific time
  double? getPriceAtTime(String symbol, String time) {
    if (!_isLoaded || _priceData == null) return null;

    final prices = _priceData![symbol];
    if (prices == null || prices.isEmpty) return null;

    try {
      final pricePoint = prices.firstWhere(
        (p) => p.time == time,
        orElse: () => prices.last,
      );
      return pricePoint.price;
    } catch (e) {
      return prices.last.price;
    }
  }

  /// Get price change percentage (compared to first price of the day)
  double getChangePercent(String symbol) {
    if (!_isLoaded || _priceData == null) return 0.0;

    final prices = _priceData![symbol];
    if (prices == null || prices.length < 2) return 0.0;

    final firstPrice = prices.first.price;
    final lastPrice = prices.last.price;

    return ((lastPrice - firstPrice) / firstPrice) * 100;
  }

  /// Get all price points for a symbol
  List<PricePoint>? getAllPrices(String symbol) {
    if (!_isLoaded || _priceData == null) return null;
    return _priceData![symbol];
  }

  /// Get list of all available symbols
  List<String> getAvailableSymbols() {
    if (!_isLoaded || _priceData == null) return [];
    return _priceData!.keys.toList();
  }

  /// Simulate real-time updates by cycling through price points
  /// Returns the next price point in the sequence
  int _currentIndex = 0;

  PricePoint? getNextPrice(String symbol) {
    if (!_isLoaded || _priceData == null) return null;

    final prices = _priceData![symbol];
    if (prices == null || prices.isEmpty) return null;

    _currentIndex = (_currentIndex + 1) % prices.length;
    return prices[_currentIndex];
  }

  /// Reset simulation index
  void resetSimulation() {
    _currentIndex = 0;
  }
}
