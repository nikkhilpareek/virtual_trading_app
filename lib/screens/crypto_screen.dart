import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/services/freecrypto_service.dart';
import '../core/utils/currency_formatter.dart';
import '../widgets/crypto_logo.dart';
import 'crypto_detail_screen.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// CryptoScreen
/// Complete cryptocurrency trading screen with market data, holdings, and buy/sell functionality
/// Follows existing design patterns from market_screen.dart and assets_screen.dart
class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  Timer? _refreshTimer;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<CryptoQuote> _filteredCryptos = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load initial data with limit of 5
    context.read<CryptoBloc>().add(const LoadCryptoMarket(limit: 5));
    // Refresh holdings to show correct data
    context.read<HoldingsBloc>().add(const LoadHoldings());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-reload data whenever screen comes into view
    if (mounted) {
      context.read<CryptoBloc>().add(const RefreshCryptoMarket(limit: 5));
      context.read<HoldingsBloc>().add(const RefreshHoldings());
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                focusNode: _searchFocusNode,
                showCursor: true,
                enableInteractiveSelection: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search cryptocurrency...',
                  hintStyle: TextStyle(
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                    fontFamily: 'ClashDisplay',
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                            setState(() {
                              _isSearching = false;
                              _filteredCryptos = [];
                            });
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  // Debounce search with reduced delay for better responsiveness
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (_searchController.text == value) {
                      _performSearch(value);
                    }
                  });
                },
                onTap: () {
                  // Ensure cursor is visible only when tapped
                  if (!_searchFocusNode.hasFocus) {
                    _searchFocusNode.requestFocus();
                  }
                },
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

  /// Perform search with isolate-based multithreading for production
  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredCryptos = [];
      });
      return;
    }

    if (!mounted) return;

    setState(() => _isSearching = true);

    try {
      // Use isolate for multithreaded search
      final service = FreeCryptoService();
      final searchResults = await compute(_searchCryptoInIsolate, {
        'query': query,
        'service': service,
      });

      if (!mounted) return;

      if (searchResults.isNotEmpty) {
        // Extract symbols from search results
        final symbols = (searchResults as List).map((r) {
          if (r is Map<String, dynamic>) {
            return r['symbol'] as String;
          }
          // Fallback for direct CryptoSearchResult serialization
          return r.toString();
        }).toList();

        developer.log(
          'Search found ${searchResults.length} results: $symbols',
          name: 'CryptoScreen',
        );

        final cryptos = await compute(_fetchPricesInIsolate, {
          'symbols': symbols,
          'service': service,
        });

        if (mounted) {
          setState(() {
            _filteredCryptos = (cryptos as List).cast<CryptoQuote>();
            _isSearching = false;
          });
          developer.log(
            'Displaying ${_filteredCryptos.length} search results',
            name: 'CryptoScreen',
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _filteredCryptos = [];
            _isSearching = false;
          });
          developer.log('No search results found', name: 'CryptoScreen');
        }
      }
    } catch (e, st) {
      developer.log(
        'Search error: $e',
        name: 'CryptoScreen',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() {
          _filteredCryptos = [];
          _isSearching = false;
        });
      }
    }
  }

  // Static isolate function for search
  static Future<List<Map<String, String>>> _searchCryptoInIsolate(
    Map<String, dynamic> params,
  ) async {
    final String query = params['query'] as String;
    final FreeCryptoService service = params['service'] as FreeCryptoService;
    final results = await service.searchCrypto(query);
    // Convert CryptoSearchResult to Map for isolate serialization
    return results.map((r) => {'symbol': r.symbol, 'name': r.name}).toList();
  }

  // Static isolate function for price fetching
  static Future<List<CryptoQuote>> _fetchPricesInIsolate(
    Map<String, dynamic> params,
  ) async {
    final List<String> symbols = params['symbols'] as List<String>;
    final FreeCryptoService service = params['service'] as FreeCryptoService;

    final List<CryptoQuote> results = [];
    for (final symbol in symbols) {
      final quote = await service.getCryptoPrice(symbol);
      if (quote != null) results.add(quote);
    }
    return results;
  }

  /// Market Tab - Shows all available cryptocurrencies
  Widget _buildMarketTab() {
    // If search bar has text, show search results (filtered or empty)
    if (_searchController.text.isNotEmpty) {
      // If we have filtered results, show them
      if (_filteredCryptos.isNotEmpty) {
        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () async {
            _performSearch(_searchController.text);
            // Reduced delay for faster UI response
            await Future.delayed(const Duration(milliseconds: 200));
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

      // Show loading or no results
      if (_isSearching) {
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      // Search completed with no results
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
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
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
                    context.read<CryptoBloc>().add(
                      const LoadCryptoMarket(limit: 5),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
            color: Theme.of(context).colorScheme.primary,
            onRefresh: () async {
              context.read<CryptoBloc>().add(
                const RefreshCryptoMarket(limit: 5),
              );
              // Reduced delay for faster UI response
              await Future.delayed(const Duration(milliseconds: 200));
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

        // Loading state or no data
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading cryptocurrencies...',
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  color: Colors.white54,
                ),
              ),
            ],
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
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

            // Bookmark Button
            IconButton(
              onPressed: () {
                context.read<WatchlistBloc>().add(
                  AddToWatchlist(
                    assetSymbol: crypto.symbol,
                    assetName: crypto.name,
                    assetType: AssetType.crypto,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${crypto.name} added to Watchlist'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bookmark_border,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 16,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  /// Show Trade Bottom Sheet with Stop-Loss and Bracket Order support
  // Removed unused _showTradeBottomSheet
}

/// Order type options for trading
enum _CryptoOrderType { market, stopLoss, bracket }

class _CryptoTradeBottomSheet extends StatefulWidget {
  final String symbol;
  final String name;
  final double currentPrice;

  const _CryptoTradeBottomSheet({
    required this.symbol,
    required this.name,
    required this.currentPrice,
  });

  @override
  State<_CryptoTradeBottomSheet> createState() =>
      _CryptoTradeBottomSheetState();
}

class _CryptoTradeBottomSheetState extends State<_CryptoTradeBottomSheet> {
  bool _isBuying = true;
  _CryptoOrderType _orderType = _CryptoOrderType.market;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _triggerPriceController = TextEditingController();
  final TextEditingController _stopLossPriceController =
      TextEditingController();
  final TextEditingController _targetPriceController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.currentPrice.toStringAsFixed(2);
    _updateDefaultPrices();
  }

  void _updateDefaultPrices() {
    final currentPrice = widget.currentPrice;
    if (_isBuying) {
      _triggerPriceController.text = (currentPrice * 0.95).toStringAsFixed(2);
      _stopLossPriceController.text = (currentPrice * 0.95).toStringAsFixed(2);
      _targetPriceController.text = (currentPrice * 1.10).toStringAsFixed(2);
    } else {
      _triggerPriceController.text = (currentPrice * 1.05).toStringAsFixed(2);
      _stopLossPriceController.text = (currentPrice * 1.05).toStringAsFixed(2);
      _targetPriceController.text = (currentPrice * 0.90).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _triggerPriceController.dispose();
    _stopLossPriceController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return quantity * price;
  }

  void _executeTrade() async {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid quantity')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      switch (_orderType) {
        case _CryptoOrderType.market:
          await _executeMarketOrder(quantity, price);
          break;
        case _CryptoOrderType.stopLoss:
          await _executeStopLossOrder(quantity);
          break;
        case _CryptoOrderType.bracket:
          await _executeBracketOrder(quantity, price);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _executeMarketOrder(double quantity, double price) async {
    if (price <= 0) {
      throw Exception('Please enter valid price');
    }

    if (_isBuying) {
      context.read<CryptoBloc>().add(
        BuyCrypto(
          symbol: widget.symbol,
          name: widget.name,
          quantity: quantity,
          price: price,
        ),
      );
    } else {
      context.read<CryptoBloc>().add(
        SellCrypto(symbol: widget.symbol, quantity: quantity, price: price),
      );
    }

    // Reduced delay for faster UI response
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_isBuying ? 'Buy' : 'Sell'} order executed successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _executeStopLossOrder(double quantity) async {
    final triggerPrice = double.tryParse(_triggerPriceController.text) ?? 0;

    if (triggerPrice <= 0) {
      throw Exception('Please enter valid trigger price');
    }

    context.read<OrderBloc>().add(
      CreateStopLossOrder(
        assetSymbol: widget.symbol,
        assetName: widget.name,
        assetType: AssetType.crypto,
        orderSide: _isBuying ? OrderSide.buy : OrderSide.sell,
        quantity: quantity,
        triggerPrice: triggerPrice,
        notes: 'Crypto stop-loss order',
      ),
    );

    // Reduced delay for faster UI response
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stop-loss order created at ₹${triggerPrice.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _executeBracketOrder(double quantity, double entryPrice) async {
    if (entryPrice <= 0) {
      throw Exception('Please enter valid entry price');
    }

    final stopLossPrice = double.tryParse(_stopLossPriceController.text) ?? 0;
    final targetPrice = double.tryParse(_targetPriceController.text) ?? 0;

    if (stopLossPrice <= 0 || targetPrice <= 0) {
      throw Exception('Please enter valid stop-loss and target prices');
    }

    if (_isBuying) {
      if (stopLossPrice >= entryPrice) {
        throw Exception('Stop-loss must be below entry price for buy orders');
      }
      if (targetPrice <= entryPrice) {
        throw Exception('Target must be above entry price for buy orders');
      }
    } else {
      if (stopLossPrice <= entryPrice) {
        throw Exception('Stop-loss must be above entry price for sell orders');
      }
      if (targetPrice >= entryPrice) {
        throw Exception('Target must be below entry price for sell orders');
      }
    }

    context.read<OrderBloc>().add(
      CreateBracketOrder(
        assetSymbol: widget.symbol,
        assetName: widget.name,
        assetType: AssetType.crypto,
        orderSide: _isBuying ? OrderSide.buy : OrderSide.sell,
        quantity: quantity,
        entryPrice: entryPrice,
        stopLossPrice: stopLossPrice,
        targetPrice: targetPrice,
        notes: 'Crypto bracket order',
      ),
    );

    // Reduced delay for faster UI response
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bracket order created: Entry ₹${entryPrice.toStringAsFixed(0)} | SL ₹${stopLossPrice.toStringAsFixed(0)} | Target ₹${targetPrice.toStringAsFixed(0)}',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Widget _buildOrderTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Type',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withAlpha((0.7 * 255).round()),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildOrderTypeChip(
              label: 'Market',
              icon: Icons.flash_on,
              isSelected: _orderType == _CryptoOrderType.market,
              onTap: () => setState(() => _orderType = _CryptoOrderType.market),
            ),
            const SizedBox(width: 8),
            _buildOrderTypeChip(
              label: 'Stop-Loss',
              icon: Icons.shield,
              isSelected: _orderType == _CryptoOrderType.stopLoss,
              onTap: () =>
                  setState(() => _orderType = _CryptoOrderType.stopLoss),
            ),
            const SizedBox(width: 8),
            _buildOrderTypeChip(
              label: 'Bracket',
              icon: Icons.account_tree,
              isSelected: _orderType == _CryptoOrderType.bracket,
              onTap: () =>
                  setState(() => _orderType = _CryptoOrderType.bracket),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderTypeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected
        ? const Color(0xFFE5BCE7)
        : Colors.white.withAlpha((0.5 * 255).round());
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE5BCE7).withAlpha((0.15 * 255).round())
                : const Color(0xff1a1a1a),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFE5BCE7) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopLossInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.orange.withAlpha((0.3 * 255).round()),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isBuying
                      ? 'Order triggers when price drops to trigger price'
                      : 'Order triggers when price rises to trigger price',
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _triggerPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'ClashDisplay',
          ),
          decoration: InputDecoration(
            labelText: 'Trigger Price (₹)',
            labelStyle: TextStyle(
              color: Colors.white.withAlpha((0.5 * 255).round()),
              fontFamily: 'ClashDisplay',
            ),
            prefixIcon: const Icon(Icons.trending_down, color: Colors.orange),
            filled: true,
            fillColor: const Color(0xff1a1a1a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBracketInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.blue.withAlpha((0.3 * 255).round()),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Entry executes now. Stop-loss & target orders created automatically.',
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stopLossPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'ClashDisplay',
                ),
                decoration: InputDecoration(
                  labelText: 'Stop-Loss (₹)',
                  labelStyle: TextStyle(
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                    fontFamily: 'ClashDisplay',
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.shield,
                    color: Colors.red,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xff1a1a1a),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _targetPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'ClashDisplay',
                ),
                decoration: InputDecoration(
                  labelText: 'Target (₹)',
                  labelStyle: TextStyle(
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                    fontFamily: 'ClashDisplay',
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.flag,
                    color: Colors.green,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xff1a1a1a),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_orderType == _CryptoOrderType.bracket) ...[
          const SizedBox(height: 12),
          _buildRiskRewardInfo(),
        ],
      ],
    );
  }

  Widget _buildRiskRewardInfo() {
    final entryPrice = double.tryParse(_priceController.text) ?? 0;
    final stopLoss = double.tryParse(_stopLossPriceController.text) ?? 0;
    final target = double.tryParse(_targetPriceController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    if (entryPrice <= 0 || stopLoss <= 0 || target <= 0 || quantity <= 0) {
      return const SizedBox.shrink();
    }

    final potentialLoss = (entryPrice - stopLoss).abs() * quantity;
    final potentialProfit = (target - entryPrice).abs() * quantity;
    final riskReward = potentialLoss > 0
        ? potentialProfit / potentialLoss
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildRiskRewardItem(
            'Risk',
            '₹${potentialLoss.toStringAsFixed(0)}',
            Colors.red,
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withAlpha((0.1 * 255).round()),
          ),
          _buildRiskRewardItem(
            'Reward',
            '₹${potentialProfit.toStringAsFixed(0)}',
            Colors.green,
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withAlpha((0.1 * 255).round()),
          ),
          _buildRiskRewardItem(
            'R:R',
            '1:${riskReward.toStringAsFixed(1)}',
            const Color(0xFFE5BCE7),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskRewardItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 11,
            color: Colors.white.withAlpha((0.5 * 255).round()),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getButtonText() {
    switch (_orderType) {
      case _CryptoOrderType.market:
        return '${_isBuying ? 'Buy' : 'Sell'} ${widget.symbol}';
      case _CryptoOrderType.stopLoss:
        return 'Create Stop-Loss Order';
      case _CryptoOrderType.bracket:
        return 'Create Bracket Order';
    }
  }

  Color _getButtonColor() {
    switch (_orderType) {
      case _CryptoOrderType.market:
        return _isBuying ? Colors.green : Colors.red;
      case _CryptoOrderType.stopLoss:
        return Colors.orange;
      case _CryptoOrderType.bracket:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
          setState(() => _isProcessing = false);
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xff0a0a0a),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CryptoLogo(symbol: widget.symbol, size: 36, fontSize: 12),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trade ${widget.symbol}',
                            style: const TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.name,
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 12,
                              color: Colors.white.withAlpha(
                                (0.5 * 255).round(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Order Type Selector
              _buildOrderTypeSelector(),
              const SizedBox(height: 20),

              // Buy/Sell Toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBuying = true;
                          _updateDefaultPrices();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isBuying
                              ? Colors.green
                              : const Color(0xff1a1a1a),
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
                      onTap: () {
                        setState(() {
                          _isBuying = false;
                          _updateDefaultPrices();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isBuying
                              ? Colors.red
                              : const Color(0xff1a1a1a),
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
              const SizedBox(height: 20),

              // Quantity Input
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'ClashDisplay',
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                    fontFamily: 'ClashDisplay',
                  ),
                  filled: true,
                  fillColor: const Color(0xff1a1a1a),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Price Input (for Market and Bracket orders)
              if (_orderType != _CryptoOrderType.stopLoss) ...[
                TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'ClashDisplay',
                  ),
                  decoration: InputDecoration(
                    labelText: _orderType == _CryptoOrderType.bracket
                        ? 'Entry Price (₹)'
                        : 'Price per unit (₹)',
                    labelStyle: TextStyle(
                      color: Colors.white.withAlpha((0.5 * 255).round()),
                      fontFamily: 'ClashDisplay',
                    ),
                    filled: true,
                    fillColor: const Color(0xff1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
              ],

              // Stop-Loss specific inputs
              if (_orderType == _CryptoOrderType.stopLoss)
                _buildStopLossInputs(),

              // Bracket order specific inputs
              if (_orderType == _CryptoOrderType.bracket) _buildBracketInputs(),

              const SizedBox(height: 20),

              // Total Amount
              if (_orderType == _CryptoOrderType.market ||
                  _orderType == _CryptoOrderType.bracket)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff1a1a1a),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _orderType == _CryptoOrderType.bracket
                            ? 'Entry Amount'
                            : 'Total Amount',
                        style: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatINR(_totalAmount),
                        style: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE5BCE7),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Execute Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _executeTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _getButtonText(),
                          style: const TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
