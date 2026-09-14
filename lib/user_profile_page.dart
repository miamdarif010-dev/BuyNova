import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'add_product_page.dart';
import 'cart_page.dart';
import 'admin_panel_page.dart';
import 'my_products_page.dart';

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
  String _sellerStatus = 'none'; // none | pending | approved | rejected

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get _isAdmin => currentUser?.email == kAdminEmail;

  // =========================================================
  // LOAD USER DATA
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = currentUser;

    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
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
            _sellerStatus = data['sellerStatus']?.toString() ?? 'none';
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
  // NAVIGATION HELPERS
  // =========================================================

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    );
    _loadUserData();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  Future<void> _openAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductPage()),
    );
  }

  Future<void> _openMyProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyProductsPage()),
    );
  }

  Future<void> _openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );
  }

  Future<void> _openAdminPanel() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminPanelPage()),
    );
  }

  void _comingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // BECOME A SELLER
  // =========================================================

  Future<void> _becomeSeller() async {
    final user = currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Become a Seller'),
        content: const Text(
          'Send a request to become a seller? An admin will review and approve your request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'name': _name,
        'email': user.email,
        'sellerStatus': 'pending',
      },
      SetOptions(merge: true),
    );

    if (!mounted) return;

    setState(() {
      _sellerStatus = 'pending';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seller request sent! Waiting for admin approval.')),
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
  // WIDGET HELPERS
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
      child: Icon(Icons.person, size: 62),
    );
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: isDanger ? Colors.red : null),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDanger ? Colors.red : null,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: isDanger ? Colors.red : null),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // SELLER SECTION CONTENT (depends on sellerStatus)
  // =========================================================

  List<Widget> _sellerSectionItems() {
    if (_sellerStatus == 'approved') {
      return [
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
          onTap: _openMyProducts,
        ),
        _menuItem(
          icon: Icons.add_box_outlined,
          title: 'Add Product',
          onTap: _openAddProduct,
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
      ];
    }

    if (_sellerStatus == 'pending') {
      return [
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.orange.shade50,
          child: const ListTile(
            leading: Icon(Icons.hourglass_top, color: Colors.orange),
            title: Text('Seller request pending'),
            subtitle: Text('An admin is reviewing your request.'),
          ),
        ),
      ];
    }

    if (_sellerStatus == 'rejected') {
      return [
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.red.shade50,
          child: ListTile(
            leading: const Icon(Icons.cancel_outlined, color: Colors.red),
            title: const Text('Seller request rejected'),
            subtitle: const Text('Tap to request again.'),
            onTap: _becomeSeller,
          ),
        ),
      ];
    }

    // status == 'none'
    return [
      _menuItem(
        icon: Icons.storefront_outlined,
        title: 'Become a Seller',
        onTap: _becomeSeller,
      ),
    ];
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user?.email ?? 'No Email',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                        ),
                        if (_phone.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                _phone,
                                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
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
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // ADMIN (only visible to kAdminEmail)
                  // =================================================
                  if (_isAdmin) ...[
                    _sectionTitle(icon: Icons.admin_panel_settings_outlined, title: 'ADMIN'),
                    _menuItem(
                      icon: Icons.dashboard_customize_outlined,
                      title: 'Admin Panel',
                      onTap: _openAdminPanel,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // =================================================
                  // BUYER
                  // =================================================
                  _sectionTitle(icon: Icons.shopping_bag_outlined, title: 'BUYER'),
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
                    onTap: _openCart,
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
                  // SELLER (content depends on sellerStatus)
                  // =================================================
                  _sectionTitle(icon: Icons.store_outlined, title: 'SELLER'),
                  ..._sellerSectionItems(),

                  const SizedBox(height: 16),

                  // =================================================
                  // COMMUNICATION
                  // =================================================
                  _sectionTitle(icon: Icons.forum_outlined, title: 'COMMUNICATION'),
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
                  _sectionTitle(icon: Icons.manage_accounts_outlined, title: 'ACCOUNT'),
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
