import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:virtual_trading_app/onboarding/onboarding.dart';
import 'package:virtual_trading_app/screens/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Listen to auth state changes.
      stream: Supabase.instance.client.auth.onAuthStateChange,

      // Build the appropriate page based on the auth state
      builder: (context,snapshot){
        // loading...
        if(snapshot.connectionState == ConnectionState.waiting){
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if(session != null){
          return HomePage();
        }else{
          return Onboarding();
        }
      }
    );
  }
}