import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty ? 'Order Placed' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.deepPurple;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      String two(int number) {
        return number.toString().padLeft(2, '0');
      }

      return '${date.year}-${two(date.month)}-${two(date.day)} '
          '${two(date.hour)}:${two(date.minute)}';
    }

    return '';
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _sellerName(Map<String, dynamic> sellerOrder) {
    final sellerCode =
        sellerOrder['sellerCode']?.toString() ?? '';

    final sellerEmail =
        sellerOrder['sellerEmail']?.toString() ?? '';

    if (sellerCode.isNotEmpty) {
      return sellerCode;
    }

    if (sellerEmail.isNotEmpty) {
      return sellerEmail;
    }

    return 'Seller';
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _imagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _imagePlaceholder();
        },
      ),
    );
  }

  Widget _buildSellerOrder(
    BuildContext context,
    Map<String, dynamic> sellerOrder,
  ) {
    final sellerOrderId =
        sellerOrder['sellerOrderId']?.toString() ?? '';

    final sellerId =
        sellerOrder['sellerId']?.toString() ?? '';

    final sellerCode =
        sellerOrder['sellerCode']?.toString() ?? '';

    final sellerEmail =
        sellerOrder['sellerEmail']?.toString() ?? '';

    final status =
        sellerOrder['orderStatus']?.toString() ?? 'placed';

    final paymentStatus =
        sellerOrder['paymentStatus']?.toString() ?? 'pending';

    final sellerSubtotal =
        _number(sellerOrder['sellerSubtotal']);

    final totalQuantity =
        _int(sellerOrder['totalQuantity']);

    final items =
        (sellerOrder['items'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seller',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _sellerName(sellerOrder),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(status),
              ],
            ),

            const SizedBox(height: 14),

            // Seller information
            if (sellerCode.isNotEmpty)
              _infoRow(
                Icons.badge_outlined,
                'Seller ID',
                sellerCode,
              ),

            if (sellerEmail.isNotEmpty)
              _infoRow(
                Icons.email_outlined,
                'Seller Email',
                sellerEmail,
              ),

            if (sellerOrderId.isNotEmpty)
              _infoRow(
                Icons.receipt_long_outlined,
                'Seller Order',
                sellerOrderId,
              ),

            const Divider(height: 24),

            // Products
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No products found.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ...items.map((item) {
                final product =
                    Map<String, dynamic>.from(item as Map);

                final name =
                    product['name']?.toString() ??
                        'Product';

                final imageUrl =
                    product['imageUrl']?.toString() ?? '';

                final quantity =
                    _int(product['quantity']);

                final price =
                    _number(product['price']);

                final total =
                    _number(product['total']);

                final productTotal =
                    total > 0 ? total : price * quantity;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildProductImage(imageUrl),
                      const SizedBox(width: 12),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Qty: $quantity',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '₩${productTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const Divider(height: 24),

            // Summary
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '$totalQuantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seller Subtotal',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '₩${sellerSubtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  paymentStatus.toUpperCase(),
                  style: TextStyle(
                    color: paymentStatus.toLowerCase() ==
                            'paid'
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (sellerOrder['createdAt'] != null)
              Text(
                'Ordered: ${_formatDate(sellerOrder['createdAt'])}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '$title: ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOrder(
    BuildContext context,
    Map<String, dynamic> order,
    List<Map<String, dynamic>> sellerOrders,
  ) {
    final orderId =
        order['orderId']?.toString() ?? '';

    final mainStatus =
        order['orderStatus']?.toString() ?? 'placed';

    final paymentMethod =
        order['paymentMethod']?.toString() ?? '';

    final total =
        _number(order['total']);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main order header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withValues(alpha: 0.12),
                  Colors.redAccent.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            orderId.isEmpty
                                ? 'Order'
                                : orderId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusChip(mainStatus),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '₩${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                if (paymentMethod.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Payment: $paymentMethod',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],

                if (order['createdAt'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Ordered: ${_formatDate(order['createdAt'])}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Seller orders
          if (sellerOrders.isNotEmpty)
            ...sellerOrders.map(
              (sellerOrder) => _buildSellerOrder(
                context,
                sellerOrder,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      Colors.grey.withValues(alpha: 0.15),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Seller order details are not available yet.',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
        ),
        body: const Center(
          child: Text(
            'Please login to view your orders.',
          ),
        ),
      );
    }

    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots();

    final sellerOrdersStream =
        FirebaseFirestore.instance
            .collection('seller_orders')
            .where(
              'customerId',
              isEqualTo: user.uid,
            )
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ordersStream,
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (orderSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load orders.\n\n${orderSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final orders = orderSnapshot.data?.docs ?? [];

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: sellerOrdersStream,
            builder: (context, sellerSnapshot) {
              if (sellerSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (sellerSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Failed to load seller orders.\n\n'
                      '${sellerSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final sellerDocs =
                  sellerSnapshot.data?.docs ?? [];

              final Map<String,
                      List<Map<String, dynamic>>>
                  sellerOrdersByMainOrder = {};

              for (final doc in sellerDocs) {
                final data = doc.data();

                final orderId =
                    data['orderId']?.toString() ?? '';

                if (orderId.isEmpty) {
                  continue;
                }

                sellerOrdersByMainOrder
                    .putIfAbsent(
                      orderId,
                      () => [],
                    )
                    .add(data);
              }

              if (orders.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          'No Orders Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Your orders will appear here.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final sortedOrders =
                  [...orders];

              sortedOrders.sort((a, b) {
                final aDate =
                    a.data()['createdAt'];

                final bDate =
                    b.data()['createdAt'];

                if (aDate is Timestamp &&
                    bDate is Timestamp) {
                  return bDate.compareTo(aDate);
                }

                return 0;
              });

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  30,
                ),
                itemCount: sortedOrders.length,
                itemBuilder: (context, index) {
                  final orderDoc =
                      sortedOrders[index];

                  final orderData =
                      orderDoc.data();

                  final orderId =
                      orderData['orderId']
                              ?.toString()
                              .isNotEmpty ==
                          true
                      ? orderData['orderId']
                          .toString()
                      : orderDoc.id;

                  final sellerOrders =
                      sellerOrdersByMainOrder[
                              orderId] ??
                          [];

                  return _buildMainOrder(
                    context,
                    orderData,
                    sellerOrders,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
