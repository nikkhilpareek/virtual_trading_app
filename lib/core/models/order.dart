import 'asset_type.dart';

/// Enum representing different types of orders
enum OrderType {
  market, // Execute immediately at current market price
  limit, // Execute at a specific price or better
  stopLoss, // Trigger sell when price reaches stop level
  bracket, // Entry order with both stop-loss and take-profit
}

/// Enum representing stop-loss types
enum StopLossType {
  fixed, // Fixed stop-loss price that doesn't change
  trailing, // Trailing stop-loss that follows price upwards (for buy) or downwards (for sell)
}

/// Extension to convert StopLossType enum to string
extension StopLossTypeExtension on StopLossType {
  String toDbString() {
    switch (this) {
      case StopLossType.fixed:
        return 'fixed';
      case StopLossType.trailing:
        return 'trailing';
    }
  }

  String get displayName {
    switch (this) {
      case StopLossType.fixed:
        return 'Fixed Stop-Loss';
      case StopLossType.trailing:
        return 'Trailing Stop-Loss';
    }
  }
}

/// Helper function to parse StopLossType from database string
StopLossType stopLossTypeFromDbString(String value) {
  switch (value) {
    case 'fixed':
      return StopLossType.fixed;
    case 'trailing':
      return StopLossType.trailing;
    default:
      throw ArgumentError('Unknown stop-loss type: $value');
  }
}

/// Enum representing the side of an order (buy or sell)
enum OrderSide { buy, sell }

/// Enum representing the current status of an order
enum OrderStatus {
  pending, // Order created, waiting for trigger condition
  triggered, // Stop-loss triggered, waiting for execution
  partiallyFilled, // Part of the order has been filled
  filled, // Order completely filled
  cancelled, // Order cancelled by user or system
  expired, // Order expired (time-based expiry)
  failed, // Order execution failed
}

/// Extension to convert OrderType enum to string for database storage
extension OrderTypeExtension on OrderType {
  String toShortString() {
    return toString().split('.').last;
  }

  /// Convert to database-compatible string
  String toDbString() {
    switch (this) {
      case OrderType.market:
        return 'market';
      case OrderType.limit:
        return 'limit';
      case OrderType.stopLoss:
        return 'stop_loss';
      case OrderType.bracket:
        return 'bracket';
    }
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case OrderType.market:
        return 'Market Order';
      case OrderType.limit:
        return 'Limit Order';
      case OrderType.stopLoss:
        return 'Stop-Loss Order';
      case OrderType.bracket:
        return 'Bracket Order';
    }
  }
}

/// Helper function to parse OrderType from database string
OrderType orderTypeFromDbString(String value) {
  switch (value) {
    case 'market':
      return OrderType.market;
    case 'limit':
      return OrderType.limit;
    case 'stop_loss':
      return OrderType.stopLoss;
    case 'bracket':
      return OrderType.bracket;
    default:
      throw ArgumentError('Unknown order type: $value');
  }
}

/// Extension for OrderSide enum
extension OrderSideExtension on OrderSide {
  String toDbString() {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case OrderSide.buy:
        return 'Buy';
      case OrderSide.sell:
        return 'Sell';
    }
  }
}

/// Helper function to parse OrderSide from database string
OrderSide orderSideFromDbString(String value) {
  switch (value) {
    case 'buy':
      return OrderSide.buy;
    case 'sell':
      return OrderSide.sell;
    default:
      throw ArgumentError('Unknown order side: $value');
  }
}

/// Extension for OrderStatus enum
extension OrderStatusExtension on OrderStatus {
  String toDbString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.triggered:
        return 'triggered';
      case OrderStatus.partiallyFilled:
        return 'partially_filled';
      case OrderStatus.filled:
        return 'filled';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.expired:
        return 'expired';
      case OrderStatus.failed:
        return 'failed';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.triggered:
        return 'Triggered';
      case OrderStatus.partiallyFilled:
        return 'Partially Filled';
      case OrderStatus.filled:
        return 'Filled';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.expired:
        return 'Expired';
      case OrderStatus.failed:
        return 'Failed';
    }
  }

  /// Check if order is in an active state
  bool get isActive {
    return this == OrderStatus.pending ||
        this == OrderStatus.triggered ||
        this == OrderStatus.partiallyFilled;
  }

  /// Check if order is in a final state (no longer active)
  bool get isFinal {
    return this == OrderStatus.filled ||
        this == OrderStatus.cancelled ||
        this == OrderStatus.expired ||
        this == OrderStatus.failed;
  }
}

/// Helper function to parse OrderStatus from database string
OrderStatus orderStatusFromDbString(String value) {
  switch (value) {
    case 'pending':
      return OrderStatus.pending;
    case 'triggered':
      return OrderStatus.triggered;
    case 'partially_filled':
      return OrderStatus.partiallyFilled;
    case 'filled':
      return OrderStatus.filled;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'expired':
      return OrderStatus.expired;
    case 'failed':
      return OrderStatus.failed;
    default:
      throw ArgumentError('Unknown order status: $value');
  }
}

/// Model representing an order in the trading system
class Order {
  final String id;
  final String userId;

  // Asset information
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;

  // Order configuration
  final OrderType orderType;
  final OrderSide orderSide;
  final double quantity;

  // Price triggers and limits
  final double? triggerPrice; // For stop-loss: activation price
  final double? limitPrice; // For limit orders
  final double? stopLossPrice; // For bracket: stop-loss exit
  final double? targetPrice; // For bracket: take-profit exit

  // Trailing stop-loss support
  final StopLossType? stopLossType; // Type of stop-loss (fixed or trailing)
  final double?
  trailingStopPercent; // Trailing stop-loss percentage (e.g., 2.5 for 2.5%)
  final double?
  highestPrice; // Highest price reached since order creation (for trailing buy stop-loss)
  final double?
  lowestPrice; // Lowest price reached since order creation (for trailing sell stop-loss)

  // Order status and execution
  final OrderStatus status;
  final double filledQuantity;
  final double? avgFillPrice;

  // Financial tracking
  final double? reservedBalance; // Amount reserved for buy orders

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? triggeredAt;
  final DateTime? filledAt;
  final DateTime? cancelledAt;
  final DateTime? expiresAt;

  // Bracket order relationships
  final String? parentOrderId; // Parent entry order for bracket legs
  final String? bracketStopLossId; // Stop-loss leg ID
  final String? bracketTargetId; // Take-profit leg ID

  // Execution details
  final String? transactionId; // Link to executed transaction
  final String? cancellationReason;
  final String? failureReason;

  // Metadata
  final String? notes;
  final String? clientOrderId;

  Order({
    required this.id,
    required this.userId,
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
    required this.orderType,
    required this.orderSide,
    required this.quantity,
    this.triggerPrice,
    this.limitPrice,
    this.stopLossPrice,
    this.targetPrice,
    required this.status,
    this.filledQuantity = 0.0,
    this.avgFillPrice,
    this.reservedBalance,
    required this.createdAt,
    required this.updatedAt,
    this.triggeredAt,
    this.filledAt,
    this.cancelledAt,
    this.expiresAt,
    this.parentOrderId,
    this.bracketStopLossId,
    this.bracketTargetId,
    this.transactionId,
    this.cancellationReason,
    this.failureReason,
    this.notes,
    this.clientOrderId,
    this.stopLossType = StopLossType.fixed,
    this.trailingStopPercent,
    this.highestPrice,
    this.lowestPrice,
  });

  /// Calculate remaining quantity to be filled
  double get remainingQuantity => quantity - filledQuantity;

  /// Check if order is completely filled
  bool get isFullyFilled => filledQuantity >= quantity;

  /// Check if order is active (can be cancelled or executed)
  bool get isActive => status.isActive;

  /// Check if order is final (completed, cancelled, or failed)
  bool get isFinal => status.isFinal;

  /// For bracket orders: calculate risk/reward ratio
  double? get riskRewardRatio {
    if (orderType != OrderType.bracket ||
        avgFillPrice == null ||
        stopLossPrice == null ||
        targetPrice == null) {
      return null;
    }

    if (orderSide == OrderSide.buy) {
      final risk = avgFillPrice! - stopLossPrice!;
      final reward = targetPrice! - avgFillPrice!;
      return risk > 0 ? reward / risk : null;
    } else {
      final risk = stopLossPrice! - avgFillPrice!;
      final reward = avgFillPrice! - targetPrice!;
      return risk > 0 ? reward / risk : null;
    }
  }

  /// Calculate potential profit for bracket order target
  double? get potentialProfit {
    if (orderType != OrderType.bracket ||
        avgFillPrice == null ||
        targetPrice == null) {
      return null;
    }

    return orderSide == OrderSide.buy
        ? (targetPrice! - avgFillPrice!) * quantity
        : (avgFillPrice! - targetPrice!) * quantity;
  }

  /// Calculate potential loss for bracket order stop-loss
  double? get potentialLoss {
    if (orderType != OrderType.bracket ||
        avgFillPrice == null ||
        stopLossPrice == null) {
      return null;
    }

    return orderSide == OrderSide.buy
        ? (avgFillPrice! - stopLossPrice!) * quantity
        : (stopLossPrice! - avgFillPrice!) * quantity;
  }

  /// Create Order from JSON (from Supabase)
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assetSymbol: json['asset_symbol'] as String,
      assetName: json['asset_name'] as String,
      assetType: AssetType.fromJson(json['asset_type'] as String),
      orderType: orderTypeFromDbString(json['order_type'] as String),
      orderSide: orderSideFromDbString(json['order_side'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      triggerPrice: json['trigger_price'] != null
          ? (json['trigger_price'] as num).toDouble()
          : null,
      limitPrice: json['limit_price'] != null
          ? (json['limit_price'] as num).toDouble()
          : null,
      stopLossPrice: json['stop_loss_price'] != null
          ? (json['stop_loss_price'] as num).toDouble()
          : null,
      targetPrice: json['target_price'] != null
          ? (json['target_price'] as num).toDouble()
          : null,
      status: orderStatusFromDbString(json['status'] as String),
      filledQuantity: json['filled_quantity'] != null
          ? (json['filled_quantity'] as num).toDouble()
          : 0.0,
      avgFillPrice: json['avg_fill_price'] != null
          ? (json['avg_fill_price'] as num).toDouble()
          : null,
      reservedBalance: json['reserved_balance'] != null
          ? (json['reserved_balance'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'] as String)
          : null,
      filledAt: json['filled_at'] != null
          ? DateTime.parse(json['filled_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      parentOrderId: json['parent_order_id'] as String?,
      bracketStopLossId: json['bracket_stop_loss_id'] as String?,
      bracketTargetId: json['bracket_target_id'] as String?,
      transactionId: json['transaction_id'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      failureReason: json['failure_reason'] as String?,
      notes: json['notes'] as String?,
      clientOrderId: json['client_order_id'] as String?,
      stopLossType: json['stop_loss_type'] != null
          ? stopLossTypeFromDbString(json['stop_loss_type'] as String)
          : StopLossType.fixed,
      trailingStopPercent: json['trailing_stop_percent'] != null
          ? (json['trailing_stop_percent'] as num).toDouble()
          : null,
      highestPrice: json['highest_price'] != null
          ? (json['highest_price'] as num).toDouble()
          : null,
      lowestPrice: json['lowest_price'] != null
          ? (json['lowest_price'] as num).toDouble()
          : null,
    );
  }

  /// Convert Order to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'order_type': orderType.toDbString(),
      'order_side': orderSide.toDbString(),
      'quantity': quantity,
      'trigger_price': triggerPrice,
      'limit_price': limitPrice,
      'stop_loss_price': stopLossPrice,
      'target_price': targetPrice,
      'status': status.toDbString(),
      'filled_quantity': filledQuantity,
      'avg_fill_price': avgFillPrice,
      'reserved_balance': reservedBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'triggered_at': triggeredAt?.toIso8601String(),
      'filled_at': filledAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'parent_order_id': parentOrderId,
      'bracket_stop_loss_id': bracketStopLossId,
      'bracket_target_id': bracketTargetId,
      'transaction_id': transactionId,
      'cancellation_reason': cancellationReason,
      'failure_reason': failureReason,
      'notes': notes,
      'client_order_id': clientOrderId,
      'stop_loss_type': stopLossType?.toDbString() ?? 'fixed',
      'trailing_stop_percent': trailingStopPercent,
      'highest_price': highestPrice,
      'lowest_price': lowestPrice,
    };
  }

  /// Create a copy of Order with updated fields
  Order copyWith({
    String? id,
    String? userId,
    String? assetSymbol,
    String? assetName,
    AssetType? assetType,
    OrderType? orderType,
    OrderSide? orderSide,
    double? quantity,
    double? triggerPrice,
    double? limitPrice,
    double? stopLossPrice,
    double? targetPrice,
    OrderStatus? status,
    double? filledQuantity,
    double? avgFillPrice,
    double? reservedBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? triggeredAt,
    DateTime? filledAt,
    DateTime? cancelledAt,
    DateTime? expiresAt,
    String? parentOrderId,
    String? bracketStopLossId,
    String? bracketTargetId,
    String? transactionId,
    String? cancellationReason,
    String? failureReason,
    String? notes,
    String? clientOrderId,
    StopLossType? stopLossType,
    double? trailingStopPercent,
    double? highestPrice,
    double? lowestPrice,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assetSymbol: assetSymbol ?? this.assetSymbol,
      assetName: assetName ?? this.assetName,
      assetType: assetType ?? this.assetType,
      orderType: orderType ?? this.orderType,
      orderSide: orderSide ?? this.orderSide,
      quantity: quantity ?? this.quantity,
      triggerPrice: triggerPrice ?? this.triggerPrice,
      limitPrice: limitPrice ?? this.limitPrice,
      stopLossPrice: stopLossPrice ?? this.stopLossPrice,
      targetPrice: targetPrice ?? this.targetPrice,
      status: status ?? this.status,
      filledQuantity: filledQuantity ?? this.filledQuantity,
      avgFillPrice: avgFillPrice ?? this.avgFillPrice,
      reservedBalance: reservedBalance ?? this.reservedBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      filledAt: filledAt ?? this.filledAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      expiresAt: expiresAt ?? this.expiresAt,
      parentOrderId: parentOrderId ?? this.parentOrderId,
      bracketStopLossId: bracketStopLossId ?? this.bracketStopLossId,
      bracketTargetId: bracketTargetId ?? this.bracketTargetId,
      transactionId: transactionId ?? this.transactionId,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      failureReason: failureReason ?? this.failureReason,
      notes: notes ?? this.notes,
      clientOrderId: clientOrderId ?? this.clientOrderId,
      stopLossType: stopLossType ?? this.stopLossType,
      trailingStopPercent: trailingStopPercent ?? this.trailingStopPercent,
      highestPrice: highestPrice ?? this.highestPrice,
      lowestPrice: lowestPrice ?? this.lowestPrice,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, type: ${orderType.displayName}, side: ${orderSide.displayName}, '
        'asset: $assetSymbol, quantity: $quantity, status: ${status.displayName})';
  }
}

/// Model for creating a bracket order (combines entry + stop-loss + target)
class BracketOrderRequest {
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;
  final OrderSide orderSide;
  final double quantity;
  final double entryPrice; // Current market price or desired entry
  final double stopLossPrice; // Exit price to limit losses
  final double targetPrice; // Exit price to lock in profits
  final String? notes;

  BracketOrderRequest({
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

  /// Validate bracket order prices
  bool isValid() {
    if (orderSide == OrderSide.buy) {
      // Buy bracket: stop-loss < entry < target
      return stopLossPrice < entryPrice && entryPrice < targetPrice;
    } else {
      // Sell bracket: target < entry < stop-loss
      return targetPrice < entryPrice && entryPrice < stopLossPrice;
    }
  }

  /// Calculate risk/reward ratio
  double get riskRewardRatio {
    if (orderSide == OrderSide.buy) {
      final risk = entryPrice - stopLossPrice;
      final reward = targetPrice - entryPrice;
      return risk > 0 ? reward / risk : 0;
    } else {
      final risk = stopLossPrice - entryPrice;
      final reward = entryPrice - targetPrice;
      return risk > 0 ? reward / risk : 0;
    }
  }

  /// Calculate potential profit
  double get potentialProfit {
    return orderSide == OrderSide.buy
        ? (targetPrice - entryPrice) * quantity
        : (entryPrice - targetPrice) * quantity;
  }

  /// Calculate potential loss
  double get potentialLoss {
    return orderSide == OrderSide.buy
        ? (entryPrice - stopLossPrice) * quantity
        : (stopLossPrice - entryPrice) * quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'order_side': orderSide.toDbString(),
      'quantity': quantity,
      'entry_price': entryPrice,
      'stop_loss_price': stopLossPrice,
      'target_price': targetPrice,
      'notes': notes,
    };
  }
}
