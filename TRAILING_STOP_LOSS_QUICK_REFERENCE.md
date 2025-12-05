# Trailing Stop-Loss Quick Reference

## 📌 One-Liner Definition
**Trailing Stop-Loss**: A dynamic stop-loss that automatically adjusts upward (for buys) or downward (for sells) by a fixed percentage as the price moves in your favor.

---

## 🎯 Quick Examples

### Example 1: Buy Order
```
Buy 100 shares at ₹100 with 5% trailing stop
├─ Stop-Loss = 100 × (1 - 0.05) = ₹95
│
├─ Price rises to ₹150
│  └─ Stop-Loss = 150 × (1 - 0.05) = ₹142.50 ✨ (Updated!)
│
└─ Price drops to ₹142.50
   └─ 🛑 ORDER TRIGGERED - Sell executed at market price
```

### Example 2: Sell Order  
```
Sell 100 shares at ₹100 with 5% trailing stop
├─ Stop-Loss = 100 × (1 + 0.05) = ₹105
│
├─ Price falls to ₹50
│  └─ Stop-Loss = 50 × (1 + 0.05) = ₹52.50 ✨ (Updated!)
│
└─ Price rises to ₹52.50
   └─ 🛑 ORDER TRIGGERED - Buy executed at market price
```

---

## 📚 API Quick Reference

### Create Trailing Stop-Loss Order
```dart
final order = Order(
  id: 'order-123',
  userId: 'user-456',
  assetSymbol: 'INFY',
  assetName: 'Infosys',
  assetType: AssetType.stock,
  orderType: OrderType.stopLoss,
  orderSide: OrderSide.buy,
  quantity: 100,
  triggerPrice: 1500,      // Entry price
  status: OrderStatus.pending,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  stopLossType: StopLossType.trailing,
  trailingStopPercent: 5.0,   // 5% trailing
  highestPrice: 1500,         // Initialize with entry
);
```

### Calculate Current Stop-Loss Price
```dart
import 'package:virtual_trading_app/core/utils/trailing_stop_loss_calculator.dart';

final currentPrice = 1750.0;
final stopLossPrice = TrailingStopLossCalculator
  .calculateCurrentStopLoss(order, currentPrice);
print('Current SL: ₹$stopLossPrice');  // Prints: Current SL: ₹1662.5
```

### Check if Order Should Trigger
```dart
final shouldExecute = TrailingStopLossCalculator
  .shouldTrigger(order, currentPrice);

if (shouldExecute) {
  await executeOrder(order);
}
```

### Update Price Extremes
```dart
final updatedOrder = TrailingStopLossCalculator
  .updatePriceExtremes(order, newPrice);

// Save updated order to database
await saveOrder(updatedOrder);
```

### Get Distance to Stop-Loss
```dart
final distancePercent = TrailingStopLossCalculator
  .getDistanceToStopLoss(order, currentPrice);
print('Distance: ${distancePercent.toStringAsFixed(2)}%');

final status = TrailingStopLossCalculator
  .getStatusFromDistance(distancePercent);
// Returns: TrailingStopStatus.safe | .warning | .critical
```

---

## 🔧 Integration Checklist

- [ ] **1. Database Migration**
  ```sql
  ALTER TABLE orders ADD COLUMN stop_loss_type VARCHAR(20);
  ALTER TABLE orders ADD COLUMN trailing_stop_percent DECIMAL(10, 4);
  ALTER TABLE orders ADD COLUMN highest_price DECIMAL(20, 8);
  ALTER TABLE orders ADD COLUMN lowest_price DECIMAL(20, 8);
  ```

- [ ] **2. Model Setup** ✅
  - Order model updated with new fields
  - FromJson/ToJson methods updated
  - CopyWith method updated

- [ ] **3. Calculator Setup** ✅
  - `TrailingStopLossCalculator` created
  - All functions implemented
  - Validation logic added

- [ ] **4. UI Implementation**
  - Add toggle for Fixed vs Trailing SL in trade dialog
  - Add trailing stop % input field
  - Add validation error messages
  - Update orders display with trailing info

- [ ] **5. Order Processing**
  - Create trailing stops via `OrderRepository`
  - Process price updates and track extremes
  - Check trigger conditions
  - Execute when triggered

- [ ] **6. Testing**
  - Unit tests for calculator functions
  - Integration tests for order lifecycle
  - Manual testing with real data

---

## 📊 Calculation Formula

### For Buy Orders
```
Stop-Loss Price = Highest Price × (1 - TrailingStop% / 100)

Example: 5% trailing stop
- Entry: ₹100, Highest: ₹100, SL = 100 × 0.95 = ₹95
- Price rises to ₹150: SL = 150 × 0.95 = ₹142.50
- Price rises to ₹200: SL = 200 × 0.95 = ₹190
```

### For Sell Orders
```
Stop-Loss Price = Lowest Price × (1 + TrailingStop% / 100)

Example: 5% trailing stop  
- Entry: ₹100, Lowest: ₹100, SL = 100 × 1.05 = ₹105
- Price falls to ₹80: SL = 80 × 1.05 = ₹84
- Price falls to ₹50: SL = 50 × 1.05 = ₹52.50
```

---

## ⚠️ Important Notes

1. **Always Initialize Highest/Lowest**
   ```dart
   highestPrice: entryPrice ?? currentPrice,
   lowestPrice: entryPrice ?? currentPrice,
   ```

2. **Valid Percentage Range**: 0.1% to 50%
   ```dart
   if (!TrailingStopLossCalculator.isValidTrailingStop(5.0)) {
     throw Exception('Invalid percentage');
   }
   ```

3. **Price Updates Are Critical**
   - Without updating highest/lowest, trailing stop won't work
   - Update on every price change
   - Save to database after updates

4. **Database Backward Compatibility**
   - Existing orders default to `stopLossType = 'fixed'`
   - No changes needed to existing data
   - Safe to add gradually

---

## 🎓 Use Case Recommendations

| Strategy | Trailing % | Best For |
|----------|-----------|----------|
| Conservative | 10-15% | Long-term investors |
| Moderate | 5-8% | Swing traders |
| Aggressive | 2-3% | Day traders |
| High Volatility | 15-20% | Volatile assets |

---

## 🚀 Common Code Patterns

### Pattern 1: Create and Save
```dart
final order = Order(
  /* ... standard fields ... */
  stopLossType: StopLossType.trailing,
  trailingStopPercent: 5.0,
  highestPrice: entryPrice,
);
await ordersCollection.add(order.toJson());
```

### Pattern 2: Monitor and Update
```dart
onPriceUpdate: (symbol, newPrice) async {
  final orders = await fetchActiveTrailingOrders(symbol);
  
  for (var order in orders) {
    final updated = TrailingStopLossCalculator
      .updatePriceExtremes(order, newPrice);
    
    if (updated != order) {
      await ordersCollection.doc(order.id).update(updated.toJson());
    }
  }
}
```

### Pattern 3: Check and Execute
```dart
final shouldTrigger = TrailingStopLossCalculator
  .shouldTrigger(order, marketPrice);

if (shouldTrigger) {
  final executedOrder = await executeMarketOrder(order);
  await ordersCollection.doc(order.id).update(executedOrder.toJson());
}
```

---

## 📖 Documentation Files

| File | Purpose |
|------|---------|
| `TRAILING_STOP_LOSS_SUMMARY.md` | This file - Quick reference |
| `TRAILING_STOP_LOSS_IMPLEMENTATION.md` | Complete technical docs |
| `TRAILING_STOP_LOSS_INTEGRATION.md` | Step-by-step integration |
| `trailing_stop_loss_calculator.dart` | Implementation code |

---

## ✅ Status

**Implementation Status**: 🟢 **COMPLETE**
- ✅ Order model updated
- ✅ Calculator utility created
- ✅ Full documentation provided
- ⏳ Database migration needed
- ⏳ UI integration needed
- ⏳ Order processing logic needed

---

## 🔗 Related Files

- `lib/core/models/order.dart` - Order model with trailing stop support
- `lib/core/utils/trailing_stop_loss_calculator.dart` - Calculator functions
- `lib/screens/stock_detail_screen.dart` - Trade dialog (needs update)
- `lib/screens/orders_screen.dart` - Orders display (needs update)
- `lib/core/repositories/order_repository.dart` - Order creation (needs update)

---

**Last Updated**: December 5, 2025
**Version**: 1.0
**Status**: Ready for Integration
