import 'dart:async';

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
import 'address_book_page.dart';
import 'reseller_orders_seller_page.dart';
import 'profile_extra_pages.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  bool _isSubmitting = false;

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
  String _role = '';

  int _pointsBalance = 0;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get _isAdmin {
    return _role == 'admin' ||
        currentUser?.email?.toLowerCase() == 'miamdarif010@gmail.com';
  }

  bool get _isSellerApproved => _sellerStatus == 'approved';

  bool get _isEntrepreneurApproved => _entrepreneurStatus == 'approved';

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
      _isLoading = false;
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
      onError: (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load profile: $e'),
          ),
        );
      },
    );
  }

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

      _applyUserData(doc.data());
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load profile: $e'),
          ),
        );
      }
    }
  }

  void _applyUserData(Map<String, dynamic>? data) {
    if (!mounted) return;

    final rawPoints = data?['pointsBalance'];

    int points = 0;

    if (rawPoints is num) {
      points = rawPoints.toInt();
    } else if (rawPoints != null) {
      points = int.tryParse(rawPoints.toString()) ?? 0;
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
  // SECTION OPEN / CLOSE
  // =========================================================

  void _openOnly(String section) {
    setState(() {
      _adminExpanded = false;
      _buyerExpanded = false;
      _entrepreneurExpanded = false;
      _sellerExpanded = false;
      _earnExpanded = false;

      switch (section) {
        case 'admin':
          _adminExpanded = true;
          break;

        case 'buyer':
          _buyerExpanded = true;
          break;

        case 'reseller':
          _entrepreneurExpanded = true;
          break;

        case 'seller':
          _sellerExpanded = true;
          break;

        case 'earn':
          _earnExpanded = true;
          break;
      }
    });
  }

  void _toggleSection(String section) {
    final bool currentlyOpen;

    switch (section) {
      case 'admin':
        currentlyOpen = _adminExpanded;
        break;

      case 'buyer':
        currentlyOpen = _buyerExpanded;
        break;

      case 'reseller':
        currentlyOpen = _entrepreneurExpanded;
        break;

      case 'seller':
        currentlyOpen = _sellerExpanded;
        break;

      case 'earn':
        currentlyOpen = _earnExpanded;
        break;

      default:
        currentlyOpen = false;
    }

    if (currentlyOpen) {
      setState(() {
        _adminExpanded = false;
        _buyerExpanded = false;
        _entrepreneurExpanded = false;
        _sellerExpanded = false;
        _earnExpanded = false;
      });
    } else {
      _openOnly(section);
    }
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _push(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

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

  void _openSettings() => _push(const SettingsPage());

  void _openMyProducts() => _push(const MyProductsPage());

  void _openMyVideos() => _push(const MyVideosPage());

  void _openAdminPanel() => _push(const AdminPanelPage());

  void _openBuyer() => _push(const BuyerPage());

  void _openEntrepreneur() => _push(const EntrepreneurPage());

  void _openSellerDashboard() => _push(const SellerPage());

  void _openWatchEarn() => _push(const WatchEarnPage());

  void _openFavorites() => _push(const FavoritesPage());

  void _openNotifications() => _push(const NotificationsPage());

  void _openAddressBook() => _push(const AddressBookPage());

  void _openSellerMessages() => _push(const SellerMessagesPage());

  void _openSellerEarnings() => _push(const EarningsPage());

  void _openSellerResellerOrders() {
    _push(const ResellerOrdersSellerPage());
  }

  void _openShopProfile() {
    _push(const ShopProfilePage());
  }

  void _openShopLocation() {
    _push(const ShopLocationPage());
  }

  void _openSalesOrders() {
    _push(const SalesOrdersPage());
  }

  void _openResellerOrders() {
    _push(const ResellerOrdersPage());
  }

  void _openResellerProfit() {
    _push(const ResellerProfitPage());
  }

  void _openResellerMessages() {
    _push(const ResellerMessagesPage());
  }

  void _openSellerVideoRewards() {
    _push(const SellerVideoRewardsPage());
  }

  void _openReferral() {
    _push(const ReferralPage());
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
          'name': _name.isNotEmpty ? _name : 'BuyNova User',
          'email': user.email ?? '',
          'sellerStatus': 'pending',
          'sellerRequestedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Seller request submitted successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Could not submit seller request: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // =========================================================
  // ENTREPRENEUR / RESELLER APPLICATION
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
          'name': _name.isNotEmpty ? _name : 'BuyNova User',
          'email': user.email ?? '',
          'entrepreneurStatus': 'pending',
          'entrepreneurRequestedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Reseller request submitted successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Could not submit reseller request: $e'),
          ),
        );
      }
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
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
          loadingBuilder: (
            context,
            child,
            progress,
          ) {
            if (progress == null) return child;

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
  // SHARED CARD
  // =========================================================

  Widget _infoCard({
    required IconData icon,
    required String title,
    Color? iconColor,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    FontWeight fontWeight = FontWeight.w500,
    double fontSize = 15,
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
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
        subtitle:
            subtitle == null ? null : Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  static const Widget _chevron =
      Icon(Icons.chevron_right);

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
      margin: const EdgeInsets.only(bottom: 8),
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
  // NOTIFICATION
  // =========================================================

  Widget _sectionNotification() {
    return _infoCard(
      icon: Icons.notifications_outlined,
      iconColor: Colors.redAccent,
      title: 'Notifications',
      fontWeight: FontWeight.w600,
      trailing: _chevron,
      onTap: _openNotifications,
    );
  }

  // =========================================================
  // NORMAL MENU
  // =========================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool indented = true,
  }) {
    return _infoCard(
      icon: icon,
      iconColor: iconColor,
      title: title,
      trailing: _chevron,
      onTap: onTap,
      indented: indented,
    );
  }

  // =========================================================
  // PLUS MENU
  // =========================================================

  Widget _plusMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return _infoCard(
      icon: icon,
      iconColor: Colors.redAccent,
      title: title,
      trailing: const Icon(
        Icons.add_circle_outline,
        color: Colors.redAccent,
      ),
      onTap: onTap,
    );
  }

  // =========================================================
  // REWARDS SUMMARY
  // =========================================================

  Widget _rewardsSummaryCard() {
    return _infoCard(
      icon: Icons.stars_outlined,
      iconColor: Colors.orange,
      title: 'My Points',
      subtitle:
          '$_pointsBalance points available',
      fontWeight: FontWeight.w600,
      trailing: _chevron,
      onTap: _openWatchEarn,
    );
  }

  // =========================================================
  // BUYER / CUSTOMER
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
        icon: Icons.location_on_outlined,
        title: 'Address Book',
        onTap: _openAddressBook,
      ),

      _menuItem(
        icon: Icons.video_library_outlined,
        title: 'My Videos',
        onTap: _openMyVideos,
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
  // SELLER
  // =========================================================

  List<Widget> _sellerSectionItems() {
    if (_isSellerApproved) {
      return [
        _sectionNotification(),

        _infoCard(
          icon: Icons.dashboard_outlined,
          iconColor: Colors.redAccent,
          title: 'Seller Dashboard',
          subtitle:
              'Manage your BuyNova seller business.',
          fontWeight: FontWeight.bold,
          trailing: _chevron,
          onTap: _openSellerDashboard,
        ),

        _menuItem(
          icon: Icons.store_outlined,
          title: 'Shop Profile',
          onTap: _openShopProfile,
        ),

        _menuItem(
          icon: Icons.location_on_outlined,
          title: 'Shop Location',
          onTap: _openShopLocation,
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
          icon: Icons.local_shipping_outlined,
          title: 'Reseller Orders',
          onTap: _openSellerResellerOrders,
        ),

        _menuItem(
          icon: Icons.receipt_long_outlined,
          title: 'Sales / Orders',
          onTap: _openSalesOrders,
        ),

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

        _infoCard(
          icon: Icons.pending_outlined,
          iconColor: Colors.orange,
          title: 'Seller Request Pending',
          subtitle:
              'Your seller request is waiting for admin approval.',
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ];
    }

    if (_sellerStatus == 'rejected') {
      return [
        _sectionNotification(),

        _infoCard(
          icon: Icons.cancel_outlined,
          iconColor: Colors.red,
          title: 'Seller Request Rejected',
          subtitle:
              'You can submit a new seller request.',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          trailing: TextButton(
            onPressed:
                _isSubmitting ? null : _becomeSeller,
            child: const Text('Apply Again'),
          ),
        ),
      ];
    }

    return [
      _sectionNotification(),

      _infoCard(
        icon: Icons.storefront_outlined,
        iconColor: Colors.redAccent,
        title: 'Become a Seller',
        subtitle:
            'Apply to sell your products on BuyNova.',
        fontWeight: FontWeight.bold,
        fontSize: 16,
        trailing: _chevron,
        onTap:
            _isSubmitting ? null : _becomeSeller,
      ),
    ];
  }

  // =========================================================
  // RESELLER
  // =========================================================

  List<Widget> _entrepreneurSectionItems() {
    if (_isEntrepreneurApproved) {
      return [
        _sectionNotification(),

        _infoCard(
          icon: Icons.dashboard_outlined,
          iconColor: Colors.redAccent,
          title: 'Reseller Dashboard',
          subtitle:
              'Manage your BuyNova reseller business.',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          trailing: _chevron,
          onTap: _openEntrepreneur,
        ),

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
          onTap: _openResellerOrders,
        ),

        _menuItem(
          icon: Icons.monetization_on_outlined,
          title: 'My Profit',
          onTap: _openResellerProfit,
        ),

        _plusMenuItem(
          icon: Icons.video_library_outlined,
          title: 'My Videos',
          onTap: _openMyVideos,
        ),

        _menuItem(
          icon: Icons.message_outlined,
          title: 'Messages',
          onTap: _openResellerMessages,
        ),
      ];
    }

    if (_entrepreneurStatus == 'pending') {
      return [
        _sectionNotification(),

        _infoCard(
          icon: Icons.pending_outlined,
          iconColor: Colors.orange,
          title: 'Reseller Request Pending',
          subtitle:
              'Your reseller request is waiting for admin approval.',
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ];
    }

    if (_entrepreneurStatus == 'rejected') {
      return [
        _sectionNotification(),

        _infoCard(
          icon: Icons.cancel_outlined,
          iconColor: Colors.red,
          title: 'Reseller Request Rejected',
          subtitle:
              'You can submit a new reseller request.',
          fontWeight: FontWeight.bold,
          fontSize: 16,
          trailing: TextButton(
            onPressed:
                _isSubmitting ? null : _becomeEntrepreneur,
            child: const Text('Apply Again'),
          ),
        ),
      ];
    }

    return [
      _sectionNotification(),

      _infoCard(
        icon: Icons.business_center_outlined,
        iconColor: Colors.redAccent,
        title: 'Become a Reseller',
        subtitle:
            'Apply to become a BuyNova reseller.',
        fontWeight: FontWeight.bold,
        fontSize: 16,
        trailing: _chevron,
        onTap:
            _isSubmitting ? null : _becomeEntrepreneur,
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
                    if (_isSubmitting) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                    ],

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

                    const SizedBox(height: 16),

                    // =================================================
                    // ADMIN
                    // =================================================

                    if (_isAdmin) ...[
                      _expandableSectionHeader(
                        icon: Icons
                            .admin_panel_settings_outlined,
                        title: 'ADMIN PANEL',
                        expanded: _adminExpanded,
                        onTap: () {
                          _toggleSection('admin');
                        },
                      ),

                      if (_adminExpanded) ...[
                        _sectionNotification(),

                        _menuItem(
                          icon: Icons
                              .admin_panel_settings_outlined,
                          title: 'Admin Dashboard',
                          onTap: _openAdminPanel,
                        ),
                      ],

                      const SizedBox(height: 8),
                    ],

                    // =================================================
                    // BUYER / CUSTOMER
                    // =================================================

                    _expandableSectionHeader(
                      icon:
                          Icons.shopping_bag_outlined,
                      title: 'BUYER / CUSTOMER',
                      expanded: _buyerExpanded,
                      onTap: () {
                        _toggleSection('buyer');
                      },
                    ),

                    if (_buyerExpanded)
                      ..._buyerSectionItems(),

                    const SizedBox(height: 8),

                    // =================================================
                    // RESELLER
                    // =================================================

                    _expandableSectionHeader(
                      icon:
                          Icons.business_center_outlined,
                      title: 'RESELLER',
                      expanded:
                          _entrepreneurExpanded,
                      onTap: () {
                        _toggleSection('reseller');
                      },
                    ),

                    if (_entrepreneurExpanded)
                      ..._entrepreneurSectionItems(),

                    const SizedBox(height: 8),

                    // =================================================
                    // SELLER
                    // =================================================

                    _expandableSectionHeader(
                      icon:
                          Icons.storefront_outlined,
                      title: 'SELLER',
                      expanded: _sellerExpanded,
                      onTap: () {
                        _toggleSection('seller');
                      },
                    ),

                    if (_sellerExpanded)
                      ..._sellerSectionItems(),

                    const SizedBox(height: 8),

                    // =================================================
                    // EARN & REWARDS
                    // =================================================

                    _expandableSectionHeader(
                      icon: Icons.stars_outlined,
                      title: 'EARN & REWARDS',
                      expanded: _earnExpanded,
                      onTap: () {
                        _toggleSection('earn');
                      },
                    ),

                    if (_earnExpanded) ...[
                      _sectionNotification(),

                      _rewardsSummaryCard(),

                      _menuItem(
                        icon:
                            Icons.play_circle_outline,
                        title: 'Watch & Earn',
                        iconColor:
                            Colors.redAccent,
                        onTap: _openWatchEarn,
                      ),

                      _menuItem(
                        icon:
                            Icons.video_library_outlined,
                        title:
                            'Seller Video Rewards',
                        onTap:
                            _openSellerVideoRewards,
                      ),

                      _menuItem(
                        icon:
                            Icons.group_add_outlined,
                        title: 'Referral',
                        onTap: _openReferral,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // =================================================
                    // SETTINGS
                    // =================================================

                    _menuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      indented: false,
                      onTap: _openSettings,
                    ),

                    // =================================================
                    // LOGOUT
                    // =================================================

                    _menuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      iconColor: Colors.red,
                      indented: false,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title:
                                  const Text('Logout'),
                              content: const Text(
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
                                      const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      dialogContext,
                                    );
                                    _logout();
                                  },
                                  child:
                                      const Text('Logout'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

এটা "lib/user_profile_page.dart"-এ পুরো replace করো। "profile_extra_pages.dart"-এ এখন কিছু পরিবর্তন লাগবে না।

এবার আচরণটা হবে: একটা section খুলবে → অন্য section বন্ধ থাকবে → একই section আবার চাপলে বন্ধ হবে। ভিতরের সব existing option এবং navigation আগের মতোই থাকবে।
