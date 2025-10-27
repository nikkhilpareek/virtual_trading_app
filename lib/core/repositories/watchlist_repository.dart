import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'dart:developer' as developer;

/// Watchlist Repository
/// Handles all watchlist operations with Supabase
class WatchlistRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user's ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch all watchlist items for current user
  Future<List<WatchlistItem>> getWatchlist() async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('watchlist')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => WatchlistItem.fromJson(json))
          .toList();
    } catch (e, st) {
      developer.log(
        'Error fetching watchlist',
        name: 'WatchListRepository',
        error: e,
        stackTrace: st,
      );

      return [];
    }
  }

  /// Stream watchlist (real-time updates)
  Stream<List<WatchlistItem>> watchWatchlist() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('watchlist')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .map((data) {
          return (data as List)
              .map((json) => WatchlistItem.fromJson(json))
              .toList();
        });
  }

  /// Check if an asset is in watchlist
  Future<bool> isInWatchlist(String assetSymbol) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('watchlist')
          .select()
          .eq('user_id', currentUserId!)
          .eq('asset_symbol', assetSymbol)
          .maybeSingle();

      return response != null;
    } catch (e,st) {
      developer.log(
        'Error checking watchlist',
        name: 'WatchListRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Add asset to watchlist
  Future<WatchlistItem?> addToWatchlist({
    required String assetSymbol,
    required String assetName,
    required AssetType assetType,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check if already in watchlist
      final exists = await isInWatchlist(assetSymbol);
      if (exists) {
        throw Exception('Asset already in watchlist');
      }

      final response = await _supabase
          .from('watchlist')
          .insert({
            'user_id': currentUserId!,
            'asset_symbol': assetSymbol,
            'asset_name': assetName,
            'asset_type': assetType.toJson(),
          })
          .select()
          .single();

      return WatchlistItem.fromJson(response);
    } catch (e,st) {
      developer.log(
        'Error adding to watchlist',
        name: 'WatchListRepository',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Remove asset from watchlist
  Future<bool> removeFromWatchlist(String assetSymbol) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _supabase
          .from('watchlist')
          .delete()
          .eq('user_id', currentUserId!)
          .eq('asset_symbol', assetSymbol);

      return true;
    } catch (e,st) {
      developer.log(
        'Error removing from watchlist',
        name: 'WatchListRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Toggle watchlist (add if not present, remove if present)
  Future<bool> toggleWatchlist({
    required String assetSymbol,
    required String assetName,
    required AssetType assetType,
  }) async {
    try {
      final exists = await isInWatchlist(assetSymbol);

      if (exists) {
        return await removeFromWatchlist(assetSymbol);
      } else {
        final item = await addToWatchlist(
          assetSymbol: assetSymbol,
          assetName: assetName,
          assetType: assetType,
        );
        return item != null;
      }
    } catch (e,st) {
      developer.log(
        'Error toggling watchlist',
        name: 'WatchListRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Get watchlist items by asset type
  Future<List<WatchlistItem>> getWatchlistByType(AssetType type) async {
    try {
      final watchlist = await getWatchlist();
      return watchlist.where((item) => item.assetType == type).toList();
    } catch (e,st) {
      developer.log(
        'Error filtering watchlist',
        name: 'WatchListRepository',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Get watchlist count
  Future<int> getWatchlistCount() async {
    try {
      final watchlist = await getWatchlist();
      return watchlist.length;
    } catch (e,st) {
      developer.log(
        'Error getting watchlist count',
        name: 'WatchListRepository',
        error: e,
        stackTrace: st,
      );
      return 0;
    }
  }

  /// Clear entire watchlist
  Future<bool> clearWatchlist() async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _supabase.from('watchlist').delete().eq('user_id', currentUserId!);

      return true;
    } catch (e,st) {
      developer.log(
        'Error clearing watchlist',
        name: 'WatchListRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
