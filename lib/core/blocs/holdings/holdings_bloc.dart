import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/repositories.dart';
import '../../models/models.dart';
import '../../services/freecrypto_service.dart';
import '../../services/local_price_service.dart';
import 'holdings_event.dart';
import 'holdings_state.dart';
import 'dart:developer' as developer;

/// Holdings BLoC
/// Manages portfolio holdings state
class HoldingsBloc extends Bloc<HoldingsEvent, HoldingsState> {
  final HoldingsRepository _holdingsRepository;
  final FreeCryptoService _cryptoService = FreeCryptoService();
  final LocalPriceService _priceService = LocalPriceService();
  AssetType? _currentFilter;

  HoldingsBloc({HoldingsRepository? holdingsRepository})
    : _holdingsRepository = holdingsRepository ?? HoldingsRepository(),
      super(const HoldingsInitial()) {
    on<LoadHoldings>(_onLoadHoldings);
    on<RefreshHoldings>(_onRefreshHoldings);
    on<UpdateHoldingPrice>(_onUpdateHoldingPrice);
    on<FilterHoldingsByType>(_onFilterHoldingsByType);
  }

  /// Fetch live prices for all holdings
  Future<List<Holding>> _enrichHoldingsWithLivePrices(
    List<Holding> holdings,
  ) async {
    final enrichedHoldings = <Holding>[];

    for (var holding in holdings) {
      Holding updatedHolding = holding;

      // Fetch live price for crypto holdings
      if (holding.assetType.toString().contains('crypto')) {
        try {
          final cryptoQuote = await _cryptoService.getCryptoPrice(
            holding.assetSymbol,
          );
          if (cryptoQuote != null) {
            updatedHolding = updatedHolding.copyWith(
              currentPrice: cryptoQuote.price,
            );
            developer.log(
              'Updated crypto price for ${holding.assetSymbol} to ${cryptoQuote.price}',
              name: 'HoldingsBloc',
            );
          }
        } catch (e) {
          developer.log(
            'Error fetching live crypto price for ${holding.assetSymbol}: $e',
            name: 'HoldingsBloc',
          );
        }
      }
      // Fetch live price for stock holdings
      else if (holding.assetType.toString().contains('stock')) {
        try {
          final price = await _priceService.getStockPrice(holding.assetSymbol);
          if (price != null) {
            updatedHolding = updatedHolding.copyWith(currentPrice: price);
            developer.log(
              'Updated stock price for ${holding.assetSymbol} to $price',
              name: 'HoldingsBloc',
            );
          }
        } catch (e) {
          developer.log(
            'Error fetching live stock price for ${holding.assetSymbol}: $e',
            name: 'HoldingsBloc',
          );
        }
      }

      enrichedHoldings.add(updatedHolding);
    }

    return enrichedHoldings;
  }

  /// Load holdings
  Future<void> _onLoadHoldings(
    LoadHoldings event,
    Emitter<HoldingsState> emit,
  ) async {
    emit(const HoldingsLoading());
    try {
      var holdings = await _holdingsRepository.getHoldings();

      // Enrich holdings with live prices
      holdings = await _enrichHoldingsWithLivePrices(holdings);

      if (holdings.isEmpty) {
        emit(const HoldingsEmpty());
        return;
      }

      final totalValue = holdings.fold<double>(
        0.0,
        (sum, holding) => sum + holding.currentValue,
      );
      final totalInvested = holdings.fold<double>(
        0.0,
        (sum, holding) => sum + holding.totalInvested,
      );
      final totalPnL = holdings.fold<double>(
        0.0,
        (sum, holding) => sum + holding.profitLoss,
      );

      emit(
        HoldingsLoaded(
          holdings: holdings,
          filterType: _currentFilter,
          totalValue: totalValue,
          totalInvested: totalInvested,
          totalProfitLoss: totalPnL,
        ),
      );
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
      var holdings = await _holdingsRepository.getHoldings();

      // Enrich holdings with live prices
      holdings = await _enrichHoldingsWithLivePrices(holdings);

      if (holdings.isEmpty) {
        emit(const HoldingsEmpty());
        return;
      }

      final totalValue = holdings.fold<double>(
        0.0,
        (sum, holding) => sum + holding.currentValue,
      );
      final totalInvested = holdings.fold<double>(
        0.0,
        (sum, holding) => sum + holding.totalInvested,
      );
      final totalPnL = holdings.fold<double>(
        0.0,
        (sum, holding) => sum + holding.profitLoss,
      );

      emit(
        HoldingsLoaded(
          holdings: holdings,
          filterType: _currentFilter,
          totalValue: totalValue,
          totalInvested: totalInvested,
          totalProfitLoss: totalPnL,
        ),
      );
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
      emit(
        HoldingsLoaded(
          holdings: currentState.holdings,
          filterType: _currentFilter,
          totalValue: currentState.totalValue,
          totalInvested: currentState.totalInvested,
          totalProfitLoss: currentState.totalProfitLoss,
        ),
      );
    } else {
      add(const LoadHoldings());
    }
  }
}
