import 'package:flutter/material.dart';

import 'favorites_page.dart';
import 'cart_page.dart';
import 'my_orders_page.dart';
import 'buyer_support_page.dart';

class BuyerPage extends StatelessWidget {
  const BuyerPage({super.key});

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.redAccent,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }

  void _openPage(
    BuildContext context,
    Widget page,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent,
                  Colors.red.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(height: 12),
                Text(
                  'Welcome to BuyNova',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Shop products, manage your orders and get support.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Shopping',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // FAVORITES
          _menuItem(
            context: context,
            icon: Icons.favorite_border,
            title: 'Favorites',
            subtitle: 'View your saved products.',
            onTap: () {
              _openPage(
                context,
                const FavoritesPage(),
              );
            },
          ),

          // CART
          _menuItem(
            context: context,
            icon: Icons.shopping_cart_outlined,
            title: 'Cart',
            subtitle: 'View and manage your shopping cart.',
            onTap: () {
              _openPage(
                context,
                const CartPage(),
              );
            },
          ),

          // MY ORDERS
          _menuItem(
            context: context,
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            subtitle: 'View orders and track your deliveries.',
            onTap: () {
              _openPage(
                context,
                const MyOrdersPage(),
              );
            },
          ),

          const SizedBox(height: 14),

          const Text(
            'Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // HELP & SUPPORT
          _menuItem(
            context: context,
            icon: Icons.support_agent_outlined,
            title: 'Help & Support',
            subtitle: 'Get help with orders, payments and delivery.',
            onTap: () {
              _openPage(
                context,
                const BuyerSupportPage(),
              );
            },
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              'BuyNova Buyer',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
