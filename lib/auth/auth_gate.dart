import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:virtual_trading_app/onboarding/onboarding.dart';
import 'package:virtual_trading_app/screens/home_page.dart';
import '../core/services/price_monitor_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
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
          return const HomePage();
        } else {
          // Stop monitor when logged out
          PriceMonitorService().stop();
          return const Onboarding();
        }
      },
    );
  }
}
