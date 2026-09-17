import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  String _statusText(String status) {
    switch (status) {
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
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
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

      final day =
          date.day.toString().padLeft(2, '0');
      final month =
          date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour =
          date.hour.toString().padLeft(2, '0');
      final minute =
          date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute';
    }

    return 'Processing...';
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildItemCard(
    Map<String, dynamic> item,
  ) {
    final name =
        (item['productName'] ?? 'Product').toString();

    final imageUrl =
        (item['imageUrl'] ?? '').toString();

    final price =
        _number(item['price']);

    final quantity =
        _int(item['quantity']);

    final itemTotal =
        _number(item['total']);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
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
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.image_not_supported_outlined,
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

          const SizedBox(width: 10),

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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '₩${price.toStringAsFixed(0)} × $quantity',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '₩${itemTotal.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final orderId =
        (data['orderId'] ?? document.id).toString();

    final status =
        (data['orderStatus'] ?? 'placed').toString();

    final paymentMethod =
        (data['paymentMethod'] ?? 'Cash on Delivery')
            .toString();

    final paymentStatus =
        (data['paymentStatus'] ?? 'pending')
            .toString();

    final total =
        _number(data['total']);

    final subtotal =
        _number(data['subtotal']);

    final deliveryFee =
        _number(data['deliveryFee']);

    final itemCount =
        _int(data['itemCount']);

    final totalQuantity =
        _int(data['totalQuantity']);

    final createdAt =
        data['createdAt'];

    final rawItems = data['items'];

    final List<Map<String, dynamic>> items = [];

    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is Map) {
          items.add(
            Map<String, dynamic>.from(rawItem),
          );
        }
      }
    }

    // পুরোনো single-product order support
    if (items.isEmpty &&
        data['productName'] != null) {
      items.add({
        'productId':
            data['productId'] ?? '',
        'productName':
            data['productName'] ?? 'Product',
        'imageUrl':
            data['imageUrl'] ?? '',
        'price':
            data['productPrice'] ?? 0,
        'quantity':
            data['quantity'] ?? 1,
        'total':
            data['subtotal'] ??
                data['total'] ??
                0,
      });
    }

    final displayItemCount =
        itemCount > 0
            ? itemCount
            : items.length;

    final displayQuantity =
        totalQuantity > 0
            ? totalQuantity
            : items.fold<int>(
                0,
                (sum, item) =>
                    sum +
                    _int(item['quantity']),
              );

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 22,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),

                _statusChip(status),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              _formatDate(createdAt),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const Divider(height: 24),

            Text(
              '$displayItemCount product(s) • $displayQuantity item(s)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            ...items.map(
              _buildItemCard,
            ),

            const SizedBox(height: 14),

            Container(
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₩${subtotal.toStringAsFixed(0)}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₩${deliveryFee.toStringAsFixed(0)}',
                      ),
                    ],
                  ),

                  const Divider(height: 18),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '₩${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 17,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 19,
                  color: Colors.grey,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    paymentMethod,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: paymentStatus ==
                            'paid'
                        ? Colors.green
                            .withValues(alpha: 0.12)
                        : Colors.orange
                            .withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    paymentStatus
                        .toUpperCase(),
                    style: TextStyle(
                      color: paymentStatus ==
                              'paid'
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Please login to see your orders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    final ordersStream = FirebaseFirestore
        .instance
        .collection('orders')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: ordersStream,
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
                  'Could not load orders.\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final documents =
              snapshot.data?.docs ?? [];

          final sortedDocuments =
              [...documents];

          sortedDocuments.sort(
            (a, b) {
              final aTime =
                  a.data()['createdAt'];

              final bTime =
                  b.data()['createdAt'];

              if (aTime is Timestamp &&
                  bTime is Timestamp) {
                return bTime
                    .compareTo(aTime);
              }

              return 0;
            },
          );

          if (sortedDocuments.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons
                          .shopping_bag_outlined,
                      size: 90,
                      color: Colors.grey,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'No Orders Yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Your orders will appear here.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 22),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.redAccent,
                        foregroundColor:
                            Colors.white,
                      ),
                      child: const Text(
                        'Continue Shopping',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount:
                sortedDocuments.length,
            itemBuilder:
                (context, index) {
              return _buildOrderCard(
                sortedDocuments[index],
              );
            },
          );
        },
      ),
    );
  }
}
