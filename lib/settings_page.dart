import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _comingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title - Coming Soon')),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _deleteAccountConfirm(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account. This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    _comingSoon(context, 'Delete Account (full flow)');
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // 1. GENERAL
          _sectionHeader('GENERAL'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _tile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => _comingSoon(context, 'Notifications'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  onTap: () => _comingSoon(context, 'Dark Mode'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  onTap: () => _comingSoon(context, 'Language'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.attach_money,
                  title: 'Currency',
                  onTap: () => _comingSoon(context, 'Currency'),
                ),
              ],
            ),
          ),

          // 2. ACCOUNT & SECURITY
          _sectionHeader('ACCOUNT & SECURITY'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _tile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () => _comingSoon(context, 'Change Password'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  onTap: () => _comingSoon(context, 'Email'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  onTap: () => _comingSoon(context, 'Phone Number'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.security_outlined,
                  title: 'Login & Security',
                  onTap: () => _comingSoon(context, 'Login & Security'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.delete_outline,
                  title: 'Delete Account',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () => _deleteAccountConfirm(context),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.logout,
                  title: 'Logout',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),

          // 3. PRIVACY
          _sectionHeader('PRIVACY'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _tile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & Security',
                  onTap: () => _comingSoon(context, 'Privacy & Security'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Settings',
                  onTap: () => _comingSoon(context, 'Privacy Settings'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.data_usage_outlined,
                  title: 'Data & Personalization',
                  onTap: () => _comingSoon(context, 'Data & Personalization'),
                ),
              ],
            ),
          ),

          // 4. HELP & SUPPORT
          _sectionHeader('HELP & SUPPORT'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _tile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () => _comingSoon(context, 'Help & Support'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.quiz_outlined,
                  title: 'FAQ',
                  onTap: () => _comingSoon(context, 'FAQ'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.contact_support_outlined,
                  title: 'Contact Us',
                  onTap: () => _comingSoon(context, 'Contact Us'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.report_gmailerrorred_outlined,
                  title: 'Report a Problem',
                  onTap: () => _comingSoon(context, 'Report a Problem'),
                ),
              ],
            ),
          ),

          // 5. ABOUT
          _sectionHeader('ABOUT BUYNOVA'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _tile(
                  icon: Icons.info_outline,
                  title: 'About BuyNova',
                  onTap: () => _comingSoon(context, 'About BuyNova'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () => _comingSoon(context, 'Terms & Conditions'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _comingSoon(context, 'Privacy Policy'),
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.star_border,
                  title: 'Rate BuyNova',
                  onTap: () => _comingSoon(context, 'Rate BuyNova'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('App Version', style: TextStyle(fontSize: 15)),
                  trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
