import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String _email = '';
  String _profileImageUrl = '';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      if (!mounted) return;

      setState(() {
        _email = user.email ?? data['email'] ?? '';
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _profileImageUrl = data['profileImageUrl'] ?? '';
      });
    } catch (e) {
      debugPrint('Profile loading error: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePhoto() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profile photo upload will be added after Firebase Storage is enabled.',
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final user = currentUser;

    if (user == null) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'email': user.email,
          'name': name,
          'phone': phone,
          'profileImageUrl': _profileImageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await user.updateDisplayName(name);
      await user.reload();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _profilePhoto() {
    if (_profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 58,
        backgroundImage: NetworkImage(_profileImageUrl),
      );
    }

    return const CircleAvatar(
      radius: 58,
      child: Icon(
        Icons.person,
        size: 62,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Profile Photo
                  _profilePhoto(),

                  const SizedBox(height: 12),

                  // Change Photo
                  OutlinedButton.icon(
                    onPressed: _changePhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Change Photo'),
                  ),

                  const SizedBox(height: 30),

                  // Name
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Phone
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Email - Locked
                  TextField(
                    controller: TextEditingController(text: _email),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      suffixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                      filled: true,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveChanges,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
