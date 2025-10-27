import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'dart:developer' as developer;

/// Holdings Repository
/// Handles all user holdings (portfolio) operations with Supabase
class HoldingsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user's ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch all holdings for current user
  Future<List<Holding>> getHoldings() async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('holdings')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Holding.fromJson(json))
          .toList();
    } catch (e,st) {
      developer.log('Error fetching holdings', name: 'HoldingsRepository', error: e, stackTrace: st);
      return [];
    }
  }

  /// Stream holdings (real-time updates)
  Stream<List<Holding>> watchHoldings() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('holdings')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .map((data) {
          return (data as List)
              .map((json) => Holding.fromJson(json))
              .toList();
        });
  }

  /// Get a specific holding by asset symbol
  Future<Holding?> getHoldingBySymbol(String assetSymbol) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('holdings')
          .select()
          .eq('user_id', currentUserId!)
          .eq('asset_symbol', assetSymbol)
          .maybeSingle();

      if (response == null) return null;
      return Holding.fromJson(response);
    } catch (e,st) {
      developer.log('Error fetching holdings', name: 'HoldingsRepository', error: e, stackTrace: st);
      return null;
    }
  }

  /// Add new holding or update existing one
  Future<Holding?> addOrUpdateHolding({
    required String assetSymbol,
    required String assetName,
    required AssetType assetType,
    required double quantity,
    required double price,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check if holding already exists
      final existing = await getHoldingBySymbol(assetSymbol);

      if (existing != null) {
        // Update existing holding - calculate new average price
        final newQuantity = existing.quantity + quantity;
        final newTotalInvested = existing.totalInvested + (quantity * price);
        final newAveragePrice = newTotalInvested / newQuantity;

        final response = await _supabase
            .from('holdings')
            .update({
              'quantity': newQuantity,
              'average_price': newAveragePrice,
              'current_price': price,
              'total_invested': newTotalInvested,
              'current_value': newQuantity * price,
              'profit_loss': (newQuantity * price) - newTotalInvested,
              'profit_loss_percentage': ((newQuantity * price) - newTotalInvested) / newTotalInvested * 100,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing.id)
            .select()
            .single();

        return Holding.fromJson(response);
      } else {
        // Create new holding
        final totalInvested = quantity * price;
        final response = await _supabase
            .from('holdings')
            .insert({
              'user_id': currentUserId!,
              'asset_symbol': assetSymbol,
              'asset_name': assetName,
              'asset_type': assetType.toJson(),
              'quantity': quantity,
              'average_price': price,
              'current_price': price,
              'total_invested': totalInvested,
              'current_value': totalInvested,
              'profit_loss': 0.0,
              'profit_loss_percentage': 0.0,
            })
            .select()
            .single();

        return Holding.fromJson(response);
      }
    } catch (e,st) {
      developer.log('Error adding/updating holding', name: 'HoldingsRepository', error: e, stackTrace: st);
      return null;
    }
  }

  /// Reduce holding quantity (for sell operations)
  Future<Holding?> reduceHolding({
    required String assetSymbol,
    required double quantity,
    required double currentPrice,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final existing = await getHoldingBySymbol(assetSymbol);
      if (existing == null) throw Exception('Holding not found');

      if (existing.quantity < quantity) {
        throw Exception('Insufficient quantity to sell');
      }

      final newQuantity = existing.quantity - quantity;

      if (newQuantity == 0) {
        // Delete holding if quantity becomes zero
        await deleteHolding(assetSymbol);
        return null;
      } else {
        // Update holding with reduced quantity
        final newTotalInvested = existing.averagePrice * newQuantity;
        final newCurrentValue = newQuantity * currentPrice;

        final response = await _supabase
            .from('holdings')
            .update({
              'quantity': newQuantity,
              'current_price': currentPrice,
              'total_invested': newTotalInvested,
              'current_value': newCurrentValue,
              'profit_loss': newCurrentValue - newTotalInvested,
              'profit_loss_percentage': (newCurrentValue - newTotalInvested) / newTotalInvested * 100,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing.id)
            .select()
            .single();

        return Holding.fromJson(response);
      }
    } catch (e,st) {
      developer.log('Error reducing holding', name: 'HoldingsRepository', error: e, stackTrace: st);
      return null;
    }
  }

  /// Update current price for a holding
  Future<Holding?> updateCurrentPrice(String assetSymbol, double newPrice) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final existing = await getHoldingBySymbol(assetSymbol);
      if (existing == null) return null;

      final newCurrentValue = existing.quantity * newPrice;
      final newProfitLoss = newCurrentValue - existing.totalInvested;
      final newProfitLossPercentage = (newProfitLoss / existing.totalInvested) * 100;

      final response = await _supabase
          .from('holdings')
          .update({
            'current_price': newPrice,
            'current_value': newCurrentValue,
            'profit_loss': newProfitLoss,
            'profit_loss_percentage': newProfitLossPercentage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing.id)
          .select()
          .single();

      return Holding.fromJson(response);
    } catch (e,st) {
      developer.log('Error updating price', name: 'HoldingsRepository', error: e, stackTrace: st);

      return null;
    }
  }

  /// Delete a holding
  Future<bool> deleteHolding(String assetSymbol) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _supabase
          .from('holdings')
          .delete()
          .eq('user_id', currentUserId!)
          .eq('asset_symbol', assetSymbol);

      return true;
    } catch (e,st) {
      developer.log('Error deleting holding', name: 'HoldingsRepository', error: e, stackTrace: st);
      return false;
    }
  }

  /// Get total portfolio value
  Future<double> getTotalPortfolioValue() async {
    try {
      final holdings = await getHoldings();
      return holdings.fold<double>(0.0, (sum, holding) => sum + holding.currentValue);
    } catch (e,st) {
      developer.log('Error calculating portfolio value', name: 'HoldingsRepository', error: e, stackTrace: st);
      return 0.0;
    }
  }

  /// Get total invested amount
  Future<double> getTotalInvested() async {
    try {
      final holdings = await getHoldings();
      return holdings.fold<double>(0.0, (sum, holding) => sum + holding.totalInvested);
    } catch (e,st) {
      developer.log('Error calculating total invested', name: 'HoldingsRepository', error: e, stackTrace: st);
      return 0.0;
    }
  }

  /// Get total profit/loss
  Future<double> getTotalProfitLoss() async {
    try {
      final holdings = await getHoldings();
      return holdings.fold<double>(0.0, (sum, holding) => sum + holding.profitLoss);
    } catch (e,st) {
      developer.log('Error calculating total P&L', name: 'HoldingsRepository', error: e, stackTrace: st);
      return 0.0;
    }
  }

  /// Get holdings by asset type
  Future<List<Holding>> getHoldingsByType(AssetType type) async {
    try {
      final holdings = await getHoldings();
      return holdings.where((h) => h.assetType == type).toList();
    } catch (e,st) {
      developer.log('Error filtering holdings', name: 'HoldingsRepository', error: e, stackTrace: st);
      return [];
    }
  }
}
