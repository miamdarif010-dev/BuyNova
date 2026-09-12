import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;

  String _name = '';
  String _phone = '';
  String _profileImageUrl = '';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        setState(() {
          _name = data['name'] ?? '';
          _phone = data['phone'] ?? '';
          _profileImageUrl = data['profileImageUrl'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Profile loading error: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfilePage(),
      ),
    );

    _loadUserData();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pop(context);
  }

  Widget _profileImage() {
    if (_profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundImage: NetworkImage(_profileImageUrl),
      );
    }

    return const CircleAvatar(
      radius: 55,
      child: Icon(
        Icons.person,
        size: 60,
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // PROFILE PICTURE
                  _profileImage(),

                  const SizedBox(height: 14),

                  // NAME
                  Text(
                    _name.isEmpty ? 'User' : _name,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // EMAIL
                  Text(
                    user?.email ?? 'No Email',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // EDIT PROFILE
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _openEditProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // MENU
                  _menuItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat coming soon'),
                        ),
                      );
                    },
                  ),

                  _menuItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Orders',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('My Orders coming soon'),
                        ),
                      );
                    },
                  ),

                  _menuItem(
                    icon: Icons.favorite_border,
                    title: 'Favorites',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Favorites coming soon'),
                        ),
                      );
                    },
                  ),

                  _menuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings coming soon'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // LOGOUT
                  Card(
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: _logout,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
