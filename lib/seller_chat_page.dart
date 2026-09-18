import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerChatPage extends StatefulWidget {
  final String conversationId;
  final String buyerId;
  final String buyerName;

  const SellerChatPage({
    super.key,
    required this.conversationId,
    required this.buyerId,
    required this.buyerName,
  });

  @override
  State<SellerChatPage> createState() => _SellerChatPageState();
}

class _SellerChatPageState extends State<SellerChatPage> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  bool _sending = false;
  bool _conversationReady = false;

  String _sellerName = 'Seller';

  User? get _user => _auth.currentUser;

  String get _sellerId => _user?.uid ?? '';

  DocumentReference<Map<String, dynamic>>
      get _conversationRef {
    return _firestore
        .collection('conversations')
        .doc(widget.conversationId);
  }

  CollectionReference<Map<String, dynamic>>
      get _messagesRef {
    return _conversationRef.collection('messages');
  }

  @override
  void initState() {
    super.initState();
    _ensureConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================
  // GET SELLER NAME
  // =========================================================

  Future<String> _getSellerName() async {
    if (_sellerId.isEmpty) {
      return 'Seller';
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_sellerId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();

        final name = data?['name'];

        if (name is String &&
            name.trim().isNotEmpty) {
          return name.trim();
        }

        final displayName =
            data?['displayName'];

        if (displayName is String &&
            displayName.trim().isNotEmpty) {
          return displayName.trim();
        }
      }
    } catch (_) {
      // Use Firebase Auth fallback.
    }

    final authName = _user?.displayName;

    if (authName != null &&
        authName.trim().isNotEmpty) {
      return authName.trim();
    }

    return 'Seller';
  }

  // =========================================================
  // ENSURE CONVERSATION
  // =========================================================

  Future<void> _ensureConversation() async {
    if (_sellerId.isEmpty) {
      return;
    }

    try {
      final sellerName =
          await _getSellerName();

      if (mounted) {
        setState(() {
          _sellerName = sellerName;
        });
      }

      final conversationSnapshot =
          await _conversationRef.get();

      if (!conversationSnapshot.exists) {
        // Normally conversations are created by
        // the buyer. This fallback keeps the page
        // functional when a seller opens a valid
        // conversation that does not exist yet.
        await _conversationRef.set({
          'conversationId':
              widget.conversationId,
          'buyerId': widget.buyerId,
          'buyerName': widget.buyerName,
          'sellerId': _sellerId,
          'sellerName': sellerName,
          'lastMessage': '',
          'lastMessageAt':
              FieldValue.serverTimestamp(),
          'buyerUnreadCount': 0,
          'sellerUnreadCount': 0,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } else {
        final data =
            conversationSnapshot.data();

        final existingBuyerId =
            data?['buyerId'];

        final existingSellerId =
            data?['sellerId'];

        // Security check.
        if (existingBuyerId !=
                widget.buyerId ||
            existingSellerId !=
                _sellerId) {
          if (mounted) {
            setState(() {
              _conversationReady = false;
            });

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'You are not a participant in this conversation.',
                ),
              ),
            );
          }

          return;
        }

        final existingBuyerName =
            data?['buyerName'];

        final existingSellerName =
            data?['sellerName'];

        final Map<String, dynamic>
            updates = {};

        if (existingBuyerName !=
                widget.buyerName &&
            widget.buyerName
                .trim()
                .isNotEmpty) {
          updates['buyerName'] =
              widget.buyerName.trim();
        }

        if (existingSellerName !=
            sellerName) {
          updates['sellerName'] =
              sellerName;
        }

        if (updates.isNotEmpty) {
          updates['updatedAt'] =
              FieldValue.serverTimestamp();

          await _conversationRef.update(
            updates,
          );
        }
      }

      if (mounted) {
        setState(() {
          _conversationReady = true;
        });
      }

      await _markMessagesAsRead();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _conversationReady = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open chat: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // MARK MESSAGES AS READ
  // =========================================================

  Future<void> _markMessagesAsRead() async {
    if (_sellerId.isEmpty) {
      return;
    }

    try {
      final snapshot = await _messagesRef
          .where(
            'receiverId',
            isEqualTo: _sellerId,
          )
          .where(
            'isRead',
            isEqualTo: false,
          )
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(
          doc.reference,
          {
            'isRead': true,
            'readAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      batch.set(
        _conversationRef,
        {
          'sellerUnreadCount': 0,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (_) {
      // Chat remains usable even if read update fails.
    }
  }

  // =========================================================
  // SEND MESSAGE
  // =========================================================

  Future<void> _sendMessage() async {
    if (_sellerId.isEmpty) {
      return;
    }

    final message =
        _messageController.text.trim();

    if (message.isEmpty || _sending) {
      return;
    }

    if (!_conversationReady) {
      await _ensureConversation();

      if (!_conversationReady) {
        return;
      }
    }

    setState(() {
      _sending = true;
    });

    try {
      final messageRef =
          _messagesRef.doc();

      final batch =
          _firestore.batch();

      // -----------------------------------------------------
      // CREATE MESSAGE
      // -----------------------------------------------------

      batch.set(
        messageRef,
        {
          'senderId': _sellerId,
          'receiverId': widget.buyerId,
          'message': message,
          'isRead': false,
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );

      // -----------------------------------------------------
      // UPDATE CONVERSATION
      // -----------------------------------------------------

      batch.update(
        _conversationRef,
        {
          'buyerId': widget.buyerId,
          'buyerName': widget.buyerName,
          'sellerId': _sellerId,
          'sellerName': _sellerName,
          'lastMessage': message,
          'lastMessageAt':
              FieldValue.serverTimestamp(),
          'buyerUnreadCount':
              FieldValue.increment(1),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      _messageController.clear();

      await Future.delayed(
        const Duration(milliseconds: 150),
      );

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Message could not be sent: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  // =========================================================
  // SCROLL
  // =========================================================

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      0,
      duration:
          const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  String _formatTime(
    Timestamp? timestamp,
  ) {
    if (timestamp == null) {
      return '';
    }

    final date =
        timestamp.toDate();

    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
            ? 12
            : date.hour;

    final minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    final period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }

  // =========================================================
  // MESSAGE BUBBLE
  // =========================================================

  Widget _messageBubble(
    Map<String, dynamic> data,
  ) {
    final senderId =
        data['senderId']
            as String? ??
            '';

    final isMine =
        senderId == _sellerId;

    final message =
        data['message']
            as String? ??
            '';

    final isRead =
        data['isRead']
            as bool? ??
            false;

    final timestamp =
        data['createdAt']
            as Timestamp?;

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  0.78,
        ),
        margin:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration:
            BoxDecoration(
          color: isMine
              ? Colors.redAccent
              : Colors.grey.shade200,
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(18),
            topRight:
                const Radius.circular(18),
            bottomLeft:
                Radius.circular(
              isMine ? 18 : 4,
            ),
            bottomRight:
                Radius.circular(
              isMine ? 4 : 18,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Align(
              alignment:
                  Alignment.centerLeft,
              child: Text(
                message,
                style: TextStyle(
                  color: isMine
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    color: isMine
                        ? Colors.white70
                        : Colors.black54,
                    fontSize: 10,
                  ),
                ),

                if (isMine) ...[
                  const SizedBox(
                    width: 4,
                  ),

                  Icon(
                    isRead
                        ? Icons.done_all
                        : Icons.check,
                    size: 14,
                    color: isRead
                        ? Colors.white
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY CHAT
  // =========================================================

  Widget _emptyChat() {
    return Center(
      child: Padding(
        padding:
           
