import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/services/alpha_vantage_service.dart';
import '../core/utils/currency_formatter.dart';

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

// Asset definitions for Indian Market (NSE/BSE)
// Prices will be fetched from Alpha Vantage API
const List<Map<String, dynamic>> _assetDefinitions = [
  // Indian Stocks (NSE/BSE)
  {'symbol': 'RELIANCE.BSE', 'name': 'Reliance Industries', 'type': AssetType.stock},
  {'symbol': 'TCS.BSE', 'name': 'Tata Consultancy Services', 'type': AssetType.stock},
  {'symbol': 'INFY.BSE', 'name': 'Infosys Limited', 'type': AssetType.stock},
  {'symbol': 'HDFCBANK.BSE', 'name': 'HDFC Bank', 'type': AssetType.stock},
  {'symbol': 'ICICIBANK.BSE', 'name': 'ICICI Bank', 'type': AssetType.stock},
  {'symbol': 'BHARTIARTL.BSE', 'name': 'Bharti Airtel', 'type': AssetType.stock},
  {'symbol': 'ITC.BSE', 'name': 'ITC Limited', 'type': AssetType.stock},
  {'symbol': 'WIPRO.BSE', 'name': 'Wipro Limited', 'type': AssetType.stock},
  
  // Crypto (INR pairs)
  {'symbol': 'BTC', 'name': 'Bitcoin', 'type': AssetType.crypto},
  {'symbol': 'ETH', 'name': 'Ethereum', 'type': AssetType.crypto},
  {'symbol': 'BNB', 'name': 'Binance Coin', 'type': AssetType.crypto},
  
  // Mutual Funds (Indian)
  {'symbol': 'SBI.BSE', 'name': 'SBI Mutual Fund', 'type': AssetType.mutualFund},
  {'symbol': 'AXIS.BSE', 'name': 'Axis Mutual Fund', 'type': AssetType.mutualFund},
];

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final AlphaVantageService _apiService = AlphaVantageService();
  
  AssetType? _selectedFilter;
  String _searchQuery = '';
  
  List<MarketAsset> _marketData = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<MarketAsset> assets = [];

      // Load stocks
      final stockSymbols = _assetDefinitions
          .where((a) => a['type'] == AssetType.stock)
          .map((a) => a['symbol'] as String)
          .toList();

      for (final symbol in stockSymbols) {
        final assetDef = _assetDefinitions.firstWhere((a) => a['symbol'] == symbol);
        try {
          final quote = await _apiService.getStockQuote(symbol);
          if (quote != null) {
            assets.add(MarketAsset(
              symbol: symbol,
              name: assetDef['name'] as String,
              currentPrice: quote.price,
              changePercentage: quote.changePercent,
              type: AssetType.stock,
              lastUpdated: DateTime.now(),
            ));
          }
          
          // Small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 600));
        } catch (e) {
          print('Error loading stock $symbol: $e');
        }
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
          
          // Small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 600));
        } catch (e) {
          print('Error loading crypto $symbol: $e');
        }
      }

      // Load mutual funds (fallback to placeholder since Alpha Vantage may not support all)
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
          
          await Future.delayed(const Duration(milliseconds: 600));
        } catch (e) {
          print('Error loading mutual fund ${assetDef['symbol']}: $e');
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
    } catch (e) {
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
    var assets = _marketData;
    
    // Filter by type
    if (_selectedFilter != null) {
      assets = assets.where((a) => a.type == _selectedFilter).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      assets = assets.where((a) =>
        a.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        a.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return assets;
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
                  color: Colors.white.withOpacity(0.5),
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
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Search assets...',
                hintStyle: TextStyle(
                  fontFamily: 'ClashDisplay',
                  color: Colors.white.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.5),
                ),
                filled: true,
                fillColor: const Color(0xff1a1a1a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Filter chips
          SizedBox(
            height: 50,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                _buildFilterChip('Stocks', AssetType.stock),
                const SizedBox(width: 8),
                _buildFilterChip('Crypto', AssetType.crypto),
                const SizedBox(width: 8),
                _buildFilterChip('Mutual Funds', AssetType.mutualFund),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Market list
          Expanded(
            child: BlocBuilder<WatchlistBloc, WatchlistState>(
              builder: (context, watchlistState) {
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

  Widget _buildFilterChip(String label, AssetType? type) {
    final isSelected = _selectedFilter == type;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE5BCE7)
              : const Color(0xff1a1a1a),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE5BCE7)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCard(MarketAsset asset, bool isInWatchlist, BuildContext context) {
    final isPositive = asset.changePercentage >= 0;
    
    return GestureDetector(
      onTap: () {
        _showTradeDialog(context, asset);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff1a1a1a),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            // Asset icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE5BCE7).withOpacity(0.1),
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
                  Row(
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getAssetTypeColor(asset.type).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          asset.type.displayName,
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getAssetTypeColor(asset.type),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asset.name,
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.5),
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
                    color: isInWatchlist ? const Color(0xFFE5BCE7) : Colors.white.withOpacity(0.5),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getAssetTypeColor(AssetType type) {
    switch (type) {
      case AssetType.stock:
        return Colors.blue;
      case AssetType.crypto:
        return Colors.orange;
      case AssetType.mutualFund:
        return Colors.green;
    }
  }

  void _showTradeDialog(BuildContext context, MarketAsset asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TradeDialog(asset: asset),
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
                            color: _isBuying ? Colors.white : Colors.white.withOpacity(0.5),
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
                            color: !_isBuying ? Colors.white : Colors.white.withOpacity(0.5),
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
                    color: Colors.white.withOpacity(0.5),
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
                color: Colors.white.withOpacity(0.7),
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
                  color: Colors.white.withOpacity(0.5),
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
                    color: Colors.white.withOpacity(0.5),
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
                            color: Colors.white.withOpacity(0.7),
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
