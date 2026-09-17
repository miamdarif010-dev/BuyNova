import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        return status.isEmpty ? 'Order Placed' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'confirmed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    return 'Processing...';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Please sign in to see your orders.',
            style: TextStyle(fontSize: 16),
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
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where(
              'userId',
              isEqualTo: user.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Failed to load orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.redAccent,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _emptyOrders(context);
          }

          // Sort newest first locally.
          final sortedDocs = [...docs];

          sortedDocs.sort((a, b) {
            final aData =
                a.data() as Map<String, dynamic>;
            final bData =
                b.data() as Map<String, dynamic>;

            final aTime = aData['createdAt'];
            final bTime = bData['createdAt'];

            if (aTime is Timestamp &&
                bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            return 0;
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];

              final data =
                  doc.data() as Map<String, dynamic>;

              return _OrderCard(
                data: data,
                orderId: doc.id,
                statusText: _statusText(
                  data['orderStatus']
                          ?.toString() ??
                      'placed',
                ),
                statusColor: _statusColor(
                  data['orderStatus']
                          ?.toString() ??
                      'placed',
                ),
                formattedDate: _formatDate(
                  data['createdAt'],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyOrders(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 16),

            const Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Your orders will appear here.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
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
}

// =============================================================
// ORDER CARD
// =============================================================

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String orderId;
  final String statusText;
  final Color statusColor;
  final String formattedDate;

  const _OrderCard({
    required this.data,
    required this.orderId,
    required this.statusText,
    required this.statusColor,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final productName =
        data['productName']?.toString() ??
            'Product';

    final imageUrl =
        data['imageUrl']?.toString() ?? '';

    final quantity =
        data['quantity'] is num
            ? (data['quantity'] as num).toInt()
            : 1;

    final total =
        data['total'] is num
            ? (data['total'] as num).toDouble()
            : 0.0;

    final paymentMethod =
        data['paymentMethod']?.toString() ??
            'Cash on Delivery';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // ORDER HEADER
            // =================================================

            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.redAccent,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
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
                    color:
                        statusColor.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // =================================================
            // PRODUCT
            // =================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
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
                                Icons.image,
                                size: 35,
                                color: Colors.grey,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.image,
                          size: 35,
                          color: Colors.grey,
                        ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        'Quantity: $quantity',
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '₩${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // =================================================
            // ORDER DETAILS
            // =================================================

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _infoRow(
                    'Payment',
                    paymentMethod,
                  ),

                  const SizedBox(height: 6),

                  _infoRow(
                    'Order Date',
                    formattedDate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
