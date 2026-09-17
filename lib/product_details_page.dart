import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_page.dart';
import 'login_page.dart';

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
  bool _isFavorite = false;
  bool _loadingFavorite = true;
  bool _addingToCart = false;

  User? get _user =>
      FirebaseAuth.instance.currentUser;

  String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double _price(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }

  String _formatPrice(dynamic value) {
    return '₩${_price(value).toStringAsFixed(0)}';
  }

  String get _name => _text(
        widget.product['name'] ??
            widget.product['productName'],
        'BuyNova Product',
      );

  String get _imageUrl => _text(
        widget.product['imageUrl'] ??
            widget.product['productImageUrl'],
      );

  String get _category =>
      _text(widget.product['category'], 'Product');

  String get _description => _text(
        widget.product['description'],
        'No description available for this product.',
      );

  double get _productPrice => _price(
        widget.product['price'] ??
            widget.product['sellingPrice'] ??
            0,
      );

  String get _sellerId =>
      _text(widget.product['sellerCode'] ??
          widget.product['sellerId']);

  String get _sellerEmail =>
      _text(widget.product['sellerEmail']);

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  DocumentReference<Map<String, dynamic>>?
      _favoriteRef() {
    final user = _user;

    if (user == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.productId);
  }

  Future<void> _checkFavorite() async {
    final ref = _favoriteRef();

    if (ref == null) {
      if (mounted) {
        setState(() {
          _loadingFavorite = false;
        });
      }
      return;
    }

    try {
      final doc = await ref.get();

      if (mounted) {
        setState(() {
          _isFavorite = doc.exists;
          _loadingFavorite = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _user;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
      return;
    }

    final ref = _favoriteRef();

    if (ref == null) return;

    try {
      if (_isFavorite) {
        await ref.delete();

        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
        }

        _showMessage('Removed from Favorites.');
      } else {
        await ref.set({
          'productId': widget.productId,
          'productName': _name,
          'productImageUrl':
              _imageUrl.isEmpty ? null : _imageUrl,
          'category': _category,
          'price': _productPrice,
          'userId': user.uid,
          'createdAt':
              FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            _isFavorite = true;
          });
        }

        _showMessage('Added to Favorites.');
      }
    } catch (e) {
      _showMessage(
        'Could not update Favorites: $e',
      );
    }
  }

  Future<void> _addToCart() async {
    final user = _user;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
      return;
    }

    if (_addingToCart) return;

    setState(() {
      _addingToCart = true;
    });

    try {
      await CartService.addItem(
        id: widget.productId,
        name: _name,
        price: _productPrice,
        imageUrl:
            _imageUrl.isEmpty ? null : _imageUrl,
      );

      if (mounted) {
        _showMessage(
          '$_name added to Cart.',
          showCartAction: true,
        );
      }
    } catch (e) {
      _showMessage(
        'Could not add to Cart: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingToCart = false;
        });
      }
    }
  }

  void _buyNow() {
    final user = _user;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
      return;
    }

    // Checkout will be connected here
    // in the next shopping step.
    _showMessage(
      'Buy Now checkout will be connected next.',
    );
  }

  void _showMessage(
    String message, {
    bool showCartAction = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: showCartAction
            ? SnackBarAction(
                label: 'VIEW CART',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CartPage(),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: double.infinity,
      height: 330,
      color: Colors.grey.shade100,
      child: _imageUrl.isNotEmpty
          ? Image.network(
              _imageUrl,
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons
                        .image_not_supported_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                );
              },
            )
          : const Center(
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.grey,
              ),
            ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CartPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.shopping_cart_outlined,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildProductImage(),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(
                      onPressed: _loadingFavorite
                          ? null
                          : _toggleFavorite,
                      icon: Icon(
                        _isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _isFavorite
                            ? Colors.redAccent
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // CATEGORY
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent
                          .withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      _category,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // NAME
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // PRICE
                  Text(
                    _formatPrice(_productPrice),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Divider(),

                  const SizedBox(height: 15),

                  // DESCRIPTION
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _description,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // PRODUCT INFORMATION
                  const Text(
                    'Product Information',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  _infoRow(
                    Icons.category_outlined,
                    'Category',
                    _category,
                  ),

                  _infoRow(
                    Icons.inventory_2_outlined,
                    'Product ID',
                    widget.productId,
                  ),

                  _infoRow(
                    Icons.store_outlined,
                    'Seller ID',
                    _sellerId,
                  ),

                  _infoRow(
                    Icons.email_outlined,
                    'Seller Email',
                    _sellerEmail,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            12,
            10,
            12,
            10,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _addingToCart ? null : _addToCart,
                  icon: _addingToCart
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons
                              .shopping_cart_outlined,
                        ),
                  label: const Text(
                    'Add to Cart',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.redAccent,
                    side: const BorderSide(
                      color: Colors.redAccent,
                    ),
                    minimumSize:
                        const Size(0, 50),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.redAccent,
                    foregroundColor:
                        Colors.white,
                    minimumSize:
                        const Size(0, 50),
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
