import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_product_page.dart';
import 'my_products_page.dart';
import 'seller_orders_page.dart';
import 'seller_return_refund_page.dart';
import 'news_feed_page.dart';

class SellerPage extends StatelessWidget {
  const SellerPage({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _statCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: enabled ? onTap : null,
      ),
    );
  }

  void _openAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    );
  }

  void _openMyProducts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyProductsPage(),
      ),
    );
  }

  void _openSellerOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SellerOrdersPage(),
      ),
    );
  }

  void _openReturnRefundRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SellerReturnRefundPage(),
      ),
    );
  }

  // =========================================================
  // OPEN MAIN VIDEOS
  // =========================================================

  void _openVideos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewsFeedPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Seller Dashboard'),
        ),
        body: const Center(
          child: Text(
            'Please login first.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load seller information.\n\n'
                '${userSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (userSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userData =
              userSnapshot.data?.data() ?? {};

          final sellerStatus =
              userData['sellerStatus']
                      ?.toString() ??
                  'pending';

          final sellerCode =
              userData['sellerCode']
                      ?.toString() ??
                  'Not assigned';

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where(
                  'sellerId',
                  isEqualTo: user.uid,
                )
                .snapshots(),
            builder: (context, productSnapshot) {
              if (productSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Unable to load products.\n\n'
                    '${productSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (productSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final products =
                  productSnapshot.data?.docs ?? [];

              int totalStock = 0;
              int totalSales = 0;
              int totalViews = 0;

              for (final product in products) {
                final data = product.data();

                totalStock +=
                    (data['stock'] as num?)
                            ?.toInt() ??
                        0;

                totalSales +=
                    (data['salesCount'] as num?)
                            ?.toInt() ??
                        0;

                totalViews +=
                    (data['views'] as num?)
                            ?.toInt() ??
                        0;
              }

              final isApproved =
                  sellerStatus == 'approved';

              final statusColor =
                  _statusColor(sellerStatus);

              return RefreshIndicator(
                onRefresh: () async {},
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // =================================================
                    // SELLER HEADER
                    // =================================================

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 32,
                            child: Icon(
                              Icons.storefront,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'BuyNova Seller',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Seller ID: $sellerCode',
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email ?? '',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors
                                        .grey
                                        .shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // APPROVAL STATUS
                    // =================================================

                    Container(
                      padding:
                          const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withValues(
                            alpha: 0.30,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isApproved
                                ? Icons.verified
                                : Icons.info_outline,
                            color: statusColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seller Status',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sellerStatus
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // =================================================
                    // OVERVIEW
                    // =================================================

                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      children: [
                        _statCard(
                          context: context,
                          title: 'Products',
                          value:
                              products.length.toString(),
                          icon:
                              Icons.inventory_2_outlined,
                        ),
                        _statCard(
                          context: context,
                          title: 'Stock',
                          value:
                              totalStock.toString(),
                          icon:
                              Icons.warehouse_outlined,
                        ),
                        _statCard(
                          context: context,
                          title: 'Sales',
                          value:
                              totalSales.toString(),
                          icon:
                              Icons.shopping_cart_checkout,
                        ),
                        _statCard(
                          context: context,
                          title: 'Views',
                          value:
                              totalViews.toString(),
                          icon:
                              Icons.visibility_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // =================================================
                    // PRODUCT MANAGEMENT
                    // =================================================

                    const Text(
                      'Product Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _menuCard(
                      context: context,
                      icon:
                          Icons.add_box_outlined,
                      title: 'Add Product',
                      subtitle: isApproved
                          ? 'Add a new product to BuyNova.'
                          : 'Seller approval is required.',
                      enabled: isApproved,
                      onTap: () {
                        _openAddProduct(context);
                      },
                    ),

                    _menuCard(
                      context: context,
                      icon:
                          Icons.inventory_outlined,
                      title: 'My Products',
                      subtitle:
                          'Manage, edit and delete your products.',
                      enabled: true,
                      onTap: () {
                        _openMyProducts(context);
                      },
                    ),

                    _menuCard(
                      context: context,
                      icon:
                          Icons.receipt_long_outlined,
                      title: 'Orders',
                      subtitle:
                          'View orders containing your products.',
                      enabled: isApproved,
                      onTap: () {
                        _openSellerOrders(context);
                      },
                    ),

                    // =================================================
                    // RETURN & REFUND
                    // =================================================

                    _menuCard(
                      context: context,
                      icon:
                          Icons.assignment_return_outlined,
                      title:
                          'Return & Refund Requests',
                      subtitle:
                          'Review customer return and refund requests.',
                      enabled: isApproved,
                      onTap: () {
                        _openReturnRefundRequests(
                          context,
                        );
                      },
                    ),

                    // =================================================
                    // VIDEOS
                    // =================================================

                    _menuCard(
                      context: context,
                      icon:
                          Icons.video_library_outlined,
                      title: 'Videos',
                      subtitle:
                          'Watch, upload and manage your BuyNova videos.',
                      enabled: isApproved,
                      onTap: () {
                        _openVideos(context);
                      },
                    ),

                    // =================================================
                    // SALES ANALYTICS
                    // =================================================

                    _menuCard(
                      context: context,
                      icon:
                          Icons.analytics_outlined,
                      title: 'Sales Analytics',
                      subtitle:
                          'View sales and product performance.',
                      enabled: isApproved,
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

                    // =================================================
                    // SELLER INFORMATION
                    // =================================================

                    const Text(
                      'Seller Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding:
                                  EdgeInsets.zero,
                              leading: const Icon(
                                Icons.badge_outlined,
                              ),
                              title:
                                  const Text('Seller ID'),
                              subtitle:
                                  Text(sellerCode),
                            ),
                            const Divider(),
                            ListTile(
                              contentPadding:
                                  EdgeInsets.zero,
                              leading: const Icon(
                                Icons.email_outlined,
                              ),
                              title:
                                  const Text('Email'),
                              subtitle:
                                  Text(user.email ?? ''),
                            ),
                            const Divider(),
                            ListTile(
                              contentPadding:
                                  EdgeInsets.zero,
                              leading: Icon(
                                Icons.verified_outlined,
                                color: statusColor,
                              ),
                              title:
                                  const Text('Status'),
                              subtitle: Text(
                                sellerStatus
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
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
}
