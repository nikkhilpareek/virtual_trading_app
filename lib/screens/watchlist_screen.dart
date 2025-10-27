import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:virtual_trading_app/screens/market_screen.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/utils/currency_formatter.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xff0a0a0a),
        elevation: 0,
        title: const Text(
          'Watchlist',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          // Filter menu
          PopupMenuButton<AssetType?>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            color: const Color(0xff1a1a1a),
            onSelected: (AssetType? type) {
              if (type == null) {
                context.read<WatchlistBloc>().add(const LoadWatchlist());
              } else {
                context.read<WatchlistBloc>().add(FilterWatchlistByType(type));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text(
                  'All',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    color: Colors.white,
                  ),
                ),
              ),
              const PopupMenuItem(
                value: AssetType.stock,
                child: Text(
                  'Stocks',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    color: Colors.white,
                  ),
                ),
              ),
              const PopupMenuItem(
                value: AssetType.crypto,
                child: Text(
                  'Crypto',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    color: Colors.white,
                  ),
                ),
              ),
              const PopupMenuItem(
                value: AssetType.mutualFund,
                child: Text(
                  'Mutual Funds',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<WatchlistBloc, WatchlistState>(
        builder: (context, state) {
          if (state is WatchlistLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5BCE7)),
            );
          }

          if (state is WatchlistError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.withAlpha((0.7 * 255).round()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading watchlist',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha((0.5 * 255).round()),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<WatchlistBloc>().add(const LoadWatchlist());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5BCE7),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is WatchlistLoaded && state.filteredItems.isNotEmpty) {
            return RefreshIndicator(
              color: const Color(0xFFE5BCE7),
              onRefresh: () async {
                context.read<WatchlistBloc>().add(const LoadWatchlist());
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: state.filteredItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = state.filteredItems[index];
                  return _buildWatchlistCard(context, item);
                },
              ),
            );
          }

          // Empty state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 80,
                  color: Colors.white.withAlpha((0.3 * 255).round()),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your Watchlist is Empty',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Add assets from the Market tab',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to the Market screen
                    // Remove DefaultTabController call (not used here) and push the MarketScreen
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MarketScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    'Browse Market',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5BCE7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWatchlistCard(BuildContext context, WatchlistItem item) {
    // Mock price data (in real app, this would come from an API)
    final mockPrice = _getMockPrice(item.assetSymbol);
    final mockChange = _getMockChange(item.assetSymbol);
    final isPositive = mockChange >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha((0.1 * 255).round())),
      ),
      child: Row(
        children: [
          // Asset icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getAssetTypeColor(
                item.assetType,
              ).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                item.assetSymbol.substring(0, 1),
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _getAssetTypeColor(item.assetType),
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
                      item.assetSymbol,
                      style: const TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getAssetTypeColor(
                          item.assetType,
                        ).withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.assetType.displayName,
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getAssetTypeColor(item.assetType),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.assetName,
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha((0.5 * 255).round()),
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
                CurrencyFormatter.formatINR(mockPrice),
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
                    CurrencyFormatter.formatPercentage(mockChange),
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

          // Remove button
          IconButton(
            onPressed: () {
              // Show confirmation dialog
              _showRemoveDialog(context, item);
            },
            icon: Icon(Icons.bookmark, color: const Color(0xFFE5BCE7)),
          ),
        ],
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

  double _getMockPrice(String symbol) {
    // Mock prices for demonstration
    final prices = {
      'AAPL': 178.50,
      'GOOGL': 142.30,
      'MSFT': 378.91,
      'TSLA': 242.15,
      'AMZN': 152.43,
      'NVDA': 495.22,
      'BTC': 67890.00,
      'ETH': 3450.75,
      'BNB': 425.30,
      'VFIAX': 425.67,
      'FXAIX': 178.45,
    };
    return prices[symbol] ?? 100.0;
  }

  double _getMockChange(String symbol) {
    // Mock changes for demonstration
    final changes = {
      'AAPL': 2.34,
      'GOOGL': -1.25,
      'MSFT': 1.89,
      'TSLA': 4.56,
      'AMZN': 0.87,
      'NVDA': 3.21,
      'BTC': 5.67,
      'ETH': -2.34,
      'BNB': 1.45,
      'VFIAX': 0.52,
      'FXAIX': 0.48,
    };
    return changes[symbol] ?? 0.0;
  }

  void _showRemoveDialog(BuildContext context, WatchlistItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove from Watchlist?',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Do you want to remove ${item.assetSymbol} from your watchlist?',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            color: Colors.white.withAlpha((0.7 * 255).round()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.white.withAlpha((0.5 * 255).round()),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<WatchlistBloc>().add(
                RemoveFromWatchlist(item.assetSymbol),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Remove',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
