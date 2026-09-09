import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';

void main() async {
  // ফ্ল্যাটার উইজেট বাইন্ডিং ইনিশিয়ালাইজেশন
  WidgetsFlutterBinding.ensureInitialized();
  
  // ফায়ারবেস সার্ভিস চালু করা
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuyNova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF326295),
        ),
        useMaterial3: true,
      ),
      // ফায়ারবেস এর ইউজার স্টেট চেক করে অটোমেটিক স্ক্রিন ডিসিশন
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // ডেটা লোড হওয়ার সময় লোডিং স্পিনার
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // ইউজার আগে থেকে লগইন করা থাকলে সরাসরি HomePage
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          }
          
          // ইউজার লগইন না থাকলে LoginPage
          return const LoginPage();
        },
      ),
    );
  }
}
