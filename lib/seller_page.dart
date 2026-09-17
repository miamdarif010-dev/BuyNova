import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_product_page.dart';
import 'my_products_page.dart';

class SellerPage extends StatelessWidget {
  const SellerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Seller Dashboard'),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Please login first.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userData = userSnapshot.data?.data() ?? {};

          final sellerCode =
              userData['sellerCode']?.toString() ?? 'N/A';

          final sellerStatus =
              userData['sellerStatus']?.toString() ?? 'pending';

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where(
                  'sellerId',
                  isEqualTo: user.uid,
                )
                .snapshots(),
            builder: (context, productSnapshot) {
              final products =
                  productSnapshot.data?.docs ?? [];

              int totalProducts = products.length;
              int totalStock = 0;
              int totalSales = 0;
              int totalViews = 0;

              for (final product in products) {
                final data = product.data();

                totalStock += data['stock'] is num
                    ? (data['stock'] as num).toInt()
                    : 0;

                totalSales += data['salesCount'] is num
                    ? (data['salesCount'] as num).toInt()
                    : 0;

                totalViews += data['views'] is num
                    ? (data['views'] as num).toInt()
                    : 0;
              }

              final isApproved =
                  sellerStatus == 'approved';

              return RefreshIndicator(
                onRefresh: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  await FirebaseFirestore.instance
                      .collection('products')
                      .where(
                        'sellerId',
                        isEqualTo: user.uid,
                      )
                      .get();
                },
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // =========================================
                    // SELLER HEADER
                    // =========================================

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.redAccent,
                            Colors.red,
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.redAccent,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'BuyNova Seller',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Seller ID: $sellerCode',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isApproved
                                ? Icons.verified
                                : Icons.pending,
                            color: Colors.white,
                            size: 30,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =========================================
                    // APPROVAL STATUS
                    // =========================================

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isApproved
                            ? Colors.green.withValues(
                                alpha: 0.10,
                              )
                            : Colors.orange.withValues(
                                alpha: 0.10,
                              ),
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: isApproved
                              ? Colors.green.withValues(
                                  alpha: 0.25,
                                )
                              : Colors.orange.withValues(
                                  alpha: 0.25,
                                ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isApproved
                                ? Icons.check_circle
                                : Icons.pending,
                            color: isApproved
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isApproved
                                      ? 'Seller Approved'
                                      : 'Seller Approval Pending',
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isApproved
                                      ? 'You can manage your products.'
                                      : 'Please wait for BuyNova Admin approval.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =========================================
                    // STATISTICS
                    // =========================================

                    const Text(
                      'Seller Overview',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      children: [
                        _statCard(
                          icon:
                              Icons.inventory_2_outlined,
                          title: 'Products',
                          value:
                              '$totalProducts',
                        ),
                        _statCard(
                          icon:
                              Icons.warehouse_outlined,
                          title: 'Stock',
                          value:
                              '$totalStock',
                        ),
                        _statCard(
                          icon:
                              Icons.shopping_bag_outlined,
                          title: 'Sales',
                          value:
                              '$totalSales',
                        ),
                        _statCard(
                          icon:
                              Icons.visibility_outlined,
                          title: 'Views',
                          value:
                              '$totalViews',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // =========================================
                    // PRODUCT MANAGEMENT
                    // =========================================

                    const Text(
                      'Product Management',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _menuCard(
                      context: context,
                      icon:
                          Icons.add_box_outlined,
                      title: 'Add Product',
                      subtitle:
                          'Add a new product to BuyNova',
                      color: Colors.green,
                      enabled: isApproved,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AddProductPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    _menuCard(
                      context: context,
                      icon:
                          Icons.inventory_2_outlined,
                      title: 'My Products',
                      subtitle:
                          'View, edit and delete your products',
                      color: Colors.blue,
                      enabled: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MyProductsPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    _menuCard(
                      context: context,
                      icon:
                          Icons.receipt_long_outlined,
                      title: 'Orders',
                      subtitle:
                          'Manage orders for your products',
                      color: Colors.orange,
                      enabled: true,
                      onTap: () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Seller Orders will be added next.',
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    _menuCard(
                      context: context,
                      icon:
                          Icons.video_library_outlined,
                      title: 'Seller Videos',
                      subtitle:
                          'Create and manage product videos',
                      color: Colors.purple,
                      enabled: true,
                      onTap: () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Seller Videos will be added next.',
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    _menuCard(
                      context: context,
                      icon:
                          Icons.bar_chart_outlined,
                      title: 'Sales Analytics',
                      subtitle:
                          'View your product performance',
                      color: Colors.teal,
                      enabled: true,
                      onTap: () {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sales Analytics will be added next.',
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // =========================================
                    // SELLER INFORMATION
                    // =========================================

                    const Text(
                      'Seller Information',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _infoRow(
                              Icons.badge_outlined,
                              'Seller ID',
                              sellerCode,
                            ),
                            const Divider(height: 24),
                            _infoRow(
                              Icons.email_outlined,
                              'Email',
                              user.email ?? 'N/A',
                            ),
                            const Divider(height: 24),
                            _infoRow(
                              isApproved
                                  ? Icons.verified
                                  : Icons.pending,
                              'Status',
                              sellerStatus,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  static Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MENU CARD
  // =========================================================

  static Widget _menuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        enabled: enabled,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: enabled
                ? color
                : Colors.grey,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          enabled
              ? subtitle
              : 'Available after seller approval',
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: enabled
            ? onTap
            : () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Your seller account must be approved first.',
                    ),
                  ),
                );
              },
      ),
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  static Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: Colors.redAccent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
