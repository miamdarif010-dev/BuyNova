import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'available_products_page.dart';
import 'my_store_page.dart';
import 'reseller_orders_page.dart';
import 'my_profit_page.dart';
class EntrepreneurPage extends StatefulWidget {
  const EntrepreneurPage({super.key});

  @override
  State<EntrepreneurPage> createState() =>
      _EntrepreneurPageState();
}

class _EntrepreneurPageState
    extends State<EntrepreneurPage> {
  bool _loading = true;

  String _status = 'none';
  String _entrepreneurCode = '';

  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

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
          _loading = false;
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
                data['entrepreneurStatus']?.toString() ??
                    'none';

            _entrepreneurCode =
                data['entrepreneurCode']?.toString() ??
                    '';
          });
        }
      }
    } catch (e) {
      debugPrint(
        'Entrepreneur loading error: $e',
      );
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  // =========================================================
  // SEND ENTREPRENEUR REQUEST
  // =========================================================

  Future<void> _sendRequest() async {
    final user = currentUser;

    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Become an Entrepreneur / Reseller',
          ),
          content: const Text(
            'Send a request to become an Entrepreneur / '
            'Reseller? An admin will review your request.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Send Request',
              ),
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
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        _status = 'pending';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Entrepreneur request sent successfully!',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send request: $e',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // MY STORE
  // =========================================================

  Future<void> _openMyStore() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const MyStorePage(),
      ),
    );
  }

  // =========================================================
  // AVAILABLE PRODUCTS
  // =========================================================

  Future<void> _openAvailableProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AvailableProductsPage(),
      ),
    );
  }

  // =========================================================
  // RESELLER ORDERS
  // =========================================================

  Future<void> _openResellerOrders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ResellerOrdersPage(),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Entrepreneur / Reseller',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh:
            _loadEntrepreneurData,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _headerCard(),

              const SizedBox(
                height: 18,
              ),

              if (_status ==
                  'approved') ...[
                _approvedSection(),
              ] else if (_status ==
                  'pending') ...[
                _pendingSection(),
              ] else if (_status ==
                  'rejected') ...[
                _rejectedSection(),
              ] else ...[
                _notRegisteredSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _headerCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 38,
              child: Icon(
                Icons.business_center,
                size: 40,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Entrepreneur / Reseller',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Find products from BuyNova sellers, '
              'set your own selling price and earn profit.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NOT REGISTERED
  // =========================================================

  Widget _notRegisteredSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Start Reselling',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        const Text(
          'Become a BuyNova Entrepreneur / Reseller '
          'and start selling products from approved sellers.',
        ),

        const SizedBox(
          height: 18,
        ),

        SizedBox(
          width:
              double.infinity,
          height: 52,
          child:
              ElevatedButton.icon(
            onPressed:
                _sendRequest,
            icon:
                const Icon(
              Icons.send,
            ),
            label:
                const Text(
              'Become an Entrepreneur',
              style:
                  TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PENDING
  // =========================================================

  Widget _pendingSection() {
    return Card(
      color:
          Colors.orange.shade50,
      elevation: 0,
      child: const Padding(
        padding:
            EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_top,
              color:
                  Colors.orange,
              size: 32,
            ),

            SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Pending',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(
                    height: 5,
                  ),

                  Text(
                    'Your Entrepreneur / Reseller '
                    'request is waiting for admin approval.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // REJECTED
  // =========================================================

  Widget _rejectedSection() {
    return Column(
      children: [
        Card(
          color:
              Colors.red.shade50,
          elevation: 0,
          child: const ListTile(
            leading: Icon(
              Icons.cancel_outlined,
              color:
                  Colors.red,
            ),
            title: Text(
              'Request Rejected',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'You can send another request.',
            ),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        SizedBox(
          width:
              double.infinity,
          height: 50,
          child:
              ElevatedButton(
            onPressed:
                _sendRequest,
            child:
                const Text(
              'Request Again',
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // APPROVED
  // =========================================================

  Widget _approvedSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // APPROVED CARD
        Card(
          color:
              Colors.green.shade50,
          elevation: 0,
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color:
                      Colors.green,
                  size: 32,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entrepreneur Approved',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (_entrepreneurCode
                          .isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 4,
                          ),
                          child:
                              Text(
                            'Entrepreneur ID: '
                            '$_entrepreneurCode',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        const Text(
          'My Business',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        // =====================================================
        // MY STORE
        // =====================================================

        _businessItem(
          icon:
              Icons.store_outlined,
          title:
              'My Store',
          subtitle:
              'Manage products you want to resell.',
          onTap:
              _openMyStore,
        ),

        // =====================================================
        // FIND PRODUCTS
        // =====================================================

        _businessItem(
          icon:
              Icons.add_business_outlined,
          title:
              'Find Products',
          subtitle:
              'Browse products from BuyNova sellers.',
          onTap:
              _openAvailableProducts,
        ),

        // =====================================================
        // RESELLER ORDERS
        // =====================================================

        _businessItem(
          icon:
              Icons.shopping_bag_outlined,
          title:
              'Reseller Orders',
          subtitle:
              'Manage orders from your customers.',
          onTap:
              _openResellerOrders,
        ),

        // =====================================================
        // MY PROFIT
        // =====================================================

        _businessItem(
          icon:
              Icons.account_balance_wallet_outlined,
          title:
              'My Profit',
          subtitle:
              'Track your reseller profit.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MyProfitPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // BUSINESS ITEM
  // =========================================================

  Widget _businessItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        leading:
            Icon(icon),
        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle:
            Text(subtitle),
        trailing:
            const Icon(
          Icons.chevron_right,
        ),
        onTap:
            onTap,
      ),
    );
  }

  // =========================================================
  // COMING SOON
  // =========================================================

  void _comingSoon(
    String title,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '$title coming soon',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}
