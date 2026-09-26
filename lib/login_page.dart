import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isResettingPassword = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ইমেইল ও পাসওয়ার্ড প্রদান করুন'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'লগইন করতে সমস্যা হয়েছে';

      if (e.code == 'user-not-found') {
        errorMessage = 'এই ইমেইলে কোনো অ্যাকাউন্ট পাওয়া যায়নি';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'ভুল পাসওয়ার্ড দিয়েছেন';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'ইমেইল ফরম্যাট সঠিক নয়';
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'ইমেইল অথবা পাসওয়ার্ড সঠিক নয়';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'এই অ্যাকাউন্টটি বর্তমানে বন্ধ আছে';
      } else if (e.code == 'too-many-requests') {
        errorMessage =
            'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন';
      } else if (e.code == 'network-request-failed') {
        errorMessage =
            'ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'প্রথমে আপনার ইমেইল লিখুন',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isResettingPassword = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'পাসওয়ার্ড রিসেট করার লিংক আপনার ইমেইলে পাঠানো হয়েছে',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage =
          'পাসওয়ার্ড রিসেট করতে সমস্যা হয়েছে';

      if (e.code == 'invalid-email') {
        errorMessage = 'ইমেইল ফরম্যাট সঠিক নয়';
      } else if (e.code == 'user-not-found') {
        errorMessage =
            'এই ইমেইলে কোনো অ্যাকাউন্ট পাওয়া যায়নি';
      } else if (e.code == 'user-disabled') {
        errorMessage =
            'এই অ্যাকাউন্টটি বর্তমানে বন্ধ আছে';
      } else if (e.code == 'too-many-requests') {
        errorMessage =
            'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন';
      } else if (e.code == 'network-request-failed') {
        errorMessage =
            'ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'পাসওয়ার্ড রিসেট করতে সমস্যা হয়েছে',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFDCE8F8),
                child: Icon(
                  Icons.shopping_bag,
                  size: 40,
                  color: Color(0xFF326295),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'BuyNova',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Text(
                'Everything you love, in one place.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_isLoading) {
                    _handleLogin();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ||
                          _isResettingPassword
                      ? null
                      : _handleForgotPassword,
                  child: _isResettingPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF326295),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF326295),
                    disabledBackgroundColor:
                        const Color(0xFF9AAEC4),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(25),
                    ),
                  ),
                  onPressed:
                      _isLoading || _isResettingPassword
                          ? null
                          : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



