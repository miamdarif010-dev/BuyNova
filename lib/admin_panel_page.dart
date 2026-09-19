import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_coupon_page.dart';

/// Only reachable if the logged-in user's email matches kAdminEmail.
const String kAdminEmail = 'miamdarif010@gmail.com';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 7,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===========================================================
  // AUTOMATIC SELLER ID
  // ===========================================================

  String _generateSellerCode(String uid) {
    final shortId = uid.length >= 6 ? uid.substring(0, 6) : uid;

    return 'SELL-${shortId.toUpperCase()}';
  }

  // ===========================================================
  // AUTOMATIC ENTREPRENEUR ID
  // ===========================================================

  String _generateEntrepreneurCode(String uid) {
    final shortId = uid.length >= 6 ? uid.substring(0, 6) : uid;

    return 'ENT-${shortId.toUpperCase()}';
  }

  // ===========================================================
  // DELETE PRODUCT
  // ===========================================================

  Future<void> _deleteProduct(
    String productId,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Delete "$name"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product deleted successfully',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete product: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===========================================================
  // UPDATE SELLER STATUS + SELLER ID
  // ===========================================================

  Future<void> _updateSellerStatus(
    String uid,
    String status,
  ) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      final userDoc = await userRef.get();
      final existingData = userDoc.data() ?? {};

      final updateData = <String, dynamic>{
        'sellerStatus': status,
      };

      if (status == 'approved') {
        final existingSellerCode =
            existingData['sellerCode']?.toString() ?? '';

        if (existingSellerCode.isEmpty) {
          updateData['sellerCode'] = _generateSellerCode(uid);

          updateData['sellerApprovedAt'] =
              FieldValue.serverTimestamp();
        }
      }

      await userRef.set(
        updateData,
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Seller approved and Seller ID created'
                : 'Seller request rejected',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update seller status: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===========================================================
  // UPDATE ENTREPRENEUR STATUS + ID
  // ===========================================================

  Future<void> _updateEntrepreneurStatus(
    String uid,
    String status,
  ) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      final userDoc = await userRef.get();
      final existingData = userDoc.data() ?? {};

      final updateData = <String, dynamic>{
        'entrepreneurStatus': status,
      };

      if (status == 'approved') {
        final existingCode =
            existingData['entrepreneurCode']?.toString() ?? '';

        if (existingCode.isEmpty) {
          updateData['entrepreneurCode'] =
              _generateEntrepreneurCode(uid);

          updateData['entrepreneurApprovedAt'] =
              FieldValue.serverTimestamp();
        }
      }

      await userRef.set(
        updateData,
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Entrepreneur approved and ID created'
                : 'Entrepreneur request rejected',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update entrepreneur status: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===========================================================
  // MAIN ADMIN PANEL
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(
                Icons.inventory_2_outlined,
              ),
              text: 'Products',
            ),
            Tab(
              icon: Icon(
                Icons.people_outline,
              ),
              text: 'Users',
            ),
            Tab(
              icon: Icon(
                Icons.storefront_outlined,
              ),
              text: 'Seller Requests',
            ),
            Tab(
              icon: Icon(
                Icons.business_center_outlined,
              ),
              text: 'Entrepreneur Requests',
            ),
            Tab(
              icon: Icon(
                Icons.link_outlined,
              ),
              text: 'Relationships',
            ),
            Tab(
              icon: Icon(
                Icons.shopping_bag_outlined,
              ),
              text: 'Orders',
            ),
            Tab(
              icon: Icon(
                Icons.local_offer_outlined,
              ),
              text: 'Coupons',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _productsTab(),
          _usersTab(),
          _sellerRequestsTab(),
          _entrepreneurRequestsTab(),
          _relationshipsTab(),
          _ordersTab(),
          const AdminCouponPage(),
        ],
      ),
    );
  }

  // ===========================================================
  // PRODUCTS TAB
  // ===========================================================

  Widget _productsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading products:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text('No products yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            final data =
                doc.data() as Map<String, dynamic>;

            final name =
                data['name']?.toString() ?? 'Unnamed';

            final price =
                data['price'] is num
                    ? (data['price'] as num).toDouble()
                    : 0.0;

            final imageUrl =
                data['imageUrl']?.toString();

            final sellerEmail =
                data['sellerEmail']?.toString() ??
                    'Unknown seller';

            final sellerCode =
                data['sellerCode']?.toString() ?? '';

            final category =
                data['category']?.toString() ?? 'General';

            return Card(
              margin: const EdgeInsets.symmetric(
                vertical: 4,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.grey.shade200,
                  backgroundImage:
                      imageUrl != null &&
                              imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                  child:
                      imageUrl == null ||
                              imageUrl.isEmpty
                          ? const Icon(
                              Icons.image,
                              color: Colors.grey,
                            )
                          : null,
                ),
                title: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '₩${price.toStringAsFixed(0)} • $category\n'
                  '${sellerCode.isNotEmpty ? '$sellerCode • ' : ''}'
                  '$sellerEmail',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => _deleteProduct(
                    doc.id,
                    name,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================
  // USERS TAB
  // ===========================================================

  Widget _usersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading users:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text('No users yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            final data =
                doc.data() as Map<String, dynamic>;

            final name =
                data['name']?.toString() ??
                    'Unnamed User';

            final email =
                data['email']?.toString() ?? '';

            final sellerStatus =
                data['sellerStatus']?.toString() ??
                    'none';

            final entrepreneurStatus =
                data['entrepreneurStatus']?.toString() ??
                    'none';

            final sellerCode =
                data['sellerCode']?.toString() ?? '';

            final entrepreneurCode =
                data['entrepreneurCode']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(
                vertical: 5,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          child: Icon(
                            Icons.person,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style:
                                    const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (sellerCode.isNotEmpty)
                      _idBox(
                        icon:
                            Icons.storefront,
                        title: 'Seller ID',
                        value: sellerCode,
                      ),
                    if (entrepreneurCode.isNotEmpty)
                      _idBox(
                        icon:
                            Icons.business_center,
                        title:
                            'Entrepreneur ID',
                        value:
                            entrepreneurCode,
                      ),
                    const SizedBox(
                      height: 8,
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _statusChip(
                          label:
                              'Seller: $sellerStatus',
                          status:
                              sellerStatus,
                        ),
                        _statusChip(
                          label:
                              'Entrepreneur: $entrepreneurStatus',
                          status:
                              entrepreneurStatus,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================
  // ID BOX
  // ===========================================================

  Widget _idBox({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 6,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // STATUS CHIP
  // ===========================================================

  Widget _statusChip({
    required String label,
    required String status,
  }) {
    Color color;

    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  // ===========================================================
  // SELLER REQUESTS
  // ===========================================================

  Widget _sellerRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where(
            'sellerStatus',
            isEqualTo: 'pending',
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading seller requests:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No pending seller requests',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            final data =
                doc.data() as Map<String, dynamic>;

            final name =
                data['name']?.toString() ??
                    'Unnamed User';

            final email =
                data['email']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(
                vertical: 4,
              ),
              child: ListTile(
                leading:
                    const CircleAvatar(
                  child: Icon(
                    Icons.storefront_outlined,
                  ),
                ),
                title: Text(name),
                subtitle: Text(
                  email,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      tooltip: 'Approve',
                      onPressed: () =>
                          _updateSellerStatus(
                        doc.id,
                        'approved',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        color: Colors.red,
                      ),
                      tooltip: 'Reject',
                      onPressed: () =>
                          _updateSellerStatus(
                        doc.id,
                        'rejected',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================
  // ENTREPRENEUR REQUESTS
  // ===========================================================

  Widget _entrepreneurRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where(
            'entrepreneurStatus',
            isEqualTo: 'pending',
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading entrepreneur requests:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business_center_outlined,
                  size: 55,
                  color: Colors.grey,
                ),
                SizedBox(
                  height: 12,
                ),
                Text(
                  'No pending entrepreneur requests',
                  style:
                      TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            final data =
                doc.data() as Map<String, dynamic>;

            final name =
                data['name']?.toString() ??
                    'Unnamed User';

            final email =
                data['email']?.toString() ?? '';

            final phone =
                data['phone']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(
                vertical: 5,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  leading:
                      const CircleAvatar(
                    radius: 27,
                    child: Icon(
                      Icons.business_center_outlined,
                    ),
                  ),
                  title: Text(
                    name,
                    style:
                        const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 5,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          email,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                        if (phone.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(
                              top: 3,
                            ),
                            child:
                                Text(phone),
                          ),
                        const SizedBox(
                          height: 5,
                        ),
                        const Text(
                          'Status: Pending',
                          style:
                              TextStyle(
                            color:
                                Colors.orange,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        tooltip:
                            'Approve Entrepreneur',
                        onPressed: () =>
                            _confirmEntrepreneurAction(
                          doc.id,
                          name,
                          'approved',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                        tooltip:
                            'Reject Entrepreneur',
                        onPressed: () =>
                            _confirmEntrepreneurAction(
                          doc.id,
                          name,
                          'rejected',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================
  // RELATIONSHIPS
  // ===========================================================

  Widget _relationshipsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reseller_products')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading relationships:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.link_off,
                  size: 55,
                  color: Colors.grey,
                ),
                SizedBox(
                  height: 12,
                ),
                Text(
                  'No Seller ↔ Entrepreneur relationships yet',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            final data =
                doc.data() as Map<String, dynamic>;

            final sellerCode =
                data['sellerCode']?.toString() ??
                    'Unknown';

            final sellerEmail =
                data['sellerEmail']?.toString() ??
                    'Unknown';

            final entrepreneurCode =
                data['entrepreneurCode']?.toString() ??
                    'Unknown';

            final entrepreneurEmail =
                data['entrepreneurEmail']?.toString() ??
                    'Unknown';

            final productName =
                data['name']?.toString() ??
                    'Unknown Product';

            final supplierPrice =
                data['supplierPrice'] is num
                    ? (data['supplierPrice'] as num)
                        .toDouble()
                    : 0.0;

            final sellingPrice =
                data['sellingPrice'] is num
                    ? (data['sellingPrice'] as num)
                        .toDouble()
                    : 0.0;

            final profit =
                data['profit'] is num
                    ? (data['profit'] as num).toDouble()
                    : sellingPrice - supplierPrice;

            return Card(
              margin: const EdgeInsets.symmetric(
                vertical: 5,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.link,
                          color: Colors.blue,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            productName,
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.storefront,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SELLER',
                                style:
                                    TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              Text(
                                sellerCode,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              Text(
                                sellerEmail,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    const Center(
                      child: Icon(
                        Icons.arrow_downward,
                        size: 25,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.business_center,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ENTREPRENEUR / RESELLER',
                                style:
                                    TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              Text(
                                entrepreneurCode,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              Text(
                                entrepreneurEmail,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        _priceInfo(
                          'Supplier',
                          supplierPrice,
                        ),
                        _priceInfo(
                          'Selling',
                          sellingPrice,
                        ),
                        _priceInfo(
                          'Profit',
                          profit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================
  // PRICE INFO
  // ===========================================================

  Widget _priceInfo(
    String title,
    double price,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          '₩${price.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // ENTREPRENEUR CONFIRMATION
  // ===========================================================

  Future<void> _confirmEntrepreneurAction(
    String uid,
    String name,
    String status,
  ) async {
    final isApprove = status == 'approved';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isApprove
              ? 'Approve Entrepreneur'
              : 'Reject Entrepreneur',
        ),
        content: Text(
          isApprove
              ? 'Approve "$name" as an Entrepreneur / Reseller?'
              : 'Reject "$name"\'s Entrepreneur request?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isApprove ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(context, true),
            child: Text(
              isApprove ? 'Approve' : 'Reject',
            ),
          ),
        ],
      ),
    );

    if (result != true) return;

    await _updateEntrepreneurStatus(
      uid,
      status,
    );
  }

  // ===========================================================
  // ORDERS TAB
  // ===========================================================

  Widget _ordersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Text(
                'Error loading orders:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 60,
                  color: Colors.grey,
                ),
                SizedBox(
                  height: 12,
                ),
                Text(
                  'No orders yet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final sortedDocs = [...docs];

        sortedDocs.sort((a, b) {
          final aData =
              a.data() as Map<String, dynamic>;

          final bData =
              b.data() as Map<String, dynamic>;

          final aTime =
              aData['createdAt'] is Timestamp
                  ? aData['createdAt'] as Timestamp
                  : Timestamp(0, 0);

          final bTime =
              bData['createdAt'] is Timestamp
                  ? bData['createdAt'] as Timestamp
                  : Timestamp(0, 0);

          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final doc = sortedDocs[index];

            final data =
                doc.data() as Map<String, dynamic>;

            return _orderCard(
              doc.id,
              data,
            );
          },
        );
      },
    );
  }

  // ===========================================================
  // MULTI-PRODUCT ORDER CARD
  // ===========================================================

  Widget _orderCard(
    String orderId,
    Map<String, dynamic> data,
  ) {
    final customerName =
        data['customerName']?.toString() ??
            'Unknown Customer';

    final phone =
        data['phone']?.toString() ?? '';

    final address =
        data['address']?.toString() ?? '';

    final total =
        data['total'] is num
            ? (data['total'] as num).toDouble()
            : 0.0;

    final subtotal =
        data['subtotal'] is num
            ? (data['subtotal'] as num).toDouble()
            : 0.0;

    final deliveryFee =
        data['deliveryFee'] is num
            ? (data['deliveryFee'] as num).toDouble()
            : 0.0;

    final paymentMethod =
        data['paymentMethod']?.toString() ??
            'Unknown';

    final paymentStatus =
        data['paymentStatus']?.toString() ??
            'pending';

    final orderStatus =
        data['orderStatus']?.toString() ??
            'placed';

    final createdAt =
        data['createdAt'] is Timestamp
            ? data['createdAt'] as Timestamp
            : null;

    final dateText =
        createdAt != null
            ? _formatDate(createdAt.toDate())
            : 'Waiting...';

    final List<Map<String, dynamic>> orderItems = [];

    final rawItems = data['items'];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          orderItems.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    if (orderItems.isEmpty &&
        data['productName'] != null) {
      orderItems.add({
        'productId': data['productId'] ?? '',
        'productName':
            data['productName'] ?? 'Product',
        'imageUrl': data['imageUrl'] ?? '',
        'price': data['productPrice'] ?? 0,
        'quantity': data['quantity'] ?? 1,
        'total':
            data['subtotal'] ??
                data['total'] ??
                0,
      });
    }

    final itemCount =
        data['itemCount'] is num
            ? (data['itemCount'] as num).toInt()
            : orderItems.length;

    final totalQuantity =
        data['totalQuantity'] is num
            ? (data['totalQuantity'] as num).toInt()
            : orderItems.fold<int>(
                0,
                (sum, item) =>
                    sum +
                    _toInt(item['quantity']),
              );

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ORDER HEADER
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ORDER',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        orderId.length > 10
                            ? orderId.substring(0, 10)
                            : orderId,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _orderStatusChip(
                  orderStatus,
                ),
              ],
            ),

            const Divider(height: 22),

            // CUSTOMER
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 21,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CUSTOMER',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        customerName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      if (phone.isNotEmpty)
                        Text(phone),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            // ADDRESS
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 21,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DELIVERY ADDRESS',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        address.isNotEmpty
                            ? address
                            : 'No address',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            // ITEM COUNT
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    Colors.blue.shade50,
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    '$itemCount product(s) • '
                    '$totalQuantity item(s)',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ALL ORDER ITEMS
            const SizedBox(
              height: 4,
            ),

            ...orderItems.map(
              _buildOrderItem,
            ),

            const SizedBox(
              height: 12,
            ),

            // PRICE SUMMARY
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    'Subtotal',
                    subtotal,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  _summaryRow(
                    'Delivery',
                    deliveryFee,
                  ),
                  const Divider(
                    height: 18,
                  ),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₩${total.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // PAYMENT
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                const SizedBox(
                  width: 7,
                ),
                Expanded(
                  child: Text(
                    paymentMethod,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
                _paymentStatusChip(
                  paymentStatus,
                ),
              ],
            ),

            const SizedBox(
              height: 7,
            ),

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // CHANGE ORDER STATUS
            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                icon: const Icon(
                  Icons.local_shipping_outlined,
                ),
                label: const Text(
                  'Change Order Status',
                ),
                onPressed: () =>
                    _showOrderStatusDialog(
                  orderId,
                  orderStatus,
                ),
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            // CHANGE PAYMENT STATUS
            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                icon: const Icon(
                  Icons.payment_outlined,
                ),
                label: const Text(
                  'Change Payment Status',
                ),
                onPressed: () =>
                    _showPaymentStatusDialog(
                  orderId,
                  paymentStatus,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // ORDER ITEM
  // ===========================================================

  Widget _buildOrderItem(
    Map<String, dynamic> item,
  ) {
    final name =
        item['productName']?.toString() ??
            'Product';

    final imageUrl =
        item['imageUrl']?.toString() ?? '';

    final price =
        _toDouble(item['price']);

    final quantity =
        _toInt(item['quantity']);

    final itemTotal =
        _toDouble(item['total']);

    return Container(
      margin:
          const EdgeInsets.only(top: 8),
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color:
                  Colors.grey.shade100,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: imageUrl.trim().isNotEmpty
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons
                              .image_not_supported_outlined,
                          color: Colors.grey,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.grey,
                  ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  '₩${price.toStringAsFixed(0)} × $quantity',
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Text(
            '₩${itemTotal.toStringAsFixed(0)}',
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // SUMMARY ROW
  // ===========================================================

  Widget _summaryRow(
    String title,
    double value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        Text(
          '₩${value.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // ORDER STATUS CHIP
  // ===========================================================

  Widget _orderStatusChip(
    String status,
  ) {
    Color color;
    String label;

    switch (status) {
      case 'confirmed':
        color = Colors.blue;
        label = 'Confirmed';
        break;

      case 'processing':
        color = Colors.orange;
        label = 'Processing';
        break;

      case 'shipped':
        color = Colors.indigo;
        label = 'Shipped';
        break;

      case 'delivered':
        color = Colors.green;
        label = 'Delivered';
        break;

      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;

      default:
        color = Colors.grey;
        label = 'Order Placed';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ===========================================================
  // PAYMENT STATUS CHIP
  // ===========================================================

  Widget _paymentStatusChip(
    String status,
  ) {
    Color color;
    String label;

    switch (status) {
      case 'paid':
        color = Colors.green;
        label = 'Paid';
        break;

      case 'failed':
        color = Colors.red;
        label = 'Failed';
        break;

      case 'refunded':
        color = Colors.purple;
        label = 'Refunded';
        break;

      default:
        color = Colors.orange;
        label = 'Pending';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ===========================================================
  // CHANGE ORDER STATUS
  // ===========================================================

  Future<void> _showOrderStatusDialog(
    String orderId,
    String currentStatus,
  ) async {
    String selectedStatus = currentStatus;

    final result =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Change Order Status',
              ),
              content:
                  DropdownButtonFormField<String>(
                initialValue:
                    selectedStatus,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Order Status',
                  border:
                      OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'placed',
                    child:
                        Text('Order Placed'),
                  ),
                  DropdownMenuItem(
                    value: 'confirmed',
                    child:
                        Text('Confirmed'),
                  ),
                  DropdownMenuItem(
                    value: 'processing',
                    child:
                        Text('Processing'),
                  ),
                  DropdownMenuItem(
                    value: 'shipped',
                    child:
                        Text('Shipped'),
                  ),
                  DropdownMenuItem(
                    value: 'delivered',
                    child:
                        Text('Delivered'),
                  ),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child:
                        Text('Cancelled'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setDialogState(() {
                    selectedStatus = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                    selectedStatus,
                  ),
                  child:
                      const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'orderStatus': result,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Order status updated successfully',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update order status: $e',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===========================================================
  // CHANGE PAYMENT STATUS
  // ===========================================================

  Future<void> _showPaymentStatusDialog(
    String orderId,
    String currentStatus,
  ) async {
    String selectedStatus = currentStatus;

    final result =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Change Payment Status',
              ),
              content:
                  DropdownButtonFormField<String>(
                initialValue:
                    selectedStatus,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Payment Status',
                  border:
                      OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'pending',
                    child:
                        Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: 'paid',
                    child:
                        Text('Paid'),
                  ),
                  DropdownMenuItem(
                    value: 'failed',
                    child:
                        Text('Failed'),
                  ),
                  DropdownMenuItem(
                    value: 'refunded',
                    child:
                        Text('Refunded'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setDialogState(() {
                    selectedStatus = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                    selectedStatus,
                  ),
                  child:
                      const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'paymentStatus': result,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Payment status updated successfully',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update payment status: $e',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===========================================================
  // NUMBER HELPERS
  // ===========================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ===========================================================
  // FORMAT DATE
  // ===========================================================

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
