import 'package:equatable/equatable.dart';
import '../../models/order.dart';
import '../../models/asset_type.dart';

/// Base class for all order events
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

/// Load all pending orders (active orders waiting to be triggered/filled)
class LoadPendingOrders extends OrderEvent {
  const LoadPendingOrders();
}

/// Load order history (completed, cancelled, or failed orders)
class LoadOrderHistory extends OrderEvent {
  final int limit;

  const LoadOrderHistory({this.limit = 50});

  @override
  List<Object?> get props => [limit];
}

/// Create a stop-loss order
class CreateStopLossOrder extends OrderEvent {
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;
  final OrderSide orderSide;
  final double quantity;
  final double triggerPrice;
  final double? limitPrice;
  final String? notes;

  const CreateStopLossOrder({
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
    required this.orderSide,
    required this.quantity,
    required this.triggerPrice,
    this.limitPrice,
    this.notes,
  });

  @override
  List<Object?> get props => [
        assetSymbol,
        assetName,
        assetType,
        orderSide,
        quantity,
        triggerPrice,
        limitPrice,
        notes,
      ];
}

/// Create a bracket order (entry + stop-loss + target)
class CreateBracketOrder extends OrderEvent {
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;
  final OrderSide orderSide;
  final double quantity;
  final double entryPrice;
  final double stopLossPrice;
  final double targetPrice;
  final String? notes;

  const CreateBracketOrder({
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
    required this.orderSide,
    required this.quantity,
    required this.entryPrice,
    required this.stopLossPrice,
    required this.targetPrice,
    this.notes,
  });

  @override
  List<Object?> get props => [
        assetSymbol,
        assetName,
        assetType,
        orderSide,
        quantity,
        entryPrice,
        stopLossPrice,
        targetPrice,
        notes,
      ];
}

/// Cancel an existing order
class CancelOrder extends OrderEvent {
  final String orderId;
  final String? reason;

  const CancelOrder({
    required this.orderId,
    this.reason,
  });

  @override
  List<Object?> get props => [orderId, reason];
}

/// Get a specific order by ID
class GetOrderById extends OrderEvent {
  final String orderId;

  const GetOrderById(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Get bracket order with all its legs
class GetBracketOrder extends OrderEvent {
  final String parentOrderId;

  const GetBracketOrder(this.parentOrderId);

  @override
  List<Object?> get props => [parentOrderId];
}

/// Refresh all orders (both pending and history)
class RefreshOrders extends OrderEvent {
  const RefreshOrders();
}

/// Event triggered when an order is updated from the backend
/// (e.g., when a stop-loss is triggered and filled)
class OrderTriggered extends OrderEvent {
  final Order order;

  const OrderTriggered(this.order);

  @override
  List<Object?> get props => [order];
}

/// Filter orders by type
class FilterOrdersByType extends OrderEvent {
  final OrderType? orderType;

  const FilterOrdersByType(this.orderType);

  @override
  List<Object?> get props => [orderType];
}

/// Filter orders by status
class FilterOrdersByStatus extends OrderEvent {
  final OrderStatus? status;

  const FilterOrdersByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

/// Filter orders by asset
class FilterOrdersByAsset extends OrderEvent {
  final String? assetSymbol;

  const FilterOrdersByAsset(this.assetSymbol);

  @override
  List<Object?> get props => [assetSymbol];
}
