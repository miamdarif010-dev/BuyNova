import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'product_details_page.dart';

class GlobalNotificationsPage extends StatefulWidget {
  const GlobalNotificationsPage({super.key});

  @override
  State<GlobalNotificationsPage> createState() =>
      _GlobalNotificationsPageState();
}

class _GlobalNotificationsPageState
    extends State<GlobalNotificationsPage> {
  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  // =========================================================
  // FORMAT BDT
  // =========================================================

  String _formatBdt(dynamic value) {
    final price = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0.0;

    return '৳${price.toStringAsFixed(2)}';
  }

  // =========================================================
  // OPEN PRODUCT
  // =========================================================

  Future<void> _openProduct(
    String notificationId,
    Map<String, dynamic> notification,
  ) async {
    final productId =
        notification['productId']?.toString();

    if (productId == null || productId.isEmpty) {
      return;
    }

    // ---------------------------------------------------------
    // Mark notification as read for THIS user only.
    // ---------------------------------------------------------

    final user = _currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('globalNotificationReads')
            .doc(notificationId)
            .set({
          'notificationId': notificationId,
          'readAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Do not block product opening if read status fails.
      }
    }

    try {
      final productSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();

      if (!mounted) return;

      if (!productSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This product is no longer available.',
            ),
          ),
        );
        return;
      }

      final productData =
          productSnapshot.data()!;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsPage(
            productId: productSnapshot.id,
            product: productData,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open product: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // MARK ALL AS READ
  // =========================================================

  Future<void> _markAllAsRead(
    List<QueryDocumentSnapshot> notifications,
  ) async {
    final user = _currentUser;

    if (user == null || notifications.isEmpty) {
      return;
    }

    try {
      final firestore =
          FirebaseFirestore.instance;

      final batch = firestore.batch();

      for (final notification in notifications) {
        final readRef = firestore
            .collection('users')
            .doc(user.uid)
            .collection('globalNotificationReads')
            .doc(notification.id);

        batch.set(
          readRef,
          {
            'notificationId': notification.id,
            'readAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All notifications marked as read.',
          ),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not mark notifications as read: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // TIME
  // =========================================================

  String _timeAgo(dynamic timestamp) {
    if (timestamp is! Timestamp) {
      return 'Just now';
    }

    final createdAt = timestamp.toDate();
    final difference =
        DateTime.now().difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} day ago';
    }

    final day = createdAt.day
        .toString()
        .padLeft(2, '0');

    final month = createdAt.month
        .toString()
        .padLeft(2, '0');

    final year = createdAt.year.toString();

    return '$day/$month/$year';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (user != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('global_notifications')
                  .where(
                    'active',
                    isEqualTo: true,
                  )
                  .snapshots(),
              builder: (
                context,
                notificationSnapshot,
              ) {
                final notifications =
                    notificationSnapshot.data?.docs ??
                        [];

                if (notifications.isEmpty) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  tooltip: 'Mark all as read',
                  icon: const Icon(
                    Icons.done_all,
                  ),
                  onPressed: () {
                    _markAllAsRead(
                      notifications,
                    );
                  },
                );
              },
            ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('global_notifications')
            .where(
              'active',
              isEqualTo: true,
            )
            .snapshots(),

        builder: (
          context,
          notificationSnapshot,
        ) {
          if (notificationSnapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load notifications.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            );
          }

          if (notificationSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final notifications =
              notificationSnapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No new notifications',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'New products will appear here.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // -----------------------------------------------------
          // Sort newest first on the client.
          // This avoids requiring a Firestore composite index.
          // -----------------------------------------------------

          notifications.sort((a, b) {
            final aData =
                a.data() as Map<String, dynamic>;

            final bData =
                b.data() as Map<String, dynamic>;

            final aTime =
                aData['createdAt'] is Timestamp
                    ? (aData['createdAt'] as Timestamp)
                        .millisecondsSinceEpoch
                    : 0;

            final bTime =
                bData['createdAt'] is Timestamp
                    ? (bData['createdAt'] as Timestamp)
                        .millisecondsSinceEpoch
                    : 0;

            return bTime.compareTo(aTime);
          });

          if (user == null) {
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              separatorBuilder: (
                context,
                index,
              ) =>
                  const SizedBox(height: 8),
              itemBuilder: (
                context,
                index,
              ) {
                final doc =
                    notifications[index];

                final data =
                    doc.data()
                        as Map<String, dynamic>;

                return _notificationCard(
                  context: context,
                  notificationId: doc.id,
                  data: data,
                  isRead: true,
                );
              },
            );
          }

          // -----------------------------------------------------
          // USER READ STATUS
          // -----------------------------------------------------

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('globalNotificationReads')
                .snapshots(),

            builder: (
              context,
              readSnapshot,
            ) {
              final readIds = <String>{};

              for (final readDoc
                  in readSnapshot.data?.docs ?? []) {
                readIds.add(readDoc.id);
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: notifications.length,
                separatorBuilder: (
                  context,
                  index,
                ) =>
                    const SizedBox(height: 8),
                itemBuilder: (
                  context,
                  index,
                ) {
                  final doc =
                      notifications[index];

                  final data =
                      doc.data()
                          as Map<String, dynamic>;

                  final isRead =
                      readIds.contains(doc.id);

                  return _notificationCard(
                    context: context,
                    notificationId: doc.id,
                    data: data,
                    isRead: isRead,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // =========================================================
  // NOTIFICATION CARD
  // =========================================================

  Widget _notificationCard({
    required BuildContext context,
    required String notificationId,
    required Map<String, dynamic> data,
    required bool isRead,
  }) {
    final title =
        data['title']?.toString() ??
            'New Product Added';

    final message =
        data['message']?.toString() ??
            'A new product has been added to BuyNova.';

    final productName =
        data['productName']?.toString() ??
            'New Product';

    final imageUrl =
        data['productImageUrl']?.toString() ??
            '';

    final price =
        data['productPrice'];

    final createdAt =
        data['createdAt'];

    return Material(
      color: isRead
          ? Theme.of(context)
              .colorScheme
              .surface
          : Colors.redAccent.withOpacity(0.08),
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: () {
          _openProduct(
            notificationId,
            data,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------
              // IMAGE
              // -------------------------------------------------

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Container(
                              color:
                                  Colors.grey.shade200,
                              child: const Icon(
                                Icons
                                    .image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color:
                              Colors.grey.shade200,
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // -------------------------------------------------
              // TEXT
              // -------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                            ),
                          ),
                        ),

                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin:
                                const EdgeInsets.only(
                              left: 6,
                              top: 5,
                            ),
                            decoration:
                                const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      productName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      message,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Text(
                          _formatBdt(price),
                          style:
                              const TextStyle(
                            color:
                                Colors.redAccent,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Text(
                          _timeAgo(createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
