import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'dart:developer' as developer;

/// User Repository
/// Handles all user profile related operations with Supabase
class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user's ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUserId != null;

  /// Fetch user profile by ID
  Future<UserProfile?> getUserProfile([String? userId]) async {
    try {
      final id = userId ?? currentUserId;
      if (id == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e, st) {
      developer.log(
        'Error fetching user profile',
        name: 'UserRepository',
        error: e,
        stackTrace: st,
      );

      return null;
    }
  }

  /// Stream user profile changes (real-time updates)
  Stream<UserProfile?> watchUserProfile([String? userId]) {
    final id = userId ?? currentUserId;
    if (id == null) {
      return Stream.value(null);
    }

    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .map((data) {
          if (data.isEmpty) return null;
          return UserProfile.fromJson(data.first);
        });
  }

  /// Update user profile
  Future<UserProfile?> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      final response = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', currentUserId!)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e,st) {
      developer.log(
        'Error updating profile',
        name: 'UserRepository',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Update user's Stonk Token balance
  Future<bool> updateBalance(double newBalance) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _supabase
          .from('profiles')
          .update({
            'stonk_balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUserId!);

      return true;
    } catch (e,st) {
      developer.log(
        'Error updating balance',
        name: 'UserRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Add amount to user's balance
  Future<bool> addToBalance(double amount) async {
    try {
      final profile = await getUserProfile();
      if (profile == null) return false;

      final newBalance = profile.stonkBalance + amount;
      return await updateBalance(newBalance);
    } catch (e,st) {
      developer.log(
        'Error adding to balance',
        name: 'UserRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Deduct amount from user's balance
  Future<bool> deductFromBalance(double amount) async {
    try {
      final profile = await getUserProfile();
      if (profile == null) return false;

      if (profile.stonkBalance < amount) {
        throw Exception('Insufficient balance');
      }

      final newBalance = profile.stonkBalance - amount;
      return await updateBalance(newBalance);
    } catch (e,st) {
      developer.log(
        'Error deducting from balance',
        name: 'UserRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Upload user avatar to Supabase Storage
  Future<String?> uploadAvatar(String filePath) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // Generate unique file name
      final fileName =
          '$currentUserId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Supabase Storage
      await _supabase.storage.from('avatars').upload(fileName, File(filePath));

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      // Update profile with new avatar URL
      await updateProfile(avatarUrl: publicUrl);

      return publicUrl;
    } catch (e,st) {
      developer.log(
        'Error uploading avatar',
        name: 'UserRepository',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Delete user avatar
  Future<bool> deleteAvatar(String avatarUrl) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // Extract file path from URL
      final uri = Uri.parse(avatarUrl);
      final path = uri.pathSegments.last;

      // Delete from storage
      await _supabase.storage.from('avatars').remove(['$currentUserId/$path']);

      // Update profile to remove avatar URL
      await updateProfile(avatarUrl: null);

      return true;
    } catch (e,st) {
      developer.log(
        'Error deleting avatar',
        name: 'UserRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Get current user's balance
  Future<double?> getCurrentBalance() async {
    try {
      final profile = await getUserProfile();
      return profile?.stonkBalance;
    } catch (e,st) {
      developer.log(
        'Error getting balance',
        name: 'UserRepository',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Check if user has sufficient balance
  Future<bool> hasSufficientBalance(double amount) async {
    try {
      final balance = await getCurrentBalance();
      if (balance == null) return false;
      return balance >= amount;
    } catch (e,st) {  
      developer.log(
        'Error checking balance',
        name: 'UserRepository',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
