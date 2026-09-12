import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import 'user_profile_page.dart';
import 'add_product_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<String> categories = [
    'All',
    'Electronics',
    'Fashion',
    'Home',
    'Beauty',
    'Sports',
    'Toys'
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 4) {
      // Profile tab
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfilePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final isLoggedIn = user != null;

        return Scaffold(
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.redAccent),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag, color: Colors.white, size: 32),
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
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Home'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: const Text('Categories'),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Account'),
                    onTap: () {
                      Navigator.pop(context);
                      if (isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const UserProfilePage()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      }
                    },
                  ),
                  if (isLoggedIn)
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Add Product'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddProductPage()),
                        );
                      },
                    ),
                  if (isLoggedIn)
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: () async {
                        Navigator.pop(context);
                        await FirebaseAuth.instance.signOut();
                      },
                    ),
                ],
              ),
            ),
          ),
          appBar: AppBar(
            backgroundColor: Colors.redAccent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
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
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Container(
                color: Colors.redAccent,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),

              // Horizontal Categories
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: Chip(
                        label: Text(categories[index]),
                        backgroundColor: index == 0 ? Colors.redAccent : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: index == 0 ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Product Grid from Firestore
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Failed to load products'),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No products found yet'),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final name = data['name']?.toString() ?? 'Unnamed Product';
                        final price = data['price'] is num
                            ? (data['price'] as num).toStringAsFixed(2)
                            : '0.00';
                        final imageUrl = data['imageUrl']?.toString();

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                  ),
                                  child: (imageUrl != null && imageUrl.isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(10),
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Center(
                                              child: Icon(Icons.image,
                                                  size: 50, color: Colors.grey),
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(Icons.image,
                                              size: 50, color: Colors.grey),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$$price',
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating Sign-in Banner (only when logged out)
          bottomSheet: isLoggedIn
              ? null
              : Container(
                  color: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sign in for best experience!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orangeAccent,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ),

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onNavTap,
            selectedItemColor: Colors.redAccent,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categories'),
              BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favorites'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}
