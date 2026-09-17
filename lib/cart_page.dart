import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'checkout_page.dart';
import 'login_page.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
  });

  double get total => price * quantity;
}

class CartService {
  static const double deliveryFeeAmount = 3000;

  static CollectionReference<Map<String, dynamic>> _cartCollection(
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart');
  }

  static Future<void> addItem({
    required String userId,
    required String productId,
    required String name,
    required double price,
    String? imageUrl,
    int quantity = 1,
  }) async {
    final ref = _cartCollection(userId).doc(productId);

    final snapshot = await ref.get();

    if (snapshot.exists) {
      final currentQuantity =
          (snapshot.data()?['quantity'] as num?)?.toInt() ?? 1;

      await ref.update({
        'name': name,
        'price': price,
        'imageUrl': imageUrl ?? '',
        'quantity': currentQuantity + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        'name': name,
        'price': price,
        'imageUrl': imageUrl ?? '',
        'quantity': quantity,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> updateQuantity({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    final ref = _cartCollection(userId).doc(productId);

    if (quantity <= 0) {
      await ref.delete();
      return;
    }

    await ref.update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeItem({
    required String userId,
    required String productId,
  }) async {
    await _cartCollection(userId).doc(productId).delete();
  }

  static Future<void> clearCart(String userId) async {
    final snapshot = await _cartCollection(userId).get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  double _price(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _quantity(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 1;
  }

  Future<void> _openLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _changeQuantity(
    String productId,
    int currentQuantity,
    int change,
  ) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    final newQuantity = currentQuantity + change;

    try {
      await CartService.updateQuantity(
        userId: user.uid,
        productId: productId,
        quantity: newQuantity,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update quantity.'),
        ),
      );
    }
  }

  Future<void> _removeItem(String productId) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      await CartService.removeItem(
        userId: user.uid,
        productId: productId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product removed from cart.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove product.'),
        ),
      );
    }
  }

  Future<void> _clearCart() async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Cart?'),
          content: const Text(
            'Are you sure you want to remove all products from your cart?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await CartService.clearCart(user.uid);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart cleared.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not clear cart.'),
        ),
      );
    }
  }

  void _checkout(List<CartItem> items) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty.'),
        ),
      );
      return;
    }

    final checkoutItems = items.map((item) {
      return CheckoutItem(
        productId: item.id,
        productName: item.name,
        price: item.price,
        imageUrl: item.imageUrl,
        quantity: item.quantity,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          items: checkoutItems,
          clearCartOnSuccess: true,
        ),
      ),
    );
  }

  Widget _buildCartItem(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final name =
        (data['name'] ?? 'Product').toString();

    final price = _price(data['price']);

    final imageUrl =
        (data['imageUrl'] ?? '').toString();

    final quantity =
        _quantity(data['quantity']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 3),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: imageUrl.trim().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                          size: 32,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.grey,
                    size: 32,
                  ),
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
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '₩${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              _changeQuantity(
                                document.id,
                                quantity,
                                -1,
                              );
                            },
                            icon: const Icon(
                              Icons.remove,
                              size: 18,
                            ),
                            padding: const EdgeInsets.all(6),
                            constraints:
                                const BoxConstraints(),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                            child: Text(
                              '$quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: () {
                              _changeQuantity(
                                document.id,
                                quantity,
                                1,
                              );
                            },
                            icon: const Icon(
                              Icons.add,
                              size: 18,
                            ),
                            padding: const EdgeInsets.all(6),
                            constraints:
                                const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    IconButton(
                      onPressed: () {
                        _removeItem(document.id);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(
    List<CartItem> items,
  ) {
    double subtotal = 0;

    int totalQuantity = 0;

    for (final item in items) {
      subtotal += item.total;
      totalQuantity += item.quantity;
    }

    final total =
        subtotal + CartService.deliveryFeeAmount;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, -3),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '$totalQuantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '₩${subtotal.toStringAsFixed(0)}',
                ),
              ],
            ),

            const SizedBox(height: 6),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '₩${CartService.deliveryFeeAmount.toStringAsFixed(0)}',
                ),
              ],
            ),

            const Divider(height: 22),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₩${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  _checkout(items);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
    final user = currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Please login to view your cart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _openLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cartStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots();

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: cartStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cart'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load cart.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final documents =
            snapshot.data?.docs ?? [];

        final items = documents.map((document) {
          final data = document.data();

          return CartItem(
            id: document.id,
            name: (data['name'] ?? 'Product').toString(),
            price: _price(data['price']),
            imageUrl:
                (data['imageUrl'] ?? '').toString(),
            quantity:
                _quantity(data['quantity']),
          );
        }).toList();

        if (items.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cart'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      size: 90,
                      color: Colors.grey,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Your Cart is Empty',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Add some products to your cart and shop now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 22),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.redAccent,
                        foregroundColor:
                            Colors.white,
                      ),
                      child: const Text(
                        'Continue Shopping',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Cart (${items.length})',
            ),
            actions: [
              IconButton(
                onPressed: _clearCart,
                tooltip: 'Clear Cart',
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                ),
              ),
            ],
          ),

          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...documents.map(_buildCartItem),

              const SizedBox(height: 120),
            ],
          ),

          bottomSheet: _buildBottomSummary(items),
        );
      },
    );
  }
}
