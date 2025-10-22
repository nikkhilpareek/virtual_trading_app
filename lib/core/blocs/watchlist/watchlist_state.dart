import 'package:equatable/equatable.dart';
import '../../models/models.dart';

/// Watchlist States
abstract class WatchlistState extends Equatable {
  const WatchlistState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class WatchlistInitial extends WatchlistState {
  const WatchlistInitial();
}

/// Loading state
class WatchlistLoading extends WatchlistState {
  const WatchlistLoading();
}

/// Loaded state with watchlist items
class WatchlistLoaded extends WatchlistState {
  final List<WatchlistItem> items;
  final AssetType? filterType;

  const WatchlistLoaded({
    required this.items,
    this.filterType,
  });

  /// Get filtered items
  List<WatchlistItem> get filteredItems {
    if (filterType == null) return items;
    return items.where((item) => item.assetType == filterType).toList();
  }

  /// Check if asset is in watchlist
  bool isWatched(String assetSymbol) {
    return items.any((item) => item.assetSymbol == assetSymbol);
  }

  @override
  List<Object?> get props => [items, filterType];
}

/// Empty state (no watchlist items)
class WatchlistEmpty extends WatchlistState {
  const WatchlistEmpty();
}

/// Adding/removing state
class WatchlistUpdating extends WatchlistState {
  final String message;

  const WatchlistUpdating(this.message);

  @override
  List<Object?> get props => [message];
}

/// Success state
class WatchlistSuccess extends WatchlistState {
  final String message;
  final List<WatchlistItem> items;

  const WatchlistSuccess({
    required this.message,
    required this.items,
  });

  @override
  List<Object?> get props => [message, items];
}

/// Error state
class WatchlistError extends WatchlistState {
  final String message;

  const WatchlistError(this.message);

  @override
  List<Object?> get props => [message];
}
