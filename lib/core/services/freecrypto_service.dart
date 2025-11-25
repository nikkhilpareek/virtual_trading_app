import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'exchange_rate_service.dart';

/// Service class for FreeCryptoAPI integration
/// Fetches real-time cryptocurrency prices and market data
/// API Docs: https://www.freecryptoapi.com/
///
/// NOTE: The API returns prices in USD. We convert to INR using live exchange rates.
class FreeCryptoService {
  static const String _baseUrl = 'https://api.freecryptoapi.com/v1';
  static const String _apiKey = '127osz6wwio8x9al1hza';

  // Cache responses for 5 seconds to reduce API calls
  static final Map<String, CachedCryptoData> _cache = {};
  static const Duration _cacheDuration = Duration(seconds: 5);
  
  // Cache historical data for 1 hour to avoid rate limits
  static final Map<String, CachedHistoricalData> _historicalCache = {};
  static const Duration _historicalCacheDuration = Duration(hours: 1);
  
  // Rate limiting: Track last API call time for CoinGecko
  static DateTime? _lastCoinGeckoCall;
  static const Duration _minTimeBetweenCalls = Duration(seconds: 2);

  /// Fetches real-time price for a cryptocurrency
  /// [symbol] - Crypto symbol (e.g., 'BTC', 'ETH', 'BNB')
  /// [currency] - Fiat currency (default: 'USD' - API only supports USD)
  Future<CryptoQuote?> getCryptoPrice(
    String symbol, {
    String currency = 'USD',
  }) async {
    final cacheKey = '$symbol-$currency';

    // Check cache first
    if (_isCacheValid(cacheKey)) {
      developer.log(
        'Using cached crypto data for $symbol',
        name: 'FreeCryptoService',
      );
      return _cache[cacheKey]!.quote;
    }

    try {
      // FreeCryptoAPI endpoint format: /getData?symbol={symbol}&token={apikey}
      final uri = Uri.parse('$_baseUrl/getData?symbol=$symbol&token=$_apiKey');
      developer.log(
        'Fetching crypto price from: $uri',
        name: 'FreeCryptoService',
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      developer.log(
        'Response status for $symbol: ${response.statusCode}',
        name: 'FreeCryptoService',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        developer.log(
          'Response data for $symbol: $data',
          name: 'FreeCryptoService',
        );

        // FreeCryptoAPI response structure
        if (data['status'] == 'success' &&
            data['symbols'] != null &&
            (data['symbols'] as List).isNotEmpty) {
          final cryptoData = data['symbols'][0];

          // Parse price in USD (actual API value)
          final priceUSD =
              double.tryParse(cryptoData['last']?.toString() ?? '0') ?? 0.0;

          // Get live USD to INR exchange rate (cached for 1 hour)
          final usdToInrRate = await ExchangeRateService.getUsdToInrRate();

          // Convert USD prices to INR
          final priceINR = priceUSD * usdToInrRate;

          // Parse daily change percentage
          final changePercent =
              double.tryParse(
                cryptoData['daily_change_percentage']?.toString() ?? '0',
              ) ??
              0.0;
          final change24h = priceINR * (changePercent / 100);

          final quote = CryptoQuote(
            symbol: symbol.toUpperCase(),
            name: _getCryptoName(symbol),
            price: priceINR,
            change24h: change24h,
            changePercent24h: changePercent,
            marketCap: 0.0, // Not provided by free tier
            volume24h: 0.0, // Not provided by free tier
            high24h:
                (double.tryParse(cryptoData['highest']?.toString() ?? '0') ??
                    0.0) *
                usdToInrRate,
            low24h:
                (double.tryParse(cryptoData['lowest']?.toString() ?? '0') ??
                    0.0) *
                usdToInrRate,
            currency: 'INR',
            lastUpdated: DateTime.now(),
          );

          // Cache the result
          _cache[cacheKey] = CachedCryptoData(
            quote: quote,
            timestamp: DateTime.now(),
          );

          developer.log(
            'Successfully parsed crypto quote for $symbol (USD->INR rate: ${usdToInrRate.toStringAsFixed(2)})',
            name: 'FreeCryptoService',
          );
          return quote;
        } else {
          throw Exception(
            'Invalid response format: ${data['error'] ?? 'Unknown error'}',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('Cryptocurrency not found: $symbol');
      } else {
        throw Exception('Failed to fetch crypto price: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Error fetching crypto price for $symbol',
        name: 'FreeCryptoService',
        error: e,
      );
      // Return null instead of throwing to allow graceful degradation
      return null;
    }
  }

  /// Fetches multiple cryptocurrency prices in a single batch
  /// More efficient than individual calls
  Future<Map<String, CryptoQuote>> getBatchCryptoPrices(
    List<String> symbols, {
    String currency = 'INR',
  }) async {
    final results = <String, CryptoQuote>{};

    // Fetch all prices concurrently
    final futures = symbols.map(
      (symbol) => getCryptoPrice(symbol, currency: currency),
    );
    final quotes = await Future.wait(futures);

    for (var i = 0; i < symbols.length; i++) {
      if (quotes[i] != null) {
        results[symbols[i]] = quotes[i]!;
      }
    }

    return results;
  }

  /// Fetches list of top cryptocurrencies by market cap
  /// Returns a predefined list since FreeCryptoAPI may not have a "top coins" endpoint
  Future<List<CryptoQuote>> getTopCryptos({
    String currency = 'USD',
    int limit = 20,
  }) async {
    // Popular cryptocurrencies to fetch
    final topSymbols = [
      'BTC',
      'ETH',
      'BNB',
      'XRP',
      'ADA',
      'DOGE',
      'SOL',
      'MATIC',
      'DOT',
      'SHIB',
      'TRX',
      'AVAX',
      'UNI',
      'LINK',
      'LTC',
      'BCH',
      'XLM',
      'ATOM',
      'ETC',
      'FIL',
    ];

    final limitedSymbols = topSymbols.take(limit).toList();
    final quotes = await getBatchCryptoPrices(
      limitedSymbols,
      currency: currency,
    );

    // Return quotes in the predefined order (by popularity)
    return quotes.values.toList();
  }

  /// Search cryptocurrencies by name or symbol
  Future<List<CryptoSearchResult>> searchCrypto(String query) async {
    // Since FreeCryptoAPI might not have search, return filtered predefined list
    final allCryptos = [
      CryptoSearchResult('BTC', 'Bitcoin'),
      CryptoSearchResult('ETH', 'Ethereum'),
      CryptoSearchResult('BNB', 'Binance Coin'),
      CryptoSearchResult('XRP', 'Ripple'),
      CryptoSearchResult('ADA', 'Cardano'),
      CryptoSearchResult('DOGE', 'Dogecoin'),
      CryptoSearchResult('SOL', 'Solana'),
      CryptoSearchResult('MATIC', 'Polygon'),
      CryptoSearchResult('DOT', 'Polkadot'),
      CryptoSearchResult('SHIB', 'Shiba Inu'),
      CryptoSearchResult('TRX', 'TRON'),
      CryptoSearchResult('AVAX', 'Avalanche'),
      CryptoSearchResult('UNI', 'Uniswap'),
      CryptoSearchResult('LINK', 'Chainlink'),
      CryptoSearchResult('LTC', 'Litecoin'),
      CryptoSearchResult('BCH', 'Bitcoin Cash'),
      CryptoSearchResult('XLM', 'Stellar'),
      CryptoSearchResult('ATOM', 'Cosmos'),
      CryptoSearchResult('ETC', 'Ethereum Classic'),
      CryptoSearchResult('FIL', 'Filecoin'),
      CryptoSearchResult('APT', 'Aptos'),
      CryptoSearchResult('NEAR', 'NEAR Protocol'),
      CryptoSearchResult('VET', 'VeChain'),
      CryptoSearchResult('ALGO', 'Algorand'),
      CryptoSearchResult('XMR', 'Monero'),
    ];

    if (query.isEmpty) return allCryptos;

    final lowerQuery = query.toLowerCase();
    return allCryptos.where((crypto) {
      return crypto.symbol.toLowerCase().contains(lowerQuery) ||
          crypto.name.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Check if cached data is still valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;

    final cachedData = _cache[key]!;
    final age = DateTime.now().difference(cachedData.timestamp);

    return age < _cacheDuration;
  }

  /// Get cryptocurrency full name from symbol
  String _getCryptoName(String symbol) {
    final names = {
      'BTC': 'Bitcoin',
      'ETH': 'Ethereum',
      'BNB': 'Binance Coin',
      'XRP': 'Ripple',
      'ADA': 'Cardano',
      'DOGE': 'Dogecoin',
      'SOL': 'Solana',
      'MATIC': 'Polygon',
      'DOT': 'Polkadot',
      'SHIB': 'Shiba Inu',
      'TRX': 'TRON',
      'AVAX': 'Avalanche',
      'UNI': 'Uniswap',
      'LINK': 'Chainlink',
      'LTC': 'Litecoin',
      'BCH': 'Bitcoin Cash',
      'XLM': 'Stellar',
      'ATOM': 'Cosmos',
      'ETC': 'Ethereum Classic',
      'FIL': 'Filecoin',
      'APT': 'Aptos',
      'NEAR': 'NEAR Protocol',
      'VET': 'VeChain',
      'ALGO': 'Algorand',
      'XMR': 'Monero',
    };

    return names[symbol.toUpperCase()] ?? symbol;
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
  }

  /// Fetches historical price data for a cryptocurrency using CoinGecko API
  /// [symbol] - Crypto symbol (e.g., 'BTC', 'ETH', 'BNB')
  /// [days] - Number of days of historical data (1, 7, 30, 90, 365)
  /// Returns list of price points with timestamps
  /// Cached for 1 hour to avoid rate limits
  Future<List<HistoricalPricePoint>> getHistoricalPrices(
    String symbol,
    int days,
  ) async {
    final cacheKey = '$symbol-$days';
    
    // Check if we have cached data
    if (_historicalCache.containsKey(cacheKey)) {
      final cached = _historicalCache[cacheKey]!;
      final age = DateTime.now().difference(cached.timestamp);
      
      if (age < _historicalCacheDuration) {
        developer.log(
          'Using cached historical data for $symbol ($days days) - age: ${age.inMinutes} minutes',
          name: 'FreeCryptoService',
        );
        return cached.data;
      }
    }
    
    try {
      // Rate limiting: Wait if needed to avoid hitting API limits
      if (_lastCoinGeckoCall != null) {
        final timeSinceLastCall = DateTime.now().difference(_lastCoinGeckoCall!);
        if (timeSinceLastCall < _minTimeBetweenCalls) {
          final waitTime = _minTimeBetweenCalls - timeSinceLastCall;
          developer.log(
            'Rate limiting: Waiting ${waitTime.inMilliseconds}ms before API call',
            name: 'FreeCryptoService',
          );
          await Future.delayed(waitTime);
        }
      }
      
      // Map crypto symbols to CoinGecko IDs
      final coinGeckoId = _getCoinGeckoId(symbol);
      
      // CoinGecko free API endpoint
      final uri = Uri.parse(
        'https://api.coingecko.com/api/v3/coins/$coinGeckoId/market_chart?vs_currency=usd&days=$days',
      );
      
      developer.log(
        'Fetching historical data for $symbol from CoinGecko',
        name: 'FreeCryptoService',
      );

      _lastCoinGeckoCall = DateTime.now(); // Update last call time

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // CoinGecko response: { "prices": [[timestamp, price], ...] }
        if (data['prices'] != null) {
          final prices = data['prices'] as List;
          
          // Get live USD to INR exchange rate
          final usdToInrRate = await ExchangeRateService.getUsdToInrRate();
          
          final historicalData = prices.map((item) {
            final timestamp = DateTime.fromMillisecondsSinceEpoch(item[0]);
            final priceUSD = (item[1] as num).toDouble();
            final priceINR = priceUSD * usdToInrRate;
            
            return HistoricalPricePoint(
              timestamp: timestamp,
              price: priceINR,
            );
          }).toList();

          // Cache the result for 1 hour
          _historicalCache[cacheKey] = CachedHistoricalData(
            data: historicalData,
            timestamp: DateTime.now(),
          );

          developer.log(
            'Successfully fetched ${historicalData.length} historical data points for $symbol (cached)',
            name: 'FreeCryptoService',
          );

          return historicalData;
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again later.');
      } else {
        throw Exception('Failed to fetch historical data: ${response.statusCode}');
      }
    } catch (e) {
      developer.log(
        'Error fetching historical data for $symbol: $e',
        name: 'FreeCryptoService',
      );
      rethrow;
    }
  }

  /// Maps crypto symbols to CoinGecko IDs
  String _getCoinGeckoId(String symbol) {
    final ids = {
      'BTC': 'bitcoin',
      'ETH': 'ethereum',
      'BNB': 'binancecoin',
      'XRP': 'ripple',
      'ADA': 'cardano',
      'DOGE': 'dogecoin',
      'SOL': 'solana',
      'MATIC': 'matic-network',
      'DOT': 'polkadot',
      'SHIB': 'shiba-inu',
      'TRX': 'tron',
      'AVAX': 'avalanche-2',
      'UNI': 'uniswap',
      'LINK': 'chainlink',
      'LTC': 'litecoin',
      'BCH': 'bitcoin-cash',
      'XLM': 'stellar',
      'ATOM': 'cosmos',
      'ETC': 'ethereum-classic',
      'FIL': 'filecoin',
      'APT': 'aptos',
      'NEAR': 'near',
      'VET': 'vechain',
      'ALGO': 'algorand',
      'XMR': 'monero',
    };

    return ids[symbol.toUpperCase()] ?? symbol.toLowerCase();
  }
}

/// Cryptocurrency Quote Model
class CryptoQuote {
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final double changePercent24h;
  final double marketCap;
  final double volume24h;
  final double high24h;
  final double low24h;
  final String currency;
  final DateTime lastUpdated;

  const CryptoQuote({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    required this.changePercent24h,
    required this.marketCap,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    required this.currency,
    required this.lastUpdated,
  });

  CryptoQuote copyWith({
    String? symbol,
    String? name,
    double? price,
    double? change24h,
    double? changePercent24h,
    double? marketCap,
    double? volume24h,
    double? high24h,
    double? low24h,
    String? currency,
    DateTime? lastUpdated,
  }) {
    return CryptoQuote(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
      changePercent24h: changePercent24h ?? this.changePercent24h,
      marketCap: marketCap ?? this.marketCap,
      volume24h: volume24h ?? this.volume24h,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isPositive => changePercent24h >= 0;
}

/// Cached crypto data with timestamp
class CachedCryptoData {
  final CryptoQuote quote;
  final DateTime timestamp;

  CachedCryptoData({required this.quote, required this.timestamp});
}

/// Cached historical data with timestamp
class CachedHistoricalData {
  final List<HistoricalPricePoint> data;
  final DateTime timestamp;

  CachedHistoricalData({required this.data, required this.timestamp});
}

/// Crypto search result
class CryptoSearchResult {
  final String symbol;
  final String name;

  CryptoSearchResult(this.symbol, this.name);
}

/// Historical price point with timestamp
class HistoricalPricePoint {
  final DateTime timestamp;
  final double price;

  HistoricalPricePoint({
    required this.timestamp,
    required this.price,
  });
}
