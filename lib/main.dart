import 'package:flutter/material.dart';

void main() {
  runApp(const BuyNovaApp());
}

class BuyNovaApp extends StatelessWidget {
  const BuyNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BuyNova',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// =====================================================
// PRODUCT MODEL
// =====================================================

class Product {
  final String id;
  final String name;
  final int price;
  final String category;
  final IconData icon;
  final double rating;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
    required this.rating,
  });
}

// =====================================================
// SAMPLE PRODUCTS
// =====================================================

final List<Product> products = [
  const Product(
    id: '1',
    name: 'Smart Phone',
    price: 499000,
    category: 'Phones',
    icon: Icons.smartphone,
    rating: 4.8,
  ),
  const Product(
    id: '2',
    name: 'Smart Watch',
    price: 39900,
    category: 'Watches',
    icon: Icons.watch,
    rating: 4.6,
  ),
  const Product(
    id: '3',
    name: 'Wireless Earbuds',
    price: 29900,
    category: 'Audio',
    icon: Icons.headphones,
    rating: 4.7,
  ),
  const Product(
    id: '4',
    name: 'Laptop',
    price: 899000,
    category: 'Electronics',
    icon: Icons.laptop,
    rating: 4.9,
  ),
  const Product(
    id: '5',
    name: 'Camera',
    price: 299000,
    category: 'Electronics',
    icon: Icons.camera_alt,
    rating: 4.5,
  ),
  const Product(
    id: '6',
    name: 'Backpack',
    price: 24900,
    category: 'Fashion',
    icon: Icons.backpack,
    rating: 4.4,
  ),
];

// =====================================================
// LOGIN PAGE
// =====================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_bag,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 15),
              const Text(
                'BuyNova',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Shop Everything You Love'),
              const SizedBox(height: 35),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: login,
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignUpPage(),
                    ),
                  );
                },
                child: const Text('Create New Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SIGN UP PAGE
// =====================================================

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomePage(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// HOME PAGE
// =====================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = 'All';
  String searchText = '';

  final Set<String> favorites = {};
  final List<Product> cart = [];

  List<Product> get filteredProducts {
    return products.where((product) {
      final categoryMatch =
          selectedCategory == 'All' ||
          product.category == selectedCategory;

      final searchMatch =
          product.name.toLowerCase().contains(
                searchText.toLowerCase(),
              );

      return categoryMatch && searchMatch;
    }).toList();
  }

  void addToCart(Product product) {
    setState(() {
      cart.add(product);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      'Phones',
      'Watches',
      'Audio',
      'Electronics',
      'Fashion',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BuyNova',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartPage(cart: cart),
                ),
              );
            },
            icon: Badge(
              label: Text('${cart.length}'),
              isLabelVisible: cart.isNotEmpty,
              child: const Icon(Icons.shopping_cart),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilePage(),
                ),
              );
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            searchText = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
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

          const SizedBox(height: 8),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.70,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final isFavorite =
                    favorites.contains(product.id);

                return Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  product.icon,
                                  size: 80,
                                  color: Colors.blue,
                                ),
                              ),
                              Positioned(
                                right: 5,
                                top: 5,
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (isFavorite) {
                                        favorites.remove(product.id);
                                      } else {
                                        favorites.add(product.id);
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite
                                        ? Colors.red
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          10,
                          8,
                          10,
                          2,
                        ),
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        child: Text(
                          '₩${product.price.toString()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 17,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(product.rating.toString()),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              addToCart(product);
                            },
                            child: const Text('Add to Cart'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// CART PAGE
// =====================================================

class CartPage extends StatefulWidget {
  final List<Product> cart;

  const CartPage({
    super.key,
    required this.cart,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int get subtotal {
    return widget.cart.fold(
      0,
      (sum, product) => sum + product.price,
    );
  }

  @override
  Widget build(BuildContext context) {
    const deliveryFee = 3000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
      ),
      body: widget.cart.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final product = widget.cart[index];

                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(product.icon),
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          '₩${product.price}',
                        ),
                        trailing: IconButton(
                          onPressed: () {
                            setState(() {
                              widget.cart.removeAt(index);
                            });
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text('₩$subtotal'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Delivery'),
                          Text('₩3000'),
                        ],
                      ),
                      const Divider(),
                      Row(
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
                            '₩${subtotal + deliveryFee}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Order placed successfully!',
                                ),
                              ),
                            );
                          },
                          child: const Text('Place Order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// =====================================================
// PROFILE PAGE
// =====================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 45,
            child: Icon(
              Icons.person,
              size: 50,
            ),
          ),
          const SizedBox(height: 15),
          const Center(
            child: Text(
              'BuyNova User',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 25),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('My Address'),
              subtitle: const Text('Add your delivery address'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('My Orders'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
