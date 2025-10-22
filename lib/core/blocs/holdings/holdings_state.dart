import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// Holdings States
abstract class HoldingsState extends Equatable {
  const HoldingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HoldingsInitial extends HoldingsState {
  const HoldingsInitial();
}

/// Loading state
class HoldingsLoading extends HoldingsState {
  const HoldingsLoading();
}

/// Loaded state with holdings list
class HoldingsLoaded extends HoldingsState {
  final List<Holding> holdings;
  final AssetType? filterType;
  final double totalValue;
  final double totalInvested;
  final double totalProfitLoss;

  const HoldingsLoaded({
    required this.holdings,
    this.filterType,
    required this.totalValue,
    required this.totalInvested,
    required this.totalProfitLoss,
  });

  /// Get filtered holdings
  List<Holding> get filteredHoldings {
    if (filterType == null) return holdings;
    return holdings.where((h) => h.assetType == filterType).toList();
  }

  /// Get total P&L percentage
  double get totalProfitLossPercentage {
    if (totalInvested == 0) return 0;
    return (totalProfitLoss / totalInvested) * 100;
  }

  /// Check if portfolio is profitable
  bool get isProfitable => totalProfitLoss > 0;

  @override
  List<Object?> get props => [
        holdings,
        filterType,
        totalValue,
        totalInvested,
        totalProfitLoss,
      ];
}

/// Empty state (no holdings)
class HoldingsEmpty extends HoldingsState {
  const HoldingsEmpty();
}

/// Error state
class HoldingsError extends HoldingsState {
  final String message;

  const HoldingsError(this.message);

  @override
  List<Object?> get props => [message];
}
