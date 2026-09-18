import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerReturnRefundPage extends StatelessWidget {
  const SellerReturnRefundPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _requestStream(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('return_refund_requests')
        .where('sellerId', isEqualTo: uid)
        .snapshots();
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'processing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _notificationTitle(String status, String requestType) {
    final type = requestType == 'refund' ? 'Refund' : 'Return';

    switch (status) {
      case 'approved':
        return '$type Request Approved';
      case 'rejected':
        return '$type Request Rejected';
      case 'processing':
        return '$type Request Processing';
      case 'completed':
        return '$type Request Completed';
      default:
        return '$type Request Updated';
    }
  }

  String _notificationMessage({
    required String status,
    required String requestType,
    required String productName,
    String sellerMessage = '',
  }) {
    final type = requestType == 'refund' ? 'refund' : 'return';

    String message;

    switch (status) {
      case 'approved':
        message =
            'Your $type request for "$productName" has been approved by the seller.';
        break;

      case 'rejected':
        message =
            'Your $type request for "$productName" has been rejected by the seller.';
        break;

      case 'processing':
        message =
            'Your $type request for "$productName" is now being processed.';
        break;

      case 'completed':
        message =
            'Your $type request for "$productName" has been completed.';
        break;

      default:
        message =
            'Your $type request for "$productName" has been updated.';
    }

    if (sellerMessage.trim().isNotEmpty) {
      message += '\n\nSeller message: ${sellerMessage.trim()}';
    }

    return message;
  }

  Future<void> _updateStatus(
    BuildContext context,
    String requestId,
    String status,
    Map<String, dynamic> requestData,
  ) async {
    try {
      final requestRef = FirebaseFirestore.instance
          .collection('return_refund_requests')
          .doc(requestId);

      final data = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'approved') {
        data['approvedAt'] = FieldValue.serverTimestamp();
      }

      if (status == 'rejected') {
        data['rejectedAt'] = FieldValue.serverTimestamp();
      }

      if (status == 'completed') {
        data['completedAt'] = FieldValue.serverTimestamp();
      }

      await requestRef.update(data);

      await _sendBuyerNotification(
        requestData: requestData,
        status: status,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request status changed to ${_statusText(status)}.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update request.\n$e',
          ),
        ),
      );
    }
  }

  Future<void> _sendBuyerNotification({
    required Map<String, dynamic> requestData,
    required String status,
  }) async {
    final customerId =
        requestData['customerId']?.toString() ?? '';

    if (customerId.isEmpty) {
      return;
    }

    final requestType =
        requestData['requestType']?.toString() ?? 'return';

    final productName =
        requestData['productName']?.toString() ?? 'Product';

    final sellerMessage =
        requestData['sellerMessage']?.toString() ?? '';

    final notificationRef = FirebaseFirestore.instance
        .collection('users')
        .doc(customerId)
        .collection('notifications')
        .doc();

    await notificationRef.set({
      'title': _notificationTitle(
        status,
        requestType,
      ),
      'message': _notificationMessage(
        status: status,
        requestType: requestType,
        productName: productName,
        sellerMessage: sellerMessage,
      ),
      'type': 'return_refund',
      'requestId': requestData['requestId']?.toString() ?? '',
      'orderId': requestData['orderId']?.toString() ?? '',
      'sellerOrderId':
          requestData['sellerOrderId']?.toString() ?? '',
      'sellerId': requestData['sellerId']?.toString() ?? '',
      'sellerCode':
          requestData['sellerCode']?.toString() ?? '',
      'productId':
          requestData['productId']?.toString() ?? '',
      'productName': productName,
      'requestType': requestType,
      'requestStatus': status,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateStatusWithMessage(
    BuildContext context,
    String requestId,
    String status,
    Map<String, dynamic> requestData,
    String sellerMessage,
  ) async {
    try {
      final requestRef = FirebaseFirestore.instance
          .collection('return_refund_requests')
          .doc(requestId);

      final data = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (sellerMessage.trim().isNotEmpty) {
        data['sellerMessage'] = sellerMessage.trim();
        data['sellerNote'] = sellerMessage.trim();
      }

      if (status == 'approved') {
        data['approvedAt'] = FieldValue.serverTimestamp();
      }

      if (status == 'rejected') {
        data['rejectedAt'] = FieldValue.serverTimestamp();
      }

      if (status == 'completed') {
        data['completedAt'] = FieldValue.serverTimestamp();
      }

      await requestRef.update(data);

      final notificationData =
          Map<String, dynamic>.from(requestData);

      notificationData['requestId'] = requestId;
      notificationData['sellerMessage'] =
          sellerMessage.trim();

      await _sendBuyerNotification(
        requestData: notificationData,
        status: status,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request ${_statusText(status).toLowerCase()} successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update request.\n$e',
          ),
        ),
      );
    }
  }

  Future<void> _showSellerMessageDialog(
    BuildContext context,
    String requestId,
    String status,
    Map<String, dynamic> requestData,
  ) async {
    final controller = TextEditingController();

    final existingMessage =
        requestData['sellerMessage']?.toString() ?? '';

    controller.text = existingMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            status == 'rejected'
                ? 'Reject Request'
                : 'Update Request',
          ),
          content: TextField(
            controller: controller,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Seller Message',
              hintText: 'Write a message for the customer...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _updateStatusWithMessage(
                  context,
                  requestId,
                  status,
                  requestData,
                  controller.text,
                );
              },
              child: Text(
                _statusText(status),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  void _showStatusMenu(
    BuildContext context,
    String requestId,
    String currentStatus,
    Map<String, dynamic> requestData,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final statuses = [
          'pending',
          'approved',
          'processing',
          'rejected',
          'completed',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Update Request Status',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...statuses.map(
                  (status) {
                    final selected = status == currentStatus;

                    return ListTile(
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? Colors.redAccent
                            : Colors.grey,
                      ),
                      title: Text(
                        _statusText(status),
                      ),
                      onTap: () async {
                        Navigator.pop(sheetContext);

                        if (status == currentStatus) {
                          return;
                        }

                        if (status == 'approved' ||
                            status == 'rejected') {
                          await _showSellerMessageDialog(
                            context,
                            requestId,
                            status,
                            requestData,
                          );
                        } else {
                          await _updateStatus(
                            context,
                            requestId,
                            status,
                            requestData,
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _productImage(String url) {
    if (url.isEmpty) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 70,
            height: 70,
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.broken_image_outlined,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Widget _requestCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final requestType =
        data['requestType']?.toString() ?? 'return';

    final status =
        data['status']?.toString() ?? 'pending';

    final productName =
        data['productName']?.toString() ?? 'Product';

    final productImage =
        data['productImageUrl']?.toString() ?? '';

    final customerName =
        data['customerName']?.toString() ?? '';

    final customerEmail =
        data['customerEmail']?.toString() ?? '';

    final reason =
        data['reason']?.toString() ?? '';

    final details =
        data['details']?.toString() ?? '';

    final sellerMessage =
        data['sellerMessage']?.toString() ?? '';

    final quantity =
        (data['quantity'] as num?)?.toInt() ?? 1;

    final price =
        (data['price'] as num?)?.toDouble() ?? 0;

    final orderId =
        data['orderId']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  requestType == 'refund'
                      ? Icons.currency_exchange
                      : Icons.assignment_return_outlined,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    requestType == 'refund'
                        ? 'Refund Request'
                        : 'Return Request',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _statusBadge(status),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _productImage(productImage),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('Quantity: $quantity'),
                      const SizedBox(height: 3),
                      Text(
                        'Price: ₩${price.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            Text(
              'Customer',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              customerName.isEmpty
                  ? 'Customer'
                  : customerName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            if (customerEmail.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(customerEmail),
            ],

            const SizedBox(height: 14),

            Text(
              'Order ID',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              orderId.isEmpty ? 'N/A' : orderId,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'Reason',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              reason.isEmpty ? 'Not provided' : reason,
            ),

            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(details),
            ],

            if (sellerMessage.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seller Message',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(sellerMessage),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showStatusMenu(
                    context,
                    doc.id,
                    status,
                    data,
                  );
                },
                icon: const Icon(
                  Icons.sync,
                ),
                label: const Text(
                  'Update Status',
                ),
              ),
            ),
          ],
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
          title: const Text(
            'Return & Refund Requests',
          ),
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
        title: const Text(
          'Return & Refund Requests',
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _requestStream(user.uid),
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
                  'Could not load requests.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final requests =
              snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_return_outlined,
                      size: 70,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Return or Refund Requests',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customer requests for your products will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent,
                      Colors.red.shade700,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_return_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Requests',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${requests.length} request${requests.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ...requests.map(
                (doc) => _requestCard(
                  context,
                  doc,
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
