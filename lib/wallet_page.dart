import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isProcessing = false;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = _uid;
    if (uid == null) return null;

    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>>? get _transactionsRef {
    final uid = _uid;
    if (uid == null) return null;

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('walletTransactions');
  }

  String _money(num value) {
    return '৳${value.toStringAsFixed(2)}';
  }

  String _paymentMethodText(String method) {
    switch (method) {
      case 'bkash':
        return 'bKash';
      case 'nagad':
        return 'Nagad';
      case 'rocket':
        return 'Rocket';
      case 'bank':
        return 'Bank Transfer';
      default:
        return method;
    }
  }

  IconData _paymentMethodIcon(String method) {
    switch (method) {
      case 'bkash':
        return Icons.phone_android;
      case 'nagad':
        return Icons.account_balance_wallet;
      case 'rocket':
        return Icons.rocket_launch;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Widget _paymentMethodOption({
    required String value,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final bool selected = value == selectedValue;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.redAccent
                : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? Colors.redAccent.withValues(alpha: 0.06)
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              _paymentMethodIcon(value),
              color: selected
                  ? Colors.redAccent
                  : Colors.grey.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _paymentMethodText(value),
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.redAccent
                      : Colors.grey.shade500,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMoneyDialog() async {
    if (_uid == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    String selectedPaymentMethod = 'bkash';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Money',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        prefixText: '৳ ',
                        hintText: 'Minimum ৳100',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _paymentMethodOption(
                      value: 'bkash',
                      selectedValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value;
                        });
                      },
                    ),
                    _paymentMethodOption(
                      value: 'nagad',
                      selectedValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value;
                        });
                      },
                    ),
                    _paymentMethodOption(
                      value: 'rocket',
                      selectedValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value;
                        });
                      },
                    ),
                    _paymentMethodOption(
                      value: 'bank',
                      selectedValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPaymentMethod = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Your deposit will be reviewed by BuyNova Admin. '
                        'Your wallet balance will increase only after approval.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          final text =
                              amountController.text.trim();

                          final amount =
                              double.tryParse(text);

                          if (amount == null || amount < 100) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Minimum deposit amount is ৳100',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(dialogContext);

                          await _createDepositRequest(
                            amount: amount,
                            paymentMethod:
                                selectedPaymentMethod,
                          );
                        },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  Future<void> _createDepositRequest({
    required double amount,
    required String paymentMethod,
  }) async {
    final uid = _uid;
    final ref = _transactionsRef;

    if (uid == null || ref == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await ref.add({
        'userId': uid,
        'type': 'credit',
        'source': 'deposit',
        'status': 'pending',
        'amount': amount,
        'currency': 'BDT',
        'currencySymbol': '৳',
        'paymentMethod': paymentMethod,
        'paymentMethodName':
            _paymentMethodText(paymentMethod),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Deposit request submitted successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create deposit request: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showWithdrawalInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Withdraw Money'),
          content: const Text(
            'Withdrawal functionality will be available soon.\n\n'
            'BuyNova will support secure withdrawal methods '
            'for eligible wallet balances.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _dateText(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final day =
          date.day.toString().padLeft(2, '0');
      final month =
          date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour =
          date.hour.toString().padLeft(2, '0');
      final minute =
          date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute';
    }

    return 'Processing...';
  }

  void _showTransactionDetails(
    Map<String, dynamic> data,
  ) {
    final amount =
        (data['amount'] as num?)?.toDouble() ?? 0;

    final status =
        data['status']?.toString() ?? 'unknown';

    final type =
        data['type']?.toString() ?? '';

    final source =
        data['source']?.toString() ?? '';

    final paymentMethod =
        data['paymentMethodName']?.toString() ??
            data['paymentMethod']?.toString() ??
            '';

    final rejectionReason =
        data['rejectionReason']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Transaction Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _detailRow(
                  'Amount',
                  _money(amount),
                ),
                _detailRow(
                  'Type',
                  type.isEmpty ? '-' : type,
                ),
                _detailRow(
                  'Source',
                  source.isEmpty ? '-' : source,
                ),
                _detailRow(
                  'Payment Method',
                  paymentMethod.isEmpty
                      ? '-'
                      : paymentMethod,
                ),
                _detailRow(
                  'Status',
                  _statusText(status),
                ),
                _detailRow(
                  'Date',
                  _dateText(data['createdAt']),
                ),
                if (rejectionReason.isNotEmpty)
                  _detailRow(
                    'Rejection Reason',
                    rejectionReason,
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletHeader({
    required double cashBalance,
    required int pointsBalance,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.redAccent,
            Colors.red,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(
              alpha: 0.25,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'BuyNova Wallet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Cash Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _money(cashBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'BDT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  onPressed: _isProcessing
                      ? null
                      : _showAddMoneyDialog,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Money',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  onPressed: _showWithdrawalInfo,
                  icon: const Icon(
                    Icons.arrow_upward,
                  ),
                  label: const Text(
                    'Withdraw',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: color,
                size: 26,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionTile(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
  ) {
    final data = doc.data();

    final amount =
        (data['amount'] as num?)?.toDouble() ?? 0;

    final type =
        data['type']?.toString() ?? '';

    final source =
        data['source']?.toString() ?? '';

    final status =
        data['status']?.toString() ?? 'unknown';

    final paymentMethod =
        data['paymentMethodName']?.toString() ??
            data['paymentMethod']?.toString() ??
            '';

    final isCredit = type == 'credit';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        onTap: () {
          _showTransactionDetails(data);
        },
        leading: CircleAvatar(
          backgroundColor: isCredit
              ? Colors.green.shade50
              : Colors.red.shade50,
          child: Icon(
            isCredit
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isCredit
                ? Colors.green
                : Colors.red,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                source == 'deposit'
                    ? 'Wallet Deposit'
                    : source.isEmpty
                        ? 'Wallet Transaction'
                        : source,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${isCredit ? '+' : '-'}${_money(amount)}',
              style: TextStyle(
                color: isCredit
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (paymentMethod.isNotEmpty)
              Text(paymentMethod),
            Text(
              _dateText(data['createdAt']),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _statusColor(status)
                .withValues(alpha: 0.10),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            _statusText(status),
            style: TextStyle(
              color: _statusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRef = _userRef;
    final transactionsRef = _transactionsRef;

    if (_uid == null ||
        userRef == null ||
        transactionsRef == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wallet'),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Please login to use BuyNova Wallet',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: userRef.snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userData =
              userSnapshot.data?.data() ??
                  <String, dynamic>{};

          final cashBalance =
              (userData['cashBalance'] as num?)
                      ?.toDouble() ??
                  0.0;

          final pointsBalance =
              (userData['pointsBalance'] as num?)
                      ?.toInt() ??
                  0;

          final lifetimePoints =
              (userData['lifetimePoints'] as num?)
                      ?.toInt() ??
                  0;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.only(
                    bottom: 20,
                  ),
                  children: [
                    _walletHeader(
                      cashBalance: cashBalance,
                      pointsBalance:
                          pointsBalance,
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: Row(
                        children: [
                          _summaryCard(
                            icon:
                                Icons.account_balance_wallet,
                            title: 'Cash Balance',
                            value:
                                _money(cashBalance),
                            color:
                                Colors.redAccent,
                          ),
                          _summaryCard(
                            icon: Icons.stars,
                            title: 'Reward Points',
                            value:
                                pointsBalance
                                    .toString(),
                            color:
                                Colors.orange,
                          ),
                          _summaryCard(
                            icon:
                                Icons.workspace_premium,
                            title: 'Lifetime',
                            value:
                                lifetimePoints
                                    .toString(),
                            color:
                                Colors.amber.shade800,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Text(
                        'TRANSACTION HISTORY',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<
                        QuerySnapshot<
                            Map<String,
                                dynamic>>>(
                      stream: transactionsRef
                          .orderBy(
                            'createdAt',
                            descending: true,
                          )
                          .snapshots(),
                      builder:
                          (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState
                                .waiting) {
                          return const Padding(
                            padding:
                                EdgeInsets.all(30),
                            child: Center(
                              child:
                                  CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding:
                                const EdgeInsets.all(
                              20,
                            ),
                            child: Text(
                              'Unable to load transactions.',
                              style: TextStyle(
                                color: Colors
                                    .red.shade700,
                              ),
                            ),
                          );
                        }

                        final docs =
                            snapshot.data?.docs ??
                                [];

                        if (docs.isEmpty) {
                          return const Padding(
                            padding:
                                EdgeInsets.all(30),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 50,
                                    color:
                                        Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No wallet transactions yet',
                                    style: TextStyle(
                                      color:
                                          Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 12,
                          ),
                          child: Column(
                            children: docs
                                .map(
                                  (doc) =>
                                      _transactionTile(
                                    doc,
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
