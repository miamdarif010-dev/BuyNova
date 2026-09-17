import 'package:flutter/material.dart';

import 'cart_page.dart';
import 'my_orders_page.dart';
import 'my_videos_page.dart';
import 'favorites_page.dart';

class BuyerPage extends StatelessWidget {
  const BuyerPage({super.key});

  void _comingSoon(
    BuildContext context,
    String title,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title is not available yet.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: Icon(
          icon,
          color: iconColor,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }

  void _openOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyOrdersPage(),
      ),
    );
  }

  void _openFavorites(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesPage(),
      ),
    );
  }

  void _openCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartPage(),
      ),
    );
  }

  void _openMyVideos(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyVideosPage(),
      ),
    );
  }

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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =========================
            // BUYER HEADER
            // =========================
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent.withValues(
                          alpha: 0.10,
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 30,
                        color: Colors.redAccent,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buyer',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Manage your shopping, orders and favorites.',
                            style: TextStyle(
                              fontSize: 13,
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

            // =========================
            // NOTIFICATIONS
            // =========================
            _menuItem(
              context: context,
              icon: Icons.notifications_none,
              iconColor: Colors.redAccent,
              title: 'Notifications',
              onTap: () {
                _comingSoon(
                  context,
                  'Buyer Notifications',
                );
              },
            ),

            // =========================
            // MY ORDERS
            // =========================
            _menuItem(
              context: context,
              icon: Icons.receipt_long_outlined,
              title: 'My Orders',
              onTap: () {
                _openOrders(context);
              },
            ),

            // =========================
            // FAVORITES
            // =========================
            _menuItem(
              context: context,
              icon: Icons.favorite_border,
              iconColor: Colors.redAccent,
              title: 'Favorites',
              onTap: () {
                _openFavorites(context);
              },
            ),

            // =========================
            // MY CART
            // =========================
            _menuItem(
              context: context,
              icon: Icons.shopping_cart_outlined,
              title: 'My Cart',
              onTap: () {
                _openCart(context);
              },
            ),

            // =========================
            // RECENTLY VIEWED
            // =========================
            _menuItem(
              context: context,
              icon: Icons.history,
              title: 'Recently Viewed',
              onTap: () {
                _comingSoon(
                  context,
                  'Recently Viewed',
                );
              },
            ),

            // =========================
            // COUPONS
            // =========================
            _menuItem(
              context: context,
              icon: Icons.local_offer_outlined,
              title: 'Coupons',
              onTap: () {
                _comingSoon(
                  context,
                  'Coupons',
                );
              },
            ),

            // =========================
            // MY VIDEOS
            // =========================
            _menuItem(
              context: context,
              icon: Icons.video_library_outlined,
              title: 'My Videos',
              onTap: () {
                _openMyVideos(context);
              },
            ),

            // =========================
            // MESSAGES
            // =========================
            _menuItem(
              context: context,
              icon: Icons.message_outlined,
              title: 'Messages',
              onTap: () {
                _comingSoon(
                  context,
                  'Messages',
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
