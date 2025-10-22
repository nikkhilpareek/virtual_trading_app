import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// Holdings Events
abstract class HoldingsEvent extends Equatable {
  const HoldingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all holdings
class LoadHoldings extends HoldingsEvent {
  const LoadHoldings();
}

/// Refresh holdings
class RefreshHoldings extends HoldingsEvent {
  const RefreshHoldings();
}

/// Update price for a holding
class UpdateHoldingPrice extends HoldingsEvent {
  final String assetSymbol;
  final double newPrice;

  const UpdateHoldingPrice({
    required this.assetSymbol,
    required this.newPrice,
  });

  @override
  List<Object?> get props => [assetSymbol, newPrice];
}

/// Filter holdings by type
class FilterHoldingsByType extends HoldingsEvent {
  final AssetType? assetType;

  const FilterHoldingsByType(this.assetType);

  @override
  List<Object?> get props => [assetType];
}
