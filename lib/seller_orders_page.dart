import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'seller_return_refund_page.dart';

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  // =========================================================
  // STATUS COLOR
  // =========================================================

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

  // =========================================================
  // STATUS TEXT
  // =========================================================

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

  // =========================================================
  // NOTIFICATION TITLE
  // =========================================================

  String _notificationTitle(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Order Confirmed';
      case 'processing':
        return 'Order Processing';
      case 'shipped':
        return 'Order Shipped';
      case 'delivered':
        return 'Order Delivered';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return 'Order Updated';
    }
  }

  // =========================================================
  // NOTIFICATION MESSAGE
  // =========================================================

  String _notificationMessage({
    required String status,
    required String sellerName,
  }) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Your order has been confirmed by $sellerName.';

      case 'processing':
        return 'Your order is now being prepared by $sellerName.';

      case 'shipped':
        return 'Your order has been shipped by $sellerName.';

      case 'delivered':
        return 'Your order has been delivered successfully.';

      case 'cancelled':
        return 'Your order has been cancelled by $sellerName.';

      default:
        return 'Your order status has been updated to '
            '${_statusText(status)}.';
    }
  }

  // =========================================================
  // NOTIFICATION TYPE
  // =========================================================

  String _notificationType(String status) {
    switch (status.toLowerCase()) {
      case 'shipped':
        return 'shipped';

      case 'delivered':
        return 'delivered';

      case 'cancelled':
        return 'cancelled';

      default:
        return 'order';
    }
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      String two(int n) => n.toString().padLeft(2, '0');

      return '${date.year}-${two(date.month)}-${two(date.day)} '
          '${two(date.hour)}:${two(date.minute)}';
    }

    return 'Date unavailable';
  }

  // =========================================================
  // NUMBER
  // =========================================================

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // INT
  // =========================================================

  int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // STATUS CHIP
  // =========================================================

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

  // =========================================================
  // IMAGE PLACEHOLDER
  // =========================================================

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

  // =========================================================
  // BUILD ITEM CARD
  // =========================================================

  Widget _buildItemCard(
    Map<String, dynamic> item,
  ) {
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

    final totalValue = item['total'];

    final total = totalValue != null
        ? _number(totalValue)
        : price * quantity;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
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
                const SizedBox(height: 5),
                Text(
                  '₩${price.toStringAsFixed(0)} × $quantity',
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ₩${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ITEMS
  // =========================================================

  List<Map<String, dynamic>> _items(
    Map<String, dynamic> data,
  ) {
    final raw = data['items'];

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  // =========================================================
  // CREATE BUYER NOTIFICATION
  // =========================================================

  void _addBuyerNotification({
    required WriteBatch batch,
    required String customerId,
    required String orderId,
    required String sellerId,
    required String sellerName,
    required String newStatus,
  }) {
    if (customerId.isEmpty) return;

    final firestore = FirebaseFirestore.instance;

    final notificationRef = firestore
        .collection('users')
        .doc(customerId)
        .collection('notifications')
        .doc();

    batch.set(
      notificationRef,
      {
        'title': _notificationTitle(newStatus),
        'message': _notificationMessage(
          status: newStatus,
          sellerName: sellerName,
        ),
        'type': _notificationType(newStatus),
        'orderId': orderId,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'customerId': customerId,
        'orderStatus': newStatus,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // =========================================================
  // UPDATE SELLER ORDER + MAIN ORDER
  // + BUYER NOTIFICATION
  // =========================================================

  Future<void> _updateStatus({
    required BuildContext context,
    required String sellerOrderId,
    required String mainOrderId,
    required String sellerId,
    required String customerId,
    required String newStatus,
    required String currentStatus,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (user.uid != sellerId) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are not allowed to update this order.',
          ),
        ),
      );

      return;
    }

    if (newStatus == currentStatus) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order is already ${_statusText(currentStatus)}.',
          ),
        ),
      );

      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // -------------------------------------------------------
      // SELLER ORDER
      // -------------------------------------------------------

      final sellerOrderRef = firestore
          .collection('seller_orders')
          .doc(sellerOrderId);

      batch.update(
        sellerOrderRef,
        {
          'orderStatus': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // -------------------------------------------------------
      // MAIN CUSTOMER ORDER
      // -------------------------------------------------------

      if (mainOrderId.isNotEmpty) {
        final mainOrderRef = firestore
            .collection('orders')
            .doc(mainOrderId);

        final mainOrder = await mainOrderRef.get();

        if (mainOrder.exists) {
          final data = mainOrder.data();

          final sellerIds = <String>{};

          final rawItems = data?['items'];

          if (rawItems is List) {
            for (final rawItem in rawItems) {
              if (rawItem is Map) {
                final id =
                    rawItem['sellerId']?.toString();

                if (id != null && id.isNotEmpty) {
                  sellerIds.add(id);
                }
              }
            }
          }

          // Single seller order:
          // synchronize main order status.
          if (sellerIds.length <= 1) {
            batch.update(
              mainOrderRef,
              {
                'orderStatus': newStatus,
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
            );
          }
        }
      }

      // -------------------------------------------------------
      // BUYER NOTIFICATION
      // -------------------------------------------------------

      _addBuyerNotification(
        batch: batch,
        customerId: customerId,
        orderId: mainOrderId,
        sellerId: sellerId,
        sellerName: user.displayName ?? 'Seller',
        newStatus: newStatus,
      );

      // -------------------------------------------------------
      // COMMIT
      // -------------------------------------------------------

      await batch.commit();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order changed to '
            '${_statusText(newStatus)}.\n'
            'Buyer notification sent.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update order.\n$e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // STATUS DIALOG
  // =========================================================

  void _showStatusDialog(
    BuildContext context, {
    required String sellerOrderId,
    required String mainOrderId,
    required String sellerId,
    required String customerId,
    required String currentStatus,
  }) {
    const statuses = [
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
          title: const Text(
            'Update Order Status',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: statuses.map(
              (status) {
                final selected = status == currentStatus;

                return ListTile(
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? _statusColor(status)
                        : null,
                  ),
                  title: Text(
                    _statusText(status),
                  ),
                  onTap: () async {
                    Navigator.pop(dialogContext);

                    await _updateStatus(
                      context: context,
                      sellerOrderId: sellerOrderId,
                      mainOrderId: mainOrderId,
                      sellerId: sellerId,
                      customerId: customerId,
                      newStatus: status,
                      currentStatus: currentStatus,
                    );
                  },
                );
              },
            ).toList(),
          ),
        );
      },
    );
  }

  // =========================================================
  // RETURN / REFUND PAGE
  // =========================================================

  void _openReturnRefundPage(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SellerReturnRefundPage(),
      ),
    );
  }

  // =========================================================
  // CHECK RETURN / REFUND REQUESTS FOR ORDER
  // =========================================================

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _returnRefundRequestsStream(
    String sellerId,
    String orderId,
  ) {
    return FirebaseFirestore.instance
        .collection('return_refund_requests')
        .where(
          'sellerId',
          isEqualTo: sellerId,
        )
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.where((doc) {
          final data = doc.data();

          final requestOrderId =
              data['orderId']?.toString() ?? '';

          return requestOrderId == orderId;
        }).toList();
      },
    );
  }

  // =========================================================
  // RETURN / REFUND BUTTON
  // =========================================================

  Widget _returnRefundButton(
    BuildContext context, {
    required String sellerId,
    required String orderId,
  }) {
    if (sellerId.isEmpty || orderId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<
        List<QueryDocumentSnapshot<
            Map<String, dynamic>>>>(
      stream: _returnRefundRequestsStream(
        sellerId,
        orderId,
      ),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;

        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(
            top: 10,
          ),
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              _openReturnRefundPage(context);
            },
            icon: const Icon(
              Icons.assignment_return_outlined,
            ),
            label: Text(
              'Return / Refund Requests ($count)',
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // ORDER DETAILS
  // =========================================================

  Future<void> _showOrderDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final orderId =
        data['orderId']?.toString() ?? '';

    final customerName =
        data['customerName']?.toString() ??
            'Customer';

    final phone =
        data['phone']?.toString() ?? '';

    final address =
        data['address']?.toString() ?? '';

    final paymentMethod =
        data['paymentMethod']?.toString() ??
            'Unknown';

    final paymentStatus =
        data['paymentStatus']?.toString() ??
            'pending';

    final status =
        data['orderStatus']?.toString() ??
            'placed';

    final sellerId =
        data['sellerId']?.toString() ?? '';

    final items = _items(data);

    final sellerSubtotal =
        _number(data['sellerSubtotal']);

    await showModalBottomSheet<void>(
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

                  Text(
                    'Order ID: $orderId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Customer: $customerName',
                  ),

                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Phone: $phone',
                    ),
                  ],

                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Address: $address',
                    ),
                  ],

                  const SizedBox(height: 12),

                  Text(
                    'Payment: $paymentMethod',
                  ),

                  Text(
                    'Payment Status: $paymentStatus',
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Text(
                        'Status: ',
                      ),
                      _statusChip(status),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Your Products',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...items.map(
                    (item) => _buildItemCard(item),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Seller Subtotal: '
                    '₩${sellerSubtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  _returnRefundButton(
                    context,
                    sellerId: sellerId,
                    orderId: orderId,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // ORDER CARD
  // =========================================================

  Widget _buildOrderCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final data = document.data();

    final sellerOrderId =
        data['sellerOrderId']?.toString() ??
            document.id;

    final mainOrderId =
        data['orderId']?.toString() ?? '';

    final sellerId =
        data['sellerId']?.toString() ?? '';

    final customerId =
        data['customerId']?.toString() ?? '';

    final customerName =
        data['customerName']?.toString() ??
            'Customer';

    final status =
        data['orderStatus']?.toString() ??
            'placed';

    final paymentStatus =
        data['paymentStatus']?.toString() ??
            'pending';

    final total =
        _number(data['sellerSubtotal']);

    final items = _items(data);

    final createdAt =
        _formatDate(data['createdAt']);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
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
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Order #$mainOrderId',
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
                    '+ ${items.length - 2} '
                    'more product(s)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

              const Divider(
                height: 24,
              ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seller Total: '
                      '₩${total.toStringAsFixed(0)}',
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

              _returnRefundButton(
                context,
                sellerId: sellerId,
                orderId: mainOrderId,
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showStatusDialog(
                      context,
                      sellerOrderId: sellerOrderId,
                      mainOrderId: mainOrderId,
                      sellerId: sellerId,
                      customerId: customerId,
                      currentStatus: status,
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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Seller Orders',
          ),
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
        title: const Text(
          'Seller Orders',
        ),
        actions: [
          IconButton(
            tooltip: 'Return / Refund',
            onPressed: () {
              _openReturnRefundPage(
                context,
              );
            },
            icon: const Icon(
              Icons.assignment_return_outlined,
            ),
          ),
        ],
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
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
                  'Unable to load seller orders.\n\n'
                  '${snapshot.error}',
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
            final aTime =
                a.data()['createdAt'];

            final bTime =
                b.data()['createdAt'];

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
                      'Orders containing your products '
                      'will appear here.',
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

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(
                context,
                documents[index],
              );
            },
          );
        },
      ),
    );
  }
}
