import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/utils/currency_formatter.dart';
import 'market_screen.dart';
import 'watchlist_screen.dart';
import 'profile_screen.dart';
import 'dart:ui';
import 'dart:developer' as developer;

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({
    super.key,
    this.userName = 'Nikhil', // Default name, can be passed from login
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Tab screens
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(userName: widget.userName),
      const MarketScreen(),
      const LearnScreen(),
      const WatchlistScreen(),
      const CryptoScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0a0a0a),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    // Floating "liquid glass" bar with custom animated items
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.bookmark_border,
        'active': Icons.bookmark,
        'label': 'Watchlist',
      },
      {
        'icon': Icons.trending_up,
        'active': Icons.trending_up,
        'label': 'Market',
      },
      {'icon': Icons.school_outlined, 'active': Icons.school, 'label': 'Learn'},
      {
        'icon': Icons.currency_bitcoin,
        'active': Icons.currency_bitcoin,
        'label': 'Crypto',
      },
    ];

    return SafeArea(
      minimum: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              // subtle frosted glass gradient + tint
              gradient: LinearGradient(
                colors: [
                  Colors.white.withAlpha((0.02 * 255).round()),
                  Colors.white.withAlpha((0.01 * 255).round()),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              color: Colors.white.withAlpha((0.02 * 255).round()),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withAlpha((0.06 * 255).round()),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.45 * 255).round()),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
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
                    onTap: () => setState(() => _currentIndex = i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          width: isActive ? 50 : 42,
                          height: isActive ? 50 : 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? color.withAlpha((0.12 * 255).round())
                                : Colors.transparent,
                            border: isActive
                                ? Border.all(
                                    color: color.withAlpha(
                                      (0.18 * 255).round(),
                                    ),
                                    width: 1.2,
                                  )
                                : Border.all(
                                    color: Colors.white.withAlpha(
                                      (0.02 * 255).round(),
                                    ),
                                    width: 1,
                                  ),
                            // tiny inner glow to mimic liquid depth
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: color.withAlpha(
                                        (0.08 * 255).round(),
                                      ),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: isActive ? 1.0 : 1.0,
                                end: isActive ? 1.18 : 1.0,
                              ),
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutBack,
                              builder: (context, scale, child) =>
                                  Transform.scale(scale: scale, child: child),
                              child: Icon(iconData, color: color, size: 20),
                            ),
                          ),
                        ),

                        // removed label area — icons only layout
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
  // ...existing code...

  // Widget _buildBottomNavigationBar() {
  //   return SafeArea(
  //     minimum: const EdgeInsets.only(left: 16, right: 16,bottom:12),
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(20),
  //       child: BackdropFilter(
  //         filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
  //         child: Container(
  //           height: 72,
  //           decoration: BoxDecoration(
  //             color: Colors.white.withOpacity(0.03),
  //             borderRadius: BorderRadius.circular(20),
  //             border: Border.all(
  //               color: Colors.white.withOpacity(0.06),
  //               width: 1,
  //             ),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.4),
  //                 blurRadius: 10,
  //                 offset: const Offset(0, 6),
  //               )
  //             ],
  //           ),
  //           child: BottomNavigationBar(
  //             currentIndex: _currentIndex,
  //             onTap: (index)=>setState(()=>_currentIndex = index),
  //             backgroundColor: Colors.transparent,
  //             selectedItemColor: const Color(0xFFE5BCE7),
  //             unselectedItemColor: Colors.white.withOpacity(0.6),
  //             type: BottomNavigationBarType.fixed,
  //             elevation: 0,
  //             showUnselectedLabels: true,
  //             selectedLabelStyle: const TextStyle(
  //               fontFamily: 'ClashDisplay',
  //               fontWeight: FontWeight.w500,
  //               fontSize: 12,
  //             ),
  //             unselectedLabelStyle: const TextStyle(
  //               fontFamily: 'ClashDisplay',
  //               fontWeight: FontWeight.w400,
  //               fontSize: 12,
  //             ),
  //             items: const [
  //               BottomNavigationBarItem(
  //                 icon: Icon(Icons.home_outlined),
  //                 activeIcon: Icon(Icons.home),
  //                 label: 'Home',
  //               ),
  //               BottomNavigationBarItem(
  //                 icon: Icon(Icons.bookmark_border),
  //                 activeIcon: Icon(Icons.bookmark),
  //                 label: 'Watchlist',
  //               ),
  //               BottomNavigationBarItem(
  //                 icon: Icon(Icons.trending_up),
  //                 activeIcon: Icon(Icons.trending_up),
  //                 label: 'Market',
  //               ),
  //               BottomNavigationBarItem(
  //                 icon: Icon(Icons.school_outlined),
  //                 activeIcon: Icon(Icons.school),
  //                 label: 'Learn',
  //               ),
  //               BottomNavigationBarItem(
  //                 icon: Icon(Icons.currency_bitcoin),
  //                 activeIcon: Icon(Icons.currency_bitcoin),
  //                 label: 'Crypto',
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

// Dashboard Screen (Home Tab)
class DashboardScreen extends StatefulWidget {
  final String userName;

  const DashboardScreen({super.key, required this.userName});

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
                // Left side - Hello, User!
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
                            text: 'Hello, ',
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

                // Right side - Notification bell and profile icons
                Row(
                  children: [
                    // Notification Bell Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Handle notification tap
                          developer.log('Notification tapped');
                        },
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Profile Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5BCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // Navigate to profile screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Portfolio Balance Card
            _buildBalanceCard(),

            const SizedBox(height: 30),

            // Quick Actions
            _buildQuickActions(context),

            const SizedBox(height: 20),

            // Recent Activity from TransactionBloc
            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
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
                    // Show only the last 5 transactions
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
                          Expanded(
                            child: ListView.separated(
                              itemCount: recentTransactions.length,
                              separatorBuilder: (context, index) => Divider(
                                color: Colors.white.withAlpha((0.1 * 255).round()),
                                height: 24,
                              ),
                              itemBuilder: (context, index) {
                                final transaction = recentTransactions[index];
                                final isBuy =
                                    transaction.transactionType ==
                                    TransactionType.buy;

                                return Row(
                                  children: [
                                    // Icon
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

                                    // Asset details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction.assetSymbol,
                                            style: TextStyle(
                                              fontFamily: 'ClashDisplay',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${transaction.quantity} shares @ ${CurrencyFormatter.formatINR(transaction.pricePerUnit)}',
                                            style: TextStyle(
                                              fontFamily: 'ClashDisplay',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white.withAlpha((0.5 * 255).round()),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Amount
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isBuy ? '-' : '+'}${CurrencyFormatter.formatINR(transaction.totalAmount).replaceAll('₹', '')}',
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
                                          transaction.formattedDate,
                                          style: TextStyle(
                                            fontFamily: 'ClashDisplay',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white.withAlpha((0.5 * 255).round()),
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

                  // Empty state
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
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 60,
                                  color: Colors.white.withAlpha((0.3* 255).round()),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No recent activity yet',
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withAlpha((0.5 * 255).round()),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start trading to see your activity',
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withAlpha((0.3 * 255).round()),
                                  ),
                                ),
                              ],
                            ),
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
                          color: const Color(0xFFE5BCE7).withAlpha((0.2 * 255).round()),
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
                                color: Colors.white.withAlpha((0.5 * 255).round()),
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
                                color: Colors.white.withAlpha((0.5 * 255).round()),
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
                  // Handle buy action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navigate to Market tab to buy assets'),
                      backgroundColor: Color(0xFFE5BCE7),
                    ),
                  );
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
                  // Handle sell action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navigate to Watchlist to sell assets'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
          border: Border.all(color: color.withAlpha((0.3 * 255).round()), width: 1),
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

// Learn Screen
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xff0a0a0a),
        elevation: 0,
        title: const Text(
          'Learn',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: Color(0xFFE5BCE7)),
            SizedBox(height: 20),
            Text(
              'Learn Trading',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Educational content coming soon...',
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
