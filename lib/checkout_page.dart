import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // =========================================================
  // NEW CART CHECKOUT
  // =========================================================

  final List<CheckoutItem> items;

  // =========================================================
  // OLD BUY NOW COMPATIBILITY
  // =========================================================

  final String? productId;
  final String? productName;
  final double? price;
  final String? imageUrl;
  final int? quantity;

  // =========================================================
  // CLEAR CART AFTER SUCCESS
  // =========================================================

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

  // =========================================================
  // RESOLVE CHECKOUT ITEMS
  // =========================================================

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

    return const [];
  }

  @override
  State<CheckoutPage> createState() =>
      _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  bool _placingOrder = false;

  String _paymentMethod = 'Cash on Delivery';

  static const double deliveryFee = 3000;

  // =========================================================
  // SUBTOTAL
  // =========================================================

  double get subtotal {
    double total = 0;

    for (final item in widget.checkoutItems) {
      total += item.total;
    }

    return total;
  }

  // =========================================================
  // TOTAL QUANTITY
  // =========================================================

  int get totalQuantity {
    int quantity = 0;

    for (final item in widget.checkoutItems) {
      quantity += item.quantity;
    }

    return quantity;
  }

  // =========================================================
  // GRAND TOTAL
  // =========================================================

  double get grandTotal {
    return subtotal + deliveryFee;
  }

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadUserInformation();
  }

  // =========================================================
  // LOAD USER INFORMATION
  // =========================================================

  Future<void> _loadUserInformation() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final data = snapshot.data();

      if (data != null) {
        _nameController.text =
            data['name']?.toString() ?? '';

        _phoneController.text =
            data['phone']?.toString() ?? '';
      }
    } catch (_) {
      // Keep checkout usable even if profile loading fails.
    }
  }

  // =========================================================
  // CLEAR CART
  // =========================================================

  Future<void> _clearCart(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
  }

  // =========================================================
  // VALIDATE
  // =========================================================

  bool _validateForm() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter your full name.');
      return false;
    }

    if (phone.isEmpty) {
      _showMessage('Please enter your phone number.');
      return false;
    }

    if (address.isEmpty) {
      _showMessage('Please enter your delivery address.');
      return false;
    }

    if (phone.length < 7) {
      _showMessage('Please enter a valid phone number.');
      return false;
    }

    if (widget.checkoutItems.isEmpty) {
      _showMessage('No products selected.');
      return false;
    }

    return true;
  }

  // =========================================================
  // PLACE ORDER
  // =========================================================

  Future<void> _placeOrder() async {
    if (_placingOrder) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login before placing an order.',
      );
      return;
    }

    if (!_validateForm()) return;

    setState(() {
      _placingOrder = true;
    });

    try {
      final orderRef =
          FirebaseFirestore.instance
              .collection('orders')
              .doc();

      final itemsData =
          widget.checkoutItems.map((item) {
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

        'customerName':
            _nameController.text.trim(),

        'phone':
            _phoneController.text.trim(),

        'address':
            _addressController.text.trim(),

        // =====================================================
        // MULTI PRODUCT ITEMS
        // =====================================================

        'items': itemsData,

        'itemCount':
            widget.checkoutItems.length,

        'totalQuantity':
            totalQuantity,

        // =====================================================
        // MONEY
        // =====================================================

        'subtotal': subtotal,

        'deliveryFee': deliveryFee,

        'total': grandTotal,

        // =====================================================
        // PAYMENT
        // =====================================================

        'paymentMethod':
            _paymentMethod,

        'paymentStatus':
            'pending',

        // =====================================================
        // ORDER STATUS
        // =====================================================

        'orderStatus':
            'placed',

        // =====================================================
        // DATE
        // =====================================================

        'createdAt':
            FieldValue.serverTimestamp(),
      });

      // =======================================================
      // CLEAR CART ONLY FOR CART CHECKOUT
      // =======================================================

      if (widget.clearCartOnSuccess) {
        await _clearCart(user.uid);
      }

      if (!mounted) return;

      // =======================================================
      // SUCCESS DIALOG
      // =======================================================

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text('Order Placed'),
              ],
            ),
            content: Text(
              'Your order has been placed successfully.\n\n'
              'Order ID:\n${orderRef.id}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // =======================================================
      // GO TO MY ORDERS
      // =======================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MyOrdersPage(),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not place order.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _placingOrder = false;
        });
      }
    }
  }

  // =========================================================
  // MESSAGE
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
  // PRODUCT IMAGE
  // =========================================================

  Widget _productImage(CheckoutItem item) {
    final imageUrl = item.imageUrl ?? '';

    if (imageUrl.isEmpty) {
      return Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 35,
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: 75,
        height: 75,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: 75,
            height: 75,
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.image_outlined,
              color: Colors.grey,
              size: 35,
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // PRODUCT CARD
  // =========================================================

  Widget _productCard(CheckoutItem item) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
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
            _productImage(item),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '₩${item.price.toStringAsFixed(0)} × ${item.quantity}',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '₩${item.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
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

  // =========================================================
  // SUMMARY ROW
  // =========================================================

  Widget _summaryRow(
    String title,
    String value, {
    bool bold = false,
    Color? valueColor,
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
                fontSize: 15,
                fontWeight: bold
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final items = widget.checkoutItems;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.redAccent,
        foregroundColor: Colors.white,
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: items.isEmpty
          ? const Center(
              child: Text(
                'No products selected.',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                ),
              ),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                120,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // ORDER ITEMS
                  // =================================================

                  const Text(
                    'Order Items',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...items.map(
                    (item) =>
                        _productCard(item),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // DELIVERY INFORMATION
                  // =================================================

                  const Text(
                    'Delivery Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        _nameController,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        InputDecoration(
                      labelText: 'Full Name',
                      hintText:
                          'Enter your full name',
                      prefixIcon:
                          const Icon(
                        Icons.person,
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

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        _phoneController,
                    keyboardType:
                        TextInputType.phone,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Phone Number',
                      hintText:
                          'Enter your phone number',
                      prefixIcon:
                          const Icon(
                        Icons.phone,
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

                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        _addressController,
                    keyboardType:
                        TextInputType
                            .streetAddress,
                    maxLines: 3,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Delivery Address',
                      hintText:
                          'Enter your complete delivery address',
                      prefixIcon:
                          const Padding(
                        padding:
                            EdgeInsets.only(
                          bottom: 45,
                        ),
                        child: Icon(
                          Icons.location_on,
                        ),
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

                  const SizedBox(height: 20),

                  // =================================================
                  // PAYMENT METHOD
                  // =================================================

                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      side: BorderSide(
                        color:
                            Colors.grey.shade300,
                      ),
                    ),
                    child: RadioGroup<String>(
                      groupValue:
                          _paymentMethod,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _paymentMethod =
                              value;
                        });
                      },
                      child:
                          const RadioListTile<
                              String>(
                        value:
                            'Cash on Delivery',
                        title: Text(
                          'Cash on Delivery',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Pay when your order arrives',
                        ),
                        secondary: Icon(
                          Icons
                              .payments_outlined,
                          color:
                              Colors.redAccent,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // ORDER SUMMARY
                  // =================================================

                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        16,
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
                            'Delivery Fee',
                            '₩${deliveryFee.toStringAsFixed(0)}',
                          ),

                          const Divider(
                            height: 20,
                          ),

                          _summaryRow(
                            'Total',
                            '₩${grandTotal.toStringAsFixed(0)}',
                            bold: true,
                            valueColor:
                                Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

      // =========================================================
      // PLACE ORDER BUTTON
      // =========================================================

      bottomNavigationBar:
          items.isEmpty
              ? null
              : SafeArea(
                  child: Container(
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),
                    decoration:
                        const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black12,
                          blurRadius: 8,
                          offset:
                              Offset(0, -2),
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
                            _placingOrder
                                ? null
                                : _placeOrder,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.redAccent,
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
                        child: _placingOrder
                            ? const SizedBox(
                                width: 25,
                                height: 25,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2.5,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : Text(
                                'Place Order • ₩${grandTotal.toStringAsFixed(0)}',
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
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
