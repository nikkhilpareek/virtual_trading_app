import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// Transaction Events
abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

/// Load transactions
class LoadTransactions extends TransactionEvent {
  final int limit;
  final int offset;

  const LoadTransactions({
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [limit, offset];
}

/// Execute buy order
class ExecuteBuyOrder extends TransactionEvent {
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;
  final double quantity;
  final double pricePerUnit;

  const ExecuteBuyOrder({
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
    required this.quantity,
    required this.pricePerUnit,
  });

  @override
  List<Object?> get props => [
        assetSymbol,
        assetName,
        assetType,
        quantity,
        pricePerUnit,
      ];
}

/// Execute sell order
class ExecuteSellOrder extends TransactionEvent {
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;
  final double quantity;
  final double pricePerUnit;

  const ExecuteSellOrder({
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
    required this.quantity,
    required this.pricePerUnit,
  });

  @override
  List<Object?> get props => [
        assetSymbol,
        assetName,
        assetType,
        quantity,
        pricePerUnit,
      ];
}

/// Filter transactions by type
class FilterTransactionsByType extends TransactionEvent {
  final TransactionType? transactionType;

  const FilterTransactionsByType(this.transactionType);

  @override
  List<Object?> get props => [transactionType];
}

/// Load transactions for specific asset
class LoadTransactionsByAsset extends TransactionEvent {
  final String assetSymbol;

  const LoadTransactionsByAsset(this.assetSymbol);

  @override
  List<Object?> get props => [assetSymbol];
}
