import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResellerOrdersPage extends StatefulWidget {
  const ResellerOrdersPage({super.key});

  @override
  State<ResellerOrdersPage> createState() =>
      _ResellerOrdersPageState();
}

class _ResellerOrdersPageState
    extends State<ResellerOrdersPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =========================================================
  // MONEY
  // =========================================================

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return '৳${value.toInt()}';
    }

    return '৳${value.toStringAsFixed(2)}';
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // STATUS COLOR
  // =========================================================

  Color _statusColor(String status) {
    switch (status) {
      case 'placed':
        return Colors.orange;

      case 'confirmed':
        return Colors.blue;

      case 'processing':
        return Colors.indigo;

      case 'shipped':
        return Colors.deepPurple;

      case 'delivered':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      case 'returned':
        return Colors.brown;

      case 'refunded':
        return Colors.teal;

      default:
        return Colors.grey;
    }
  }

  // =========================================================
  // STATUS TEXT
  // =========================================================

  String _statusText(String status) {
    switch (status) {
      case 'placed':
        return 'Placed';

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

      case 'returned':
        return 'Returned';

      case 'refunded':
        return 'Refunded';

      default:
        return status.isEmpty
            ? 'Unknown'
            : status[0].toUpperCase() +
                status.substring(1);
    }
  }

  // =========================================================
  // DATE
  // =========================================================

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

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

      return '$day/$month/$year $hour:$minute';
    }

    return 'Recently';
  }

  // =========================================================
  // UPDATE STATUS
  // =========================================================

  Future<void> _updateOrderStatus(
    DocumentSnapshot order,
    String newStatus,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final data =
        order.data() as Map<String, dynamic>;

    final currentStatus =
        data['orderStatus']?.toString() ?? 'placed';

    if (currentStatus == 'cancelled' ||
        currentStatus == 'returned' ||
        currentStatus == 'refunded' ||
        currentStatus == 'delivered') {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This order can no longer be changed.',
          ),
        ),
      );

      return;
    }

    try {
      await _firestore
          .collection('reseller_orders')
          .doc(order.id)
          .update({
        'orderStatus': newStatus,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order status changed to ${_statusText(newStatus)}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update order: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // STATUS DIALOG
  // =========================================================

  Future<void> _showStatusDialog(
    DocumentSnapshot order,
  ) async {
    final data =
        order.data() as Map<String, dynamic>;

    final currentStatus =
        data['orderStatus']?.toString() ?? 'placed';

    final availableStatuses = <String>[
      'placed',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Update Order Status',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableStatuses.map(
              (status) {
                final selected =
                    status == currentStatus;

                return ListTile(
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _statusColor(status),
                  ),
                  title: Text(
                    _statusText(status),
                  ),
                  onTap: () {
                    Navigator.pop(
                      dialogContext,
                    );

                    if (status != currentStatus) {
                      _updateOrderStatus(
                        order,
                        status,
                      );
                    }
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
  // ORDER ITEMS
  // =========================================================

  Widget _orderItems(
    List<dynamic> items,
  ) {
    if (items.isEmpty) {
      return const Text(
        'No product information available.',
      );
    }

    return Column(
      children: items.map(
        (item) {
          if (item is! Map) {
            return const SizedBox();
          }

          final name =
              item['productName']?.toString() ??
                  item['name']?.toString() ??
                  'Product';

          final quantity =
              item['quantity'] is num
                  ? (item['quantity'] as num).toInt()
                  : 1;

          final price =
              _toDouble(
            item['price'],
          );

          final total =
              _toDouble(
            item['total'],
          );

          final imageUrl =
              item['imageUrl']?.toString() ?? '';

          return Container(
            margin:
                const EdgeInsets.only(
              bottom: 10,
            ),
            padding:
                const EdgeInsets.all(10),
            decoration:
                BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // IMAGE
                SizedBox(
                  width: 58,
                  height: 58,
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return Container(
                                color: Colors
                                    .grey
                                    .shade200,
                                child:
                                    const Icon(
                                  Icons
                                      .image_not_supported_outlined,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors
                                .grey
                                .shade200,
                            child:
                                const Icon(
                              Icons
                                  .image_outlined,
                            ),
                          ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                // NAME
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
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Qty: $quantity',
                        style:
                            TextStyle(
                          fontSize: 12,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        '${_money(price)} × $quantity',
                        style:
                            TextStyle(
                          fontSize: 12,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Text(
                  _money(
                    total > 0
                        ? total
                        : price *
                            quantity,
                  ),
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  // =========================================================
  // ORDER DETAILS
  // =========================================================

  Future<void> _showOrderDetails(
    DocumentSnapshot order,
  ) async {
    final data =
        order.data() as Map<String, dynamic>;

    final items =
        data['items'] is List
            ? List<dynamic>.from(
                data['items'],
              )
            : <dynamic>[];

    final customerName =
        data['customerName']?.toString() ??
            'Customer';

    final phone =
        data['phone']?.toString() ?? '';

    final address =
        data['address']?.toString() ??
            '';

    final orderId =
        data['orderId']?.toString() ??
            order.id;

    final entrepreneurCode =
        data['entrepreneurCode']
                ?.toString() ??
            '';

    final sellerCode =
        data['sellerCode']?.toString() ??
            '';

    final sellerId =
        data['sellerId']?.toString() ??
            '';

    final status =
        data['orderStatus']?.toString() ??
            'placed';

    final sellingTotal =
        _toDouble(
      data['sellingTotal'] ??
          data['total'],
    );

    final supplierTotal =
        _toDouble(
      data['supplierTotal'],
    );

    final profit =
        _toDouble(
      data['profit'],
    );

    final createdAt =
        _formatDate(
      data['createdAt'],
    );

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Details',
                    style:
                        TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ORDER ID
                  _detailRow(
                    'Order ID',
                    orderId,
                  ),

                  _detailRow(
                    'Date',
                    createdAt,
                  ),

                  _detailRow(
                    'Customer',
                    customerName,
                  ),

                  if (phone.isNotEmpty)
                    _detailRow(
                      'Phone',
                      phone,
                    ),

                  if (address.isNotEmpty)
                    _detailRow(
                      'Address',
                      address,
                    ),

                  if (entrepreneurCode
                      .isNotEmpty)
                    _detailRow(
                      'Entrepreneur',
                      entrepreneurCode,
                    ),

                  if (sellerCode
                      .isNotEmpty)
                    _detailRow(
                      'Seller',
                      sellerCode,
                    ),

                  if (sellerId
                      .isNotEmpty)
                    _detailRow(
                      'Seller ID',
                      sellerId,
                    ),

                  const SizedBox(
                    height: 10,
                  ),

                  // STATUS
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              _statusColor(
                            status,
                          ).withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Text(
                          _statusText(
                            status,
                          ),
                          style:
                              TextStyle(
                            color:
                                _statusColor(
                              status,
                            ),
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Products',
                    style:
                        TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _orderItems(items),

                  const SizedBox(
                    height: 10,
                  ),

                  // MONEY SUMMARY
                  if (supplierTotal >
                      0)
                    _moneyRow(
                      'Supplier Cost',
                      supplierTotal,
                    ),

                  _moneyRow(
                    'Customer Total',
                    sellingTotal,
                  ),

                  if (profit > 0)
                    _moneyRow(
                      'Expected Profit',
                      profit,
                      profitStyle:
                          true,
                    ),

                  const SizedBox(
                    height: 15,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          () {
                        Navigator.pop(
                          sheetContext,
                        );

                        _showStatusDialog(
                          order,
                        );
                      },
                      icon: const Icon(
                        Icons
                            .sync_alt_rounded,
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
      },
    );
  }

  // =========================================================
  // DETAIL ROW
  // =========================================================

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style:
                  TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MONEY ROW
  // =========================================================

  Widget _moneyRow(
    String title,
    double value, {
    bool profitStyle = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          Text(
            _money(value),
            style:
                TextStyle(
              fontWeight:
                  FontWeight.bold,
              color: profitStyle
                  ? Colors.green
                  : null,
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
    DocumentSnapshot order,
  ) {
    final data =
        order.data() as Map<String, dynamic>;

    final orderId =
        data['orderId']?.toString() ??
            order.id;

    final customerName =
        data['customerName']?.toString() ??
            'Customer';

    final phone =
        data['phone']?.toString() ?? '';

    final status =
        data['orderStatus']?.toString() ??
            'placed';

    final items =
        data['items'] is List
            ? List<dynamic>.from(
                data['items'],
              )
            : <dynamic>[];

    final sellingTotal =
        _toDouble(
      data['sellingTotal'] ??
          data['total'],
    );

    final supplierTotal =
        _toDouble(
      data['supplierTotal'],
    );

    final profit =
        _toDouble(
      data['profit'],
    );

    final date =
        _formatDate(
      data['createdAt'],
    );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 1.5,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        onTap: () {
          _showOrderDetails(
            order,
          );
        },
        child: Padding(
          padding:
              const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // TOP
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Order #$orderId',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          date,
                          style:
                              TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          _statusColor(
                        status,
                      ).withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                    child: Text(
                      _statusText(
                        status,
                      ),
                      style:
                          TextStyle(
                        color:
                            _statusColor(
                          status,
                        ),
                        fontSize: 11,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(
                height: 22,
              ),

              // CUSTOMER
              Row(
                children: [
                  const Icon(
                    Icons
                        .person_outline_rounded,
                    size: 19,
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Expanded(
                    child: Text(
                      customerName,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              if (phone.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 5,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .phone_outlined,
                        size: 17,
                      ),
                      const SizedBox(
                        width: 7,
                      ),
                      Text(
                        phone,
                        style:
                            TextStyle(
                          fontSize: 12,
                          color: Colors
                              .grey
                              .shade700,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(
                height: 10,
              ),

              // ITEMS
              Row(
                children: [
                  const Icon(
                    Icons
                        .inventory_2_outlined,
                    size: 18,
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Text(
                    '${items.length} product${items.length == 1 ? '' : 's'}',
                    style:
                        TextStyle(
                      fontSize: 12,
                      color: Colors
                          .grey
                          .shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              // TOTALS
              Row(
                children: [
                  Expanded(
                    child:
                        _miniMoney(
                      'Customer',
                      sellingTotal,
                    ),
                  ),
                  Expanded(
                    child:
                        _miniMoney(
                      'Supplier',
                      supplierTotal,
                    ),
                  ),
                  Expanded(
                    child:
                        _miniMoney(
                      'Profit',
                      profit,
                      green: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              // BUTTON
              SizedBox(
                width:
                    double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed: () {
                    _showOrderDetails(
                      order,
                    );
                  },
                  icon: const Icon(
                    Icons
                        .visibility_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'View Order',
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
  // MINI MONEY
  // =========================================================

  Widget _miniMoney(
    String title,
    double value, {
    bool green = false,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              TextStyle(
            fontSize: 10,
            color:
                Colors.grey.shade600,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          _money(value),
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.bold,
            color: green
                ? Colors.green
                : null,
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
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .shopping_bag_outlined,
              size: 80,
              color:
                  Colors.grey.shade500,
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'No Reseller Orders Yet',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Orders placed through your reseller store will appear here.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.grey.shade600,
                height: 1.5,
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
  Widget build(
    BuildContext context,
  ) {
    final user =
        _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text(
            'Reseller Orders',
          ),
        ),
        body:
            const Center(
          child: Text(
            'Please login first.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Reseller Orders',
        ),
      ),
      body:
          StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(
              'reseller_orders',
            )
            .where(
              'entrepreneurUid',
              isEqualTo: user.uid,
            )
            .snapshots(),
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child: Text(
                  'Could not load reseller orders.\n\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data?.docs ??
                  [];

          if (docs.isEmpty) {
            return _emptyView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(
                12,
              ),
              physics:
                  const AlwaysScrollableScrollPhysics(),
              itemCount:
                  docs.length,
              itemBuilder:
                  (
                context,
                index,
              ) {
                return _orderCard(
                  docs[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
