import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'checkout_page.dart';
import 'login_page.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;

  // =========================================================
  // RESELLER / ENTREPRENEUR DATA
  // =========================================================

  final bool isResellerProduct;
  final String? entrepreneurUid;
  final String? sellerId;
  final String? supplierProductId;
  final double? supplierPrice;
  final double? resellerProfit;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,

    this.isResellerProduct = false,
    this.entrepreneurUid,
    this.sellerId,
    this.supplierProductId,
    this.supplierPrice,
    this.resellerProfit,
  });

  double get total => price * quantity;

  // =========================================================
  // SUPPLIER TOTAL
  // =========================================================

  double get supplierTotal =>
      (supplierPrice ?? 0) * quantity;

  // =========================================================
  // PROFIT TOTAL
  // =========================================================

  double get profitTotal {
    if (resellerProfit != null) {
      return resellerProfit! * quantity;
    }

    if (supplierPrice != null) {
      return (price - supplierPrice!) * quantity;
    }

    return 0;
  }
}

// =============================================================
// CART SERVICE
// =============================================================

class CartService {
  // BuyNova Bangladesh currency
  static const double deliveryFeeAmount = 3000;

  static CollectionReference<Map<String, dynamic>>
      _cartReference(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart');
  }

  // ===========================================================
  // ADD ITEM
  // ===========================================================

  static Future<void> addItem({
    required String id,
    required String name,
    required double price,
    String? imageUrl,

    // =========================================================
    // OPTIONAL RESELLER DATA
    // =========================================================

    bool isResellerProduct = false,
    String? entrepreneurUid,
    String? sellerId,
    String? supplierProductId,
    double? supplierPrice,
    double? resellerProfit,
  }) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final cartRef =
        _cartReference(user.uid);

    final itemRef =
        cartRef.doc(id);

    final existing =
        await itemRef.get();

    if (existing.exists) {
      final data =
          existing.data() ?? {};

      final oldQuantity =
          (data['quantity'] as num?)
                  ?.toInt() ??
              1;

      await itemRef.update({
        'name': name,
        'price': price,
        'imageUrl': imageUrl ?? '',
        'quantity': oldQuantity + 1,

        // Keep/update reseller information
        'isResellerProduct':
            isResellerProduct,
        'entrepreneurUid':
            entrepreneurUid ?? '',
        'sellerId':
            sellerId ?? '',
        'supplierProductId':
            supplierProductId ?? id,
        'supplierPrice':
            supplierPrice,
        'resellerProfit':
            resellerProfit,
      });
    } else {
      await itemRef.set({
        'productId': id,
        'name': name,
        'price': price,
        'imageUrl': imageUrl ?? '',
        'quantity': 1,
        'addedAt':
            FieldValue.serverTimestamp(),

        // =====================================================
        // RESELLER INFORMATION
        // =====================================================

        'isResellerProduct':
            isResellerProduct,
        'entrepreneurUid':
            entrepreneurUid ?? '',
        'sellerId':
            sellerId ?? '',
        'supplierProductId':
            supplierProductId ?? id,
        'supplierPrice':
            supplierPrice,
        'resellerProfit':
            resellerProfit,
      });
    }
  }

  // ===========================================================
  // REMOVE ITEM
  // ===========================================================

  static Future<void> removeItem(
    String id,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    await _cartReference(user.uid)
        .doc(id)
        .delete();
  }

  // ===========================================================
  // UPDATE QUANTITY
  // ===========================================================

  static Future<void> updateQuantity(
    String id,
    int quantity,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final itemRef =
        _cartReference(user.uid)
            .doc(id);

    if (quantity <= 0) {
      await itemRef.delete();
      return;
    }

    await itemRef.update({
      'quantity': quantity,
    });
  }

  // ===========================================================
  // CLEAR CART
  // ===========================================================

  static Future<void> clearCart() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final snapshot =
        await _cartReference(user.uid)
            .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch =
        FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

// =============================================================
// CART PAGE
// =============================================================

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
  });

  @override
  State<CartPage> createState() =>
      _CartPageState();
}

class _CartPageState
    extends State<CartPage> {
  // ===========================================================
  // CHANGE QUANTITY
  // ===========================================================

  Future<void> _changeQuantity(
    String id,
    int currentQuantity,
    int change,
  ) async {
    final newQuantity =
        currentQuantity + change;

    try {
      await CartService.updateQuantity(
        id,
        newQuantity,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not update cart: $e',
      );
    }
  }

  // ===========================================================
  // REMOVE
  // ===========================================================

  Future<void> _removeItem(
    String id,
  ) async {
    try {
      await CartService.removeItem(
        id,
      );

      if (!mounted) return;

      _showMessage(
        'Product removed from cart.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not remove product: $e',
      );
    }
  }

  // ===========================================================
  // CHECKOUT
  // ===========================================================

  Future<void> _checkout(
    List<CartItem> cartItems,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginPage(),
        ),
      );

      return;
    }

    if (cartItems.isEmpty) {
      _showMessage(
        'Your cart is empty.',
      );
      return;
    }

    // =========================================================
    // CONVERT CART ITEMS TO CHECKOUT ITEMS
    // =========================================================

    final checkoutItems =
        cartItems.map((item) {
      return CheckoutItem(
        id:
            item.id,
       name:
            item.name,
        price:
            item.price,
        imageUrl:
            item.imageUrl,
        quantity:
            item.quantity,

        // =====================================================
        // RESELLER DATA
        // =====================================================

        isResellerProduct:
            item.isResellerProduct,

        entrepreneurUid:
            item.entrepreneurUid,

        sellerId:
            item.sellerId,

        supplierProductId:
            item.supplierProductId,

        supplierPrice:
            item.supplierPrice,

        resellerProfit:
            item.resellerProfit,
      );
    }).toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CheckoutPage(
          items: checkoutItems,
          clearCartOnSuccess:
              true,
        ),
      ),
    );
  }

  // ===========================================================
  // MESSAGE
  // ===========================================================

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

  // ===========================================================
  // PRODUCT IMAGE
  // ===========================================================

  Widget _productImage(
    String? imageUrl,
  ) {
    if (imageUrl == null ||
        imageUrl.trim().isEmpty) {
      return Container(
        width: 90,
        height: 90,
        decoration:
            BoxDecoration(
          color:
              Colors.grey.shade200,
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.image_outlined,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder:
            (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: 90,
            height: 90,
            color:
                Colors.grey.shade200,
            child:
                const Icon(
              Icons.image_outlined,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  // ===========================================================
  // CART ITEM CARD
  // ===========================================================

  Widget _cartItemCard(
    CartItem item,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 1,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _productImage(
              item.imageUrl,
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // PRODUCT NAME + RESELLER LABEL
                  // =================================================

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
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
                      ),

                      if (item
                          .isResellerProduct)
                        Container(
                          margin:
                              const EdgeInsets.only(
                            left: 6,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .blue
                                .withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child:
                              const Text(
                            'Reseller',
                            style:
                                TextStyle(
                              color:
                                  Colors.blue,
                              fontSize:
                                  10,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  // =================================================
                  // PRICE
                  // =================================================

                  Text(
                    '৳${item.price.toStringAsFixed(0)}',
                    style:
                        const TextStyle(
                      color:
                          Colors.redAccent,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  // =================================================
                  // QUANTITY
                  // =================================================

                  Row(
                    children: [
                      Container(
                        decoration:
                            BoxDecoration(
                          border:
                              Border.all(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed:
                                  item.quantity >
                                          1
                                      ? () =>
                                          _changeQuantity(
                                            item.id,
                                            item.quantity,
                                            -1,
                                          )
                                      : null,
                              icon:
                                  const Icon(
                                Icons.remove,
                                size: 20,
                              ),
                              visualDensity:
                                  VisualDensity
                                      .compact,
                            ),

                            SizedBox(
                              width: 28,
                              child: Text(
                                '${item.quantity}',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed:
                                  () =>
                                      _changeQuantity(
                                item.id,
                                item.quantity,
                                1,
                              ),
                              icon:
                                  const Icon(
                                Icons.add,
                                size: 20,
                              ),
                              visualDensity:
                                  VisualDensity
                                      .compact,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        onPressed:
                            () =>
                                _removeItem(
                          item.id,
                        ),
                        icon:
                            const Icon(
                          Icons
                              .delete_outline,
                          color:
                              Colors.redAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  // =================================================
                  // ITEM TOTAL
                  // =================================================

                  Text(
                    'Item Total: ৳${item.total.toStringAsFixed(0)}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  // =================================================
                  // RESELLER PROFIT
                  // =================================================

                  if (item
                      .isResellerProduct)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 4,
                      ),
                      child: Text(
                        'Estimated Profit: '
                        '৳${item.profitTotal.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          color:
                              Colors.green,
                          fontSize:
                              13,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // SUMMARY
  // ===========================================================

  Widget _summaryCard(
    double subtotal,
    double deliveryFee,
    double total,
    int totalQuantity,
  ) {
    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Quantity',
                  ),
                ),
                Text(
                  '$totalQuantity',
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Subtotal',
                  ),
                ),
                Text(
                  '৳${subtotal.toStringAsFixed(0)}',
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Delivery Fee',
                  ),
                ),
                Text(
                  '৳${deliveryFee.toStringAsFixed(0)}',
                ),
              ],
            ),

            const Divider(
              height: 24,
            ),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '৳${total.toStringAsFixed(0)}',
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final user =
        FirebaseAuth.instance.currentUser;

    // =========================================================
    // LOGIN REQUIRED
    // =========================================================

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor:
              Colors.redAccent,
          foregroundColor:
              Colors.white,
          title: const Text(
            'Cart',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons
                      .shopping_cart_outlined,
                  size: 80,
                  color:
                      Colors.grey.shade400,
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'Please login to view your cart.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const LoginPage(),
                      ),
                    );
                  },
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors.redAccent,
                    foregroundColor:
                        Colors.white,
                  ),
                  child:
                      const Text(
                    'Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // =========================================================
    // CART STREAM
    // =========================================================

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.redAccent,
        foregroundColor:
            Colors.white,
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream:
            FirebaseFirestore
                .instance
                .collection(
                  'users',
                )
                .doc(user.uid)
                .collection(
                  'cart',
                )
                .snapshots(),

        builder:
            (context, snapshot) {
          if (snapshot
                  .connectionState ==
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
                    const EdgeInsets
                        .all(
                  20,
                ),
                child: Text(
                  'Could not load cart.\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final documents =
              snapshot.data?.docs ??
                  [];

          if (documents.isEmpty) {
            return _emptyCart();
          }

          final cartItems =
              <CartItem>[];

          for (final doc
              in documents) {
            final data =
                doc.data();

            // =================================================
            // NAME
            // =================================================

            final name =
                data['name']
                        ?.toString() ??
                    data['productName']
                        ?.toString() ??
                    'Unnamed Product';

            // =================================================
            // PRICE
            // =================================================

            final priceValue =
                data['price'] ??
                    data['sellingPrice'] ??
                    0;

            final double price =
                priceValue is num
                    ? priceValue.toDouble()
                    : double.tryParse(
                          priceValue
                              .toString(),
                        ) ??
                        0;

            // =================================================
            // QUANTITY
            // =================================================

            final quantity =
                (data['quantity']
                            as num?)
                        ?.toInt() ??
                    1;

            // =================================================
            // IMAGE
            // =================================================

            final image =
                data['imageUrl']
                    ?.toString();

            // =================================================
            // RESELLER DATA
            // =================================================

            final isResellerProduct =
                data['isResellerProduct'] ==
                    true;

            final entrepreneurUid =
                _nullableString(
              data['entrepreneurUid'],
            );

            final sellerId =
                _nullableString(
              data['sellerId'],
            );

            final supplierProductId =
                _nullableString(
              data['supplierProductId'],
            );

            final supplierPrice =
                _nullableDouble(
              data['supplierPrice'],
            );

            final resellerProfit =
                _nullableDouble(
              data['resellerProfit'],
            );

            cartItems.add(
              CartItem(
                id: doc.id,
                name: name,
                price: price,
                imageUrl:
                    image == null ||
                            image.isEmpty
                        ? null
                        : image,
                quantity:
                    quantity < 1
                        ? 1
                        : quantity,

                // =================================================
                // RESTORE RESELLER DATA
                // =================================================

                isResellerProduct:
                    isResellerProduct,

                entrepreneurUid:
                    entrepreneurUid,

                sellerId:
                    sellerId,

                supplierProductId:
                    supplierProductId,

                supplierPrice:
                    supplierPrice,

                resellerProfit:
                    resellerProfit,
              ),
            );
          }

          // =================================================
          // CALCULATE TOTALS
          // =================================================

          double subtotal = 0;

          int totalQuantity = 0;

          for (final item
              in cartItems) {
            subtotal +=
                item.total;

            totalQuantity +=
                item.quantity;
          }

          final deliveryFee =
              CartService
                  .deliveryFeeAmount;

          final total =
              subtotal +
                  deliveryFee;

          // =================================================
          // PAGE
          // =================================================

          return Column(
            children: [
              Expanded(
                child:
                    ListView(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    16,
                    16,
                    16,
                    20,
                  ),
                  children: [
                    Text(
                      '${cartItems.length} product${cartItems.length == 1 ? '' : 's'} in cart',
                      style:
                          TextStyle(
                        color: Colors
                            .grey
                            .shade700,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    ...cartItems.map(
                      (item) =>
                          _cartItemCard(
                        item,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    _summaryCard(
                      subtotal,
                      deliveryFee,
                      total,
                      totalQuantity,
                    ),
                  ],
                ),
              ),

              // =================================================
              // CHECKOUT BUTTON
              // =================================================

              SafeArea(
                child: Container(
                  padding:
                      const EdgeInsets
                          .all(
                    12,
                  ),
                  decoration:
                      const BoxDecoration(
                    color:
                        Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black12,
                        blurRadius:
                            8,
                        offset:
                            Offset(
                          0,
                          -2,
                        ),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width:
                        double.infinity,
                    height: 54,
                    child:
                        ElevatedButton(
                      onPressed:
                          () =>
                              _checkout(
                        cartItems,
                      ),
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            Colors
                                .redAccent,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                      ),
                      child: Text(
                        'Checkout • ৳${total.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================
  // NULLABLE STRING
  // ===========================================================

  String? _nullableString(
    dynamic value,
  ) {
    final text =
        value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  // ===========================================================
  // NULLABLE DOUBLE
  // ===========================================================

  double? _nullableDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final parsed =
        double.tryParse(
      value.toString(),
    );

    return parsed;
  }

  // ===========================================================
  // EMPTY CART
  // ===========================================================

  Widget _emptyCart() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .shopping_cart_outlined,
              size: 90,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Add products to your cart and they will appear here.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
