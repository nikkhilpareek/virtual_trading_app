import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class StockDetailScreen extends StatelessWidget {
  final Holding holding;

  const StockDetailScreen({
    super.key,
    required this.holding,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StockDetailBloc()
        ..add(LoadStockDetail(holding.assetSymbol)),
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
      backgroundColor: const Color(0xff0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xff0a0a0a),
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
            icon: const Icon(Icons.refresh, color: Color(0xFFE5BCE7)),
          ),
        ],
      ),
      body: BlocBuilder<StockDetailBloc, StockDetailState>(
        builder: (context, state) {
          if (state is StockDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE5BCE7),
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
                        backgroundColor: const Color(0xFFE5BCE7),
                        foregroundColor: Colors.black,
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
              color: const Color(0xFFE5BCE7),
              backgroundColor: const Color(0xff121212),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentHoldingCard(state.holding),
                      const SizedBox(height: 24),
                      _buildStatisticsSection(state),
                      const SizedBox(height: 24),
                      _buildTransactionHistory(state.transactions),
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

  Widget _buildCurrentHoldingCard(Holding? holdingData) {
    final currentHolding = holdingData ?? holding;
    final isPositive = currentHolding.profitLoss >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE5BCE7).withAlpha((0.2 * 255).round()),
            const Color(0xFF9D4EDD).withAlpha((0.1 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5BCE7).withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Holdings',
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE5BCE7),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildStatisticsSection(StockDetailLoaded state) {
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
                const Color(0xFFE5BCE7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Sell Transactions',
                '${state.sellTransactionCount}',
                Icons.trending_down,
                const Color(0xFF9D4EDD),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withAlpha((0.1 * 255).round()),
        ),
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

  Widget _buildTransactionHistory(List<Transaction> transactions) {
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
        ...transactions.map((transaction) => _buildTransactionCard(transaction)),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
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
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5BCE7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
