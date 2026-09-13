import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile_page.dart';
import 'settings_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;

  String _name = '';
  String _phone = '';
  String _profileImageUrl = '';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // =========================================================
  // LOAD USER DATA
  // =========================================================

  Future<void> _loadUserData() async {
    final user = currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        if (mounted) {
          setState(() {
            _name = data['name'] ?? '';
            _phone = data['phone'] ?? '';
            _profileImageUrl = data['profileImageUrl'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Profile loading error: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // =========================================================
  // EDIT PROFILE
  // =========================================================

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfilePage(),
      ),
    );

    _loadUserData();
  }

  // =========================================================
  // SETTINGS
  // =========================================================

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  // =========================================================
  // COMING SOON
  // =========================================================

  void _comingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pop(context);
  }

  // =========================================================
  // PROFILE IMAGE
  // =========================================================

  Widget _profileImage() {
    if (_profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 58,
        backgroundImage: NetworkImage(_profileImageUrl),
      );
    }

    return const CircleAvatar(
      radius: 58,
      child: Icon(
        Icons.person,
        size: 62,
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
        top: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MENU ITEM
  // =========================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 2,
        ),
        leading: Icon(
          icon,
          color: isDanger ? Colors.red : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDanger ? Colors.red : null,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDanger ? Colors.red : null,
        ),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // =================================================
                  // PROFILE HEADER
                  // =================================================

                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        _profileImage(),

                        const SizedBox(height: 14),

                        Text(
                          _name.isEmpty ? 'User' : _name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          user?.email ?? 'No Email',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        if (_phone.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _phone,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _openEditProfile,
                            icon: const Icon(Icons.edit),
                            label: const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // BUYER
                  // =================================================

                  _sectionTitle(
                    icon: Icons.shopping_bag_outlined,
                    title: 'BUYER',
                  ),

                  _menuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Orders',
                    onTap: () => _comingSoon('My Orders'),
                  ),

                  _menuItem(
                    icon: Icons.favorite_border,
                    title: 'Favorites',
                    onTap: () => _comingSoon('Favorites'),
                  ),

                  _menuItem(
                    icon: Icons.shopping_cart_outlined,
                    title: 'My Cart',
                    onTap: () => _comingSoon('My Cart'),
                  ),

                  _menuItem(
                    icon: Icons.history,
                    title: 'Recently Viewed',
                    onTap: () => _comingSoon('Recently Viewed'),
                  ),

                  _menuItem(
                    icon: Icons.local_offer_outlined,
                    title: 'Coupons',
                    onTap: () => _comingSoon('Coupons'),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // SELLER
                  // =================================================

                  _sectionTitle(
                    icon: Icons.store_outlined,
                    title: 'SELLER',
                  ),

                  _menuItem(
                    icon: Icons.storefront_outlined,
                    title: 'Shop Profile',
                    onTap: () => _comingSoon('Shop Profile'),
                  ),

                  _menuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Shop Location',
                    onTap: () => _comingSoon('Shop Location'),
                  ),

                  _menuItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'My Products',
                    onTap: () => _comingSoon('My Products'),
                  ),

                  _menuItem(
                    icon: Icons.add_box_outlined,
                    title: 'Add Product',
                    onTap: () => _comingSoon('Add Product'),
                  ),

                  _menuItem(
                    icon: Icons.edit_outlined,
                    title: 'Edit Product',
                    onTap: () => _comingSoon('Edit Product'),
                  ),

                  _menuItem(
                    icon: Icons.delete_outline,
                    title: 'Delete Product',
                    onTap: () => _comingSoon('Delete Product'),
                  ),

                  _menuItem(
                    icon: Icons.bar_chart_outlined,
                    title: 'Sales / Orders',
                    onTap: () => _comingSoon('Sales / Orders'),
                  ),

                  _menuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Earnings',
                    onTap: () => _comingSoon('Earnings'),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // COMMUNICATION
                  // =================================================

                  _sectionTitle(
                    icon: Icons.forum_outlined,
                    title: 'COMMUNICATION',
                  ),

                  _menuItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat',
                    onTap: () => _comingSoon('Chat'),
                  ),

                  _menuItem(
                    icon: Icons.message_outlined,
                    title: 'Messages',
                    onTap: () => _comingSoon('Messages'),
                  ),

                  _menuItem(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    onTap: () => _comingSoon('Notifications'),
                  ),

                  _menuItem(
                    icon: Icons.support_agent_outlined,
                    title: 'Contact Us',
                    onTap: () => _comingSoon('Contact Us'),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // ACCOUNT
                  // =================================================

                  _sectionTitle(
                    icon: Icons.manage_accounts_outlined,
                    title: 'ACCOUNT',
                  ),

                  _menuItem(
                    icon: Icons.security_outlined,
                    title: 'Account & Security',
                    onTap: () => _comingSoon('Account & Security'),
                  ),

                  _menuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: _openSettings,
                  ),

                  const SizedBox(height: 8),

                  _menuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: _logout,
                    isDanger: true,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
