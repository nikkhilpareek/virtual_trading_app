import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import '../core/utils/currency_formatter.dart';
import 'market_screen.dart';
import 'assets_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'learn_screen.dart';
import 'crypto_screen.dart';
import 'orders_screen.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView(
        controller: _pageController,
        // Use page scroll physics for smoother snapping between pages.
        // This makes light swipes snap reliably to the next page without jitter.
        physics: const PageScrollPhysics(),
        pageSnapping: true,
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
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.7 * 255).round());

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

Widget _buildTopPerformers(BuildContext context) {
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
    // Ensure the top-performers container keeps a reasonable minimum height
    // so it doesn't collapse when its internal list is short or the page
    // rebuilds often. Use a minHeight rather than a fixed height so it can
    // still grow when needed on larger displays.
    constraints: const BoxConstraints(minHeight: 200),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).dividerColor, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Top Performer of the Week',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        // Vertical list showing only top 5, shrink-wrapped so the outer container
        // sizes itself exactly to the list contents (no extra bottom space).
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          // small cache to keep nearby items ready during fast scrolls
          cacheExtent: 200,
          addRepaintBoundaries: true,
          itemCount: topStocks.length > 5 ? 5 : topStocks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final s = topStocks[index];
            final symbol = s['symbol'] as String;
            final name = s['name'] as String;
            final price = s['price'] as double;
            final change = s['change'] as double;
            final positive = change >= 0;

            return Container(
              // let the item take available width in vertical list
              width: double.infinity,
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
                            color: Colors.white.withAlpha((0.7 * 255).round()),
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

        const SizedBox(height: 12),
        // Centered See more button at the bottom of the same container
        Center(
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('See more clicked')));
            },
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'See more',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
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
  // Keep last total balance to animate from previous value instead of always
  // starting from zero which can cause visual glitches.
  double _lastTotalBalance = 0.0;
  @override
  void initState() {
    super.initState();
    // Load transactions when dashboard loads
    context.read<TransactionBloc>().add(const LoadTransactions(limit: 10));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        color: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _ProfileAvatarButton(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () async {
          // Trigger refresh events for primary data shown on the dashboard
          context.read<UserBloc>().add(const RefreshUserProfile());
          context.read<HoldingsBloc>().add(const RefreshHoldings());
          context.read<TransactionBloc>().add(
            const LoadTransactions(limit: 10),
          );
          // Small delay to allow blocs to process and UI to update
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        // Give Recent Activity a minimum height so the card
                        // doesn't shrink to a very small size when there are
                        // few or no items. This keeps the layout stable on
                        // refreshes.
                        constraints: const BoxConstraints(minHeight: 180),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
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
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
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
                            // Show only top 2 recent activities (non-scrollable)
                            Builder(
                              builder: (context) {
                                final items = recentTransactions
                                    .take(2)
                                    .toList();
                                return Column(
                                  children: [
                                    for (var i = 0; i < items.length; i++) ...[
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color:
                                                  (items[i].transactionType ==
                                                              TransactionType
                                                                  .buy
                                                          ? Colors.green
                                                          : Colors.red)
                                                      .withAlpha(
                                                        (0.1 * 255).round(),
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              items[i].transactionType ==
                                                      TransactionType.buy
                                                  ? Icons.arrow_downward
                                                  : Icons.arrow_upward,
                                              color:
                                                  items[i].transactionType ==
                                                      TransactionType.buy
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
                                                  items[i].assetSymbol,
                                                  style: TextStyle(
                                                    fontFamily: 'ClashDisplay',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${items[i].quantity} shares @ ${CurrencyFormatter.formatINR(items[i].pricePerUnit)}',
                                                  style: TextStyle(
                                                    fontFamily: 'ClashDisplay',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.white
                                                        .withAlpha(
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
                                                '${items[i].transactionType == TransactionType.buy ? '-' : '+'}${CurrencyFormatter.formatINR(items[i].totalAmount).replaceAll('₹', '')}',
                                                style: TextStyle(
                                                  fontFamily: 'ClashDisplay',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      items[i].transactionType ==
                                                          TransactionType.buy
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                items[i].formattedDate,
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
                                      ),
                                      if (i != items.length - 1)
                                        Divider(
                                          color: Colors.white.withAlpha(
                                            (0.1 * 255).round(),
                                          ),
                                          height: 24,
                                        ),
                                    ],
                                    const SizedBox(height: 12),
                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                          _showAllActivitiesBottomSheet(
                                            context,
                                            state.transactions,
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Show all',
                                          style: TextStyle(
                                            fontFamily: 'ClashDisplay',
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
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
                              color: Colors.white.withAlpha(
                                (0.3 * 255).round(),
                              ),
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
                _buildTopPerformers(context),
                const SizedBox(height: 100),
              ],
            ),
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.info,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Total balance amount with animation from 0 -> totalBalance
                  TweenAnimationBuilder<double>(
                    // Animate from the previous total balance to the new value to
                    // avoid flashing other numbers (like "Available") during
                    // rebuilds. Use the stored _lastTotalBalance as begin.
                    tween: Tween(begin: _lastTotalBalance, end: totalBalance),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        CurrencyFormatter.formatINR(value),
                        style: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      );
                    },
                    onEnd: () {
                      // When animation finishes, update the stored last value so
                      // future animations start from the current balance.
                      _lastTotalBalance = totalBalance;
                    },
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
                Theme.of(context).colorScheme.primary,
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
        // Orders Button - Full width
        _buildActionButton(
          'View Orders',
          Icons.pending_actions,
          const Color(0xFFE5BCE7),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            );
          },
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

  /// Show all recent activities in a bottom sheet
  void _showAllActivitiesBottomSheet(
    BuildContext context,
    List<Transaction> transactions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75, // 3/4th of the screen
        minChildSize: 0.5,
        maxChildSize: 0.75, // Maximum 3/4th of the screen
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Activities',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${transactions.length} transactions',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha((0.6 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List of transactions
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isBuy =
                        transaction.transactionType == TransactionType.buy;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (isBuy ? Colors.green : Colors.red)
                                  .withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isBuy ? Colors.green : Colors.red,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Transaction details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      transaction.assetSymbol,
                                      style: const TextStyle(
                                        fontFamily: 'ClashDisplay',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatINR(
                                        transaction.totalAmount,
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'ClashDisplay',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isBuy
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${transaction.quantity.toStringAsFixed(2)} @ ${CurrencyFormatter.formatINR(transaction.pricePerUnit)}',
                                      style: TextStyle(
                                        fontFamily: 'ClashDisplay',
                                        fontSize: 12,
                                        color: Colors.white.withAlpha(
                                          (0.6 * 255).round(),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isBuy ? Colors.green : Colors.red)
                                                .withAlpha((0.2 * 255).round()),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isBuy ? 'BUY' : 'SELL',
                                        style: TextStyle(
                                          fontFamily: 'ClashDisplay',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isBuy
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTime(transaction.createdAt),
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: 11,
                                    color: Colors.white.withAlpha(
                                      (0.5 * 255).round(),
                                    ),
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Reusable profile avatar button that shows Google/Supabase user avatar if available.
class _ProfileAvatarButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    String? avatarUrl;
    final meta = user?.userMetadata;
    if (meta != null) {
      // Check common keys that might contain avatar URL
      avatarUrl =
          (meta['avatar_url'] ?? meta['picture'] ?? meta['avatar']) as String?;
    }

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: Icon(Icons.person, color: Colors.black, size: 20),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.person, color: Colors.black, size: 20),
                ),
              )
            : const Icon(Icons.person, color: Colors.black, size: 20),
      ),
    );
  }
}
