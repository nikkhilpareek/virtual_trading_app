import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'stock_detail_event.dart';
import 'stock_detail_state.dart';
import '../../models/holding.dart';
import '../../models/transaction.dart';
import 'dart:developer' as developer;

/// BLoC for managing stock detail and transaction history
class StockDetailBloc extends Bloc<StockDetailEvent, StockDetailState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  StockDetailBloc() : super(StockDetailInitial()) {
    on<LoadStockDetail>(_onLoadStockDetail);
    on<RefreshStockDetail>(_onRefreshStockDetail);
  }

  Future<void> _onLoadStockDetail(
    LoadStockDetail event,
    Emitter<StockDetailState> emit,
  ) async {
    emit(StockDetailLoading());
    await _loadData(event.assetSymbol, emit);
  }

  Future<void> _onRefreshStockDetail(
    RefreshStockDetail event,
    Emitter<StockDetailState> emit,
  ) async {
    // Keep current state while refreshing
    await _loadData(event.assetSymbol, emit);
  }

  Future<void> _loadData(
    String assetSymbol,
    Emitter<StockDetailState> emit,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        emit(const StockDetailError('User not authenticated'));
        return;
      }

      developer.log('Loading stock detail for $assetSymbol', name: 'StockDetailBloc');

      // Fetch holding for this stock
      final holdingResponse = await _supabase
          .from('holdings')
          .select()
          .eq('user_id', userId)
          .eq('asset_symbol', assetSymbol)
          .maybeSingle();

      Holding? holding;
      if (holdingResponse != null) {
        holding = Holding.fromJson(holdingResponse);
        developer.log('Found holding: ${holding.quantity} shares', name: 'StockDetailBloc');
      } else {
        developer.log('No holding found for $assetSymbol', name: 'StockDetailBloc');
      }

      // Fetch all transactions for this stock
      final transactionsResponse = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .eq('asset_symbol', assetSymbol)
          .order('created_at', ascending: false);

      final transactions = (transactionsResponse as List)
          .map((json) => Transaction.fromJson(json))
          .toList();

      developer.log('Found ${transactions.length} transactions', name: 'StockDetailBloc');

      emit(StockDetailLoaded(
        holding: holding,
        transactions: transactions,
        assetSymbol: assetSymbol,
      ));
    } catch (e, st) {
      developer.log(
        'Error loading stock detail',
        name: 'StockDetailBloc',
        error: e,
        stackTrace: st,
      );
      emit(StockDetailError('Failed to load stock details: $e'));
    }
  }
}
