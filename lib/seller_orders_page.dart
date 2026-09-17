import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
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

  String _statusText(String status) {
    switch (status.toLowerCase()) {
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
        return 'Placed';
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      String two(int n) => n.toString().padLeft(2, '0');

      return '${date.year}-${two(date.month)}-${two(date.day)} '
          '${two(date.hour)}:${two(date.minute)}';
    }

    return 'Date unavailable';
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

  Widget _buildItemCard(Map<String, dynamic> item) {
    final name =
        item['productName']?.toString() ??
        item['name']?.toString() ??
        'Product';

    final imageUrl =
        item['imageUrl']?.toString() ??
        item['productImageUrl']?.toString() ??
        '';

    final price = _number(item['price']);
    final quantity = _int(item['quantity']);
    final total = _number(item['total']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          navigatorKey.currentContext!,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _imagePlaceholder();
                    },
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Price: ₩${price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  'Quantity: $quantity',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ₩${total.toStringAsFixed(0)}',
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
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: Colors.grey,
      ),
    );
  }

  void _showOrderDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final orderId = data['orderId']?.toString() ?? '';
    final customerName =
        data['customerName']?.toString() ?? 'Customer';
    final phone = data['phone']?.toString() ?? '';
    final address = data['address']?.toString() ?? '';
    final paymentMethod =
        data['paymentMethod']?.toString() ?? 'Unknown';
    final paymentStatus =
        data['paymentStatus']?.toString() ?? 'pending';
    final orderStatus =
        data['orderStatus']?.toString() ?? 'placed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Order ID: $orderId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Customer: $customerName'),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Phone: $phone'),
                  ],
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Address: $address'),
                  ],
                  const SizedBox(height: 12),
                  Text('Payment: $paymentMethod'),
                  Text('Payment Status: $paymentStatus'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Order Status: '),
                      _statusChip(orderStatus),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Seller Products',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._itemsFromOrder(data).map(
                    (item) => _buildItemCard(item),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Seller Subtotal: ₩${_number(data['sellerSubtotal']).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
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

  List<Map<String, dynamic>> _itemsFromOrder(
    Map<String, dynamic> data,
  ) {
    final rawItems = data['items'];

    if (rawItems is List) {
      return rawItems
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    return [];
  }

  Future<void> _updateOrderStatus(
    BuildContext context,
    String documentId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('seller_orders')
          .doc(documentId)
          .update({
        'orderStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order status changed to ${_statusText(status)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
          ),
        );
      }
    }
  }

  void _showStatusDialog(
    BuildContext context,
    String documentId,
    String currentStatus,
  ) {
    final statuses = [
      'placed',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map((status) {
              return ListTile(
                leading: Icon(
                  status == currentStatus
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(_statusText(status)),
                onTap: () async {
                  Navigator.pop(dialogContext);

                  await _updateOrderStatus(
                    context,
                    documentId,
                    status,
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final orderId =
        data['orderId']?.toString() ?? document.id;

    final customerName =
        data['customerName']?.toString() ?? 'Customer';

    final status =
        data['orderStatus']?.toString() ?? 'placed';

    final paymentStatus =
        data['paymentStatus']?.toString() ?? 'pending';

    final total =
        _number(data['sellerSubtotal']);

    final createdAt = _formatDate(
      data['createdAt'],
    );

    final items = _itemsFromOrder(data);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showOrderDetails(
            context,
            data,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Order #$orderId',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Customer: $customerName',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                createdAt,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${items.length} product(s)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...items.take(2).map(
                  (item) => _buildItemCard(item),
                ),
              ],
              if (items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 4,
                  ),
                  child: Text(
                    '+ ${items.length - 2} more product(s)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seller Total: ₩${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    'Payment: $paymentStatus',
                    style: TextStyle(
                      color: paymentStatus == 'paid'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showStatusDialog(
                      context,
                      document.id,
                      status,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Update Order Status',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Seller Orders'),
        ),
        body: const Center(
          child: Text(
            'Please login to view seller orders.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Orders'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('seller_orders')
            .where(
              'sellerId',
              isEqualTo: user.uid,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load seller orders.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
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
              snapshot.data?.docs.toList() ?? [];

          documents.sort((a, b) {
            final aTime = a.data()['createdAt'];
            final bTime = b.data()['createdAt'];

            if (aTime is Timestamp &&
                bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            return 0;
          });

          if (documents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 70,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Seller Orders Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Orders containing your products will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(
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

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();
