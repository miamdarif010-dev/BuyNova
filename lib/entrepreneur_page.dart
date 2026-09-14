import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EntrepreneurPage extends StatefulWidget {
  const EntrepreneurPage({super.key});

  @override
  State<EntrepreneurPage> createState() => _EntrepreneurPageState();
}

class _EntrepreneurPageState extends State<EntrepreneurPage> {
  bool _isLoading = true;

  String _status = 'none';
  String _entrepreneurId = '';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadEntrepreneurData();
  }

  // =========================================================
  // LOAD ENTREPRENEUR DATA
  // =========================================================

  Future<void> _loadEntrepreneurData() async {
    final user = currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};

        if (mounted) {
          setState(() {
            _status =
                data['entrepreneurStatus']?.toString() ?? 'none';

            _entrepreneurId =
                data['entrepreneurId']?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Entrepreneur loading error: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // BECOME ENTREPRENEUR
  // =========================================================

  Future<void> _becomeEntrepreneur() async {
    final user = currentUser;

    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Become an Entrepreneur'),
          content: const Text(
            'Do you want to become a BuyNova Entrepreneur / Reseller?\n\n'
            'After sending the request, an admin will review your application.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': user.displayName ?? '',
          'email': user.email,
          'entrepreneurStatus': 'pending',
          'entrepreneurRequestedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _status = 'pending';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Entrepreneur request sent! Waiting for admin approval.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request failed: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // COMMON MENU ITEM
  // =========================================================

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 3,
        ),
        leading: Icon(
          icon,
          color: color,
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

  // =========================================================
  // APPROVED DASHBOARD
  // =========================================================

  Widget _approvedView() {
    return Column(
      children: [
        Card(
          elevation: 0,
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Icon(
                  Icons.verified,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Entrepreneur Account Approved',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_entrepreneurId.isNotEmpty)
                  Text(
                    'Entrepreneur ID: $_entrepreneurId',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        _menuItem(
          icon: Icons.storefront_outlined,
          title: 'My Store',
          onTap: () {
            _comingSoon('My Store');
          },
        ),

        _menuItem(
          icon: Icons.add_business_outlined,
          title: 'Add Products to My Store',
          onTap: () {
            _comingSoon('Add Products to My Store');
          },
        ),

        _menuItem(
          icon: Icons.inventory_2_outlined,
          title: 'My Reseller Products',
          onTap: () {
            _comingSoon('My Reseller Products');
          },
        ),

        _menuItem(
          icon: Icons.attach_money,
          title: 'My Profit',
          onTap: () {
            _comingSoon('My Profit');
          },
        ),

        _menuItem(
          icon: Icons.shopping_bag_outlined,
          title: 'Reseller Orders',
          onTap: () {
            _comingSoon('Reseller Orders');
          },
        ),

        _menuItem(
          icon: Icons.people_outline,
          title: 'Connected Sellers',
          onTap: () {
            _comingSoon('Connected Sellers');
          },
        ),
      ],
    );
  }

  // =========================================================
  // COMING SOON
  // =========================================================

  void _comingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // STATUS VIEW
  // =========================================================

  Widget _content() {
    if (_status == 'approved') {
      return _approvedView();
    }

    if (_status == 'pending') {
      return Card(
        elevation: 0,
        color: Colors.orange.shade50,
        child: const ListTile(
          leading: Icon(
            Icons.hourglass_top,
            color: Colors.orange,
          ),
          title: Text(
            'Entrepreneur request pending',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'An admin is reviewing your request.',
          ),
        ),
      );
    }

    if (_status == 'rejected') {
      return Card(
        elevation: 0,
        color: Colors.red.shade50,
        child: ListTile(
          leading: const Icon(
            Icons.cancel_outlined,
            color: Colors.red,
          ),
          title: const Text(
            'Entrepreneur request rejected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Tap below to request again.',
          ),
          trailing: ElevatedButton(
            onPressed: _becomeEntrepreneur,
            child: const Text('Request Again'),
          ),
        ),
      );
    }

    return _menuItem(
      icon: Icons.business_center_outlined,
      title: 'Become an Entrepreneur',
      onTap: _becomeEntrepreneur,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Entrepreneur',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
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
                          CircleAvatar(
                            radius: 30,
                            child: const Icon(
                              Icons.business_center,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName?.isNotEmpty == true
                                      ? user!.displayName!
                                      : 'Entrepreneur',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
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

                  const Text(
                    'ENTREPRENEUR / RESELLER',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Find products from BuyNova sellers, '
                    'add them to your store, set your own selling price, '
                    'and earn profit from each sale.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _content(),

                  const SizedBox(height: 25),

                  Card(
                    elevation: 0,
                    color: Colors.blue.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Business flow:\n'
                              'Seller → BuyNova → Entrepreneur → Customer',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
