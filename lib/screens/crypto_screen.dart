import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/services/freecrypto_service.dart';
import '../core/models/models.dart';
import '../core/utils/currency_formatter.dart';
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
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load initial data
    context.read<CryptoBloc>().add(const LoadCryptoMarket());
    context.read<CryptoBloc>().add(const LoadCryptoHoldings());

    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isSearching) {
        context.read<CryptoBloc>().add(const RefreshCryptoMarket());
        context.read<CryptoBloc>().add(const RefreshCryptoHoldings());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Crypto',
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Portfolio Summary Card (only shown in Holdings tab)
            _buildPortfolioSummary(),

            const SizedBox(height: 20),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xff121212),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE5BCE7), Color(0xFFD4A5D6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Market'),
                    Tab(text: 'Holdings'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildMarketTab(), _buildHoldingsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Portfolio Summary Card (shown only in Holdings tab)
  Widget _buildPortfolioSummary() {
    return BlocBuilder<CryptoBloc, CryptoState>(
      builder: (context, state) {
        // Only show if we're on holdings tab AND have holdings
        if (_tabController.index != 1 || state is! CryptoHoldingsLoaded) {
          return const SizedBox.shrink();
        }

        final totalValue = state.totalValue;
        final totalPnL = state.totalProfitLoss;
        final pnlPercentage = state.totalProfitLossPercentage;
        final isPositive = totalPnL >= 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE5BCE7).withAlpha((0.1 * 255).round()),
                  const Color(0xFFD4A5D6).withAlpha((0.05 * 255).round()),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha((0.1 * 255).round()),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Crypto Portfolio',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withAlpha((0.6 * 255).round()),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.formatINR(totalValue),
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${CurrencyFormatter.formatINR(totalPnL)}',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${isPositive ? '+' : ''}${pnlPercentage.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isPositive
                            ? Colors.green.withAlpha((0.8 * 255).round())
                            : Colors.red.withAlpha((0.8 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Market Tab - Shows all available cryptocurrencies
  Widget _buildMarketTab() {
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

  /// Holdings Tab - Shows user's crypto holdings
  Widget _buildHoldingsTab() {
    return BlocBuilder<CryptoBloc, CryptoState>(
      builder: (context, state) {
        if (state is CryptoHoldingsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE5BCE7)),
          );
        }

        if (state is CryptoHoldingsEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.currency_bitcoin,
                  size: 80,
                  color: Colors.white.withAlpha((0.3 * 255).round()),
                ),
                const SizedBox(height: 20),
                Text(
                  'No Crypto Holdings',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start trading cryptocurrencies from the Market tab',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is CryptoHoldingsError) {
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
                  'Error Loading Holdings',
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
                    context.read<CryptoBloc>().add(const LoadCryptoHoldings());
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

        if (state is CryptoHoldingsLoaded) {
          final holdings = state.holdings;
          final pricesMap = state.currentPrices;

          return RefreshIndicator(
            color: const Color(0xFFE5BCE7),
            onRefresh: () async {
              context.read<CryptoBloc>().add(const RefreshCryptoHoldings());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: holdings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final holding = holdings[index];
                final currentPrice =
                    pricesMap[holding.assetSymbol]?.price ??
                    holding.currentPrice ??
                    holding.averagePrice;
                return _buildHoldingCard(holding, currentPrice);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Crypto Card Widget for Market Tab
  Widget _buildCryptoCard(CryptoQuote crypto) {
    final isPositive = crypto.changePercent24h >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha((0.08 * 255).round())),
      ),
      child: Row(
        children: [
          // Crypto Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE5BCE7).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                crypto.symbol.substring(
                  0,
                  crypto.symbol.length > 3 ? 3 : crypto.symbol.length,
                ),
                style: const TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE5BCE7),
                ),
              ),
            ),
          ),

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  /// Holding Card Widget for Holdings Tab
  Widget _buildHoldingCard(Holding holding, double currentPrice) {
    final currentValue = holding.quantity * currentPrice;
    final profitLoss = currentValue - holding.totalInvested;
    final profitLossPercentage = (profitLoss / holding.totalInvested) * 100;
    final isPositive = profitLoss >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha((0.08 * 255).round())),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Crypto Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5BCE7).withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    holding.assetSymbol.substring(
                      0,
                      holding.assetSymbol.length > 3
                          ? 3
                          : holding.assetSymbol.length,
                    ),
                    style: const TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE5BCE7),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Crypto Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holding.assetSymbol,
                      style: const TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${holding.quantity.toStringAsFixed(8)} ${holding.assetSymbol}',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 12,
                        color: Colors.white.withAlpha((0.6 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),

              // Sell Button
              IconButton(
                onPressed: () => _showSellDialog(holding, currentPrice),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove, color: Colors.red, size: 16),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  'Invested',
                  CurrencyFormatter.formatINRCompact(holding.totalInvested),
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withAlpha((0.1 * 255).round()),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Current',
                  CurrencyFormatter.formatINRCompact(currentValue),
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withAlpha((0.1 * 255).round()),
              ),
              Expanded(
                child: _buildStatColumn(
                  'P&L',
                  '${isPositive ? '+' : ''}${CurrencyFormatter.formatINRCompact(profitLoss)}',
                  valueColor: isPositive ? Colors.green : Colors.red,
                  subtitle:
                      '${isPositive ? '+' : ''}${profitLossPercentage.toStringAsFixed(2)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper widget for stat columns
  Widget _buildStatColumn(
    String label,
    String value, {
    Color? valueColor,
    String? subtitle,
  }) {
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
            color: valueColor ?? Colors.white,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 10,
              color: (valueColor ?? Colors.white).withAlpha(
                (0.7 * 255).round(),
              ),
            ),
          ),
        ],
      ],
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

  /// Show Sell Dialog
  void _showSellDialog(Holding holding, double currentPrice) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff1a1a1a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sell ${holding.assetSymbol}',
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
              'Available: ${holding.quantity.toStringAsFixed(8)} ${holding.assetSymbol}',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 14,
                color: Colors.white.withAlpha((0.7 * 255).round()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Price: ${CurrencyFormatter.formatINR(currentPrice)}',
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
                labelText: 'Quantity to Sell',
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

                        if (quantity > holding.quantity) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Insufficient quantity'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        context.read<CryptoBloc>().add(
                          SellCrypto(
                            symbol: holding.assetSymbol,
                            quantity: quantity,
                            price: currentPrice,
                          ),
                        );
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Text(
                        'Sell',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          color: Colors.red,
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
