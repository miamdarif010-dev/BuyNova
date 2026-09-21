import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyProfitPage extends StatelessWidget {
  const MyProfitPage({super.key});

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(double value) {
    if (value == value.roundToDouble()) {
      return '৳${value.toInt()}';
    }
    return '৳${value.toStringAsFixed(2)}';
  }

  double _profitOf(Map<String, dynamic> data) {
    return _toDouble(data['resellerProfit'] ?? data['profit']);
  }

  String _orderId(String docId, Map<String, dynamic> data) {
    final id = data['resellerOrderId']?.toString() ?? '';
    return id.isNotEmpty ? id : docId;
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'returned':
      case 'refunded':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    if (status.isEmpty) return 'Placed';
    return status[0].toUpperCase() + status.substring(1);
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderTile(String docId, Map<String, dynamic> data) {
    final status =
        (data['orderStatus']?.toString() ?? 'placed').toLowerCase();
    final profit = _profitOf(data);
    final color = _statusColor(status);
    final counted = status != 'cancelled' &&
        status != 'returned' &&
        status != 'refunded';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          _orderId(docId, data),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(data['createdAt']),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        trailing: Text(
          _money(profit),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: counted ? Colors.green : Colors.grey,
            decoration:
                counted ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profit')),
        body: const Center(child: Text('Please login first.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profit')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reseller_orders')
            .where('entrepreneurUid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load profit.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          double earned = 0;
          double pending = 0;
          int deliveredCount = 0;
          int pendingCount = 0;

          for (final doc in docs) {
            final data = doc.data();
            final status =
                (data['orderStatus']?.toString() ?? 'placed')
                    .toLowerCase();
            final profit = _profitOf(data);

            if (status == 'delivered') {
              earned += profit;
              deliveredCount++;
            } else if (status == 'cancelled' ||
                status == 'returned' ||
                status == 'refunded') {
              // Not counted.
            } else {
              pending += profit;
              pendingCount++;
            }
          }

          final sorted = [...docs];

          sorted.sort((a, b) {
            final aTime = a.data()['createdAt'];
            final bTime = b.data()['createdAt'];
            final aDate = aTime is Timestamp ? aTime.toDate() : null;
            final bDate = bTime is Timestamp ? bTime.toDate() : null;

            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _summaryCard(
                    title: 'Earned Profit',
                    value: _money(earned),
                    subtitle:
                        '$deliveredCount delivered order${deliveredCount == 1 ? '' : 's'}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 10),
                  _summaryCard(
                    title: 'Pending Profit',
                    value: _money(pending),
                    subtitle:
                        '$pendingCount order${pendingCount == 1 ? '' : 's'} in progress',
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Profit is counted as earned only after an order is '
                'delivered. Cancelled, returned and refunded orders '
                'are not counted.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (sorted.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No reseller orders yet.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...sorted.map(
                  (doc) => _orderTile(doc.id, doc.data()),
                ),
            ],
          );
        },
      ),
    );
  }
}
