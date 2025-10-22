import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../core/blocs/blocs.dart';
import '../auth/auth_gate.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xff0a0a0a),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showEditProfileDialog(context),
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE5BCE7),
              ),
            );
          }
          
          if (state is UserError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.read<UserBloc>().add(const RefreshUserProfile());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5BCE7),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          if (state is UserLoaded) {
            final profile = state.profile;
            
            return RefreshIndicator(
              color: const Color(0xFFE5BCE7),
              onRefresh: () async {
                context.read<UserBloc>().add(const RefreshUserProfile());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Avatar
                    _buildAvatar(context, profile.avatarUrl),
                    
                    const SizedBox(height: 24),
                    
                    // User Name
                    Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Email
                    Text(
                      profile.email,
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Stonk Balance Card
                    _buildBalanceCard(profile.stonkBalance),
                    
                    const SizedBox(height: 24),
                    
                    // Portfolio Stats
                    _buildPortfolioStats(context),
                    
                    const SizedBox(height: 24),
                    
                    // Settings Section
                    _buildSettingsSection(context),
                    
                    const SizedBox(height: 32),
                    
                    // Logout Button
                    _buildLogoutButton(context),
                    
                    const SizedBox(height: 20),
                    
                    // Account Info
                    Text(
                      'Member since ${_formatDate(profile.createdAt)}',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String? avatarUrl) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE5BCE7),
              width: 3,
            ),
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar();
                    },
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        
        // Upload button
        Positioned(
          bottom: 0,
          right: 0,
          child: BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              final isUploading = state is UserUploadingAvatar;
              
              return GestureDetector(
                onTap: isUploading ? null : () => _pickAndUploadImage(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5BCE7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xff0a0a0a),
                      width: 2,
                    ),
                  ),
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 18,
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xff1a1a1a),
      child: const Icon(
        Icons.person,
        size: 60,
        color: Color(0xFFE5BCE7),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5BCE7), Color(0xFFB88FBA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5BCE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${balance.toStringAsFixed(2)} ST',
            style: const TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stonk Tokens',
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioStats(BuildContext context) {
    return BlocBuilder<HoldingsBloc, HoldingsState>(
      builder: (context, state) {
        double totalValue = 0.0;
        double totalInvested = 0.0;
        double profitLoss = 0.0;
        int holdingsCount = 0;
        
        if (state is HoldingsLoaded) {
          totalValue = state.totalValue;
          totalInvested = state.totalInvested;
          profitLoss = state.totalProfitLoss;
          holdingsCount = state.holdings.length;
        }
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xff1a1a1a),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Portfolio Summary',
                style: TextStyle(
                  fontFamily: 'ClashDisplay',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Holdings',
                      holdingsCount.toString(),
                      Icons.pie_chart,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Invested',
                      '${totalInvested.toStringAsFixed(0)} ST',
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Value',
                      '${totalValue.toStringAsFixed(0)} ST',
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'P&L',
                      '${profitLoss >= 0 ? '+' : ''}${profitLoss.toStringAsFixed(0)} ST',
                      profitLoss >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      valueColor: profitLoss >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFE5BCE7),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff1a1a1a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () => _showEditProfileDialog(context),
          ),
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            indent: 60,
          ),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings coming soon'),
                  ),
                );
              },
              activeColor: const Color(0xFFE5BCE7),
            ),
          ),
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            indent: 60,
          ),
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Security',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Security settings coming soon'),
                ),
              );
            },
          ),
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            indent: 60,
          ),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support coming soon'),
                ),
              );
            },
          ),
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            indent: 60,
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE5BCE7).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFFE5BCE7),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'ClashDisplay',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      trailing: trailing ?? const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.red.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.logout,
              color: Colors.red,
            ),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null && context.mounted) {
        context.read<UserBloc>().add(UploadUserAvatar(image.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final userState = context.read<UserBloc>().state;
    if (userState is! UserLoaded) return;
    
    final nameController = TextEditingController(text: userState.profile.fullName);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(
            fontFamily: 'ClashDisplay',
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: TextStyle(
              fontFamily: 'ClashDisplay',
              color: Colors.white.withOpacity(0.5),
            ),
            filled: true,
            fillColor: const Color(0xff0a0a0a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              Navigator.pop(dialogContext);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                context.read<UserBloc>().add(
                  UpdateUserProfile(fullName: newName),
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              nameController.dispose();
            },
            child: const Text(
              'Save',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Color(0xFFE5BCE7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              // Sign out from Supabase
              await Supabase.instance.client.auth.signOut();
              
              // Navigate to AuthGate (which will show onboarding/login)
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthGate()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff1a1a1a),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(
              Icons.trending_up,
              color: Color(0xFFE5BCE7),
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'About Stonks',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stonks - Virtual Trading App',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Learn trading with virtual Stonk Tokens. Buy and sell stocks, crypto, and mutual funds in a risk-free environment.',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2025 Stonks. All rights reserved.',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Color(0xFFE5BCE7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
