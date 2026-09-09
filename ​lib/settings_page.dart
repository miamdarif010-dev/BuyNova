import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_page.dart';
import 'add_product_page.dart';
import 'login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // ফায়ারবেস থেকে সরাসরি সাইন আউট (লগআউট) করার ফানশন
  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF326295),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // বর্তমান ইউজারের ইমেইল হেডারে দেখাবে
          Card(
            color: const Color(0xFFEBF3FA),
            elevation: 0,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF326295),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: const Text(
                'Logged in as',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              subtitle: Text(
                user?.email ?? 'No User',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ১. প্রোফাইল অপশন
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF326295)),
            title: const Text('Profile'),
            subtitle: const Text('View and edit your personal information'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserProfilePage()),
              );
            },
          ),
          const Divider(),

          // ২. প্রোডাক্ট অ্যাড অপশন
          ListTile(
            leading: const Icon(Icons.add_box_outlined, color: Color(0xFF326295)),
            title: const Text('Add Product'),
            subtitle: const Text('Upload new items to the shop'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProductPage()),
              );
            },
          ),
          const Divider(),

          const SizedBox(height: 30),

          // ৩. সাইন আউট (লগআউট) বাটন
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Sign Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
