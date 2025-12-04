# Trading Statistics - How They Work

## Current Implementation ✅

### Statistics ARE Already Dynamic!

The trading statistics in `stock_detail_screen.dart` are **fully dynamic** and calculated in real-time from your transactions table via the `StockDetailBloc`.

#### Calculation Logic (in `stock_detail_state.dart`):

```dart
/// Get total quantity bought
double get totalBought => transactions
    .where((t) => t.transactionType == TransactionType.buy)
    .fold(0.0, (sum, t) => sum + t.quantity);

/// Get total quantity sold
double get totalSold => transactions
    .where((t) => t.transactionType == TransactionType.sell)
    .fold(0.0, (sum, t) => sum + t.quantity);

/// Get total amount invested
double get totalInvested => transactions
    .where((t) => t.transactionType == TransactionType.buy)
    .fold(0.0, (sum, t) => sum + t.totalAmount);

/// Get total amount received from selling
double get totalReceived => transactions
    .where((t) => t.transactionType == TransactionType.sell)
    .fold(0.0, (sum, t) => sum + t.totalAmount);
```

### Why Statistics Might Show 0 Sold:

1. **No sell transactions in database** - Check Supabase `transactions` table
2. **Wrong transaction_type value** - Ensure sells are marked as `"sell"` not `"SELL"`
3. **Refresh timing** - Need to wait for database commit before reloading

## How Data Flows:

```
User taps "Sell" 
  ↓
CryptoBloc.SellCrypto or TransactionBloc.ExecuteSellOrder
  ↓
TransactionRepository.executeSellOrder()
  ↓
Creates transaction with transaction_type: "sell"
  ↓  
Inserts into Supabase transactions table
  ↓
(Wait 1500ms + 800ms for commit)
  ↓
StockDetailBloc.LoadStockDetail()
  ↓
Fetches ALL transactions for symbol
  ↓
StockDetailLoaded state recalculates statistics
  ↓
UI updates with new totals
```

## Verification Steps:

### 1. Check Database
```sql
-- In Supabase SQL Editor:
SELECT * FROM transactions 
WHERE asset_symbol = 'YOUR_SYMBOL' 
ORDER BY created_at DESC;
```

Look for:
- `transaction_type` = `"sell"` (lowercase!)
- Recent timestamp
- Correct quantity and amounts

### 2. Check Transaction Repository

File: `lib/core/repositories/transaction_repository.dart`

The `executeSellOrder` method should create:
```dart
'transaction_type': TransactionType.sell.toJson(), // Returns "sell"
```

### 3. Check Bloc Logging

Look for debug logs in console:
```
[StockDetailBloc] Loading stock detail for RELIANCE
[StockDetailBloc] Found holding: 10.00 shares
[StockDetailBloc] Found 5 transactions
[StockDetailBloc] Buy transactions: 3, Sell transactions: 2  ← Check this!
```

## Local JSON Stock Prices

### What You Have:
- `assets/Stock Prices/stock_prices_2min_nov26.json`
- 20 Indian stocks with prices every 2 minutes
- Simulates market data without API

### How to Use:

1. **Created LocalPriceService** - Loads JSON and provides prices
2. **Created PriceUpdater** - Updates holdings with JSON prices
3. **Added to pubspec.yaml** - Asset is now accessible

### Integration:

```dart
// In your app initialization:
final priceUpdater = PriceUpdater();
await priceUpdater.initialize();

// Update all holding prices:
await priceUpdater.updateAllHoldingPrices();

// Get price for a symbol:
final price = priceUpdater.getCurrentPrice('RELIANCE');
```

## The Real Issue:

If statistics show **18.00 units bought** but **0.00 units sold**, it means:

❌ **No sell transactions are in the database**

Possible causes:
1. Sell operation throws an error (check logs)
2. Database permission issue
3. Wrong transaction_type format
4. Not waiting long enough for commit

## Solution:

### Immediate Fix:
Increase wait time in confirmation dialog to ensure database commit:

```dart
await Future.delayed(const Duration(milliseconds: 1500)); // After sell
// ... show confirmation ...
await Future.delayed(const Duration(milliseconds: 800));  // Before reload
```

### Permanent Fix:
Use BlocListener to wait for actual success state instead of arbitrary delays.

## Testing:

1. **Buy some stock** → Check stats update immediately
2. **Sell some stock** → Check stats update after 2.3 seconds
3. **Check Supabase** → Verify sell transaction exists
4. **Check console** → Look for "Sell transactions: X" log

---

**Bottom Line:** Statistics ARE dynamic. If they're not updating, the sell transaction isn't being created or the bloc isn't reloading. Check your database!
