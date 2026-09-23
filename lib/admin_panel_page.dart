import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'admin_coupon_page.dart';
import 'admin_wallet_page.dart';

const String kAdminEmail = 'miamdarif010@gmail.com';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _pageTitle = 'Admin Dashboard';
  Widget? _selectedPage;

  // =========================================================
  // ID GENERATORS
  // =========================================================

  String _generateSellerCode(String uid) {
    final shortId = uid.length >= 6 ? uid.substring(0, 6) : uid;
    return 'SELL-${shortId.toUpperCase()}';
  }

  String _generateEntrepreneurCode(String uid) {
    final shortId = uid.length >= 6 ? uid.substring(0, 6) : uid;
    return 'ENT-${shortId.toUpperCase()}';
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _openSection(String title, Widget page) {
    setState(() {
      _pageTitle = title;
      _selectedPage = page;
    });
  }

  void _backToDashboard() {
    setState(() {
      _pageTitle = 'Admin Dashboard';
      _selectedPage = null;
    });
  }

  // =========================================================
  // PRODUCT DELETE
  // =========================================================

  Future<void> _deleteProduct(String productId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product?'),
          content: Text(
            'Are you sure you want to delete "$name"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('products').doc(productId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete product: $e'),
        ),
      );
    }
  }

  // =========================================================
  // SELLER STATUS
  // =========================================================

  Future<void> _updateSellerStatus(
    String uid,
    String status,
  ) async {
    try {
      final data = <String, dynamic>{
        'sellerStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'approved') {
        data['sellerCode'] = _generateSellerCode(uid);
        data['sellerApprovedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('users').doc(uid).update(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Seller approved successfully'
                : 'Seller request rejected',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update seller status: $e'),
        ),
      );
    }
  }

  // =========================================================
  // ENTREPRENEUR STATUS
  // =========================================================

  Future<void> _updateEntrepreneurStatus(
    String uid,
    String status,
  ) async {
    try {
      final data = <String, dynamic>{
        'entrepreneurStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'approved') {
        data['entrepreneurCode'] =
            _generateEntrepreneurCode(uid);

        data['entrepreneurApprovedAt'] =
            FieldValue.serverTimestamp();
      }

      await _firestore.collection('users').doc(uid).update(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Entrepreneur approved successfully'
                : 'Entrepreneur request rejected',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update entrepreneur status: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // DELETE USER
  // =========================================================

  Future<void> _deleteUser(
    String uid,
    String name,
    String email,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text('Delete User'),
            ],
          ),
          content: Text(
            'You are about to permanently delete:\n\n'
            '$name\n'
            '$email\n\n'
            'The secure Admin backend will delete the Firebase '
            'Authentication account and related user data.\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('adminDeleteUser');

      await callable.call({
        'uid': uid,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User account deleted successfully',
          ),
        ),
      );

      _backToDashboard();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
        ),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: _selectedPage != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                ),
                onPressed: _backToDashboard,
              )
            : null,
      ),
      body: _selectedPage ?? _dashboard(),
    );
  }

  // =========================================================
  // DASHBOARD
  // =========================================================

  Widget _dashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _adminHeader(),
          const SizedBox(height: 24),
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _overviewGrid(),
          const SizedBox(height: 28),
          const Text(
            'Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // ---------------------------------------------------
          // ALL USERS
          // ---------------------------------------------------
          _adminMenuBox(
            icon: Icons.people_outline,
            title: 'Users',
            subtitle: 'View and manage all users',
            onTap: () => _openSection(
              'Users',
              _usersTab(),
            ),
          ),

          // ---------------------------------------------------
          // APPROVED SELLERS
          // ---------------------------------------------------
          _adminMenuBox(
            icon: Icons.store_outlined,
            title: 'Sellers',
            subtitle: 'View all approved sellers',
            onTap: () => _openSection(
              'Sellers',
              _sellersTab(),
            ),
          ),

          // ---------------------------------------------------
          // APPROVED RESELLERS / ENTREPRENEURS
          // ---------------------------------------------------
          _adminMenuBox(
            icon: Icons.business_center_outlined,
            title: 'Resellers / Entrepreneurs',
            subtitle: 'View all approved resellers',
            onTap: () => _openSection(
              'Resellers / Entrepreneurs',
              _resellersTab(),
            ),
          ),

          // ---------------------------------------------------
          // PRODUCTS
          // ---------------------------------------------------
          _adminMenuBox(
            icon: Icons.inventory_2_outlined,
            title: 'Products',
            subtitle: 'Manage all products',
            onTap: () => _openSection(
              'Products',
              _productsTab(),
            ),
          ),

          // ---------------------------------------------------
          // SELLER REQUESTS
          // ---------------------------------------------------
          _adminMenuBox(
            icon: Icons.storefront_outlined,
            title: 'Seller Requests',
            subtitle: 'Approve or reject sellers',
            onTap: () => _openSection(
              'Seller Requests',
              _sellerRequestsTab(),
            ),
          ),

          // ---------------------------------------------------
          // ---------------------------------------------------
          // RESELLER REQUESTS
          // ---------------------------------------------------
          _adminMenuBox(
           icon:Icons.person_add_alt_1_outlined,
            title: 'Entrepreneur Requests',
            subtitle: 'Approve or reject resellers',
            onTap: () => _openSection(
              'Entrepreneur Requests',
              _entrepreneurRequestsTab(),
            ),
          ),

          // ---------------------------------------------------
          // RELATIONSHIPS
          // ---------------------------------------------------
          _adminMenuBox(
            icon: Icons.link,
            title: 'Relationships',
            subtitle: 'Seller ↔ Reseller products',
            onTap: () => _openSection(
              'Relationships',
              _relationshipsTab(),
            ),
          ),

          // ---------------------------------------------------
          // ORDERS
          // ---------------------------------------------------
          _adminMenuBox(
            icon: Icons.shopping_bag_outlined,
            title: 'Orders',
            subtitle: 'Manage all orders',
            onTap: () => _openSection(
              'Orders',
              _ordersTab(),
            ),
          ),

          // ---------------------------------------------------
          // COUPONS
          // ---------------------------------------------------
          _adminMenuBox(
            icon: Icons.local_offer_outlined,
            title: 'Coupons',
            subtitle: 'Create and manage coupons',
            onTap: () => _openSection(
              'Coupons',
              const AdminCouponPage(),
            ),
          ),

          // ---------------------------------------------------
          // WALLET
          // ---------------------------------------------------
          _adminMenuBox(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: 'Manage wallet transactions',
            onTap: () => _openSection(
              'Wallet',
              const AdminWalletPage(),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =========================================================
  // ADMIN HEADER
  // =========================================================

  Widget _adminHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            child: Icon(
              Icons.admin_panel_settings,
              size: 30,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BuyNova Admin',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Full platform control center',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // OVERVIEW
  // =========================================================

  Widget _overviewGrid() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        int users = 0;
        int sellers = 0;
        int entrepreneurs = 0;

        if (userSnapshot.hasData) {
          users = userSnapshot.data!.docs.length;

          for (final doc in userSnapshot.data!.docs) {
            final data = doc.data();

            if (data['sellerStatus'] == 'approved') {
              sellers++;
            }

            if (data['entrepreneurStatus'] == 'approved') {
              entrepreneurs++;
            }
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            final products =
                productSnapshot.data?.docs.length ?? 0;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('orders').snapshots(),
              builder: (context, orderSnapshot) {
                final orders =
                    orderSnapshot.data?.docs.length ?? 0;

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _overviewCard(
                      Icons.people,
                      'Users',
                      users.toString(),
                    ),
                    _overviewCard(
                      Icons.store,
                      'Sellers',
                      sellers.toString(),
                    ),
                    _overviewCard(
                      Icons.business_center,
                      'Resellers',
                      entrepreneurs.toString(),
                    ),
                    _overviewCard(
                      Icons.inventory_2,
                      'Products',
                      products.toString(),
                    ),
                    _overviewCard(
                      Icons.shopping_bag,
                      'Orders',
                      orders.toString(),
                    ),
                    _overviewCard(
                      Icons.account_balance_wallet,
                      'Wallet',
                      'Manage',
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _overviewCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 27),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MENU BOX
  // =========================================================

  Widget _adminMenuBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // =========================================================
  // ALL USERS
  // =========================================================

  Widget _usersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text('No users found'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final name =
                (data['name'] ?? 'No Name').toString();

            final email =
                (data['email'] ?? 'No Email').toString();

            final sellerStatus =
                (data['sellerStatus'] ?? 'none').toString();

            final entrepreneurStatus =
                (data['entrepreneurStatus'] ?? 'none')
                    .toString();

            return _userCard(
              uid: doc.id,
              data: data,
              name: name,
              email: email,
              sellerStatus: sellerStatus,
              entrepreneurStatus: entrepreneurStatus,
            );
          },
        );
      },
    );
  }

  // =========================================================
  // APPROVED SELLERS
  // =========================================================

  Widget _sellersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .where(
            'sellerStatus',
            isEqualTo: 'approved',
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text('No approved sellers found.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            return _roleUserCard(
              uid: doc.id,
              data: doc.data(),
              role: 'Seller',
              roleCode:
                  (doc.data()['sellerCode'] ?? 'Not assigned')
                      .toString(),
              roleIcon: Icons.store_outlined,
            );
          },
        );
      },
    );
  }

  // =========================================================
  // APPROVED RESELLERS / ENTREPRENEURS
  // =========================================================

  Widget _resellersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .where(
            'entrepreneurStatus',
            isEqualTo: 'approved',
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No approved resellers / entrepreneurs found.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            return _roleUserCard(
              uid: doc.id,
              data: doc.data(),
              role: 'Reseller / Entrepreneur',
              roleCode:
                  (doc.data()['entrepreneurCode'] ??
                          'Not assigned')
                      .toString(),
              roleIcon: Icons.business_center_outlined,
            );
          },
        );
      },
    );
  }

  // =========================================================
  // ROLE USER CARD
  // =========================================================

  Widget _roleUserCard({
    required String uid,
    required Map<String, dynamic> data,
    required String role,
    required String roleCode,
    required IconData roleIcon,
  }) {
    final name =
        (data['name'] ?? 'No Name').toString();

    final email =
        (data['email'] ?? 'No Email').toString();

    final imageUrl =
        (data['profileImageUrl'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          _openSection(
            'User Details',
            _userDetailsTab(uid, data),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl.isEmpty
                    ? Icon(roleIcon)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _statusChip(
                          role,
                          'approved',
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            roleCode,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // USER CARD
  // =========================================================

  Widget _userCard({
    required String uid,
    required Map<String, dynamic> data,
    required String name,
    required String email,
    required String sellerStatus,
    required String entrepreneurStatus,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          _openSection(
            'User Details',
            _userDetailsTab(uid, data),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundImage:
                    data['profileImageUrl'] != null &&
                            data['profileImageUrl']
                                .toString()
                                .isNotEmpty
                        ? NetworkImage(
                            data['profileImageUrl'].toString(),
                          )
                        : null,
                child:
                    data['profileImageUrl'] == null ||
                            data['profileImageUrl']
                                .toString()
                                .isEmpty
                        ? const Icon(Icons.person)
                        : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _statusChip(
                          'Seller: $sellerStatus',
                          sellerStatus,
                        ),
                        _statusChip(
                          'Reseller: $entrepreneurStatus',
                          entrepreneurStatus,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // USER DETAILS
  // =========================================================

  Widget _userDetailsTab(
    String uid,
    Map<String, dynamic> data,
  ) {
    final name =
        (data['name'] ?? 'No Name').toString();

    final email =
        (data['email'] ?? 'No Email').toString();

    final phone =
        (data['phone'] ?? 'Not added').toString();

    final sellerStatus =
        (data['sellerStatus'] ?? 'none').toString();

    final entrepreneurStatus =
        (data['entrepreneurStatus'] ?? 'none')
            .toString();

    final sellerCode =
        (data['sellerCode'] ?? 'Not assigned').toString();

    final entrepreneurCode =
        (data['entrepreneurCode'] ?? 'Not assigned')
            .toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _userProfileHeader(
            uid,
            data,
            name,
            email,
          ),
          const SizedBox(height: 18),

          _detailsSection(
            title: 'Basic Profile',
            icon: Icons.person_outline,
            children: [
              _summaryRow('UID', uid),
              _summaryRow('Name', name),
              _summaryRow('Email', email),
              _summaryRow('Phone', phone),
            ],
          ),

          const SizedBox(height: 14),

          _detailsSection(
            title: 'Buyer / Customer',
            icon: Icons.shopping_cart_outlined,
            children: [
              _summaryRow(
                'Role',
                'Buyer / Customer',
              ),
              _summaryRow(
                'Account',
                'Active',
              ),
            ],
          ),

          const SizedBox(height: 14),

          _detailsSection(
            title: 'Seller',
            icon: Icons.store_outlined,
            children: [
              _summaryRow(
                'Seller Status',
                sellerStatus,
              ),
              _summaryRow(
                'Seller ID',
                sellerCode,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _detailsSection(
            title: 'Reseller / Entrepreneur',
            icon: Icons.business_center_outlined,
            children: [
              _summaryRow(
                'Status',
                entrepreneurStatus,
              ),
              _summaryRow(
                'Entrepreneur ID',
                entrepreneurCode,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _walletDetails(uid, data),

          const SizedBox(height: 14),

          _userProducts(uid, data),

          const SizedBox(height: 14),

          _userVideos(uid),

          const SizedBox(height: 14),

          _userOrders(uid),

          const SizedBox(height: 22),

          _deleteUserButton(
            uid,
            name,
            email,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =========================================================
  // USER PROFILE HEADER
  // =========================================================

  Widget _userProfileHeader(
    String uid,
    Map<String, dynamic> data,
    String name,
    String email,
  ) {
    final imageUrl =
        (data['profileImageUrl'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 42,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'UID: $uid',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DETAILS SECTION
  // =========================================================

  Widget _detailsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // =========================================================
  // WALLET
  // =========================================================

  Widget _walletDetails(
    String uid,
    Map<String, dynamic> data,
  ) {
    final cashBalance =
        _toDouble(data['cashBalance']);

    final pointsBalance =
        _toInt(data['pointsBalance']);

    final lifetimePoints =
        _toInt(data['lifetimePoints']);

    return _detailsSection(
      title: 'BuyNova Wallet',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _summaryRow(
          'Cash Balance',
          '৳${cashBalance.toStringAsFixed(2)}',
        ),
        _summaryRow(
          'Points',
          pointsBalance.toString(),
        ),
        _summaryRow(
          'Lifetime Points',
          lifetimePoints.toString(),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('users')
              .doc(uid)
              .collection('walletTransactions')
              .orderBy(
                'createdAt',
                descending: true,
              )
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                'Wallet transaction history unavailable.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Text(
                'No wallet transactions.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              );
            }

            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...docs.map(
                  (doc) {
                    final tx = doc.data();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(
                        Icons.receipt_long_outlined,
                      ),
                      title: Text(
                        (tx['source'] ??
                                tx['type'] ??
                                'Transaction')
                            .toString(),
                      ),
                      subtitle: Text(
                        (tx['status'] ?? 'unknown')
                            .toString(),
                      ),
                      trailing: Text(
                        '৳${_toDouble(tx['amount']).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // USER PRODUCTS
  // =========================================================

  Widget _userProducts(
    String uid,
    Map<String, dynamic> userData,
  ) {
    final userEmail =
        (userData['email'] ?? '').toString();

    return _detailsSection(
      title: 'Products',
      icon: Icons.inventory_2_outlined,
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('products')
              .where(
                'sellerId',
                isEqualTo: uid,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                'Seller products unavailable.',
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Text(
                'No seller products found.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final product = doc.data();

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.shopping_bag_outlined,
                  ),
                  title: Text(
                    (product['name'] ??
                            'Unnamed Product')
                        .toString(),
                  ),
                  subtitle: Text(
                    (product['category'] ??
                            'No category')
                        .toString(),
                  ),
                  trailing: Text(
                    '৳${_toDouble(product['price']).toStringAsFixed(0)}',
                  ),
                );
              }).toList(),
            );
          },
        ),

        const Divider(),

        const Text(
          'Reseller Products',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('reseller_products')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                'Reseller products unavailable.',
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const SizedBox(
                height: 40,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final docs = (snapshot.data?.docs ?? [])
                .where((doc) {
              final data = doc.data();

              final entrepreneurId =
                  data['entrepreneurId']?.toString();

              final ownerId =
                  data['userId']?.toString();

              final entrepreneurUid =
                  data['entrepreneurUid']?.toString();

              final entrepreneurEmail =
                  data['entrepreneurEmail']?.toString();

              return entrepreneurId == uid ||
                  ownerId == uid ||
                  entrepreneurUid == uid ||
                  entrepreneurEmail == userEmail;
            }).toList();

            if (docs.isEmpty) {
              return const Text(
                'No reseller products found.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final product = doc.data();

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.storefront_outlined,
                  ),
                  title: Text(
                    (product['productName'] ??
                            product['name'] ??
                            'Reseller Product')
                        .toString(),
                  ),
                  subtitle: Text(
                    'Supplier: ${product['sellerCode'] ?? 'N/A'}',
                  ),
                  trailing: Text(
                    '৳${_toDouble(
                      product['sellingPrice'] ??
                          product['price'],
                    ).toStringAsFixed(0)}',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // USER VIDEOS
  // =========================================================

  Widget _userVideos(String uid) {
    return _detailsSection(
      title: 'Videos',
      icon: Icons.video_library_outlined,
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('sellerVideos')
              .where(
                'sellerId',
                isEqualTo: uid,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                'Seller videos unavailable.',
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(10),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Text(
                'No seller videos found.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final video = doc.data();

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.play_circle_outline,
                  ),
                  title: Text(
                    (video['title'] ??
                            video['name'] ??
                            'Seller Video')
                        .toString(),
                  ),
                  subtitle: Text(
                    (video['status'] ?? 'Published')
                        .toString(),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // USER ORDERS
  // =========================================================

  Widget _userOrders(String uid) {
    return _detailsSection(
      title: 'Orders',
      icon: Icons.shopping_bag_outlined,
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('orders')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(
                'Orders unavailable.',
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(10),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final docs = (snapshot.data?.docs ?? [])
                .where((doc) {
              final data = doc.data();

              return data['customerId']?.toString() ==
                      uid ||
                  data['userId']?.toString() == uid ||
                  data['buyerId']?.toString() == uid ||
                  data['sellerId']?.toString() == uid ||
                  data['entrepreneurId']?.toString() ==
                      uid ||
                  data['resellerId']?.toString() == uid;
            }).toList();

            if (docs.isEmpty) {
              return const Text(
                'No orders found for this user.',
                style: TextStyle(
                  color: Colors.black54,
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final order = doc.data();

                return Container(
                  margin:
                      const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9F7),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID: ${doc.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${order['orderStatus'] ?? 'N/A'}',
                      ),
                      Text(
                        'Payment: ${order['paymentStatus'] ?? 'N/A'}',
                      ),
                      Text(
                        'Total: ৳${_toDouble(order['total']).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // DELETE BUTTON
  // =========================================================

  Widget _deleteUserButton(
    String uid,
    String name,
    String email,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          _deleteUser(
            uid,
            name,
            email,
          );
        },
        icon: const Icon(
          Icons.delete_forever,
        ),
        label: const Text(
          'Delete User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SELLER REQUESTS
  // =========================================================

  Widget _sellerRequestsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .where(
            'sellerStatus',
            isEqualTo: 'pending',
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No pending seller requests.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            return _requestCard(
              uid: doc.id,
              data: data,
              role: 'Seller',
              onApprove: () => _updateSellerStatus(
                doc.id,
                'approved',
              ),
              onReject: () => _updateSellerStatus(
                doc.id,
                'rejected',
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // ENTREPRENEUR REQUESTS
  // =========================================================

  Widget _entrepreneurRequestsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .where(
            'entrepreneurStatus',
            isEqualTo: 'pending',
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No pending entrepreneur requests.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            return _requestCard(
              uid: doc.id,
              data: data,
              role: 'Entrepreneur / Reseller',
              onApprove:
                  () => _confirmEntrepreneurAction(
                doc.id,
                'approved',
              ),
              onReject:
                  () => _confirmEntrepreneurAction(
                doc.id,
                'rejected',
              ),
            );
          },
        );
      },
    );
  }

  Widget _requestCard({
    required String uid,
    required Map<String, dynamic> data,
    required String role,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    final name =
        (data['name'] ?? 'No Name').toString();

    final email =
        (data['email'] ?? 'No Email').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text('Name: $name'),
          Text('Email: $email'),
          Text(
            'UID: $uid',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(
                    Icons.check,
                  ),
                  label: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Reject',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RELATIONSHIPS
  // =========================================================

  Widget _relationshipsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('reseller_products')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No Seller ↔ Reseller relationships found.',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();

            final productName =
                (data['productName'] ??
                        data['name'] ??
                        'Product')
                    .toString();

            final sellerCode =
                (data['sellerCode'] ?? 'N/A')
                    .toString();

            final entrepreneurCode =
                (data['entrepreneurCode'] ??
                        'N/A')
                    .toString();

            final supplierPrice =
                _toDouble(
              data['supplierPrice'],
            );

            final sellingPrice =
                _toDouble(
              data['sellingPrice'],
            );

            final profit =
                _toDouble(
              data['profit'],
            );

            return Container(
              margin:
                  const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _summaryRow(
                    'Seller',
                    sellerCode,
                  ),
                  _summaryRow(
                    'Reseller',
                    entrepreneurCode,
                  ),
                  _summaryRow(
                    'Supplier Price',
                    '৳${supplierPrice.toStringAsFixed(2)}',
                  ),
                  _summaryRow(
                    'Selling Price',
                    '৳${sellingPrice.toStringAsFixed(2)}',
                  ),
                  _summaryRow(
                    'Profit',
                    '৳${profit.toStringAsFixed(2)}',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // PRODUCTS
  // =========================================================

  Widget _productsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('products')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text('No products found.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final name =
                (data['name'] ?? 'Product').toString();

            final category =
                (data['category'] ?? 'No Category')
                    .toString();

            final sellerEmail =
                (data['sellerEmail'] ?? 'N/A')
                    .toString();

            final sellerCode =
                (data['sellerCode'] ?? 'N/A')
                    .toString();

            final imageUrl =
                (data['imageUrl'] ?? '').toString();

            return Container(
              margin:
                  const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  _productImage(imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '৳${_toDouble(data['price']).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          category,
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sellerCode,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          sellerEmail,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete Product',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      _deleteProduct(
                        doc.id,
                        name,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _productImage(String url) {
    if (url.isEmpty) {
      return Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.image_outlined,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 65,
        height: 65,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: 65,
            height: 65,
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            child: const Icon(
              Icons.broken_image_outlined,
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // ORDERS
  // =========================================================

  Widget _ordersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorView(snapshot.error.toString());
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          snapshot.data?.docs ?? [],
        );

        docs.sort((a, b) {
          final aTime =
              _dateFromValue(
            a.data()['createdAt'],
          );

          final bTime =
              _dateFromValue(
            b.data()['createdAt'],
          );

          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text('No orders found.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _orderCard(docs[index]);
          },
        );
      },
    );
  }

  Widget _orderCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final customerName =
        (data['customerName'] ?? 'Customer')
            .toString();

    final phone =
        (data['phone'] ?? 'N/A').toString();

    final address =
        (data['address'] ?? 'N/A').toString();

    final total =
        _toDouble(data['total']);

    final orderStatus =
        (data['orderStatus'] ?? 'Order Placed')
            .toString();

    final paymentStatus =
        (data['paymentStatus'] ?? 'Pending')
            .toString();

    final items =
        data['items'] is List
            ? List<dynamic>.from(
                data['items'],
              )
            : <dynamic>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${doc.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '৳${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _summaryRow(
            'Customer',
            customerName,
          ),
          _summaryRow(
            'Phone',
            phone,
          ),
          _summaryRow(
            'Address',
            address,
          ),
          _summaryRow(
            'Order Status',
            orderStatus,
          ),
          _summaryRow(
            'Payment Status',
            paymentStatus,
          ),
          const SizedBox(height: 10),
          if (items.isNotEmpty) ...[
            const Text(
              'Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            ...items.map(
              (item) => _buildOrderItem(item),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showOrderStatusDialog(
                      doc.id,
                      orderStatus,
                    );
                  },
                  child: const Text(
                    'Order Status',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showPaymentStatusDialog(
                      doc.id,
                      paymentStatus,
                    );
                  },
                  child: const Text(
                    'Payment',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(dynamic item) {
    if (item is! Map) {
      return Text(item.toString());
    }

    final name =
        (item['name'] ??
                item['productName'] ??
                'Product')
            .toString();

    final quantity =
        _toInt(
          item['quantity'],
        );

    final price =
        _toDouble(
          item['price'],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$name × $quantity',
            ),
          ),
          Text(
            '৳${price.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ORDER STATUS
  // =========================================================

  Future<void> _showOrderStatusDialog(
    String orderId,
    String currentStatus,
  ) async {
    const statuses = [
      'Order Placed',
      'Confirmed',
      'Processing',
      'Shipped',
      'Delivered',
      'Cancelled',
      'Returned',
    ];

    final selected =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text(
            'Update Order Status',
          ),
          children: statuses.map((status) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  context,
                  status,
                );
              },
              child: Row(
                children: [
                  if (status == currentStatus)
                    const Icon(
                      Icons.check,
                      size: 18,
                    ),
                  if (status == currentStatus)
                    const SizedBox(width: 8),
                  Text(status),
                ],
              ),
            );
          }).toList(),
        );
      },
    );

    if (selected == null) return;

    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({
      'orderStatus': selected,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // PAYMENT STATUS
  // =========================================================

  Future<void> _showPaymentStatusDialog(
    String orderId,
    String currentStatus,
  ) async {
    const statuses = [
      'Pending',
      'Paid',
      'Failed',
      'Refunded',
    ];

    final selected =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text(
            'Update Payment Status',
          ),
          children: statuses.map((status) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(
                  context,
                  status,
                );
              },
              child: Row(
                children: [
                  if (status == currentStatus)
                    const Icon(
                      Icons.check,
                      size: 18,
                    ),
                  if (status == currentStatus)
                    const SizedBox(width: 8),
                  Text(status),
                ],
              ),
            );
          }).toList(),
        );
      },
    );

    if (selected == null) return;

    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({
      'paymentStatus': selected,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // ENTREPRENEUR CONFIRMATION
  // =========================================================

  Future<void> _confirmEntrepreneurAction(
    String uid,
    String status,
  ) async {
    final approved = status == 'approved';

    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            approved
                ? 'Approve Entrepreneur?'
                : 'Reject Entrepreneur?',
          ),
          content: Text(
            approved
                ? 'This user will receive an Entrepreneur ID.'
                : 'This entrepreneur request will be rejected.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: Text(
                approved
                    ? 'Approve'
                    : 'Reject',
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _updateEntrepreneurStatus(
        uid,
        status,
      );
    }
  }

  // =========================================================
  // COMMON HELPERS
  // =========================================================

  Widget _statusChip(
    String text,
    String status,
  ) {
    final approved = status == 'approved';
    final pending = status == 'pending';
    final rejected = status == 'rejected';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: approved
            ? Colors.green.withValues(
                alpha: 0.10,
              )
            : pending
                ? Colors.orange.withValues(
                    alpha: 0.10,
                  )
                : rejected
                    ? Colors.red.withValues(
                        alpha: 0.10,
                      )
                    : Colors.grey.withValues(
                        alpha: 0.10,
                      ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: approved
              ? Colors.green
              : pending
                  ? Colors.orange
                  : rejected
                      ? Colors.red
                      : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Something went wrong:\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // =========================================================
  // CONVERTERS
  // =========================================================

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
