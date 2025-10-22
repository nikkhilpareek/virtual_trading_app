import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/repositories.dart';
import '../../models/models.dart';
import 'holdings_event.dart';
import 'holdings_state.dart';

/// Holdings BLoC
/// Manages portfolio holdings state
class HoldingsBloc extends Bloc<HoldingsEvent, HoldingsState> {
  final HoldingsRepository _holdingsRepository;
  AssetType? _currentFilter;

  HoldingsBloc({HoldingsRepository? holdingsRepository})
      : _holdingsRepository = holdingsRepository ?? HoldingsRepository(),
        super(const HoldingsInitial()) {
    on<LoadHoldings>(_onLoadHoldings);
    on<RefreshHoldings>(_onRefreshHoldings);
    on<UpdateHoldingPrice>(_onUpdateHoldingPrice);
    on<FilterHoldingsByType>(_onFilterHoldingsByType);
  }

  /// Load holdings
  Future<void> _onLoadHoldings(
    LoadHoldings event,
    Emitter<HoldingsState> emit,
  ) async {
    emit(const HoldingsLoading());
    try {
      final holdings = await _holdingsRepository.getHoldings();
      
      if (holdings.isEmpty) {
        emit(const HoldingsEmpty());
        return;
      }

      final totalValue = await _holdingsRepository.getTotalPortfolioValue();
      final totalInvested = await _holdingsRepository.getTotalInvested();
      final totalPnL = await _holdingsRepository.getTotalProfitLoss();

      emit(HoldingsLoaded(
        holdings: holdings,
        filterType: _currentFilter,
        totalValue: totalValue,
        totalInvested: totalInvested,
        totalProfitLoss: totalPnL,
      ));
    } catch (e) {
      emit(HoldingsError('Error loading holdings: ${e.toString()}'));
    }
  }

  /// Refresh holdings
  Future<void> _onRefreshHoldings(
    RefreshHoldings event,
    Emitter<HoldingsState> emit,
  ) async {
    try {
      final holdings = await _holdingsRepository.getHoldings();
      
      if (holdings.isEmpty) {
        emit(const HoldingsEmpty());
        return;
      }

      final totalValue = await _holdingsRepository.getTotalPortfolioValue();
      final totalInvested = await _holdingsRepository.getTotalInvested();
      final totalPnL = await _holdingsRepository.getTotalProfitLoss();

      emit(HoldingsLoaded(
        holdings: holdings,
        filterType: _currentFilter,
        totalValue: totalValue,
        totalInvested: totalInvested,
        totalProfitLoss: totalPnL,
      ));
    } catch (e) {
      emit(HoldingsError('Error refreshing holdings: ${e.toString()}'));
    }
  }

  /// Update holding price
  Future<void> _onUpdateHoldingPrice(
    UpdateHoldingPrice event,
    Emitter<HoldingsState> emit,
  ) async {
    if (state is HoldingsLoaded) {
      try {
        await _holdingsRepository.updateCurrentPrice(
          event.assetSymbol,
          event.newPrice,
        );
        
        // Reload holdings to get updated values
        add(const RefreshHoldings());
      } catch (e) {
        emit(HoldingsError('Error updating price: ${e.toString()}'));
      }
    }
  }

  /// Filter holdings by type
  Future<void> _onFilterHoldingsByType(
    FilterHoldingsByType event,
    Emitter<HoldingsState> emit,
  ) async {
    _currentFilter = event.assetType;
    
    if (state is HoldingsLoaded) {
      final currentState = state as HoldingsLoaded;
      emit(HoldingsLoaded(
        holdings: currentState.holdings,
        filterType: _currentFilter,
        totalValue: currentState.totalValue,
        totalInvested: currentState.totalInvested,
        totalProfitLoss: currentState.totalProfitLoss,
      ));
    } else {
      add(const LoadHoldings());
    }
  }
}
