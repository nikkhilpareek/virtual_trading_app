# Debug Trading Statistics Not Updating

## Quick Diagnosis

### Step 1: Check if Sell Transactions Exist in Database

Open your Supabase project dashboard:
1. Go to **Table Editor**
2. Open the `transactions` table
3. Filter by your asset symbol (e.g., `RELIANCE`)
4. Look for rows with `transaction_type = "sell"`

**Expected:** You should see sell transactions with recent timestamps

**If NO sell transactions:**
- The sell operation is failing silently
- Check Flutter debug console for errors
- Check the section below on "Debugging Sell Flow"

### Step 2: Check Console Logs

After selling, look for this log in your Flutter console:

```
[StockDetailBloc] Buy transactions: X, Sell transactions: Y
```

**If Y = 0:** No sell transactions in database
**If Y > 0:** Transactions exist, statistics should show them

### Step 3: Verify Transaction Type Format

Check your database - the `transaction_type` column should be:
- ✅ `"sell"` (lowercase)
- ❌ NOT `"SELL"` (uppercase)
- ❌ NOT `"Sell"` (capitalized)

## Debugging Sell Flow

### Add Debug Logging to Crypto Bloc

File: `lib/core/blocs/crypto/crypto_bloc.dart`

Find the `_onSellCrypto` method and add logging:

```dart
Future<void> _onSellCrypto(
  SellCrypto event,
  Emitter<CryptoState> emit,
) async {
  emit(CryptoTrading());
  
  developer.log('🔴 SELL CRYPTO STARTED: ${event.symbol}, qty: ${event.quantity}', name: 'CryptoBloc');
  
  try {
    // ... existing code ...
    
    final transaction = await _transactionRepository.executeSellOrder(
      assetSymbol: event.symbol,
      // ... other params
    );
    
    developer.log('✅ SELL TRANSACTION CREATED: ${transaction?.id}', name: 'CryptoBloc');
    
    if (transaction != null) {
      emit(CryptoTradeSuccess('Successfully sold ${event.quantity} ${event.symbol}'));
    } else {
      developer.log('❌ SELL FAILED: Transaction is null', name: 'CryptoBloc');
      emit(const CryptoTradeError('Failed to create sell transaction'));
    }
  } catch (e, st) {
    developer.log('❌ SELL ERROR: $e', name: 'CryptoBloc', error: e, stackTrace: st);
    emit(CryptoTradeError(e.toString()));
  }
}
```

### Check Transaction Repository

File: `lib/core/repositories/transaction_repository.dart`

Look for `executeSellOrder` method and verify:

```dart
'transaction_type': TransactionType.sell.toJson(), // Must return "sell"
```

### Manual Database Test

Try inserting a sell transaction manually in Supabase:

```sql
INSERT INTO transactions (
  user_id,
  asset_symbol,
  asset_name,
  asset_type,
  transaction_type,
  quantity,
  price_per_unit,
  total_amount,
  balance_after,
  created_at
) VALUES (
  'YOUR_USER_ID',
  'RELIANCE',
  'Reliance Industries',
  'stock',
  'sell',  -- IMPORTANT: lowercase!
  5.0,
  1540.0,
  7700.0,
  107700.0,
  NOW()
);
```

Then refresh the Holdings screen - statistics should update immediately.

## Common Issues & Solutions

### Issue 1: "setState() called after dispose" Errors

**Symptom:** Lots of errors about MarketScreen setState after dispose

**Solution:** This is unrelated to trading statistics. It's from the market screen polling. To fix:

```dart
// In market_screen.dart, in _loadMarketData():
if (!mounted) return; // Add this at the start
```

### Issue 2: Local Stock Prices JSON Not Loading

**Symptom:** Prices show 0 or don't update

**Solution:** 
1. Run `flutter pub get` to register the new asset
2. Hot restart (not hot reload) the app
3. Check console for: `[LocalPriceService] Loaded prices for 20 stocks`

### Issue 3: Statistics Show 0 After Successful Sell

**Symptom:** 
- Console shows: `Buy transactions: 3, Sell transactions: 0`
- But you just sold successfully

**Diagnosis:** 
- Sell transaction didn't save to database
- Check Supabase RLS (Row Level Security) policies
- User might not have INSERT permission on transactions table

**Solution:**
```sql
-- In Supabase SQL Editor, create policy:
CREATE POLICY "Users can insert their own transactions"
ON transactions FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);
```

### Issue 4: Timing - Refresh Too Fast

**Symptom:** Sometimes works, sometimes doesn't

**Current delays:**
- 1500ms after sell dispatch
- 800ms before reload

**Try increasing:**
```dart
await Future.delayed(const Duration(milliseconds: 2000)); // After sell
await Future.delayed(const Duration(milliseconds: 1000)); // Before reload
```

## Testing Checklist

- [ ] Open Holdings detail screen for a stock you own
- [ ] Note the "Total Bought" and "Total Sold" values
- [ ] Tap the red "Sell" button
- [ ] Enter quantity (less than available)
- [ ] Tap "Sell" button in bottom sheet
- [ ] Wait for success dialog (green checkmark)
- [ ] Tap "Done"
- [ ] **Wait 3 seconds** for reload
- [ ] Check if "Total Sold" increased
- [ ] Check console for transaction count logs
- [ ] Check Supabase transactions table

## Expected Console Output

```
[StockDetailBloc] Loading stock detail for RELIANCE
[StockDetailBloc] Found holding: 18.00 shares
[StockDetailBloc] Found 4 transactions
[StockDetailBloc] Buy transactions: 3, Sell transactions: 1
```

After selling 5 units:

```
[CryptoBloc] 🔴 SELL CRYPTO STARTED: RELIANCE, qty: 5.0
[CryptoBloc] ✅ SELL TRANSACTION CREATED: uuid-here
[StockDetailBloc] Loading stock detail for RELIANCE
[StockDetailBloc] Found holding: 13.00 shares  ← Reduced!
[StockDetailBloc] Found 5 transactions  ← One more!
[StockDetailBloc] Buy transactions: 3, Sell transactions: 2  ← Increased!
```

## Still Not Working?

If statistics still show 0 sold after all this:

1. **Share your console output** - Look for the exact logs
2. **Check Supabase transactions table** - Screenshot the data
3. **Verify transaction_type column** - Must be lowercase "sell"
4. **Check RLS policies** - User must have INSERT permission
5. **Try manual SQL insert** - If that works, it's a code issue

---

**Remember:** The statistics code is CORRECT and DYNAMIC. If they're not updating, the problem is either:
- Sell transactions aren't being created
- StockDetailBloc isn't refreshing 
- Database permissions issue
