import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      length: 5,
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
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
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

      final existingData =
          userDoc.data() ?? {};

      final updateData =
          <String, dynamic>{
        'sellerStatus': status,
      };

      // Generate Seller ID when approved.
      if (status == 'approved') {
        final existingSellerCode =
            existingData['sellerCode']
                    ?.toString() ??
                '';

        if (existingSellerCode.isEmpty) {
          updateData['sellerCode'] =
              _generateSellerCode(uid);

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
  // UPDATE ENTREPRENEUR STATUS + ENTREPRENEUR ID
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

      final existingData =
          userDoc.data() ?? {};

      final updateData =
          <String, dynamic>{
        'entrepreneurStatus': status,
      };

      // Generate Entrepreneur ID when approved.
      if (status == 'approved') {
        final existingEntrepreneurCode =
            existingData['entrepreneurCode']
                    ?.toString() ??
                '';

        if (existingEntrepreneurCode.isEmpty) {
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
              icon: Icon(Icons.inventory_2_outlined),
              text: 'Products',
            ),
            Tab(
              icon: Icon(Icons.people_outline),
              text: 'Users',
            ),
            Tab(
              icon: Icon(Icons.storefront_outlined),
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
                'Error loading products:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

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
                doc.data()
                    as Map<String, dynamic>;

            final name =
                data['name']?.toString() ??
                    'Unnamed';

            final price =
                data['price'] is num
                    ? (data['price'] as num)
                        .toDouble()
                    : 0.0;

            final imageUrl =
                data['imageUrl']?.toString();

            final sellerEmail =
                data['sellerEmail']
                        ?.toString() ??
                    'Unknown seller';

            final sellerCode =
                data['sellerCode']
                        ?.toString() ??
                    '';

            final category =
                data['category']?.toString() ??
                    'General';

            return Card(
              margin:
                  const EdgeInsets.symmetric(
                vertical: 4,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.grey.shade200,
                  backgroundImage:
                      imageUrl != null &&
                              imageUrl.isNotEmpty
                          ? NetworkImage(
                              imageUrl,
                            )
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
                  overflow:
                      TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '₩${price.toStringAsFixed(0)} • '
                  '$category\n'
                  '${sellerCode.isNotEmpty ? '$sellerCode • ' : ''}'
                  '$sellerEmail',
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () =>
                      _deleteProduct(
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
                'Error loading users:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

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
                doc.data()
                    as Map<String, dynamic>;

            final name =
                data['name']?.toString() ??
                    'Unnamed User';

            final email =
                data['email']?.toString() ??
                    '';

            final sellerStatus =
                data['sellerStatus']
                        ?.toString() ??
                    'none';

            final entrepreneurStatus =
                data['entrepreneurStatus']
                        ?.toString() ??
                    'none';

            final sellerCode =
                data['sellerCode']
                        ?.toString() ??
                    '';

            final entrepreneurCode =
                data['entrepreneurCode']
                        ?.toString() ??
                    '';

            return Card(
              margin:
                  const EdgeInsets.symmetric(
                vertical: 5,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(10),
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
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                name,
                                style:
                                    const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors
                                      .grey
                                      .shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // SELLER ID
                    if (sellerCode.isNotEmpty)
                      _idBox(
                        icon:
                            Icons.storefront,
                        title: 'Seller ID',
                        value: sellerCode,
                      ),

                    // ENTREPRENEUR ID
                    if (entrepreneurCode
                        .isNotEmpty)
                      _idBox(
                        icon:
                            Icons.business_center,
                        title:
                            'Entrepreneur ID',
                        value:
                            entrepreneurCode,
                      ),

                    const SizedBox(height: 8),

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
                              'Entrepreneur: '
                              '$entrepreneurStatus',
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
      margin:
          const EdgeInsets.only(bottom: 6),
      padding:
          const EdgeInsets.symmetric(
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
          const SizedBox(width: 8),
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
      visualDensity:
          VisualDensity.compact,
    );
  }

  // ===========================================================
  // SELLER REQUESTS TAB
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

        final docs =
            snapshot.data?.docs ?? [];

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
                doc.data()
                    as Map<String, dynamic>;

            final name =
                data['name']?.toString() ??
                    'Unnamed User';

            final email =
                data['email']?.toString() ??
                    '';

            return Card(
              margin:
                  const EdgeInsets.symmetric(
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
  // ENTREPRENEUR REQUESTS TAB
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

        final docs =
            snapshot.data?.docs ?? [];

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
                SizedBox(height: 12),
                Text(
                  'No pending entrepreneur requests',
                  style: TextStyle(
                    fontSize: 16,
                  ),
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
                doc.data()
                    as Map<String, dynamic>;

            final name =
                data['name']?.toString() ??
                    'Unnamed User';

            final email =
                data['email']?.toString() ??
                    '';

            final phone =
                data['phone']?.toString() ??
                    '';

            return Card(
              margin:
                  const EdgeInsets.symmetric(
                vertical: 5,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(8),
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
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 5,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          email,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                        if (phone.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 3,
                            ),
                            child: Text(
                              phone,
                            ),
                          ),
                        const SizedBox(
                          height: 5,
                        ),
                        const Text(
                          'Status: Pending',
                          style: TextStyle(
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
                        icon:
                            const Icon(
                          Icons.check_circle,
                          color:
                              Colors.green,
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
                        icon:
                            const Icon(
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
  // SELLER ↔ ENTREPRENEUR RELATIONSHIPS
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
              padding:
                  const EdgeInsets.all(20),
              child: Text(
                'Error loading relationships:\n'
                '${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

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
                SizedBox(height: 12),
                Text(
                  'No Seller ↔ Entrepreneur relationships yet',
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            final data =
                doc.data()
                    as Map<String, dynamic>;

            final sellerCode =
                data['sellerCode']
                        ?.toString() ??
                    'Unknown';

            final sellerEmail =
                data['sellerEmail']
                        ?.toString() ??
                    'Unknown';

            final entrepreneurCode =
                data['entrepreneurCode']
                        ?.toString() ??
                    'Unknown';

            final entrepreneurEmail =
                data['entrepreneurEmail']
                        ?.toString() ??
                    'Unknown';

            final productName =
                data['name']?.toString() ??
                    'Unknown Product';

            final supplierPrice =
                data['supplierPrice'] is num
                    ? (data['supplierPrice']
                            as num)
                        .toDouble()
                    : 0.0;

            final sellingPrice =
                data['sellingPrice'] is num
                    ? (data['sellingPrice']
                            as num)
                        .toDouble()
                    : 0.0;

            final profit =
                data['profit'] is num
                    ? (data['profit'] as num)
                        .toDouble()
                    : sellingPrice -
                        supplierPrice;

            return Card(
              margin:
                  const EdgeInsets.symmetric(
                vertical: 5,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(12),
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

                    // SELLER
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
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
                                CrossAxisAlignment
                                    .start,
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
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ARROW
                    const Center(
                      child: Icon(
                        Icons
                            .arrow_downward,
                        size: 25,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ENTREPRENEUR
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Icon(
                          Icons
                              .business_center,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
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
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(),

                    // PRICE INFORMATION
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
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
  // CONFIRM ENTREPRENEUR ACTION
  // ===========================================================

  Future<void> _confirmEntrepreneurAction(
    String uid,
    String name,
    String status,
  ) async {
    final isApprove =
        status == 'approved';

    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
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
                Navigator.pop(
              context,
              false,
            ),
            child:
                const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  isApprove
                      ? Colors.green
                      : Colors.red,
              foregroundColor:
                  Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),
            child: Text(
              isApprove
                  ? 'Approve'
                  : 'Reject',
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
}
