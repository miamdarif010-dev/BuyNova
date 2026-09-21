import 'package:flutter/material.dart';

import 'favorites_page.dart';
import 'cart_page.dart';
import 'my_orders_page.dart';
import 'buyer_support_page.dart';
import 'notifications_page.dart';
import 'buyer_messages_page.dart';
import 'news_feed_page.dart';

class BuyerPage extends StatelessWidget {
  const BuyerPage({super.key});

  // =========================================================
  // OPEN VIDEOS
  // =========================================================

  void _openVideos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NewsFeedPage(),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buyer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // HEADER
            // =================================================

            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buyer Account',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Shop products, manage orders and '
                            'enjoy BuyNova services.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // SHOPPING
            // =================================================

            const Text(
              'Shopping',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _buyerItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle:
                  'View your latest BuyNova notifications.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const NotificationsPage(),
                  ),
                );
              },
            ),

            _buyerItem(
              context,
              icon: Icons.message_outlined,
              title: 'Messages',
              subtitle:
                  'Chat with sellers and manage conversations.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const BuyerMessagesPage(),
                  ),
                );
              },
            ),

            _buyerItem(
              context,
              icon: Icons.favorite_border,
              title: 'Favorites',
              subtitle:
                  'View products you saved as favorites.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const FavoritesPage(),
                  ),
                );
              },
            ),

            _buyerItem(
              context,
              icon: Icons.shopping_cart_outlined,
              title: 'Cart',
              subtitle:
                  'View products added to your cart.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartPage(),
                  ),
                );
              },
            ),

            _buyerItem(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              subtitle:
                  'Track and manage your orders.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MyOrdersPage(),
                  ),
                );
              },
            ),

            // =================================================
            // VIDEOS
            // =================================================

            _buyerItem(
              context,
              icon: Icons.video_library_outlined,
              title: 'Videos',
              subtitle:
                  'Watch, upload and manage your BuyNova videos.',
              onTap: () {
                _openVideos(context);
              },
            ),

            const SizedBox(height: 18),

            // =================================================
            // SUPPORT
            // =================================================

            const Text(
              'Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            _buyerItem(
              context,
              icon: Icons.support_agent_outlined,
              title: 'Help & Support',
              subtitle:
                  'Get help with your BuyNova account and orders.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const BuyerSupportPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUYER ITEM
  // =========================================================

  Widget _buyerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}
