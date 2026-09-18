import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'favorites_page.dart';
import 'cart_page.dart';
import 'my_orders_page.dart';
import 'buyer_support_page.dart';
import 'notifications_page.dart';

class BuyerPage extends StatefulWidget {
  const BuyerPage({super.key});

  @override
  State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
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
        trailing: trailing ??
            const Icon(
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream<
          QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Widget _notificationMenuItem(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notificationStream(),
      builder: (context, snapshot) {
        int unreadCount = 0;

        if (snapshot.hasData) {
          for (final document in snapshot.data!.docs) {
            final data = document.data();

            final bool isRead =
                data['isRead'] == true ||
                data['read'] == true;

            if (!isRead) {
              unreadCount++;
            }
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.redAccent,
                  ),
                ),

                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        unreadCount > 99
                            ? '99+'
                            : unreadCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              unreadCount == 0
                  ? 'You have no unread notifications.'
                  : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}.',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              _openPage(
                context,
                const NotificationsPage(),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyer'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =========================================================
          // WELCOME
          // =========================================================

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

          // =========================================================
          // SHOPPING
          // =========================================================

          const Text(
            'Shopping',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // =========================================================
          // NOTIFICATIONS
          // =========================================================

          _notificationMenuItem(context),

          // =========================================================
          // FAVORITES
          // =========================================================

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

          // =========================================================
          // CART
          // =========================================================

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

          // =========================================================
          // MY ORDERS
          // =========================================================

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

          // =========================================================
          // SUPPORT
          // =========================================================

          const Text(
            'Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // =========================================================
          // HELP & SUPPORT
          // =========================================================

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

          // =========================================================
          // FOOTER
          // =========================================================

          Center(
            child: Text(
              user == null
                  ? 'BuyNova Buyer'
                  : 'BuyNova Buyer',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
