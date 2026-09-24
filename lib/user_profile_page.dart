import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'buyer_page.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'admin_panel_page.dart';
import 'entrepreneur_page.dart';
import 'watch_earn_page.dart';
import 'seller_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  String _name = '';
  String _phone = '';
  String _profileImageUrl = '';

  String _sellerStatus = '';
  String _entrepreneurStatus = '';
  String _role = '';

  int _pointsBalance = 0;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  // =========================================================
  // ADMIN CHECK
  // =========================================================

  bool get _isAdmin {
    return _role.toLowerCase() == 'admin' ||
        currentUser?.email?.toLowerCase() ==
            'miamdarif010@gmail.com';
  }

  bool get _isSellerApproved =>
      _sellerStatus.toLowerCase() == 'approved';

  bool get _isEntrepreneurApproved =>
      _entrepreneurStatus.toLowerCase() == 'approved';

  // =========================================================
  // INIT / DISPOSE
  // =========================================================

  @override
  void initState() {
    super.initState();
    _listenUserData();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  // =========================================================
  // LIVE USER DATA
  // =========================================================

  void _listenUserData() {
    final user = currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
      (doc) {
        _applyUserData(doc.data());
      },
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not load profile: $error',
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadUserData() async {
    final user = currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      _applyUserData(doc.data());
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load profile: $error',
          ),
        ),
      );
    }
  }

  void _applyUserData(
    Map<String, dynamic>? data,
  ) {
    if (!mounted) return;

    final rawPoints = data?['pointsBalance'];

    int points = 0;

    if (rawPoints is num) {
      points = rawPoints.toInt();
    } else if (rawPoints != null) {
      points = int.tryParse(
            rawPoints.toString(),
          ) ??
          0;
    }

    setState(() {
      _name = (data?['name'] ?? '').toString();

      _phone = (data?['phone'] ?? '').toString();

      _profileImageUrl =
          (data?['profileImageUrl'] ?? '').toString();

      _sellerStatus =
          (data?['sellerStatus'] ?? '').toString();

      _entrepreneurStatus =
          (data?['entrepreneurStatus'] ?? '').toString();

      _role = (data?['role'] ?? '').toString();

      _pointsBalance = points;

      _isLoading = false;
    });
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _push(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  void _openEditProfile() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => const EditProfilePage(),
      ),
    )
        .then((_) {
      _loadUserData();
    });
  }

  // ADMIN → DIRECT PAGE
  void _openAdmin() {
    _push(const AdminPanelPage());
  }

  // BUYER → DIRECT PAGE
  void _openBuyer() {
    _push(const BuyerPage());
  }

  // RESELLER → DIRECT PAGE
  void _openReseller() {
    _push(const EntrepreneurPage());
  }

  // SELLER → DIRECT PAGE
  void _openSeller() {
    _push(const SellerPage());
  }

  // EARN → DIRECT PAGE
  void _openEarn() {
    _push(const WatchEarnPage());
  }

  // SETTINGS → DIRECT PAGE
  void _openSettings() {
    _push(const SettingsPage());
  }

  // =========================================================
  // SELLER APPLICATION
  // =========================================================

  Future<void> _becomeSeller() async {
    final user = currentUser;

    if (user == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': _name.isNotEmpty
              ? _name
              : 'BuyNova User',
          'email': user.email ?? '',
          'sellerStatus': 'pending',
          'sellerRequestedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller request submitted successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit seller request: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // =========================================================
  // RESELLER APPLICATION
  // =========================================================

  Future<void> _becomeEntrepreneur() async {
    final user = currentUser;

    if (user == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': _name.isNotEmpty
              ? _name
              : 'BuyNova User',
          'email': user.email ?? '',
          'entrepreneurStatus': 'pending',
          'entrepreneurRequestedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reseller request submitted successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit reseller request: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: $error',
          ),
        ),
      );
    }
  }

  // =========================================================
  // PROFILE IMAGE
  // =========================================================

  Widget _profileImage() {
    if (_profileImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _profileImageUrl,
          width: 78,
          height: 78,
          fit: BoxFit.cover,
          loadingBuilder: (
            context,
            child,
            loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return const SizedBox(
              width: 78,
              height: 78,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const Icon(
              Icons.person,
              size: 44,
              color: Colors.grey,
            );
          },
        ),
      );
    }

    return const Icon(
      Icons.person,
      size: 44,
      color: Colors.grey,
    );
  }

  // =========================================================
  // PROFILE MENU CARD
  // =========================================================

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? Colors.redAccent;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // SIMPLE MENU ITEM
  // =========================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // LOGOUT DIALOG
  // =========================================================

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Please log in to view your profile.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (_isSubmitting)
                      const Padding(
                        padding:
                            EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(),
                      ),

                    // =================================================
                    // PROFILE
                    // =================================================

                    Card(
                      elevation: 0,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _openEditProfile,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration:
                                    BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      Colors.grey.shade200,
                                ),
                                child: _profileImage(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              _name.isNotEmpty
                                  ? _name
                                  : 'BuyNova User',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              user.email ?? '',
                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),

                            if (_phone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _phone,
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _openEditProfile,
                                icon: const Icon(
                                  Icons.edit_outlined,
                                ),
                                label: const Text(
                                  'Edit Profile',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // ADMIN PANEL
                    // EDIT PROFILE-এর ঠিক নিচে
                    // =================================================

                    if (_isAdmin)
                      _sectionCard(
                        icon: Icons
                            .admin_panel_settings_outlined,
                        title: 'ADMIN PANEL',
                        subtitle:
                            'Manage BuyNova from the admin panel.',
                        onTap: _openAdmin,
                        iconColor: Colors.red,
                      ),

                    // =================================================
                    // BUYER / CUSTOMER
                    // DIRECT PAGE
                    // কোনো EXPAND / DROPDOWN নেই
                    // =================================================

                    _sectionCard(
                      icon:
                          Icons.shopping_bag_outlined,
                      title: 'BUYER / CUSTOMER',
                      subtitle:
                          'Shopping, orders, favorites and buyer tools.',
                      onTap: _openBuyer,
                      iconColor: Colors.redAccent,
                    ),

                    // =================================================
                    // RESELLER
                    // DIRECT PAGE
                    // =================================================

                    _sectionCard(
                      icon:
                          Icons.business_center_outlined,
                      title: 'RESELLER',
                      subtitle:
                          _isEntrepreneurApproved
                              ? 'Manage your reseller business.'
                              : _entrepreneurStatus ==
                                      'pending'
                                  ? 'Reseller request is pending.'
                                  : _entrepreneurStatus ==
                                          'rejected'
                                      ? 'Reseller request was rejected.'
                                      : 'Apply to become a BuyNova reseller.',
                      onTap: _openReseller,
                      iconColor: Colors.deepOrange,
                    ),

                    // =================================================
                    // SELLER
                    // DIRECT PAGE
                    // =================================================

                    _sectionCard(
                      icon:
                          Icons.storefront_outlined,
                      title: 'SELLER',
                      subtitle:
                          _isSellerApproved
                              ? 'Manage your seller business.'
                              : _sellerStatus ==
                                      'pending'
                                  ? 'Seller request is pending.'
                                  : _sellerStatus ==
                                          'rejected'
                                      ? 'Seller request was rejected.'
                                      : 'Apply to sell products on BuyNova.',
                      onTap: _openSeller,
                      iconColor: Colors.blue,
                    ),

                    // =================================================
                    // EARN & REWARDS
                    // =================================================

                    _sectionCard(
                      icon: Icons.stars_outlined,
                      title: 'EARN & REWARDS',
                      subtitle:
                          'Points, Watch & Earn and rewards.',
                      onTap: _openEarn,
                      iconColor: Colors.orange,
                    ),

                    const SizedBox(height: 6),

                    // =================================================
                    // SETTINGS
                    // =================================================

                    _menuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: _openSettings,
                    ),

                    // =================================================
                    // LOGOUT
                    // =================================================

                    _menuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      iconColor: Colors.red,
                      onTap: _showLogoutDialog,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
