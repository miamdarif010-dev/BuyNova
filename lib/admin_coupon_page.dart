import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCouponPage extends StatefulWidget {
  const AdminCouponPage({super.key});

  @override
  State<AdminCouponPage> createState() =>
      _AdminCouponPageState();
}

class _AdminCouponPageState extends State<AdminCouponPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // CREATE / EDIT COUPON
  // =========================================================

  Future<void> _showCouponForm({
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    final data = document?.data();

    final codeController = TextEditingController(
      text: data?['code']?.toString() ?? '',
    );

    final discountController = TextEditingController(
      text: data?['discountValue']?.toString() ?? '',
    );

    final minimumController = TextEditingController(
      text: data?['minimumOrder']?.toString() ?? '0',
    );

    final maximumController = TextEditingController(
      text: data?['maximumDiscount']?.toString() ?? '0',
    );

    String discountType =
        data?['discountType']?.toString() ?? 'percentage';

    bool isActive =
        data?['isActive'] != false;

    DateTime expiryDate;

    final existingExpiry =
        data?['expiresAt'];

    if (existingExpiry is Timestamp) {
      expiryDate =
          existingExpiry.toDate();
    } else {
      expiryDate =
          DateTime.now().add(
        const Duration(days: 30),
      );
    }

    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            Future<void> selectExpiryDate() async {
              final selected =
                  await showDatePicker(
                context: context,
                initialDate: expiryDate.isBefore(
                  DateTime.now(),
                )
                    ? DateTime.now()
                    : expiryDate,
                firstDate:
                    DateTime.now(),
                lastDate:
                    DateTime.now().add(
                  const Duration(
                    days: 3650,
                  ),
                ),
              );

              if (selected == null) {
                return;
              }

              setDialogState(() {
                expiryDate = DateTime(
                  selected.year,
                  selected.month,
                  selected.day,
                  23,
                  59,
                  59,
                );
              });
            }

            Future<void> saveCoupon() async {
              final code =
                  codeController.text
                      .trim()
                      .toUpperCase();

              final discount =
                  double.tryParse(
                    discountController
                        .text
                        .trim(),
                  );

              final minimumOrder =
                  double.tryParse(
                    minimumController
                        .text
                        .trim(),
                  );

              final maximumDiscount =
                  double.tryParse(
                    maximumController
                        .text
                        .trim(),
                  );

              if (code.isEmpty) {
                setDialogState(() {
                  errorMessage =
                      'Please enter a coupon code.';
                });
                return;
              }

              if (discount == null ||
                  discount <= 0) {
                setDialogState(() {
                  errorMessage =
                      'Please enter a valid discount.';
                });
                return;
              }

              if (discountType ==
                      'percentage' &&
                  discount > 100) {
                setDialogState(() {
                  errorMessage =
                      'Percentage discount cannot exceed 100%.';
                });
                return;
              }

              if (minimumOrder == null ||
                  minimumOrder < 0) {
                setDialogState(() {
                  errorMessage =
                      'Please enter a valid minimum order.';
                });
                return;
              }

              if (maximumDiscount == null ||
                  maximumDiscount < 0) {
                setDialogState(() {
                  errorMessage =
                      'Please enter a valid maximum discount.';
                });
                return;
              }

              if (expiryDate.isBefore(
                DateTime.now(),
              )) {
                setDialogState(() {
                  errorMessage =
                      'Expiry date must be in the future.';
                });
                return;
              }

              try {
                // =================================================
                // DUPLICATE CODE CHECK
                // =================================================

                final duplicateSnapshot =
                    await _firestore
                        .collection('coupons')
                        .where(
                          'code',
                          isEqualTo: code,
                        )
                        .limit(5)
                        .get();

                for (final duplicate
                    in duplicateSnapshot.docs) {
                  if (document == null ||
                      duplicate.id !=
                          document.id) {
                    if (!mounted) return;

                    setDialogState(() {
                      errorMessage =
                          'This coupon code already exists.';
                    });

                    return;
                  }
                }

                final couponData = {
                  'code': code,
                  'discountType':
                      discountType,
                  'discountValue':
                      discount,
                  'minimumOrder':
                      minimumOrder,
                  'maximumDiscount':
                      maximumDiscount,
                  'isActive':
                      isActive,
                  'expiresAt':
                      Timestamp.fromDate(
                    expiryDate,
                  ),
                  'updatedAt':
                      FieldValue.serverTimestamp(),
                };

                if (document == null) {
                  couponData['createdAt'] =
                      FieldValue.serverTimestamp();

                  await _firestore
                      .collection('coupons')
                      .add(couponData);
                } else {
                  await _firestore
                      .collection('coupons')
                      .doc(document.id)
                      .update(
                    couponData,
                  );
                }

                if (!mounted) return;

                Navigator.pop(
                  dialogContext,
                );

                _showMessage(
                  document == null
                      ? 'Coupon created successfully.'
                      : 'Coupon updated successfully.',
                );
              } catch (e) {
                setDialogState(() {
                  errorMessage =
                      'Could not save coupon.';
                });
              }
            }

            return AlertDialog(
              title: Text(
                document == null
                    ? 'Create Coupon'
                    : 'Edit Coupon',
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (errorMessage != null) ...[
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets.all(
                            10,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.red
                                .withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: Text(
                            errorMessage!,
                            style:
                                const TextStyle(
                              color:
                                  Colors.red,
                              fontSize:
                                  13,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                      ],

                      TextField(
                        controller:
                            codeController,
                        textCapitalization:
                            TextCapitalization
                                .characters,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Coupon Code',
                          hintText:
                              'Example: WELCOME10',
                          prefixIcon:
                              const Icon(
                            Icons
                                .confirmation_number_outlined,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      DropdownButtonFormField<String>(
                        initialValue:
                            discountType,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Discount Type',
                          prefixIcon:
                              const Icon(
                            Icons
                                .discount_outlined,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value:
                                'percentage',
                            child: Text(
                              'Percentage (%)',
                            ),
                          ),
                          DropdownMenuItem(
                            value:
                                'fixed',
                            child: Text(
                              'Fixed Amount (₩)',
                            ),
                          ),
                        ],
                        onChanged:
                            (value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            discountType =
                                value;
                          });
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextField(
                        controller:
                            discountController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              discountType ==
                                      'percentage'
                                  ? 'Discount Percentage'
                                  : 'Discount Amount',
                          prefixIcon:
                              const Icon(
                            Icons
                                .price_check_outlined,
                          ),
                          suffixText:
                              discountType ==
                                      'percentage'
                                  ? '%'
                                  : '₩',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextField(
                        controller:
                            minimumController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Minimum Order',
                          prefixIcon:
                              const Icon(
                            Icons
                                .shopping_cart_outlined,
                          ),
                          suffixText:
                              '₩',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextField(
                        controller:
                            maximumController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Maximum Discount',
                          hintText:
                              '0 = No limit',
                          prefixIcon:
                              const Icon(
                            Icons
                                .vertical_align_bottom_outlined,
                          ),
                          suffixText:
                              '₩',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        onTap:
                            selectExpiryDate,
                        child:
                            InputDecorator(
                          decoration:
                              InputDecoration(
                            labelText:
                                'Expiry Date',
                            prefixIcon:
                                const Icon(
                              Icons
                                  .event_outlined,
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                          ),
                          child: Text(
                            '${expiryDate.day.toString().padLeft(2, '0')}/'
                            '${expiryDate.month.toString().padLeft(2, '0')}/'
                            '${expiryDate.year}',
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      SwitchListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title:
                            const Text(
                          'Coupon Active',
                        ),
                        subtitle:
                            const Text(
                          'Customers can use this coupon when active.',
                        ),
                        value:
                            isActive,
                        activeThumbColor:
                            Colors.redAccent,
                        onChanged:
                            (value) {
                          setDialogState(() {
                            isActive =
                                value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text(
                    'Cancel',
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      saveCoupon,
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors.redAccent,
                    foregroundColor:
                        Colors.white,
                  ),
                  child:
                      Text(
                    document == null
                        ? 'Create'
                        : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();
    discountController.dispose();
    minimumController.dispose();
    maximumController.dispose();
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> _deleteCoupon(
    DocumentSnapshot<Map<String, dynamic>>
        document,
  ) async {
    final data =
        document.data();

    final code =
        data?['code']?.toString() ?? '';

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Delete Coupon?',
          ),
          content: Text(
            'Are you sure you want to delete "$code"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _firestore
          .collection('coupons')
          .doc(document.id)
          .delete();

      if (!mounted) return;

      _showMessage(
        'Coupon deleted.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Could not delete coupon.',
      );
    }
  }

  // =========================================================
  // TOGGLE ACTIVE
  // =========================================================

  Future<void> _toggleCoupon(
    DocumentSnapshot<Map<String, dynamic>>
        document,
  ) async {
    final data =
        document.data();

    final current =
        data?['isActive'] == true;

    try {
      await _firestore
          .collection('coupons')
          .doc(document.id)
          .update({
        'isActive':
            !current,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage(
        current
            ? 'Coupon deactivated.'
            : 'Coupon activated.',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Could not update coupon.',
      );
    }
  }

  // =========================================================
  // DISCOUNT TEXT
  // =========================================================

  String _discountText(
    Map<String, dynamic> data,
  ) {
    final type =
        data['discountType']
                ?.toString()
                .toLowerCase() ??
            'fixed';

    final value =
        _toDouble(
      data['discountValue'],
    );

    if (type == 'percentage') {
      return '${value.toStringAsFixed(0)}% OFF';
    }

    return '₩${value.toStringAsFixed(0)} OFF';
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
  // DATE
  // =========================================================

  String _formatDate(
    dynamic value,
  ) {
    if (value is! Timestamp) {
      return 'No expiry';
    }

    final date =
        value.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // COUPON CARD
  // =========================================================

  Widget _couponCard(
    DocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final data =
        document.data() ?? {};

    final code =
        data['code']?.toString() ?? '';

    final isActive =
        data['isActive'] == true;

    final minimum =
        _toDouble(
      data['minimumOrder'],
    );

    final maximum =
        _toDouble(
      data['maximumDiscount'],
    );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration:
                      BoxDecoration(
                    color: Colors.redAccent
                        .withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                  child:
                      const Icon(
                    Icons
                        .local_offer_outlined,
                    color:
                        Colors.redAccent,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        code,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        _discountText(
                          data,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.redAccent,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected:
                      (value) {
                    if (value ==
                        'edit') {
                      _showCouponForm(
                        document:
                            document,
                      );
                    } else if (value ==
                        'toggle') {
                      _toggleCoupon(
                        document,
                      );
                    } else if (value ==
                        'delete') {
                      _deleteCoupon(
                        document,
                      );
                    }
                  },
                  itemBuilder:
                      (context) => [
                    const PopupMenuItem(
                      value:
                          'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .edit_outlined,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(
                            'Edit',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value:
                          'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isActive
                                ? Icons
                                    .pause_circle_outline
                                : Icons
                                    .play_circle_outline,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            isActive
                                ? 'Deactivate'
                                : 'Activate',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value:
                          'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete_outline,
                            color:
                                Colors.red,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(
                            'Delete',
                            style:
                                TextStyle(
                              color:
                                  Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            Row(
              children: [
                _smallInfo(
                  'Minimum',
                  '₩${minimum.toStringAsFixed(0)}',
                ),
                const SizedBox(
                  width: 20,
                ),
                _smallInfo(
                  'Max Discount',
                  maximum <= 0
                      ? 'No limit'
                      : '₩${maximum.toStringAsFixed(0)}',
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color: isActive
                        ? Colors.green
                            .withValues(
                            alpha: 0.10,
                          )
                        : Colors.red
                            .withValues(
                            alpha: 0.10,
                          ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child:
                      Text(
                    isActive
                        ? 'ACTIVE'
                        : 'INACTIVE',
                    style:
                        TextStyle(
                      color: isActive
                          ? Colors.green
                          : Colors.red,
                      fontSize:
                          11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                const Icon(
                  Icons
                      .event_outlined,
                  size: 18,
                  color:
                      Colors.grey,
                ),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  'Expires: ${_formatDate(data['expiresAt'])}',
                  style:
                      TextStyle(
                    color: Colors
                        .grey
                        .shade700,
                    fontSize:
                        13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallInfo(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              TextStyle(
            color:
                Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        Text(
          value,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.redAccent,
        foregroundColor:
            Colors.white,
        title:
            const Text(
          'Coupon Management',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            () => _showCouponForm(),
        backgroundColor:
            Colors.redAccent,
        foregroundColor:
            Colors.white,
        icon:
            const Icon(
          Icons.add,
        ),
        label:
            const Text(
          'Create Coupon',
        ),
      ),

      body:
          StreamBuilder<
              QuerySnapshot<
                  Map<String,
                      dynamic>>>(
        stream:
            _firestore
                .collection(
                  'coupons',
                )
                .snapshots(),

        builder:
            (context, snapshot) {
          if (snapshot
                  .connectionState ==
              ConnectionState
                  .waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Colors.redAccent,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons
                          .error_outline,
                      size: 50,
                      color:
                          Colors.grey,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    const Text(
                      'Could not load coupons.',
                      textAlign:
                          TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final documents =
              snapshot.data?.docs ??
                  [];

          if (documents.isEmpty) {
            return Center(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  24,
                ),
                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .local_offer_outlined,
                      size: 65,
                      color: Colors
                          .grey
                          .shade400,
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    const Text(
                      'No coupons created yet.',
                      style:
                          TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      'Tap "Create Coupon" to create your first promotion.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final sorted =
              [...documents];

          sorted.sort(
            (a, b) {
              final aData =
                  a.data();

              final bData =
                  b.data();

              final aActive =
                  aData['isActive'] ==
                      true;

              final bActive =
                  bData['isActive'] ==
                      true;

              if (aActive &&
                  !bActive) {
                return -1;
              }

              if (!aActive &&
                  bActive) {
                return 1;
              }

              return 0;
            },
          );

          return ListView(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            children: [
              Row(
                children: [
                  const Icon(
                    Icons
                        .local_offer_outlined,
                    color:
                        Colors.redAccent,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Text(
                    '${documents.length} Coupon${documents.length == 1 ? '' : 's'}',
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              ...sorted.map(
                (document) =>
                    _couponCard(
                  document,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
