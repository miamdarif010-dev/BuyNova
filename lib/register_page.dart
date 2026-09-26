import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword =
        _confirmPasswordController.text;

    if (name.isEmpty) {
      _showMessage('আপনার নাম লিখুন');
      return;
    }

    if (email.isEmpty) {
      _showMessage('আপনার ইমেইল লিখুন');
      return;
    }

    if (password.isEmpty) {
      _showMessage('একটি পাসওয়ার্ড দিন');
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage(
        'পাসওয়ার্ড আবার লিখুন',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'দুইটি পাসওয়ার্ড একই নয়',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    UserCredential? credential;

    try {
      credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'registration-failed',
          message: 'User account could not be created.',
        );
      }

      await user.updateDisplayName(name);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': '',
          'profileImageUrl': '',
          'sellerStatus': 'none',
          'entrepreneurStatus': 'none',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'অ্যাকাউন্ট সফলভাবে তৈরি হয়েছে',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage =
          'অ্যাকাউন্ট তৈরি করতে সমস্যা হয়েছে';

      if (e.code == 'email-already-in-use') {
        errorMessage =
            'এই ইমেইল দিয়ে ইতিমধ্যে একটি অ্যাকাউন্ট আছে';
      } else if (e.code == 'invalid-email') {
        errorMessage =
            'ইমেইল ফরম্যাট সঠিক নয়';
      } else if (e.code == 'weak-password') {
        errorMessage =
            'পাসওয়ার্ডটি খুব দুর্বল। আরও শক্তিশালী পাসওয়ার্ড দিন';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage =
            'Email/Password Login Firebase-এ চালু করা নেই';
      } else if (e.code == 'network-request-failed') {
        errorMessage =
            'ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন';
      } else if (e.code == 'too-many-requests') {
        errorMessage =
            'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন';
      }

      if (mounted) {
        _showMessage(
          errorMessage,
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'অ্যাকাউন্ট তৈরি করতে সমস্যা হয়েছে',
          isError: true,
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

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              const CircleAvatar(
                radius: 40,
                backgroundColor:
                    Color(0xFFDCE8F8),
                child: Icon(
                  Icons.person_add,
                  size: 40,
                  color: Color(0xFF326295),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Create your BuyNova account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Join BuyNova and start shopping',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: _nameController,
                textCapitalization:
                    TextCapitalization.words,
                textInputAction:
                    TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(
                    Icons.person_outline,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
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
                textInputAction:
                    TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller:
                    _confirmPasswordController,
                obscureText:
                    _obscureConfirmPassword,
                textInputAction:
                    TextInputAction.done,
                onSubmitted: (_) {
                  if (!_isLoading) {
                    _handleRegister();
                  }
                },
                decoration: InputDecoration(
                  labelText:
                      'Confirm Password',
                  prefixIcon: const Icon(
                    Icons.lock_reset,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                  border:
                      const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF326295),
                    disabledBackgroundColor:
                        const Color(0xFF9AAEC4),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : _handleRegister,
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    color: Color(0xFF326295),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

