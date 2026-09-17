import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_page.dart';
import 'login_page.dart';
import 'checkout_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> product;

  const ProductDetailsPage({
    super.key,
    required this.productId,
    required this.product,
  });

  @override
  State<ProductDetailsPage> createState() =>
      _ProductDetailsPageState();
}

class _ProductDetailsPageState
    extends State<ProductDetailsPage> {
  int _quantity = 1;
  bool _isFavorite = false;
  bool _loadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  // =========================================================
  // PRODUCT DATA
  // =========================================================

  String get productName {
    return widget.product['name']?.toString() ??
        widget.product['productName']?.toString() ??
        'Unnamed Product';
  }

  String get imageUrl {
    return widget.product['imageUrl']?.toString() ??
        widget.product['productImageUrl']?.toString() ??
        '';
  }

  String get category {
    return widget.product['category']?.toString() ?? '';
  }

  String get description {
    return widget.product['description']?.toString() ??
        'No description available.';
  }

  double get price {
    final value =
        widget.product['price'] ??
        widget.product['sellingPrice'] ??
        0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String get sellerCode {
    return widget.product['sellerCode']?.toString() ?? '';
  }

  String get sellerId {
    return widget.product['sellerId']?.toString() ?? '';
  }

  String get sellerEmail {
    return widget.product['sellerEmail']?.toString() ?? '';
  }

  double get subtotal {
    return price * _quantity;
  }

  // =========================================================
  // FAVORITE REFERENCE
  // =========================================================

  DocumentReference<Map<String, dynamic>>
      _favoriteReference(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(widget.productId);
  }

  // =========================================================
  // LOAD FAVORITE
  // =========================================================

  Future<void> _loadFavoriteStatus() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingFavorite = false;
        });
      }
      return;
    }

    try {
      final snapshot =
          await _favoriteReference(user.uid).get();

      if (!mounted) return;

      setState(() {
        _isFavorite = snapshot.exists;
        _loadingFavorite = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingFavorite = false;
      });
    }
  }

  // =========================================================
  // TOGGLE FAVORITE
  // =========================================================

  Future<void> _toggleFavorite() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );

      await _loadFavoriteStatus();
      return;
    }

    final favoriteRef =
        _favoriteReference(user.uid);

    try {
      if (_isFavorite) {
        await favoriteRef.delete();

        if (!mounted) return;

        setState(() {
          _isFavorite = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Removed from Favorites'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        await favoriteRef.set({
          'productId': widget.productId,
          'productName': productName,
          'productImageUrl': imageUrl,
          'category': category,
          'price': price,
          'userId': user.uid,
          'createdAt':
              FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        setState(() {
          _isFavorite = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Added to Favorites ❤️'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Favorite update failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // ADD TO CART
  // =========================================================

  Future<void> _addToCart() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
      return;
    }

    try {
      for (int i = 0; i < _quantity; i++) {
        await CartService.addItem(
          id: widget.productId,
          name: productName,
          price: price,
          imageUrl:
              imageUrl.isEmpty ? null : imageUrl,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$_quantity × $productName added to cart',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Could not add to cart: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // BUY NOW
  // =========================================================

  Future<void> _buyNow() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          productId: widget.productId,
          productName: productName,
          price: price,
          imageUrl:
              imageUrl.isEmpty ? null : imageUrl,
          quantity: _quantity,
        ),
      ),
    );
  }

  // =========================================================
  // QUANTITY
  // =========================================================

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity <= 1) return;

    setState(() {
      _quantity--;
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CartPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // IMAGE
            // =================================================

            SizedBox(
              width: double.infinity,
              height: 330,
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
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),

            // =================================================
            // PRODUCT INFORMATION
            // =================================================

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed:
                            _loadingFavorite
                                ? null
                                : _toggleFavorite,
                        icon: Icon(
                          _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isFavorite
                              ? Colors.redAccent
                              : Colors.grey,
                          size: 30,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (category.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Colors.redAccent.shade100,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  Text(
                    '₩${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 25,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // QUANTITY
                  // =================================================

                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                Colors.grey.shade300,
                          ),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed:
                                  _decreaseQuantity,
                              icon: const Icon(
                                Icons.remove,
                              ),
                            ),

                            SizedBox(
                              width: 35,
                              child: Text(
                                '$_quantity',
                                textAlign:
                                    TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed:
                                  _increaseQuantity,
                              icon: const Icon(
                                Icons.add,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      Text(
                        'Total: ₩${subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // SELLER INFORMATION
                  // =================================================

                  if (sellerCode.isNotEmpty ||
                      sellerId.isNotEmpty ||
                      sellerEmail.isNotEmpty)
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seller Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            if (sellerCode.isNotEmpty)
                              Text(
                                'Seller ID: $sellerCode',
                              ),

                            if (sellerId.isNotEmpty)
                              Text(
                                'Seller UID: $sellerId',
                              ),

                            if (sellerEmail.isNotEmpty)
                              Text(
                                'Seller Email: $sellerEmail',
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      // =========================================================
      // BOTTOM ACTIONS
      // =========================================================

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(10),
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                  ),
                  label: const Text(
                    'Add to Cart',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.redAccent,
                    side: const BorderSide(
                      color: Colors.redAccent,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _buyNow,
                  icon: const Icon(
                    Icons.flash_on,
                  ),
                  label: const Text(
                    'Buy Now',
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
