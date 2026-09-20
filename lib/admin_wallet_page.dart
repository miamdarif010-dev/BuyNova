import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class AdminWalletPage extends StatefulWidget {
  const AdminWalletPage({super.key});

  @override
  State<AdminWalletPage> createState() => _AdminWalletPageState();
}

class _AdminWalletPageState extends State<AdminWalletPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  late TabController _tabController;

  bool _processing = false;

  late final FirebaseFunctions _functions;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _functions = FirebaseFunctions.instanceFor(
      region: 'asia-northeast3',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _money(dynamic value) {
    final amount =
        value is num ? value.toDouble() : 0.0;

    if (amount == amount.roundToDouble()) {
      return '৳${amount.toInt()}';
    }

    return '৳${amount.toStringAsFixed(2)}';
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Processing...';
    }

    final date = timestamp.toDate();

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} '
        '$hour:$minute $period';
  }

  String _methodName(
    Map<String, dynamic> data,
  ) {
    return data['withdrawalMethodName']?.toString() ??
        data['paymentMethodName']?.toString() ??
        data['withdrawalMethod']?.toString() ??
        data['paymentMethod']?.toString() ??
        'Unknown';
  }

  String _maskedAccount(String account) {
    if (account.length <= 4) {
      return account;
    }

    return '•••• ${account.substring(account.length - 4)}';
  }

  // =========================================================
  // CLOUD FUNCTIONS ERROR
  // =========================================================

  String _functionErrorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unauthenticated':
          return 'Please login again.';
        case 'permission-denied':
          return 'Admin permission is required.';
        case 'not-found':
          return error.message ??
              'Wallet transaction was not found.';
        case 'failed-precondition':
          return error.message ??
              'This transaction cannot be processed.';
        case 'invalid-argument':
          return error.message ??
              'Invalid wallet transaction.';
        case 'already-exists':
          return error.message ??
              'This transaction has already been processed.';
        case 'unavailable':
          return 'Wallet service is temporarily unavailable.';
        case 'deadline-exceeded':
          return 'Wallet service took too long to respond.';
        default:
          return error.message ??
              'Wallet operation failed.';
      }
    }

    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  // =========================================================
  // APPROVE WALLET TRANSACTION
  // =========================================================

  Future<void> _approveTransaction(
    DocumentSnapshot<Map<String, dynamic>> transactionDoc,
  ) async {
    if (_processing) return;

    final data = transactionDoc.data();

    if (data == null) return;

    final userId =
        data['userId']?.toString() ?? '';

    final transactionId =
        transactionDoc.id;

    final amount =
        (data['amount'] as num?)?.toDouble() ?? 0.0;

    final source =
        data['source']?.toString() ?? '';

    if (userId.isEmpty ||
        transactionId.isEmpty ||
        amount < 100 ||
        (source != 'deposit' &&
            source != 'withdrawal')) {
      _showMessage(
        'Invalid wallet transaction.',
        Colors.red,
      );
      return;
    }

    final isWithdrawal =
        source == 'withdrawal';

    final confirmed = await _confirmAction(
      title: isWithdrawal
          ? 'Approve Withdrawal?'
          : 'Approve Deposit?',
      message: isWithdrawal
          ? 'Approve ${_money(amount)} withdrawal for this user?'
          : 'Approve ${_money(amount)} deposit for this user?',
      confirmText: 'Approve',
      confirmColor: Colors.green,
    );

    if (!confirmed) return;

    if (!mounted) return;

    setState(() {
      _processing = true;
    });

    try {
      final callable =
          _functions.httpsCallable(
        'approveWalletTransaction',
      );

      final result =
          await callable.call({
        'userId': userId,
        'transactionId': transactionId,
      });

      final resultData =
          result.data is Map
              ? Map<String, dynamic>.from(
                  result.data as Map,
                )
              : <String, dynamic>{};

      final newBalance =
          resultData['newBalance'];

      if (isWithdrawal) {
        _showMessage(
          newBalance is num
              ? 'Withdrawal approved. New balance: ${_money(newBalance)}'
              : 'Withdrawal approved successfully.',
          Colors.green,
        );
      } else {
        _showMessage(
          newBalance is num
              ? 'Deposit approved. New balance: ${_money(newBalance)}'
              : 'Deposit approved successfully.',
          Colors.green,
        );
      }
    } catch (e) {
      _showMessage(
        _functionErrorMessage(e),
        Colors.red,
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
  // REJECT WALLET TRANSACTION
  // =========================================================

  Future<void> _rejectTransaction(
    DocumentSnapshot<Map<String, dynamic>> transactionDoc,
  ) async {
    if (_processing) return;

    final data = transactionDoc.data();

    if (data == null) return;

    final userId =
        data['userId']?.toString() ?? '';

    final transactionId =
        transactionDoc.id;

    final amount =
        (data['amount'] as num?)?.toDouble() ?? 0.0;

    final source =
        data['source']?.toString() ?? '';

    if (userId.isEmpty ||
        transactionId.isEmpty ||
        (source != 'deposit' &&
            source != 'withdrawal')) {
      _showMessage(
        'Invalid wallet transaction.',
        Colors.red,
      );
      return;
    }

    final isWithdrawal =
        source == 'withdrawal';

    final reason = await _askReason(
      title: isWithdrawal
          ? 'Reject Withdrawal'
          : 'Reject Deposit',
      hintText: isWithdrawal
          ? 'Reason for withdrawal rejection'
          : 'Reason for deposit rejection',
    );

    if (reason == null) return;

    if (!mounted) return;

    setState(() {
      _processing = true;
    });

    try {
      final callable =
          _functions.httpsCallable(
        'rejectWalletTransaction',
      );

      await callable.call({
        'userId': userId,
        'transactionId': transactionId,
        'reason': reason,
      });

      _showMessage(
        isWithdrawal
            ? 'Withdrawal rejected.'
            : 'Deposit rejected.',
        Colors.orange,
      );
    } catch (e) {
      _showMessage(
        _functionErrorMessage(e),
        Colors.red,
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
  // REASON DIALOG
  // =========================================================

  Future<String?> _askReason({
    required String title,
    required String hintText,
  }) async {
    final controller =
        TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hintText,
              border:
                  const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason =
                    controller.text.trim();

                if (reason.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a reason.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  reason,
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  // =========================================================
  // CONFIRM DIALOG
  // =========================================================

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    confirmColor,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // =========================================================
  // TRANSACTION DETAILS
  // =========================================================

  void _showDetails(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) return;

    final source =
        data['source']?.toString() ?? '';

    final type =
        data['type']?.toString() ?? '';

    final isWithdrawal =
        source == 'withdrawal' ||
            type == 'debit';

    final amount =
        (data['amount'] as num?)?.toDouble() ??
            0.0;

    final status =
        data['status']?.toString() ??
            'pending';

    final userId =
        data['userId']?.toString() ?? '';

    final account =
        data['accountNumber']?.toString() ??
            '';

    final method =
        _methodName(data);

    final reason =
        data['reason']?.toString() ??
            data['rejectionReason']?.toString() ??
            '';

    final createdAt =
        data['createdAt'] as Timestamp?;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  isWithdrawal
                      ? 'Withdrawal Details'
                      : 'Deposit Details',
                  style:
                      const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                _detailRow(
                  'User ID',
                  userId,
                ),
                _detailRow(
                  'Amount',
                  _money(amount),
                ),
                _detailRow(
                  'Method',
                  method,
                ),
                if (account.isNotEmpty)
                  _detailRow(
                    'Account',
                    account,
                  ),
                _detailRow(
                  'Status',
                  status.toUpperCase(),
                ),
                if (createdAt != null)
                  _detailRow(
                    'Date',
                    _formatDate(
                      createdAt,
                    ),
                  ),
                if (reason.isNotEmpty)
                  _detailRow(
                    'Reason',
                    reason,
                  ),
                const SizedBox(
                  height: 12,
                ),
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton.icon(
                          onPressed:
                              _processing
                                  ? null
                                  : () {
                                      Navigator.pop(
                                        context,
                                      );

                                      _rejectTransaction(
                                        doc,
                                      );
                                    },
                          icon:
                              const Icon(
                            Icons.close,
                          ),
                          label:
                              const Text(
                            'Reject',
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            ElevatedButton.icon(
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.green,
                            foregroundColor:
                                Colors.white,
                          ),
                          onPressed:
                              _processing
                                  ? null
                                  : () {
                                      Navigator.pop(
                                        context,
                                      );

                                      _approveTransaction(
                                        doc,
                                      );
                                    },
                          icon:
                              const Icon(
                            Icons.check,
                          ),
                          label:
                              const Text(
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

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PENDING DEPOSITS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _depositStream() {
    return _firestore
        .collectionGroup(
          'walletTransactions',
        )
        .where(
          'source',
          isEqualTo: 'deposit',
        )
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .snapshots();
  }

  // =========================================================
  // PENDING WITHDRAWALS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _withdrawalStream() {
    return _firestore
        .collectionGroup(
          'walletTransactions',
        )
        .where(
          'source',
          isEqualTo: 'withdrawal',
        )
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .snapshots();
  }

  // =========================================================
  // TRANSACTION LIST
  // =========================================================

  Widget _transactionList({
    required Stream<
        QuerySnapshot<Map<String, dynamic>>>
        stream,
    required bool isWithdrawal,
  }) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
                CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Text(
                'Could not load wallet requests.\n\n${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            ),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  isWithdrawal
                      ? Icons.arrow_circle_up
                      : Icons.add_circle,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  isWithdrawal
                      ? 'No pending withdrawals'
                      : 'No pending deposits',
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final sortedDocs = [...docs];

        sortedDocs.sort(
          (a, b) {
            final aTime =
                a.data()['createdAt']
                    as Timestamp?;

            final bTime =
                b.data()['createdAt']
                    as Timestamp?;

            if (aTime == null &&
                bTime == null) {
              return 0;
            }

            if (aTime == null) {
              return 1;
            }

            if (bTime == null) {
              return -1;
            }

            return bTime.compareTo(
              aTime,
            );
          },
        );

        return ListView.builder(
          padding:
              const EdgeInsets.all(12),
          itemCount:
              sortedDocs.length,
          itemBuilder:
              (context, index) {
            final doc =
                sortedDocs[index];

            final data =
                doc.data();

            final amount =
                (data['amount'] as num?)
                        ?.toDouble() ??
                    0.0;

            final userId =
                data['userId']
                        ?.toString() ??
                    '';

            final method =
                _methodName(data);

            final account =
                data['accountNumber']
                        ?.toString() ??
                    '';

            final createdAt =
                data['createdAt']
                    as Timestamp?;

            return Card(
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                onTap: () =>
                    _showDetails(doc),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                (isWithdrawal
                                        ? Colors.red
                                        : Colors.green)
                                    .withValues(
                              alpha: 0.10,
                            ),
                            child: Icon(
                              isWithdrawal
                                  ? Icons
                                      .arrow_circle_up
                                  : Icons
                                      .add_circle,
                              color:
                                  isWithdrawal
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  isWithdrawal
                                      ? 'Withdrawal'
                                      : 'Add Money',
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'User: $userId',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _money(amount),
                            style:
                                TextStyle(
                              color:
                                  isWithdrawal
                                      ? Colors.red
                                      : Colors.green,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      const Divider(
                        height: 1,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons
                                .account_balance,
                            size: 17,
                            color:
                                Colors.grey,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            method,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                          if (account
                              .isNotEmpty) ...[
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                isWithdrawal
                                    ? _maskedAccount(
                                        account)
                                    : '',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            ),
                          ] else
                            const Spacer(),
                          Text(
                            _formatDate(
                              createdAt,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 11,
                              color:
                                  Colors.grey,
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
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  _processing
                                      ? null
                                      : () {
                                          _rejectTransaction(
                                            doc,
                                          );
                                        },
                              icon:
                                  const Icon(
                                Icons.close,
                              ),
                              label:
                                  const Text(
                                'Reject',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child:
                                ElevatedButton.icon(
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.green,
                                foregroundColor:
                                    Colors.white,
                              ),
                              onPressed:
                                  _processing
                                      ? null
                                      : () {
                                          _approveTransaction(
                                            doc,
                                          );
                                        },
                              icon:
                                  const Icon(
                                Icons.check,
                              ),
                              label:
                                  const Text(
                                'Approve',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // MAIN UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wallet Management',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon:
                  Icon(Icons.add_circle),
              text: 'Deposits',
            ),
            Tab(
              icon: Icon(
                Icons.arrow_circle_up,
              ),
              text: 'Withdrawals',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _transactionList(
            stream:
                _depositStream(),
            isWithdrawal: false,
          ),
          _transactionList(
            stream:
                _withdrawalStream(),
            isWithdrawal: true,
          ),
        ],
      ),
      floatingActionButton:
          _processing
              ? FloatingActionButton(
                  onPressed: null,
                  child:
                      const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : null,
    );
  }
}
