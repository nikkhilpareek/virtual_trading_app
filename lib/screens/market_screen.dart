import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/services/yfinance_service.dart';
import '../core/services/local_price_service.dart';
import '../core/utils/currency_formatter.dart';
import 'market_stock_detail_screen.dart';
import 'dart:developer' as developer;
import 'dart:async';

// Market asset data model with real-time prices
class MarketAsset {
  final String symbol;
  final String name;
  final double currentPrice;
  final double changePercentage;
  final AssetType type;
  final DateTime? lastUpdated;

  const MarketAsset({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.changePercentage,
    required this.type,
    this.lastUpdated,
  });

  MarketAsset copyWith({
    String? symbol,
    String? name,
    double? currentPrice,
    double? changePercentage,
    AssetType? type,
    DateTime? lastUpdated,
  }) {
    return MarketAsset(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      currentPrice: currentPrice ?? this.currentPrice,
      changePercentage: changePercentage ?? this.changePercentage,
      type: type ?? this.type,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Asset definitions for Indian Market (NSE)
// Prices will be fetched from YFinance API via FastAPI backend
const List<Map<String, dynamic>> _assetDefinitions = [
  // Indian Stocks (NSE)
  {
    'symbol': 'RELIANCE',
    'name': 'Reliance Industries',
    'type': AssetType.stock,
  },
  {
    'symbol': 'TCS',
    'name': 'Tata Consultancy Services',
    'type': AssetType.stock,
  },
  {'symbol': 'INFY', 'name': 'Infosys Limited', 'type': AssetType.stock},
  {'symbol': 'HDFCBANK', 'name': 'HDFC Bank', 'type': AssetType.stock},
  {'symbol': 'ICICIBANK', 'name': 'ICICI Bank', 'type': AssetType.stock},
  {'symbol': 'BHARTIARTL', 'name': 'Bharti Airtel', 'type': AssetType.stock},
  {'symbol': 'ITC', 'name': 'ITC Limited', 'type': AssetType.stock},
  {'symbol': 'WIPRO', 'name': 'Wipro Limited', 'type': AssetType.stock},
  {
    'symbol': 'HINDUNILVR',
    'name': 'Hindustan Unilever',
    'type': AssetType.stock,
  },
  {'symbol': 'LT', 'name': 'Larsen & Toubro', 'type': AssetType.stock},
  {'symbol': 'SBIN', 'name': 'State Bank of India', 'type': AssetType.stock},
  {'symbol': 'AXISBANK', 'name': 'Axis Bank', 'type': AssetType.stock},
  {'symbol': 'BAJFINANCE', 'name': 'Bajaj Finance', 'type': AssetType.stock},
  {'symbol': 'HCLTECH', 'name': 'HCL Technologies', 'type': AssetType.stock},
  {
    'symbol': 'KOTAKBANK',
    'name': 'Kotak Mahindra Bank',
    'type': AssetType.stock,
  },
];

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with WidgetsBindingObserver {
  final YFinanceService _apiService = YFinanceService();
  final LocalPriceService _localPriceService = LocalPriceService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _refreshTimer;
  Timer? _searchDebounce;

  String _searchQuery = '';
  List<MarketAsset> _searchResults = [];
  bool _isSearching = false;

  List<MarketAsset> _marketData = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _useLocalPrices = true; // Use local JSON by default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAndLoadData();
    // Start continuous refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isLoading && mounted) {
        _loadMarketData(silent: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-reload data whenever market screen comes into view
    if (mounted && !_isLoading) {
      _loadMarketData(silent: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Dismiss keyboard when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _initializeAndLoadData() async {
    try {
      // LocalPriceService loads on demand, no need to pre-load
      developer.log('MarketScreen initialized', name: 'MarketScreen');
      _loadMarketData();
    } catch (e) {
      developer.log('Error in initialization: $e', name: 'MarketScreen');
      setState(() {
        _useLocalPrices = false;
      });
      _loadMarketData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // Public method to dismiss keyboard - called when PageView changes
  void dismissKeyboard() {
    _searchFocusNode.unfocus();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Use compute for multithreaded search - production level
      final results = await compute(_searchInIsolate, {
        'query': query.toLowerCase(),
        'marketData': _marketData,
      });

      // API search as fallback
      if (results.isEmpty) {
        final apiResults = await _apiService.searchStocks(query);
        final searchSymbols = apiResults.take(10).map((r) => r.symbol).toList();

        if (searchSymbols.isNotEmpty) {
          final quotes = await _apiService.getMultipleStockQuotes(
            searchSymbols,
          );
          List<MarketAsset> searchAssets = [];
          for (var quote in quotes) {
            searchAssets.add(
              MarketAsset(
                symbol: quote.symbol,
                name: quote.name,
                currentPrice: quote.price,
                changePercentage: quote.changePercent,
                type: AssetType.stock,
                lastUpdated: DateTime.now(),
              ),
            );
          }

          if (mounted && _searchQuery.toLowerCase() == query.toLowerCase()) {
            setState(() {
              _searchResults = searchAssets;
              _isSearching = false;
            });
          }
          return;
        }
      }

      // Only update if still mounted and query hasn't changed
      if (mounted && _searchQuery.toLowerCase() == query.toLowerCase()) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      developer.log('Search error: $e', name: 'MarketScreen');
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  // Static isolate function for multithreaded search
  static List<MarketAsset> _searchInIsolate(Map<String, dynamic> params) {
    final String query = params['query'] as String;
    final List<MarketAsset> data = params['marketData'] as List<MarketAsset>;

    return data
        .where(
          (asset) =>
              asset.symbol.toLowerCase().contains(query) ||
              asset.name.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _loadMarketData({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    developer.log(
      'Starting to load market data from ${_useLocalPrices ? "local JSON" : "API"}... (silent: $silent)',
      name: 'MarketScreen',
    );

    try {
      final List<MarketAsset> assets = [];

      if (_useLocalPrices) {
        // Load from local JSON - fetch prices for known symbols
        developer.log('Loading stocks from JSON', name: 'MarketScreen');

        for (final assetDef in _assetDefinitions) {
          final symbol = assetDef['symbol'] as String;

          final price = await _localPriceService.getStockPrice(symbol);

          if (price != null) {
            assets.add(
              MarketAsset(
                symbol: symbol,
                name: assetDef['name'] as String,
                currentPrice: price,
                changePercentage: 0.0,
                type: AssetType.stock,
                lastUpdated: DateTime.now(),
              ),
            );
            developer.log('Loaded $symbol: ₹$price', name: 'MarketScreen');
          }
        }
      } else {
        // Load from API (fallback)
        final stockSymbols = _assetDefinitions
            .where((a) => a['type'] == AssetType.stock)
            .map((a) => a['symbol'] as String)
            .toList();

        developer.log(
          'Loading ${stockSymbols.length} stocks from API',
          name: 'MarketScreen',
        );

        try {
          final quotes = await _apiService.getMultipleStockQuotes(stockSymbols);

          for (final quote in quotes) {
            final assetDef = _assetDefinitions.firstWhere(
              (a) => a['symbol'] == quote.symbol,
              orElse: () => {
                'symbol': quote.symbol,
                'name': quote.name,
                'type': AssetType.stock,
              },
            );
            assets.add(
              MarketAsset(
                symbol: quote.symbol,
                name: assetDef['name'] as String,
                currentPrice: quote.price,
                changePercentage: quote.changePercent,
                type: AssetType.stock,
                lastUpdated: DateTime.now(),
              ),
            );
          }
        } catch (e, st) {
          developer.log(
            'Error loading stocks from API',
            name: 'MarketScreen',
            error: e,
            stackTrace: st,
          );
        }
      }

      // Skip crypto and mutual funds when using local JSON
      // (JSON only has stock data)

      if (mounted) {
        setState(() {
          _marketData = assets;
          _isLoading = false;
        });
      }
      developer.log(
        'Market data loaded successfully: ${assets.length} assets',
        name: 'MarketScreen',
      );
    } catch (e, st) {
      developer.log(
        'Fatal error loading market data',
        name: 'MarketScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load market data: $e';
        });
      }
    }
  }

  Future<void> _refreshData() async {
    _apiService.clearCache();
    await _loadMarketData();
  }

  String _getCompanyDomain(String symbol) {
    // Map stock symbols to company domains for logo API
    const domainMap = {
      'RELIANCE': 'ril',
      'TCS': 'tcs',
      'INFY': 'infosys',
      'HDFCBANK': 'hdfcbank',
      'ICICIBANK': 'icicibank',
      'HINDUNILVR': 'hul',
      'ITC': 'itcportal',
      'SBIN': 'onlinesbi',
      'BHARTIARTL': 'airtel',
      'KOTAKBANK': 'kotak',
      'LT': 'larsentoubro',
      'ASIANPAINT': 'asianpaints',
      'AXISBANK': 'axisbank',
      'MARUTI': 'marutisuzuki',
      'TITAN': 'titan',
      'SUNPHARMA': 'sunpharma',
      'WIPRO': 'wipro',
      'ULTRACEMCO': 'ultratechcement',
      'NESTLEIND': 'nestle',
      'BAJFINANCE': 'bajajfinserv',
    };

    return domainMap[symbol] ?? symbol.toLowerCase();
  }

  List<MarketAsset> get _filteredAssets {
    // If searching, return search results
    if (_searchQuery.isNotEmpty) {
      return _searchResults;
    }

    // Otherwise return the default market data
    return _marketData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Title and Reload Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Market',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  // Reload Button
                  IconButton(
                    onPressed: _isLoading ? null : _refreshData,
                    icon: Icon(
                      Icons.refresh,
                      color: _isLoading ? Colors.grey : Colors.white,
                    ),
                    tooltip: 'Reload',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                showCursor: true,
                enableInteractiveSelection: true,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });

                  // Debounce search - production level 300ms
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 300),
                    () => _performSearch(value),
                  );
                },
                onTap: () {
                  // Ensure cursor is visible only when tapped
                  if (!_searchFocusNode.hasFocus) {
                    _searchFocusNode.requestFocus();
                  }
                },
                style: const TextStyle(
                  fontFamily: 'ClashDisplay',
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Search any stock (e.g., ANGELONE, ZOMATO)...',
                  hintStyle: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 13,
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                  ),
                  prefixIcon: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.search,
                          color: Colors.white.withAlpha((0.5 * 255).round()),
                        ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                            setState(() {
                              _searchQuery = '';
                              _searchResults = [];
                              _isSearching = false;
                            });
                            _searchDebounce?.cancel();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Market Content
            Expanded(
              child: _isLoading && _marketData.isEmpty
                  ? _buildLoadingState()
                  : _errorMessage != null && _marketData.isEmpty
                  ? _buildErrorState()
                  : _buildMarketList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketList() {
    return BlocBuilder<WatchlistBloc, WatchlistState>(
      builder: (context, watchlistState) {
        if (_filteredAssets.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.white.withAlpha((0.3 * 255).round()),
                ),
                const SizedBox(height: 16),
                Text(
                  'No stocks found',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha((0.7 * 255).round()),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try searching with a different keyword',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: _filteredAssets.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final asset = _filteredAssets[index];

            // Check if in watchlist
            bool isInWatchlist = false;
            if (watchlistState is WatchlistLoaded) {
              isInWatchlist = watchlistState.isWatched(asset.symbol);
            }

            return _buildAssetCard(asset, isInWatchlist, context);
          },
        );
      },
    );
  }

  Widget _buildAssetCard(
    MarketAsset asset,
    bool isInWatchlist,
    BuildContext context,
  ) {
    final isPositive = asset.changePercentage >= 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketStockDetailScreen(
              symbol: asset.symbol,
              name: asset.name,
              assetType: asset.type,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Stock Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://logo.clearbit.com/${_getCompanyDomain(asset.symbol)}.com',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to first letter if logo fails to load
                    return Center(
                      child: Text(
                        asset.symbol.substring(0, 1),
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Asset details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.symbol,
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asset.name,
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Price and change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatINR(asset.currentPrice),
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      CurrencyFormatter.formatPercentage(
                        asset.changePercentage,
                      ),
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Watchlist button
            BlocBuilder<WatchlistBloc, WatchlistState>(
              builder: (context, state) {
                return IconButton(
                  onPressed: () {
                    context.read<WatchlistBloc>().add(
                      ToggleWatchlist(
                        assetSymbol: asset.symbol,
                        assetName: asset.name,
                        assetType: asset.type,
                      ),
                    );
                  },
                  icon: Icon(
                    isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                    color: isInWatchlist
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 16),
          Text(
            'Loading market data...',
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a moment due to API rate limits',
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to load market data',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Trade Dialog for buying/selling assets
class TradeDialog extends StatefulWidget {
  final MarketAsset asset;

  const TradeDialog({super.key, required this.asset});

  @override
  State<TradeDialog> createState() => _TradeDialogState();
}

class _TradeDialogState extends State<TradeDialog> {
  bool _isBuying = true;
  final _quantityController = TextEditingController(text: '1');

  double get _quantity => double.tryParse(_quantityController.text) ?? 0;
  double get _totalAmount => _quantity * widget.asset.currentPrice;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trade ${widget.asset.symbol}',
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Buy/Sell Toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBuying = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isBuying
                            ? Colors.green
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Buy',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isBuying
                                ? Colors.white
                                : Colors.white.withAlpha((0.5 * 255).round()),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBuying = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isBuying
                            ? Colors.red
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Sell',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: !_isBuying
                                ? Colors.white
                                : Colors.white.withAlpha((0.5 * 255).round()),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Current Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Price',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatINR(widget.asset.currentPrice),
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Quantity Input
            Text(
              'Quantity',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withAlpha((0.7 * 255).round()),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
              style: const TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixText: 'shares',
                suffixStyle: TextStyle(
                  fontFamily: 'ClashDisplay',
                  color: Colors.white.withAlpha((0.5 * 255).round()),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatINR(_totalAmount),
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // User Balance
            BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                if (state is UserLoaded) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Balance',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withAlpha((0.7 * 255).round()),
                          ),
                        ),
                        Text(
                          state.profile.formattedBalance,
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 24),

            // Execute Button
            BlocConsumer<TransactionBloc, TransactionState>(
              listener: (context, state) {
                if (state is TransactionSuccess) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh user and holdings
                  context.read<UserBloc>().add(const RefreshUserProfile());
                  context.read<HoldingsBloc>().add(const RefreshHoldings());
                } else if (state is TransactionError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isExecuting = state is TransactionExecuting;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isExecuting || _quantity <= 0
                        ? null
                        : () {
                            if (_isBuying) {
                              context.read<TransactionBloc>().add(
                                ExecuteBuyOrder(
                                  assetSymbol: widget.asset.symbol,
                                  assetName: widget.asset.name,
                                  assetType: widget.asset.type,
                                  quantity: _quantity,
                                  pricePerUnit: widget.asset.currentPrice,
                                ),
                              );
                            } else {
                              context.read<TransactionBloc>().add(
                                ExecuteSellOrder(
                                  assetSymbol: widget.asset.symbol,
                                  assetName: widget.asset.name,
                                  assetType: widget.asset.type,
                                  quantity: _quantity,
                                  pricePerUnit: widget.asset.currentPrice,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBuying ? Colors.green : Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: isExecuting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            '${_isBuying ? 'Buy' : 'Sell'} ${widget.asset.symbol}',
                            style: const TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
