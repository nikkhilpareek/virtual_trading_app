# Lot-Based Holdings Implementation Guide

## Overview
This implements a lot-based (batch-based) position tracking system where each purchase at a different price is tracked separately. This allows:
- Individual stop-loss orders for each purchase batch
- Better tax accounting (FIFO, LIFO, specific lot identification)
- Clearer profit/loss tracking per purchase
- More granular position management

## Changes Made

### 1. New Model: `HoldingLot`
**File**: `lib/core/models/holding_lot.dart`

Represents a single purchase batch with:
- `id`: Unique identifier
- `purchasePrice`: The price at which this lot was bought
- `purchaseDate`: When this lot was purchased
- `quantity`: How many units in this lot
- `transactionId`: Link to the buy transaction

### 2. Database Migration
**File**: `database/holding_lots_table.sql`

Creates `holding_lots` table with:
- Full RLS (Row Level Security) policies
- Indexes for performance
- Auto-updating `updated_at` trigger
- Migration of existing holdings to lots

### 3. How It Works

#### Before (Current System):
```
User buys 10 shares of RELIANCE at ₹2,500
User buys 5 shares of RELIANCE at ₹2,600

Holdings Table:
- RELIANCE: 15 shares at avg ₹2,533.33
```

Single entry, averaged price, one stop-loss for all shares.

#### After (Lot-Based System):
```
User buys 10 shares of RELIANCE at ₹2,500
User buys 5 shares of RELIANCE at ₹2,600

Holding_Lots Table:
- Lot 1: RELIANCE: 10 shares at ₹2,500 (Purchase: Dec 1)
- Lot 2: RELIANCE: 5 shares at ₹2,600 (Purchase: Dec 3)

Holdings Table (Aggregated View):
- RELIANCE: 15 shares at avg ₹2,533.33
```

Two separate lots, each can have its own stop-loss!

## Implementation Steps

### Step 1: Run Database Migration
```bash
# Connect to your Supabase project
# Go to SQL Editor in Supabase Dashboard
# Run the contents of database/holding_lots_table.sql
```

### Step 2: Update Transaction Repository
Modify `lib/core/repositories/transaction_repository.dart`:

```dart
// In executeBuyOrder method, after creating holding:
// Create a holding lot entry
final lotId = _uuid.v4();
await _supabase.from('holding_lots').insert({
  'id': lotId,
  'user_id': currentUserId!,
  'asset_symbol': assetSymbol,
  'asset_name': assetName,
  'asset_type': assetType.toJson(),
  'quantity': quantity,
  'purchase_price': pricePerUnit,
  'current_price': pricePerUnit,
  'purchase_date': DateTime.now().toIso8601String(),
  'transaction_id': response['id'], // Link to transaction
});
```

### Step 3: Create HoldingLotRepository
**File**: `lib/core/repositories/holding_lot_repository.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class HoldingLotRepository {
  final SupabaseClient _supabase;
  
  HoldingLotRepository(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Get all lots for a specific asset symbol
  Future<List<HoldingLot>> getLotsBySymbol(String assetSymbol) async {
    final response = await _supabase
        .from('holding_lots')
        .select()
        .eq('user_id', currentUserId!)
        .eq('asset_symbol', assetSymbol)
        .order('purchase_date', ascending: true);

    return (response as List)
        .map((json) => HoldingLot.fromJson(json))
        .toList();
  }

  /// Get all lots for user
  Future<List<HoldingLot>> getAllLots() async {
    final response = await _supabase
        .from('holding_lots')
        .select()
        .eq('user_id', currentUserId!)
        .order('purchase_date', ascending: false);

    return (response as List)
        .map((json) => HoldingLot.fromJson(json))
        .toList();
  }

  /// Reduce quantity from a specific lot (FIFO by default)
  Future<void> reduceQuantityFromLot(String lotId, double quantityToSell) async {
    final lot = await _supabase
        .from('holding_lots')
        .select()
        .eq('id', lotId)
        .single();

    final currentQty = (lot['quantity'] as num).toDouble();
    final newQty = currentQty - quantityToSell;

    if (newQty <= 0.0001) {
      // Delete lot if fully sold
      await _supabase.from('holding_lots').delete().eq('id', lotId);
    } else {
      // Update lot with reduced quantity
      await _supabase
          .from('holding_lots')
          .update({'quantity': newQty})
          .eq('id', lotId);
    }
  }

  /// Update current price for all lots of an asset
  Future<void> updateCurrentPrice(String assetSymbol, double newPrice) async {
    await _supabase
        .from('holding_lots')
        .update({'current_price': newPrice})
        .eq('user_id', currentUserId!)
        .eq('asset_symbol', assetSymbol);
  }
}
```

### Step 4: Update Holdings Detail Screen
Modify `lib/screens/stock_detail_screen.dart`:

Show lots instead of or in addition to aggregated holding:

```dart
// Add to _StockDetailView
Widget _buildLotsSection(BuildContext context, List<HoldingLot> lots) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Purchase Lots',
        style: TextStyle(
          fontFamily: 'ClashDisplay',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 16),
      ...lots.map((lot) => _buildLotCard(context, lot)),
    ],
  );
}

Widget _buildLotCard(BuildContext context, HoldingLot lot) {
  final isPositive = lot.profitLoss >= 0;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff121212),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isPositive
            ? Colors.green.withAlpha((0.3 * 255).round())
            : Colors.red.withAlpha((0.3 * 255).round()),
      ),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchased: ${DateFormat('MMM dd, yyyy').format(lot.purchaseDate)}',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    color: Colors.white.withAlpha((0.6 * 255).round()),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lot.formattedQuantity + ' units',
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lot.formattedPurchasePrice,
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lot.formattedProfitLoss,
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _createStopLossForLot(context, lot),
                icon: const Icon(Icons.shield, size: 16),
                label: const Text('Stop-Loss'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _sellLot(context, lot),
                icon: const Icon(Icons.sell, size: 16),
                label: const Text('Sell'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

### Step 5: Update Order Creation
When creating stop-loss or bracket orders, add `lot_id` field:

```dart
// Modify CreateStopLossOrder and CreateBracketOrder events
class CreateStopLossOrder extends OrderEvent {
  final String? lotId; // NEW: Link to specific lot
  // ... other fields
}

// In order creation:
context.read<OrderBloc>().add(
  CreateStopLossOrder(
    assetSymbol: lot.assetSymbol,
    quantity: lot.quantity,
    lotId: lot.id, // Link order to specific lot
    // ... other params
  ),
);
```

### Step 6: Update Backend Order Monitor
Modify `backend/order_monitor.py`:

When executing a sell order, use FIFO or specific lot:

```python
# In _execute_sell method:
if order_data.get('lot_id'):
    # Sell from specific lot
    lot = self.supabase.table('holding_lots').select('*').eq(
        'id', order_data['lot_id']
    ).single().execute()
    
    # Reduce or delete lot
    new_qty = float(lot.data['quantity']) - quantity
    if new_qty <= 0.0001:
        self.supabase.table('holding_lots').delete().eq(
            'id', lot.data['id']
        ).execute()
    else:
        self.supabase.table('holding_lots').update({
            'quantity': new_qty
        }).eq('id', lot.data['id']).execute()
else:
    # FIFO: sell from oldest lot first
    lots = self.supabase.table('holding_lots').select('*').eq(
        'user_id', user_id
    ).eq('asset_symbol', symbol).order('purchase_date', asc=True).execute()
    
    # Process FIFO...
```

## Benefits

1. **Individual Stop-Loss Management**: Each purchase can have its own protective stop-loss
2. **Better Risk Management**: See which lots are profitable vs loss-making
3. **Tax Optimization**: Choose which lots to sell (FIFO, LIFO, or specific)
4. **Clearer P&L**: Track performance of each investment decision
5. **Flexible Trading**: Can keep profitable lots while cutting losses on others

## UI/UX Changes

### Before:
```
RELIANCE
15 shares @ avg ₹2,533.33
P&L: +₹1,200 (+5.2%)
[Sell] [Stop-Loss] [Bracket]
```

### After:
```
RELIANCE (Total: 15 shares)

Purchase Lots:
┌─────────────────────────────────┐
│ Lot 1 - Dec 1, 2025            │
│ 10 units @ ₹2,500              │
│ P&L: +₹800 (+3.2%)             │
│ [Stop-Loss] [Sell This Lot]    │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ Lot 2 - Dec 3, 2025            │
│ 5 units @ ₹2,600               │
│ P&L: +₹400 (+3.1%)             │
│ [Stop-Loss] [Sell This Lot]    │
└─────────────────────────────────┘
```

## Migration Path

1. **Phase 1**: Create database table and model ✅ (Done)
2. **Phase 2**: Update transaction creation to add lots
3. **Phase 3**: Create lot repository and BLoC
4. **Phase 4**: Update UI to show lots
5. **Phase 5**: Link orders to specific lots
6. **Phase 6**: Update backend order execution

## Testing Checklist

- [ ] Database migration runs successfully
- [ ] New purchases create holding_lots entries
- [ ] Lots are displayed correctly in UI
- [ ] Stop-loss can be created for individual lots
- [ ] Selling from a specific lot works
- [ ] FIFO selling works when lot not specified
- [ ] Aggregated holding view still works
- [ ] Current prices update for all lots
- [ ] Orders linked to lots execute correctly

## Notes

- The original `holdings` table is kept for backward compatibility and aggregated views
- You can still show the "total" view by summing all lots
- Orders can now have an optional `lot_id` field to link them to specific lots
- Backend needs to handle both lot-specific and aggregated operations
