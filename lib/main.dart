                                            style:
     import 'package:flutter/material.dart';

void main() {
  runApp(const BuyNovaApp());
}

/* =========================================================
   MODELS
========================================================= */

class Product {
  final String id;
  String name;
  int price;
  String category;
  IconData icon;
  double rating;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
    this.rating = 4.5,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });
}

class Address {
  String name;
  String phone;
  String address;
  String city;

  Address({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
  });
}

class Order {
  final String id;
  final List<CartItem> items;
  final int total;
  final Address address;
  final DateTime date;
  String status;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.address,
    required this.date,
    this.status = 'Order Placed',
  });
}

/* =========================================================
   PRODUCTS
========================================================= */

final List<Product> products = [
  Product(
    id: 'p001',
    name: 'Smart Phone',
    price: 499000,
    category: 'Phones',
    icon: Icons.phone_android,
    rating: 4.8,
  ),
  Product(
    id: 'p002',
    name: 'Smart Watch',
    price: 39900,
    category: 'Watches',
    icon: Icons.watch,
    rating: 4.6,
  ),
  Product(
    id: 'p003',
    name: 'Wireless Earbuds',
    price: 29900,
    category: 'Audio',
    icon: Icons.headphones,
    rating: 4.7,
  ),
  Product(
    id: 'p004',
    name: 'Laptop',
    price: 899000,
    category: 'Electronics',
    icon: Icons.laptop,
    rating: 4.9,
  ),
  Product(
    id: 'p005',
    name: 'Camera',
    price: 299000,
    category: 'Electronics',
    icon: Icons.camera_alt,
    rating: 4.6,
  ),
  Product(
    id: 'p006',
    name: 'Backpack',
    price: 24900,
    category: 'Fashion',
    icon: Icons.backpack,
    rating: 4.4,
  ),
];

/* =========================================================
   PRICE FORMAT
========================================================= */

String formatPrice(int price) {
  return '${price.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      )} ₩';
}

/* =========================================================
   APP
========================================================= */

class BuyNovaApp extends StatelessWidget {
  const BuyNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BuyNova',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginPage(),
    );
  }
}

/* =========================================================
   LOGIN
========================================================= */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool showPassword = false;

  void login() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email এবং Password দিন'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 45),

              CircleAvatar(
                radius: 55,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.shopping_bag_rounded,
                  size: 58,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'BuyNova',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Everything you love, in one place.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                    icon: Icon(
                      showPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: login,
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Demo login: any email + password',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   HOME
========================================================= */

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final List<CartItem> cart = [];
  final List<Address> addresses = [];
  final List<Order> orders = [];
  final Set<String> favorites = {};

  void addToCart(Product product) {
    final existing = cart.where(
      (item) => item.product.id == product.id,
    );

    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      cart.add(
        CartItem(product: product),
      );
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void toggleFavorite(Product product) {
    setState(() {
      if (favorites.contains(product.id)) {
        favorites.remove(product.id);
      } else {
        favorites.add(product.id);
      }
    });
  }

  int get cartCount {
    return cart.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StorePage(
        favorites: favorites,
        onAddToCart: addToCart,
        onFavorite: toggleFavorite,
      ),
      CartPage(
        cart: cart,
        addresses: addresses,
        orders: orders,
        onOrderCreated: () {
          setState(() {});
        },
      ),
      FavoritesPage(
        favorites: favorites,
        onAddToCart: addToCart,
        onFavorite: toggleFavorite,
      ),
      ProfilePage(
        orders: orders,
        addresses: addresses,
      ),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Store',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: true,
              label: Text('$cartCount'),
              child: const Icon(
                Icons.shopping_cart_outlined,
              ),
            ),
            selectedIcon: Badge(
              isLabelVisible: true,
              label: Text('$cartCount'),
              child: const Icon(
                Icons.shopping_cart,
              ),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   STORE
========================================================= */

class StorePage extends StatefulWidget {
  final Set<String> favorites;
  final Function(Product) onAddToCart;
  final Function(Product) onFavorite;

  const StorePage({
    super.key,
    required this.favorites,
    required this.onAddToCart,
    required this.onFavorite,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String selectedCategory = 'All';
  String searchText = '';

  final List<String> categories = [
    'All',
    'Phones',
    'Watches',
    'Audio',
    'Electronics',
    'Fashion',
  ];

  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((product) {
      final matchesCategory =
          selectedCategory == 'All' ||
          product.category == selectedCategory;

      final matchesSearch = product.name
          .toLowerCase()
          .contains(searchText.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: Colors.white,
            title: const Text(
              'BuyNova',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none,
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                8,
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 55,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected =
                      selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 10,
                      top: 8,
                      bottom: 8,
                    ),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                12,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Products',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${filteredProducts.length} items',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (filteredProducts.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product =
                        filteredProducts[index];

                    return ProductCard(
                      product: product,
                      isFavorite:
                          widget.favorites.contains(
                        product.id,
                      ),
                      onAddToCart: () {
                        widget.onAddToCart(product);
                      },
                      onFavorite: () {
                        widget.onFavorite(product);
                      },
                    );
                  },
                  childCount: filteredProducts.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.68,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* =========================================================
   PRODUCT CARD
========================================================= */

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onAddToCart;
  final VoidCallback onFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onAddToCart,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsPage(
                product: product,
                isFavorite: isFavorite,
                onAddToCart: onAddToCart,
                onFavorite: onFavorite,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Icon(
                        product.icon,
                        size: 75,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                    ),

                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                product.category,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 3),
                  Text('${product.rating}'),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                formatPrice(product.price),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 7),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddToCart,
                  icon: const Icon(
                    Icons.add_shopping_cart,
                    size: 18,
                  ),
                  label: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   PRODUCT DETAILS
========================================================= */

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onAddToCart;
  final VoidCallback onFavorite;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onAddToCart,
    required this.onFavorite,
  });

  @override
  State<ProductDetailsPage> createState() =>
      _ProductDetailsPageState();
}

class _ProductDetailsPageState
    extends State<ProductDetailsPage> {
  late bool favorite;

  final List<String> comments = [
    'Very good product!',
    'Looks great.',
  ];

  final commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    favorite = widget.isFavorite;
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  void addComment() {
    final text = commentController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      comments.add(text);
      commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                favorite = !favorite;
              });
              widget.onFavorite();
            },
            icon: Icon(
              favorite
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              widget.product.icon,
              size: 140,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.product.category,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              const SizedBox(width: 5),
              Text(
                '${widget.product.rating}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            formatPrice(widget.product.price),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 55,
            child: FilledButton.icon(
              onPressed: widget.onAddToCart,
              icon: const Icon(
                Icons.shopping_cart,
              ),
              label: const Text(
                'Add to Cart',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Comments',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: addComment,
                icon: const Icon(Icons.send),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...comments.map(
            (comment) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: const Text('Customer'),
                subtitle: Text(comment),
                trailing: const Icon(
                  Icons.favorite_border,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   CART
========================================================= */

class CartPage extends StatefulWidget {
  final List<CartItem> cart;
  final List<Address> addresses;
  final List<Order> orders;
  final VoidCallback onOrderCreated;

  const CartPage({
    super.key,
    required this.cart,
    required this.addresses,
    required this.orders,
    required this.onOrderCreated,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int get subtotal {
    return widget.cart.fold(
      0,
      (sum, item) =>
          sum + item.product.price * item.quantity,
    );
  }

  int get deliveryFee {
    return subtotal == 0 ? 0 : 3000;
  }

  int get total {
    return subtotal + deliveryFee;
  }

  void increase(CartItem item) {
    setState(() {
      item.quantity++;
    });
  }

  void decrease(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        widget.cart.remove(item);
      }
    });
  }

  void checkout() {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          cart: widget.cart,
          addresses: widget.addresses,
          orders: widget.orders,
          total: total,
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
        widget.onOrderCreated();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Cart',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            child: widget.cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    children: [
                      ...widget.cart.map(
                        (item) => Card(
                          margin: const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.grey.shade100,
                                    borderRadius:
                                        BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                  child: Icon(
                                    item.product.icon,
                                    size: 38,
                                    color:
                                        Theme.of(context)
                                            .colorScheme
                                            .primary,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        formatPrice(
                                          item.product.price,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                decrease(
                                                    item),
                                            icon:
                                                const Icon(
                                              Icons
                                                  .remove_circle_outline,
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style:
                                                const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                increase(
                                                    item),
                                            icon:
                                                const Icon(
                                              Icons
                                                  .add_circle_outline,
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
                        ),
                      ),

                      const SizedBox(height: 10),

                      Card(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _priceRow(
                                'Subtotal',
                                formatPrice(subtotal),
                              ),
                              const SizedBox(height: 8),
                              _priceRow(
                                'Delivery',
                                formatPrice(deliveryFee),
                              ),
                              const Divider(height: 25),
                              _priceRow(
                                'Total',
                                formatPrice(total),
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: 55,
                        child: FilledButton(
                          onPressed: checkout,
                          child: const Text(
                            'Checkout',
                            style: TextStyle(
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),
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
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 18 : 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 18 : 15,
          ),
        ),
      ],
    );
  }
}

/* =========================================================
   CHECKOUT
========================================================= */

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cart;
  final List<Address> addresses;
  final List<Order> orders;
  final int total;

  const CheckoutPage({
    super.key,
    required this.cart,
    required this.addresses,
    required this.orders,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() =>
      _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();

  String payment = 'Cash on Delivery';

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    super.dispose();
  }

  void placeOrder() {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সব তথ্য পূরণ করুন'),
        ),
      );
      return;
    }

    final address = Address(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      city: cityController.text.trim(),
    );

    widget.addresses.add(address);

    final order = Order(
      id: 'BN-${DateTime.now().millisecondsSinceEpoch}',
      items: widget.cart
          .map(
            (item) => CartItem(
              product: item.product,
              quantity: item.quantity,
            ),
          )
          .toList(),
      total: widget.total,
      address: address,
      date: DateTime.now(),
    );

    widget.orders.insert(0, order);

    widget.cart.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Successful 🎉'),
          content: Text(
            'Your order ${order.id} has been placed.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.home_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon:
                  Icon(Icons.location_city_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          RadioListTile<String>(
            value: 'Cash on Delivery',
            groupValue: payment,
            title: const Text('Cash on Delivery'),
            onChanged: (value) {
              setState(() {
                payment = value!;
              });
            },
          ),

          RadioListTile<String>(
            value: 'Online Payment',
            groupValue: payment,
            title: const Text('Online Payment'),
            onChanged: (value) {
              setState(() {
                payment = value!;
              });
            },
          ),

          const SizedBox(height: 15),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    formatPrice(widget.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 55,
            child: FilledButton(
              onPressed: placeOrder,
              child: const Text(
                'Place Order',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   FAVORITES
========================================================= */

class FavoritesPage extends StatelessWidget {
  final Set<String> favorites;
  final Function(Product) onAddToCart;
  final Function(Product) onFavorite;

  const FavoritesPage({
    super.key,
    required this.favorites,
    required this.onAddToCart,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteProducts = products
        .where(
          (product) => favorites.contains(product.id),
        )
        .toList();

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            child: favoriteProducts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'No favorite products',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding:
                        const EdgeInsets.all(12),
                    itemCount:
                        favoriteProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                    itemBuilder: (context, index) {
                      final product =
                          favoriteProducts[index];

                      return ProductCard(
                        product: product,
                        isFavorite: true,
                        onAddToCart: () =>
                            onAddToCart(product),
                        onFavorite: () =>
                            onFavorite(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   PROFILE
========================================================= */

class ProfilePage extends StatelessWidget {
  final List<Order> orders;
  final List<Address> addresses;

  const ProfilePage({
    super.key,
    required this.orders,
    required this.addresses,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),

          const CircleAvatar(
            radius: 48,
            child: Icon(
              Icons.person,
              size: 50,
            ),
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              'BuyNova Customer',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 5),

          const Center(
            child: Text(
              'customer@buynova.com',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 25),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.receipt_long_outlined,
              ),
              title: const Text('My Orders'),
              subtitle:
                  Text('${orders.length} order(s)'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderHistoryPage(
                      orders: orders,
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
              ),
              title: const Text('My Addresses'),
              subtitle:
                  Text('${addresses.length} saved'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddressPage(
                      addresses: addresses,
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.settings_outlined,
              ),
              title: const Text('Settings'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.help_outline,
              ),
              title: const Text('Help & Support'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.logout,
              ),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LoginPage(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   ADDRESS PAGE
========================================================= */

class AddressPage extends StatelessWidget {
  final List<Address> addresses;

  const AddressPage({
    super.key,
    required this.addresses,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
      ),
      body: addresses.isEmpty
          ? const Center(
              child: Text(
                'No saved addresses',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address =
                    addresses[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.location_on,
                    ),
                    title: Text(
                      address.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${address.phone}\n'
                      '${address.address}\n'
                      '${address.city}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

/* =========================================================
   ORDER HISTORY
========================================================= */

class OrderHistoryPage extends StatelessWidget {
  final List<Order> orders;

  const OrderHistoryPage({
    super.key,
    required this.orders,
  });

  String formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(
                        Icons.shopping_bag,
                      ),
                    ),
                    title: Text(
                      order.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${order.items.length} item(s)\n'
                      '${formatDate(order.date)}\n'
                      '${order.status}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      formatPrice(order.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsPage(
                            order: order,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

/* =========================================================
   ORDER DETAILS
========================================================= */

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  const OrderDetailsPage({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Order ID: ${order.id}',
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Status: ${order.status}',
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Date: ${order.date.year}-'
                    '${order.date.month.toString().padLeft(2, '0')}-'
                    '${order.date.day.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Products',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ...order.items.map(
            (item) => Card(
              child: ListTile(
                leading: Icon(
                  item.product.icon,
                ),
                title: Text(
                  item.product.name,
                ),
                subtitle: Text(
                  'Quantity: ${item.quantity}',
                ),
                trailing: Text(
                  formatPrice(
                    item.product.price *
                        item.quantity,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(order.address.name),
                  Text(order.address.phone),
                  Text(order.address.address),
                  Text(order.address.city),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                    formatPrice(order.total),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}                                           const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                increase(
                                                    item),
                                            icon:
                                                const Icon(
                                              Icons
                                                  .add_circle_outline,
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
                        ),
                      ),

                      const SizedBox(height: 10),

                      Card(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _priceRow(
                                'Subtotal',
                                formatPrice(subtotal),
                              ),
                              const SizedBox(height: 8),
                              _priceRow(
                                'Delivery',
                                formatPrice(deliveryFee),
                              ),
                              const Divider(height: 25),
                              _priceRow(
                                'Total',
                                formatPrice(total),
                                bold: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        height: 55,
                        child: FilledButton(
                          onPressed: checkout,
                          child: const Text(
                            'Checkout',
                            style: TextStyle(
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),
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
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 18 : 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 18 : 15,
          ),
        ),
      ],
    );
  }
}

/* =========================================================
   CHECKOUT
========================================================= */

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cart;
  final List<Address> addresses;
  final List<Order> orders;
  final int total;

  const CheckoutPage({
    super.key,
    required this.cart,
    required this.addresses,
    required this.orders,
    required this.total,
  });

  @override
  State<CheckoutPage> createState() =>
      _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();

  String payment = 'Cash on Delivery';

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    super.dispose();
  }

  void placeOrder() {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সব তথ্য পূরণ করুন'),
        ),
      );
      return;
    }

    final address = Address(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      city: cityController.text.trim(),
    );

    widget.addresses.add(address);

    final order = Order(
      id: 'BN-${DateTime.now().millisecondsSinceEpoch}',
      items: widget.cart
          .map(
            (item) => CartItem(
              product: item.product,
              quantity: item.quantity,
            ),
          )
          .toList(),
      total: widget.total,
      address: address,
      date: DateTime.now(),
    );

    widget.orders.insert(0, order);

    widget.cart.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Order Successful 🎉'),
          content: Text(
            'Your order ${order.id} has been placed.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Delivery Address',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.home_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon:
                  Icon(Icons.location_city_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          RadioListTile<String>(
            value: 'Cash on Delivery',
            groupValue: payment,
            title: const Text('Cash on Delivery'),
            onChanged: (value) {
              setState(() {
                payment = value!;
              });
            },
          ),

          RadioListTile<String>(
            value: 'Online Payment',
            groupValue: payment,
            title: const Text('Online Payment'),
            onChanged: (value) {
              setState(() {
                payment = value!;
              });
            },
          ),

          const SizedBox(height: 15),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    formatPrice(widget.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 55,
            child: FilledButton(
              onPressed: placeOrder,
              child: const Text(
                'Place Order',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   FAVORITES
========================================================= */

class FavoritesPage extends StatelessWidget {
  final Set<String> favorites;
  final Function(Product) onAddToCart;
  final Function(Product) onFavorite;

  const FavoritesPage({
    super.key,
    required this.favorites,
    required this.onAddToCart,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteProducts = products
        .where(
          (product) => favorites.contains(product.id),
        )
        .toList();

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            child: favoriteProducts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'No favorite products',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding:
                        const EdgeInsets.all(12),
                    itemCount:
                        favoriteProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                    itemBuilder: (context, index) {
                      final product =
                          favoriteProducts[index];

                      return ProductCard(
                        product: product,
                        isFavorite: true,
                        onAddToCart: () =>
                            onAddToCart(product),
                        onFavorite: () =>
                            onFavorite(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   PROFILE
========================================================= */

class ProfilePage extends StatelessWidget {
  final List<Order> orders;
  final List<Address> addresses;

  const ProfilePage({
    super.key,
    required this.orders,
    required this.addresses,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),

          const CircleAvatar(
            radius: 48,
            child: Icon(
              Icons.person,
              size: 50,
            ),
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              'BuyNova Customer',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 5),

          const Center(
            child: Text(
              'customer@buynova.com',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 25),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.receipt_long_outlined,
              ),
              title: const Text('My Orders'),
              subtitle:
                  Text('${orders.length} order(s)'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrderHistoryPage(
                      orders: orders,
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
              ),
              title: const Text('My Addresses'),
              subtitle:
                  Text('${addresses.length} saved'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddressPage(
                      addresses: addresses,
                    ),
                  ),
                );
              },
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.settings_outlined,
              ),
              title: const Text('Settings'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.help_outline,
              ),
              title: const Text('Help & Support'),
              trailing:
                  const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.logout,
              ),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LoginPage(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   ADDRESS PAGE
========================================================= */

class AddressPage extends StatelessWidget {
  final List<Address> addresses;

  const AddressPage({
    super.key,
    required this.addresses,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
      ),
      body: addresses.isEmpty
          ? const Center(
              child: Text(
                'No saved addresses',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address =
                    addresses[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.location_on,
                    ),
                    title: Text(
                      address.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${address.phone}\n'
                      '${address.address}\n'
                      '${address.city}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

/* =========================================================
   ORDER HISTORY
========================================================= */

class OrderHistoryPage extends StatelessWidget {
  final List<Order> orders;

  const OrderHistoryPage({
    super.key,
    required this.orders,
  });

  String formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(
                        Icons.shopping_bag,
                      ),
                    ),
                    title: Text(
                      order.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${order.items.length} item(s)\n'
                      '${formatDate(order.date)}\n'
                      '${order.status}',
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      formatPrice(order.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OrderDetailsPage(
                            order: order,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

/* =========================================================
   ORDER DETAILS
========================================================= */

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  const OrderDetailsPage({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Order ID: ${order.id}',
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Status: ${order.status}',
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Date: ${order.date.year}-'
                    '${order.date.month.toString().padLeft(2, '0')}-'
                    '${order.date.day.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Products',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ...order.items.map(
            (item) => Card(
              child: ListTile(
                leading: Icon(
                  item.product.icon,
                ),
                title: Text(
                  item.product.name,
                ),
                subtitle: Text(
                  'Quantity: ${item.quantity}',
                ),
                trailing: Text(
                  formatPrice(
                    item.product.price *
                        item.quantity,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(order.address.name),
                  Text(order.address.phone),
                  Text(order.address.address),
                  Text(order.address.city),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                    formatPrice(order.total),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
