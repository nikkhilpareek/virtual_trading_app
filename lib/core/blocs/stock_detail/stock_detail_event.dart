import 'package:equatable/equatable.dart';
import '../../models/holding.dart';
import '../../models/transaction.dart';

/// Stock Detail Events
abstract class StockDetailEvent extends Equatable {
  const StockDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Load stock details and transaction history for a specific symbol
class LoadStockDetail extends StockDetailEvent {
  final String assetSymbol;

  const LoadStockDetail(this.assetSymbol);

  @override
  List<Object?> get props => [assetSymbol];
}

/// Refresh stock details and transaction history
class RefreshStockDetail extends StockDetailEvent {
  final String assetSymbol;

  const RefreshStockDetail(this.assetSymbol);

  @override
  List<Object?> get props => [assetSymbol];
}
