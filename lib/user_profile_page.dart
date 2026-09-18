import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'buyer_page.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'admin_panel_page.dart';
import 'my_products_page.dart';
import 'my_videos_page.dart';
import 'entrepreneur_page.dart';
import 'watch_earn_page.dart';
import 'favorites_page.dart';
import 'seller_page.dart';
import 'notifications_page.dart';
import 'seller_messages_page.dart';
import 'earnings_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;

  bool _adminExpanded = false;
  bool _buyerExpanded = false;
  bool _earnExpanded = false;
  bool _entrepreneurExpanded = false;
  bool _sellerExpanded = false;

  String _name = '';
  String _phone = '';
  String _profileImageUrl = '';

  String _sellerStatus = '';
  String _entrepreneurStatus = '';

  int _pointsBalance = 0;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get _isAdmin {
    return currentUser?.email?.toLowerCase() ==
        'miamdarif010@gmail.com';
  }

  bool get _isSellerApproved {
    return _sellerStatus == 'approved';
  }

  bool get _isEntrepreneurApproved {
    return _entrepreneurStatus == 'approved';
  }

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
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      final rawPoints = data?['pointsBalance'];

      int points = 0;

      if (rawPoints is int) {
        points = rawPoints;
      } else if (rawPoints is num) {
        points = rawPoints.toInt();
      } else if (rawPoints != null) {
        points = int.tryParse(
              rawPoints.toString(),
            ) ??
            0;
      }

      if (mounted) {
        setState(() {
          _name = (data?['name'] ?? '').toString();
          _phone = (data?['phone'] ?? '').toString();

          _profileImageUrl =
              (data?['profileImageUrl'] ?? '').toString();

          _sellerStatus =
              (data?['sellerStatus'] ?? '').toString();

          _entrepreneurStatus =
              (data?['entrepreneurStatus'] ?? '').toString();

          _pointsBalance = points;

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not load profile: $e',
            ),
          ),
        );
      }
    }
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfilePage(),
      ),
    ).then((_) {
      _loadUserData();
    });
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _openMyProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyProductsPage(),
      ),
    );
  }

  void _openMyVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyVideosPage(),
      ),
    );
  }

  void _openAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminPanelPage(),
      ),
    );
  }

  void _openBuyer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuyerPage(),
      ),
    );
  }

  void _openEntrepreneur() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EntrepreneurPage(),
      ),
    );
  }

  void _openSellerDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SellerPage(),
      ),
    );
  }

  void _openWatchEarn() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WatchEarnPage(),
      ),
    );
  }

  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesPage(),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );
  }

  // =========================================================
  // SELLER MESSAGES
  // =========================================================

  void _openSellerMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SellerMessagesPage(),
      ),
    );
  }

  // =========================================================
  // SELLER EARNINGS
  // =========================================================

  void _openSellerEarnings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EarningsPage(),
      ),
    );
  }

  // =========================================================
  // FEATURE NOT AVAILABLE
  // =========================================================

  void _featureNotAvailable(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title is coming soon.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // SELLER APPLICATION
  // =========================================================

  Future<void> _becomeSeller() async {
    final user = currentUser;

    if (user == null) return;

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

      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seller request submitted successfully.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not submit seller request: $e',
            ),
          ),
        );
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

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logout failed: $e',
            ),
          ),
        );
      }
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
          errorBuilder:
              (context, error, stackTrace) {
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
  // SECTION HEADER
  // =========================================================

  Widget _expandableSectionHeader({
    required IconData icon,
    required String title,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.redAccent,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          expanded
              ? Icons.keyboard_arrow_up
              : Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // SECTION NOTIFICATION
  // =========================================================

  Widget _sectionNotification() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 8,
      ),
      child: ListTile(
        leading: const Icon(
          Icons.notifications_outlined,
          color: Colors.redAccent,
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: _openNotifications,
      ),
    );
  }

  // =========================================================
  // NORMAL MENU ITEM
  // =========================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool indented = true,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(
        left: indented ? 12 : 0,
        right: indented ? 12 : 0,
        bottom: 8,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
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
  // PLUS MENU ITEM
  // =========================================================

  Widget _plusMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 8,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.redAccent,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.add_circle_outline,
          color: Colors.redAccent,
        ),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // REWARDS SUMMARY
  // =========================================================

  Widget _rewardsSummaryCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: 8,
      ),
      child: ListTile(
        leading: const Icon(
          Icons.stars_outlined,
          color: Colors.orange,
        ),
        title: const Text(
          'My Points',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$_pointsBalance points available',
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: _openWatchEarn,
      ),
    );
  }

  // =========================================================
  // BUYER SECTION
  // =========================================================

  List<Widget> _buyerSectionItems() {
    return [
      _sectionNotification(),

      _menuItem(
        icon: Icons.shopping_bag_outlined,
        title: 'Buyer Dashboard',
        onTap: _openBuyer,
      ),

      _menuItem(
        icon: Icons.favorite_border,
        title: 'Favorites',
        onTap: _openFavorites,
      ),

      _menuItem(
        icon: Icons.shopping_cart_outlined,
        title: 'Cart',
        onTap: _openBuyer,
      ),

      _menuItem(
        icon: Icons.receipt_long_outlined,
        title: 'My Orders',
        onTap: _openBuyer,
      ),

      _menuItem(
        icon: Icons.help_outline,
        title: 'Help & Support',
        onTap: _openBuyer,
      ),

      _menuItem(
        icon: Icons.assignment_return_outlined,
        title: 'Return & Refund',
        onTap: _openBuyer,
      ),
    ];
  }

  // =========================================================
  // SELLER SECTION
  // =========================================================

  List<Widget> _sellerSectionItems() {
    if (_isSellerApproved) {
      return [
        _sectionNotification(),

        Card(
          elevation: 0,
          margin: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 8,
          ),
          child: ListTile(
            leading: const Icon(
              Icons.dashboard_outlined,
              color: Colors.redAccent,
            ),
            title: const Text(
              'Seller Dashboard',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Manage your BuyNova seller business.',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: _openSellerDashboard,
          ),
        ),

        _menuItem(
          icon: Icons.store_outlined,
          title: 'Shop Profile',
          onTap: () {
            _featureNotAvailable(
              'Shop Profile',
            );
          },
        ),

        _menuItem(
          icon: Icons.location_on_outlined,
          title: 'Shop Location',
          onTap: () {
            _featureNotAvailable(
              'Shop Location',
            );
          },
        ),

        _plusMenuItem(
          icon: Icons.inventory_2_outlined,
          title: 'My Products',
          onTap: _openMyProducts,
        ),

        _plusMenuItem(
          icon: Icons.video_library_outlined,
          title: 'My Videos',
          onTap: _openMyVideos,
        ),

        _menuItem(
          icon: Icons.favorite_border,
          title: 'Favorites',
          onTap: _openFavorites,
        ),

        _menuItem(
          icon: Icons.receipt_long_outlined,
          title: 'Sales / Orders',
          onTap: () {
            _featureNotAvailable(
              'Sales / Orders',
            );
          },
        ),

        // =====================================================
        // SELLER EARNINGS — CONNECTED
        // =====================================================

        _menuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Earnings',
          onTap: _openSellerEarnings,
        ),

        _menuItem(
          icon: Icons.message_outlined,
          title: 'Messages',
          onTap: _openSellerMessages,
        ),
      ];
    }

    if (_sellerStatus == 'pending') {
      return [
        _sectionNotification(),

        Card(
          elevation: 0,
          margin: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 8,
          ),
          child: ListTile(
            leading: const Icon(
              Icons.pending_outlined,
              color: Colors.orange,
            ),
            title: const Text(
              'Seller Request Pending',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Your seller request is waiting for admin approval.',
            ),
          ),
        ),
      ];
    }

    if (_sellerStatus == 'rejected') {
      return [
        _sectionNotification(),

        Card(
          elevation: 0,
          margin: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 8,
          ),
          child: ListTile(
            leading: const Icon(
              Icons.cancel_outlined,
              color: Colors.red,
            ),
            title: const Text(
              'Seller Request Rejected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'You can submit a new seller request.',
            ),
            trailing: TextButton(
              onPressed: _becomeSeller,
              child: const Text(
                'Apply Again',
              ),
            ),
          ),
        ),
      ];
    }

    return [
      _sectionNotification(),

      Card(
        elevation: 0,
        margin: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 8,
        ),
        child: ListTile(
          leading: const Icon(
            Icons.storefront_outlined,
            color: Colors.redAccent,
          ),
          title: const Text(
            'Become a Seller',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Apply to sell your products on BuyNova.',
          ),
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: _becomeSeller,
        ),
      ),
    ];
  }

  // =========================================================
  // ENTREPRENEUR SECTION
  // =========================================================

  List<Widget> _entrepreneurSectionItems() {
    if (_isEntrepreneurApproved) {
      return [
        _sectionNotification(),

        _menuItem(
          icon: Icons.storefront_outlined,
          title: 'My Store',
          onTap: _openEntrepreneur,
        ),

        _menuItem(
          icon: Icons.favorite_border,
          title: 'Favorites',
          onTap: _openFavorites,
        ),

        _menuItem(
          icon: Icons.receipt_long_outlined,
          title: 'Reseller Orders',
          onTap: () {
            _featureNotAvailable(
              'Reseller Orders',
            );
          },
        ),

        _menuItem(
          icon: Icons.monetization_on_outlined,
          title: 'My Profit',
          onTap: () {
            _featureNotAvailable(
              'My Profit',
            );
          },
        ),

        _plusMenuItem(
          icon: Icons.video_library_outlined,
          title: 'My Videos',
          onTap: _openMyVideos,
        ),

        _menuItem(
          icon: Icons.message_outlined,
          title: 'Messages',
          onTap: () {
            _featureNotAvailable(
              'Messages',
            );
          },
        ),
      ];
    }

    if (_entrepreneurStatus == 'pending') {
      return [
        _sectionNotification(),

        Card(
          elevation: 0,
          margin: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 8,
          ),
          child: ListTile(
            leading: const Icon(
              Icons.pending_outlined,
              color: Colors.orange,
            ),
            title: const Text(
              'Entrepreneur Request Pending',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Your entrepreneur request is waiting for admin approval.',
            ),
          ),
        ),
      ];
    }

    return [
      _sectionNotification(),

      Card(
        elevation: 0,
        margin: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 8,
        ),
        child: ListTile(
          leading: const Icon(
            Icons.business_center_outlined,
            color: Colors.redAccent,
          ),
          title: const Text(
            'Become an Entrepreneur / Reseller',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Apply to become a BuyNova reseller.',
          ),
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: _openEntrepreneur,
        ),
      ),
    ];
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
          title: const Text(
            'My Profile',
          ),
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
                    // =================================================
                    // PROFILE CARD
                    // =================================================

                    Card(
                      elevation: 0,
                      child: Padding(
                        padding:
                            const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap:
                                  _openEditProfile,
                              child: Container(
                                width: 84,
                                height: 84,
                                decoration:
                                    BoxDecoration(
                                  shape:
                                      BoxShape.circle,
                                  color:
                                      Colors.grey.shade200,
                                ),
                                child:
                                    _profileImage(),
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              _name.isNotEmpty
                                  ? _name
                                  : 'BuyNova User',
                              style:
                                  const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              user.email ?? '',
                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),

                            if (_phone.isNotEmpty) ...[
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                _phone,
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),
                            ],

                            const SizedBox(
                              height: 14,
                            ),

                            SizedBox(
                              width:
                                  double.infinity,
                              child:
                                  OutlinedButton.icon(
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

                    const SizedBox(
                      height: 16,
                    ),

                    // =================================================
                    // ADMIN
                    // =================================================

                    if (_isAdmin) ...[
                      _expandableSectionHeader(
                        icon:
                            Icons.admin_panel_settings_outlined,
                        title:
                            'ADMIN PANEL',
                        expanded:
                            _adminExpanded,
                        onTap:
                            _openAdminPanel,
                      ),

                      if (_adminExpanded) ...[
                        _sectionNotification(),

                        _menuItem(
                          icon:
                              Icons.admin_panel_settings_outlined,
                          title:
                              'Admin Dashboard',
                          onTap:
                              _openAdminPanel,
                        ),
                      ],

                      const SizedBox(
                        height: 8,
                      ),
                    ],

                    // =================================================
                    // BUYER
                    // =================================================

                    _expandableSectionHeader(
                      icon:
                          Icons.shopping_bag_outlined,
                      title:
                          'BUYER',
                      expanded:
                          _buyerExpanded,
                      onTap:
                          _openBuyer,
                    ),

                    if (_buyerExpanded) ...[
                      ..._buyerSectionItems(),
                    ],

                    const SizedBox(
                      height: 8,
                    ),

                    // =================================================
                    // EARN & REWARDS
                    // =================================================

                    _expandableSectionHeader(
                      icon:
                          Icons.stars_outlined,
                      title:
                          'EARN & REWARDS',
                      expanded:
                          _earnExpanded,
                      onTap:
                          _openWatchEarn,
                    ),

                    if (_earnExpanded) ...[
                      _sectionNotification(),

                      _rewardsSummaryCard(),

                      _menuItem(
                        icon:
                            Icons.play_circle_outline,
                        title:
                            'Watch & Earn',
                        iconColor:
                            Colors.redAccent,
                        onTap:
                            _openWatchEarn,
                      ),

                      _menuItem(
                        icon:
                            Icons.video_library_outlined,
                        title:
                            'Seller Video Rewards',
                        onTap: () {
                          _featureNotAvailable(
                            'Seller Video Rewards',
                          );
                        },
                      ),

                      _menuItem(
                        icon:
                            Icons.group_add_outlined,
                        title:
                            'Referral',
                        onTap: () {
                          _featureNotAvailable(
                            'Referral',
                          );
                        },
                      ),
                    ],

                    const SizedBox(
                      height: 8,
                    ),

                    // =================================================
                    // ENTREPRENEUR / RESELLER
                    // =================================================

                    _expandableSectionHeader(
                      icon:
                          Icons.business_center_outlined,
                      title:
                          'ENTREPRENEUR / RESELLER',
                      expanded:
                          _entrepreneurExpanded,
                      onTap:
                          _openEntrepreneur,
                    ),

                    if (_entrepreneurExpanded) ...[
                      ..._entrepreneurSectionItems(),
                    ],

                    const SizedBox(
                      height: 8,
                    ),

                    // =================================================
                    // SELLER
                    // =================================================

                    _expandableSectionHeader(
                      icon:
                          Icons.storefront_outlined,
                      title:
                          'SELLER',
                      expanded:
                          _sellerExpanded,
                      onTap:
                          _openSellerDashboard,
                    ),

                    if (_sellerExpanded) ...[
                      ..._sellerSectionItems(),
                    ],

                    const SizedBox(
                      height: 16,
                    ),

                    // =================================================
                    // SETTINGS
                    // =================================================

                    _menuItem(
                      icon:
                          Icons.settings_outlined,
                      title:
                          'Settings',
                      indented: false,
                      onTap:
                          _openSettings,
                    ),

                    // =================================================
                    // LOGOUT
                    // =================================================

                    _menuItem(
                      icon:
                          Icons.logout,
                      title:
                          'Logout',
                      iconColor:
                          Colors.red,
                      indented: false,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (dialogContext) {
                            return AlertDialog(
                              title:
                                  const Text(
                                'Logout',
                              ),
                              content:
                                  const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      dialogContext,
                                    );
                                  },
                                  child:
                                      const Text(
                                    'Cancel',
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      dialogContext,
                                    );

                                    _logout();
                                  },
                                  child:
                                      const Text(
                                    'Logout',
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
