import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminWalletPage extends StatefulWidget {
  const AdminWalletPage({super.key});

  @override
  State<AdminWalletPage> createState() => _AdminWalletPageState();
}

class _AdminWalletPageState extends State<AdminWalletPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _processing = false;

  // =========================================================
  // PENDING DEPOSITS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _depositStream() {
    return _firestore
        .collectionGroup('walletTransactions')
        .where('source', isEqualTo: 'deposit')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // =========================================================
  // PENDING WITHDRAWALS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _withdrawalStream() {
    return _firestore
        .collectionGroup('walletTransactions')
        .where('source', isEqualTo: 'withdrawal')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _money(dynamic value) {
    return '৳${_toDouble(value).toStringAsFixed(2)}';
  }

  String _date(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      String two(int n) =>
          n.toString().padLeft(2, '0');

      return '${date.year}-${two(date.month)}-'
          '${two(date.day)} '
          '${two(date.hour)}:${two(date.minute)}';
    }

    return 'Waiting...';
  }

  // =========================================================
  // PAYMENT / WITHDRAWAL METHOD
  // =========================================================

  String _methodName(dynamic value) {
    final method = value?.toString() ?? '';

    if (method.isEmpty) {
      return 'Not selected';
    }

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

  // =========================================================
  // DEPOSIT DETAILS
  // =========================================================

  Future<void> _showDepositDetails(
    DocumentSnapshot<Map<String, dynamic>> transaction,
  ) async {
    final data = transaction.data() ?? {};

    final userId =
        data['userId']?.toString() ?? '';

    final amount =
        _toDouble(data['amount']);

    final paymentMethod =
        _methodName(data['paymentMethod']);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                                Navigator.pop(
                                  context,
                                );

                                await _rejectDeposit(
                                  transaction,
                                );
                              },
                        icon: const Icon(
                          Icons.close,
                        ),
                        label: const Text(
                          'Reject',
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _processing
                            ? null
                            : () async {
                                Navigator.pop(
                                  context,
                                );

                                await _approveDeposit(
                                  transaction,
                                );
                              },
                        icon: const Icon(
                          Icons.check,
                        ),
                        label: const Text(
                          'Approve',
                        ),
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

  // =========================================================
  // WITHDRAWAL DETAILS
  // =========================================================

  Future<void> _showWithdrawalDetails(
    DocumentSnapshot<Map<String, dynamic>> transaction,
  ) async {
    final data = transaction.data() ?? {};

    final userId =
        data['userId']?.toString() ?? '';

    final amount =
        _toDouble(data['amount']);

    final withdrawalMethod =
        _methodName(
      data['withdrawalMethod'],
    );

    final accountNumber =
        data['accountNumber']?.toString() ??
            'Not provided';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Withdrawal Request',
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
                  'Method',
                  withdrawalMethod,
                ),

                _detailRow(
                  'Account',
                  accountNumber,
                ),

                _detailRow(
                  'Status',
                  'Pending',
                ),

                _detailRow(
                  'Created',
                  _date(data['createdAt']),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(12),
                    color: Colors.orange
                        .withValues(alpha: 0.10),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The wallet balance will be '
                          'deducted only after the '
                          'withdrawal is approved.',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processing
                            ? null
                            : () async {
                                Navigator.pop(
                                  context,
                                );

                                await _rejectWithdrawal(
                                  transaction,
                                );
                              },
                        icon: const Icon(
                          Icons.close,
                        ),
                        label: const Text(
                          'Reject',
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _processing
                            ? null
                            : () async {
                                Navigator.pop(
                                  context,
                                );

                                await _approveWithdrawal(
                                  transaction,
                                );
                              },
                        icon: const Icon(
                          Icons.check,
                        ),
                        label: const Text(
                          'Approve',
                        ),
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

  // =========================================================
  // DETAIL ROW
  // =========================================================

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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

  // =========================================================
  // APPROVE DEPOSIT
  // =========================================================

  Future<void> _approveDeposit(
    DocumentSnapshot<Map<String, dynamic>> transaction,
  ) async {
    final data = transaction.data() ?? {};

    final userId =
        data['userId']?.toString() ?? '';

    final amount =
        _toDouble(data['amount']);

    if (userId.isEmpty || amount <= 0) {
      _showMessage(
        'Invalid deposit request.',
        error: true,
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Approve Deposit?',
          ),
          content: Text(
            'This will add ${_money(amount)} '
            'to the user wallet.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Approve',
              ),
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
      final transactionReference =
          transaction.reference;

      final userReference =
          _firestore
              .collection('users')
              .doc(userId);

      final notificationReference =
          userReference
              .collection('notifications')
              .doc();

      await _firestore.runTransaction(
        (firestoreTransaction) async {
          final transactionSnapshot =
              await firestoreTransaction.get(
            transactionReference,
          );

          final userSnapshot =
              await firestoreTransaction.get(
            userReference,
          );

          if (!transactionSnapshot.exists) {
            throw Exception(
              'Deposit request no longer exists.',
            );
          }

          if (!userSnapshot.exists) {
            throw Exception(
              'User account not found.',
            );
          }

          final transactionData =
              transactionSnapshot.data();

          final currentStatus =
              transactionData?['status']
                  ?.toString();

          if (currentStatus != 'pending') {
            throw Exception(
              'This deposit has already been processed.',
            );
          }

          final userData =
              userSnapshot.data();

          final currentBalance =
              _toDouble(
            userData?['cashBalance'],
          );

          final newBalance =
              currentBalance + amount;

          firestoreTransaction.update(
            userReference,
            {
              'cashBalance': newBalance,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          firestoreTransaction.update(
            transactionReference,
            {
              'status': 'approved',
              'approvedAmount': amount,
              'approvedAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          firestoreTransaction.set(
            notificationReference,
            {
              'title': 'Money Added',
              'message':
                  '${_money(amount)} has been added '
                  'to your BuyNova wallet.',
              'type': 'wallet_deposit',
              'amount': amount,
              'currency': 'BDT',
              'currencySymbol': '৳',
              'isRead': false,
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );
        },
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${_money(amount)} added successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
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

  // =========================================================
  // REJECT DEPOSIT
  // =========================================================

  Future<void> _rejectDeposit(
    DocumentSnapshot<Map<String, dynamic>> transaction,
  ) async {
    final data = transaction.data() ?? {};

    final amount =
        _toDouble(data['amount']);

    final reasonController =
        TextEditingController();

    final result =
        await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Reject Deposit',
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration:
                const InputDecoration(
              labelText: 'Reason',
              hintText:
                  'Enter rejection reason',
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  reasonController.text.trim(),
                );
              },
              child: const Text(
                'Reject',
              ),
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
      final userId =
          data['userId']?.toString() ?? '';

      final notificationReference =
          userId.isEmpty
              ? null
              : _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('notifications')
                  .doc();

      await _firestore.runTransaction(
        (firestoreTransaction) async {
          final transactionSnapshot =
              await firestoreTransaction.get(
            transaction.reference,
          );

          if (!transactionSnapshot.exists) {
            throw Exception(
              'Deposit request no longer exists.',
            );
          }

          final transactionData =
              transactionSnapshot.data();

          final currentStatus =
              transactionData?['status']
                  ?.toString();

          if (currentStatus != 'pending') {
            throw Exception(
              'This deposit has already been processed.',
            );
          }

          firestoreTransaction.update(
            transaction.reference,
            {
              'status': 'rejected',
              'rejectionReason':
                  result.isEmpty
                      ? 'Deposit rejected by admin.'
                      : result,
              'rejectedAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          if (notificationReference != null) {
            firestoreTransaction.set(
              notificationReference,
              {
                'title':
                    'Deposit Rejected',
                'message':
                    result.isEmpty
                        ? '${_money(amount)} deposit request '
                          'was rejected.'
                        : '${_money(amount)} deposit request '
                          'was rejected. $result',
                'type':
                    'wallet_deposit_rejected',
                'amount': amount,
                'currency': 'BDT',
                'currencySymbol': '৳',
                'isRead': false,
                'createdAt':
                    FieldValue.serverTimestamp(),
              },
            );
          }
        },
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${_money(amount)} deposit rejected.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
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

  // =========================================================
  // APPROVE WITHDRAWAL
  // =========================================================

  Future<void> _approveWithdrawal(
    DocumentSnapshot<Map<String, dynamic>> transaction,
  ) async {
    final data = transaction.data() ?? {};

    final userId =
        data['userId']?.toString() ?? '';

    final amount =
        _toDouble(data['amount']);

    if (userId.isEmpty || amount <= 0) {
      _showMessage(
        'Invalid withdrawal request.',
        error: true,
      );
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Approve Withdrawal?',
          ),
          content: Text(
            'This will deduct ${_money(amount)} '
            'from the user wallet.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Approve',
              ),
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
      final userReference =
          _firestore
              .collection('users')
              .doc(userId);

      final notificationReference =
          userReference
              .collection('notifications')
              .doc();

      await _firestore.runTransaction(
        (firestoreTransaction) async {
          final transactionSnapshot =
              await firestoreTransaction.get(
            transaction.reference,
          );

          final userSnapshot =
              await firestoreTransaction.get(
            userReference,
          );

          if (!transactionSnapshot.exists) {
            throw Exception(
              'Withdrawal request no longer exists.',
            );
          }

          if (!userSnapshot.exists) {
            throw Exception(
              'User account not found.',
            );
          }

          final transactionData =
              transactionSnapshot.data();

          final currentStatus =
              transactionData?['status']
                  ?.toString();

          // Prevent double approval.
          if (currentStatus != 'pending') {
            throw Exception(
              'This withdrawal has already been processed.',
            );
          }

          final userData =
              userSnapshot.data();

          final currentBalance =
              _toDouble(
            userData?['cashBalance'],
          );

          // Never allow negative wallet balance.
          if (amount > currentBalance) {
            throw Exception(
              'Insufficient wallet balance. '
              'Current balance is ${_money(currentBalance)}.',
            );
          }

          final newBalance =
              currentBalance - amount;

          // Deduct money only here.
          firestoreTransaction.update(
            userReference,
            {
              'cashBalance': newBalance,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // Mark withdrawal approved.
          firestoreTransaction.update(
            transaction.reference,
            {
              'status': 'approved',
              'approvedAmount': amount,
              'approvedAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // Notify user.
          firestoreTransaction.set(
            notificationReference,
            {
              'title': 'Withdrawal Approved',
              'message':
                  '${_money(amount)} withdrawal has been '
                  'approved from your BuyNova wallet.',
              'type': 'wallet_withdrawal',
              'amount': amount,
              'currency': 'BDT',
              'currencySymbol': '৳',
              'isRead': false,
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );
        },
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${_money(amount)} withdrawal approved.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
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

  // =========================================================
  // REJECT WITHDRAWAL
  // =========================================================

  Future<void> _rejectWithdrawal(
    DocumentSnapshot<Map<String, dynamic>> transaction,
  ) async {
    final data = transaction.data() ?? {};

    final amount =
        _toDouble(data['amount']);

    final reasonController =
        TextEditingController();

    final result =
        await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Reject Withdrawal',
          ),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration:
                const InputDecoration(
              labelText: 'Reason',
              hintText:
                  'Enter rejection reason',
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  reasonController.text.trim(),
                );
              },
              child: const Text(
                'Reject',
              ),
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
      final userId =
          data['userId']?.toString() ?? '';

      final notificationReference =
          userId.isEmpty
              ? null
              : _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('notifications')
                  .doc();

      await _firestore.runTransaction(
        (firestoreTransaction) async {
          final transactionSnapshot =
              await firestoreTransaction.get(
            transaction.reference,
          );

          if (!transactionSnapshot.exists) {
            throw Exception(
              'Withdrawal request no longer exists.',
            );
          }

          final transactionData =
              transactionSnapshot.data();

          final currentStatus =
              transactionData?['status']
                  ?.toString();

          if (currentStatus != 'pending') {
            throw Exception(
              'This withdrawal has already been processed.',
            );
          }

          // Important:
          // Rejecting a withdrawal does NOT deduct money.
          firestoreTransaction.update(
            transaction.reference,
            {
              'status': 'rejected',
              'rejectionReason':
                  result.isEmpty
                      ? 'Withdrawal rejected by admin.'
                      : result,
              'rejectedAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          if (notificationReference != null) {
            firestoreTransaction.set(
              notificationReference,
              {
                'title':
                    'Withdrawal Rejected',
                'message':
                    result.isEmpty
                        ? '${_money(amount)} withdrawal request '
                          'was rejected.'
                        : '${_money(amount)} withdrawal request '
                          'was rejected. $result',
                'type':
                    'wallet_withdrawal_rejected',
                'amount': amount,
                'currency': 'BDT',
                'currencySymbol': '৳',
                'isRead': false,
                'createdAt':
                    FieldValue.serverTimestamp(),
              },
            );
          }
        },
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        '${_money(amount)} withdrawal rejected.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
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

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            error ? Colors.red : null,
      ),
    );
  }

  // =========================================================
  // DEPOSIT LIST
  // =========================================================

  Widget _buildDepositList() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _depositStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Text(
                'Unable to load deposit requests.\n\n'
                '${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        final documents =
            snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          return _emptyState(
            icon: Icons
                .account_balance_wallet_outlined,
            title:
                'No pending deposit requests',
            message:
                'New Add Money requests '
                'will appear here.',
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(16),
          itemCount: documents.length,
          itemBuilder:
              (context, index) {
            final transaction =
                documents[index];

            final data =
                transaction.data();

            final amount =
                _toDouble(
              data['amount'],
            );

            final userId =
                data['userId']
                        ?.toString() ??
                    'Unknown user';

            final paymentMethod =
                _methodName(
              data['paymentMethod'],
            );

            return Card(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.all(
                  16,
                ),
                leading:
                    const CircleAvatar(
                  radius: 25,
                  child: Icon(
                    Icons
                        .account_balance_wallet,
                  ),
                ),
                title: Text(
                  _money(amount),
                  style:
                      const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle:
                    Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 8,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'User: $userId',
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Payment: '
                        '$paymentMethod',
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        _date(
                          data['createdAt'],
                        ),
                      ),
                    ],
                  ),
                ),
                trailing:
                    const Icon(
                  Icons.chevron_right,
                ),
                onTap: _processing
                    ? null
                    : () =>
                        _showDepositDetails(
                          transaction,
                        ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // WITHDRAWAL LIST
  // =========================================================

  Widget _buildWithdrawalList() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _withdrawalStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Text(
                'Unable to load withdrawal requests.\n\n'
                '${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        final documents =
            snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          return _emptyState(
            icon:
                Icons.payments_outlined,
            title:
                'No pending withdrawal requests',
            message:
                'New withdrawal requests '
                'will appear here.',
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.all(16),
          itemCount: documents.length,
          itemBuilder:
              (context, index) {
            final transaction =
                documents[index];

            final data =
                transaction.data();

            final amount =
                _toDouble(
              data['amount'],
            );

            final userId =
                data['userId']
                        ?.toString() ??
                    'Unknown user';

            final method =
                _methodName(
              data['withdrawalMethod'],
            );

            return Card(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.all(
                  16,
                ),
                leading:
                    const CircleAvatar(
                  radius: 25,
                  child: Icon(
                    Icons.payments_outlined,
                  ),
                ),
                title: Text(
                  _money(amount),
                  style:
                      const TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle:
                    Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 8,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'User: $userId',
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Method: $method',
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        _date(
                          data['createdAt'],
                        ),
                      ),
                    ],
                  ),
                ),
                trailing:
                    const Icon(
                  Icons.chevron_right,
                ),
                onTap: _processing
                    ? null
                    : () =>
                        _showWithdrawalDetails(
                          transaction,
                        ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 150),
        Icon(
          icon,
          size: 64,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style:
                const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Text(
              message,
              textAlign:
                  TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Wallet Management',
          ),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon:
                    Icon(Icons.add_card),
                text: 'Deposits',
              ),
              Tab(
                icon:
                    Icon(Icons.payments_outlined),
                text: 'Withdrawals',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AdminWalletDepositTab(),
            _AdminWalletWithdrawalTab(),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// TAB HELPERS
// =========================================================

class _AdminWalletDepositTab
    extends StatelessWidget {
  const _AdminWalletDepositTab();

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<
            _AdminWalletPageState>();

    if (state == null) {
      return const SizedBox.shrink();
    }

    return state._buildDepositList();
  }
}

class _AdminWalletWithdrawalTab
    extends StatelessWidget {
  const _AdminWalletWithdrawalTab();

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<
            _AdminWalletPageState>();

    if (state == null) {
      return const SizedBox.shrink();
    }

    return state._buildWithdrawalList();
  }
}
