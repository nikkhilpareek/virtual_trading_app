import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/freecrypto_service.dart';
import '../../repositories/holdings_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/user_repository.dart';
import '../../models/models.dart';
import 'crypto_event.dart';
import 'crypto_state.dart';
import 'dart:developer' as developer;

/// Crypto BLoC
/// Manages cryptocurrency market data, holdings, and trading operations
class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final FreeCryptoService _cryptoService;
  final HoldingsRepository _holdingsRepository;
  final TransactionRepository _transactionRepository;
  final UserRepository _userRepository;

  CryptoBloc({
    FreeCryptoService? cryptoService,
    HoldingsRepository? holdingsRepository,
    TransactionRepository? transactionRepository,
    UserRepository? userRepository,
  }) : _cryptoService = cryptoService ?? FreeCryptoService(),
       _holdingsRepository = holdingsRepository ?? HoldingsRepository(),
       _transactionRepository =
           transactionRepository ?? TransactionRepository(),
       _userRepository = userRepository ?? UserRepository(),
       super(const CryptoInitial()) {
    on<LoadCryptoMarket>(_onLoadCryptoMarket);
    on<RefreshCryptoMarket>(_onRefreshCryptoMarket);
    on<UpdateCryptoPrice>(_onUpdateCryptoPrice);
    on<SearchCrypto>(_onSearchCrypto);
    on<BuyCrypto>(_onBuyCrypto);
    on<SellCrypto>(_onSellCrypto);
    on<LoadCryptoHoldings>(_onLoadCryptoHoldings);
    on<RefreshCryptoHoldings>(_onRefreshCryptoHoldings);
  }

  /// Load cryptocurrency market data
  Future<void> _onLoadCryptoMarket(
    LoadCryptoMarket event,
    Emitter<CryptoState> emit,
  ) async {
    emit(const CryptoMarketLoading());

    try {
      final cryptos = await _cryptoService.getTopCryptos(
        currency: event.currency,
        limit: event.limit,
      );

      if (cryptos.isEmpty) {
        emit(const CryptoMarketError('No cryptocurrency data available'));
        return;
      }

      emit(CryptoMarketLoaded(cryptos: cryptos, lastUpdated: DateTime.now()));
    } catch (e) {
      developer.log('Error loading crypto market', error: e);
      emit(
        CryptoMarketError(
          'Failed to load cryptocurrency data: ${e.toString()}',
        ),
      );
    }
  }

  /// Refresh cryptocurrency market data
  Future<void> _onRefreshCryptoMarket(
    RefreshCryptoMarket event,
    Emitter<CryptoState> emit,
  ) async {
    try {
      final cryptos = await _cryptoService.getTopCryptos(
        currency: event.currency,
        limit: event.limit,
      );

      if (cryptos.isEmpty) {
        emit(const CryptoMarketError('No cryptocurrency data available'));
        return;
      }

      emit(CryptoMarketLoaded(cryptos: cryptos, lastUpdated: DateTime.now()));
    } catch (e) {
      developer.log('Error refreshing crypto market', error: e);
      emit(
        CryptoMarketError(
          'Failed to refresh cryptocurrency data: ${e.toString()}',
        ),
      );
    }
  }

  /// Update price for a specific cryptocurrency
  Future<void> _onUpdateCryptoPrice(
    UpdateCryptoPrice event,
    Emitter<CryptoState> emit,
  ) async {
    if (state is CryptoMarketLoaded) {
      final currentState = state as CryptoMarketLoaded;

      try {
        final updatedQuote = await _cryptoService.getCryptoPrice(
          event.symbol,
          currency: event.currency,
        );

        if (updatedQuote != null) {
          final updatedCryptos = currentState.cryptos.map((crypto) {
            if (crypto.symbol == event.symbol) {
              return updatedQuote;
            }
            return crypto;
          }).toList();

          emit(
            CryptoMarketLoaded(
              cryptos: updatedCryptos,
              lastUpdated: DateTime.now(),
            ),
          );
        }
      } catch (e) {
        developer.log(
          'Error updating crypto price for ${event.symbol}',
          error: e,
        );
        // Don't emit error, just keep current state
      }
    }
  }

  /// Search cryptocurrencies
  Future<void> _onSearchCrypto(
    SearchCrypto event,
    Emitter<CryptoState> emit,
  ) async {
    try {
      final results = await _cryptoService.searchCrypto(event.query);

      emit(CryptoSearchResults(results: results, query: event.query));
    } catch (e) {
      developer.log('Error searching crypto', error: e);
      emit(
        CryptoMarketError('Failed to search cryptocurrencies: ${e.toString()}'),
      );
    }
  }

  /// Buy cryptocurrency
  Future<void> _onBuyCrypto(BuyCrypto event, Emitter<CryptoState> emit) async {
    emit(const CryptoTrading());

    try {
      // Check user balance
      final profile = await _userRepository.getUserProfile();
      if (profile == null) {
        emit(const CryptoTradeError('User profile not found'));
        return;
      }

      final totalCost = event.quantity * event.price;

      if (profile.stonkBalance < totalCost) {
        emit(
          CryptoTradeError(
            'Insufficient balance. Required: ₹${totalCost.toStringAsFixed(2)}, Available: ₹${profile.stonkBalance.toStringAsFixed(2)}',
          ),
        );
        return;
      }

      // Deduct balance
      await _userRepository.deductFromBalance(totalCost);

      // Add or update holding
      await _holdingsRepository.addOrUpdateHolding(
        assetSymbol: event.symbol,
        assetName: event.name,
        assetType: AssetType.crypto,
        quantity: event.quantity,
        price: event.price,
      );

      // Record transaction via executeBuyOrder
      await _transactionRepository.executeBuyOrder(
        assetSymbol: event.symbol,
        assetName: event.name,
        assetType: AssetType.crypto,
        quantity: event.quantity,
        pricePerUnit: event.price,
      );

      emit(
        CryptoTradeSuccess(
          message: 'Successfully bought ${event.quantity} ${event.symbol}',
          isBuy: true,
        ),
      );

      // Reload holdings to update UI
      add(const LoadCryptoHoldings());
    } catch (e) {
      developer.log('Error buying crypto', error: e);
      emit(CryptoTradeError('Failed to buy cryptocurrency: ${e.toString()}'));
    }
  }

  /// Sell cryptocurrency
  Future<void> _onSellCrypto(
    SellCrypto event,
    Emitter<CryptoState> emit,
  ) async {
    emit(const CryptoTrading());

    try {
      // Check if user has this holding
      final holding = await _holdingsRepository.getHoldingBySymbol(
        event.symbol,
      );

      if (holding == null) {
        emit(CryptoTradeError('You don\'t own any ${event.symbol}'));
        return;
      }

      if (holding.quantity < event.quantity) {
        emit(
          CryptoTradeError(
            'Insufficient quantity. You have ${holding.quantity} ${event.symbol}',
          ),
        );
        return;
      }

      final totalValue = event.quantity * event.price;

      // Add balance
      await _userRepository.addToBalance(totalValue);

      // Update or remove holding using reduceHolding
      await _holdingsRepository.reduceHolding(
        assetSymbol: event.symbol,
        quantity: event.quantity,
        currentPrice: event.price,
      );

      // Record transaction via executeSellOrder
      await _transactionRepository.executeSellOrder(
        assetSymbol: event.symbol,
        assetName: holding.assetName,
        assetType: AssetType.crypto,
        quantity: event.quantity,
        pricePerUnit: event.price,
      );

      emit(
        CryptoTradeSuccess(
          message: 'Successfully sold ${event.quantity} ${event.symbol}',
          isBuy: false,
        ),
      );

      // Reload holdings to update UI
      add(const LoadCryptoHoldings());
    } catch (e) {
      developer.log('Error selling crypto', error: e);
      emit(CryptoTradeError('Failed to sell cryptocurrency: ${e.toString()}'));
    }
  }

  /// Load user's crypto holdings
  Future<void> _onLoadCryptoHoldings(
    LoadCryptoHoldings event,
    Emitter<CryptoState> emit,
  ) async {
    emit(const CryptoHoldingsLoading());

    try {
      // Get all holdings filtered by crypto type
      final allHoldings = await _holdingsRepository.getHoldings();
      final cryptoHoldings = allHoldings
          .where((h) => h.assetType == AssetType.crypto)
          .toList();

      if (cryptoHoldings.isEmpty) {
        emit(const CryptoHoldingsEmpty());
        return;
      }

      // Fetch current prices for all holdings
      final symbols = cryptoHoldings.map((h) => h.assetSymbol).toList();
      final pricesMap = await _cryptoService.getBatchCryptoPrices(symbols);

      // Update holdings with current prices
      for (var holding in cryptoHoldings) {
        if (pricesMap.containsKey(holding.assetSymbol)) {
          await _holdingsRepository.updateCurrentPrice(
            holding.assetSymbol,
            pricesMap[holding.assetSymbol]!.price,
          );
        }
      }

      // Recalculate totals
      double totalValue = 0;
      double totalInvested = 0;

      for (var holding in cryptoHoldings) {
        final currentPrice =
            pricesMap[holding.assetSymbol]?.price ?? holding.averagePrice;
        totalValue += holding.quantity * currentPrice;
        totalInvested += holding.totalInvested;
      }

      final totalPnL = totalValue - totalInvested;
      final totalPnLPercentage = totalInvested > 0
          ? (totalPnL / totalInvested) * 100
          : 0.0;

      emit(
        CryptoHoldingsLoaded(
          holdings: cryptoHoldings,
          currentPrices: pricesMap,
          totalValue: totalValue,
          totalInvested: totalInvested,
          totalProfitLoss: totalPnL,
          totalProfitLossPercentage: totalPnLPercentage.toDouble(),
        ),
      );
    } catch (e) {
      developer.log('Error loading crypto holdings', error: e);
      emit(CryptoHoldingsError('Failed to load holdings: ${e.toString()}'));
    }
  }

  /// Refresh user's crypto holdings with current prices
  Future<void> _onRefreshCryptoHoldings(
    RefreshCryptoHoldings event,
    Emitter<CryptoState> emit,
  ) async {
    // Same as load, but doesn't show loading state
    try {
      final allHoldings = await _holdingsRepository.getHoldings();
      final cryptoHoldings = allHoldings
          .where((h) => h.assetType == AssetType.crypto)
          .toList();

      if (cryptoHoldings.isEmpty) {
        emit(const CryptoHoldingsEmpty());
        return;
      }

      final symbols = cryptoHoldings.map((h) => h.assetSymbol).toList();
      final pricesMap = await _cryptoService.getBatchCryptoPrices(symbols);

      for (var holding in cryptoHoldings) {
        if (pricesMap.containsKey(holding.assetSymbol)) {
          await _holdingsRepository.updateCurrentPrice(
            holding.assetSymbol,
            pricesMap[holding.assetSymbol]!.price,
          );
        }
      }

      double totalValue = 0;
      double totalInvested = 0;

      for (var holding in cryptoHoldings) {
        final currentPrice =
            pricesMap[holding.assetSymbol]?.price ?? holding.averagePrice;
        totalValue += holding.quantity * currentPrice;
        totalInvested += holding.totalInvested;
      }

      final totalPnL = totalValue - totalInvested;
      final totalPnLPercentage = totalInvested > 0
          ? (totalPnL / totalInvested) * 100
          : 0.0;

      emit(
        CryptoHoldingsLoaded(
          holdings: cryptoHoldings,
          currentPrices: pricesMap,
          totalValue: totalValue,
          totalInvested: totalInvested,
          totalProfitLoss: totalPnL,
          totalProfitLossPercentage: totalPnLPercentage.toDouble(),
        ),
      );
    } catch (e) {
      developer.log('Error refreshing crypto holdings', error: e);
      emit(CryptoHoldingsError('Failed to refresh holdings: ${e.toString()}'));
    }
  }
}
