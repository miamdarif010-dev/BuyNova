import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _methodsRef {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('paymentMethods');
  }

  void _comingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title - Coming Soon')),
    );
  }

  Future<void> _setDefault(String docId) async {
    final ref = _methodsRef;
    if (ref == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await ref.get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == docId});
    }

    await batch.commit();
  }

  Future<void> _deleteMethod(String docId) async {
    final ref = _methodsRef;
    if (ref == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: const Text('Are you sure you want to remove this?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.doc(docId).delete();
    }
  }

  Future<void> _showAddMethodSheet() async {
    if (_uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('Credit / Debit Card'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddCardDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance, color: Colors.green),
                title: const Text('Bank Transfer'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddBankDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android, color: Colors.orange),
                title: const Text('Mobile Payment'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddMobilePaymentDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined, color: Colors.brown),
                title: const Text('Cash on Delivery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _methodsRef?.add({
                    'type': 'cod',
                    'label': 'Cash on Delivery',
                    'isDefault': false,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddCardDialog() async {
    final nameController = TextEditingController();
    final last4Controller = TextEditingController();
    final expiryController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Cardholder Name'),
            ),
            TextField(
              controller: last4Controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Last 4 Digits',
                helperText: 'For your security, only the last 4 digits are saved',
              ),
            ),
            TextField(
              controller: expiryController,
              decoration: const InputDecoration(
                labelText: 'Expiry (MM/YY)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true &&
        nameController.text.trim().isNotEmpty &&
        last4Controller.text.trim().length == 4) {
      await _methodsRef?.add({
        'type': 'card',
        'label': 'Card ending in ${last4Controller.text.trim()}',
        'cardholderName': nameController.text.trim(),
        'last4': last4Controller.text.trim(),
        'expiry': expiryController.text.trim(),
        'isDefault': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _showAddBankDialog() async {
    final bankNameController = TextEditingController();
    final accountNameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bank Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankNameController,
              decoration: const InputDecoration(labelText: 'Bank Name'),
            ),
            TextField(
              controller: accountNameController,
              decoration: const InputDecoration(labelText: 'Account Holder Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && bankNameController.text.trim().isNotEmpty) {
      await _methodsRef?.add({
        'type': 'bank',
        'label': bankNameController.text.trim(),
        'accountHolderName': accountNameController.text.trim(),
        'isDefault': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _showAddMobilePaymentDialog() async {
    final providerController = TextEditingController();
    final numberController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Mobile Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: providerController,
              decoration: const InputDecoration(
                labelText: 'Provider',
                hintText: 'e.g. bKash, Nagad, Rocket',
              ),
            ),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && providerController.text.trim().isNotEmpty) {
      await _methodsRef?.add({
        'type': 'mobile',
        'label': '${providerController.text.trim()} - ${numberController.text.trim()}',
        'provider': providerController.text.trim(),
        'number': numberController.text.trim(),
        'isDefault': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'card':
        return Icons.credit_card;
      case 'bank':
        return Icons.account_balance;
      case 'mobile':
        return Icons.phone_android;
      case 'cod':
        return Icons.local_shipping_outlined;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = _methodsRef;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: ref == null
          ? const Center(child: Text('Please login to manage payment methods'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showAddMethodSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Payment Method'),
                    ),
                  ),
                ),

                // SAVED PAYMENT METHODS
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: ref.orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No saved payment methods yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'SAVED PAYMENT METHODS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...docs.map((doc) {
                            final data = doc.data();
                            final type = data['type']?.toString() ?? '';
                            final label = data['label']?.toString() ?? 'Payment Method';
                            final isDefault = data['isDefault'] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(_iconForType(type), color: Colors.redAccent),
                                title: Text(label),
                                subtitle: isDefault
                                    ? const Text(
                                        'Default',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'default') {
                                      _setDefault(doc.id);
                                    } else if (value == 'delete') {
                                      _deleteMethod(doc.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (!isDefault)
                                      const PopupMenuItem(
                                        value: 'default',
                                        child: Text('Set as Default'),
                                      ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Remove', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.history),
                              title: const Text('Payment History'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _comingSoon('Payment History'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
