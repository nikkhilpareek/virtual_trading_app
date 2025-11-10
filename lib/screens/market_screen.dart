import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/services/yfinance_service.dart';
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
  {'symbol': 'RELIANCE', 'name': 'Reliance Industries', 'type': AssetType.stock},
  {'symbol': 'TCS', 'name': 'Tata Consultancy Services', 'type': AssetType.stock},
  {'symbol': 'INFY', 'name': 'Infosys Limited', 'type': AssetType.stock},
  {'symbol': 'HDFCBANK', 'name': 'HDFC Bank', 'type': AssetType.stock},
  {'symbol': 'ICICIBANK', 'name': 'ICICI Bank', 'type': AssetType.stock},
  {'symbol': 'BHARTIARTL', 'name': 'Bharti Airtel', 'type': AssetType.stock},
  {'symbol': 'ITC', 'name': 'ITC Limited', 'type': AssetType.stock},
  {'symbol': 'WIPRO', 'name': 'Wipro Limited', 'type': AssetType.stock},
  {'symbol': 'HINDUNILVR', 'name': 'Hindustan Unilever', 'type': AssetType.stock},
  {'symbol': 'LT', 'name': 'Larsen & Toubro', 'type': AssetType.stock},
  {'symbol': 'SBIN', 'name': 'State Bank of India', 'type': AssetType.stock},
  {'symbol': 'AXISBANK', 'name': 'Axis Bank', 'type': AssetType.stock},
  {'symbol': 'BAJFINANCE', 'name': 'Bajaj Finance', 'type': AssetType.stock},
  {'symbol': 'HCLTECH', 'name': 'HCL Technologies', 'type': AssetType.stock},
  {'symbol': 'KOTAKBANK', 'name': 'Kotak Mahindra Bank', 'type': AssetType.stock},
];

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final YFinanceService _apiService = YFinanceService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;
  Timer? _searchDebounce;
  
  String _searchQuery = '';
  List<MarketAsset> _searchResults = [];
  bool _isSearching = false;
  
  List<MarketAsset> _marketData = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _loadMarketData();
    // Start continuous refresh every 5 seconds (not 1 second to avoid overwhelming the API)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isLoading) {
        _loadMarketData(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
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
      final results = await _apiService.searchStocks(query);
      
      // Fetch prices for search results in batch
      List<MarketAsset> searchAssets = [];
      final searchSymbols = results.take(10).map((r) => r.symbol).toList();
      
      if (searchSymbols.isNotEmpty) {
        final quotes = await _apiService.getMultipleStockQuotes(searchSymbols);
        for (var quote in quotes) {
          searchAssets.add(MarketAsset(
            symbol: quote.symbol,
            name: quote.name,
            currentPrice: quote.price,
            changePercentage: quote.changePercent,
            type: AssetType.stock,
            lastUpdated: DateTime.now(),
          ));
        }
      }
      
      if (mounted) {
        setState(() {
          _searchResults = searchAssets;
          _isSearching = false;
        });
      }
    } catch (e) {
      developer.log('Error searching stocks: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _loadMarketData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    developer.log('Starting to load market data... (silent: $silent)', name: 'MarketScreen');

    try {
      final List<MarketAsset> assets = [];

      // Load stocks
      final stockSymbols = _assetDefinitions
          .where((a) => a['type'] == AssetType.stock)
          .map((a) => a['symbol'] as String)
          .toList();

      developer.log('Loading ${stockSymbols.length} stocks', name: 'MarketScreen');

      // Use batch fetching for better performance
      try {
        developer.log('Fetching quotes for ${stockSymbols.length} stocks in batch', name: 'MarketScreen');
        final quotes = await _apiService.getMultipleStockQuotes(stockSymbols);
        
        for (final quote in quotes) {
          final assetDef = _assetDefinitions.firstWhere(
            (a) => a['symbol'] == quote.symbol,
            orElse: () => {'symbol': quote.symbol, 'name': quote.name, 'type': AssetType.stock},
          );
          developer.log('Got quote for ${quote.symbol}: ${quote.price}', name: 'MarketScreen');
          assets.add(MarketAsset(
            symbol: quote.symbol,
            name: assetDef['name'] as String,
            currentPrice: quote.price,
            changePercentage: quote.changePercent,
            type: AssetType.stock,
            lastUpdated: DateTime.now(),
          ));
        }
      } catch (e, st) {
        developer.log('Error loading stocks in batch', name: 'MarketScreen', error: e, stackTrace: st);
      }

      // Load crypto
      final cryptoSymbols = _assetDefinitions
          .where((a) => a['type'] == AssetType.crypto)
          .map((a) => a['symbol'] as String)
          .toList();

      for (final symbol in cryptoSymbols) {
        final assetDef = _assetDefinitions.firstWhere((a) => a['symbol'] == symbol);
        try {
          final quote = await _apiService.getCryptoQuote(symbol);
          if (quote != null) {
            assets.add(MarketAsset(
              symbol: symbol,
              name: assetDef['name'] as String,
              currentPrice: quote.price,
              changePercentage: quote.changePercent,
              type: AssetType.crypto,
              lastUpdated: DateTime.now(),
            ));
          }
        } catch (e,st) {
          developer.log('Error loading crypto $symbol', name: 'MarketScreen', error: e, stackTrace:st);
        }
      }

      // Load mutual funds (using stock quotes from YFinance)
      final mutualFundSymbols = _assetDefinitions
          .where((a) => a['type'] == AssetType.mutualFund)
          .toList();

      for (final assetDef in mutualFundSymbols) {
        try {
          final quote = await _apiService.getStockQuote(assetDef['symbol'] as String);
          if (quote != null) {
            assets.add(MarketAsset(
              symbol: assetDef['symbol'] as String,
              name: assetDef['name'] as String,
              currentPrice: quote.price,
              changePercentage: quote.changePercent,
              type: AssetType.mutualFund,
              lastUpdated: DateTime.now(),
            ));
          }
        } catch (e,st) {
          developer.log('Error loading mutual fund ${assetDef['symbol']}', name: 'MarketScreen', error: e, stackTrace: st);
          // Add placeholder data for mutual funds if API fails
          assets.add(MarketAsset(
            symbol: assetDef['symbol'] as String,
            name: assetDef['name'] as String,
            currentPrice: 0.0, // Will show as unavailable
            changePercentage: 0.0,
            type: AssetType.mutualFund,
            lastUpdated: null,
          ));
        }
      }

      setState(() {
        _marketData = assets;
        _isLoading = false;
        _lastRefresh = DateTime.now();
      });
      developer.log('Market data loaded successfully: ${assets.length} assets', name: 'MarketScreen');
    } catch (e, st) {
      developer.log('Fatal error loading market data', name: 'MarketScreen', error: e, stackTrace: st);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load market data: $e';
      });
    }
  }

  Future<void> _refreshData() async {
    _apiService.clearCache();
    await _loadMarketData();
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
      backgroundColor: const Color(0xff0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xff0a0a0a),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_lastRefresh != null)
              Text(
                'Last updated: ${_formatTime(_lastRefresh!)}',
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 12,
                  color: Colors.white.withAlpha((0.5 * 255).round()),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _isLoading ? Colors.grey : const Color(0xFFE5BCE7),
            ),
            onPressed: _isLoading ? null : _refreshData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading && _marketData.isEmpty
          ? _buildLoadingState()
          : _errorMessage != null && _marketData.isEmpty
              ? _buildErrorState()
              : Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                
                // Debounce search
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                  _performSearch(value);
                });
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
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5BCE7)),
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
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _searchResults = [];
                            _isSearching = false;
                          });
                          _searchDebounce?.cancel();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xff1a1a1a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Market list
          Expanded(
            child: BlocBuilder<WatchlistBloc, WatchlistState>(
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(MarketAsset asset, bool isInWatchlist, BuildContext context) {
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
          color: const Color(0xff1a1a1a),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withAlpha((0.1 * 255).round()),
          ),
        ),
        child: Row(
          children: [
            // Asset icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE5BCE7).withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  asset.symbol.substring(0, 1),
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE5BCE7),
                  ),
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
                    style: const TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asset.name,
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha((0.5 * 255).round()),
                    ),
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
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
                      CurrencyFormatter.formatPercentage(asset.changePercentage),
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
                    color: isInWatchlist ? const Color(0xFFE5BCE7) : Colors.white.withAlpha((0.5 * 255).round()),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFE5BCE7),
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
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
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
                backgroundColor: const Color(0xFFE5BCE7),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
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
      decoration: const BoxDecoration(
        color: Color(0xff0a0a0a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: _isBuying ? Colors.green : const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Buy',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isBuying ? Colors.white : Colors.white.withAlpha((0.5 * 255).round()),
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
                        color: !_isBuying ? Colors.red : const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Sell',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: !_isBuying ? Colors.white : Colors.white.withAlpha((0.5 * 255).round()),
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
                fillColor: const Color(0xff1a1a1a),
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
                      color: const Color(0xff1a1a1a),
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
                          style: const TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE5BCE7),
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
                    onPressed: isExecuting || _quantity <= 0 ? null : () {
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
