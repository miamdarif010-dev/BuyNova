import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'my_orders_page.dart';

class CheckoutItem {
  final String productId;
  final String productName;
  final double price;
  final String? imageUrl;
  final int quantity;

  const CheckoutItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    required this.quantity,
  });

  double get total => price * quantity;
}

class CheckoutPage extends StatefulWidget {
  /// Cart থেকে একাধিক product পাঠানোর জন্য
  final List<CheckoutItem> items;

  /// Buy Now-এর পুরোনো single-product system-এর জন্য
  final String? productId;
  final String? productName;
  final double? price;
  final String? imageUrl;
  final int? quantity;

  /// Cart থেকে এলে order দেওয়ার পর cart clear হবে
  final bool clearCartOnSuccess;

  const CheckoutPage({
    super.key,
    this.items = const [],
    this.productId,
    this.productName,
    this.price,
    this.imageUrl,
    this.quantity,
    this.clearCartOnSuccess = false,
  });

  List<CheckoutItem> get checkoutItems {
    if (items.isNotEmpty) {
      return items;
    }

    if (productId != null &&
        productName != null &&
        price != null &&
        quantity != null) {
      return [
        CheckoutItem(
          productId: productId!,
          productName: productName!,
          price: price!,
          imageUrl: imageUrl,
          quantity: quantity!,
        ),
      ];
    }

    return [];
  }

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _placingOrder = false;

  static const double deliveryFee = 3000;

  List<CheckoutItem> get items => widget.checkoutItems;

  double get subtotal {
    double value = 0;

    for (final item in items) {
      value += item.total;
    }

    return value;
  }

  double get total {
    return subtotal + deliveryFee;
  }

  int get totalQuantity {
    int value = 0;

    for (final item in items) {
      value += item.quantity;
    }

    return value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _clearCart(String uid) async {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart');

    final snapshot = await cartRef.get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    if (items.isEmpty) {
      _showMessage('Your cart is empty.');
      return;
    }

    setState(() {
      _placingOrder = true;
    });

    try {
      final orderRef =
          FirebaseFirestore.instance.collection('orders').doc();

      final orderItems = items.map((item) {
        return {
          'productId': item.productId,
          'productName': item.productName,
          'imageUrl': item.imageUrl ?? '',
          'price': item.price,
          'quantity': item.quantity,
          'total': item.total,
        };
      }).toList();

      await orderRef.set({
        'orderId': orderRef.id,
        'userId': user.uid,
        'userEmail': user.email ?? '',

        'customerName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),

        'items': orderItems,
        'itemCount': items.length,
        'totalQuantity': totalQuantity,

        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,

        'paymentMethod': 'Cash on Delivery',
        'paymentStatus': 'pending',
        'orderStatus': 'placed',

        'createdAt': FieldValue.serverTimestamp(),
      });

      if (widget.clearCartOnSuccess) {
        await _clearCart(user.uid);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyOrdersPage(),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to place order. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _placingOrder = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildProductItem(CheckoutItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.imageUrl != null &&
                    item.imageUrl!.trim().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.grey,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₩${item.price.toStringAsFixed(0)} × ${item.quantity}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₩${item.total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
        ),
        body: const Center(
          child: Text(
            'No products available for checkout.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter your name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }

                  if (value.trim().length < 8) {
                    return 'Please enter a valid phone number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Delivery Address',
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                  ),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter delivery address';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 28),

              const Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              ...items.map(_buildProductItem),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      'Products',
                      '${items.length}',
                    ),
                    _summaryRow(
                      'Total Quantity',
                      '$totalQuantity',
                    ),
                    _summaryRow(
                      'Subtotal',
                      '₩${subtotal.toStringAsFixed(0)}',
                    ),
                    _summaryRow(
                      'Delivery',
                      '₩${deliveryFee.toStringAsFixed(0)}',
                    ),
                    const Divider(),
                    _summaryRow(
                      'Total',
                      '₩${total.toStringAsFixed(0)}',
                      bold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: Colors.green,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cash on Delivery',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pay when your order is delivered.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _placingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _placingOrder
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Place Order • ₩${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
