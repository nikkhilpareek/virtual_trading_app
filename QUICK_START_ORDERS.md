# 🚀 Quick Start: Stop-Loss & Bracket Orders

## 3-Step Setup (5 minutes)

### Step 1: Database Setup (2 min)

1. Open [Supabase Dashboard](https://app.supabase.com)
2. Navigate to **SQL Editor**
3. Copy entire content of `database/orders_table.sql`
4. Paste and click **RUN**
5. ✅ Verify: Run `SELECT COUNT(*) FROM orders;` (should return 0)

### Step 2: Backend Setup (2 min)

```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Start server (order monitor auto-starts)
./start.sh
```

✅ **Verify:** Console shows:
```
🚀 Starting Order Monitor Service...
🔍 Order Monitor Service started
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Step 3: Flutter Setup (1 min)

```bash
# Install uuid package
flutter pub add uuid

# Get dependencies
flutter pub get

# Run app
flutter run
```

---

## 📱 Usage Examples

### Example 1: Stop-Loss Order (Protect Holdings)

**Scenario:** You bought 10 RELIANCE shares at ₹2500. Set stop-loss at ₹2450 to limit loss to ₹500.

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/blocs/blocs.dart';
import 'core/models/order.dart';
import 'core/models/asset_type.dart';

// In your trade screen widget
void createStopLoss() {
  context.read<OrderBloc>().add(
    CreateStopLossOrder(
      assetSymbol: 'RELIANCE',
      assetName: 'Reliance Industries',
      assetType: AssetType.stock,
      orderSide: OrderSide.sell,      // Sell to exit
      quantity: 10,
      triggerPrice: 2450.0,           // Trigger at ₹2450
      notes: 'Protect 10 RELIANCE shares',
    ),
  );
}

// Listen for result
BlocListener<OrderBloc, OrderState>(
  listener: (context, state) {
    if (state is StopLossOrderCreated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Stop-loss order created'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is OrderError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${state.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  child: YourWidget(),
);
```

**What Happens:**
1. Order created with status `pending`
2. Backend monitors RELIANCE price every 5 seconds
3. When price ≤ ₹2450, order triggers
4. 10 shares sold automatically at market price
5. You get notification (if implemented)

---

### Example 2: Bracket Order (Entry + Risk Management)

**Scenario:** Buy 0.01 BTC at ₹75L with stop-loss at ₹70L and target at ₹85L.

```dart
void createBracketOrder() {
  context.read<OrderBloc>().add(
    CreateBracketOrder(
      assetSymbol: 'BTC',
      assetName: 'Bitcoin',
      assetType: AssetType.crypto,
      orderSide: OrderSide.buy,
      quantity: 0.01,                 // 0.01 BTC
      entryPrice: 7500000.0,          // ₹75L (current price)
      stopLossPrice: 7000000.0,       // ₹70L (max loss: ₹50k)
      targetPrice: 8500000.0,         // ₹85L (profit: ₹1L)
      notes: 'BTC bracket - 1:2 risk/reward',
    ),
  );
}

// Listen for bracket creation
BlocListener<OrderBloc, OrderState>(
  listener: (context, state) {
    if (state is BracketOrderCreated) {
      final bracket = state.bracketOrder;
      
      print('Entry Order: ${bracket.entryOrder.status}');      // filled
      print('Stop-Loss: ${bracket.stopLossOrder.status}');     // pending
      print('Target: ${bracket.targetOrder.status}');          // pending
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Bracket order created!\n'
            'Entry filled at ₹${bracket.entryOrder.avgFillPrice}\n'
            'Stop-loss: ₹${bracket.stopLossOrder.stopLossPrice}\n'
            'Target: ₹${bracket.targetOrder.targetPrice}',
          ),
        ),
      );
    }
  },
  child: YourWidget(),
);
```

**What Happens:**
1. **Entry order** executes immediately:
   - 0.01 BTC bought at ₹75L
   - Balance deducted: ₹75,000
   - Holding created/updated
2. **Stop-loss order** created (pending):
   - Sell 0.01 BTC if price ≤ ₹70L
   - Monitors every 5 seconds
3. **Target order** created (pending):
   - Sell 0.01 BTC if price ≥ ₹85L
   - Also monitors every 5 seconds
4. **Auto-cancellation:**
   - If stop-loss fills → target cancelled
   - If target fills → stop-loss cancelled

---

## 📊 Monitoring Orders

### Load Pending Orders

```dart
// In initState or button press
@override
void initState() {
  super.initState();
  context.read<OrderBloc>().add(const LoadPendingOrders());
}

// Display orders
BlocBuilder<OrderBloc, OrderState>(
  builder: (context, state) {
    if (state is PendingOrdersLoaded) {
      return ListView.builder(
        itemCount: state.orders.length,
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return ListTile(
            title: Text('${order.assetSymbol} - ${order.orderType.displayName}'),
            subtitle: Text(
              '${order.orderSide.displayName} ${order.quantity} @ ₹${order.triggerPrice}',
            ),
            trailing: Chip(
              label: Text(order.status.displayName),
              backgroundColor: _getStatusColor(order.status),
            ),
          );
        },
      );
    }
    
    if (state is OrderEmpty) {
      return Center(child: Text('No pending orders'));
    }
    
    return CircularProgressIndicator();
  },
);

Color _getStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Colors.orange;
    case OrderStatus.triggered:
      return Colors.blue;
    case OrderStatus.filled:
      return Colors.green;
    case OrderStatus.cancelled:
      return Colors.grey;
    default:
      return Colors.red;
  }
}
```

### Real-Time Order Updates

```dart
// Start watching for real-time updates
@override
void initState() {
  super.initState();
  final orderBloc = context.read<OrderBloc>();
  orderBloc.startWatchingOrders(activeOnly: true);
}

@override
void dispose() {
  context.read<OrderBloc>().stopWatchingOrders();
  super.dispose();
}

// BLoC automatically emits new state when orders change
```

---

## 🎯 Cancel Order

```dart
void cancelOrder(String orderId) {
  context.read<OrderBloc>().add(
    CancelOrder(
      orderId: orderId,
      reason: 'User cancelled',
    ),
  );
}

// UI Example
IconButton(
  icon: Icon(Icons.cancel),
  onPressed: () => cancelOrder(order.id),
);

// Listen for cancellation
BlocListener<OrderBloc, OrderState>(
  listener: (context, state) {
    if (state is OrderCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order cancelled. Balance refunded.')),
      );
      // Reload orders
      context.read<OrderBloc>().add(const LoadPendingOrders());
    }
  },
  child: YourWidget(),
);
```

**What Gets Refunded:**
- Buy orders: `reserved_balance` returned to user balance
- Sell orders: No refund (holdings not locked)

---

## 🧪 Testing Your Implementation

### Test 1: Stop-Loss Execution

```dart
// 1. Create a stop-loss order
context.read<OrderBloc>().add(
  CreateStopLossOrder(
    assetSymbol: 'TCS',
    assetName: 'TCS Limited',
    assetType: AssetType.stock,
    orderSide: OrderSide.sell,
    quantity: 5,
    triggerPrice: 3500.0,  // Set below current price
  ),
);

// 2. Check backend logs (should see):
// 📊 Checking 1 pending orders...
// 💰 TCS: ₹3520.00
// (waiting for price to drop...)

// 3. When price drops to ≤3500:
// 🎯 TRIGGER: Order abc123...
// ⚡ Executing sell order: 5 x TCS @ ₹3500
// ✅ Sell order executed: 5 x TCS @ ₹3500
// 🔗 Cancelled sibling bracket order: ... (if bracket)

// 4. Check in app:
// - Order status changed to 'filled'
// - Transaction created
// - Holding reduced
// - Balance increased
```

### Test 2: Bracket Order Lifecycle

```dart
// 1. Create bracket order
context.read<OrderBloc>().add(
  CreateBracketOrder(
    assetSymbol: 'ETH',
    assetName: 'Ethereum',
    assetType: AssetType.crypto,
    orderSide: OrderSide.buy,
    quantity: 0.1,
    entryPrice: 200000.0,      // ₹2L
    stopLossPrice: 180000.0,   // ₹1.8L (-10%)
    targetPrice: 240000.0,     // ₹2.4L (+20%)
  ),
);

// 2. Immediately after creation:
// - Entry order: status = 'filled'
// - Stop-loss: status = 'pending'
// - Target: status = 'pending'
// - Holding: 0.1 ETH added
// - Balance: ₹20,000 deducted

// 3. Backend starts monitoring both legs:
// 📊 Checking 2 pending orders...
// 💰 ETH: ₹205000.00
// (no trigger yet)

// 4a. If price rises to ≥₹2.4L (target hit):
// 🎯 TRIGGER: Order target-id...
// ⚡ Executing sell order: 0.1 x ETH @ ₹240000
// ✅ Sell order executed
// 🔗 Cancelled sibling: stop-loss-id
// Result: +₹4000 profit (₹24k - ₹20k)

// 4b. If price drops to ≤₹1.8L (stop-loss hit):
// 🎯 TRIGGER: Order stop-loss-id...
// ⚡ Executing sell order: 0.1 x ETH @ ₹180000
// ✅ Sell order executed
// 🔗 Cancelled sibling: target-id
// Result: -₹2000 loss (₹18k - ₹20k)
```

---

## 🔍 Debugging Tips

### Check Backend Status

```bash
# See if backend is running
curl http://localhost:8000/

# Response should be:
# {"message":"Stonks Trading API","version":"2.0.0",...}

# Check logs
tail -f backend/nohup.out  # If running in background
```

### Check Database

```sql
-- See all orders
SELECT 
    id, 
    asset_symbol, 
    order_type, 
    order_side, 
    status, 
    trigger_price, 
    created_at
FROM orders 
ORDER BY created_at DESC 
LIMIT 10;

-- See pending orders only
SELECT * FROM orders WHERE status = 'pending';

-- See bracket order with legs
SELECT 
    e.id as entry_id,
    e.asset_symbol,
    e.status as entry_status,
    sl.id as stop_loss_id,
    sl.status as sl_status,
    sl.stop_loss_price,
    tg.id as target_id,
    tg.status as tg_status,
    tg.target_price
FROM orders e
LEFT JOIN orders sl ON sl.id = e.bracket_stop_loss_id
LEFT JOIN orders tg ON tg.id = e.bracket_target_id
WHERE e.order_type = 'bracket';
```

### Common Issues

**"Order not triggering"**
- Check backend logs for price checks
- Verify trigger price is correct direction
- Ensure asset symbol is valid (RELIANCE.NS, BTC-INR)

**"Insufficient balance"**
- Check if balance was reserved: `SELECT reserved_balance FROM orders WHERE id = '...'`
- Cancel other pending buy orders to free balance

**"App not showing orders"**
- Verify OrderBloc is in main.dart providers
- Check Supabase RLS policies allow SELECT
- Test query: `SELECT * FROM orders WHERE user_id = 'your-uuid'`

---

## 📚 Next Steps

1. **Build UI:**
   - Create `OrdersScreen` to display orders
   - Add order type selector to trade dialogs
   - Show risk/reward calculator for brackets

2. **Add Notifications:**
   - Install `flutter_local_notifications`
   - Notify when orders trigger/fill
   - Background notification support

3. **Enhance Features:**
   - Trailing stop-loss (adjusts with profit)
   - Good-till-cancelled (GTC) orders
   - Time-based expiry
   - Partial fills

4. **Production Readiness:**
   - Add comprehensive error handling
   - Implement retry logic
   - Add monitoring/alerting
   - Scale backend with Redis queue

---

## 🎉 Success!

You now have:
- ✅ Stop-loss orders working
- ✅ Bracket orders working
- ✅ Background monitoring service
- ✅ Real-time order updates
- ✅ Balance management
- ✅ Error handling

**Test it now:**
```dart
context.read<OrderBloc>().add(
  CreateStopLossOrder(
    assetSymbol: 'RELIANCE',
    assetName: 'Reliance Industries',
    assetType: AssetType.stock,
    orderSide: OrderSide.sell,
    quantity: 1,
    triggerPrice: 2500.0,
  ),
);
```

Happy Trading! 🚀📈
