import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// Watchlist Events
abstract class WatchlistEvent extends Equatable {
  const WatchlistEvent();

  @override
  List<Object?> get props => [];
}

/// Load watchlist
class LoadWatchlist extends WatchlistEvent {
  const LoadWatchlist();
}

/// Add to watchlist
class AddToWatchlist extends WatchlistEvent {
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;

  const AddToWatchlist({
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
  });

  @override
  List<Object?> get props => [assetSymbol, assetName, assetType];
}

/// Remove from watchlist
class RemoveFromWatchlist extends WatchlistEvent {
  final String assetSymbol;

  const RemoveFromWatchlist(this.assetSymbol);

  @override
  List<Object?> get props => [assetSymbol];
}

/// Toggle watchlist
class ToggleWatchlist extends WatchlistEvent {
  final String assetSymbol;
  final String assetName;
  final AssetType assetType;

  const ToggleWatchlist({
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
  });

  @override
  List<Object?> get props => [assetSymbol, assetName, assetType];
}

/// Filter watchlist by type
class FilterWatchlistByType extends WatchlistEvent {
  final AssetType? assetType;

  const FilterWatchlistByType(this.assetType);

  @override
  List<Object?> get props => [assetType];
}

/// Clear watchlist
class ClearWatchlist extends WatchlistEvent {
  const ClearWatchlist();
}
