import 'dart:math';
import '../models/order.dart';

/// Utility class for calculating and managing trailing stop-loss orders
class TrailingStopLossCalculator {
  /// Calculate the current stop-loss price for a trailing stop-loss order
  ///
  /// For Buy orders: stop-loss = highest_price * (1 - trailingStopPercent/100)
  /// For Sell orders: stop-loss = lowest_price * (1 + trailingStopPercent/100)
  static double calculateCurrentStopLoss(Order order, double currentPrice) {
    if (order.stopLossType != StopLossType.trailing ||
        order.trailingStopPercent == null) {
      throw ArgumentError('Order is not a trailing stop-loss order');
    }

    if (order.orderSide == OrderSide.buy) {
      // For buy orders, use highest price reached
      final highestPrice = max(
        order.highestPrice ?? order.triggerPrice ?? currentPrice,
        currentPrice,
      );
      return highestPrice * (1 - order.trailingStopPercent! / 100);
    } else {
      // For sell orders, use lowest price reached
      final lowestPrice = min(
        order.lowestPrice ?? order.triggerPrice ?? currentPrice,
        currentPrice,
      );
      return lowestPrice * (1 + order.trailingStopPercent! / 100);
    }
  }

  /// Check if a trailing stop-loss order should be triggered
  static bool shouldTrigger(Order order, double currentPrice) {
    if (order.stopLossType != StopLossType.trailing) {
      return false;
    }

    final currentStopLoss = calculateCurrentStopLoss(order, currentPrice);

    if (order.orderSide == OrderSide.buy) {
      // For buy orders, trigger if price <= stop-loss
      return currentPrice <= currentStopLoss;
    } else {
      // For sell orders, trigger if price >= stop-loss
      return currentPrice >= currentStopLoss;
    }
  }

  /// Update highest/lowest prices for a trailing stop-loss order
  /// Returns an updated Order with new highest/lowest prices
  static Order updatePriceExtremes(Order order, double currentPrice) {
    if (order.stopLossType != StopLossType.trailing) {
      return order;
    }

    if (order.orderSide == OrderSide.buy) {
      // For buy orders, update highest price
      final newHighest = max(order.highestPrice ?? currentPrice, currentPrice);
      if (newHighest != order.highestPrice) {
        return order.copyWith(highestPrice: newHighest);
      }
    } else {
      // For sell orders, update lowest price
      final newLowest = min(order.lowestPrice ?? currentPrice, currentPrice);
      if (newLowest != order.lowestPrice) {
        return order.copyWith(lowestPrice: newLowest);
      }
    }

    return order;
  }

  /// Calculate the profit/loss at the current stop-loss level
  static double? calculatePLAtStopLoss(Order order, double currentPrice) {
    if (order.avgFillPrice == null) {
      return null;
    }

    final currentStopLoss = calculateCurrentStopLoss(order, currentPrice);

    if (order.orderSide == OrderSide.buy) {
      return (currentStopLoss - order.avgFillPrice!) * order.quantity;
    } else {
      return (order.avgFillPrice! - currentStopLoss) * order.quantity;
    }
  }

  /// Get a formatted description of the trailing stop-loss
  static String getDescription(Order order, double currentPrice) {
    if (order.stopLossType != StopLossType.trailing ||
        order.trailingStopPercent == null) {
      return 'Invalid trailing stop-loss';
    }

    final currentStopLoss = calculateCurrentStopLoss(order, currentPrice);
    final trailing = order.trailingStopPercent!.toStringAsFixed(2);

    if (order.orderSide == OrderSide.buy) {
      final highest = order.highestPrice ?? currentPrice;
      return 'Trailing SL: $trailing% | '
          'Highest: ₹${highest.toStringAsFixed(2)} | '
          'Current SL: ₹${currentStopLoss.toStringAsFixed(2)}';
    } else {
      final lowest = order.lowestPrice ?? currentPrice;
      return 'Trailing SL: $trailing% | '
          'Lowest: ₹${lowest.toStringAsFixed(2)} | '
          'Current SL: ₹${currentStopLoss.toStringAsFixed(2)}';
    }
  }

  /// Validate trailing stop-loss parameters
  static bool isValidTrailingStop(double trailingStopPercent) {
    return trailingStopPercent > 0 && trailingStopPercent <= 50;
  }

  /// Get validation error message for trailing stop-loss
  static String? getTrailingStopValidationError(double trailingStopPercent) {
    if (trailingStopPercent <= 0) {
      return 'Trailing stop percentage must be greater than 0%';
    }
    if (trailingStopPercent > 50) {
      return 'Trailing stop percentage cannot exceed 50%';
    }
    return null;
  }

  /// Calculate potential loss if trailing stop is triggered
  static double calculateMaxLoss(
    Order order,
    double currentPrice,
    double quantity,
  ) {
    if (order.stopLossType != StopLossType.trailing ||
        order.avgFillPrice == null) {
      return 0;
    }

    final currentStopLoss = calculateCurrentStopLoss(order, currentPrice);

    if (order.orderSide == OrderSide.buy) {
      return (order.avgFillPrice! - currentStopLoss) * quantity;
    } else {
      return (currentStopLoss - order.avgFillPrice!) * quantity;
    }
  }

  /// Get the distance from current price to stop-loss in percentage
  static double getDistanceToStopLoss(Order order, double currentPrice) {
    if (order.stopLossType != StopLossType.trailing) {
      return 0;
    }

    final currentStopLoss = calculateCurrentStopLoss(order, currentPrice);

    if (order.orderSide == OrderSide.buy) {
      if (currentPrice == 0) return 0;
      return ((currentPrice - currentStopLoss) / currentPrice) * 100;
    } else {
      if (currentStopLoss == 0) return 0;
      return ((currentStopLoss - currentPrice) / currentStopLoss) * 100;
    }
  }

  /// Get color recommendation based on distance to stop-loss
  /// Green (safe), Yellow (warning), Red (critical)
  static TrailingStopStatus getStatusFromDistance(double distancePercent) {
    if (distancePercent > 5) {
      return TrailingStopStatus.safe;
    } else if (distancePercent > 2) {
      return TrailingStopStatus.warning;
    } else {
      return TrailingStopStatus.critical;
    }
  }
}

/// Status of a trailing stop-loss order
enum TrailingStopStatus {
  safe, // Distance > 5%
  warning, // Distance between 2-5%
  critical, // Distance < 2%
}

/// Extension for TrailingStopStatus
extension TrailingStopStatusExtension on TrailingStopStatus {
  String get displayName {
    switch (this) {
      case TrailingStopStatus.safe:
        return 'Safe';
      case TrailingStopStatus.warning:
        return 'Warning';
      case TrailingStopStatus.critical:
        return 'Critical';
    }
  }

  String get description {
    switch (this) {
      case TrailingStopStatus.safe:
        return 'Plenty of room before stop-loss triggers';
      case TrailingStopStatus.warning:
        return 'Getting close to stop-loss level';
      case TrailingStopStatus.critical:
        return 'Very close to stop-loss trigger';
    }
  }
}
