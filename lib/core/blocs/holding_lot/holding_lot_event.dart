import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// Holding Lot Events
abstract class HoldingLotEvent extends Equatable {
  const HoldingLotEvent();

  @override
  List<Object?> get props => [];
}

/// Load lots for a specific asset
class LoadLotsBySymbol extends HoldingLotEvent {
  final String assetSymbol;

  const LoadLotsBySymbol(this.assetSymbol);

  @override
  List<Object?> get props => [assetSymbol];
}

/// Load all lots for user
class LoadAllLots extends HoldingLotEvent {
  const LoadAllLots();
}

/// Load lots by asset type
class LoadLotsByType extends HoldingLotEvent {
  final AssetType assetType;

  const LoadLotsByType(this.assetType);

  @override
  List<Object?> get props => [assetType];
}

/// Update current price for lots
class UpdateLotsPrices extends HoldingLotEvent {
  final String assetSymbol;
  final double newPrice;

  const UpdateLotsPrices({required this.assetSymbol, required this.newPrice});

  @override
  List<Object?> get props => [assetSymbol, newPrice];
}

/// Refresh lots
class RefreshLots extends HoldingLotEvent {
  final String? assetSymbol;

  const RefreshLots({this.assetSymbol});

  @override
  List<Object?> get props => [assetSymbol];
}
