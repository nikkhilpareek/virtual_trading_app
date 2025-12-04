import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_event.dart';
import 'order_state.dart';
import '../../repositories/order_repository.dart';

/// BLoC for managing orders (stop-loss, bracket, etc.)
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _orderRepository;
  StreamSubscription? _ordersSubscription;

  OrderBloc({OrderRepository? orderRepository})
    : _orderRepository = orderRepository ?? OrderRepository(),
      super(const OrderInitial()) {
    // Register event handlers
    on<LoadPendingOrders>(_onLoadPendingOrders);
    on<LoadOrderHistory>(_onLoadOrderHistory);
    on<CreateStopLossOrder>(_onCreateStopLossOrder);
    on<CreateBracketOrder>(_onCreateBracketOrder);
    on<CancelOrder>(_onCancelOrder);
    on<GetOrderById>(_onGetOrderById);
    on<GetBracketOrder>(_onGetBracketOrder);
    on<RefreshOrders>(_onRefreshOrders);
    on<OrderTriggered>(_onOrderTriggered);
    on<FilterOrdersByType>(_onFilterOrdersByType);
    on<FilterOrdersByStatus>(_onFilterOrdersByStatus);
    on<FilterOrdersByAsset>(_onFilterOrdersByAsset);
  }

  /// Load pending orders
  Future<void> _onLoadPendingOrders(
    LoadPendingOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading(message: 'Loading pending orders...'));

    try {
      final orders = await _orderRepository.getPendingOrders();

      if (orders.isEmpty) {
        emit(const OrderEmpty(message: 'No pending orders'));
      } else {
        emit(PendingOrdersLoaded(orders: orders, lastUpdated: DateTime.now()));
      }
    } catch (e) {
      emit(OrderError(message: 'Failed to load pending orders', error: e));
    }
  }

  /// Load order history
  Future<void> _onLoadOrderHistory(
    LoadOrderHistory event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading(message: 'Loading order history...'));

    try {
      final orders = await _orderRepository.getOrderHistory(limit: event.limit);

      if (orders.isEmpty) {
        emit(const OrderEmpty(message: 'No order history'));
      } else {
        emit(OrderHistoryLoaded(orders: orders, lastUpdated: DateTime.now()));
      }
    } catch (e) {
      emit(OrderError(message: 'Failed to load order history', error: e));
    }
  }

  /// Create stop-loss order
  Future<void> _onCreateStopLossOrder(
    CreateStopLossOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(const CreatingStopLossOrder());

    try {
      final order = await _orderRepository.createStopLossOrder(
        assetSymbol: event.assetSymbol,
        assetName: event.assetName,
        assetType: event.assetType,
        orderSide: event.orderSide,
        quantity: event.quantity,
        triggerPrice: event.triggerPrice,
        limitPrice: event.limitPrice,
        notes: event.notes,
      );

      emit(StopLossOrderCreated(order));

      // Reload pending orders
      add(const LoadPendingOrders());
    } catch (e) {
      emit(
        OrderError(
          message: 'Failed to create stop-loss order: ${e.toString()}',
          error: e,
        ),
      );
    }
  }

  /// Create bracket order
  Future<void> _onCreateBracketOrder(
    CreateBracketOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(const CreatingBracketOrder());

    try {
      final bracketOrder = await _orderRepository.createBracketOrder(
        assetSymbol: event.assetSymbol,
        assetName: event.assetName,
        assetType: event.assetType,
        orderSide: event.orderSide,
        quantity: event.quantity,
        entryPrice: event.entryPrice,
        stopLossPrice: event.stopLossPrice,
        targetPrice: event.targetPrice,
        notes: event.notes,
      );

      emit(BracketOrderCreated(bracketOrder));

      // Reload pending orders
      add(const LoadPendingOrders());
    } catch (e) {
      emit(
        OrderError(
          message: 'Failed to create bracket order: ${e.toString()}',
          error: e,
        ),
      );
    }
  }

  /// Cancel an order
  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(CancellingOrder(event.orderId));

    try {
      final order = await _orderRepository.cancelOrder(
        event.orderId,
        reason: event.reason,
      );

      emit(OrderCancelled(order));

      // Reload pending orders
      add(const LoadPendingOrders());
    } catch (e) {
      emit(
        OrderError(
          message: 'Failed to cancel order: ${e.toString()}',
          error: e,
        ),
      );
    }
  }

  /// Get order by ID
  Future<void> _onGetOrderById(
    GetOrderById event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading(message: 'Loading order...'));

    try {
      final order = await _orderRepository.getOrderById(event.orderId);

      if (order == null) {
        emit(const OrderError(message: 'Order not found'));
      } else {
        emit(SingleOrderLoaded(order));
      }
    } catch (e) {
      emit(OrderError(message: 'Failed to load order', error: e));
    }
  }

  /// Get bracket order with all legs
  Future<void> _onGetBracketOrder(
    GetBracketOrder event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading(message: 'Loading bracket order...'));

    try {
      final bracketOrder = await _orderRepository.getBracketOrder(
        event.parentOrderId,
      );

      if (bracketOrder == null) {
        emit(const OrderError(message: 'Bracket order not found'));
      } else {
        emit(BracketOrderLoaded(bracketOrder));
      }
    } catch (e) {
      emit(OrderError(message: 'Failed to load bracket order', error: e));
    }
  }

  /// Refresh all orders
  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrderState> emit,
  ) async {
    emit(const OrderLoading(message: 'Refreshing orders...'));

    try {
      final pending = await _orderRepository.getPendingOrders();
      final history = await _orderRepository.getOrderHistory();

      emit(
        AllOrdersLoaded(
          pendingOrders: pending,
          historyOrders: history,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      emit(OrderError(message: 'Failed to refresh orders', error: e));
    }
  }

  /// Handle order triggered notification
  void _onOrderTriggered(OrderTriggered event, Emitter<OrderState> emit) {
    emit(
      OrderTriggeredState(
        order: event.order,
        message: 'Order ${event.order.assetSymbol} has been triggered!',
      ),
    );

    // Reload orders after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      add(const RefreshOrders());
    });
  }

  /// Filter orders by type
  void _onFilterOrdersByType(
    FilterOrdersByType event,
    Emitter<OrderState> emit,
  ) {
    if (state is AllOrdersLoaded) {
      final currentState = state as AllOrdersLoaded;
      emit(currentState.copyWithFilters(filterType: event.orderType));
    }
  }

  /// Filter orders by status
  void _onFilterOrdersByStatus(
    FilterOrdersByStatus event,
    Emitter<OrderState> emit,
  ) {
    if (state is AllOrdersLoaded) {
      final currentState = state as AllOrdersLoaded;
      emit(currentState.copyWithFilters(filterStatus: event.status));
    }
  }

  /// Filter orders by asset
  void _onFilterOrdersByAsset(
    FilterOrdersByAsset event,
    Emitter<OrderState> emit,
  ) {
    if (state is AllOrdersLoaded) {
      final currentState = state as AllOrdersLoaded;
      emit(currentState.copyWithFilters(filterAsset: event.assetSymbol));
    }
  }

  /// Start watching orders in real-time
  void startWatchingOrders({bool activeOnly = false}) {
    _ordersSubscription?.cancel();
    _ordersSubscription = _orderRepository
        .watchOrders(activeOnly: activeOnly)
        .listen((orders) {
          // Refresh orders when stream updates
          add(const RefreshOrders());
        });
  }

  /// Stop watching orders
  void stopWatchingOrders() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
  }

  @override
  Future<void> close() {
    stopWatchingOrders();
    return super.close();
  }
}
