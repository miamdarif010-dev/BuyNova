import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EntrepreneurPage extends StatefulWidget {
  const EntrepreneurPage({super.key});

  @override
  State<EntrepreneurPage> createState() => _EntrepreneurPageState();
}

class _EntrepreneurPageState extends State<EntrepreneurPage> {
  bool _loading = true;

  String _status = 'none';
  String _entrepreneurCode = '';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadEntrepreneurData();
  }

  Future<void> _loadEntrepreneurData() async {
    final user = currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
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
            _status =
                data['entrepreneurStatus']?.toString() ?? 'none';

            _entrepreneurCode =
                data['entrepreneurCode']?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Entrepreneur loading error: $e');
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    final user = currentUser;

    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Become an Entrepreneur / Reseller',
          ),
          content: const Text(
            'Send a request to become an Entrepreneur / Reseller? '
            'An admin will review your request.',
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
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': user.displayName ?? '',
          'email': user.email,
          'entrepreneurStatus': 'pending',
          'entrepreneurRequestedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _status = 'pending';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Entrepreneur request sent successfully!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send request: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openMyStore() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyStorePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Entrepreneur / Reseller',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(),
            const SizedBox(height: 18),
            if (_status == 'approved') ...[
              _approvedSection(),
            ] else if (_status == 'pending') ...[
              _pendingSection(),
            ] else if (_status == 'rejected') ...[
              _rejectedSection(),
            ] else ...[
              _notRegisteredSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 38,
              child: Icon(
                Icons.business_center,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Entrepreneur / Reseller',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find products from BuyNova sellers, '
              'set your own selling price and earn profit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notRegisteredSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Start Reselling',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Become a BuyNova Entrepreneur / Reseller and '
          'start selling products from approved sellers.',
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _sendRequest,
            icon: const Icon(Icons.send),
            label: const Text(
              'Become an Entrepreneur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pendingSection() {
    return Card(
      color: Colors.orange.shade50,
      elevation: 0,
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_top,
              color: Colors.orange,
              size: 32,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Pending',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Your Entrepreneur / Reseller request '
                    'is waiting for admin approval.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rejectedSection() {
    return Column(
      children: [
        Card(
          color: Colors.red.shade50,
          elevation: 0,
          child: const ListTile(
            leading: Icon(
              Icons.cancel_outlined,
              color: Colors.red,
            ),
            title: Text(
              'Request Rejected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'You can send another request.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _sendRequest,
            child: const Text(
              'Request Again',
            ),
          ),
        ),
      ],
    );
  }

  Widget _approvedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.green.shade50,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entrepreneur Approved',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_entrepreneurCode.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 4),
                          child: Text(
                            'Entrepreneur ID: $_entrepreneurCode',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'My Business',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        _businessItem(
          icon: Icons.store_outlined,
          title: 'My Store',
          subtitle:
              'Manage products you want to resell.',
          onTap: _openMyStore,
        ),

        _businessItem(
          icon: Icons.add_business_outlined,
          title: 'Find Products',
          subtitle:
              'Browse products from BuyNova sellers.',
          onTap: _openMyStore,
        ),

        _businessItem(
          icon: Icons.shopping_bag_outlined,
          title: 'Reseller Orders',
          subtitle:
              'Manage orders from your customers.',
          onTap: () {
            _comingSoon('Reseller Orders');
          },
        ),

        _businessItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'My Profit',
          subtitle:
              'Track your reseller profit.',
          onTap: () {
            _comingSoon('My Profit');
          },
        ),
      ],
    );
  }

  Widget _businessItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
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
}

// =============================================================
// MY STORE PAGE
// =============================================================

class MyStorePage extends StatefulWidget {
  const MyStorePage({super.key});

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  Future<void> _removeFromStore(
    String documentId,
    String name,
  ) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Remove Product',
          ),
          content: Text(
            'Remove "$name" from your store?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('reseller_products')
          .doc(documentId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product removed from your store',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to remove product: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Store',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _storeHeader(user.uid),
          Expanded(
            child: _myStoreProducts(
              user.uid,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _showAvailableProducts,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Find Products',
        ),
      ),
    );
  }

  Widget _storeHeader(String uid) {
    return FutureBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(),
      builder: (context, snapshot) {
        final data =
            snapshot.data?.data() ?? {};

        final code =
            data['entrepreneurCode']
                    ?.toString() ??
                'ENT-${uid.substring(0, 6).toUpperCase()}';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    child: Icon(
                      Icons.store,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Reseller Store',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Entrepreneur ID: $code',
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _myStoreProducts(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reseller_products')
          .where(
            'entrepreneurUid',
            isEqualTo: uid,
          )
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Text(
                'Error loading My Store:\n'
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
                  Icons.store_outlined,
                  size: 65,
                  color: Colors.grey,
                ),
                SizedBox(height: 12),
                Text(
                  'Your store is empty',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Tap "Find Products" to add products.',
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.fromLTRB(
            12,
            0,
            12,
            90,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];

            final data =
                doc.data()
                    as Map<String, dynamic>;

            final name =
                data['name']?.toString() ??
                    'Product';

            final imageUrl =
                data['imageUrl']
                        ?.toString() ??
                    '';

            final supplierPrice =
                (data['supplierPrice']
                            is num)
                    ? (data['supplierPrice']
                            as num)
                        .toDouble()
                    : 0.0;

            final sellingPrice =
                (data['sellingPrice']
                            is num)
                    ? (data['sellingPrice']
                            as num)
                        .toDouble()
                    : 0.0;

            final profit =
                (data['profit'] is num)
                    ? (data['profit'] as num)
                        .toDouble()
                    : sellingPrice -
                        supplierPrice;

            final sellerCode =
                data['sellerCode']
                        ?.toString() ??
                    '';

            return Card(
              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                      child: SizedBox(
                        width: 85,
                        height: 85,
                        child: imageUrl
                                .isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Icon(
                                    Icons.image,
                                    size: 40,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.image,
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            'Supplier: â‚©'
                            '${supplierPrice.toStringAsFixed(0)}',
                          ),
                          Text(
                            'Selling: â‚©'
                            '${sellingPrice.toStringAsFixed(0)}',
                          ),
                          Text(
                            'Profit: â‚©'
                            '${profit.toStringAsFixed(0)}',
                            style:
                                const TextStyle(
                              color:
                                  Colors.green,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          if (sellerCode
                              .isNotEmpty)
                            Text(
                              'Seller ID: '
                              '$sellerCode',
                              style:
                                  TextStyle(
                                fontSize: 11,
                                color: Colors
                                    .grey
                                    .shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: () =>
                          _removeFromStore(
                        doc.id,
                        name,
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

  void _showAvailableProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AvailableProductsPage(),
      ),
    );
  }
}

// =============================================================
// AVAILABLE PRODUCTS
// =============================================================

class AvailableProductsPage
    extends StatelessWidget {
  const AvailableProductsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const _AvailableProductsPage();
  }
}

class _AvailableProductsPage
    extends StatefulWidget {
  const _AvailableProductsPage();

  @override
  State<_AvailableProductsPage> createState() =>
      _AvailableProductsPageState();
}

class _AvailableProductsPageState
    extends State<_AvailableProductsPage> {
  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  Future<void> addProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    final user = currentUser;

    if (user == null) return;

    final supplierPrice =
        (data['price'] is num)
            ? (data['price'] as num).toDouble()
            : 0.0;

    final sellerUid =
        data['sellerId']?.toString() ?? '';

    final sellerEmail =
        data['sellerEmail']?.toString() ?? '';

    final name =
        data['name']?.toString() ??
            'Product';

    final imageUrl =
        data['imageUrl']?.toString() ?? '';

    final category =
        data['category']?.toString() ??
            'General';

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final userData =
        userDoc.data() ?? {};

    final entrepreneurCode =
        userData['entrepreneurCode']
                ?.toString() ??
            'ENT-${user.uid.substring(0, 6).toUpperCase()}';

    final sellerCode =
        data['sellerCode']?.toString() ??
            (sellerUid.isNotEmpty
                ? 'SELL-${sellerUid.substring(0, 6).toUpperCase()}'
                : '');

    final controller =
        TextEditingController(
      text: (supplierPrice * 1.3)
          .round()
          .toString(),
    );

    final sellingPrice =
        await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Set Selling Price',
          ),
          content: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Supplier Price: '
                'â‚©${supplierPrice.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your Selling Price',
                  prefixText: 'â‚© ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your profit will be calculated automatically.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.replaceAll(',', '').trim(),
                );

                if (value == null || value <= 0) {
                  return;
                }

                Navigator.pop(context, value);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (sellingPrice == null) return;

    final profit = sellingPrice - supplierPrice;

    try {
      await FirebaseFirestore.instance
          .collection('reseller_products')
          .add({
        'productId': productId,
        'name': name,
        'imageUrl': imageUrl,
        'category': category,
        'supplierPrice': supplierPrice,
        'sellingPrice': sellingPrice,
        'profit': profit,
        'entrepreneurUid': user.uid,
        'entrepreneurCode': entrepreneurCode,
        'sellerUid': sellerUid,
        'sellerCode': sellerCode,
        'sellerEmail': sellerEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name added to your store!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add product: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find Products',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading products:\n${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No products available yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name']?.toString() ?? 'Product';
              final imageUrl = data['imageUrl']?.toString() ?? '';
              final price = (data['price'] is num)
                  ? (data['price'] as num).toDouble()
                  : 0.0;
              final sellerEmail = data['sellerEmail']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 85,
                          height: 85,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.image, size: 40);
                                  },
                                )
                              : const Icon(Icons.image, size: 40),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Supplier Price: â‚©${price.toStringAsFixed(0)}'),
                            if (sellerEmail.isNotEmpty)
                              Text(
                                'Seller: $sellerEmail',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => addProduct(doc.id, data),
                                child: const Text('Add to My Store'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
