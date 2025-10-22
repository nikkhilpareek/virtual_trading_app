import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

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
    } catch (e) {
      print('Error fetching watchlist: $e');
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
    } catch (e) {
      print('Error checking watchlist: $e');
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
    } catch (e) {
      print('Error adding to watchlist: $e');
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
    } catch (e) {
      print('Error removing from watchlist: $e');
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
    } catch (e) {
      print('Error toggling watchlist: $e');
      return false;
    }
  }

  /// Get watchlist items by asset type
  Future<List<WatchlistItem>> getWatchlistByType(AssetType type) async {
    try {
      final watchlist = await getWatchlist();
      return watchlist.where((item) => item.assetType == type).toList();
    } catch (e) {
      print('Error filtering watchlist: $e');
      return [];
    }
  }

  /// Get watchlist count
  Future<int> getWatchlistCount() async {
    try {
      final watchlist = await getWatchlist();
      return watchlist.length;
    } catch (e) {
      print('Error getting watchlist count: $e');
      return 0;
    }
  }

  /// Clear entire watchlist
  Future<bool> clearWatchlist() async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _supabase
          .from('watchlist')
          .delete()
          .eq('user_id', currentUserId!);

      return true;
    } catch (e) {
      print('Error clearing watchlist: $e');
      return false;
    }
  }
}
