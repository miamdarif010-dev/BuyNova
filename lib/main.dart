import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'home_page.dart';
import 'app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await AppSettings.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'BuyNova',
          debugShowCheckedModeBanner: false,

          themeMode: themeMode,

          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.redAccent,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.redAccent,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),

          home: const HomePage(),
        );
      },
    );
  }
}
