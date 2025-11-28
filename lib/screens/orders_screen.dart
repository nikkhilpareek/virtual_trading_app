import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/utils/currency_formatter.dart';

/// Screen to display and manage pending orders (stop-loss, bracket orders)
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load orders on screen init
    context.read<OrderBloc>().add(const RefreshOrders());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Orders',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<OrderBloc>().add(const RefreshOrders());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE5BCE7),
          labelColor: const Color(0xFFE5BCE7),
          unselectedLabelColor: Colors.white.withAlpha((0.5 * 255).round()),
          labelStyle: const TextStyle(
            fontFamily: 'ClashDisplay',
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5BCE7)),
            );
          }

          if (state is OrderError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.withAlpha((0.7 * 255).round()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      color: Colors.white.withAlpha((0.7 * 255).round()),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OrderBloc>().add(const RefreshOrders());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          List<Order> pendingOrders = [];
          List<Order> historyOrders = [];

          if (state is AllOrdersLoaded) {
            pendingOrders = state.pendingOrders;
            historyOrders = state.historyOrders;
          } else if (state is PendingOrdersLoaded) {
            pendingOrders = state.orders;
          } else if (state is OrderHistoryLoaded) {
            historyOrders = state.orders;
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(pendingOrders, isActive: true),
              _buildOrdersList(historyOrders, isActive: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.pending_actions : Icons.history,
              size: 64,
              color: Colors.white.withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active orders' : 'No order history',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha((0.5 * 255).round()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'Create stop-loss or bracket orders from the trade dialog'
                  : 'Your completed orders will appear here',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 14,
                color: Colors.white.withAlpha((0.3 * 255).round()),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE5BCE7),
      onRefresh: () async {
        context.read<OrderBloc>().add(const RefreshOrders());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order, isActive: isActive);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order, {required bool isActive}) {
    final isStopLoss = order.orderType == OrderType.stopLoss;
    final isBracket = order.orderType == OrderType.bracket;
    final isBuy = order.orderSide == OrderSide.buy;

    Color typeColor;
    IconData typeIcon;

    if (isBracket) {
      typeColor = Colors.blue;
      typeIcon = Icons.account_tree;
    } else if (isStopLoss) {
      typeColor = Colors.orange;
      typeIcon = Icons.shield;
    } else {
      typeColor = isBuy ? Colors.green : Colors.red;
      typeIcon = Icons.flash_on;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Main card content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    // Order type icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: typeColor.withAlpha((0.15 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    // Symbol and type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.assetSymbol,
                            style: const TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withAlpha(
                                    (0.2 * 255).round(),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order.orderType.displayName,
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: typeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (isBuy ? Colors.green : Colors.red)
                                      .withAlpha((0.2 * 255).round()),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isBuy ? 'BUY' : 'SELL',
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isBuy ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    _buildStatusBadge(order.status),
                  ],
                ),

                const SizedBox(height: 16),

                // Order details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff0a0a0a),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Quantity', '${order.quantity}'),
                      if (order.triggerPrice != null)
                        _buildDetailRow(
                          'Trigger Price',
                          CurrencyFormatter.formatINR(order.triggerPrice!),
                        ),
                      if (order.stopLossPrice != null)
                        _buildDetailRow(
                          'Stop-Loss',
                          CurrencyFormatter.formatINR(order.stopLossPrice!),
                          valueColor: Colors.red,
                        ),
                      if (order.targetPrice != null)
                        _buildDetailRow(
                          'Target',
                          CurrencyFormatter.formatINR(order.targetPrice!),
                          valueColor: Colors.green,
                        ),
                      if (order.avgFillPrice != null)
                        _buildDetailRow(
                          'Fill Price',
                          CurrencyFormatter.formatINR(order.avgFillPrice!),
                          valueColor: const Color(0xFFE5BCE7),
                        ),
                      _buildDetailRow(
                        'Created',
                        _formatDateTime(order.createdAt),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action button (for active orders only)
          if (isActive && order.isActive)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showCancelConfirmation(order),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          color: Colors.red.withAlpha((0.8 * 255).round()),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cancel Order',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.withAlpha((0.8 * 255).round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    String label;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        label = 'PENDING';
        break;
      case OrderStatus.triggered:
        color = Colors.blue;
        label = 'TRIGGERED';
        break;
      case OrderStatus.partiallyFilled:
        color = Colors.purple;
        label = 'PARTIAL';
        break;
      case OrderStatus.filled:
        color = Colors.green;
        label = 'FILLED';
        break;
      case OrderStatus.cancelled:
        color = Colors.grey;
        label = 'CANCELLED';
        break;
      case OrderStatus.expired:
        color = Colors.brown;
        label = 'EXPIRED';
        break;
      case OrderStatus.failed:
        color = Colors.red;
        label = 'FAILED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'ClashDisplay',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 13,
              color: Colors.white.withAlpha((0.5 * 255).round()),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showCancelConfirmation(Order order) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Order?',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel the ${order.orderType.displayName} for ${order.assetSymbol}?',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            color: Colors.white.withAlpha((0.7 * 255).round()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Keep Order',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.white.withAlpha((0.5 * 255).round()),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<OrderBloc>().add(
                CancelOrder(orderId: order.id, reason: 'Cancelled by user'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order cancelled'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Cancel Order',
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
