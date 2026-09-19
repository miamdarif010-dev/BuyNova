import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;

  // Rewards
  int _pointsBalance = 0;
  int _lifetimePoints = 0;

  // Real money - Bangladesh BDT
  double _cashBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final snapshot =
          await _firestore.collection('users').doc(user.uid).get();

      final data = snapshot.data();

      if (mounted) {
        setState(() {
          _pointsBalance = _toInt(data?['pointsBalance']);
          _lifetimePoints = _toInt(data?['lifetimePoints']);

          // Bangladesh currency
          _cashBalance = _toDouble(data?['cashBalance']);

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet load failed: $e'),
          ),
        );
      }
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        );
  }

  String _formatMoney(double amount) {
    return '৳${amount.toStringAsFixed(2)}';
  }

  String _transactionTitle(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final source = data['source']?.toString() ?? '';

    if (type == 'credit') {
      if (source == 'watch_earn') {
        return 'Watch & Earn';
      }

      if (source == 'referral') {
        return 'Referral Reward';
      }

      if (source == 'seller_video') {
        return 'Seller Video Reward';
      }

      if (source == 'deposit') {
        return 'Money Added';
      }

      if (source == 'profit') {
        return 'Profit Earned';
      }

      if (source == 'refund') {
        return 'Refund';
      }

      return 'Reward Earned';
    }

    if (type == 'debit') {
      if (source == 'withdrawal') {
        return 'Withdrawal';
      }

      if (source == 'purchase') {
        return 'Purchase';
      }

      return 'Points Used';
    }

    return 'Wallet Transaction';
  }

  IconData _transactionIcon(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final source = data['source']?.toString() ?? '';

    if (type == 'debit') {
      if (source == 'withdrawal') {
        return Icons.account_balance_rounded;
      }

      if (source == 'purchase') {
        return Icons.shopping_bag_rounded;
      }

      return Icons.arrow_upward_rounded;
    }

    if (source == 'watch_earn') {
      return Icons.play_circle_fill_rounded;
    }

    if (source == 'referral') {
      return Icons.people_alt_rounded;
    }

    if (source == 'seller_video') {
      return Icons.video_library_rounded;
    }

    if (source == 'deposit') {
      return Icons.add_circle_rounded;
    }

    if (source == 'profit') {
      return Icons.trending_up_rounded;
    }

    if (source == 'refund') {
      return Icons.currency_exchange_rounded;
    }

    return Icons.stars_rounded;
  }

  String _statusText(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'completed';

    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _statusColor(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'completed';

    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year • $hour:$minute';
    }

    return 'Date unavailable';
  }

  Future<void> _showAddMoneyDialog() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Money'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Amount',
              hintText: 'Example: 1000',
              prefixText: '৳ ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount =
                    double.tryParse(controller.text.trim()) ?? 0;

                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid amount.',
                      ),
                    ),
                  );
                  return;
                }

                if (amount < 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Minimum amount is ৳100.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                await _createDepositRequest(
                  user.uid,
                  amount,
                );
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _createDepositRequest(
    String uid,
    double amount,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('walletTransactions')
          .add({
        'type': 'credit',
        'source': 'deposit',
        'amount': amount,
        'currency': 'BDT',
        'currencySymbol': '৳',
        'status': 'pending',
        'paymentMethod': 'not_selected',
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Deposit request created. Payment gateway will be connected later.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create deposit request: $e',
          ),
        ),
      );
    }
  }

  void _showWithdrawalInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Withdraw',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Money withdrawal will be available after BuyNova enables the secure withdrawal system.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                _infoRow(
                  Icons.account_balance_wallet_rounded,
                  'Cash Balance',
                  _formatMoney(_cashBalance),
                ),
                const SizedBox(height: 10),
                _infoRow(
                  Icons.stars_rounded,
                  'Reward Points',
                  _formatNumber(_pointsBalance),
                ),
                const SizedBox(height: 10),
                _infoRow(
                  Icons.security_rounded,
                  'Security',
                  'Payment verification required',
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Coming Soon'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _walletHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'BuyNova Wallet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Cash Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatMoney(_cashBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bangladesh Taka (BDT)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddMoneyDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Money'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                    Colors.black87,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isMoney,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 25),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isMoney
                  ? _formatMoney(
                      double.tryParse(value) ?? 0,
                    )
                  : _formatNumber(
                      int.tryParse(value) ?? 0,
                    ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Wallet',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                icon: Icons.add_card_rounded,
                title: 'Add Money',
                onTap: _showAddMoneyDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                icon: Icons.account_balance_rounded,
                title: 'Withdraw',
                onTap: _showWithdrawalInfo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 6),
          Text(title),
        ],
      ),
    );
  }

  Widget _transactionItem(
    String id,
    Map<String, dynamic> data,
  ) {
    final type =
        data['type']?.toString() ?? 'credit';

    final source =
        data['source']?.toString() ?? '';

    final points =
        _toInt(data['points']);

    final amount =
        _toDouble(data['amount']);

    final isCredit =
        type == 'credit';

    final isMoneyTransaction =
        source == 'deposit' ||
        source == 'profit' ||
        source == 'refund' ||
        source == 'purchase' ||
        source == 'withdrawal';

    final displayValue =
        isMoneyTransaction
            ? _formatMoney(amount)
            : _formatNumber(points);

    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCredit
                  ? Colors.green.withValues(
                      alpha: 0.12,
                    )
                  : Colors.red.withValues(
                      alpha: 0.12,
                    ),
            ),
            child: Icon(
              _transactionIcon(data),
              color: isCredit
                  ? Colors.green
                  : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _transactionTitle(data),
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(
                    data['createdAt'],
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(
                          alpha: 0.55,
                        ),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration:
                      BoxDecoration(
                    color: _statusColor(
                      data,
                    ).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Text(
                    _statusText(data),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          _statusColor(data),
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isCredit ? '+' : '-'}$displayValue',
            style: TextStyle(
              color: isCredit
                  ? Colors.green
                  : Colors.red,
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionHistory() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'Please login first.',
        ),
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .doc(user.uid)
          .collection('walletTransactions')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding:
                const EdgeInsets.all(16),
            decoration:
                BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: const Text(
              'Transaction history is not available yet.',
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(25),
            decoration:
                BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 45,
                ),
                SizedBox(height: 10),
                Text(
                  'No transactions yet',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your money and rewards history will appear here.',
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            return _transactionItem(
              doc.id,
              doc.data(),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wallet'),
        ),
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            onPressed: _loadWallet,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWallet,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(16),
          children: [
            _walletHeader(),

            const SizedBox(height: 16),

            Row(
              children: [
                _summaryCard(
                  icon:
                      Icons.account_balance_wallet_rounded,
                  title:
                      'Cash Balance',
                  value:
                      _cashBalance.toString(),
                  isMoney: true,
                ),
                const SizedBox(width: 12),
                _summaryCard(
                  icon:
                      Icons.stars_rounded,
                  title:
                      'Reward Points',
                  value:
                      _pointsBalance.toString(),
                  isMoney: false,
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding:
                  const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Lifetime Rewards Earned',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _formatNumber(
                      _lifetimePoints,
                    ),
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            _quickActions(),

            const SizedBox(height: 26),

            const Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _transactionHistory(),

            const SizedBox(height: 30),

            Center(
              child: Text(
                'BuyNova • BDT Wallet & Rewards',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(
                        alpha: 0.45,
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
