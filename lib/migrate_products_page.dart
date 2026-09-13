import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// TEMPORARY PAGE â€” used once to migrate old data from the
/// wrongly-named 'Products' collection into the correct
/// lowercase 'products' collection, fixing the 'image' ->
/// 'imageUrl' field name at the same time.
///
/// After running the migration successfully, delete this file
/// and remove its entry from the drawer/settings menu.
class MigrateProductsPage extends StatefulWidget {
  const MigrateProductsPage({super.key});

  @override
  State<MigrateProductsPage> createState() => _MigrateProductsPageState();
}

class _MigrateProductsPageState extends State<MigrateProductsPage> {
  bool _isRunning = false;
  String _log = '';

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _log = 'Starting migration...\n';
    });

    try {
      final oldCollection =
          await FirebaseFirestore.instance.collection('Products').get();

      if (oldCollection.docs.isEmpty) {
        setState(() {
          _log += 'No documents found in old "Products" collection.\n';
          _isRunning = false;
        });
        return;
      }

      setState(() {
        _log += 'Found ${oldCollection.docs.length} product(s) to migrate.\n';
      });

      int migrated = 0;

      for (final doc in oldCollection.docs) {
        final data = doc.data();

        final newData = {
          'name': data['name'] ?? 'Unnamed Product',
          'price': data['price'] ?? 0,
          'description': data['description'] ?? '',
          // old field was 'image', new field is 'imageUrl'
          'imageUrl': data['imageUrl'] ?? data['image'] ?? '',
          'category': data['category'] ?? 'General',
          'sellerId': data['sellerId'],
          'sellerEmail': data['sellerEmail'],
          'rating': data['rating'] ?? 5,
          'reviewCount': data['reviewCount'] ?? data['reviewcount'] ?? 0,
          'stock': data['stock'] ?? 10,
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('products').add(newData);

        migrated++;
        setState(() {
          _log += 'Migrated: ${newData['name']}\n';
        });
      }

      setState(() {
        _log += '\nDone. $migrated product(s) migrated successfully.\n';
        _log += 'You can now delete the old "Products" collection from '
            'the Firebase Console, and remove this migration page.\n';
      });
    } catch (e) {
      setState(() {
        _log += '\nError: $e\n';
      });
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migrate Old Products'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This copies documents from the old "Products" collection '
              'into the correct "products" collection, fixing field names '
              'along the way. Run this once, then delete this page.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _runMigration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: _isRunning
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Run Migration'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty ? 'Log will appear here...' : _log,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
