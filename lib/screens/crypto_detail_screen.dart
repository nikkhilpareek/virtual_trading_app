import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
                      ).colorScheme.primary.withAlpha((0.5 * 255).round()),
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

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.crypto.changePercent24h >= 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
