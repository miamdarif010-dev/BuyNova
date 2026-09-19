import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminWalletPage extends StatefulWidget {
  const AdminWalletPage({super.key});

  @override
  State<AdminWalletPage> createState() => _AdminWalletPageState();
}

class _AdminWalletPageState extends State<AdminWalletPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _processing = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _depositStream() {
    return _firestore
        .collectionGroup('walletTransactions')
        .where('source', isEqualTo: 'deposit')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic value) {
    return '৳${_toDouble(value).toStringAsFixed(2)}';
  }

  String _date(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      String two(int n) => n.toString().padLeft(2, '0');

      return '${date.year}-${two(date.month)}-${two(date.day)} '
          '${two(date.hour)}:${two(date.minute)}';
    }

    return 'Waiting...';
  }

  Future<void> _showDepositDetails(
    DocumentSnapshot<Map<String, dynamic>> transaction,
  ) async {
    final data = transaction.data() ?? {};

    final userId = data['userId']?.toString() ?? '';
    final amount = _toDouble(data['amount']);
    final paymentMethod =
        data['paymentMethod']?.toString() ?? 'Not selected';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deposit Request',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _detailRow(
                  'Amount',
                  _money(amount),
                ),
                _detailRow(
                  'User ID',
                  userId,
                ),
                _detailRow(
                  'Payment Method',
                  paymentMethod,
                ),
                _detailRow(
                  'Status',
                  'Pending',
                ),
                _detailRow(
                  'Created',
                  _date(data['createdAt']),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _rejectDeposit(transaction);
                              },
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _processing
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _approveDeposit(transaction);
                              },
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _approveDeposit(
    DocumentSnapshot<Map<String, dynamic>> transaction,
  ) async {
    final data = transaction.data() ?? {};

    final userId = data['userId']?.toString() ?? '';
    final amount = _toDouble(data['amount']);

    if (userId.isEmpty || amount <= 0) {
      _showMessage('Invalid deposit request.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve Deposit?'),
          content: Text(
            'Approve ${_money(amount)} for this user?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      /*
       * IMPORTANT:
       *
       * We intentionally do NOT change cashBalance here.
       *
       * Real-money balance must be updated by a trusted backend /
       * Cloud Function after verification.
       *
       * For now we only mark the deposit request as approved.
       */

      await transaction.reference.update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage(
        '${_money(amount)} deposit approved.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to approve deposit.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _rejectDeposit(
    DocumentSnapshot<Map<String, dynamic>> transaction,
  ) async {
    final data = transaction.data() ?? {};

    final amount = _toDouble(data['amount']);

    final reasonController = TextEditingController();

    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Deposit'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Enter rejection reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  reasonController.text.trim(),
                );
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (result == null) {
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      await transaction.reference.update({
        'status': 'rejected',
        'rejectionReason':
            result.isEmpty ? 'Deposit rejected by admin.' : result,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage(
        '${_money(amount)} deposit rejected.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to reject deposit.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Deposits'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _depositStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load deposit requests.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No pending deposit requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'New Add Money requests will appear here.',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final transaction = documents[index];
              final data = transaction.data();

              final amount = _toDouble(data['amount']);
              final userId =
                  data['userId']?.toString() ?? 'Unknown user';

              final paymentMethod =
                  data['paymentMethod']?.toString() ??
                      'Not selected';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 25,
                    child: const Icon(
                      Icons.account_balance_wallet,
                    ),
                  ),
                  title: Text(
                    _money(amount),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User: $userId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Payment: $paymentMethod',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _date(data['createdAt']),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: _processing
                      ? null
                      : () => _showDepositDetails(
                            transaction,
                          ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
