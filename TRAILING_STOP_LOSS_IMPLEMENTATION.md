# Trailing Stop-Loss Implementation Guide

## Overview
This document describes the enhanced stop-loss functionality including a new **Trailing Stop-Loss** feature that has been added to the trading system. This feature allows traders to automatically adjust their stop-loss levels as prices move in their favor.

## What is Trailing Stop-Loss?

### Fixed Stop-Loss (Existing)
- **Definition**: A fixed price level that triggers a sell order when reached
- **Use Case**: Set a hard limit on losses
- **Example**: Buy at ₹100, set stop-loss at ₹95 → If price drops to ₹95, sell at market price

### Trailing Stop-Loss (New)
- **Definition**: A dynamic stop-loss that follows the price upward (for buy orders) or downward (for sell orders) by a fixed percentage
- **Use Case**: Lock in profits while allowing the position to grow
- **Example**: Buy at ₹100 with 5% trailing stop-loss → If price rises to ₹120, stop-loss moves up to ₹114 → If price then drops to ₹114, sell at market price

## Data Model Changes

### New Enums Added

```dart
enum StopLossType {
  fixed,    // Traditional fixed stop-loss price
  trailing, // Dynamic trailing stop-loss percentage
}
```

### New Fields Added to Order Model

```dart
class Order {
  // ... existing fields ...
  
  // Trailing stop-loss support
  final StopLossType? stopLossType;      // Type of stop-loss (fixed or trailing)
  final double? trailingStopPercent;     // Trailing stop-loss percentage (e.g., 2.5 for 2.5%)
  final double? highestPrice;            // Highest price reached (used for buy trailing stop-loss)
  final double? lowestPrice;             // Lowest price reached (used for sell trailing stop-loss)
}
```

## Implementation Details

### Trailing Stop-Loss Calculation

#### For Buy Orders (Long Position)
- **Entry Price**: ₹100
- **Trailing Stop %**: 5%
- **Calculation**: Stop-Loss = highestPrice × (1 - trailingStopPercent/100)
- **Example Scenarios**:
  - Price reaches ₹120: Stop-Loss = 120 × 0.95 = ₹114
  - Price reaches ₹130: Stop-Loss = 130 × 0.95 = ₹123.50
  - Price drops to ₹123.50: Order triggers, sells at market price

#### For Sell Orders (Short Position)
- **Entry Price**: ₹100
- **Trailing Stop %**: 5%
- **Calculation**: Stop-Loss = lowestPrice × (1 + trailingStopPercent/100)
- **Example Scenarios**:
  - Price drops to ₹80: Stop-Loss = 80 × 1.05 = ₹84
  - Price drops to ₹70: Stop-Loss = 70 × 1.05 = ₹73.50
  - Price rises to ₹73.50: Order triggers, buys at market price

### Database Fields Required

The following new fields should be added to the `orders` table in Supabase:

```sql
-- Add to orders table
ALTER TABLE orders ADD COLUMN stop_loss_type VARCHAR DEFAULT 'fixed';
ALTER TABLE orders ADD COLUMN trailing_stop_percent DECIMAL(10, 4);
ALTER TABLE orders ADD COLUMN highest_price DECIMAL(20, 8);
ALTER TABLE orders ADD COLUMN lowest_price DECIMAL(20, 8);
```

## Usage in UI

### Creating a Trailing Stop-Loss Order

1. **Toggle between Fixed and Trailing**:
   - Add a radio button group or dropdown to select stop-loss type
   - Show/hide relevant input fields based on selection

2. **Fixed Stop-Loss Form**:
   ```
   [Radio] Fixed Stop-Loss
   Trigger Price: [___________]
   ```

3. **Trailing Stop-Loss Form**:
   ```
   [Radio] Trailing Stop-Loss
   Trailing Stop %: [_____] %
   (Optional) Max Loss Limit: [___________]
   ```

### Order Display

In the Orders screen, display both types:
- **Fixed**: "Fixed SL: ₹95"
- **Trailing**: "Trailing SL: 5% | Current: ₹114"

## Order Processing Logic

### Trigger Conditions

#### Fixed Stop-Loss
```dart
bool isTriggered(double currentPrice, Order order) {
  if (order.stopLossType == StopLossType.fixed) {
    if (order.orderSide == OrderSide.buy) {
      return currentPrice <= order.stopLossPrice!;
    } else {
      return currentPrice >= order.stopLossPrice!;
    }
  }
  return false;
}
```

#### Trailing Stop-Loss
```dart
bool isTriggered(double currentPrice, Order order) {
  if (order.stopLossType == StopLossType.trailing) {
    // Update highest/lowest prices
    if (order.orderSide == OrderSide.buy) {
      double newHighest = max(order.highestPrice ?? currentPrice, currentPrice);
      double calculatedStopLoss = newHighest * (1 - order.trailingStopPercent!/100);
      return currentPrice <= calculatedStopLoss;
    } else {
      double newLowest = min(order.lowestPrice ?? currentPrice, currentPrice);
      double calculatedStopLoss = newLowest * (1 + order.trailingStopPercent!/100);
      return currentPrice >= calculatedStopLoss;
    }
  }
  return false;
}
```

### Price Update Logic

When price updates are received, trailing stop-loss orders must update their highest/lowest prices:

```dart
void updateTrailingStopLoss(Order order, double currentPrice) {
  if (order.stopLossType != StopLossType.trailing) return;
  
  if (order.orderSide == OrderSide.buy) {
    // For buy orders, track the highest price
    order.highestPrice = max(order.highestPrice ?? order.triggerPrice!, currentPrice);
  } else {
    // For sell orders, track the lowest price
    order.lowestPrice = min(order.lowestPrice ?? order.triggerPrice!, currentPrice);
  }
  
  // Save updated order
  await orderRepository.updateOrder(order);
}
```

## Key Advantages

### Fixed Stop-Loss
✅ Simple and straightforward
✅ Clear risk management
✅ Best for protecting against losses
✅ No adjustments needed

### Trailing Stop-Loss
✅ Automatically locks in profits
✅ Reduces manual monitoring
✅ Adapts to market conditions
✅ Balances risk and reward
✅ Perfect for trending markets
✅ Useful for swing trading

## Implementation Checklist

- [x] Add `StopLossType` enum to Order model
- [x] Add trailing stop-loss fields to Order class
- [x] Update fromJson/toJson methods
- [x] Update copyWith method
- [ ] Add database migration for new fields
- [ ] Update OrderRepository.createStopLossOrder() method
- [ ] Add StopLossType toggle UI in trade dialog
- [ ] Add trailing stop percentage input field
- [ ] Implement trailing stop-loss calculation logic
- [ ] Update order display in orders_screen.dart
- [ ] Add unit tests for trailing stop-loss calculation
- [ ] Add integration tests for order triggering

## Example: Creating an Order with Trailing Stop-Loss

```dart
// Create trailing stop-loss order
final order = Order(
  id: 'order-123',
  userId: 'user-456',
  assetSymbol: 'INFY',
  assetName: 'Infosys',
  assetType: AssetType.stock,
  orderType: OrderType.stopLoss,
  orderSide: OrderSide.buy,
  quantity: 10,
  triggerPrice: 100,  // Entry price
  status: OrderStatus.pending,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  stopLossType: StopLossType.trailing,
  trailingStopPercent: 5.0,  // 5% trailing stop
  highestPrice: 100,  // Initial price
);
```

## Advanced Features (Future)

1. **Trailing Stop with Breakeven**: Automatically move stop to entry price after reaching certain profit level
2. **Step Trailing Stop**: Adjust trailing percentage based on profit levels
3. **Alerts**: Notify user when stop-loss level changes
4. **Analytics**: Track stop-loss accuracy and effectiveness
5. **Backtesting**: Test trading strategies with different trailing percentages

## Troubleshooting

### Common Issues

1. **Stop-Loss not triggering**:
   - Check if trailing stop percentage is too high
   - Verify price data is updating correctly
   - Ensure order status is still "pending"

2. **Missing highest/lowest price**:
   - Initialize with entry price on order creation
   - Always update before checking trigger condition

3. **Database migration issues**:
   - Ensure all existing orders have default values
   - Run migration on all environments

## Related Files

- `lib/core/models/order.dart` - Order model with trailing stop-loss support
- `lib/screens/stock_detail_screen.dart` - Trade dialog (needs UI updates)
- `lib/core/repositories/order_repository.dart` - Order repository (needs logic updates)
- `lib/screens/orders_screen.dart` - Orders display (needs display updates)

## References

- [Investopedia: Trailing Stop-Loss](https://www.investopedia.com/terms/t/trailingstop.asp)
- [Forex Trading: Trailing Stop-Loss Strategies](https://example.com)
