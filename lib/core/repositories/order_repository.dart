import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/asset_type.dart';

/// Repository for managing orders (stop-loss, bracket, etc.)
class OrderRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Create a simple stop-loss order
  ///
  /// [assetSymbol] - Stock/crypto symbol (e.g., 'RELIANCE', 'BTC')
  /// [assetName] - Display name of the asset
  /// [assetType] - Type of asset (stock, crypto, mutualFund)
  /// [orderSide] - Buy or Sell
  /// [quantity] - Number of units
  /// [triggerPrice] - Price level that activates the stop-loss
  /// [limitPrice] - Optional limit price after trigger
  Future<Order> createStopLossOrder({
    required String assetSymbol,
    required String assetName,
    required AssetType assetType,
    required OrderSide orderSide,
    required double quantity,
    required double triggerPrice,
    double? limitPrice,
    String? notes,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Validate trigger price
    if (triggerPrice <= 0) {
      throw Exception('Trigger price must be greater than 0');
    }

    // For buy stop-loss, we need to reserve balance
    double? reservedBalance;
    if (orderSide == OrderSide.buy) {
      final estimatedCost = quantity * (limitPrice ?? triggerPrice);

      // Check user balance
      final userProfile = await _supabase
          .from('profiles')
          .select('stonk_balance')
          .eq('id', _currentUserId!)
          .single();

      final currentBalance = (userProfile['stonk_balance'] as num).toDouble();

      if (currentBalance < estimatedCost) {
        throw Exception(
          'Insufficient balance. Required: ₹${estimatedCost.toStringAsFixed(2)}, Available: ₹${currentBalance.toStringAsFixed(2)}',
        );
      }

      reservedBalance = estimatedCost;

      // Deduct reserved balance
      await _supabase
          .from('profiles')
          .update({'stonk_balance': currentBalance - reservedBalance})
          .eq('id', _currentUserId!);
    } else {
      // For sell stop-loss, verify holding exists
      final holdings = await _supabase
          .from('holdings')
          .select('quantity')
          .eq('user_id', _currentUserId!)
          .eq('asset_symbol', assetSymbol)
          .maybeSingle();

      if (holdings == null) {
        throw Exception('You do not own any $assetSymbol to sell');
      }

      final availableQuantity = (holdings['quantity'] as num).toDouble();
      if (availableQuantity < quantity) {
        throw Exception(
          'Insufficient holdings. Required: $quantity, Available: $availableQuantity',
        );
      }
    }

    final now = DateTime.now();
    final orderId = _uuid.v4();

    final orderData = {
      'id': orderId,
      'user_id': _currentUserId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'order_type': OrderType.stopLoss.toDbString(),
      'order_side': orderSide.toDbString(),
      'quantity': quantity,
      'trigger_price': triggerPrice,
      'limit_price': limitPrice,
      'status': OrderStatus.pending.toDbString(),
      'filled_quantity': 0,
      'reserved_balance': reservedBalance,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'notes': notes,
    };

    final response = await _supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single();

    return Order.fromJson(response);
  }

  /// Create a bracket order (entry + stop-loss + take-profit)
  ///
  /// Creates three linked orders:
  /// 1. Entry order (executed immediately at market price)
  /// 2. Stop-loss order (triggers if price drops below stop level)
  /// 3. Take-profit order (triggers if price reaches target level)
  ///
  /// When one leg fills, the other is automatically cancelled
  Future<BracketOrderResult> createBracketOrder({
    required String assetSymbol,
    required String assetName,
    required AssetType assetType,
    required OrderSide orderSide,
    required double quantity,
    required double entryPrice, // Current market price
    required double stopLossPrice, // Exit to limit loss
    required double targetPrice, // Exit to lock profit
    String? notes,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Validate bracket order prices
    if (orderSide == OrderSide.buy) {
      // Buy bracket: stop-loss < entry < target
      if (stopLossPrice >= entryPrice || entryPrice >= targetPrice) {
        throw Exception(
          'Invalid bracket prices for BUY: stop-loss ($stopLossPrice) < entry ($entryPrice) < target ($targetPrice)',
        );
      }
    } else {
      // Sell bracket: target < entry < stop-loss
      if (targetPrice >= entryPrice || entryPrice >= stopLossPrice) {
        throw Exception(
          'Invalid bracket prices for SELL: target ($targetPrice) < entry ($entryPrice) < stop-loss ($stopLossPrice)',
        );
      }
    }

    final now = DateTime.now();

    // Step 1: Execute entry order immediately (like market order)
    late Order entryOrder;
    if (orderSide == OrderSide.buy) {
      entryOrder = await _executeBuyOrder(
        assetSymbol: assetSymbol,
        assetName: assetName,
        assetType: assetType,
        quantity: quantity,
        price: entryPrice,
        orderType: OrderType.bracket,
        notes: notes,
      );
    } else {
      entryOrder = await _executeSellOrder(
        assetSymbol: assetSymbol,
        assetName: assetName,
        assetType: assetType,
        quantity: quantity,
        price: entryPrice,
        orderType: OrderType.bracket,
        notes: notes,
      );
    }

    // Step 2: Create stop-loss leg (opposite side of entry)
    final stopLossId = _uuid.v4();
    final stopLossOrderData = {
      'id': stopLossId,
      'user_id': _currentUserId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'order_type': OrderType.stopLoss.toDbString(),
      'order_side':
          (orderSide == OrderSide.buy ? OrderSide.sell : OrderSide.buy)
              .toDbString(),
      'quantity': quantity,
      'trigger_price': stopLossPrice,
      'stop_loss_price': stopLossPrice,
      'status': OrderStatus.pending.toDbString(),
      'filled_quantity': 0,
      'parent_order_id': entryOrder.id,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'notes': 'Bracket Order - Stop Loss Leg',
    };

    // Step 3: Create take-profit leg (opposite side of entry)
    final targetId = _uuid.v4();
    final targetOrderData = {
      'id': targetId,
      'user_id': _currentUserId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'order_type': OrderType.stopLoss
          .toDbString(), // Target also uses stop-loss mechanism
      'order_side':
          (orderSide == OrderSide.buy ? OrderSide.sell : OrderSide.buy)
              .toDbString(),
      'quantity': quantity,
      'trigger_price': targetPrice,
      'target_price': targetPrice,
      'status': OrderStatus.pending.toDbString(),
      'filled_quantity': 0,
      'parent_order_id': entryOrder.id,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'notes': 'Bracket Order - Take Profit Leg',
    };

    // Insert both legs in parallel
    final results = await Future.wait([
      _supabase.from('orders').insert(stopLossOrderData).select().single(),
      _supabase.from('orders').insert(targetOrderData).select().single(),
    ]);

    final stopLossOrder = Order.fromJson(results[0]);
    final targetOrder = Order.fromJson(results[1]);

    // Step 4: Update entry order with bracket leg references
    await _supabase
        .from('orders')
        .update({
          'bracket_stop_loss_id': stopLossId,
          'bracket_target_id': targetId,
        })
        .eq('id', entryOrder.id);

    return BracketOrderResult(
      entryOrder: entryOrder.copyWith(
        bracketStopLossId: stopLossId,
        bracketTargetId: targetId,
      ),
      stopLossOrder: stopLossOrder,
      targetOrder: targetOrder,
    );
  }

  /// Internal method to execute a buy order
  Future<Order> _executeBuyOrder({
    required String assetSymbol,
    required String assetName,
    required AssetType assetType,
    required double quantity,
    required double price,
    required OrderType orderType,
    String? notes,
  }) async {
    final totalCost = quantity * price;

    // Check and deduct balance
    final userProfile = await _supabase
        .from('profiles')
        .select('stonk_balance')
        .eq('id', _currentUserId!)
        .single();

    final currentBalance = (userProfile['stonk_balance'] as num).toDouble();

    if (currentBalance < totalCost) {
      throw Exception('Insufficient balance for entry order');
    }

    final newBalance = currentBalance - totalCost;
    await _supabase
        .from('profiles')
        .update({'stonk_balance': newBalance})
        .eq('id', _currentUserId!);

    // Create or update holding
    final existingHolding = await _supabase
        .from('holdings')
        .select()
        .eq('user_id', _currentUserId!)
        .eq('asset_symbol', assetSymbol)
        .maybeSingle();

    if (existingHolding != null) {
      final oldQty = (existingHolding['quantity'] as num).toDouble();
      final oldAvgPrice = (existingHolding['average_price'] as num).toDouble();
      final newQty = oldQty + quantity;
      final newAvgPrice =
          ((oldQty * oldAvgPrice) + (quantity * price)) / newQty;

      await _supabase
          .from('holdings')
          .update({
            'quantity': newQty,
            'average_price': newAvgPrice,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existingHolding['id']);
    } else {
      await _supabase.from('holdings').insert({
        'user_id': _currentUserId,
        'asset_symbol': assetSymbol,
        'asset_name': assetName,
        'asset_type': assetType.toJson(),
        'quantity': quantity,
        'average_price': price,
        'current_price': price,
      });
    }

    // Create transaction record
    final transactionId = _uuid.v4();
    await _supabase.from('transactions').insert({
      'id': transactionId,
      'user_id': _currentUserId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'transaction_type': 'buy',
      'quantity': quantity,
      'price_per_unit': price,
      'total_amount': totalCost,
      'balance_after': newBalance,
    });

    // Create filled order record
    final now = DateTime.now();
    final orderId = _uuid.v4();
    final orderData = {
      'id': orderId,
      'user_id': _currentUserId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'order_type': orderType.toDbString(),
      'order_side': OrderSide.buy.toDbString(),
      'quantity': quantity,
      'status': OrderStatus.filled.toDbString(),
      'filled_quantity': quantity,
      'avg_fill_price': price,
      'transaction_id': transactionId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'filled_at': now.toIso8601String(),
      'notes': notes,
    };

    final response = await _supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single();

    return Order.fromJson(response);
  }

  /// Internal method to execute a sell order
  Future<Order> _executeSellOrder({
    required String assetSymbol,
    required String assetName,
    required AssetType assetType,
    required double quantity,
    required double price,
    required OrderType orderType,
    String? notes,
  }) async {
    // Verify holding exists and has sufficient quantity
    final holding = await _supabase
        .from('holdings')
        .select()
        .eq('user_id', _currentUserId!)
        .eq('asset_symbol', assetSymbol)
        .single();

    final availableQty = (holding['quantity'] as num).toDouble();
    if (availableQty < quantity) {
      throw Exception('Insufficient holdings to sell');
    }

    final totalProceeds = quantity * price;

    // Update balance
    final userProfile = await _supabase
        .from('profiles')
        .select('stonk_balance')
        .eq('id', _currentUserId!)
        .single();

    final currentBalance = (userProfile['stonk_balance'] as num).toDouble();
    final newBalance = currentBalance + totalProceeds;

    await _supabase
        .from('profiles')
        .update({'stonk_balance': newBalance})
        .eq('id', _currentUserId!);

    // Update or delete holding
    final newQty = availableQty - quantity;
    if (newQty > 0.0001) {
      await _supabase
          .from('holdings')
          .update({
            'quantity': newQty,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', holding['id']);
    } else {
      await _supabase.from('holdings').delete().eq('id', holding['id']);
    }

    // Create transaction record
    final transactionId = _uuid.v4();
    await _supabase.from('transactions').insert({
      'id': transactionId,
      'user_id': _currentUserId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'transaction_type': 'sell',
      'quantity': quantity,
      'price_per_unit': price,
      'total_amount': totalProceeds,
      'balance_after': newBalance,
    });

    // Create filled order record
    final now = DateTime.now();
    final orderId = _uuid.v4();
    final orderData = {
      'id': orderId,
      'user_id': _currentUserId,
      'asset_symbol': assetSymbol,
      'asset_name': assetName,
      'asset_type': assetType.toJson(),
      'order_type': orderType.toDbString(),
      'order_side': OrderSide.sell.toDbString(),
      'quantity': quantity,
      'status': OrderStatus.filled.toDbString(),
      'filled_quantity': quantity,
      'avg_fill_price': price,
      'transaction_id': transactionId,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'filled_at': now.toIso8601String(),
      'notes': notes,
    };

    final response = await _supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single();

    return Order.fromJson(response);
  }

  /// Get all pending orders for the current user
  Future<List<Order>> getPendingOrders() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('orders')
        .select()
        .eq('user_id', _currentUserId!)
        .inFilter('status', ['pending', 'triggered', 'partially_filled'])
        .order('created_at', ascending: false);

    return (response as List).map((json) => Order.fromJson(json)).toList();
  }

  /// Get order history (filled, cancelled, expired orders)
  Future<List<Order>> getOrderHistory({int limit = 50}) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('orders')
        .select()
        .eq('user_id', _currentUserId!)
        .inFilter('status', ['filled', 'cancelled', 'expired', 'failed'])
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => Order.fromJson(json)).toList();
  }

  /// Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('orders')
        .select()
        .eq('id', orderId)
        .eq('user_id', _currentUserId!)
        .maybeSingle();

    return response != null ? Order.fromJson(response) : null;
  }

  /// Cancel a pending order
  Future<Order> cancelOrder(String orderId, {String? reason}) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Get the order
    final order = await getOrderById(orderId);
    if (order == null) {
      throw Exception('Order not found');
    }

    if (!order.isActive) {
      throw Exception(
        'Order cannot be cancelled (status: ${order.status.displayName})',
      );
    }

    // If order has reserved balance, refund it
    if (order.reservedBalance != null && order.reservedBalance! > 0) {
      final userProfile = await _supabase
          .from('profiles')
          .select('stonk_balance')
          .eq('id', _currentUserId!)
          .single();

      final currentBalance = (userProfile['stonk_balance'] as num).toDouble();
      final newBalance = currentBalance + order.reservedBalance!;

      await _supabase
          .from('profiles')
          .update({'stonk_balance': newBalance})
          .eq('id', _currentUserId!);
    }

    // If this is a bracket order leg, cancel the sibling leg too
    if (order.parentOrderId != null) {
      final parentOrder = await getOrderById(order.parentOrderId!);
      if (parentOrder != null) {
        // Find and cancel the sibling leg
        final siblingId = order.id == parentOrder.bracketStopLossId
            ? parentOrder.bracketTargetId
            : parentOrder.bracketStopLossId;

        if (siblingId != null) {
          await _supabase
              .from('orders')
              .update({
                'status': OrderStatus.cancelled.toDbString(),
                'cancelled_at': DateTime.now().toIso8601String(),
                'cancellation_reason': 'Sibling leg cancelled',
              })
              .eq('id', siblingId);
        }
      }
    }

    // Cancel the order
    final response = await _supabase
        .from('orders')
        .update({
          'status': OrderStatus.cancelled.toDbString(),
          'cancelled_at': DateTime.now().toIso8601String(),
          'cancellation_reason': reason ?? 'User requested cancellation',
        })
        .eq('id', orderId)
        .select()
        .single();

    return Order.fromJson(response);
  }

  /// Watch orders in real-time (stream updates)
  Stream<List<Order>> watchOrders({bool activeOnly = false}) {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final query = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId!);

    return query.map((list) {
      final orders = list.map((json) => Order.fromJson(json)).toList();

      if (activeOnly) {
        return orders.where((o) => o.isActive).toList();
      }

      return orders;
    });
  }

  /// Get bracket order with all its legs
  Future<BracketOrderResult?> getBracketOrder(String parentOrderId) async {
    final entryOrder = await getOrderById(parentOrderId);
    if (entryOrder == null || entryOrder.orderType != OrderType.bracket) {
      return null;
    }

    final stopLossOrder = entryOrder.bracketStopLossId != null
        ? await getOrderById(entryOrder.bracketStopLossId!)
        : null;

    final targetOrder = entryOrder.bracketTargetId != null
        ? await getOrderById(entryOrder.bracketTargetId!)
        : null;

    if (stopLossOrder == null || targetOrder == null) {
      return null;
    }

    return BracketOrderResult(
      entryOrder: entryOrder,
      stopLossOrder: stopLossOrder,
      targetOrder: targetOrder,
    );
  }
}

/// Result object for bracket order creation
class BracketOrderResult {
  final Order entryOrder; // The filled entry order
  final Order stopLossOrder; // The pending stop-loss leg
  final Order targetOrder; // The pending take-profit leg

  BracketOrderResult({
    required this.entryOrder,
    required this.stopLossOrder,
    required this.targetOrder,
  });

  /// Check if bracket is still active
  bool get isActive {
    return stopLossOrder.isActive || targetOrder.isActive;
  }

  /// Get which leg was filled (if any)
  Order? get filledLeg {
    if (stopLossOrder.status == OrderStatus.filled) return stopLossOrder;
    if (targetOrder.status == OrderStatus.filled) return targetOrder;
    return null;
  }
}
