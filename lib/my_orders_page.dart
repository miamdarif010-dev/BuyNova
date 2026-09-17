import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  User? get _user => FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    final user = _user;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  String _formatPrice(dynamic price) {
    double value = 0;

    if (price is num) {
      value = price.toDouble();
    } else {
      value = double.tryParse(
            price?.toString() ?? '0',
          ) ??
          0;
    }

    return '₩${value.toStringAsFixed(0)}';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();

      final year = date.year.toString();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$year-$month-$day $hour:$minute';
    }

    return 'Date unavailable';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;

      case 'shipped':
        return Colors.blue;

      case 'processing':
        return Colors.orange;

      case 'cancelled':
        return Colors.red;

      case 'pending':
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    if (status.isEmpty) {
      return 'Pending';
    }

    switch (status.toLowerCase()) {
      case 'delivered':
        return 'Delivered';

      case 'shipped':
        return 'Shipped';

      case 'processing':
        return 'Processing';

      case 'cancelled':
        return 'Cancelled';

      case 'pending':
      default:
        return 'Pending';
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
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

  Widget _orderCard(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final orderId = document.id;

    final productName =
        (data['productName'] ?? 'BuyNova Product').toString();

    final productImage =
        (data['productImageUrl'] ?? '').toString();

    final status =
        (data['status'] ?? 'pending').toString();

    final quantity = data['quantity'] ?? 1;

    final total = data['totalPrice'] ??
        data['total'] ??
        data['price'] ??
        0;

    final createdAt = data['createdAt'];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showOrderDetails(
            context,
            document,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // PRODUCT IMAGE
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100,
                    ),
                    child: productImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(10),
                            child: Image.network(
                              productImage,
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
                            size: 35,
                            color: Colors.grey,
                          ),
                  ),

                  const SizedBox(width: 12),

                  // PRODUCT INFORMATION
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Quantity: $quantity',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatPrice(total),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  _statusBadge(status),
                ],
              ),

              const SizedBox(height: 12),

              const Divider(height: 1),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final orderId = document.id;

    final productName =
        (data['productName'] ?? 'BuyNova Product').toString();

    final productImage =
        (data['productImageUrl'] ?? '').toString();

    final status =
        (data['status'] ?? 'pending').toString();

    final quantity = data['quantity'] ?? 1;

    final total = data['totalPrice'] ??
        data['total'] ??
        data['price'] ??
        0;

    final address =
        (data['shippingAddress'] ??
                data['address'] ??
                '')
            .toString();

    final paymentMethod =
        (data['paymentMethod'] ?? 'Not specified')
            .toString();

    final createdAt = data['createdAt'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (productImage.isNotEmpty)
                    Center(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12),
                        child: Image.network(
                          productImage,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Container(
                              width: 140,
                              height: 140,
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons
                                    .image_not_supported_outlined,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _detailRow(
                    'Order ID',
                    orderId,
                  ),

                  _detailRow(
                    'Status',
                    _statusText(status),
                  ),

                  _detailRow(
                    'Quantity',
                    quantity.toString(),
                  ),

                  _detailRow(
                    'Total',
                    _formatPrice(total),
                  ),

                  _detailRow(
                    'Payment',
                    paymentMethod,
                  ),

                  _detailRow(
                    'Date',
                    _formatDate(createdAt),
                  ),

                  if (address.isNotEmpty)
                    _detailRow(
                      'Shipping Address',
                      address,
                    ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Close'),
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

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
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

  Widget _emptyOrders() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 80,
        ),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(
                  alpha: 0.08,
                ),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 45,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your orders will appear here after you place an order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
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
        body: const Center(
          child: Text(
            'Please log in to view your orders.',
          ),
        ),
      );
    }

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
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load orders.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents =
              snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return _emptyOrders();
          }

          documents.sort((a, b) {
            final aData = a.data();
            final bData = b.data();

            final aTime = aData['createdAt'];
            final bTime = bData['createdAt'];

            if (aTime is Timestamp &&
                bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            return 0;
          });

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(
                const Duration(milliseconds: 300),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics:
                  const AlwaysScrollableScrollPhysics(),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return _orderCard(
                  context,
                  documents[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
