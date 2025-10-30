import 'package:equatable/equatable.dart';
import '../../models/holding.dart';
import '../../models/transaction.dart';

/// Stock Detail States
abstract class StockDetailState extends Equatable {
  const StockDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class StockDetailInitial extends StockDetailState {}

/// Loading stock details
class StockDetailLoading extends StockDetailState {}

/// Stock details loaded successfully
class StockDetailLoaded extends StockDetailState {
  final Holding? holding;
  final List<Transaction> transactions;
  final String assetSymbol;

  const StockDetailLoaded({
    this.holding,
    required this.transactions,
    required this.assetSymbol,
  });

  @override
  List<Object?> get props => [holding, transactions, assetSymbol];

  /// Check if user owns this stock
  bool get hasHolding => holding != null && holding!.quantity > 0;

  /// Get total quantity bought
  double get totalBought => transactions
      .where((t) => t.transactionType == TransactionType.buy)
      .fold(0.0, (sum, t) => sum + t.quantity);

  /// Get total quantity sold
  double get totalSold => transactions
      .where((t) => t.transactionType == TransactionType.sell)
      .fold(0.0, (sum, t) => sum + t.quantity);

  /// Get total amount invested
  double get totalInvested => transactions
      .where((t) => t.transactionType == TransactionType.buy)
      .fold(0.0, (sum, t) => sum + t.totalAmount);

  /// Get total amount received from selling
  double get totalReceived => transactions
      .where((t) => t.transactionType == TransactionType.sell)
      .fold(0.0, (sum, t) => sum + t.totalAmount);

  /// Get number of buy transactions
  int get buyTransactionCount => transactions
      .where((t) => t.transactionType == TransactionType.buy)
      .length;

  /// Get number of sell transactions
  int get sellTransactionCount => transactions
      .where((t) => t.transactionType == TransactionType.sell)
      .length;

  /// Create a copy with updated fields
  StockDetailLoaded copyWith({
    Holding? holding,
    List<Transaction>? transactions,
    String? assetSymbol,
  }) {
    return StockDetailLoaded(
      holding: holding ?? this.holding,
      transactions: transactions ?? this.transactions,
      assetSymbol: assetSymbol ?? this.assetSymbol,
    );
  }
}

/// Error loading stock details
class StockDetailError extends StockDetailState {
  final String message;

  const StockDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
