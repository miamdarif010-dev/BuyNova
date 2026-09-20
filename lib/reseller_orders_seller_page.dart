import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResellerOrdersSellerPage extends StatelessWidget {
  const ResellerOrdersSellerPage({super.key});

  // =========================================================
  // HELPERS
  // =========================================================

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return '৳${value.toInt()}';
    }
    return '৳${value.toStringAsFixed(2)}';
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  String _formatDate(dynamic value) {
    final date = _date(value);

    if (date == null) {
      return 'Date unavailable';
    }

    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');
    final year =
        date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;

      case 'processing':
        return Colors.orange;

      case 'shipped':
        return Colors.deepPurple;

      case 'delivered':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      case 'returned':
        return Colors.brown;

      case 'refunded':
        return Colors.purple;

      case 'placed':
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    if (status.isEmpty) {
      return 'Placed';
    }

    return status[0].toUpperCase() +
        status.substring(1).toLowerCase();
  }

  // =========================================================
  // ORDER ID
  // =========================================================

  String _orderId(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final resellerOrderId =
        _text(data['resellerOrderId']);

    if (resellerOrderId.isNotEmpty) {
      return resellerOrderId;
    }

    final orderId =
        _text(data['orderId']);

    if (orderId.isNotEmpty) {
      return orderId;
    }

    return doc.id;
  }

  // =========================================================
  // ORDER ITEMS
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
  // SHOW ORDER DETAILS
  // =========================================================

  void _showOrderDetails(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) {
    final data =
        doc.data() as Map<String, dynamic>;

    final orderId =
        _orderId(doc, data);

    final customerName =
        _text(data['customerName']).isNotEmpty
            ? _text(data['customerName'])
            : 'Customer';

    final customerPhone =
        _text(data['customerPhone']).isNotEmpty
            ? _text(data['customerPhone'])
            : _text(data['phone']);

    final customerEmail =
        _text(data['customerEmail']);

    final address =
        _text(data['address']);

    final entrepreneurCode =
        _text(data['entrepreneurCode']);

    final sellingTotal =
        _toDouble(data['sellingTotal']);

    final supplierTotal =
        _toDouble(data['supplierTotal']);

    final profit =
        _toDouble(data['profit']);

    final discount =
        _toDouble(data['discount']);

    final items =
        _items(data);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (
            context,
            scrollController,
          ) {
            return SafeArea(
              child: ListView(
                controller: scrollController,
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  30,
                ),
                children: [
                  Text(
                    'Reseller Order',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    orderId,
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // CUSTOMER
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            customerName,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          if (customerPhone
                              .isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 5,
                              ),
                              child: Text(
                                'Phone: $customerPhone',
                              ),
                            ),

                          if (customerEmail
                              .isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 5,
                              ),
                              child: Text(
                                'Email: $customerEmail',
                              ),
                            ),

                          if (address.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 5,
                              ),
                              child: Text(
                                'Address: $address',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ENTREPRENEUR
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(
                          Icons.business_center,
                        ),
                      ),
                      title: const Text(
                        'Entrepreneur / Reseller',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        entrepreneurCode.isEmpty
                            ? 'Entrepreneur information'
                            : entrepreneurCode,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (items.isEmpty)
                    const Card(
                      elevation: 0,
                      child: Padding(
                        padding:
                            EdgeInsets.all(16),
                        child: Text(
                          'No product details found.',
                        ),
                      ),
                    )
                  else
                    ...items.map(
                      (item) {
                        final name =
                            _text(
                          item['productName'],
                        ).isNotEmpty
                                ? _text(
                                    item[
                                        'productName'],
                                  )
                                : _text(
                                    item['name'],
                                  );

                        final quantity =
                            _toInt(
                          item['quantity'],
                        );

                        final price =
                            _toDouble(
                          item['price'],
                        );

                        final total =
                            _toDouble(
                          item['total'],
                        );

                        return Card(
                          elevation: 0,
                          margin:
                              const EdgeInsets.only(
                            bottom: 8,
                          ),
                          child: ListTile(
                            leading:
                                const CircleAvatar(
                              child: Icon(
                                Icons.inventory_2_outlined,
                              ),
                            ),
                            title: Text(
                              name.isEmpty
                                  ? 'Product'
                                  : name,
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                            subtitle: Text(
                              'Quantity: $quantity\n'
                              'Supplier price: ${_money(price)}',
                            ),
                            trailing: Text(
                              _money(total),
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 14),

                  // FINANCIAL SUMMARY
                  Card(
                    color:
                        Colors.green.shade50,
                    elevation: 0,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _summaryRow(
                            'Selling Total',
                            _money(
                              sellingTotal,
                            ),
                          ),
                          _summaryRow(
                            'Supplier Total',
                            _money(
                              supplierTotal,
                            ),
                          ),
                          _summaryRow(
                            'Discount',
                            _money(
                              discount,
                            ),
                          ),
                          const Divider(),
                          _summaryRow(
                            'Entrepreneur Profit',
                            _money(profit),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Order Date: ${_formatDate(data['createdAt'])}',
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // SUMMARY ROW
  // =========================================================

  Widget _summaryRow(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: bold
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ORDER CARD
  // =========================================================

  Widget _orderCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) {
    final data =
        doc.data() as Map<String, dynamic>;

    final orderId =
        _orderId(doc, data);

    final status =
        _text(data['orderStatus']).isEmpty
            ? 'placed'
            : _text(data['orderStatus']);

    final customerName =
        _text(data['customerName']).isEmpty
            ? 'Customer'
            : _text(data['customerName']);

    final entrepreneurCode =
        _text(data['entrepreneurCode']);

    final sellingTotal =
        _toDouble(data['sellingTotal']);

    final supplierTotal =
        _toDouble(data['supplierTotal']);

    final profit =
        _toDouble(data['profit']);

    final items =
        _items(data);

    int totalQuantity = 0;

    for (final item in items) {
      totalQuantity +=
          _toInt(item['quantity']);
    }

    final color =
        _statusColor(status);

    return Card(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      elevation: 1.5,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    orderId,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color: color.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    _statusText(status),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              _formatDate(
                data['createdAt'],
              ),
              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    customerName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (entrepreneurCode
                .isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 5,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.business_center_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      entrepreneurCode,
                      style:
                          const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 14,
              runSpacing: 5,
              children: [
                Text(
                  'Items: ${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade700,
                  ),
                ),
                Text(
                  'Qty: $totalQuantity',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ],
            ),

            const Divider(
              height: 20,
            ),

            Row(
              children: [
                Expanded(
                  child: _moneyColumn(
                    'Supplier',
                    _money(
                      supplierTotal,
                    ),
                  ),
                ),
                Expanded(
                  child: _moneyColumn(
                    'Customer Paid',
                    _money(
                      sellingTotal,
                    ),
                  ),
                ),
                Expanded(
                  child: _moneyColumn(
                    'Profit',
                    _money(profit),
                    valueColor:
                        Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showOrderDetails(
                    context,
                    doc,
                  );
                },
                icon: const Icon(
                  Icons.visibility_outlined,
                ),
                label: const Text(
                  'View Order Details',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MONEY COLUMN
  // =========================================================

  Widget _moneyColumn(
    String title,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color:
                Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            const Text(
              'No Reseller Orders Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders from BuyNova Entrepreneurs '
              'for your products will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
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
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reseller Orders',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        backgroundColor:
            Colors.redAccent,
        foregroundColor:
            Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reseller_orders')
            .where(
              'sellerId',
              isEqualTo: user.uid,
            )
            .snapshots(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Could not load reseller orders.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _emptyView();
          }

          final sortedDocs =
              [...docs];

          sortedDocs.sort(
            (a, b) {
              final aData =
                  a.data()
                      as Map<String, dynamic>;
              final bData =
                  b.data()
                      as Map<String, dynamic>;

              final aDate =
                  _date(aData['createdAt']);

              final bDate =
                  _date(bData['createdAt']);

              if (aDate == null &&
                  bDate == null) {
                return 0;
              }

              if (aDate == null) {
                return 1;
              }

              if (bDate == null) {
                return -1;
              }

              return bDate.compareTo(aDate);
            },
          );

          return RefreshIndicator(
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection(
                    'reseller_orders',
                  )
                  .where(
                    'sellerId',
                    isEqualTo: user.uid,
                  )
                  .get();
            },
            child: ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.only(
                top: 8,
                bottom: 20,
              ),
              itemCount:
                  sortedDocs.length,
              itemBuilder:
                  (context, index) {
                return _orderCard(
                  context,
                  sortedDocs[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
