import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:virtual_trading_app/onboarding/onboarding.dart';
import 'package:virtual_trading_app/screens/home_page.dart';
import '../core/services/price_monitor_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/blocs/blocs.dart';
import '../core/repositories/transaction_repository.dart';
import '../core/models/transaction.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<List<Transaction>>? _txSub;

  @override
  void dispose() {
    _txSub?.cancel();
    PriceMonitorService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Listen to auth state changes.
      stream: Supabase.instance.client.auth.onAuthStateChange,
      // Set initial data to current session state
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      // Build the appropriate page based on the auth state
      builder: (context, snapshot) {
        // loading...
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xff0a0a0a),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE5BCE7)),
            ),
          );
        }

        final session = snapshot.data?.session;

        if (session != null) {
          // Start price monitor when authenticated
          PriceMonitorService().start();

          // Listen to transactions and refresh holdings on changes
          _txSub?.cancel();
          _txSub = TransactionRepository().watchTransactions().listen((_) {
            if (mounted) {
              // Refresh holdings and orders to reflect auto-sells
              context.read<HoldingsBloc>().add(const RefreshHoldings());
              context.read<OrderBloc>().add(const LoadPendingOrders());
            }
          });
          return const HomePage();
        } else {
          // Stop monitor when logged out
          PriceMonitorService().stop();
          _txSub?.cancel();
          _txSub = null;
          return const Onboarding();
        }
      },
    );
  }
}
