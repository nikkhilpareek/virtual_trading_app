import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/repositories.dart';
import '../../models/models.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

/// Watchlist BLoC
/// Manages watchlist state and operations
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  final WatchlistRepository _watchlistRepository;
  AssetType? _currentFilter;

  WatchlistBloc({WatchlistRepository? watchlistRepository})
      : _watchlistRepository = watchlistRepository ?? WatchlistRepository(),
        super(const WatchlistInitial()) {
    on<LoadWatchlist>(_onLoadWatchlist);
    on<AddToWatchlist>(_onAddToWatchlist);
    on<RemoveFromWatchlist>(_onRemoveFromWatchlist);
    on<ToggleWatchlist>(_onToggleWatchlist);
    on<FilterWatchlistByType>(_onFilterWatchlistByType);
    on<ClearWatchlist>(_onClearWatchlist);
  }

  /// Load watchlist
  Future<void> _onLoadWatchlist(
    LoadWatchlist event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(const WatchlistLoading());
    try {
      final items = await _watchlistRepository.getWatchlist();

      if (items.isEmpty) {
        emit(const WatchlistEmpty());
        return;
      }

      emit(WatchlistLoaded(
        items: items,
        filterType: _currentFilter,
      ));
    } catch (e) {
      emit(WatchlistError('Error loading watchlist: ${e.toString()}'));
    }
  }

  /// Add to watchlist
  Future<void> _onAddToWatchlist(
    AddToWatchlist event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(const WatchlistUpdating('Adding to watchlist...'));
    try {
      final item = await _watchlistRepository.addToWatchlist(
        assetSymbol: event.assetSymbol,
        assetName: event.assetName,
        assetType: event.assetType,
      );

      if (item != null) {
        final items = await _watchlistRepository.getWatchlist();
        emit(WatchlistSuccess(
          message: '${event.assetSymbol} added to watchlist',
          items: items,
        ));
        
        // Load watchlist after success
        add(const LoadWatchlist());
      } else {
        emit(const WatchlistError('Failed to add to watchlist'));
      }
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  /// Remove from watchlist
  Future<void> _onRemoveFromWatchlist(
    RemoveFromWatchlist event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(const WatchlistUpdating('Removing from watchlist...'));
    try {
      final success =
          await _watchlistRepository.removeFromWatchlist(event.assetSymbol);

      if (success) {
        final items = await _watchlistRepository.getWatchlist();
        emit(WatchlistSuccess(
          message: '${event.assetSymbol} removed from watchlist',
          items: items,
        ));
        
        // Load watchlist after success
        add(const LoadWatchlist());
      } else {
        emit(const WatchlistError('Failed to remove from watchlist'));
      }
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  /// Toggle watchlist
  Future<void> _onToggleWatchlist(
    ToggleWatchlist event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(const WatchlistUpdating('Updating watchlist...'));
    try {
      final success = await _watchlistRepository.toggleWatchlist(
        assetSymbol: event.assetSymbol,
        assetName: event.assetName,
        assetType: event.assetType,
      );

      if (success) {
        final items = await _watchlistRepository.getWatchlist();
        final isWatched = await _watchlistRepository.isInWatchlist(event.assetSymbol);
        
        emit(WatchlistSuccess(
          message: isWatched
              ? '${event.assetSymbol} added to watchlist'
              : '${event.assetSymbol} removed from watchlist',
          items: items,
        ));
        
        // Load watchlist after success
        add(const LoadWatchlist());
      } else {
        emit(const WatchlistError('Failed to update watchlist'));
      }
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }

  /// Filter watchlist by type
  Future<void> _onFilterWatchlistByType(
    FilterWatchlistByType event,
    Emitter<WatchlistState> emit,
  ) async {
    _currentFilter = event.assetType;

    if (state is WatchlistLoaded) {
      final currentState = state as WatchlistLoaded;
      emit(WatchlistLoaded(
        items: currentState.items,
        filterType: _currentFilter,
      ));
    } else {
      add(const LoadWatchlist());
    }
  }

  /// Clear watchlist
  Future<void> _onClearWatchlist(
    ClearWatchlist event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(const WatchlistUpdating('Clearing watchlist...'));
    try {
      final success = await _watchlistRepository.clearWatchlist();

      if (success) {
        emit(const WatchlistEmpty());
      } else {
        emit(const WatchlistError('Failed to clear watchlist'));
      }
    } catch (e) {
      emit(WatchlistError(e.toString()));
    }
  }
}
