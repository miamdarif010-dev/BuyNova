import 'package:flutter/material.dart';

class ReturnRefundPage extends StatelessWidget {
  const ReturnRefundPage({super.key});

  void _showInfo(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _item({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return & Refund'),
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
                  Icons.assignment_return_outlined,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(height: 12),
                Text(
                  'Return & Refund',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage returns, refunds and related requests.',
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
            'Return & Refund',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _item(
            context: context,
            icon: Icons.add_circle_outline,
            title: 'Request a Return',
            subtitle: 'Start a return request for an eligible order.',
            onTap: () {
              _showInfo(
                context,
                'Return Request',
                'Return requests will be connected to your orders here.',
              );
            },
          ),

          _item(
            context: context,
            icon: Icons.currency_exchange,
            title: 'Request a Refund',
            subtitle: 'Request a refund for an eligible order.',
            onTap: () {
              _showInfo(
                context,
                'Refund Request',
                'Refund requests will be connected to your orders here.',
              );
            },
          ),

          _item(
            context: context,
            icon: Icons.pending_actions_outlined,
            title: 'My Return & Refund Requests',
            subtitle: 'Check the status of your requests.',
            onTap: () {
              _showInfo(
                context,
                'My Requests',
                'Your return and refund requests will appear here.',
              );
            },
          ),

          const SizedBox(height: 18),

          const Text(
            'Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _item(
            context: context,
            icon: Icons.policy_outlined,
            title: 'Return Policy',
            subtitle: 'Learn about BuyNova return conditions.',
            onTap: () {
              _showInfo(
                context,
                'Return Policy',
                'Return policy details will be added here.',
              );
            },
          ),

          _item(
            context: context,
            icon: Icons.payments_outlined,
            title: 'Refund Policy',
            subtitle: 'Learn how refunds are processed.',
            onTap: () {
              _showInfo(
                context,
                'Refund Policy',
                'Refund policy details will be added here.',
              );
            },
          ),

          _item(
            context: context,
            icon: Icons.help_outline,
            title: 'Return & Refund FAQ',
            subtitle: 'Find answers to common questions.',
            onTap: () {
              _showInfo(
                context,
                'FAQ',
                'Return and refund frequently asked questions will be added here.',
              );
            },
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Return and refund eligibility may depend on the product, seller and order status.',
                    style: TextStyle(
                      fontSize: 13,
                    ),
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
