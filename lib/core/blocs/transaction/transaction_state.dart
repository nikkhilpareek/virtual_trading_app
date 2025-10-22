import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// Transaction States
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TransactionInitial extends TransactionState {
  const TransactionInitial();
}

/// Loading state
class TransactionLoading extends TransactionState {
  const TransactionLoading();
}

/// Loaded state with transactions
class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final TransactionType? filterType;

  const TransactionLoaded({
    required this.transactions,
    this.filterType,
  });

  /// Get filtered transactions
  List<Transaction> get filteredTransactions {
    if (filterType == null) return transactions;
    return transactions
        .where((tx) => tx.transactionType == filterType)
        .toList();
  }

  @override
  List<Object?> get props => [transactions, filterType];
}

/// Empty state (no transactions)
class TransactionEmpty extends TransactionState {
  const TransactionEmpty();
}

/// Executing order state
class TransactionExecuting extends TransactionState {
  final String message;

  const TransactionExecuting(this.message);

  @override
  List<Object?> get props => [message];
}

/// Order executed successfully
class TransactionSuccess extends TransactionState {
  final Transaction transaction;
  final String message;

  const TransactionSuccess({
    required this.transaction,
    required this.message,
  });

  @override
  List<Object?> get props => [transaction, message];
}

/// Error state
class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}
