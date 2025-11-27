import 'package:equatable/equatable.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart' show BracketOrderResult;

/// Base class for all order states
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the bloc is created
class OrderInitial extends OrderState {
  const OrderInitial();
}

/// Loading state when fetching or creating orders
class OrderLoading extends OrderState {
  final String? message;

  const OrderLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State when no orders are found
class OrderEmpty extends OrderState {
  final String message;

  const OrderEmpty({this.message = 'No orders found'});

  @override
  List<Object?> get props => [message];
}

/// State when pending orders are loaded
class PendingOrdersLoaded extends OrderState {
  final List<Order> orders;
  final DateTime lastUpdated;

  const PendingOrdersLoaded({required this.orders, required this.lastUpdated});

  @override
  List<Object?> get props => [orders, lastUpdated];

  /// Get count of pending orders
  int get pendingCount =>
      orders.where((o) => o.status == OrderStatus.pending).length;

  /// Get count of triggered orders
  int get triggeredCount =>
      orders.where((o) => o.status == OrderStatus.triggered).length;
}

/// State when order history is loaded
class OrderHistoryLoaded extends OrderState {
  final List<Order> orders;
  final DateTime lastUpdated;

  const OrderHistoryLoaded({required this.orders, required this.lastUpdated});

  @override
  List<Object?> get props => [orders, lastUpdated];

  /// Get count of filled orders
  int get filledCount =>
      orders.where((o) => o.status == OrderStatus.filled).length;

  /// Get count of cancelled orders
  int get cancelledCount =>
      orders.where((o) => o.status == OrderStatus.cancelled).length;
}

/// State when both pending and history orders are loaded
class AllOrdersLoaded extends OrderState {
  final List<Order> pendingOrders;
  final List<Order> historyOrders;
  final DateTime lastUpdated;
  final OrderType? filterType;
  final OrderStatus? filterStatus;
  final String? filterAsset;

  const AllOrdersLoaded({
    required this.pendingOrders,
    required this.historyOrders,
    required this.lastUpdated,
    this.filterType,
    this.filterStatus,
    this.filterAsset,
  });

  @override
  List<Object?> get props => [
    pendingOrders,
    historyOrders,
    lastUpdated,
    filterType,
    filterStatus,
    filterAsset,
  ];

  /// Get filtered pending orders
  List<Order> get filteredPending {
    var filtered = pendingOrders;

    if (filterType != null) {
      filtered = filtered.where((o) => o.orderType == filterType).toList();
    }

    if (filterStatus != null) {
      filtered = filtered.where((o) => o.status == filterStatus).toList();
    }

    if (filterAsset != null && filterAsset!.isNotEmpty) {
      filtered = filtered.where((o) => o.assetSymbol == filterAsset).toList();
    }

    return filtered;
  }

  /// Get filtered history orders
  List<Order> get filteredHistory {
    var filtered = historyOrders;

    if (filterType != null) {
      filtered = filtered.where((o) => o.orderType == filterType).toList();
    }

    if (filterStatus != null) {
      filtered = filtered.where((o) => o.status == filterStatus).toList();
    }

    if (filterAsset != null && filterAsset!.isNotEmpty) {
      filtered = filtered.where((o) => o.assetSymbol == filterAsset).toList();
    }

    return filtered;
  }

  /// Get total count of all orders
  int get totalCount => pendingOrders.length + historyOrders.length;

  /// Copy with new filters
  AllOrdersLoaded copyWithFilters({
    OrderType? filterType,
    OrderStatus? filterStatus,
    String? filterAsset,
    bool clearFilters = false,
  }) {
    return AllOrdersLoaded(
      pendingOrders: pendingOrders,
      historyOrders: historyOrders,
      lastUpdated: lastUpdated,
      filterType: clearFilters ? null : (filterType ?? this.filterType),
      filterStatus: clearFilters ? null : (filterStatus ?? this.filterStatus),
      filterAsset: clearFilters ? null : (filterAsset ?? this.filterAsset),
    );
  }
}

/// State when a stop-loss order is being created
class CreatingStopLossOrder extends OrderState {
  const CreatingStopLossOrder();
}

/// State when a stop-loss order is successfully created
class StopLossOrderCreated extends OrderState {
  final Order order;

  const StopLossOrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

/// State when a bracket order is being created
class CreatingBracketOrder extends OrderState {
  const CreatingBracketOrder();
}

/// State when a bracket order is successfully created
class BracketOrderCreated extends OrderState {
  final BracketOrderResult bracketOrder;

  const BracketOrderCreated(this.bracketOrder);

  @override
  List<Object?> get props => [bracketOrder];
}

/// State when cancelling an order
class CancellingOrder extends OrderState {
  final String orderId;

  const CancellingOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// State when an order is successfully cancelled
class OrderCancelled extends OrderState {
  final Order order;

  const OrderCancelled(this.order);

  @override
  List<Object?> get props => [order];
}

/// State when a single order is loaded
class SingleOrderLoaded extends OrderState {
  final Order order;

  const SingleOrderLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

/// State when a bracket order with all legs is loaded
class BracketOrderLoaded extends OrderState {
  final BracketOrderResult bracketOrder;

  const BracketOrderLoaded(this.bracketOrder);

  @override
  List<Object?> get props => [bracketOrder];
}

/// State when an order is triggered by the backend
class OrderTriggeredState extends OrderState {
  final Order order;
  final String message;

  const OrderTriggeredState({required this.order, required this.message});

  @override
  List<Object?> get props => [order, message];
}

/// Error state for order operations
class OrderError extends OrderState {
  final String message;
  final dynamic error;

  const OrderError({required this.message, this.error});

  @override
  List<Object?> get props => [message, error];
}
