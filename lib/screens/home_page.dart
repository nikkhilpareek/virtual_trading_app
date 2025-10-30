import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/utils/currency_formatter.dart';
import 'market_screen.dart';
import 'assets_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'learn_screen.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, this.userName = 'Nikhil'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;
  late final List<Widget> _screens;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();

    _screens = [
      const AssetsScreen(),
      const MarketScreen(),
      DashboardScreen(
        userName: widget.userName,
        onNavigateToTab: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
          setState(() => _currentIndex = index);
        },
      ),
      const LearnScreen(),
      const CryptoScreen(),
    ];
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xff0a0a0a),
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final items = [
      {
        'icon': Icons.account_balance_wallet_outlined,
        'active': Icons.account_balance_wallet,
        'label': 'Assets',
      },
      {
        'icon': Icons.trending_up,
        'active': Icons.trending_up,
        'label': 'Market',
      },
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Home'},
      {'icon': Icons.school_outlined, 'active': Icons.school, 'label': 'Learn'},
      {
        'icon': Icons.currency_bitcoin,
        'active': Icons.currency_bitcoin,
        'label': 'Crypto',
      },
    ];

    return SafeArea(
      minimum: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 65,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha((0.02 * 255).round()),
                    Colors.white.withAlpha((0.01 * 255).round()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                color: Colors.white.withAlpha((0.02 * 255).round()),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withAlpha((0.06 * 255).round()),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.42 * 255).round()),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final isActive = _currentIndex == i;
                  final iconData = isActive
                      ? items[i]['active'] as IconData
                      : items[i]['icon'] as IconData;
                  final color = isActive
                      ? const Color(0xFFE5BCE7)
                      : Colors.white.withAlpha((0.7 * 255).round());

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _pageController.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                        setState(() => _currentIndex = i);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? color.withAlpha((0.12 * 255).round())
                                  : Colors.transparent,
                              border: Border.all(
                                color: isActive
                                    ? color.withAlpha((0.18 * 255).round())
                                    : Colors.white.withAlpha(
                                        (0.02 * 255).round(),
                                      ),
                                width: 1.0,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: color.withAlpha(
                                          (0.06 * 255).round(),
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(iconData, color: color, size: 20),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildTopPerformers() {
  // Mock NSE top performers
  final List<Map<String, Object>> topStocks = [
    {
      'symbol': 'TCS',
      'name': 'Tata Consultancy Services',
      'price': 3200.50,
      'change': 2.3,
    },
    {
      'symbol': 'RELIANCE',
      'name': 'Reliance Industries',
      'price': 2310.75,
      'change': 1.6,
    },
    {'symbol': 'INFY', 'name': 'Infosys', 'price': 1420.10, 'change': 3.8},
    {'symbol': 'HDFC', 'name': 'HDFC Bank', 'price': 1550.30, 'change': -0.9},
    {
      'symbol': 'ICICIBANK',
      'name': 'ICICI Bank',
      'price': 970.45,
      'change': 4.1,
    },
  ];

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xff1a1a1a),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withAlpha((0.08 * 255).round()),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Performer of the Week',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: topStocks.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final s = topStocks[index];
              final symbol = s['symbol'] as String;
              final name = s['name'] as String;
              final price = s['price'] as double;
              final change = s['change'] as double;
              final positive = change >= 0;

              return Container(
                width: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff121212),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha((0.04 * 255).round()),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (positive ? Colors.green : Colors.red).withAlpha(
                          (0.12 * 255).round(),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          symbol,
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: positive ? Colors.green : Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatINR(price),
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(
                                (0.7 * 255).round(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${positive ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: positive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

// Dashboard Screen (Home Tab)
class DashboardScreen extends StatefulWidget {
  final String userName;
  final Function(int)? onNavigateToTab;

  const DashboardScreen({
    super.key,
    required this.userName,
    this.onNavigateToTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load transactions when dashboard loads
    context.read<TransactionBloc>().add(const LoadTransactions(limit: 10));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0a0a0a),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    String displayName = widget.userName;
                    if (state is UserLoaded) {
                      displayName = state.profile.displayName;
                    }
                    return RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hello, \n',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: '$displayName!',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5BCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ),
                        icon: const Icon(
                          Icons.person,
                          color: Colors.black,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildBalanceCard(),
              const SizedBox(height: 30),
              _buildQuickActions(context),
              const SizedBox(height: 20),

              // Recent Activity
              BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state is TransactionLoading) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.1 * 255).round()),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE5BCE7),
                        ),
                      ),
                    );
                  }

                  if (state is TransactionLoaded &&
                      state.transactions.isNotEmpty) {
                    final recentTransactions = state.transactions
                        .take(5)
                        .toList();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.1 * 255).round()),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 180,
                            child: ListView.separated(
                              itemCount: recentTransactions.length,
                              separatorBuilder: (c, i) => Divider(
                                color: Colors.white.withAlpha(
                                  (0.1 * 255).round(),
                                ),
                                height: 24,
                              ),
                              itemBuilder: (c, i) {
                                final t = recentTransactions[i];
                                final isBuy =
                                    t.transactionType == TransactionType.buy;
                                return Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            (isBuy ? Colors.green : Colors.red)
                                                .withAlpha((0.1 * 255).round()),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isBuy
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isBuy
                                            ? Colors.green
                                            : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.assetSymbol,
                                            style: TextStyle(
                                              fontFamily: 'ClashDisplay',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${t.quantity} shares @ ${CurrencyFormatter.formatINR(t.pricePerUnit)}',
                                            style: TextStyle(
                                              fontFamily: 'ClashDisplay',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white.withAlpha(
                                                (0.5 * 255).round(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isBuy ? '-' : '+'}${CurrencyFormatter.formatINR(t.totalAmount).replaceAll('₹', '')}',
                                          style: TextStyle(
                                            fontFamily: 'ClashDisplay',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isBuy
                                                ? Colors.red
                                                : Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t.formattedDate,
                                          style: TextStyle(
                                            fontFamily: 'ClashDisplay',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white.withAlpha(
                                              (0.5 * 255).round(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xff1a1a1a),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha((0.1 * 255).round()),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Recent Activities",
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Icon(
                            Icons.trending_up,
                            size: 60,
                            color: Colors.white.withAlpha((0.3 * 255).round()),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recent activity yet',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(
                                (0.5 * 255).round(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start trading to see your activity',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(
                                (0.3 * 255).round(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              _buildTopPerformers(),
              const SizedBox(height: 16),
              _buildTopPerformers(), const SizedBox(height: 16),
              _buildTopPerformers(), const SizedBox(height: 16),
              _buildTopPerformers(), const SizedBox(height: 16),
              _buildTopPerformers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        return BlocBuilder<HoldingsBloc, HoldingsState>(
          builder: (context, holdingsState) {
            // Default values
            double stonkBalance = 0.0;
            double portfolioValue = 0.0;
            double profitLoss = 0.0;
            double profitLossPercentage = 0.0;

            // Get user balance
            if (userState is UserLoaded) {
              stonkBalance = userState.profile.stonkBalance;
            }

            // Get portfolio stats
            if (holdingsState is HoldingsLoaded) {
              portfolioValue = holdingsState.totalValue;
              profitLoss = holdingsState.totalProfitLoss;
              profitLossPercentage = holdingsState.totalProfitLossPercentage;
            }

            // Total balance = Stonk Tokens + Portfolio Value
            double totalBalance = stonkBalance + portfolioValue;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff1a1a1a),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withAlpha((0.1 * 255).round()),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and info icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Portfolio Balance',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withAlpha((0.7 * 255).round()),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE5BCE7,
                          ).withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.info,
                          color: Color(0xFFE5BCE7),
                          size: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Total balance amount
                  Text(
                    CurrencyFormatter.formatINR(totalBalance),
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Breakdown
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available',
                              style: TextStyle(
                                fontFamily: 'ClashDisplay',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withAlpha(
                                  (0.5 * 255).round(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatINRCompact(stonkBalance),
                              style: const TextStyle(
                                fontFamily: 'ClashDisplay',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invested',
                              style: TextStyle(
                                fontFamily: 'ClashDisplay',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withAlpha(
                                  (0.5 * 255).round(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatINR(portfolioValue),
                              style: TextStyle(
                                fontFamily: 'ClashDisplay',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (profitLoss != 0) ...[
                    const SizedBox(height: 12),

                    // Percentage change
                    Row(
                      children: [
                        Icon(
                          profitLoss >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: profitLoss >= 0 ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${CurrencyFormatter.formatPercentage(profitLossPercentage)} (${profitLoss >= 0 ? '+' : ''}${CurrencyFormatter.formatINR(profitLoss).replaceAll('₹', '')})',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: profitLoss >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Buy',
                Icons.add_shopping_cart,
                const Color(0xFFE5BCE7),
                () {
                  // Navigate to Market tab (index 1)
                  widget.onNavigateToTab?.call(1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Sell',
                Icons.remove_shopping_cart,
                Colors.red,
                () {
                  // Navigate to Watchlist tab (index 0)
                  widget.onNavigateToTab?.call(0);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withAlpha((0.11 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha((0.3 * 255).round()),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Crypto Screen
class CryptoScreen extends StatelessWidget {
  const CryptoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xff0a0a0a),
        elevation: 0,
        title: const Text(
          'Crypto',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.currency_bitcoin, size: 80, color: Color(0xFFE5BCE7)),
            SizedBox(height: 20),
            Text(
              'Cryptocurrency',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Crypto trading coming soon...',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
