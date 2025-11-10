import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

/// Service class for YFinance API integration via FastAPI backend
/// Fetches real-time stock and cryptocurrency prices from local backend
class YFinanceService {
  // Backend URL - change this to your computer's IP address when testing on real device
  // For iOS Simulator: use 'localhost' or '127.0.0.1'
  // For Android Emulator: use '10.0.2.2' 
  // For Real Device: use your computer's IP address (e.g., '192.168.1.100')
  static const String _baseUrl = 'http://10.0.2.2:8000';
  
  // Cache responses for 30 seconds to improve performance while keeping data fresh
  static final Map<String, CachedQuote> _quoteCache = {};
  static const Duration _cacheDuration = Duration(seconds: 30);

  /// Fetches real-time quote for a stock symbol
  /// Example: RELIANCE, TCS, INFY, HDFCBANK
  Future<StockQuote?> getStockQuote(String symbol) async {
    // Check cache first
    if (_isCacheValid(symbol)) {
      developer.log('Using cached quote for $symbol', name: 'YFinanceService');
      return _quoteCache[symbol]!.quote as StockQuote;
    }

    try {
      final uri = Uri.parse('$_baseUrl/quote/$symbol');
      developer.log('Fetching quote from: $uri', name: 'YFinanceService');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      developer.log('Response status for $symbol: ${response.statusCode}', name: 'YFinanceService');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log('Response data for $symbol: $data', name: 'YFinanceService');
        
        // Check for errors
        if (data.containsKey('error')) {
          throw Exception('API Error: ${data['error']}');
        }
        
        if (data.containsKey('detail')) {
          throw Exception(data['detail']);
        }

        final stockQuote = StockQuote(
          symbol: data['symbol'] ?? symbol,
          name: data['name'] ?? symbol,
          price: (data['price'] ?? 0).toDouble(),
          change: (data['change'] ?? 0).toDouble(),
          changePercent: (data['changePercent'] ?? 0).toDouble(),
          volume: data['volume'] ?? 0,
          previousClose: (data['previousClose'] ?? 0).toDouble(),
          open: (data['open'] ?? 0).toDouble(),
          high: (data['high'] ?? 0).toDouble(),
          low: (data['low'] ?? 0).toDouble(),
          latestTradingDay: data['latestTradingDay'] ?? '',
        );

        // Cache the result
        _quoteCache[symbol] = CachedQuote(
          quote: stockQuote,
          timestamp: DateTime.now(),
        );

        developer.log('Successfully parsed quote for $symbol', name: 'YFinanceService');
        return stockQuote;
      } else if (response.statusCode == 404) {
        throw Exception('Stock not found: $symbol');
      } else {
        throw Exception('Failed to fetch quote: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Error fetching stock quote for $symbol',
        name: 'YFinanceService',
        error: e,
      );
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
      final uri = Uri.parse('$_baseUrl/crypto/$symbol').replace(
        queryParameters: {'market': market},
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for errors
        if (data.containsKey('error')) {
          throw Exception('API Error: ${data['error']}');
        }
        
        if (data.containsKey('detail')) {
          throw Exception(data['detail']);
        }

        final cryptoQuote = CryptoQuote(
          symbol: data['symbol'] ?? symbol,
          market: data['market'] ?? market,
          price: (data['price'] ?? 0).toDouble(),
          change: (data['change'] ?? 0).toDouble(),
          changePercent: (data['changePercent'] ?? 0).toDouble(),
          bidPrice: (data['bidPrice'] ?? 0).toDouble(),
          askPrice: (data['askPrice'] ?? 0).toDouble(),
          lastRefreshed: data['lastRefreshed'] ?? '',
        );

        // Cache the result
        _quoteCache[cacheKey] = CachedQuote(
          quote: cryptoQuote,
          timestamp: DateTime.now(),
        );

        return cryptoQuote;
      } else if (response.statusCode == 404) {
        throw Exception('Crypto not found: $symbol');
      } else {
        throw Exception('Failed to fetch crypto quote: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Error fetching crypto quote for $symbol',
        name: 'YFinanceService',
        error: e,
      );
      return null;
    }
  }

  /// Fetches top stocks
  Future<List<StockQuote>> getTopStocks() async {
    try {
      final uri = Uri.parse('$_baseUrl/top');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['stocks'] == null) {
          return [];
        }

        final List<StockQuote> quotes = [];
        for (final stock in data['stocks']) {
          final quote = StockQuote(
            symbol: stock['symbol'] ?? '',
            name: stock['name'] ?? stock['symbol'] ?? '',
            price: (stock['price'] ?? 0).toDouble(),
            change: (stock['change'] ?? 0).toDouble(),
            changePercent: (stock['changePercent'] ?? 0).toDouble(),
            volume: stock['volume'] ?? 0,
            previousClose: (stock['previousClose'] ?? 0).toDouble(),
            open: (stock['open'] ?? 0).toDouble(),
            high: (stock['high'] ?? 0).toDouble(),
            low: (stock['low'] ?? 0).toDouble(),
            latestTradingDay: stock['latestTradingDay'] ?? '',
          );
          quotes.add(quote);
          
          // Cache each quote
          _quoteCache[quote.symbol] = CachedQuote(
            quote: quote,
            timestamp: DateTime.now(),
          );
        }

        return quotes;
      } else {
        throw Exception('Failed to fetch top stocks: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Error fetching top stocks',
        name: 'YFinanceService',
        error: e,
      );
      return [];
    }
  }

  /// Fetches multiple stock quotes in batch
  Future<List<StockQuote>> getMultipleStockQuotes(List<String> symbols) async {
    try {
      final symbolsParam = symbols.join(',');
      final uri = Uri.parse('$_baseUrl/batch').replace(
        queryParameters: {'symbols': symbolsParam},
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['stocks'] == null) {
          return [];
        }

        final List<StockQuote> quotes = [];
        for (final stock in data['stocks']) {
          final quote = StockQuote(
            symbol: stock['symbol'] ?? '',
            name: stock['name'] ?? stock['symbol'] ?? '',
            price: (stock['price'] ?? 0).toDouble(),
            change: (stock['change'] ?? 0).toDouble(),
            changePercent: (stock['changePercent'] ?? 0).toDouble(),
            volume: stock['volume'] ?? 0,
            previousClose: (stock['previousClose'] ?? 0).toDouble(),
            open: (stock['open'] ?? 0).toDouble(),
            high: (stock['high'] ?? 0).toDouble(),
            low: (stock['low'] ?? 0).toDouble(),
            latestTradingDay: stock['latestTradingDay'] ?? '',
          );
          quotes.add(quote);
          
          // Cache each quote
          _quoteCache[quote.symbol] = CachedQuote(
            quote: quote,
            timestamp: DateTime.now(),
          );
        }

        return quotes;
      } else {
        throw Exception('Failed to fetch batch quotes: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Error fetching batch quotes',
        name: 'YFinanceService',
        error: e,
      );
      return [];
    }
  }

  /// Fetches multiple crypto quotes in batch
  Future<List<CryptoQuote>> getMultipleCryptoQuotes(
    List<String> symbols, {
    String market = 'INR',
  }) async {
    final List<CryptoQuote> quotes = [];
    
    // Fetch them individually since backend doesn't have batch crypto endpoint
    for (final symbol in symbols) {
      final quote = await getCryptoQuote(symbol, market: market);
      if (quote != null) {
        quotes.add(quote);
      }
    }
    
    return quotes;
  }

  /// Search for stocks
  Future<List<SearchResult>> searchStocks(String query) async {
    if (query.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/search/$query');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['results'] == null) {
          return [];
        }

        final List<SearchResult> results = [];
        for (final result in data['results']) {
          results.add(SearchResult(
            symbol: result['symbol'] ?? '',
            name: result['name'] ?? '',
            type: result['type'] ?? 'stock',
          ));
        }

        return results;
      } else {
        throw Exception('Failed to search stocks: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Error searching stocks',
        name: 'YFinanceService',
        error: e,
      );
      return [];
    }
  }

  /// Checks if cached data is still valid
  bool _isCacheValid(String key) {
    if (!_quoteCache.containsKey(key)) return false;
    
    final cachedData = _quoteCache[key]!;
    final now = DateTime.now();
    final difference = now.difference(cachedData.timestamp);
    
    return difference < _cacheDuration;
  }

  /// Clears the cache (useful for manual refresh)
  void clearCache() {
    _quoteCache.clear();
  }

  /// Removes specific symbol from cache
  void removeCachedQuote(String symbol) {
    _quoteCache.remove(symbol);
  }

  /// Check if backend is reachable
  Future<bool> checkBackendHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      developer.log(
        'Backend health check failed',
        name: 'YFinanceService',
        error: e,
      );
      return false;
    }
  }
}

/// Stock quote data model
class StockQuote {
  final String symbol;
  final String name;
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
    required this.name,
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
    return 'StockQuote($symbol: ₹$price, ${changePercent.toStringAsFixed(2)}%)';
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
    return 'CryptoQuote($symbol/$market: ₹$price, ${changePercent.toStringAsFixed(2)}%)';
  }
}

/// Search result data model
class SearchResult {
  final String symbol;
  final String name;
  final String type;

  SearchResult({
    required this.symbol,
    required this.name,
    required this.type,
  });
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
