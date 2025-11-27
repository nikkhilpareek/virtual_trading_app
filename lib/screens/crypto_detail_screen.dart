import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/services/freecrypto_service.dart';
import '../core/utils/currency_formatter.dart';
import '../widgets/crypto_logo.dart';
import 'dart:math' as math;
import 'dart:developer' as developer;

/// Crypto Detail Screen - Shows detailed information and historical data for a cryptocurrency
class CryptoDetailScreen extends StatefulWidget {
  final CryptoQuote crypto;

  const CryptoDetailScreen({super.key, required this.crypto});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  List<FlSpot> _chartData = [];
  bool _isLoading = true;
  String _selectedTimeframe = '7D';

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  /// Load historical data from CoinGecko API
  void _loadHistoricalData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Determine number of days based on timeframe
      int days = 7;
      switch (_selectedTimeframe) {
        case '7D':
          days = 7;
          break;
        case '1M':
          days = 30;
          break;
        case '3M':
          days = 90;
          break;
        case '1Y':
          days = 365;
          break;
      }

      // Fetch real historical data from CoinGecko API
      final service = FreeCryptoService();
      final historicalData = await service.getHistoricalPrices(
        widget.crypto.symbol,
        days,
      );

      if (!mounted) return;

      // Convert to FlSpot for chart
      final points = <FlSpot>[];
      for (int i = 0; i < historicalData.length; i++) {
        points.add(FlSpot(i.toDouble(), historicalData[i].price));
      }

      setState(() {
        _chartData = points;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading historical data: $e');
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load historical data: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  Widget _buildGoogleFinanceChart() {
    if (_chartData.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: Colors.white.withAlpha((0.5 * 255).round()),
            fontFamily: 'ClashDisplay',
          ),
        ),
      );
    }

    // Calculate min/max with padding
    final minY = _chartData.map((e) => e.y).reduce(math.min) * 0.995;
    final maxY = _chartData.map((e) => e.y).reduce(math.max) * 1.005;
    final range = maxY - minY;

    // Calculate smart interval for horizontal grid lines (5 lines max)
    final interval = range / 4;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withAlpha((0.05 * 255).round()),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _chartData.length / 4,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= _chartData.length) {
                  return const SizedBox();
                }

                // Show date labels based on timeframe
                String label;
                switch (_selectedTimeframe) {
                  case '7D':
                    label = 'D${index + 1}';
                    break;
                  case '1M':
                    label = 'D${index + 1}';
                    break;
                  case '3M':
                    label = 'M${(index / 30).floor() + 1}';
                    break;
                  case '1Y':
                    label = 'M${(index / 30).floor() + 1}';
                    break;
                  default:
                    label = '${index + 1}';
                }

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.4 * 255).round()),
                      fontSize: 10,
                      fontFamily: 'ClashDisplay',
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 70,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  CurrencyFormatter.formatINRCompact(value),
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.4 * 255).round()),
                    fontSize: 10,
                    fontFamily: 'ClashDisplay',
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (_chartData.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot spot) =>
                Theme.of(context).colorScheme.surface,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  CurrencyFormatter.formatINR(spot.y),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'ClashDisplay',
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.5),
                      strokeWidth: 2,
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  );
                }).toList();
              },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _chartData,
            isCurved: true,
            curveSmoothness: 0.4,
            color: widget.crypto.changePercent24h >= 0
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFF5252),
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (widget.crypto.changePercent24h >= 0
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5252))
                      .withAlpha((0.2 * 255).round()),
                  (widget.crypto.changePercent24h >= 0
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF5252))
                      .withAlpha((0.0 * 255).round()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTradeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CryptoDetailTradeBottomSheet(crypto: widget.crypto),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.crypto.changePercent24h >= 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTradeBottomSheet(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.swap_horiz),
        label: const Text(
          'Trade',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  CryptoLogo(
                    symbol: widget.crypto.symbol,
                    size: 32,
                    fontSize: 12,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.crypto.symbol,
                        style: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.crypto.name,
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 12,
                          color: Colors.white.withAlpha((0.6 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Price
                    Text(
                      CurrencyFormatter.formatINR(widget.crypto.price),
                      style: const TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 24h Change
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isPositive ? Colors.green : Colors.red)
                            .withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 16,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isPositive ? '+' : ''}${widget.crypto.changePercent24h.toStringAsFixed(2)}% (24h)',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Price Chart
                    const Text(
                      'Price Chart',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timeframe Selector
                    Row(
                      children: [
                        _buildTimeframeButton('7D'),
                        const SizedBox(width: 8),
                        _buildTimeframeButton('1M'),
                        const SizedBox(width: 8),
                        _buildTimeframeButton('3M'),
                        const SizedBox(width: 8),
                        _buildTimeframeButton('1Y'),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Chart
                    _isLoading
                        ? Container(
                            height: 300,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              color: Color(0xFFE5BCE7),
                            ),
                          )
                        : _chartData.isEmpty
                        ? Container(
                            height: 300,
                            alignment: Alignment.center,
                            child: Text(
                              'No chart data available',
                              style: TextStyle(
                                color: Colors.white.withAlpha(
                                  (0.5 * 255).round(),
                                ),
                                fontFamily: 'ClashDisplay',
                              ),
                            ),
                          )
                        : Container(
                            height: 300,
                            padding: const EdgeInsets.only(
                              top: 16,
                              right: 16,
                              bottom: 16,
                              left: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xff1a1a1a),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withAlpha(
                                  (0.08 * 255).round(),
                                ),
                              ),
                            ),
                            child: _buildGoogleFinanceChart(),
                          ),

                    const SizedBox(height: 32),

                    // Stats Grid
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.08 * 255).round()),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow(
                            '24h High',
                            CurrencyFormatter.formatINR(widget.crypto.high24h),
                          ),
                          const Divider(color: Color(0xff2a2a2a), height: 24),
                          _buildStatRow(
                            '24h Low',
                            CurrencyFormatter.formatINR(widget.crypto.low24h),
                          ),
                          const Divider(color: Color(0xff2a2a2a), height: 24),
                          _buildStatRow(
                            '24h Change',
                            '${isPositive ? '+' : ''}${CurrencyFormatter.formatINR(widget.crypto.change24h)}',
                          ),
                          const Divider(color: Color(0xff2a2a2a), height: 24),
                          _buildStatRow('Currency', widget.crypto.currency),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeButton(String timeframe) {
    final isSelected = _selectedTimeframe == timeframe;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTimeframe = timeframe);
        _loadHistoricalData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          timeframe,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 14,
            color: Colors.white.withAlpha((0.6 * 255).round()),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Trade Bottom Sheet Widget for Crypto Detail Screen
class _CryptoDetailTradeBottomSheet extends StatefulWidget {
  final CryptoQuote crypto;

  const _CryptoDetailTradeBottomSheet({required this.crypto});

  @override
  State<_CryptoDetailTradeBottomSheet> createState() =>
      _CryptoDetailTradeBottomSheetState();
}

class _CryptoDetailTradeBottomSheetState
    extends State<_CryptoDetailTradeBottomSheet> {
  bool _isBuying = true;
  String _orderType = 'market'; // 'market', 'stopLoss', 'bracket'
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _triggerPriceController = TextEditingController();
  final TextEditingController _stopLossPriceController =
      TextEditingController();
  final TextEditingController _targetPriceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default prices based on current price
    final currentPrice = widget.crypto.price;
    _triggerPriceController.text = (currentPrice * 0.98).toStringAsFixed(2);
    _stopLossPriceController.text = (currentPrice * 0.95).toStringAsFixed(2);
    _targetPriceController.text = (currentPrice * 1.10).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _triggerPriceController.dispose();
    _stopLossPriceController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  double get _quantity => double.tryParse(_quantityController.text) ?? 0;
  double get _triggerPrice =>
      double.tryParse(_triggerPriceController.text) ?? 0;
  double get _stopLossPrice =>
      double.tryParse(_stopLossPriceController.text) ?? 0;
  double get _targetPrice => double.tryParse(_targetPriceController.text) ?? 0;

  double get _totalAmount {
    final qty = _quantity;
    switch (_orderType) {
      case 'stopLoss':
        return qty * _triggerPrice;
      case 'bracket':
        return qty * widget.crypto.price;
      default:
        return qty * widget.crypto.price;
    }
  }

  void _executeTrade() {
    if (_quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderBloc = context.read<OrderBloc>();
      final side = _isBuying ? OrderSide.buy : OrderSide.sell;

      switch (_orderType) {
        case 'stopLoss':
          if (_triggerPrice <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter a valid trigger price'),
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
          orderBloc.add(
            CreateStopLossOrder(
              assetSymbol: widget.crypto.symbol,
              assetName: widget.crypto.name,
              assetType: AssetType.crypto,
              orderSide: side,
              quantity: _quantity,
              triggerPrice: _triggerPrice,
            ),
          );
          break;

        case 'bracket':
          if (_stopLossPrice <= 0 || _targetPrice <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter valid stop-loss and target prices'),
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
          orderBloc.add(
            CreateBracketOrder(
              assetSymbol: widget.crypto.symbol,
              assetName: widget.crypto.name,
              assetType: AssetType.crypto,
              orderSide: side,
              quantity: _quantity,
              entryPrice: widget.crypto.price,
              stopLossPrice: _stopLossPrice,
              targetPrice: _targetPrice,
            ),
          );
          break;

        default:
          // Market order - use existing crypto bloc
          if (_isBuying) {
            context.read<CryptoBloc>().add(
              BuyCrypto(
                symbol: widget.crypto.symbol,
                name: widget.crypto.name,
                quantity: _quantity,
                price: widget.crypto.price,
              ),
            );
          } else {
            context.read<CryptoBloc>().add(
              SellCrypto(
                symbol: widget.crypto.symbol,
                quantity: _quantity,
                price: widget.crypto.price,
              ),
            );
          }
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _orderType == 'market'
                ? '${_isBuying ? "Bought" : "Sold"} ${_quantity.toStringAsFixed(4)} ${widget.crypto.symbol}'
                : '${_orderType == 'stopLoss' ? 'Stop-Loss' : 'Bracket'} order placed for ${widget.crypto.symbol}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
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
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    CryptoLogo(
                      symbol: widget.crypto.symbol,
                      size: 40,
                      fontSize: 14,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trade ${widget.crypto.symbol}',
                            style: const TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatINR(widget.crypto.price),
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 14,
                              color: Colors.white.withAlpha(
                                (0.6 * 255).round(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Buy/Sell Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xff1a1a1a),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isBuying = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isBuying
                                  ? Colors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Buy',
                                style: TextStyle(
                                  fontFamily: 'ClashDisplay',
                                  fontWeight: FontWeight.w600,
                                  color: _isBuying ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isBuying = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isBuying
                                  ? Colors.red
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Sell',
                                style: TextStyle(
                                  fontFamily: 'ClashDisplay',
                                  fontWeight: FontWeight.w600,
                                  color: !_isBuying
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Order Type Selector
                const Text(
                  'Order Type',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildOrderTypeChip('Market', 'market'),
                    const SizedBox(width: 8),
                    _buildOrderTypeChip('Stop-Loss', 'stopLoss'),
                    const SizedBox(width: 8),
                    _buildOrderTypeChip('Bracket', 'bracket'),
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
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xff1a1a1a),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixText: widget.crypto.symbol,
                    suffixStyle: const TextStyle(color: Colors.white70),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Conditional fields based on order type
                if (_orderType == 'stopLoss') ...[
                  TextField(
                    controller: _triggerPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'ClashDisplay',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Trigger Price',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xff1a1a1a),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Colors.white70),
                      helperText: _isBuying
                          ? 'Order triggers when price rises above this'
                          : 'Order triggers when price falls below this',
                      helperStyle: TextStyle(
                        color: Colors.white.withAlpha((0.5 * 255).round()),
                        fontSize: 11,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],

                if (_orderType == 'bracket') ...[
                  TextField(
                    controller: _stopLossPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'ClashDisplay',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Stop-Loss Price',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xff1a1a1a),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Colors.white70),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _targetPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'ClashDisplay',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Target Price',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xff1a1a1a),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: Colors.white70),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildRiskRewardSection(),
                ],

                const SizedBox(height: 20),

                // Total Amount
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
                        'Estimated Total',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          color: Colors.white.withAlpha((0.6 * 255).round()),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatINR(_totalAmount),
                        style: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
                    onPressed: _isLoading ? null : _executeTrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBuying ? Colors.green : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
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
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeChip(String label, String type) {
    final isSelected = _orderType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _orderType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : const Color(0xff1a1a1a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.withAlpha((0.3 * 255).round()),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskRewardSection() {
    final entryPrice = widget.crypto.price;
    final stopLoss = _stopLossPrice;
    final target = _targetPrice;

    if (stopLoss <= 0 || target <= 0) return const SizedBox.shrink();

    final risk = (entryPrice - stopLoss).abs();
    final reward = (target - entryPrice).abs();
    final riskRewardRatio = risk > 0 ? reward / risk : 0.0;
    final potentialLoss = _quantity * risk;
    final potentialProfit = _quantity * reward;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk/Reward Analysis',
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRRItem(
                'Risk',
                CurrencyFormatter.formatINR(potentialLoss),
                Colors.red,
              ),
              _buildRRItem(
                'Reward',
                CurrencyFormatter.formatINR(potentialProfit),
                Colors.green,
              ),
              _buildRRItem(
                'R:R Ratio',
                '1:${riskRewardRatio.toStringAsFixed(2)}',
                riskRewardRatio >= 2 ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRRItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 10,
            color: Colors.white.withAlpha((0.5 * 255).round()),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getButtonText() {
    final action = _isBuying ? 'Buy' : 'Sell';
    switch (_orderType) {
      case 'stopLoss':
        return 'Place Stop-Loss $action Order';
      case 'bracket':
        return 'Place Bracket $action Order';
      default:
        return '$action ${widget.crypto.symbol}';
    }
  }
}
