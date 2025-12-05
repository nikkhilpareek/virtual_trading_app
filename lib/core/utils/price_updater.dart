import '../services/local_price_service.dart';
import '../repositories/holdings_repository.dart';
import 'dart:developer' as developer;

/// Helper to update holdings prices from local JSON
class PriceUpdater {
  final LocalPriceService _priceService = LocalPriceService();
  final HoldingsRepository _holdingsRepo = HoldingsRepository();

  /// Initialize - LocalPriceService loads on demand
  Future<void> initialize() async {
    developer.log('PriceUpdater initialized', name: 'PriceUpdater');
  }

  /// Update all holdings with latest prices from JSON
  Future<void> updateAllHoldingPrices() async {
    try {
      final holdings = await _holdingsRepo.getHoldings();
      final symbols = holdings.map((h) => h.assetSymbol).toList();
      final prices = await _priceService.getBatchStockPrices(symbols);

      for (final holding in holdings) {
        final currentPrice = prices[holding.assetSymbol];
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
  Future<double?> getCurrentPrice(String symbol) async {
    return await _priceService.getStockPrice(symbol);
  }
}
