import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'user_profile_page.dart';
import 'add_product_page.dart';
import 'settings_page.dart';
import 'cart_page.dart';
import 'categories_page.dart';
import 'news_feed_page.dart';
import 'app_settings.dart';
import 'product_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _selectedCategory = 0;

  final List<String> categories = [
    'All',
    'Phones',
    'Laptops',
    'Watches',
    'Earbuds',
    'Cameras',
    'Fashion',
    'Shoes',
    'Bags',
    'Beauty',
    'Sports',
    'Toys',
    'Grocery',
  ];

  // =========================================================
  // CURRENCY SYMBOL
  // =========================================================

  String _currencySymbol(String currency) {
    switch (currency) {
      case 'BDT':
        return '৳';
      case 'USD':
        return '\$';
      case 'INR':
        return '₹';
      case 'EUR':
        return '€';
      case 'KRW':
      default:
        return '₩';
    }
  }

  // =========================================================
  // CURRENCY CONVERSION
  // =========================================================

  double _convertPrice(
    double krwPrice,
    String currency,
  ) {
    switch (currency) {
      case 'BDT':
        return krwPrice * 0.09;

      case 'USD':
        return krwPrice * 0.00075;

      case 'INR':
        return krwPrice * 0.063;

      case 'EUR':
        return krwPrice * 0.00064;

      case 'KRW':
      default:
        return krwPrice;
    }
  }

  // =========================================================
  // FORMAT PRICE
  // =========================================================

  String _formatPrice(
    double krwPrice,
    String currency,
  ) {
    final convertedPrice = _convertPrice(
      krwPrice,
      currency,
    );

    final symbol = _currencySymbol(currency);

    if (currency == 'KRW') {
      return '$symbol${convertedPrice.toStringAsFixed(0)}';
    }

    return '$symbol${convertedPrice.toStringAsFixed(2)}';
  }

  // =========================================================
  // FAVORITE REFERENCE
  // =========================================================

  DocumentReference<Map<String, dynamic>> _favoriteReference(
    String userId,
    String productId,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(productId);
  }

  // =========================================================
  // ADD / REMOVE FAVORITE
  // =========================================================

  Future<void> _toggleFavorite({
    required User user,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    final favoriteRef = _favoriteReference(
      user.uid,
      productId,
    );

    try {
      final favoriteSnapshot = await favoriteRef.get();

      if (favoriteSnapshot.exists) {
        await favoriteRef.delete();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from Favorites'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        final name =
            productData['name']?.toString() ??
                'Unnamed Product';

        final imageUrl =
            productData['imageUrl']?.toString() ?? '';

        final category =
            productData['category']?.toString() ?? '';

        final price =
            productData['price'] is num
                ? (productData['price'] as num).toDouble()
                : 0.0;

        await favoriteRef.set({
          'productId': productId,
          'productName': name,
          'productImageUrl': imageUrl,
          'category': category,
          'price': price,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to Favorites ❤️'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update Favorites: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // OPEN PRODUCT DETAILS
  // =========================================================

  void _openProductDetails({
    required String productId,
    required Map<String, dynamic> product,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          productId: productId,
          product: product,
        ),
      ),
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION
  // =========================================================

  Future<void> _onNavTap(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      return;
    }

    if (index == 1) {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const CategoriesPage(),
        ),
      );

      if (result != null && mounted) {
        final matchIndex = categories.indexOf(result);

        if (matchIndex != -1) {
          setState(() {
            _selectedCategory = matchIndex;
          });
        }
      }

      if (mounted) {
        setState(() {
          _selectedIndex = 0;
        });
      }

      return;
    }

    if (index == 2) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NewsFeedPage(),
        ),
      );

      if (mounted) {
        setState(() {
          _selectedIndex = 0;
        });
      }

      return;
    }

    if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CartPage(),
        ),
      );

      if (mounted) {
        setState(() {
          _selectedIndex = 0;
        });
      }

      return;
    }

    if (index == 4) {
      final currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UserProfilePage(),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    }
  }

  // =========================================================
  // OPEN VIDEOS
  // =========================================================

  void _openVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewsFeedPage(),
      ),
    );
  }

  // =========================================================
  // OPEN ACCOUNT
  // =========================================================

  void _openAccount(bool isLoggedIn) {
    if (isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserProfilePage(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final isLoggedIn = user != null;

        return ValueListenableBuilder<String>(
          valueListenable: AppSettings.currency,
          builder: (
            context,
            currency,
            child,
          ) {
            return Scaffold(
              // =================================================
              // DRAWER
              // =================================================

              drawer: Drawer(
                child: SafeArea(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DrawerHeader(
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'BuyNova',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.person_outline,
                        ),
                        title: const Text('Account'),
                        onTap: () {
                          Navigator.pop(context);
                          _openAccount(isLoggedIn);
                        },
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.home_outlined,
                        ),
                        title: const Text('Home'),
                        onTap: () {
                          Navigator.pop(context);

                          setState(() {
                            _selectedIndex = 0;
                          });
                        },
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.category_outlined,
                        ),
                        title: const Text('Categories'),
                        onTap: () async {
                          Navigator.pop(context);

                          final result =
                              await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CategoriesPage(),
                            ),
                          );

                          if (result != null && mounted) {
                            final matchIndex =
                                categories.indexOf(result);

                            if (matchIndex != -1) {
                              setState(() {
                                _selectedCategory =
                                    matchIndex;
                              });
                            }
                          }
                        },
                      ),

                      if (isLoggedIn)
                        ListTile(
                          leading: const Icon(
                            Icons.add_circle_outline,
                          ),
                          title: const Text(
                            'Add Product',
                          ),
                          onTap: () {
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddProductPage(),
                              ),
                            );
                          },
                        ),

                      // =================================================
                      // VIDEOS
                      // =================================================

                      ListTile(
                        leading: const Icon(
                          Icons.video_library_outlined,
                        ),
                        title: const Text('Videos'),
                        subtitle: const Text(
                          'Watch Reels & Videos',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _openVideos();
                        },
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.shopping_cart_outlined,
                        ),
                        title: const Text('Cart'),
                        onTap: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CartPage(),
                            ),
                          );
                        },
                      ),

                      // =================================================
                      // SETTINGS
                      // =================================================

                      ListTile(
                        leading: const Icon(
                          Icons.settings_outlined,
                        ),
                        title: const Text('Settings'),
                        onTap: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SettingsPage(),
                            ),
                          );
                        },
                      ),

                      if (isLoggedIn)
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                          ),
                          title: const Text('Logout'),
                          onTap: () async {
                            Navigator.pop(context);

                            await FirebaseAuth
                                .instance
                                .signOut();
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // =================================================
              // APP BAR
              // =================================================

              appBar: AppBar(
                backgroundColor: Colors.redAccent,
                elevation: 0,

                leading: Builder(
                  builder: (context) {
                    return IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
                  },
                ),

                title: const Text(
                  'BuyNova',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),

                actions: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: 2,
                      ),
                      child: Text(
                        _currencySymbol(currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: user == null
                        ? null
                        : FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('cart')
                            .snapshots(),

                    builder: (
                      context,
                      cartSnapshot,
                    ) {
                      int cartCount = 0;

                      for (final doc
                          in cartSnapshot.data?.docs ?? []) {
                        final data =
                            doc.data()
                                as Map<String, dynamic>;

                        final qty =
                            data['quantity'] is num
                                ? (data['quantity'] as num)
                                    .toInt()
                                : 1;

                        cartCount += qty;
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
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

                          if (cartCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding:
                                    const EdgeInsets.all(3),
                                decoration:
                                    const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                constraints:
                                    const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$cartCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color:
                                        Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              // =================================================
              // BODY
              // =================================================

              body: Column(
                children: [
                  // =================================================
                  // SEARCH
                  // =================================================

                  Container(
                    color: Colors.redAccent,
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      12,
                    ),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(21),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // =================================================
                  // CATEGORIES
                  // =================================================

                  Container(
                    height: 58,
                    color: Colors.white,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics:
                          const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final isSelected =
                            _selectedCategory == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 200,
                            ),
                            margin:
                                const EdgeInsets.symmetric(
                              horizontal: 5,
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.redAccent
                                  : Colors.grey.shade100,
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.redAccent
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                categories[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // =================================================
                  // PRODUCTS
                  // =================================================

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .snapshots(),

                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Failed to load products',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
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
                            snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No products found yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        // =================================================
                        // FAVORITES
                        // =================================================

                        return StreamBuilder<QuerySnapshot>(
                          stream: user == null
                              ? null
                              : FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('favorites')
                                  .snapshots(),

                          builder: (
                            context,
                            favoriteSnapshot,
                          ) {
                            final favoriteIds =
                                <String>{};

                            for (final favoriteDoc
                                in favoriteSnapshot
                                        .data?.docs ??
                                    []) {
                              favoriteIds.add(
                                favoriteDoc.id,
                              );
                            }

                            return GridView.builder(
                              padding:
                                  const EdgeInsets.all(8),

                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),

                              itemCount: docs.length,

                              itemBuilder:
                                  (context, index) {
                                final productDoc =
                                    docs[index];

                                final data =
                                    productDoc.data()
                                        as Map<String,
                                            dynamic>;

                                final productId =
                                    productDoc.id;

                                final name =
                                    data['name']
                                            ?.toString() ??
                                        'Unnamed Product';

                                final rawPrice =
                                    data['price'] is num
                                        ? (data['price']
                                                as num)
                                            .toDouble()
                                        : 0.0;

                                final displayPrice =
                                    _formatPrice(
                                  rawPrice,
                                  currency,
                                );

                                final imageUrl =
                                    data['imageUrl']
                                        ?.toString();

                                final isFavorite =
                                    favoriteIds.contains(
                                  productId,
                                );

                                // =================================================
                                // PRODUCT CARD
                                // =================================================

                                return Card(
                                  elevation: 2,
                                  clipBehavior:
                                      Clip.antiAlias,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      10,
                                    ),
                                  ),

                                  child: InkWell(
                                    onTap: () {
                                      _openProductDetails(
                                        productId:
                                            productId,
                                        product: data,
                                      );
                                    },

                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        // =================================================
                                        // IMAGE
                                        // =================================================

                                        Expanded(
                                          child: Stack(
                                            children: [
                                              Container(
                                                width:
                                                    double.infinity,
                                                decoration:
                                                    BoxDecoration(
                                                  color: Colors
                                                      .grey[300],
                                                ),
                                                child:
                                                    imageUrl !=
                                                                null &&
                                                            imageUrl
                                                                .isNotEmpty
                                                        ? Image
                                                            .network(
                                                            imageUrl,
                                                            fit: BoxFit
                                                                .cover,
                                                            width:
                                                                double.infinity,
                                                            height:
                                                                double.infinity,
                                                            errorBuilder:
                                                                (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return const Center(
                                                                child:
                                                                    Icon(
                                                                  Icons
                                                                      .image,
                                                                  size:
                                                                      50,
                                                                  color:
                                                                      Colors.grey,
                                                                ),
                                                              );
                                                            },
                                                          )
                                                        : const Center(
                                                            child:
                                                                Icon(
                                                              Icons
                                                                  .image,
                                                              size:
                                                                  50,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                              ),

                                              // =================================================
                                              // FAVORITE BUTTON
                                              // =================================================

                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child:
                                                    Material(
                                                  color: Colors
                                                      .white,
                                                  shape:
                                                      const CircleBorder(),
                                                  elevation:
                                                      2,
                                                  child:
                                                      InkWell(
                                                    customBorder:
                                                        const CircleBorder(),

                                                    onTap:
                                                        () async {
                                                      final currentUser =
                                                          user;

                                                      if (currentUser ==
                                                          null) {
                                                        await Navigator
                                                            .push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    const LoginPage(),
                                                          ),
                                                        );
                                                        return;
                                                      }

                                                      await _toggleFavorite(
                                                        user:
                                                            currentUser,
                                                        productId:
                                                            productId,
                                                        productData:
                                                            data,
                                                      );
                                                    },

                                                    child:
                                                        Padding(
                                                      padding:
                                                          const EdgeInsets
                                                              .all(
                                                        7,
                                                      ),
                                                      child:
                                                          Icon(
                                                        isFavorite
                                                            ? Icons
                                                                .favorite
                                                            : Icons
                                                                .favorite_border,
                                                        color: isFavorite
                                                            ? Colors
                                                                .redAccent
                                                            : Colors
                                                                .grey,
                                                        size:
                                                            21,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // =================================================
                                        // PRODUCT INFO
                                        // =================================================

                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .all(
                                            8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                name,
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .bold,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                              ),

                                              const SizedBox(
                                                height: 4,
                                              ),

                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child:
                                                        Text(
                                                      displayPrice,
                                                      style:
                                                          const TextStyle(
                                                        color:
                                                            Colors.redAccent,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            16,
                                                      ),
                                                      maxLines:
                                                          1,
                                                      overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                    ),
                                                  ),

                                                  const SizedBox(
                                                    width: 5,
                                                  ),

                                                  // =================================================
                                                  // ADD TO CART
                                                  // =================================================

                                                  InkWell(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                      20,
                                                    ),

                                                    onTap:
                                                        () async {
                                                      final currentUser =
                                                          user;

                                                      if (currentUser ==
                                                          null) {
                                                        await Navigator
                                                            .push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    const LoginPage(),
                                                          ),
                                                        );
                                                        return;
                                                      }

                                                      await CartService
                                                          .addItem(
                                                        id:
                                                            productId,
                                                        name:
                                                            name,
                                                        price:
                                                            rawPrice,
                                                        imageUrl:
                                                            imageUrl,
                                                      );

                                                      if (!context
                                                          .mounted) {
                                                        return;
                                                      }

                                                      ScaffoldMessenger
                                                          .of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content:
                                                              Text(
                                                            '$name added to cart',
                                                          ),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          duration:
                                                              const Duration(
                                                            seconds:
                                                                1,
                                                          ),
                                                        ),
                                                      );
                                                    },

                                                    child:
                                                        Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .all(
                                                        6,
                                                      ),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: Colors
                                                            .redAccent,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          20,
                                                        ),
                                                      ),
                                                      child:
                                                          const Icon(
                                                        Icons
                                                            .add_shopping_cart,
                                                        size:
                                                            16,
                                                        color: Colors
                                                            .white,
                                                      ),
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
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              // =================================================
              // SIGN IN BANNER
              // =================================================

              bottomSheet: isLoggedIn
                  ? null
                  : Container(
                      color: Colors.orangeAccent,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Sign in for best experience!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          ElevatedButton(
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.white,
                              foregroundColor:
                                  Colors.orangeAccent,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginPage(),
                                ),
                              );
                            },
                            child:
                                const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),

              // =================================================
              // BOTTOM NAVIGATION
              // =================================================

              bottomNavigationBar:
                  BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onNavTap,
                selectedItemColor:
                    Colors.redAccent,
                unselectedItemColor:
                    Colors.grey,
                type:
                    BottomNavigationBarType.fixed,

                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),

                  BottomNavigationBarItem(
                    icon: Icon(Icons.category),
                    label: 'Categories',
                  ),

                  BottomNavigationBarItem(
                    icon: Icon(Icons.video_library),
                    label: 'Videos',
                  ),

                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.shopping_cart_outlined,
                    ),
                    label: 'Cart',
                  ),

                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
