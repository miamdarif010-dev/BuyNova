import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'cart_page.dart';
import 'admin_panel_page.dart';
import 'my_products_page.dart';
import 'my_videos_page.dart';
import 'entrepreneur_page.dart';
import 'watch_earn_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;

  // Section open / close
  bool _buyerExpanded = false;
  bool _earnExpanded = false;
  bool _entrepreneurExpanded = false;
  bool _sellerExpanded = false;

  String _name = '';
  String _phone = '';
  String _profileImageUrl = '';

  String _sellerStatus = 'none';
  String _entrepreneurStatus = 'none';

  int _pointsBalance = 0;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get _isAdmin => currentUser?.email == kAdminEmail;

  bool get _isSellerApproved => _sellerStatus == 'approved';

  bool get _isEntrepreneurApproved =>
      _entrepreneurStatus == 'approved';

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

      if (doc.exists) {
        final data = doc.data() ?? {};

        if (mounted) {
          setState(() {
            _name = data['name']?.toString() ?? '';
            _phone = data['phone']?.toString() ?? '';

            _profileImageUrl =
                data['profileImageUrl']?.toString() ?? '';

            _sellerStatus =
                data['sellerStatus']?.toString() ?? 'none';

            _entrepreneurStatus =
                data['entrepreneurStatus']?.toString() ?? 'none';

            _pointsBalance =
                (data['pointsBalance'] as num?)?.toInt() ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Profile loading error: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfilePage(),
      ),
    );

    await _loadUserData();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  Future<void> _openMyProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyProductsPage(),
      ),
    );
  }

  Future<void> _openMyVideos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyVideosPage(),
      ),
    );
  }

  Future<void> _openCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartPage(),
      ),
    );
  }

  Future<void> _openAdminPanel() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminPanelPage(),
      ),
    );
  }

  Future<void> _openEntrepreneur() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EntrepreneurPage(),
      ),
    );

    await _loadUserData();
  }

  Future<void> _openWatchEarn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WatchEarnPage(),
      ),
    );

    await _loadUserData();
  }

  // =========================================================
  // NOTIFICATIONS
  // =========================================================

  void _openNotifications(String sectionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$sectionName notifications are not connected yet.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // FEATURES NOT READY YET
  // =========================================================

  void _featureNotAvailable(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title is not available yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // BECOME SELLER
  // =========================================================

  Future<void> _becomeSeller() async {
    final user = currentUser;

    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Become a Seller'),
        content: const Text(
          'Send a request to become a seller? '
          'An admin will review and approve your request.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': _name,
          'email': user.email,
          'sellerStatus': 'pending',
          'sellerRequestedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _sellerStatus = 'pending';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller request sent! Waiting for admin approval.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send seller request: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
        backgroundImage: NetworkImage(
          _profileImageUrl,
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Icon(
          icon,
          size: 25,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(
          expanded
              ? Icons.keyboard_arrow_up
              : Icons.keyboard_arrow_down,
        ),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // NOTIFICATION ROW
  // =========================================================

  Widget _sectionNotification({
    required String sectionName,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 2,
        ),
        leading: const Icon(
          Icons.notifications_none,
          color: Colors.redAccent,
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: () {
          _openNotifications(sectionName);
        },
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
    bool isDanger = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
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
  // MENU ITEM WITH PLUS BUTTON
  // =========================================================

  Widget _plusMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required VoidCallback onAdd,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 2,
        ),
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Add',
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.redAccent,
              ),
              onPressed: onAdd,
            ),
            const Icon(
              Icons.chevron_right,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // REWARDS CARD
  // =========================================================

  Widget _rewardsSummaryCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withValues(
              alpha: 0.12,
            ),
          ),
          child: const Icon(
            Icons.stars_outlined,
            color: Colors.orange,
          ),
        ),
        title: const Text(
          'My Rewards',
          style: TextStyle(
            fontSize: 16,
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
  // SELLER SECTION ITEMS
  // =========================================================

  List<Widget> _sellerSectionItems() {
    if (_isSellerApproved) {
      return [
        _menuItem(
          icon: Icons.storefront_outlined,
          title: 'Shop Profile',
          onTap: () {
            _featureNotAvailable('Shop Profile');
          },
        ),

        _menuItem(
          icon: Icons.location_on_outlined,
          title: 'Shop Location',
          onTap: () {
            _featureNotAvailable('Shop Location');
          },
        ),

        _plusMenuItem(
          icon: Icons.inventory_2_outlined,
          title: 'My Products',
          onTap: _openMyProducts,
          onAdd: _openMyProducts,
        ),

        _plusMenuItem(
          icon: Icons.video_library_outlined,
          title: 'My Videos',
          onTap: _openMyVideos,
          onAdd: _openMyVideos,
        ),

        _menuItem(
          icon: Icons.bar_chart_outlined,
          title: 'Sales / Orders',
          onTap: () {
            _featureNotAvailable('Sales / Orders');
          },
        ),

        _menuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Earnings',
          onTap: () {
            _featureNotAvailable('Earnings');
          },
        ),

        _menuItem(
          icon: Icons.message_outlined,
          title: 'Messages',
          onTap: () {
            _featureNotAvailable('Seller Messages');
          },
        ),
      ];
    }

    if (_sellerStatus == 'pending') {
      return [
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(
            bottom: 8,
          ),
          color: Colors.orange.shade50,
          child: const ListTile(
            leading: Icon(
              Icons.hourglass_top,
              color: Colors.orange,
            ),
            title: Text(
              'Seller request pending',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'An admin is reviewing your request.',
            ),
          ),
        ),
      ];
    }

    if (_sellerStatus == 'rejected') {
      return [
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(
            bottom: 8,
          ),
          color: Colors.red.shade50,
          child: ListTile(
            leading: const Icon(
              Icons.cancel_outlined,
              color: Colors.red,
            ),
            title: const Text(
              'Seller request rejected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Tap to request again.',
            ),
            onTap: _becomeSeller,
          ),
        ),
      ];
    }

    return [
      _menuItem(
        icon: Icons.storefront_outlined,
        title: 'Become a Seller',
        onTap: _becomeSeller,
      ),
    ];
  }

  // =========================================================
  // ENTREPRENEUR / RESELLER SECTION ITEMS
  // =========================================================

  List<Widget> _entrepreneurSectionItems() {
    if (_isEntrepreneurApproved) {
      return [
        _menuItem(
          icon: Icons.storefront_outlined,
          title: 'My Store',
          onTap: _openEntrepreneur,
        ),

        _menuItem(
          icon: Icons.shopping_bag_outlined,
          title: 'Reseller Orders',
          onTap: () {
            _featureNotAvailable('Reseller Orders');
          },
        ),

        _menuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'My Profit',
          onTap: () {
            _featureNotAvailable('My Profit');
          },
        ),

        _plusMenuItem(
          icon: Icons.video_library_outlined,
          title: 'My Videos',
          onTap: _openMyVideos,
          onAdd: _openMyVideos,
        ),

        _menuItem(
          icon: Icons.message_outlined,
          title: 'Messages',
          onTap: () {
            _featureNotAvailable('Reseller Messages');
          },
        ),
      ];
    }

    if (_entrepreneurStatus == 'pending') {
      return [
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(
            bottom: 8,
          ),
          color: Colors.orange.shade50,
          child: ListTile(
            leading: const Icon(
              Icons.hourglass_top,
              color: Colors.orange,
            ),
            title: const Text(
              'Entrepreneur request pending',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Your request is waiting for admin approval.',
            ),
            onTap: _openEntrepreneur,
          ),
        ),
      ];
    }

    return [
      _menuItem(
        icon: Icons.business_center_outlined,
        title: 'Become an Entrepreneur / Reseller',
        onTap: _openEntrepreneur,
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
                    // PROFILE
                    // =================================================

                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          _profileImage(),

                          const SizedBox(height: 14),

                          Text(
                            _name.isEmpty
                                ? 'User'
                                : _name,
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
                                  color:
                                      Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _phone,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color:
                                        Colors.grey.shade600,
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
                              onPressed:
                                  _openEditProfile,
                              icon: const Icon(
                                Icons.edit,
                              ),
                              label: const Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =================================================
                    // ADMIN
                    // =================================================

                    if (_isAdmin) ...[
                      _menuItem(
                        icon: Icons
                            .admin_panel_settings_outlined,
                        title: 'Admin Panel',
                        onTap: _openAdminPanel,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // =================================================
                    // BUYER
                    // =================================================

                    _expandableSectionHeader(
                      icon: Icons.shopping_bag_outlined,
                      title: 'BUYER',
                      expanded: _buyerExpanded,
                      onTap: () {
                        setState(() {
                          _buyerExpanded = !_buyerExpanded;
                        });
                      },
                    ),

                    if (_buyerExpanded) ...[
                      _sectionNotification(
                        sectionName: 'Buyer',
                      ),

                      _menuItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'My Orders',
                        onTap: () {
                          _featureNotAvailable(
                            'My Orders',
                          );
                        },
                      ),

                      _menuItem(
                        icon: Icons.favorite_border,
                        title: 'Favorites',
                        onTap: () {
                          _featureNotAvailable(
                            'Favorites',
                          );
                        },
                      ),

                      _menuItem(
                        icon: Icons.shopping_cart_outlined,
                        title: 'My Cart',
                        onTap: _openCart,
                      ),

                      _menuItem(
                        icon: Icons.history,
                        title: 'Recently Viewed',
                        onTap: () {
                          _featureNotAvailable(
                            'Recently Viewed',
                          );
                        },
                      ),

                      _menuItem(
                        icon: Icons.local_offer_outlined,
                        title: 'Coupons',
                        onTap: () {
                          _featureNotAvailable(
                            'Coupons',
                          );
                        },
                      ),

                      _plusMenuItem(
                        icon: Icons.video_library_outlined,
                        title: 'My Videos',
                        onTap: _openMyVideos,
                        onAdd: _openMyVideos,
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
                    ],

                    const SizedBox(height: 8),

                    // =================================================
                    // EARN & REWARDS
                    // =================================================

                    _expandableSectionHeader(
                      icon: Icons.monetization_on_outlined,
                      title: 'EARN & REWARDS',
                      expanded: _earnExpanded,
                      onTap: () {
                        setState(() {
                          _earnExpanded = !_earnExpanded;
                        });
                      },
                    ),

                    if (_earnExpanded) ...[
                      _sectionNotification(
                        sectionName: 'Earn & Rewards',
                      ),

                      _menuItem(
                        icon: Icons.play_circle_outline,
                        title: 'Watch & Earn',
                        onTap: _openWatchEarn,
                      ),

                      _rewardsSummaryCard(),

                      _menuItem(
                        icon: Icons.card_giftcard_outlined,
                        title: 'Referral & Invite',
                        onTap: () {
                          _featureNotAvailable(
                            'Referral & Invite',
                          );
                        },
                      ),

                      _menuItem(
                        icon: Icons
                            .account_balance_wallet_outlined,
                        title: 'Withdraw Rewards',
                        onTap: () {
                          _featureNotAvailable(
                            'Withdraw Rewards',
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 8),

                    // =================================================
                    // ENTREPRENEUR / RESELLER
                    // =================================================

                    _expandableSectionHeader(
                      icon: Icons.business_center_outlined,
                      title:
                          'ENTREPRENEUR / RESELLER',
                      expanded: _entrepreneurExpanded,
                      onTap: () {
                        setState(() {
                          _entrepreneurExpanded =
                              !_entrepreneurExpanded;
                        });
                      },
                    ),

                    if (_entrepreneurExpanded) ...[
                      _sectionNotification(
                        sectionName:
                            'Entrepreneur / Reseller',
                      ),

                      ..._entrepreneurSectionItems(),
                    ],

                    const SizedBox(height: 8),

                    // =================================================
                    // SELLER
                    // =================================================

                    _expandableSectionHeader(
                      icon: Icons.store_outlined,
                      title: 'SELLER',
                      expanded: _sellerExpanded,
                      onTap: () {
                        setState(() {
                          _sellerExpanded =
                              !_sellerExpanded;
                        });
                      },
                    ),

                    if (_sellerExpanded) ...[
                      _sectionNotification(
                        sectionName: 'Seller',
                      ),

                      ..._sellerSectionItems(),
                    ],

                    const SizedBox(height: 20),

                    // =================================================
                    // SETTINGS
                    // =================================================

                    _menuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: _openSettings,
                    ),

                    const SizedBox(height: 8),

                    // =================================================
                    // LOGOUT
                    // =================================================

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
            ),
    );
  }
}
