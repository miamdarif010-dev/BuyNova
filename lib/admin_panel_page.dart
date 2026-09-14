import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Only reachable if the logged-in user's email matches kAdminEmail
/// (checked before navigating here â€” see user_profile_page.dart).
const String kAdminEmail = 'miamdarif010@gmail.com';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct(String productId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "$name"? This cannot be undone.'),
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

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
    }
  }

  Future<void> _updateSellerStatus(String uid, String status) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'sellerStatus': status},
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Users'),
            Tab(text: 'Seller Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _productsTab(),
          _usersTab(),
          _sellerRequestsTab(),
        ],
      ),
    );
  }

  // ===========================================================
  // PRODUCTS TAB â€” view/delete any product
  // ===========================================================
  Widget _productsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No products yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final name = data['name']?.toString() ?? 'Unnamed';
            final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;
            final imageUrl = data['imageUrl']?.toString();
            final sellerEmail = data['sellerEmail']?.toString() ?? 'Unknown seller';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                      ? NetworkImage(imageUrl)
                      : null,
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? const Icon(Icons.image, color: Colors.grey)
                      : null,
                ),
                title: Text(name),
                subtitle: Text('\$${price.toStringAsFixed(2)} â€¢ $sellerEmail'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteProduct(doc.id, name),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================
  // USERS TAB â€” view all users
  // ===========================================================
  Widget _usersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No users yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            final name = data['name']?.toString() ?? 'Unnamed User';
            final email = data['email']?.toString() ?? '';
            final sellerStatus = data['sellerStatus']?.toString() ?? 'none';

            Color badgeColor;
            switch (sellerStatus) {
              case 'approved':
                badgeColor = Colors.green;
                break;
              case 'pending':
                badgeColor = Colors.orange;
                break;
              case 'rejected':
                badgeColor = Colors.red;
                break;
              default:
                badgeColor = Colors.grey;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(name),
                subtitle: Text(email),
                trailing: Chip(
                  label: Text(
                    sellerStatus,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: badgeColor,
                  padding: EdgeInsets.zero,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================
  // SELLER REQUESTS TAB â€” approve/reject
  // ===========================================================
  Widget _sellerRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('sellerStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No pending seller requests'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final name = data['name']?.toString() ?? 'Unnamed User';
            final email = data['email']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
                title: Text(name),
                subtitle: Text(email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      tooltip: 'Approve',
                      onPressed: () => _updateSellerStatus(doc.id, 'approved'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Reject',
                      onPressed: () => _updateSellerStatus(doc.id, 'rejected'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
