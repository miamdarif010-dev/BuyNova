import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'available_products_page.dart';
import 'my_store_page.dart';
import 'reseller_orders_page.dart';
import 'my_profit_page.dart';
import 'news_feed_page.dart';

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
  // VIDEOS
  // =========================================================

  Future<void> _openVideos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const NewsFeedPage(),
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
      backgroundColor: const Color(0xFFFFF9F7),
      appBar: AppBar(
        title: const Text(
          'Entrepreneur / Reseller',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
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
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color:
                  Colors.redAccent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_center_outlined,
              size: 40,
              color: Colors.redAccent,
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

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset:
                    const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconBox(
                    Icons.storefront_outlined,
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  const Expanded(
                    child: Text(
                      'Become an Entrepreneur',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                'Apply to become a BuyNova reseller '
                'and start your business.',
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _sendRequest,
                  icon:
                      const Icon(
                    Icons.send_outlined,
                  ),
                  label:
                      const Text(
                    'Become an Entrepreneur',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PENDING
  // =========================================================

  Widget _pendingSection() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            Colors.orange.shade50,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:
                  Colors.orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top,
              color:
                  Colors.orange,
              size: 28,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          const Expanded(
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
    );
  }

  // =========================================================
  // REJECTED
  // =========================================================

  Widget _rejectedSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color:
                Colors.red.shade50,
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color:
                      Colors.red.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color:
                      Colors.red,
                  size: 28,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Rejected',
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
                      'You can send another request.',
                    ),
                  ],
                ),
              ),
            ],
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
        // =====================================================
        // APPROVED STATUS BOX
        // =====================================================

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color:
                Colors.green.shade50,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  Colors.green.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color:
                      Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color:
                      Colors.green,
                  size: 30,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entrepreneur Approved',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    if (_entrepreneurCode
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Entrepreneur ID: '
                        '$_entrepreneurCode',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 4,
                    ),

                    const Text(
                      'Your reseller account is active.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 22,
        ),

        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // =====================================================
        // OVERVIEW BOXES
        // =====================================================

        Row(
          children: [
            Expanded(
              child: _overviewBox(
                icon:
                    Icons.store_outlined,
                title:
                    'My Store',
                subtitle:
                    'Manage store',
                onTap:
                    _openMyStore,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: _overviewBox(
                icon:
                    Icons.search_outlined,
                title:
                    'Find Products',
                subtitle:
                    'Browse products',
                onTap:
                    _openAvailableProducts,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        Row(
          children: [
            Expanded(
              child: _overviewBox(
                icon:
                    Icons.shopping_bag_outlined,
                title:
                    'Orders',
                subtitle:
                    'Reseller orders',
                onTap:
                    _openResellerOrders,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: _overviewBox(
                icon:
                    Icons.account_balance_wallet_outlined,
                title:
                    'My Profit',
                subtitle:
                    'Track profit',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MyProfitPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 24,
        ),

        const Text(
          'Business Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // =====================================================
        // LARGE BUSINESS BOXES
        // =====================================================

        _businessBox(
          icon:
              Icons.store_outlined,
          title:
              'My Store',
          subtitle:
              'Manage products you want to resell.',
          onTap:
              _openMyStore,
        ),

        _businessBox(
          icon:
              Icons.add_business_outlined,
          title:
              'Find Products',
          subtitle:
              'Browse products from BuyNova sellers.',
          onTap:
              _openAvailableProducts,
        ),

        _businessBox(
          icon:
              Icons.video_library_outlined,
          title:
              'Videos',
          subtitle:
              'Watch, upload and manage your BuyNova videos.',
          onTap:
              _openVideos,
        ),

        _businessBox(
          icon:
              Icons.shopping_bag_outlined,
          title:
              'Reseller Orders',
          subtitle:
              'Manage orders from your customers.',
          onTap:
              _openResellerOrders,
        ),

        _businessBox(
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
                builder: (_) =>
                    const MyProfitPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // ICON BOX
  // =========================================================

  Widget _iconBox(
    IconData icon,
  ) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color:
            Colors.redAccent.withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color:
            Colors.redAccent,
        size: 26,
      ),
    );
  }

  // =========================================================
  // OVERVIEW BOX
  // =========================================================

  Widget _overviewBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(16),
      onTap:
          onTap,
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: 0.04),
              blurRadius:
                  10,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color:
                    Colors.redAccent.withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color:
                    Colors.redAccent,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              title,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              subtitle,
              style:
                  TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LARGE BUSINESS BOX
  // =========================================================

  Widget _businessBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.04),
            blurRadius:
                10,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color:
            Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap:
              onTap,
          child: Padding(
            padding:
                const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color:
                        Colors.redAccent.withValues(alpha: 0.10),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color:
                        Colors.redAccent,
                    size: 28,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        subtitle,
                        style:
                            TextStyle(
                          color:
                              Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        Colors.grey.shade100,
                    shape:
                        BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
