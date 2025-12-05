# Trailing Stop-Loss Integration Guide

## Quick Start

### 1. Basic Usage in OrderRepository

```dart
// Creating a trailing stop-loss order
Future<Order> createTrailingStopLossOrder({
  required String assetSymbol,
  required String assetName,
  required AssetType assetType,
  required OrderSide orderSide,
  required double quantity,
  required double entryPrice,
  required double trailingStopPercent,
}) async {
  // Validate
  if (!TrailingStopLossCalculator.isValidTrailingStop(trailingStopPercent)) {
    throw Exception('Invalid trailing stop percentage');
  }

  final order = Order(
    id: const Uuid().v4(),
    userId: currentUserId,
    assetSymbol: assetSymbol,
    assetName: assetName,
    assetType: assetType,
    orderType: OrderType.stopLoss,
    orderSide: orderSide,
    quantity: quantity,
    triggerPrice: entryPrice,
    status: OrderStatus.pending,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    stopLossType: StopLossType.trailing,
    trailingStopPercent: trailingStopPercent,
    highestPrice: entryPrice,  // Initialize with entry price
    lowestPrice: entryPrice,   // Initialize with entry price
  );

  // Save to Supabase
  await supabase.from('orders').insert(order.toJson());
  return order;
}
```

### 2. Monitoring Price Updates

```dart
// When price updates arrive from real-time service
void onPriceUpdate(String symbol, double newPrice) {
  final activeOrders = _getActiveTrailingStopOrders(symbol);
  
  for (var order in activeOrders) {
    // Update price extremes
    final updatedOrder = TrailingStopLossCalculator.updatePriceExtremes(order, newPrice);
    
    // Check if should trigger
    if (TrailingStopLossCalculator.shouldTrigger(updatedOrder, newPrice)) {
      _triggerOrder(updatedOrder);
    } else if (updatedOrder != order) {
      // Save updated price extremes
      _updateOrder(updatedOrder);
    }
  }
}
```

### 3. UI Integration in Trade Dialog

```dart
// Add this to the trade dialog state
bool _useTrailingStop = false;
TextEditingController _trailingStopPercentController = TextEditingController();

// In build method, add radio/toggle for stop-loss type
Row(
  children: [
    Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _useTrailingStop = false),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: !_useTrailingStop 
              ? Colors.orange.withAlpha((0.3 * 255).round())
              : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: !_useTrailingStop ? Colors.orange : Colors.grey,
            ),
          ),
          child: const Text('Fixed SL'),
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _useTrailingStop = true),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _useTrailingStop 
              ? Colors.orange.withAlpha((0.3 * 255).round())
              : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _useTrailingStop ? Colors.orange : Colors.grey,
            ),
          ),
          child: const Text('Trailing SL'),
        ),
      ),
    ),
  ],
)

// Show appropriate input based on selection
if (!_useTrailingStop)
  _buildPriceInput('Trigger Price', _triggerPriceController, currentPrice, Colors.orange)
else
  _buildPercentInput('Trailing Stop %', _trailingStopPercentController, Colors.orange)
```

### 4. Order Display in Orders Screen

```dart
// In _buildOrderCard method
if (order.orderType == OrderType.stopLoss) {
  if (order.stopLossType == StopLossType.trailing) {
    // Display trailing stop-loss info
    final desc = TrailingStopLossCalculator.getDescription(order, currentPrice);
    
    _buildDetailRow(
      'Stop-Loss Type',
      'Trailing (${order.trailingStopPercent?.toStringAsFixed(2)}%)',
    );
    _buildDetailRow('Details', desc);
    
    // Show status indicator
    final distance = TrailingStopLossCalculator.getDistanceToStopLoss(order, currentPrice);
    final status = TrailingStopLossCalculator.getStatusFromDistance(distance);
    
    _buildDetailRow(
      'Status',
      status.displayName,
      valueColor: _getStatusColor(status),
    );
  } else {
    // Display fixed stop-loss (existing code)
    _buildDetailRow(
      'Stop-Loss',
      'Fixed at ₹${order.stopLossPrice?.toStringAsFixed(2)}',
    );
  }
}
```

### 5. Real-time Notification System

```dart
// Optional: Add notifications when trailing stop-loss updates
void _onTrailingStopUpdate(Order order, double newHighest) {
  final currentSL = TrailingStopLossCalculator.calculateCurrentStopLoss(order, newHighest);
  
  // Show notification
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Trailing SL Updated for ${order.assetSymbol}\n'
        'New Stop-Loss: ₹${currentSL.toStringAsFixed(2)}',
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
```

## Database Setup

### SQL Migration

```sql
-- Add columns to existing orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS stop_loss_type VARCHAR(20) DEFAULT 'fixed';
ALTER TABLE orders ADD COLUMN IF NOT EXISTS trailing_stop_percent DECIMAL(10, 4);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS highest_price DECIMAL(20, 8);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS lowest_price DECIMAL(20, 8);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_orders_trailing_stop 
ON orders(user_id, asset_symbol) 
WHERE stop_loss_type = 'trailing' AND status = 'pending';
```

### RLS Policies (if using Supabase)

```sql
-- Policy for reading trailing stop-loss orders
CREATE POLICY "Users can view their trailing stop orders"
ON orders FOR SELECT
USING (
  auth.uid() = user_id AND stop_loss_type = 'trailing'
);

-- Policy for updating trailing stop-loss prices
CREATE POLICY "System can update trailing stop extremes"
ON orders FOR UPDATE
USING (
  auth.uid() = user_id AND stop_loss_type = 'trailing'
)
WITH CHECK (
  auth.uid() = user_id AND stop_loss_type = 'trailing'
);
```

## Testing Checklist

### Unit Tests
- [ ] Test trailing stop calculation for buy orders
- [ ] Test trailing stop calculation for sell orders
- [ ] Test stop-loss trigger condition (buy)
- [ ] Test stop-loss trigger condition (sell)
- [ ] Test price extreme updates
- [ ] Test validation functions
- [ ] Test distance to stop-loss calculation
- [ ] Test status determination

### Integration Tests
- [ ] Create trailing stop order through UI
- [ ] Update order when price changes
- [ ] Trigger order when stop-loss reached
- [ ] Display updated stop-loss in orders list
- [ ] Save order to database correctly
- [ ] Retrieve trailing stop orders from database

### Manual Testing
- [ ] Buy order with trailing stop (5% test)
- [ ] Sell order with trailing stop (5% test)
- [ ] Price increases - verify stop-loss follows
- [ ] Price decreases after increase - verify trigger
- [ ] Check real-time updates work
- [ ] Verify database records correctly

## Performance Considerations

### Optimization Tips

1. **Batch Updates**: Process multiple price updates in batch
```dart
// Instead of updating one by one
for (var order in orders) {
  updateOrder(order);
}

// Process in batch
final updated = orders.map((o) => 
  TrailingStopLossCalculator.updatePriceExtremes(o, newPrice)
).toList();
await batchUpdateOrders(updated);
```

2. **Efficient Queries**: Use indexes on frequently queried columns
```dart
// Query only active trailing stop orders
final activeTrailingOrders = await supabase
  .from('orders')
  .select()
  .eq('user_id', userId)
  .eq('stop_loss_type', 'trailing')
  .eq('status', 'pending');
```

3. **Caching**: Cache calculated stop-loss levels
```dart
final Map<String, double> _stopLossCache = {};

double getCachedStopLoss(Order order, double price) {
  final key = '${order.id}_$price';
  return _stopLossCache[key] ??= 
    TrailingStopLossCalculator.calculateCurrentStopLoss(order, price);
}
```

## Common Issues and Solutions

### Issue 1: Stop-Loss not updating
**Solution**: Ensure highest/lowest prices are initialized on order creation
```dart
highestPrice: entryPrice ?? currentPrice,
lowestPrice: entryPrice ?? currentPrice,
```

### Issue 2: Stop-Loss calculation seems wrong
**Solution**: Check that you're using correct formula for order side
- Buy: SL = highest × (1 - percent/100)
- Sell: SL = lowest × (1 + percent/100)

### Issue 3: Database migration failed
**Solution**: Check if columns already exist with ALTER TABLE IF NOT EXISTS

### Issue 4: Trailing stop not triggering
**Solution**: Verify order status is still "pending" and use correct price

## Next Steps

1. Add trailing stop-loss type selection to trade dialog
2. Implement price update logic in real-time price service
3. Add database migration for new fields
4. Update orders display to show trailing stop info
5. Add notification system for stop-loss updates
6. Create comprehensive tests
7. Monitor in production for edge cases

## References

- `lib/core/models/order.dart` - Order model
- `lib/core/utils/trailing_stop_loss_calculator.dart` - Calculator utility
- `TRAILING_STOP_LOSS_IMPLEMENTATION.md` - Full documentation
