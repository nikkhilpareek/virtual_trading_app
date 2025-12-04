import '../services/local_price_service.dart';
import '../repositories/holdings_repository.dart';
import 'dart:developer' as developer;

/// Helper to update holdings prices from local JSON
class PriceUpdater {
  final LocalPriceService _priceService = LocalPriceService();
  final HoldingsRepository _holdingsRepo = HoldingsRepository();

  /// Initialize and load local prices
  Future<void> initialize() async {
    await _priceService.loadPrices();
    developer.log('PriceUpdater initialized', name: 'PriceUpdater');
  }

  /// Update all holdings with latest prices from JSON
  Future<void> updateAllHoldingPrices() async {
    try {
      final holdings = await _holdingsRepo.getHoldings();

      for (final holding in holdings) {
        final currentPrice = _priceService.getCurrentPrice(holding.assetSymbol);
        if (currentPrice != null) {
          await _holdingsRepo.updateCurrentPrice(
            holding.assetSymbol,
            currentPrice,
          );
          developer.log(
            'Updated ${holding.assetSymbol} to $currentPrice',
            name: 'PriceUpdater',
          );
        }
      }
    } catch (e, st) {
      developer.log(
        'Error updating holding prices',
        name: 'PriceUpdater',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Get current price for a symbol
  double? getCurrentPrice(String symbol) {
    return _priceService.getCurrentPrice(symbol);
  }

  /// Get price change percentage
  double getChangePercent(String symbol) {
    return _priceService.getChangePercent(symbol);
  }
}
