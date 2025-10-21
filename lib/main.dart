import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{

  //supabase setup
  await Supabase.initialize(
    url: 'https://edmeobztjodvmichfmej.supabase.co',
    anonKey: 'sb_publishable_-DSF2QJyQ860fN9mEnKHRg__IlB3CLp',
  );


  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Trading App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // ignore: deprecated_member_use
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: const AuthGate(),
    );
  }
}
