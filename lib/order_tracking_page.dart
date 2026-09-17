import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderTrackingPage extends StatelessWidget {
  final String orderId;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
  });

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
        return 'Order Placed';
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return Icons.receipt_long_outlined;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.inventory_2_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.home_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
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

  int _statusIndex(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return 0;
      case 'confirmed':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return '';
    }

    final date = value.toDate();

    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Widget _buildStep({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool active,
    required bool completed,
    required bool isLast,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: active || completed
                      ? color.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active || completed
                        ? color
                        : Colors.grey.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: active || completed
                      ? color
                      : Colors.grey,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 45,
                  color: completed
                      ? color.withValues(alpha: 0.55)
                      : Colors.grey.withValues(alpha: 0.20),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    active || completed
                        ? FontWeight.bold
                        : FontWeight.w500,
                color:
                    active || completed
                        ? null
                        : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTracking(
    BuildContext context,
    String status,
  ) {
    final normalized =
        status.toLowerCase();

    if (normalized == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cancel_outlined,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Order Cancelled',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This order has been cancelled.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex =
        _statusIndex(normalized);

    final steps = [
      'Order Placed',
      'Confirmed',
      'Processing',
      'Shipped',
      'Delivered',
    ];

    final icons = [
      Icons.receipt_long_outlined,
      Icons.check_circle_outline,
      Icons.inventory_2_outlined,
      Icons.local_shipping_outlined,
      Icons.home_outlined,
    ];

    return Column(
      children: List.generate(
        steps.length,
        (index) {
          final completed =
              index < currentIndex;

          final active =
              index == currentIndex;

          return _buildStep(
            context: context,
            title: steps[index],
            icon: icons[index],
            active: active,
            completed: completed,
            isLast:
                index == steps.length - 1,
            color: Colors.redAccent,
          );
        },
      ),
    );
  }

  Widget _buildSellerOrderCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final sellerCode =
        data['sellerCode']?.toString() ?? '';

    final sellerEmail =
        data['sellerEmail']?.toString() ?? '';

    final status =
        data['orderStatus']?.toString() ?? 'placed';

    final sellerSubtotal =
        (data['sellerSubtotal'] as num?)
                ?.toDouble() ??
            0;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Seller Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status)
                      .withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (sellerCode.isNotEmpty)
            Text(
              'Seller ID: $sellerCode',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

          if (sellerEmail.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(top: 4),
              child: Text(
                'Seller: $sellerEmail',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),

          const SizedBox(height: 14),

          _buildTracking(
            context,
            status,
          ),

          const SizedBox(height: 14),

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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (data['updatedAt'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'Last updated: '
              '${_formatDate(data['updatedAt'])}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Track Order',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
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
                  'Failed to load order.\n\n'
                  '${orderSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!orderSnapshot.hasData ||
              !orderSnapshot.data!.exists) {
            return const Center(
              child: Text(
                'Order not found.',
              ),
            );
          }

          final order =
              orderSnapshot.data!.data() ?? {};

          final mainStatus =
              order['orderStatus']
                      ?.toString() ??
                  'placed';

          final total =
              (order['total'] as num?)
                      ?.toDouble() ??
                  0;

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('seller_orders')
                .where(
                  'orderId',
                  isEqualTo: orderId,
                )
                .snapshots(),
            builder: (
              context,
              sellerSnapshot,
            ) {
              if (sellerSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (sellerSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(20),
                    child: Text(
                      'Failed to load seller orders.\n\n'
                      '${sellerSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final sellerOrders =
                  sellerSnapshot.data?.docs ?? [];

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  30,
                ),
                children: [
                  // Order header
                  Container(
                    padding:
                        const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.redAccent
                              .withValues(
                            alpha: 0.14,
                          ),
                          Colors.redAccent
                              .withValues(
                            alpha: 0.04,
                          ),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping,
                              color:
                                  Colors.redAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Order #$orderId',
                                style:
                                    const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          _statusText(mainStatus),
                          style: TextStyle(
                            color:
                                _statusColor(
                              mainStatus,
                            ),
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Total: '
                          '₩${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        if (order['createdAt'] !=
                            null) ...[
                          const SizedBox(height: 5),
                          Text(
                            'Ordered: '
                            '${_formatDate(
                              order['createdAt'],
                            )}',
                            style:
                                const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Order Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildTracking(
                    context,
                    mainStatus,
                  ),

                  const SizedBox(height: 28),

                  if (sellerOrders.isNotEmpty) ...[
                    const Text(
                      'Seller Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...sellerOrders.map(
                      (doc) => _buildSellerOrderCard(
                        context,
                        doc.data(),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
