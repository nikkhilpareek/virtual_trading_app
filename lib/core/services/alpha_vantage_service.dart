import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for Alpha Vantage API integration
/// Fetches real-time stock and cryptocurrency prices
class AlphaVantageService {
  static const String _apiKey = 'II5VB4PZ3EP56LG9';
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  
  // Rate limiting: Free tier allows 25 API calls per day
  // Cache responses for 5 minutes to avoid hitting rate limits
  static final Map<String, CachedQuote> _quoteCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Fetches real-time quote for a stock symbol
  /// Example: AAPL, GOOGL, MSFT
  Future<StockQuote?> getStockQuote(String symbol) async {
    // Check cache first
    if (_isCacheValid(symbol)) {
      return _quoteCache[symbol]!.quote as StockQuote;
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'function': 'GLOBAL_QUOTE',
        'symbol': symbol,
        'apikey': _apiKey,
      });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for API errors
        if (data.containsKey('Error Message')) {
          throw Exception('API Error: ${data['Error Message']}');
        }
        
        if (data.containsKey('Note')) {
          // Rate limit exceeded
          throw Exception('Rate limit exceeded. Please try again later.');
        }

        if (!data.containsKey('Global Quote')) {
          throw Exception('Invalid response format');
        }

        final quote = data['Global Quote'];
        if (quote.isEmpty) {
          throw Exception('No data found for symbol: $symbol');
        }

        final stockQuote = StockQuote(
          symbol: symbol,
          price: double.tryParse(quote['05. price'] ?? '0') ?? 0.0,
          change: double.tryParse(quote['09. change'] ?? '0') ?? 0.0,
          changePercent: _parseChangePercent(quote['10. change percent']),
          volume: int.tryParse(quote['06. volume'] ?? '0') ?? 0,
          previousClose: double.tryParse(quote['08. previous close'] ?? '0') ?? 0.0,
          open: double.tryParse(quote['02. open'] ?? '0') ?? 0.0,
          high: double.tryParse(quote['03. high'] ?? '0') ?? 0.0,
          low: double.tryParse(quote['04. low'] ?? '0') ?? 0.0,
          latestTradingDay: quote['07. latest trading day'] ?? '',
        );

        // Cache the result
        _quoteCache[symbol] = CachedQuote(
          quote: stockQuote,
          timestamp: DateTime.now(),
        );

        return stockQuote;
      } else {
        throw Exception('Failed to fetch quote: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching stock quote for $symbol: $e');
      return null;
    }
  }

  /// Fetches real-time exchange rate for cryptocurrency
  /// Example: BTC, ETH, BNB to INR (Indian Rupee)
  Future<CryptoQuote?> getCryptoQuote(String symbol, {String market = 'INR'}) async {
    final cacheKey = '$symbol-$market';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _quoteCache[cacheKey]!.quote as CryptoQuote;
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'function': 'CURRENCY_EXCHANGE_RATE',
        'from_currency': symbol,
        'to_currency': market,
        'apikey': _apiKey,
      });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for API errors
        if (data.containsKey('Error Message')) {
          throw Exception('API Error: ${data['Error Message']}');
        }
        
        if (data.containsKey('Note')) {
          // Rate limit exceeded
          throw Exception('Rate limit exceeded. Please try again later.');
        }

        if (!data.containsKey('Realtime Currency Exchange Rate')) {
          throw Exception('Invalid response format');
        }

        final exchangeRate = data['Realtime Currency Exchange Rate'];
        final price = double.tryParse(exchangeRate['5. Exchange Rate'] ?? '0') ?? 0.0;
        final previousClose = double.tryParse(exchangeRate['8. Previous Close'] ?? '0') ?? 0.0;
        
        // Calculate change
        final change = price - previousClose;
        final changePercent = previousClose > 0 ? (change / previousClose) * 100 : 0.0;

        final cryptoQuote = CryptoQuote(
          symbol: symbol,
          market: market,
          price: price,
          change: change,
          changePercent: changePercent,
          bidPrice: double.tryParse(exchangeRate['8. Bid Price'] ?? '0') ?? 0.0,
          askPrice: double.tryParse(exchangeRate['9. Ask Price'] ?? '0') ?? 0.0,
          lastRefreshed: exchangeRate['6. Last Refreshed'] ?? '',
        );

        // Cache the result
        _quoteCache[cacheKey] = CachedQuote(
          quote: cryptoQuote,
          timestamp: DateTime.now(),
        );

        return cryptoQuote;
      } else {
        throw Exception('Failed to fetch crypto quote: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching crypto quote for $symbol: $e');
      return null;
    }
  }

  /// Fetches multiple stock quotes in batch
  /// Note: Free tier has rate limits, so this may take time
  Future<List<StockQuote>> getMultipleStockQuotes(List<String> symbols) async {
    final List<StockQuote> quotes = [];
    
    for (final symbol in symbols) {
      final quote = await getStockQuote(symbol);
      if (quote != null) {
        quotes.add(quote);
      }
      
      // Add a small delay between requests to avoid rate limiting
      if (symbols.indexOf(symbol) < symbols.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    return quotes;
  }

  /// Fetches multiple crypto quotes in batch
  Future<List<CryptoQuote>> getMultipleCryptoQuotes(
    List<String> symbols, {
    String market = 'INR',
  }) async {
    final List<CryptoQuote> quotes = [];
    
    for (final symbol in symbols) {
      final quote = await getCryptoQuote(symbol, market: market);
      if (quote != null) {
        quotes.add(quote);
      }
      
      // Add a small delay between requests to avoid rate limiting
      if (symbols.indexOf(symbol) < symbols.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    return quotes;
  }

  /// Checks if cached data is still valid
  bool _isCacheValid(String key) {
    if (!_quoteCache.containsKey(key)) return false;
    
    final cachedData = _quoteCache[key]!;
    final now = DateTime.now();
    final difference = now.difference(cachedData.timestamp);
    
    return difference < _cacheDuration;
  }

  /// Parses change percent string (e.g., "1.2345%" -> 1.2345)
  double _parseChangePercent(String? percentStr) {
    if (percentStr == null || percentStr.isEmpty) return 0.0;
    
    // Remove % sign and parse
    final cleaned = percentStr.replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Clears the cache (useful for manual refresh)
  void clearCache() {
    _quoteCache.clear();
  }

  /// Removes specific symbol from cache
  void removeCachedQuote(String symbol) {
    _quoteCache.remove(symbol);
  }
}

/// Stock quote data model
class StockQuote {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final int volume;
  final double previousClose;
  final double open;
  final double high;
  final double low;
  final String latestTradingDay;

  StockQuote({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.latestTradingDay,
  });

  bool get isPositive => change >= 0;

  @override
  String toString() {
    return 'StockQuote($symbol: \$$price, ${changePercent.toStringAsFixed(2)}%)';
  }
}

/// Cryptocurrency quote data model
class CryptoQuote {
  final String symbol;
  final String market;
  final double price;
  final double change;
  final double changePercent;
  final double bidPrice;
  final double askPrice;
  final String lastRefreshed;

  CryptoQuote({
    required this.symbol,
    required this.market,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.bidPrice,
    required this.askPrice,
    required this.lastRefreshed,
  });

  bool get isPositive => change >= 0;

  @override
  String toString() {
    return 'CryptoQuote($symbol/$market: \$$price, ${changePercent.toStringAsFixed(2)}%)';
  }
}

/// Cached quote with timestamp
class CachedQuote {
  final dynamic quote; // Can be StockQuote or CryptoQuote
  final DateTime timestamp;

  CachedQuote({
    required this.quote,
    required this.timestamp,
  });
}
