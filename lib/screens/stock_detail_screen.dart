import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class StockDetailScreen extends StatelessWidget {
  final Holding holding;

  const StockDetailScreen({super.key, required this.holding});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          StockDetailBloc()..add(LoadStockDetail(holding.assetSymbol)),
      child: _StockDetailView(holding: holding),
    );
  }
}

class _StockDetailView extends StatelessWidget {
  final Holding holding;

  const _StockDetailView({required this.holding});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              holding.assetSymbol,
              style: const TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              holding.assetName,
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withAlpha((0.6 * 255).round()),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<StockDetailBloc>().add(
                RefreshStockDetail(holding.assetSymbol),
              );
            },
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      floatingActionButton: _buildActionButton(context, holding),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BlocBuilder<StockDetailBloc, StockDetailState>(
        builder: (context, state) {
          if (state is StockDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          if (state is StockDetailError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        fontFamily: 'ClashDisplay',
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<StockDetailBloc>().add(
                          LoadStockDetail(holding.assetSymbol),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is StockDetailLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<StockDetailBloc>().add(
                  RefreshStockDetail(holding.assetSymbol),
                );
                await Future.delayed(const Duration(seconds: 1));
              },
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentHoldingCard(context, state.holding),
                      const SizedBox(height: 24),
                      _buildStatisticsSection(context, state),
                      const SizedBox(height: 24),
                      _buildTransactionHistory(context, state.transactions),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCurrentHoldingCard(BuildContext context, Holding? holdingData) {
    final currentHolding = holdingData ?? holding;
    final isPositive = currentHolding.profitLoss >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.2 * 255).round()),
            Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.1 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.primary.withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Holdings',
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: currentHolding.assetType == AssetType.stock
                      ? Colors.blue.withAlpha((0.2 * 255).round())
                      : currentHolding.assetType == AssetType.crypto
                      ? Colors.orange.withAlpha((0.2 * 255).round())
                      : Colors.green.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentHolding.assetType.displayName,
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: currentHolding.assetType == AssetType.stock
                        ? Colors.blue
                        : currentHolding.assetType == AssetType.crypto
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 14,
                        color: Colors.white.withAlpha((0.6 * 255).round()),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentHolding.quantity.toStringAsFixed(2),
                      style: const TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Avg Price',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 14,
                        color: Colors.white.withAlpha((0.6 * 255).round()),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatINR(currentHolding.averagePrice),
                      style: const TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Value',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 14,
                      color: Colors.white.withAlpha((0.6 * 255).round()),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatINR(currentHolding.currentValue),
                    style: const TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'P&L',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 14,
                      color: Colors.white.withAlpha((0.6 * 255).round()),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${CurrencyFormatter.formatINR(currentHolding.profitLoss)}',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${currentHolding.profitLossPercentage.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 14,
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
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    StockDetailLoaded state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trading Statistics',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Bought',
                '${state.totalBought.toStringAsFixed(2)} units',
                Icons.shopping_cart,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Sold',
                '${state.totalSold.toStringAsFixed(2)} units',
                Icons.sell,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Amount Invested',
                CurrencyFormatter.formatINR(state.totalInvested),
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Amount Received',
                CurrencyFormatter.formatINR(state.totalReceived),
                Icons.attach_money,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Buy Transactions',
                '${state.buyTransactionCount}',
                Icons.trending_up,
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Sell Transactions',
                '${state.sellTransactionCount}',
                Icons.trending_down,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha((0.1 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    color: Colors.white.withAlpha((0.7 * 255).round()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xff121212),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.white.withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 16,
                color: Colors.white.withAlpha((0.6 * 255).round()),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaction History',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              '${transactions.length} transactions',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 14,
                color: Colors.white.withAlpha((0.6 * 255).round()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...transactions.map(
          (transaction) => _buildTransactionCard(context, transaction),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, Transaction transaction) {
    final isBuy = transaction.transactionType == TransactionType.buy;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBuy
              ? Colors.green.withAlpha((0.3 * 255).round())
              : Colors.red.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isBuy
                      ? Colors.green.withAlpha((0.2 * 255).round())
                      : Colors.red.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isBuy ? Icons.add_shopping_cart : Icons.sell,
                  color: isBuy ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          transaction.transactionType.displayName,
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isBuy ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.1 * 255).round()),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${transaction.quantity.toStringAsFixed(2)} units',
                            style: const TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(transaction.createdAt)} • ${timeFormat.format(transaction.createdAt)}',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 12,
                        color: Colors.white.withAlpha((0.5 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Per Unit',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 12,
                      color: Colors.white.withAlpha((0.6 * 255).round()),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatINR(transaction.pricePerUnit),
                    style: const TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 12,
                      color: Colors.white.withAlpha((0.6 * 255).round()),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatINR(transaction.totalAmount),
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isBuy ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.05 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance After',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    color: Colors.white.withAlpha((0.7 * 255).round()),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatINR(transaction.balanceAfter),
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Action Button with multiple options
  Widget _buildActionButton(BuildContext context, Holding holding) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Sell Button
        FloatingActionButton.extended(
          heroTag: 'sell',
          onPressed: () => _showTradeDialog(context, holding, 'sell'),
          backgroundColor: Colors.red,
          icon: const Icon(Icons.sell, color: Colors.white),
          label: const Text(
            'Sell',
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Stop-Loss Button
        FloatingActionButton.extended(
          heroTag: 'stoploss',
          onPressed: () => _showTradeDialog(context, holding, 'stoploss'),
          backgroundColor: Colors.orange,
          icon: const Icon(Icons.shield, color: Colors.white, size: 20),
          label: const Text(
            'Stop-Loss',
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Bracket Order Button
        FloatingActionButton.extended(
          heroTag: 'bracket',
          onPressed: () => _showTradeDialog(context, holding, 'bracket'),
          backgroundColor: Colors.blue,
          icon: const Icon(
            Icons.account_balance,
            color: Colors.white,
            size: 20,
          ),
          label: const Text(
            'Bracket',
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  /// Show Trade Dialog with UPI-style confirmation
  void _showTradeDialog(BuildContext context, Holding holding, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _TradeBottomSheet(holding: holding, tradeType: type),
    );
  }
}

/// Trade Bottom Sheet Widget with UPI-style confirmation
class _TradeBottomSheet extends StatefulWidget {
  final Holding holding;
  final String tradeType; // 'sell', 'stoploss', 'bracket'

  const _TradeBottomSheet({required this.holding, required this.tradeType});

  @override
  State<_TradeBottomSheet> createState() => _TradeBottomSheetState();
}

class _TradeBottomSheetState extends State<_TradeBottomSheet> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _triggerPriceController = TextEditingController();
  final TextEditingController _stopLossPriceController =
      TextEditingController();
  final TextEditingController _targetPriceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentPrice =
        widget.holding.currentPrice ?? widget.holding.averagePrice;

    // Set default values
    if (widget.tradeType == 'stoploss') {
      _triggerPriceController.text = (currentPrice * 0.95).toStringAsFixed(2);
    } else if (widget.tradeType == 'bracket') {
      _stopLossPriceController.text = (currentPrice * 0.97).toStringAsFixed(2);
      _targetPriceController.text = (currentPrice * 1.05).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _triggerPriceController.dispose();
    _stopLossPriceController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  void _showConfirmationDialog(String message, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Asset', widget.holding.assetSymbol),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Amount',
                      CurrencyFormatter.formatINR(amount),
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Close bottom sheet
                    // Refresh data - Force reload from database
                    context.read<HoldingsBloc>().add(const RefreshHoldings());
                    // Use a longer delay to ensure database transaction commits
                    await Future.delayed(const Duration(milliseconds: 800));
                    if (context.mounted) {
                      // Force a complete reload, not just refresh
                      context.read<StockDetailBloc>().add(
                        LoadStockDetail(widget.holding.assetSymbol),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
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

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: Colors.white.withOpacity(isTotal ? 1.0 : 0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
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

  Future<void> _executeTrade() async {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final currentPrice =
        widget.holding.currentPrice ?? widget.holding.averagePrice;

    if (quantity <= 0) {
      _showErrorDialog(
        'Invalid Quantity',
        'Please enter a valid quantity greater than 0.',
      );
      return;
    }

    if (quantity > widget.holding.quantity) {
      _showErrorDialog(
        'Insufficient Quantity',
        'You only have ${widget.holding.quantity.toStringAsFixed(2)} units available.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      switch (widget.tradeType) {
        case 'sell':
          final totalAmount = quantity * currentPrice;
          if (widget.holding.assetType == AssetType.crypto) {
            context.read<CryptoBloc>().add(
              SellCrypto(
                symbol: widget.holding.assetSymbol,
                quantity: quantity,
                price: currentPrice,
              ),
            );
          } else {
            context.read<TransactionBloc>().add(
              ExecuteSellOrder(
                assetSymbol: widget.holding.assetSymbol,
                assetName: widget.holding.assetName,
                assetType: widget.holding.assetType,
                quantity: quantity,
                pricePerUnit: currentPrice,
              ),
            );
          }
          // Wait for transaction to complete
          await Future.delayed(const Duration(milliseconds: 1500));
          if (mounted) {
            _showConfirmationDialog(
              'Sold $quantity ${widget.holding.assetSymbol}',
              totalAmount,
            );
          }
          break;

        case 'stoploss':
          final triggerPrice =
              double.tryParse(_triggerPriceController.text) ?? 0;
          if (triggerPrice <= 0) {
            _showErrorDialog(
              'Invalid Price',
              'Please enter a valid trigger price.',
            );
            setState(() => _isLoading = false);
            return;
          }
          context.read<OrderBloc>().add(
            CreateStopLossOrder(
              assetSymbol: widget.holding.assetSymbol,
              assetName: widget.holding.assetName,
              assetType: widget.holding.assetType,
              orderSide: OrderSide.sell,
              quantity: quantity,
              triggerPrice: triggerPrice,
              notes: 'Stop-loss order from holdings',
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _showConfirmationDialog(
              'Stop-Loss order created for ${widget.holding.assetSymbol}',
              quantity * triggerPrice,
            );
          }
          break;

        case 'bracket':
          final stopLossPrice =
              double.tryParse(_stopLossPriceController.text) ?? 0;
          final targetPrice = double.tryParse(_targetPriceController.text) ?? 0;
          if (stopLossPrice <= 0 || targetPrice <= 0) {
            _showErrorDialog(
              'Invalid Prices',
              'Please enter valid stop-loss and target prices.',
            );
            setState(() => _isLoading = false);
            return;
          }
          if (stopLossPrice >= currentPrice || targetPrice <= currentPrice) {
            _showErrorDialog(
              'Invalid Bracket Order',
              'Stop-loss must be below and target must be above current price.',
            );
            setState(() => _isLoading = false);
            return;
          }
          context.read<OrderBloc>().add(
            CreateBracketOrder(
              assetSymbol: widget.holding.assetSymbol,
              assetName: widget.holding.assetName,
              assetType: widget.holding.assetType,
              orderSide: OrderSide.sell,
              quantity: quantity,
              entryPrice: currentPrice,
              stopLossPrice: stopLossPrice,
              targetPrice: targetPrice,
              notes: 'Bracket order from holdings',
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _showConfirmationDialog(
              'Bracket order created for ${widget.holding.assetSymbol}',
              quantity * currentPrice,
            );
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice =
        widget.holding.currentPrice ?? widget.holding.averagePrice;

    String title = '';
    switch (widget.tradeType) {
      case 'sell':
        title = 'Sell ${widget.holding.assetSymbol}';
        break;
      case 'stoploss':
        title = 'Stop-Loss Order';
        break;
      case 'bracket':
        title = 'Bracket Order';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Current Holdings Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Quantity',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          widget.holding.quantity.toStringAsFixed(2),
                          style: const TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Price',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatINR(currentPrice),
                          style: const TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Quantity Input
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  hintText:
                      'Max: ${widget.holding.quantity.toStringAsFixed(2)}',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to update total
                },
              ),
              const SizedBox(height: 12),
              // Type-specific inputs
              if (widget.tradeType == 'stoploss') ...[
                TextField(
                  controller: _triggerPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Trigger Price',
                    prefixIcon: const Icon(Icons.shield, color: Colors.orange),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ] else if (widget.tradeType == 'bracket') ...[
                TextField(
                  controller: _stopLossPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Stop-Loss Price',
                    prefixIcon: const Icon(Icons.shield, color: Colors.red),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _targetPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Target Price',
                    prefixIcon: const Icon(Icons.flag, color: Colors.green),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
              const SizedBox(height: 12),
              // Total Amount
              if (widget.tradeType == 'sell')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatINR(
                          (double.tryParse(_quantityController.text) ?? 0) *
                              currentPrice,
                        ),
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _executeTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.tradeType == 'sell'
                        ? Colors.red
                        : widget.tradeType == 'stoploss'
                        ? Colors.orange
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          widget.tradeType == 'sell'
                              ? 'Sell'
                              : widget.tradeType == 'stoploss'
                              ? 'Create Stop-Loss'
                              : 'Create Bracket Order',
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
