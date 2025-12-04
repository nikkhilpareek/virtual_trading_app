import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../core/services/yfinance_service.dart';
import '../core/services/local_price_service.dart';
import '../core/utils/currency_formatter.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import 'dart:developer' as developer;

class MarketStockDetailScreen extends StatefulWidget {
  final String symbol;
  final String name;
  final AssetType assetType;

  const MarketStockDetailScreen({
    super.key,
    required this.symbol,
    required this.name,
    required this.assetType,
  });

  @override
  State<MarketStockDetailScreen> createState() =>
      _MarketStockDetailScreenState();
}

class _MarketStockDetailScreenState extends State<MarketStockDetailScreen> {
  final YFinanceService _yfinanceService = YFinanceService();
  final LocalPriceService _localPriceService = LocalPriceService();
  StockQuote? _stockQuote;
  CryptoQuote? _cryptoQuote;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  bool _isInWatchlist = false;
  bool _useLocalPrices = true;
  double? _localPrice;
  double? _localChangePercent;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadStockDetails(silent: true);
      }
    });
  }

  Future<void> _initializeAndLoadData() async {
    try {
      await _localPriceService.loadPrices();
      _loadStockDetails();
    } catch (e) {
      developer.log(
        'Error loading local prices: $e',
        name: 'MarketStockDetail',
      );
      setState(() {
        _useLocalPrices = false;
      });
      _loadStockDetails();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStockDetails({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      if (widget.assetType == AssetType.stock && _useLocalPrices) {
        // Use local JSON prices for stocks
        final price = _localPriceService.getCurrentPrice(widget.symbol);
        final changePercent = _localPriceService.getChangePercent(
          widget.symbol,
        );

        if (mounted) {
          setState(() {
            _localPrice = price;
            _localChangePercent = changePercent;
            _isLoading = false;
          });
        }
        developer.log('Loaded local price for ${widget.symbol}: ₹$price');
      } else if (widget.assetType == AssetType.crypto) {
        final quote = await _yfinanceService.getCryptoQuote(widget.symbol);
        if (mounted) {
          setState(() {
            _cryptoQuote = quote;
            _isLoading = false;
          });
        }
      } else {
        // Fallback to API for stocks
        final quote = await _yfinanceService.getStockQuote(widget.symbol);
        if (mounted) {
          setState(() {
            _stockQuote = quote;
            _isLoading = false;
          });
        }
      }
      developer.log('Loaded details for ${widget.symbol}');
    } catch (e) {
      developer.log('Error loading stock details: $e');
      if (mounted && !silent) {
        setState(() {
          _errorMessage = 'Failed to load stock details';
          _isLoading = false;
        });
      }
    }
  }

  void _showTradeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TradeBottomSheet(
        symbol: widget.symbol,
        name: widget.name,
        assetType: widget.assetType,
        currentPrice: _getCurrentPrice(),
      ),
    );
  }

  double _getCurrentPrice() {
    if (widget.assetType == AssetType.crypto) {
      return _cryptoQuote?.price ?? 0;
    }
    if (_useLocalPrices && _localPrice != null) {
      return _localPrice!;
    }
    return _stockQuote?.price ?? 0;
  }

  double _getChangePercent() {
    if (widget.assetType == AssetType.crypto) {
      return _cryptoQuote?.changePercent ?? 0;
    }
    if (_useLocalPrices && _localChangePercent != null) {
      return _localChangePercent!;
    }
    return _stockQuote?.changePercent ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: const TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              widget.name,
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withAlpha((0.6 * 255).round()),
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<WatchlistBloc, WatchlistState>(
            builder: (context, state) {
              if (state is WatchlistLoaded) {
                _isInWatchlist = state.items.any(
                  (item) => item.assetSymbol == widget.symbol,
                );
              }
              return IconButton(
                icon: Icon(
                  _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                  color: _isInWatchlist
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                ),
                onPressed: () {
                  context.read<WatchlistBloc>().add(
                    ToggleWatchlist(
                      assetSymbol: widget.symbol,
                      assetName: widget.name,
                      assetType: widget.assetType,
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadStockDetails(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white.withAlpha((0.3 * 255).round()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _loadStockDetails(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadStockDetails(),
              color: Theme.of(context).colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price Card
                    _buildPriceCard(),

                    const SizedBox(height: 20),

                    // Buy Button Only
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showTradeDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Buy',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Market Stats
                    if (_stockQuote != null) _buildMarketStats(),

                    if (_cryptoQuote != null) _buildCryptoStats(),

                    const SizedBox(height: 24),

                    // About Section
                    _buildAboutSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPriceCard() {
    final currentPrice = _getCurrentPrice();
    final changePercent = _getChangePercent();
    final isPositive = changePercent >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.15 * 255).round()),
            Theme.of(
              context,
            ).colorScheme.primary.withAlpha((0.05 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.primary.withAlpha((0.2 * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Price',
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withAlpha((0.6 * 255).round()),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatINR(currentPrice),
            style: const TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withAlpha(
                (0.2 * 255).round(),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  CurrencyFormatter.formatPercentage(changePercent),
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Today',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: (isPositive ? Colors.green : Colors.red).withAlpha(
                      (0.8 * 255).round(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStats() {
    final quote = _stockQuote!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Market Statistics',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatsGrid([
          _StatItem('Open', CurrencyFormatter.formatINR(quote.open)),
          _StatItem('High', CurrencyFormatter.formatINR(quote.high)),
          _StatItem('Low', CurrencyFormatter.formatINR(quote.low)),
          _StatItem(
            'Prev Close',
            CurrencyFormatter.formatINR(quote.previousClose),
          ),
          _StatItem('Volume', _formatVolume(quote.volume)),
          _StatItem('Last Updated', quote.latestTradingDay),
        ]),
      ],
    );
  }

  Widget _buildCryptoStats() {
    final quote = _cryptoQuote!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Market Statistics',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatsGrid([
          _StatItem('Current Price', CurrencyFormatter.formatINR(quote.price)),
          _StatItem(
            '24h Change',
            CurrencyFormatter.formatPercentage(quote.changePercent),
          ),
          _StatItem('Bid Price', CurrencyFormatter.formatINR(quote.bidPrice)),
          _StatItem('Ask Price', CurrencyFormatter.formatINR(quote.askPrice)),
          _StatItem('Market', quote.market),
          _StatItem('Last Updated', quote.lastRefreshed),
        ]),
      ],
    );
  }

  Widget _buildStatsGrid(List<_StatItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xff1a1a1a),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withAlpha((0.1 * 255).round()),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withAlpha((0.5 * 255).round()),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                item.value,
                style: const TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xff1a1a1a),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withAlpha((0.1 * 255).round()),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getAssetTypeColor(
                        widget.assetType,
                      ).withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.assetType.displayName,
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getAssetTypeColor(widget.assetType),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.name,
                style: const TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getAssetDescription(),
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withAlpha((0.7 * 255).round()),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getAssetDescription() {
    switch (widget.symbol) {
      case 'RELIANCE':
        return 'Reliance Industries Limited is an Indian multinational conglomerate, headquartered in Mumbai. It has diverse businesses including energy, petrochemicals, natural gas, retail, telecommunications, mass media, and textiles.';
      case 'TCS':
        return 'Tata Consultancy Services is an Indian multinational information technology services and consulting company. It is one of the largest IT services companies in the world.';
      case 'INFY':
        return 'Infosys Limited is an Indian multinational information technology company that provides business consulting, information technology and outsourcing services.';
      case 'HDFCBANK':
        return 'HDFC Bank Limited is an Indian banking and financial services company headquartered in Mumbai. It is one of India\'s leading private sector banks.';
      case 'ICICIBANK':
        return 'ICICI Bank Limited is an Indian multinational bank and financial services company. It is the second largest bank in India by assets and market capitalization.';
      case 'HINDUNILVR':
        return 'Hindustan Unilever Limited is an Indian consumer goods company headquartered in Mumbai. It is a subsidiary of Unilever.';
      case 'ITC':
        return 'ITC Limited is an Indian conglomerate headquartered in Kolkata. Its diversified business includes FMCG, hotels, paperboards & packaging, agri-business, and information technology.';
      case 'BAJFINANCE':
        return 'Bajaj Finance Limited is an Indian financial services company headquartered in Pune. It is engaged in lending and allied activities.';
      case 'SBIN':
        return 'State Bank of India is an Indian multinational public sector bank and financial services statutory body. It is the largest bank in India with over 450 million customers.';
      case 'BHARTIARTL':
        return 'Bharti Airtel Limited is an Indian multinational telecommunications services company based in New Delhi. It is the second largest mobile network operator in India.';
      case 'BTC-USD':
        return 'Bitcoin is a decentralized digital currency that can be transferred on the peer-to-peer bitcoin network. Bitcoin transactions are verified by network nodes through cryptography.';
      case 'ETH-USD':
        return 'Ethereum is a decentralized, open-source blockchain with smart contract functionality. Ether is the native cryptocurrency of the platform.';
      case 'BNB-USD':
        return 'Binance Coin is a cryptocurrency that can be used to trade and pay fees on the Binance cryptocurrency exchange. It has expanded its use cases to various applications.';
    }

    return 'Real-time market data and trading information for ${widget.name}.';
  }

  Color _getAssetTypeColor(AssetType type) {
    switch (type) {
      case AssetType.stock:
        return Colors.blue;
      case AssetType.crypto:
        return Colors.orange;
      case AssetType.mutualFund:
        return Colors.green;
    }
  }

  String _formatVolume(int volume) {
    if (volume >= 10000000) {
      return '${(volume / 10000000).toStringAsFixed(2)}Cr';
    } else if (volume >= 100000) {
      return '${(volume / 100000).toStringAsFixed(2)}L';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    }
    return volume.toString();
  }
}

class _StatItem {
  final String label;
  final String value;

  _StatItem(this.label, this.value);
}

/// Order type options for trading
enum _OrderTypeOption { market, stopLoss, bracket }

class _TradeBottomSheet extends StatefulWidget {
  final String symbol;
  final String name;
  final AssetType assetType;
  final double currentPrice;

  const _TradeBottomSheet({
    required this.symbol,
    required this.name,
    required this.assetType,
    required this.currentPrice,
  });

  @override
  State<_TradeBottomSheet> createState() => _TradeBottomSheetState();
}

class _TradeBottomSheetState extends State<_TradeBottomSheet> {
  bool _isBuying = true;
  _OrderTypeOption _orderType = _OrderTypeOption.market;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _triggerPriceController = TextEditingController();
  final TextEditingController _stopLossPriceController =
      TextEditingController();
  final TextEditingController _targetPriceController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.currentPrice.toStringAsFixed(2);
    // Set default stop-loss and target prices based on current price
    _updateDefaultPrices();
  }

  void _updateDefaultPrices() {
    final currentPrice = widget.currentPrice;
    // Default stop-loss: 5% below current price for buy, 5% above for sell
    // Default target: 10% above current price for buy, 10% below for sell
    if (_isBuying) {
      _triggerPriceController.text = (currentPrice * 0.95).toStringAsFixed(2);
      _stopLossPriceController.text = (currentPrice * 0.95).toStringAsFixed(2);
      _targetPriceController.text = (currentPrice * 1.10).toStringAsFixed(2);
    } else {
      _triggerPriceController.text = (currentPrice * 1.05).toStringAsFixed(2);
      _stopLossPriceController.text = (currentPrice * 1.05).toStringAsFixed(2);
      _targetPriceController.text = (currentPrice * 0.90).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _triggerPriceController.dispose();
    _stopLossPriceController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return quantity * price;
  }

  void _executeTrade() async {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid quantity')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      switch (_orderType) {
        case _OrderTypeOption.market:
          await _executeMarketOrder(quantity, price);
          break;
        case _OrderTypeOption.stopLoss:
          await _executeStopLossOrder(quantity);
          break;
        case _OrderTypeOption.bracket:
          await _executeBracketOrder(quantity, price);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _executeMarketOrder(double quantity, double price) async {
    if (price <= 0) {
      throw Exception('Please enter valid price');
    }

    if (_isBuying) {
      context.read<TransactionBloc>().add(
        ExecuteBuyOrder(
          assetSymbol: widget.symbol,
          assetName: widget.name,
          assetType: widget.assetType,
          quantity: quantity,
          pricePerUnit: price,
        ),
      );
    } else {
      context.read<TransactionBloc>().add(
        ExecuteSellOrder(
          assetSymbol: widget.symbol,
          assetName: widget.name,
          assetType: widget.assetType,
          quantity: quantity,
          pricePerUnit: price,
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_isBuying ? 'Buy' : 'Sell'} order executed successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _executeStopLossOrder(double quantity) async {
    final triggerPrice = double.tryParse(_triggerPriceController.text) ?? 0;

    if (triggerPrice <= 0) {
      throw Exception('Please enter valid trigger price');
    }

    context.read<OrderBloc>().add(
      CreateStopLossOrder(
        assetSymbol: widget.symbol,
        assetName: widget.name,
        assetType: widget.assetType,
        orderSide: _isBuying ? OrderSide.buy : OrderSide.sell,
        quantity: quantity,
        triggerPrice: triggerPrice,
        notes: 'Stop-loss order from trade dialog',
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stop-loss order created at ₹${triggerPrice.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _executeBracketOrder(double quantity, double entryPrice) async {
    if (entryPrice <= 0) {
      throw Exception('Please enter valid entry price');
    }

    final stopLossPrice = double.tryParse(_stopLossPriceController.text) ?? 0;
    final targetPrice = double.tryParse(_targetPriceController.text) ?? 0;

    if (stopLossPrice <= 0 || targetPrice <= 0) {
      throw Exception('Please enter valid stop-loss and target prices');
    }

    // Validate bracket prices
    if (_isBuying) {
      if (stopLossPrice >= entryPrice) {
        throw Exception('Stop-loss must be below entry price for buy orders');
      }
      if (targetPrice <= entryPrice) {
        throw Exception('Target must be above entry price for buy orders');
      }
    } else {
      if (stopLossPrice <= entryPrice) {
        throw Exception('Stop-loss must be above entry price for sell orders');
      }
      if (targetPrice >= entryPrice) {
        throw Exception('Target must be below entry price for sell orders');
      }
    }

    context.read<OrderBloc>().add(
      CreateBracketOrder(
        assetSymbol: widget.symbol,
        assetName: widget.name,
        assetType: widget.assetType,
        orderSide: _isBuying ? OrderSide.buy : OrderSide.sell,
        quantity: quantity,
        entryPrice: entryPrice,
        stopLossPrice: stopLossPrice,
        targetPrice: targetPrice,
        notes: 'Bracket order from trade dialog',
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bracket order created: Entry ₹${entryPrice.toStringAsFixed(0)} | SL ₹${stopLossPrice.toStringAsFixed(0)} | Target ₹${targetPrice.toStringAsFixed(0)}',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Widget _buildOrderTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Type',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withAlpha((0.7 * 255).round()),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildOrderTypeChip(
              label: 'Market',
              icon: Icons.flash_on,
              isSelected: _orderType == _OrderTypeOption.market,
              onTap: () => setState(() => _orderType = _OrderTypeOption.market),
            ),
            const SizedBox(width: 8),
            _buildOrderTypeChip(
              label: 'Stop-Loss',
              icon: Icons.shield,
              isSelected: _orderType == _OrderTypeOption.stopLoss,
              onTap: () =>
                  setState(() => _orderType = _OrderTypeOption.stopLoss),
            ),
            const SizedBox(width: 8),
            _buildOrderTypeChip(
              label: 'Bracket',
              icon: Icons.account_tree,
              isSelected: _orderType == _OrderTypeOption.bracket,
              onTap: () =>
                  setState(() => _orderType = _OrderTypeOption.bracket),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderTypeChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected
        ? const Color(0xFFE5BCE7)
        : Colors.white.withAlpha((0.5 * 255).round());
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE5BCE7).withAlpha((0.15 * 255).round())
                : const Color(0xff1a1a1a),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFE5BCE7) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopLossInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.orange.withAlpha((0.3 * 255).round()),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isBuying
                      ? 'Order triggers when price drops to trigger price'
                      : 'Order triggers when price rises to trigger price',
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _triggerPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'ClashDisplay',
          ),
          decoration: InputDecoration(
            labelText: 'Trigger Price (₹)',
            labelStyle: TextStyle(
              color: Colors.white.withAlpha((0.5 * 255).round()),
              fontFamily: 'ClashDisplay',
            ),
            prefixIcon: const Icon(Icons.trending_down, color: Colors.orange),
            filled: true,
            fillColor: const Color(0xff1a1a1a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBracketInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.blue.withAlpha((0.3 * 255).round()),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Entry executes now. Stop-loss & target orders created automatically.',
                  style: const TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stopLossPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'ClashDisplay',
                ),
                decoration: InputDecoration(
                  labelText: 'Stop-Loss (₹)',
                  labelStyle: TextStyle(
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                    fontFamily: 'ClashDisplay',
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.shield,
                    color: Colors.red,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xff1a1a1a),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _targetPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'ClashDisplay',
                ),
                decoration: InputDecoration(
                  labelText: 'Target (₹)',
                  labelStyle: TextStyle(
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                    fontFamily: 'ClashDisplay',
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.flag,
                    color: Colors.green,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xff1a1a1a),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_orderType == _OrderTypeOption.bracket) ...[
          const SizedBox(height: 12),
          _buildRiskRewardInfo(),
        ],
      ],
    );
  }

  Widget _buildRiskRewardInfo() {
    final entryPrice = double.tryParse(_priceController.text) ?? 0;
    final stopLoss = double.tryParse(_stopLossPriceController.text) ?? 0;
    final target = double.tryParse(_targetPriceController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    if (entryPrice <= 0 || stopLoss <= 0 || target <= 0 || quantity <= 0) {
      return const SizedBox.shrink();
    }

    final potentialLoss = (entryPrice - stopLoss).abs() * quantity;
    final potentialProfit = (target - entryPrice).abs() * quantity;
    final riskReward = potentialLoss > 0
        ? potentialProfit / potentialLoss
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildRiskRewardItem(
            'Risk',
            '₹${potentialLoss.toStringAsFixed(0)}',
            Colors.red,
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withAlpha((0.1 * 255).round()),
          ),
          _buildRiskRewardItem(
            'Reward',
            '₹${potentialProfit.toStringAsFixed(0)}',
            Colors.green,
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withAlpha((0.1 * 255).round()),
          ),
          _buildRiskRewardItem(
            'R:R',
            '1:${riskReward.toStringAsFixed(1)}',
            const Color(0xFFE5BCE7),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskRewardItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 11,
            color: Colors.white.withAlpha((0.5 * 255).round()),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getButtonText() {
    switch (_orderType) {
      case _OrderTypeOption.market:
        return '${_isBuying ? 'Buy' : 'Sell'} ${widget.symbol}';
      case _OrderTypeOption.stopLoss:
        return 'Create Stop-Loss Order';
      case _OrderTypeOption.bracket:
        return 'Create Bracket Order';
    }
  }

  Color _getButtonColor() {
    switch (_orderType) {
      case _OrderTypeOption.market:
        return _isBuying ? Colors.green : Colors.red;
      case _OrderTypeOption.stopLoss:
        return Colors.orange;
      case _OrderTypeOption.bracket:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
          setState(() => _isProcessing = false);
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xff0a0a0a),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trade ${widget.symbol}',
                    style: const TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Order Type Selector
              _buildOrderTypeSelector(),
              const SizedBox(height: 20),

              // Buy/Sell Toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBuying = true;
                          _updateDefaultPrices();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isBuying
                              ? Colors.green
                              : const Color(0xff1a1a1a),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Buy',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isBuying
                                  ? Colors.white
                                  : Colors.white.withAlpha((0.5 * 255).round()),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBuying = false;
                          _updateDefaultPrices();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isBuying
                              ? Colors.red
                              : const Color(0xff1a1a1a),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Sell',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: !_isBuying
                                  ? Colors.white
                                  : Colors.white.withAlpha((0.5 * 255).round()),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quantity Input
              TextField(
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'ClashDisplay',
                ),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(
                    color: Colors.white.withAlpha((0.5 * 255).round()),
                    fontFamily: 'ClashDisplay',
                  ),
                  filled: true,
                  fillColor: const Color(0xff1a1a1a),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Price Input (for Market and Bracket orders)
              if (_orderType != _OrderTypeOption.stopLoss) ...[
                TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'ClashDisplay',
                  ),
                  decoration: InputDecoration(
                    labelText: _orderType == _OrderTypeOption.bracket
                        ? 'Entry Price (₹)'
                        : 'Price per unit (₹)',
                    labelStyle: TextStyle(
                      color: Colors.white.withAlpha((0.5 * 255).round()),
                      fontFamily: 'ClashDisplay',
                    ),
                    filled: true,
                    fillColor: const Color(0xff1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
              ],

              // Stop-Loss specific inputs
              if (_orderType == _OrderTypeOption.stopLoss)
                _buildStopLossInputs(),

              // Bracket order specific inputs
              if (_orderType == _OrderTypeOption.bracket) _buildBracketInputs(),

              const SizedBox(height: 20),

              // Total Amount
              if (_orderType == _OrderTypeOption.market ||
                  _orderType == _OrderTypeOption.bracket)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff1a1a1a),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _orderType == _OrderTypeOption.bracket
                            ? 'Entry Amount'
                            : 'Total Amount',
                        style: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatINR(_totalAmount),
                        style: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE5BCE7),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Execute Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _executeTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _getButtonText(),
                          style: const TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
