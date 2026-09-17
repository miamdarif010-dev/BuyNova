import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'my_orders_page.dart';

class CheckoutPage extends StatefulWidget {
  final String productId;
  final String productName;
  final double price;
  final String? imageUrl;
  final int quantity;

  const CheckoutPage({
    super.key,
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _placingOrder = false;

  static const double deliveryFee = 3000;

  double get subtotal => widget.price * widget.quantity;

  double get total => subtotal + deliveryFee;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _placingOrder = true;
    });

    try {
      final orderRef =
          FirebaseFirestore.instance.collection('orders').doc();

      await orderRef.set({
        'orderId': orderRef.id,
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'customerName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),

        'productId': widget.productId,
        'productName': widget.productName,
        'imageUrl': widget.imageUrl ?? '',

        'quantity': widget.quantity,
        'productPrice': widget.price,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,

        'paymentMethod': 'Cash on Delivery',
        'paymentStatus': 'pending',
        'orderStatus': 'placed',

        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully! 🎉'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MyOrdersPage(),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _placingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter your name';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter your phone number';
                }
                if (value.trim().length < 8) {
                  return 'Enter a valid phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                alignLabelWithHint: true,
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                ),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter your delivery address';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Product
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: widget.imageUrl != null &&
                              widget.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(8),
                              child: Image.network(
                                widget.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Icon(
                                    Icons.image,
                                    size: 35,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              size: 35,
                              color: Colors.grey,
                            ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productName,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            '₩${widget.price.toStringAsFixed(0)} × ${widget.quantity}',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Payment
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.payments_outlined,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Cash on Delivery',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Pay when your order arrives',
                ),
                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Price summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _priceRow(
                      'Subtotal',
                      '₩${subtotal.toStringAsFixed(0)}',
                    ),

                    const SizedBox(height: 8),

                    _priceRow(
                      'Delivery',
                      '₩${deliveryFee.toStringAsFixed(0)}',
                    ),

                    const Divider(height: 24),

                    _priceRow(
                      'Total',
                      '₩${total.toStringAsFixed(0)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    _placingOrder ? null : _placeOrder,
                child: _placingOrder
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: bold ? 18 : 15,
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 15,
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
            color:
                bold ? Colors.redAccent : Colors.black87,
          ),
        ),
      ],
    );
  }
}
