import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/blocs/blocs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //supabase setup
  await Supabase.initialize(
    url: 'https://edmeobztjodvmichfmej.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVkbWVvYnp0am9kdm1pY2hmbWVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4ODAwOTQsImV4cCI6MjA3NjQ1NjA5NH0.ZQi5iPj6JE7Ft_jVq7fBAib4C6BrQ7Lztmd5AMB3zzo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => UserBloc()..add(const LoadUserProfile()),
        ),
        BlocProvider(
          create: (context) => HoldingsBloc()..add(const LoadHoldings()),
        ),
        BlocProvider(
          create: (context) => TransactionBloc(),
        ),
        BlocProvider(
          create: (context) => WatchlistBloc()..add(const LoadWatchlist()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stonks',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          appBarTheme: const AppBarTheme(
            iconTheme: IconThemeData(color: Colors.white),
            actionsIconTheme: IconThemeData(color: Colors.white),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
