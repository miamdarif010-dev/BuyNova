import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'cart_page.dart';

class MyStorePage extends StatefulWidget {
  const MyStorePage({super.key});

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =========================================================
  // MONEY FORMAT 
  // =========================================================

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return '৳${value.toInt()}';
    }

    return '৳${value.toStringAsFixed(2)}';
  }

  // =========================================================
  // DOUBLE CONVERTER
  // =========================================================

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
  // ADD RESELLER PRODUCT TO COMMON BUYNOVA CART
  // =========================================================

  Future<void> _addToCart(
    DocumentSnapshot product,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    final data =
        product.data() as Map<String, dynamic>;

    final productName =
        data['productName']?.toString() ??
            data['name']?.toString() ??
            'Product';

    final imageUrl =
        data['imageUrl']?.toString() ?? '';

    final sellingPrice =
        _toDouble(data['sellingPrice']);

    final supplierPrice =
        _toDouble(data['supplierPrice']);

    final sellerId =
        data['sellerId']?.toString() ?? '';

    final entrepreneurUid =
        data['entrepreneurUid']?.toString() ?? '';

    final sourceProductId =
        data['sourceProductId']?.toString() ?? '';

    final active =
        data['active'] == true;

    // ---------------------------------------------------------
    // VALIDATION
    // ---------------------------------------------------------

    if (!active) {
      _showMessage(
        'This product is currently inactive.',
      );
      return;
    }

    if (sellingPrice <= 0) {
      _showMessage(
        'This product has an invalid selling price.',
      );
      return;
    }

    if (supplierPrice <= 0) {
      _showMessage(
        'Supplier price is missing.',
      );
      return;
    }

    if (sellerId.isEmpty) {
      _showMessage(
        'Seller information is missing.',
      );
      return;
    }

    if (entrepreneurUid.isEmpty ||
        entrepreneurUid != user.uid) {
      _showMessage(
        'This reseller product does not belong to your account.',
      );
      return;
    }

    if (sourceProductId.isEmpty) {
      _showMessage(
        'Original product information is missing.',
      );
      return;
    }

    final calculatedProfit =
        sellingPrice - supplierPrice;

    if (calculatedProfit <= 0) {
      _showMessage(
        'Selling price must be higher than supplier price.',
      );
      return;
    }

    try {
      // =======================================================
      // IMPORTANT:
      // CartService.addItem IS STATIC.
      //
      // Quantity is NOT passed here because CartService
      // automatically adds quantity = 1 for a new item and
      // increases the existing quantity by 1.
      //
      // All reseller information is preserved.
      // =======================================================

      await CartService.addItem(
        id: product.id,
        name: productName,
        price: sellingPrice,
        imageUrl: imageUrl.isNotEmpty
            ? imageUrl
            : null,

        // Reseller information
        isResellerProduct: true,
        entrepreneurUid: user.uid,
        sellerId: sellerId,
        supplierProductId: sourceProductId,
        supplierPrice: supplierPrice,
        resellerProfit: calculatedProfit,
      );

      if (!mounted) return;

      _showMessage(
        '$productName added to cart.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not add product to cart: $e',
      );
    }
  }

  // =========================================================
  // SHOW MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // DELETE PRODUCT
  // =========================================================

  Future<void> _deleteProduct(
    DocumentSnapshot product,
  ) async {
    final data =
        product.data() as Map<String, dynamic>;

    final productName =
        data['productName']?.toString() ??
            data['name']?.toString() ??
            'Product';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Product?',
          ),
          content: Text(
            'Remove "$productName" from your store?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Remove',
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
          .collection('reseller_products')
          .doc(product.id)
          .delete();

      if (!mounted) return;

      _showMessage(
        'Product removed from your store.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not remove product: $e',
      );
    }
  }

  // =========================================================
  // TOGGLE PRODUCT STATUS
  // =========================================================

  Future<void> _toggleProductStatus(
    DocumentSnapshot product,
  ) async {
    final data =
        product.data() as Map<String, dynamic>;

    final active =
        data['active'] == true;

    try {
      await _firestore
          .collection('reseller_products')
          .doc(product.id)
          .update({
        'active': !active,
        'status': !active
            ? 'active'
            : 'inactive',
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage(
        !active
            ? 'Product is now active.'
            : 'Product is now inactive.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not update product: $e',
      );
    }
  }

  // =========================================================
  // EDIT SELLING PRICE
  // =========================================================

  Future<void> _editSellingPrice(
    DocumentSnapshot product,
  ) async {
    final data =
        product.data() as Map<String, dynamic>;

    final supplierPrice =
        _toDouble(data['supplierPrice']);

    final currentSellingPrice =
        _toDouble(data['sellingPrice']);

    final productName =
        data['productName']?.toString() ??
            data['name']?.toString() ??
            'Product';

    final controller = TextEditingController(
      text: currentSellingPrice
          .toStringAsFixed(0),
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Edit Selling Price',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Supplier Price: ${_money(supplierPrice)}',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      'Your Selling Price',
                  prefixText: '৳ ',
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () async {
                final price =
                    double.tryParse(
                      controller.text.trim(),
                    ) ??
                    0;

                if (price <= 0) {
                  _showMessage(
                    'Enter a valid price.',
                  );
                  return;
                }

                if (price <= supplierPrice) {
                  _showMessage(
                    'Selling price must be higher than supplier price.',
                  );
                  return;
                }

                try {
                  await _firestore
                      .collection(
                        'reseller_products',
                      )
                      .doc(product.id)
                      .update({
                    'sellingPrice': price,
                    'profit':
                        price - supplierPrice,
                    'updatedAt':
                        FieldValue
                            .serverTimestamp(),
                  });

                  if (!dialogContext
                      .mounted) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                  );

                  if (!mounted) return;

                  _showMessage(
                    'Selling price updated.',
                  );
                } catch (e) {
                  if (!mounted) return;

                  _showMessage(
                    'Could not update price: $e',
                  );
                }
              },
              child: const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  // =========================================================
  // PRODUCT CARD
  // =========================================================

  Widget _productCard(
    DocumentSnapshot product,
  ) {
    final data =
        product.data() as Map<String, dynamic>;

    final productName =
        data['productName']?.toString() ??
            data['name']?.toString() ??
            'Unnamed Product';

    final imageUrl =
        data['imageUrl']?.toString() ?? '';

    final category =
        data['category']?.toString() ??
            'General';

    final sellerCode =
        data['sellerCode']?.toString() ?? '';

    final supplierPrice =
        _toDouble(data['supplierPrice']);

    final sellingPrice =
        _toDouble(data['sellingPrice']);

    final profit =
        _toDouble(data['profit']);

    final active =
        data['active'] == true;

    final salesCount =
        data['salesCount'] is num
            ? (data['salesCount'] as num)
                .toInt()
            : 0;

    final views =
        data['views'] is num
            ? (data['views'] as num).toInt()
            : 0;

    return Card(
      clipBehavior:
          Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // =====================================================
          // IMAGE
          // =====================================================

          Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
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
                            color:
                                Colors.grey.shade200,
                            child:
                                const Center(
                              child: Icon(
                                Icons
                                    .image_not_supported_outlined,
                                size: 42,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color:
                            Colors.grey.shade200,
                        child:
                            const Center(
                          child: Icon(
                            Icons
                                .image_outlined,
                            size: 42,
                          ),
                        ),
                      ),
              ),

              // STATUS
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color: active
                        ? Colors.green
                        : Colors.grey,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    active
                        ? 'ACTIVE'
                        : 'INACTIVE',
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // MENU
              Positioned(
                top: 4,
                right: 4,
                child: PopupMenuButton<String>(
                  onSelected:
                      (value) {
                    if (value ==
                        'price') {
                      _editSellingPrice(
                        product,
                      );
                    } else if (value ==
                        'status') {
                      _toggleProductStatus(
                        product,
                      );
                    } else if (value ==
                        'delete') {
                      _deleteProduct(
                        product,
                      );
                    }
                  },
                  itemBuilder:
                      (context) {
                    return [
                      const PopupMenuItem(
                        value: 'price',
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .edit_rounded,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Edit Price',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(
                              active
                                  ? Icons
                                      .visibility_off_rounded
                                  : Icons
                                      .visibility_rounded,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              active
                                  ? 'Deactivate'
                                  : 'Activate',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .delete_outline_rounded,
                              color:
                                  Colors.red,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Remove',
                              style:
                                  TextStyle(
                                color:
                                    Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ),
            ],
          ),

          // =====================================================
          // DETAILS
          // =====================================================

          Padding(
            padding:
                const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  category,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 9),

                if (sellerCode
                    .isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .storefront_outlined,
                        size: 15,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          sellerCode,
                          style:
                              TextStyle(
                            fontSize:
                                12,
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 10),

                // SUPPLIER PRICE
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      'Supplier',
                      style:
                          TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _money(
                        supplierPrice,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // SELLING PRICE
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      'Selling',
                      style:
                          TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _money(
                        sellingPrice,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // PROFIT
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.green
                        .withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Profit',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      Text(
                        _money(profit),
                        style:
                            const TextStyle(
                          color:
                              Colors.green,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 9),

                // STATS
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Views: $views',
                        style:
                            TextStyle(
                          fontSize: 11,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ),
                    Text(
                      'Sales: $salesCount',
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

                const SizedBox(height: 10),

                // =================================================
                // ADD TO CART
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: FilledButton.icon(
                    onPressed: active
                        ? () {
                            _addToCart(product);
                          }
                        : null,
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 19,
                    ),
                    label: const Text(
                      'Add to Cart',
                    ),
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
  // EMPTY VIEW
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
              Icons.storefront_outlined,
              size: 80,
              color:
                  Colors.grey.shade500,
            ),
            const SizedBox(
              height: 18,
            ),
            const Text(
              'Your Store Is Empty',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Go to Available Products and add products from approved sellers to start your store.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
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
              const Text('My Store'),
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
            const Text('My Store'),
      ),
      body:
          StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(
              'reseller_products',
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
                  'Could not load your store.\n\n${snapshot.error}',
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

          // =====================================================
          // SUMMARY
          // =====================================================

          double totalProfit = 0;
          int activeProducts = 0;

          for (final doc in docs) {
            final data =
                doc.data()
                    as Map<String, dynamic>;

            totalProfit +=
                _toDouble(
              data['profit'],
            );

            if (data['active'] ==
                true) {
              activeProducts++;
            }
          }

          return Column(
            children: [
              // =================================================
              // STORE SUMMARY
              // =================================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        icon: Icons
                            .inventory_2_outlined,
                        title:
                            'Products',
                        value:
                            '${docs.length}',
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: _summaryCard(
                        icon: Icons
                            .check_circle_outline,
                        title:
                            'Active',
                        value:
                            '$activeProducts',
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: _summaryCard(
                        icon: Icons
                            .trending_up_rounded,
                        title:
                            'Profit',
                        value:
                            _money(
                          totalProfit,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // PRODUCT GRID
              // =================================================

              Expanded(
                child:
                    RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child:
                      GridView.builder(
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio:
                          0.50,
                    ),
                    itemCount:
                        docs.length,
                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      return _productCard(
                        docs[index],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(10),
      decoration:
          BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 21,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            title,
            style:
                TextStyle(
              fontSize: 11,
              color: Colors
                  .grey.shade700,
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
