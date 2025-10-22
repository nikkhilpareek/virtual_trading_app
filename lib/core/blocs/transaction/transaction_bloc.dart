import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/repositories.dart';
import '../../models/models.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

/// Transaction BLoC
/// Manages transaction history and trading operations
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository _transactionRepository;
  TransactionType? _currentFilter;

  TransactionBloc({TransactionRepository? transactionRepository})
      : _transactionRepository =
            transactionRepository ?? TransactionRepository(),
        super(const TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<ExecuteBuyOrder>(_onExecuteBuyOrder);
    on<ExecuteSellOrder>(_onExecuteSellOrder);
    on<FilterTransactionsByType>(_onFilterTransactionsByType);
    on<LoadTransactionsByAsset>(_onLoadTransactionsByAsset);
  }

  /// Load transactions
  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      final transactions = await _transactionRepository.getTransactions(
        limit: event.limit,
        offset: event.offset,
      );

      if (transactions.isEmpty) {
        emit(const TransactionEmpty());
        return;
      }

      emit(TransactionLoaded(
        transactions: transactions,
        filterType: _currentFilter,
      ));
    } catch (e) {
      emit(TransactionError('Error loading transactions: ${e.toString()}'));
    }
  }

  /// Execute buy order
  Future<void> _onExecuteBuyOrder(
    ExecuteBuyOrder event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionExecuting('Processing buy order...'));
    try {
      final transaction = await _transactionRepository.executeBuyOrder(
        assetSymbol: event.assetSymbol,
        assetName: event.assetName,
        assetType: event.assetType,
        quantity: event.quantity,
        pricePerUnit: event.pricePerUnit,
      );

      if (transaction != null) {
        emit(TransactionSuccess(
          transaction: transaction,
          message:
              'Successfully bought ${event.quantity} ${event.assetSymbol}',
        ));
        
        // Reload transactions after success
        add(const LoadTransactions());
      } else {
        emit(const TransactionError('Failed to execute buy order'));
      }
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  /// Execute sell order
  Future<void> _onExecuteSellOrder(
    ExecuteSellOrder event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionExecuting('Processing sell order...'));
    try {
      final transaction = await _transactionRepository.executeSellOrder(
        assetSymbol: event.assetSymbol,
        assetName: event.assetName,
        assetType: event.assetType,
        quantity: event.quantity,
        pricePerUnit: event.pricePerUnit,
      );

      if (transaction != null) {
        emit(TransactionSuccess(
          transaction: transaction,
          message: 'Successfully sold ${event.quantity} ${event.assetSymbol}',
        ));
        
        // Reload transactions after success
        add(const LoadTransactions());
      } else {
        emit(const TransactionError('Failed to execute sell order'));
      }
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  /// Filter transactions by type
  Future<void> _onFilterTransactionsByType(
    FilterTransactionsByType event,
    Emitter<TransactionState> emit,
  ) async {
    _currentFilter = event.transactionType;

    if (state is TransactionLoaded) {
      final currentState = state as TransactionLoaded;
      emit(TransactionLoaded(
        transactions: currentState.transactions,
        filterType: _currentFilter,
      ));
    } else {
      add(const LoadTransactions());
    }
  }

  /// Load transactions for specific asset
  Future<void> _onLoadTransactionsByAsset(
    LoadTransactionsByAsset event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    try {
      final transactions =
          await _transactionRepository.getTransactionsByAsset(event.assetSymbol);

      if (transactions.isEmpty) {
        emit(const TransactionEmpty());
        return;
      }

      emit(TransactionLoaded(
        transactions: transactions,
        filterType: _currentFilter,
      ));
    } catch (e) {
      emit(TransactionError('Error loading transactions: ${e.toString()}'));
    }
  }
}
