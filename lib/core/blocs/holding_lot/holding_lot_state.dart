import 'package:equatable/equatable.dart';

/// Holding Lot States
/// DEPRECATED - Use HoldingsBloc instead
abstract class HoldingLotState extends Equatable {
  const HoldingLotState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HoldingLotInitial extends HoldingLotState {
  const HoldingLotInitial();
}

/// Loading state
class HoldingLotLoading extends HoldingLotState {
  const HoldingLotLoading();
}

/// Lots loaded successfully
class HoldingLotsLoaded extends HoldingLotState {
  final List<dynamic> lots;
  final String? assetSymbol;

  const HoldingLotsLoaded({required this.lots, this.assetSymbol});

  @override
  List<Object?> get props => [lots, assetSymbol];

  /// Get total quantity across all lots
  double get totalQuantity =>
      lots.fold(0.0, (sum, lot) => sum + (lot?.quantity ?? 0.0));

  /// Get total invested across all lots
  double get totalInvested =>
      lots.fold(0.0, (sum, lot) => sum + (lot?.totalInvested ?? 0.0));

  /// Get total current value across all lots
  double get totalCurrentValue =>
      lots.fold(0.0, (sum, lot) => sum + (lot?.currentValue ?? 0.0));

  /// Get total profit/loss across all lots
  double get totalProfitLoss =>
      lots.fold(0.0, (sum, lot) => sum + (lot?.profitLoss ?? 0.0));

  /// Get weighted average purchase price
  double get averagePurchasePrice {
    if (totalQuantity == 0) return 0;
    return totalInvested / totalQuantity;
  }

  /// Get profit/loss percentage
  double get profitLossPercentage {
    if (totalInvested == 0) return 0;
    return (totalProfitLoss / totalInvested) * 100;
  }

  /// Get profitable lots
  List<dynamic> get profitableLots =>
      lots.where((lot) => lot != null && lot.isProfitable).toList();

  /// Get loss-making lots
  List<dynamic> get lossLots =>
      lots.where((lot) => lot != null && lot.isLoss).toList();

  /// Get break-even lots
  List<dynamic> get breakEvenLots => lots
      .where((lot) => lot != null && !lot.isProfitable && !lot.isLoss)
      .toList();
}

/// No lots found
class HoldingLotsEmpty extends HoldingLotState {
  const HoldingLotsEmpty();
}

/// Error state
class HoldingLotError extends HoldingLotState {
  final String message;

  const HoldingLotError(this.message);

  @override
  List<Object?> get props => [message];
}
