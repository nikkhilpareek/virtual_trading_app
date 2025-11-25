import 'package:equatable/equatable.dart';
import '../../services/freecrypto_service.dart';
import '../../models/holding.dart';

/// Crypto States
abstract class CryptoState extends Equatable {
  const CryptoState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CryptoInitial extends CryptoState {
  const CryptoInitial();
}

/// Loading cryptocurrency market data
class CryptoMarketLoading extends CryptoState {
  const CryptoMarketLoading();
}

/// Cryptocurrency market data loaded successfully
class CryptoMarketLoaded extends CryptoState {
  final List<CryptoQuote> cryptos;
  final DateTime lastUpdated;

  const CryptoMarketLoaded({required this.cryptos, required this.lastUpdated});

  @override
  List<Object?> get props => [cryptos, lastUpdated];
}

/// Error loading cryptocurrency market data
class CryptoMarketError extends CryptoState {
  final String message;

  const CryptoMarketError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Loading crypto holdings
class CryptoHoldingsLoading extends CryptoState {
  const CryptoHoldingsLoading();
}

/// Crypto holdings loaded successfully
class CryptoHoldingsLoaded extends CryptoState {
  final List<Holding> holdings;
  final Map<String, CryptoQuote> currentPrices;
  final double totalValue;
  final double totalInvested;
  final double totalProfitLoss;
  final double totalProfitLossPercentage;

  const CryptoHoldingsLoaded({
    required this.holdings,
    required this.currentPrices,
    required this.totalValue,
    required this.totalInvested,
    required this.totalProfitLoss,
    required this.totalProfitLossPercentage,
  });

  @override
  List<Object?> get props => [
    holdings,
    currentPrices,
    totalValue,
    totalInvested,
    totalProfitLoss,
    totalProfitLossPercentage,
  ];
}

/// Empty crypto holdings
class CryptoHoldingsEmpty extends CryptoState {
  const CryptoHoldingsEmpty();
}

/// Error loading crypto holdings
class CryptoHoldingsError extends CryptoState {
  final String message;

  const CryptoHoldingsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Combined state with both market and holdings data
class CryptoFullData extends CryptoState {
  final List<CryptoQuote> marketCryptos;
  final List<Holding> holdings;
  final Map<String, CryptoQuote> currentPrices;
  final double totalValue;
  final double totalInvested;
  final double totalProfitLoss;
  final double totalProfitLossPercentage;
  final DateTime lastUpdated;

  const CryptoFullData({
    required this.marketCryptos,
    required this.holdings,
    required this.currentPrices,
    required this.totalValue,
    required this.totalInvested,
    required this.totalProfitLoss,
    required this.totalProfitLossPercentage,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    marketCryptos,
    holdings,
    currentPrices,
    totalValue,
    totalInvested,
    totalProfitLoss,
    totalProfitLossPercentage,
    lastUpdated,
  ];
}

/// Trading in progress
class CryptoTrading extends CryptoState {
  const CryptoTrading();
}

/// Trade completed successfully
class CryptoTradeSuccess extends CryptoState {
  final String message;
  final bool isBuy;

  const CryptoTradeSuccess({required this.message, required this.isBuy});

  @override
  List<Object?> get props => [message, isBuy];
}

/// Trade failed
class CryptoTradeError extends CryptoState {
  final String message;

  const CryptoTradeError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Search results
class CryptoSearchResults extends CryptoState {
  final List<CryptoSearchResult> results;
  final String query;

  const CryptoSearchResults({required this.results, required this.query});

  @override
  List<Object?> get props => [results, query];
}
