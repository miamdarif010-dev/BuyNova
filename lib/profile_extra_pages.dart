import 'package:flutter/material.dart';

// =========================================================
// SHARED BASE PAGE
// =========================================================

class _BasePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const _BasePage({
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 72,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// SELLER PAGES
// =========================================================

class ShopProfilePage extends StatelessWidget {
  const ShopProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      title: 'Shop Profile',
      icon: Icons.store_outlined,
      message:
          'Your shop name, logo and description will appear here.',
    );
  }
}

class ShopLocationPage extends StatelessWidget {
  const ShopLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      title: 'Shop Location',
      icon: Icons.location_on_outlined,
      message:
          'Set and manage your shop address here.',
    );
  }
}

class SalesOrdersPage extends StatelessWidget {
  const SalesOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      title: 'Sales / Orders',
      icon: Icons.receipt_long_outlined,
      message:
          'Orders placed for your products will appear here.',
    );
  }
}

// =========================================================
// RESELLER PAGES
// =========================================================

class ResellerOrdersPage extends StatelessWidget {
  const ResellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      title: 'Reseller Orders',
      icon: Icons.receipt_long_outlined,
      message:
          'Orders you placed as a reseller will appear here.',
    );
  }
}

class ResellerProfitPage extends StatelessWidget {
  const ResellerProfitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      title: 'My Profit',
      icon: Icons.monetization_on_outlined,
      message:
          'Your reseller profit summary will appear here.',
    );
  }
}

class ResellerMessagesPage extends StatelessWidget {
  const ResellerMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      title: 'Messages',
      icon: Icons.message_outlined,
      message:
          'Your reseller messages will appear here.',
    );
  }
}

// =========================================================
// EARN & REWARDS PAGES
// =========================================================

class SellerVideoRewardsPage extends StatelessWidget {
  const SellerVideoRewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      title: 'Seller Video Rewards',
      icon: Icons.video_library_outlined,
      message:
          'Rewards for watching seller videos will appear here.',
    );
  }
}

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BasePage(
      title: 'Referral',
      icon: Icons.group_add_outlined,
      message:
          'Invite friends and track your referral rewards here.',
    );
  }
}
