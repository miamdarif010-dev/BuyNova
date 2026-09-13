import 'package:flutter/material.dart';

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

class CartManager {
  static final List<CartItem> items = [];

  static void addItem({
    required String id,
    required String name,
    required double price,
    String? imageUrl,
  }) {
    final index = items.indexWhere((item) => item.id == id);

    if (index != -1) {
      items[index].quantity++;
    } else {
      items.add(
        CartItem(
          id: id,
          name: name,
          price: price,
          imageUrl: imageUrl,
        ),
      );
    }
  }

  static void removeItem(String id) {
    items.removeWhere((item) => item.id == id);
  }

  static void increaseQuantity(String id) {
    final index = items.indexWhere((item) => item.id == id);

    if (index != -1) {
      items[index].quantity++;
    }
  }

  static void decreaseQuantity(String id) {
    final index = items.indexWhere((item) => item.id == id);

    if (index != -1) {
      if (items[index].quantity > 1) {
        items[index].quantity--;
      } else {
        items.removeAt(index);
      }
    }
  }

  static double get subtotal {
    return items.fold(
      0,
      (sum, item) => sum + item.total,
    );
  }

  static double get deliveryFee {
    if (items.isEmpty) return 0;
    return 3000;
  }

  static double get total {
    return subtotal + deliveryFee;
  }

  static int get itemCount {
    return items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = CartManager.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Cart (${CartManager.itemCount})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: items.isEmpty
          ? _emptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              // PRODUCT IMAGE
                              Container(
                                width: 85,
                                height: 85,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Icon(
                                              Icons.image,
                                              size: 40,
                                              color: Colors.grey,
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                              ),

                              const SizedBox(width: 12),

                              // PRODUCT INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
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
                                      '₩${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        // DECREASE
                                        InkWell(
                                          onTap: () {
                                            CartManager
                                                .decreaseQuantity(
                                              item.id,
                                            );
                                            _refresh();
                                          },
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration:
                                                BoxDecoration(
                                              border: Border.all(
                                                color: Colors
                                                    .grey
                                                    .shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                6,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.remove,
                                              size: 18,
                                            ),
                                          ),
                                        ),

                                        SizedBox(
                                          width: 38,
                                          child: Center(
                                            child: Text(
                                              '${item.quantity}',
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // INCREASE
                                        InkWell(
                                          onTap: () {
                                            CartManager
                                                .increaseQuantity(
                                              item.id,
                                            );
                                            _refresh();
                                          },
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration:
                                                BoxDecoration(
                                              border: Border.all(
                                                color: Colors
                                                    .grey
                                                    .shade300,
                                              ),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                6,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              size: 18,
                                            ),
                                          ),
                                        ),

                                        const Spacer(),

                                        // DELETE
                                        IconButton(
                                          onPressed: () {
                                            CartManager
                                                .removeItem(
                                              item.id,
                                            );
                                            _refresh();
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // PRICE SUMMARY
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _priceRow(
                        'Subtotal',
                        '₩${CartManager.subtotal.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 8),
                      _priceRow(
                        'Delivery Fee',
                        '₩${CartManager.deliveryFee.toStringAsFixed(0)}',
                      ),
                      const Divider(height: 20),
                      _priceRow(
                        'Total',
                        '₩${CartManager.total.toStringAsFixed(0)}',
                        bold: true,
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Checkout coming soon',
                                ),
                                behavior:
                                    SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
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
              ],
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
                bold ? FontWeight.bold : FontWeight.w600,
            color: bold ? Colors.redAccent : null,
          ),
        ),
      ],
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 90,
              color: Colors.grey.shade400,
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
            Text(
              'Add products to your cart and they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}
