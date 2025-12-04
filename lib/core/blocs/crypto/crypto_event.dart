import 'package:equatable/equatable.dart';

/// Crypto Events
abstract class CryptoEvent extends Equatable {
  const CryptoEvent();

  @override
  List<Object?> get props => [];
}

/// Load cryptocurrency market data
class LoadCryptoMarket extends CryptoEvent {
  final int limit;
  final String currency;

  const LoadCryptoMarket({this.limit = 20, this.currency = 'USD'});

  @override
  List<Object?> get props => [limit, currency];
}

/// Refresh cryptocurrency market data
class RefreshCryptoMarket extends CryptoEvent {
  final int limit;
  final String currency;

  const RefreshCryptoMarket({this.limit = 20, this.currency = 'USD'});

  @override
  List<Object?> get props => [limit, currency];
}

/// Update price for a specific cryptocurrency
class UpdateCryptoPrice extends CryptoEvent {
  final String symbol;
  final String currency;

  const UpdateCryptoPrice({required this.symbol, this.currency = 'USD'});

  @override
  List<Object?> get props => [symbol, currency];
}

/// Search cryptocurrencies
class SearchCrypto extends CryptoEvent {
  final String query;

  const SearchCrypto(this.query);

  @override
  List<Object?> get props => [query];
}

/// Buy cryptocurrency
class BuyCrypto extends CryptoEvent {
  final String symbol;
  final String name;
  final double quantity;
  final double price;

  const BuyCrypto({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.price,
  });

  @override
  List<Object?> get props => [symbol, name, quantity, price];
}

/// Sell cryptocurrency
class SellCrypto extends CryptoEvent {
  final String symbol;
  final double quantity;
  final double price;

  const SellCrypto({
    required this.symbol,
    required this.quantity,
    required this.price,
  });

  @override
  List<Object?> get props => [symbol, quantity, price];
}

/// Load user's crypto holdings
class LoadCryptoHoldings extends CryptoEvent {
  const LoadCryptoHoldings();
}

/// Refresh user's crypto holdings with current prices
class RefreshCryptoHoldings extends CryptoEvent {
  const RefreshCryptoHoldings();
}
