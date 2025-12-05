import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import '../repositories/holdings_repository.dart';
import '../repositories/transaction_repository.dart';
import 'yfinance_service.dart';
import 'local_price_service.dart';

/// Monitors prices for holdings and triggers full sells
/// when stop-loss is breached or price moves outside bracket.
class PriceMonitorService {
  static final PriceMonitorService _instance = PriceMonitorService._internal();
  factory PriceMonitorService() => _instance;
  PriceMonitorService._internal();

  final _supabase = Supabase.instance.client;
  final _holdingsRepo = HoldingsRepository();
  final _txRepo = TransactionRepository();
  final _yfin = YFinanceService();
  final _local = LocalPriceService();

  Timer? _timer;
  Duration interval = const Duration(seconds: 20);

  bool get _isAuthenticated => _supabase.auth.currentUser != null;

  void start({Duration? pollInterval}) {
    if (pollInterval != null) interval = pollInterval;
    _timer?.cancel();
    if (!_isAuthenticated) {
      developer.log('PriceMonitor: Not authenticated, skipping start');
      return;
    }
    developer.log(
      'PriceMonitor: Starting with interval ${interval.inSeconds}s',
    );
    _timer = Timer.periodic(interval, (_) => _tick());
    // Run immediately once
    _tick();
  }

  void stop() {
    developer.log('PriceMonitor: Stopping');
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    try {
      if (!_isAuthenticated) return;

      final holdings = await _holdingsRepo.getHoldings();
      if (holdings.isEmpty) return;

      // Split symbols by type for efficient fetching
      final stockSymbols = <String>[];
      final cryptoSymbols = <String>[];
      for (final h in holdings) {
        if (h.assetType == AssetType.crypto) {
          cryptoSymbols.add(h.assetSymbol);
        } else {
          stockSymbols.add(h.assetSymbol);
        }
      }

      final Map<String, double> latestPrices = {};

      final now = DateTime.now();
      final isWeekend =
          now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

      // Fetch in batch for stocks (fallback to local when weekend)
      if (stockSymbols.isNotEmpty) {
        if (isWeekend) {
          final local = await _local.getBatchStockPrices(stockSymbols);
          latestPrices.addAll(local);
        } else {
          final quotes = await _yfin.getMultipleStockQuotes(stockSymbols);
          for (final q in quotes) {
            latestPrices[q.symbol] = q.price;
          }
          // If backend returned empty for some, try local for missing ones
          final missing = stockSymbols
              .where((s) => !latestPrices.containsKey(s))
              .toList();
          if (missing.isNotEmpty) {
            final local = await _local.getBatchStockPrices(missing);
            latestPrices.addAll(local);
          }
        }
      }
      // Fetch individually for crypto (no batch endpoint)
      for (final sym in cryptoSymbols) {
        if (isWeekend) {
          final p = await _local.getStockPrice(
            sym,
          ); // reuse local source if crypto included
          if (p != null) latestPrices[sym] = p;
        } else {
          final q = await _yfin.getCryptoQuote(sym);
          if (q != null) latestPrices[sym] = q.price;
        }
      }

      for (final h in holdings) {
        final price = latestPrices[h.assetSymbol];
        if (price == null) continue;

        // Update current price in holdings for PnL visibility
        await _holdingsRepo.updateCurrentPrice(h.assetSymbol, price);

        final stop = h.stopLoss;
        final lower = h.bracketLower;
        final upper = h.bracketUpper;

        bool breach = false;
        String reason = '';

        if (stop != null && price <= stop) {
          breach = true;
          reason = 'Stop-loss ($stop) breached by $price';
        }
        if (!breach && (lower != null || upper != null)) {
          if (lower != null && price < lower) {
            breach = true;
            reason = 'Below bracket lower ($lower) at $price';
          } else if (upper != null && price > upper) {
            breach = true;
            reason = 'Above bracket upper ($upper) at $price';
          }
        }

        if (breach && h.quantity > 0) {
          developer.log(
            'PriceMonitor: Trigger SELL ${h.assetSymbol} qty=${h.quantity} @ $price ($reason)',
            name: 'PriceMonitorService',
          );

          // Execute sell for full holding
          try {
            await _txRepo.executeSellOrder(
              assetSymbol: h.assetSymbol,
              assetName: h.assetName,
              assetType: h.assetType,
              quantity: h.quantity,
              pricePerUnit: price,
            );

            // Clear risk rules after execution
            await _holdingsRepo.clearRiskRules(h.assetSymbol);
          } catch (e, st) {
            developer.log(
              'Auto-sell failed for ${h.assetSymbol}',
              error: e,
              stackTrace: st,
              name: 'PriceMonitorService',
            );
          }
        }
      }
    } catch (e, st) {
      developer.log(
        'PriceMonitor tick error',
        error: e,
        stackTrace: st,
        name: 'PriceMonitorService',
      );
    }
  }
}
