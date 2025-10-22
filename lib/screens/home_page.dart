import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/models/models.dart';
import 'market_screen.dart';
import 'watchlist_screen.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0a0a0a),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFFE5BCE7),
        unselectedItemColor: Colors.white.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'ClashDisplay',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'ClashDisplay',
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            activeIcon: Icon(Icons.trending_up),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_bitcoin),
            activeIcon: Icon(Icons.currency_bitcoin),
            label: 'Crypto',
          ),
        ],
      ),
    );
  }

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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
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
                          print('Notification tapped');
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
                          // Handle profile tap
                          print('Profile tapped');
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
                          color: Colors.white.withOpacity(0.1),
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
                  
                  if (state is TransactionLoaded && state.transactions.isNotEmpty) {
                    // Show only the last 5 transactions
                    final recentTransactions = state.transactions.take(5).toList();
                    
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
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
                                color: Colors.white.withOpacity(0.1),
                                height: 24,
                              ),
                              itemBuilder: (context, index) {
                                final transaction = recentTransactions[index];
                                final isBuy = transaction.transactionType == TransactionType.buy;
                                
                                return Row(
                                  children: [
                                    // Icon
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: (isBuy ? Colors.green : Colors.red).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isBuy ? Colors.green : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Asset details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                            '${transaction.quantity} shares @ ${transaction.pricePerUnit.toStringAsFixed(2)} ST',
                                            style: TextStyle(
                                              fontFamily: 'ClashDisplay',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.white.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Amount
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isBuy ? '-' : '+'}${transaction.totalAmount.toStringAsFixed(2)} ST',
                                          style: TextStyle(
                                            fontFamily: 'ClashDisplay',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isBuy ? Colors.red : Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          transaction.formattedDate,
                                          style: TextStyle(
                                            fontFamily: 'ClashDisplay',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white.withOpacity(0.5),
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
                        color: Colors.white.withOpacity(0.1),
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
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No recent activity yet',
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start trading to see your activity',
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.3),
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
                  color: Colors.white.withOpacity(0.1),
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
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5BCE7).withOpacity(0.2),
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
                    '${totalBalance.toStringAsFixed(2)} ST',
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
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${stonkBalance.toStringAsFixed(2)} ST',
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
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${portfolioValue.toStringAsFixed(2)} ST',
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
                          profitLoss >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: profitLoss >= 0 ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${profitLoss >= 0 ? '+' : ''}${profitLossPercentage.toStringAsFixed(2)}% (${profitLoss >= 0 ? '+' : ''}${profitLoss.toStringAsFixed(2)} ST)',
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

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
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
            Icon(
              Icons.school,
              size: 80,
              color: Color(0xFFE5BCE7),
            ),
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
            Icon(
              Icons.currency_bitcoin,
              size: 80,
              color: Color(0xFFE5BCE7),
            ),
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
