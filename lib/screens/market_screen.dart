import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';

// Mock market data (In a real app, this would come from an API)
class MarketAsset {
  final String symbol;
  final String name;
  final double currentPrice;
  final double changePercentage;
  final AssetType type;

  const MarketAsset({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.changePercentage,
    required this.type,
  });
}

// Mock data for demonstration
final List<MarketAsset> _mockMarketData = [
  // Stocks
  const MarketAsset(
    symbol: 'AAPL',
    name: 'Apple Inc.',
    currentPrice: 178.50,
    changePercentage: 2.34,
    type: AssetType.stock,
  ),
  const MarketAsset(
    symbol: 'GOOGL',
    name: 'Alphabet Inc.',
    currentPrice: 142.30,
    changePercentage: -1.25,
    type: AssetType.stock,
  ),
  const MarketAsset(
    symbol: 'MSFT',
    name: 'Microsoft Corp.',
    currentPrice: 378.91,
    changePercentage: 1.89,
    type: AssetType.stock,
  ),
  const MarketAsset(
    symbol: 'TSLA',
    name: 'Tesla Inc.',
    currentPrice: 242.15,
    changePercentage: 4.56,
    type: AssetType.stock,
  ),
  const MarketAsset(
    symbol: 'AMZN',
    name: 'Amazon.com Inc.',
    currentPrice: 152.43,
    changePercentage: 0.87,
    type: AssetType.stock,
  ),
  const MarketAsset(
    symbol: 'NVDA',
    name: 'NVIDIA Corp.',
    currentPrice: 495.22,
    changePercentage: 3.21,
    type: AssetType.stock,
  ),
  
  // Crypto
  const MarketAsset(
    symbol: 'BTC',
    name: 'Bitcoin',
    currentPrice: 67890.00,
    changePercentage: 5.67,
    type: AssetType.crypto,
  ),
  const MarketAsset(
    symbol: 'ETH',
    name: 'Ethereum',
    currentPrice: 3450.75,
    changePercentage: -2.34,
    type: AssetType.crypto,
  ),
  const MarketAsset(
    symbol: 'BNB',
    name: 'Binance Coin',
    currentPrice: 425.30,
    changePercentage: 1.45,
    type: AssetType.crypto,
  ),
  
  // Mutual Funds
  const MarketAsset(
    symbol: 'VFIAX',
    name: 'Vanguard 500 Index',
    currentPrice: 425.67,
    changePercentage: 0.52,
    type: AssetType.mutualFund,
  ),
  const MarketAsset(
    symbol: 'FXAIX',
    name: 'Fidelity 500 Index',
    currentPrice: 178.45,
    changePercentage: 0.48,
    type: AssetType.mutualFund,
  ),
];

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  AssetType? _selectedFilter;
  String _searchQuery = '';

  List<MarketAsset> get _filteredAssets {
    var assets = _mockMarketData;
    
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
        title: const Text(
          'Market',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
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
                  '${asset.currentPrice.toStringAsFixed(2)} ST',
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
                      '${isPositive ? '+' : ''}${asset.changePercentage.toStringAsFixed(2)}%',
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
                  '${widget.asset.currentPrice.toStringAsFixed(2)} ST',
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
                  '${_totalAmount.toStringAsFixed(2)} ST',
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
