import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'user_repository.dart';
import 'holdings_repository.dart';
import '../utils/currency_formatter.dart';

/// Transaction Repository
/// Handles all transaction operations and trading logic with Supabase
class TransactionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserRepository _userRepository = UserRepository();
  final HoldingsRepository _holdingsRepository = HoldingsRepository();

  /// Get current user's ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetch all transactions for current user
  Future<List<Transaction>> getTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  /// Stream transactions (real-time updates)
  Stream<List<Transaction>> watchTransactions({int limit = 50}) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) {
          return (data as List)
              .map((json) => Transaction.fromJson(json))
              .toList();
        });
  }

  /// Get transactions for a specific asset
  Future<List<Transaction>> getTransactionsByAsset(String assetSymbol) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', currentUserId!)
          .eq('asset_symbol', assetSymbol)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching asset transactions: $e');
      return [];
    }
  }

  /// Get transactions by type (buy or sell)
  Future<List<Transaction>> getTransactionsByType(TransactionType type) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', currentUserId!)
          .eq('transaction_type', type.toJson())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching transactions by type: $e');
      return [];
    }
  }

  /// Execute a BUY transaction
  Future<Transaction?> executeBuyOrder({
    required String assetSymbol,
    required String assetName,
    required AssetType assetType,
    required double quantity,
    required double pricePerUnit,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final totalAmount = quantity * pricePerUnit;

      // Check if user has sufficient balance
      final hasFunds = await _userRepository.hasSufficientBalance(totalAmount);
      if (!hasFunds) {
        throw Exception('Insufficient balance. Need ${CurrencyFormatter.formatINR(totalAmount)}');
      }

      // Deduct amount from balance
      final balanceUpdated = await _userRepository.deductFromBalance(totalAmount);
      if (!balanceUpdated) {
        throw Exception('Failed to update balance');
      }

      // Get new balance
      final newBalance = await _userRepository.getCurrentBalance() ?? 0.0;

      // Add or update holding
      await _holdingsRepository.addOrUpdateHolding(
        assetSymbol: assetSymbol,
        assetName: assetName,
        assetType: assetType,
        quantity: quantity,
        price: pricePerUnit,
      );

      // Create transaction record
      final response = await _supabase
          .from('transactions')
          .insert({
            'user_id': currentUserId!,
            'asset_symbol': assetSymbol,
            'asset_name': assetName,
            'asset_type': assetType.toJson(),
            'transaction_type': TransactionType.buy.toJson(),
            'quantity': quantity,
            'price_per_unit': pricePerUnit,
            'total_amount': totalAmount,
            'balance_after': newBalance,
          })
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (e) {
      print('Error executing buy order: $e');
      rethrow;
    }
  }

  /// Execute a SELL transaction
  Future<Transaction?> executeSellOrder({
    required String assetSymbol,
    required String assetName,
    required AssetType assetType,
    required double quantity,
    required double pricePerUnit,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check if user has this holding
      final holding = await _holdingsRepository.getHoldingBySymbol(assetSymbol);
      if (holding == null) {
        throw Exception('You do not own this asset');
      }

      // Check if user has sufficient quantity
      if (holding.quantity < quantity) {
        throw Exception('Insufficient quantity. You own ${holding.quantity} units');
      }

      final totalAmount = quantity * pricePerUnit;

      // Add amount to balance
      final balanceUpdated = await _userRepository.addToBalance(totalAmount);
      if (!balanceUpdated) {
        throw Exception('Failed to update balance');
      }

      // Get new balance
      final newBalance = await _userRepository.getCurrentBalance() ?? 0.0;

      // Reduce holding quantity
      await _holdingsRepository.reduceHolding(
        assetSymbol: assetSymbol,
        quantity: quantity,
        currentPrice: pricePerUnit,
      );

      // Create transaction record
      final response = await _supabase
          .from('transactions')
          .insert({
            'user_id': currentUserId!,
            'asset_symbol': assetSymbol,
            'asset_name': assetName,
            'asset_type': assetType.toJson(),
            'transaction_type': TransactionType.sell.toJson(),
            'quantity': quantity,
            'price_per_unit': pricePerUnit,
            'total_amount': totalAmount,
            'balance_after': newBalance,
          })
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (e) {
      print('Error executing sell order: $e');
      rethrow;
    }
  }

  /// Get total amount spent (all buy transactions)
  Future<double> getTotalSpent() async {
    try {
      final buyTransactions = await getTransactionsByType(TransactionType.buy);
      return buyTransactions.fold<double>(0.0, (sum, tx) => sum + tx.totalAmount);
    } catch (e) {
      print('Error calculating total spent: $e');
      return 0.0;
    }
  }

  /// Get total amount received (all sell transactions)
  Future<double> getTotalReceived() async {
    try {
      final sellTransactions = await getTransactionsByType(TransactionType.sell);
      return sellTransactions.fold<double>(0.0, (sum, tx) => sum + tx.totalAmount);
    } catch (e) {
      print('Error calculating total received: $e');
      return 0.0;
    }
  }

  /// Get transaction count
  Future<int> getTransactionCount() async {
    try {
      final transactions = await getTransactions();
      return transactions.length;
    } catch (e) {
      print('Error getting transaction count: $e');
      return 0;
    }
  }
}
