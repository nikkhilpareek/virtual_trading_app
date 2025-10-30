import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/utils/currency_formatter.dart';
import 'stock_detail_screen.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'Assets',
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Portfolio Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: BlocBuilder<HoldingsBloc, HoldingsState>(
                builder: (context, state) {
                  double totalValue = 0;
                  double totalInvested = 0;
                  double totalPnL = 0;

                  if (state is HoldingsLoaded) {
                    for (var holding in state.holdings) {
                      final currentValue =
                          (holding.currentPrice ?? holding.averagePrice) *
                          holding.quantity;
                      final investedValue =
                          holding.averagePrice * holding.quantity;
                      totalValue += currentValue;
                      totalInvested += investedValue;
                    }
                    totalPnL = totalValue - totalInvested;
                  }

                  final pnlPercentage = totalInvested > 0
                      ? (totalPnL / totalInvested) * 100
                      : 0.0;
                  final isPositive = totalPnL >= 0;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(
                            0xFFE5BCE7,
                          ).withAlpha((0.1 * 255).round()),
                          const Color(
                            0xFFD4A5D6,
                          ).withAlpha((0.05 * 255).round()),
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
                          'Total Portfolio Value',
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
                              isPositive
                                  ? Icons.trending_up
                                  : Icons.trending_down,
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
                                    ? Colors.green.withAlpha(
                                        (0.8 * 255).round(),
                                      )
                                    : Colors.red.withAlpha((0.8 * 255).round()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
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
                    Tab(text: 'Holdings'),
                    Tab(text: 'Watchlist'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                // Disable swipe gestures so tabs change only via tapping the TabBar
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Holdings Tab
                  _buildHoldingsTab(),
                  // Watchlist Tab
                  _buildWatchlistTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingsTab() {
    return BlocBuilder<HoldingsBloc, HoldingsState>(
      builder: (context, state) {
        if (state is HoldingsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE5BCE7)),
          );
        }

        if (state is HoldingsError) {
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
                  state.message,
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is HoldingsLoaded) {
          if (state.holdings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.white.withAlpha((0.3 * 255).round()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Holdings Yet',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha((0.7 * 255).round()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start investing to see your assets here',
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

          return ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
            // Pre-cache nearby items to make fast scrolls smoother
            cacheExtent: 800,
            // Avoid keeping every child alive unnecessarily
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemCount: state.holdings.length,
            itemBuilder: (context, index) {
              final holding = state.holdings[index];
              return _buildHoldingCard(holding);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWatchlistTab() {
    return BlocBuilder<WatchlistBloc, WatchlistState>(
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
                  state.message,
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is WatchlistLoaded) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.white.withAlpha((0.3 * 255).round()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Watchlist Items',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha((0.7 * 255).round()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add stocks to track them here',
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

          return ListView.builder(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
            cacheExtent: 800,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _buildWatchlistCard(item);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHoldingCard(Holding holding) {
    final currentPrice = holding.currentPrice ?? holding.averagePrice;
    final currentValue = currentPrice * holding.quantity;
    final investedValue = holding.averagePrice * holding.quantity;
    final pnl = currentValue - investedValue;
    final pnlPercentage = (pnl / investedValue) * 100;
    final isPositive = pnl >= 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StockDetailScreen(holding: holding),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff121212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withAlpha((0.06 * 255).round()),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holding.assetSymbol,
                        style: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        holding.assetName,
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 12,
                          color: Colors.white.withAlpha((0.5 * 255).round()),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatINR(currentValue),
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
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 12,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${isPositive ? '+' : ''}${pnlPercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withAlpha((0.1 * 255).round()),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem('Qty', holding.quantity.toStringAsFixed(2)),
                _buildInfoItem(
                  'Avg Price',
                  CurrencyFormatter.formatINR(holding.averagePrice),
                ),
                _buildInfoItem(
                  'P&L',
                  '${isPositive ? '+' : ''}${CurrencyFormatter.formatINR(pnl)}',
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistCard(WatchlistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha((0.06 * 255).round())),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.assetSymbol,
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.assetName,
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE5BCE7).withAlpha((0.15 * 255).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.assetType.name.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE5BCE7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
