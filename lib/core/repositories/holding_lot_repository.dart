import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'dart:developer' as developer;

class HoldingLotRepository {
  final SupabaseClient _supabase;

  HoldingLotRepository(this._supabase);

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Get all lots for a specific asset symbol
  Future<List<HoldingLot>> getLotsBySymbol(String assetSymbol) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('holding_lots')
          .select()
          .eq('user_id', currentUserId!)
          .eq('asset_symbol', assetSymbol)
          .eq('is_active', true) // Only get active (unsold) lots
          .gte('quantity', 0.001)
          .order('purchase_date', ascending: true);

      return (response as List)
          .map((json) => HoldingLot.fromJson(json))
          .toList();
    } catch (e, st) {
      developer.log(
        'Error fetching lots by symbol',
        name: 'HoldingLotRepository',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Get all lots for user
  Future<List<HoldingLot>> getAllLots() async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('holding_lots')
          .select()
          .eq('user_id', currentUserId!)
          .eq('is_active', true) // Only get active (unsold) lots
          .gte('quantity', 0.001)
          .order('purchase_date', ascending: false);

      return (response as List)
          .map((json) => HoldingLot.fromJson(json))
          .toList();
    } catch (e, st) {
      developer.log(
        'Error fetching all lots',
        name: 'HoldingLotRepository',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Get all lots for a specific asset type
  Future<List<HoldingLot>> getLotsByAssetType(AssetType assetType) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('holding_lots')
          .select()
          .eq('user_id', currentUserId!)
          .eq('asset_type', assetType.toJson())
          .eq('is_active', true) // Only get active (unsold) lots
          .gte('quantity', 0.001)
          .order('purchase_date', ascending: false);

      return (response as List)
          .map((json) => HoldingLot.fromJson(json))
          .toList();
    } catch (e, st) {
      developer.log(
        'Error fetching lots by type',
        name: 'HoldingLotRepository',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Create a new holding lot
  Future<HoldingLot?> createLot({
    required String assetSymbol,
    required String assetName,
    required AssetType assetType,
    required double quantity,
    required double purchasePrice,
    String? transactionId,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('holding_lots')
          .insert({
            'user_id': currentUserId!,
            'asset_symbol': assetSymbol,
            'asset_name': assetName,
            'asset_type': assetType.toJson(),
            'quantity': quantity,
            'purchase_price': purchasePrice,
            'current_price': purchasePrice,
            'purchase_date': DateTime.now().toIso8601String(),
            'transaction_id': transactionId,
            'is_active': true,
          })
          .select()
          .single();

      developer.log(
        'Created lot: $assetSymbol x $quantity @ $purchasePrice',
        name: 'HoldingLotRepository',
      );

      return HoldingLot.fromJson(response);
    } catch (e, st) {
      developer.log(
        'Error creating lot',
        name: 'HoldingLotRepository',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Reduce quantity from a specific lot
  Future<bool> reduceQuantityFromLot(
    String lotId,
    double quantityToSell,
  ) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final lot = await _supabase
          .from('holding_lots')
          .select()
          .eq('id', lotId)
          .eq('user_id', currentUserId!)
          .single();

      final currentQty = (lot['quantity'] as num).toDouble();
      final newQty = currentQty - quantityToSell;

      developer.log(
        'Reducing lot $lotId: $currentQty - $quantityToSell = $newQty',
        name: 'HoldingLotRepository',
      );

      if (newQty <= 0.0001) {
        // Mark lot as inactive (sold)
        developer.log(
          '🔄 Attempting to mark lot $lotId as INACTIVE',
          name: 'HoldingLotRepository',
        );

        final updateResponse = await _supabase
            .from('holding_lots')
            .update({
              'quantity': 0,
              'is_active': false,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', lotId)
            .eq('user_id', currentUserId!)
            .select();

        developer.log(
          '🚫 Marked lot $lotId as INACTIVE - Response: $updateResponse',
          name: 'HoldingLotRepository',
        );
      } else {
        // Update lot with reduced quantity
        await _supabase
            .from('holding_lots')
            .update({
              'quantity': newQty,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', lotId)
            .eq('user_id', currentUserId!);

        developer.log(
          '✏️ Updated lot $lotId: $currentQty -> $newQty',
          name: 'HoldingLotRepository',
        );
      }
      return true;
    } catch (e, st) {
      developer.log(
        'Error reducing lot quantity',
        name: 'HoldingLotRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Get oldest lot for FIFO selling
  Future<HoldingLot?> getOldestLot(String assetSymbol) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('holding_lots')
          .select()
          .eq('user_id', currentUserId!)
          .eq('asset_symbol', assetSymbol)
          .eq('is_active', true) // Only get active (unsold) lots
          .gte('quantity', 0.001)
          .order('purchase_date', ascending: true)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return HoldingLot.fromJson(response);
    } catch (e, st) {
      developer.log(
        'Error getting oldest lot',
        name: 'HoldingLotRepository',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Sell using FIFO (First In, First Out) method
  Future<bool> sellFIFO(String assetSymbol, double quantityToSell) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      double remainingToSell = quantityToSell;

      while (remainingToSell > 0.0001) {
        final oldestLot = await getOldestLot(assetSymbol);
        if (oldestLot == null) {
          throw Exception('No more lots available to sell');
        }

        if (oldestLot.quantity <= remainingToSell) {
          // Sell entire lot
          await reduceQuantityFromLot(oldestLot.id, oldestLot.quantity);
          remainingToSell -= oldestLot.quantity;
        } else {
          // Sell partial lot
          await reduceQuantityFromLot(oldestLot.id, remainingToSell);
          remainingToSell = 0;
        }
      }

      developer.log(
        'FIFO sell completed: $assetSymbol x $quantityToSell',
        name: 'HoldingLotRepository',
      );

      return true;
    } catch (e, st) {
      developer.log(
        'Error in FIFO sell',
        name: 'HoldingLotRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Update current price for all lots of an asset
  Future<void> updateCurrentPrice(String assetSymbol, double newPrice) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _supabase
          .from('holding_lots')
          .update({
            'current_price': newPrice,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUserId!)
          .eq('asset_symbol', assetSymbol);

      developer.log(
        'Updated price for all lots of $assetSymbol: $newPrice',
        name: 'HoldingLotRepository',
      );
    } catch (e, st) {
      developer.log(
        'Error updating current price',
        name: 'HoldingLotRepository',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Get total quantity across all lots for an asset
  Future<double> getTotalQuantity(String assetSymbol) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final lots = await getLotsBySymbol(assetSymbol);
      return lots.fold<double>(0.0, (sum, lot) => sum + lot.quantity);
    } catch (e, st) {
      developer.log(
        'Error getting total quantity',
        name: 'HoldingLotRepository',
        error: e,
        stackTrace: st,
      );
      return 0.0;
    }
  }

  /// Mark all lots for an asset as inactive (when fully sold)
  Future<void> deleteAllLots(String assetSymbol) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _supabase
          .from('holding_lots')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUserId!)
          .eq('asset_symbol', assetSymbol)
          .eq('is_active', true);

      developer.log(
        'Marked all active lots as inactive for $assetSymbol',
        name: 'HoldingLotRepository',
      );
    } catch (e, st) {
      developer.log(
        'Error marking lots as inactive',
        name: 'HoldingLotRepository',
        error: e,
        stackTrace: st,
      );
    }
  }
}
