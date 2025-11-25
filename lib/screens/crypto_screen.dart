import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/services/freecrypto_service.dart';
import '../core/utils/currency_formatter.dart';
import '../widgets/crypto_logo.dart';
import 'crypto_detail_screen.dart';
import 'dart:async';

/// CryptoScreen
/// Complete cryptocurrency trading screen with market data, holdings, and buy/sell functionality
/// Follows existing design patterns from market_screen.dart and assets_screen.dart
class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen>
    with AutomaticKeepAliveClientMixin {
  Timer? _refreshTimer;
  final TextEditingController _searchController = TextEditingController();
  List<CryptoQuote> _filteredCryptos = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();

    // Load initial data with limit of 5
    context.read<CryptoBloc>().add(const LoadCryptoMarket(limit: 5));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xff0a0a0a),
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
                    'Crypto',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  // Reload Button
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _filteredCryptos = [];
                      });
                      context.read<CryptoBloc>().add(
                        const RefreshCryptoMarket(limit: 5),
                      );
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Reload',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search cryptocurrency...',
                  hintStyle: TextStyle(
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                    fontFamily: 'ClashDisplay',
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFE5BCE7),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _isSearching = false;
                              _filteredCryptos = [];
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xff1a1a1a),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _performSearch,
              ),
            ),

            const SizedBox(height: 20),

            // Market Content
            Expanded(child: _buildMarketTab()),
          ],
        ),
      ),
    );
  }

  /// Perform search with multithreading
  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredCryptos = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    // Use Future.microtask for multithreading
    final service = FreeCryptoService();
    final searchResults = await Future.microtask(
      () => service.searchCrypto(query),
    );

    if (searchResults.isNotEmpty) {
      // Fetch prices for search results
      final symbols = searchResults.map((r) => r.symbol).toList();
      final cryptos = await Future.microtask(() async {
        final List<CryptoQuote?> results = [];
        for (final symbol in symbols) {
          final quote = await service.getCryptoPrice(symbol);
          if (quote != null) results.add(quote);
        }
        return results.whereType<CryptoQuote>().toList();
      });

      setState(() {
        _filteredCryptos = cryptos;
        _isSearching = true;
      });
    } else {
      setState(() {
        _filteredCryptos = [];
        _isSearching = true;
      });
    }
  }

  /// Market Tab - Shows all available cryptocurrencies
  Widget _buildMarketTab() {
    // If searching, show filtered results
    if (_isSearching && _filteredCryptos.isNotEmpty) {
      return RefreshIndicator(
        color: const Color(0xFFE5BCE7),
        onRefresh: () async {
          _performSearch(_searchController.text);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: _filteredCryptos.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildCryptoCard(_filteredCryptos[index]);
          },
        ),
      );
    }

    // If searching but no results
    if (_isSearching && _filteredCryptos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: Colors.white.withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha((0.7 * 255).round()),
              ),
            ),
          ],
        ),
      );
    }

    // Default view - show cryptos from bloc
    return BlocBuilder<CryptoBloc, CryptoState>(
      builder: (context, state) {
        if (state is CryptoMarketLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE5BCE7)),
          );
        }

        if (state is CryptoMarketError) {
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
                  'Error Loading Market Data',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    state.message,
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 14,
                      color: Colors.white.withAlpha((0.5 * 255).round()),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    context.read<CryptoBloc>().add(const LoadCryptoMarket());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5BCE7),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is CryptoMarketLoaded) {
          final cryptos = state.cryptos;

          return RefreshIndicator(
            color: const Color(0xFFE5BCE7),
            onRefresh: () async {
              context.read<CryptoBloc>().add(const RefreshCryptoMarket());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: cryptos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final crypto = cryptos[index];
                return _buildCryptoCard(crypto);
              },
            ),
          );
        }

        return const Center(
          child: Text(
            'No cryptocurrency data available',
            style: TextStyle(fontFamily: 'ClashDisplay', color: Colors.white54),
          ),
        );
      },
    );
  }

  /// Crypto Card Widget for Market Tab
  Widget _buildCryptoCard(CryptoQuote crypto) {
    final isPositive = crypto.changePercent24h >= 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CryptoDetailScreen(crypto: crypto),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff1a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withAlpha((0.08 * 255).round()),
          ),
        ),
        child: Row(
          children: [
            // Crypto Icon with logo from CryptoCurrency Icons API
            CryptoLogo(symbol: crypto.symbol, size: 48, fontSize: 14),

            const SizedBox(width: 12),

            // Crypto Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crypto.symbol,
                    style: const TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    crypto.name,
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 12,
                      color: Colors.white.withAlpha((0.6 * 255).round()),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Price and Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatINR(crypto.price),
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withAlpha(
                      (0.1 * 255).round(),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${crypto.changePercent24h.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Buy Button
            IconButton(
              onPressed: () => _showBuyDialog(crypto),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5BCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 16),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  /// Show Buy Dialog
  void _showBuyDialog(CryptoQuote crypto) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Buy ${crypto.symbol}',
          style: const TextStyle(
            fontFamily: 'ClashDisplay',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Price: ${CurrencyFormatter.formatINR(crypto.price)}',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 14,
                color: Colors.white.withAlpha((0.7 * 255).round()),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.white,
              ),
              decoration: InputDecoration(
                labelText: 'Quantity',
                labelStyle: TextStyle(
                  fontFamily: 'ClashDisplay',
                  color: Colors.white.withAlpha((0.5 * 255).round()),
                ),
                filled: true,
                fillColor: const Color(0xff0a0a0a),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
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
          BlocConsumer<CryptoBloc, CryptoState>(
            listener: (context, state) {
              if (state is CryptoTradeSuccess) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is CryptoTradeError) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is CryptoTrading;

              return TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        final quantity = double.tryParse(
                          quantityController.text,
                        );
                        if (quantity == null || quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid quantity'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        context.read<CryptoBloc>().add(
                          BuyCrypto(
                            symbol: crypto.symbol,
                            name: crypto.name,
                            quantity: quantity,
                            price: crypto.price,
                          ),
                        );
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE5BCE7),
                        ),
                      )
                    : const Text(
                        'Buy',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          color: Color(0xFFE5BCE7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
