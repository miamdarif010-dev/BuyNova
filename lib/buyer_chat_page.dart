import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BuyerChatPage extends StatefulWidget {
  final String conversationId;
  final String sellerId;
  final String sellerName;

  const BuyerChatPage({
    super.key,
    required this.conversationId,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<BuyerChatPage> createState() => _BuyerChatPageState();
}

class _BuyerChatPageState extends State<BuyerChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  bool _isSending = false;

  String? get _buyerId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _messagesCollection {
    return _firestore
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages');
  }

  DocumentReference<Map<String, dynamic>> get _conversationReference {
    return _firestore
        .collection('conversations')
        .doc(widget.conversationId);
  }

  @override
  void initState() {
    super.initState();
    _createConversationIfNeeded();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _createConversationIfNeeded() async {
    final buyerId = _buyerId;

    if (buyerId == null) {
      return;
    }

    final reference = _conversationReference;

    final snapshot = await reference.get();

    if (!snapshot.exists) {
      await reference.set({
        'conversationId': widget.conversationId,
        'buyerId': buyerId,
        'sellerId': widget.sellerId,
        'sellerName': widget.sellerName,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'buyerUnreadCount': 0,
        'sellerUnreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = snapshot.data();

      if (data != null) {
        final existingBuyerId = data['buyerId'];

        if (existingBuyerId != buyerId) {
          return;
        }
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messageStream() {
    return _messagesCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _markMessagesAsRead() async {
    final buyerId = _buyerId;

    if (buyerId == null) {
      return;
    }

    try {
      final snapshot = await _messagesCollection
          .where('receiverId', isEqualTo: buyerId)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final batch = _firestore.batch();

      for (final document in snapshot.docs) {
        batch.update(
          document.reference,
          {
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          },
        );
      }

      batch.update(
        _conversationReference,
        {
          'buyerUnreadCount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } catch (_) {
      // Read status should not prevent the chat from opening.
    }
  }

  Future<void> _sendMessage() async {
    final buyerId = _buyerId;

    if (buyerId == null) {
      return;
    }

    final message = _messageController.text.trim();

    if (message.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final conversationSnapshot =
          await _conversationReference.get();

      if (conversationSnapshot.exists) {
        final conversationData =
            conversationSnapshot.data();

        if (conversationData != null) {
          final existingBuyerId =
              conversationData['buyerId'];

          if (existingBuyerId != buyerId) {
            throw Exception(
              'You are not allowed to use this conversation.',
            );
          }
        }
      } else {
        await _conversationReference.set({
          'conversationId': widget.conversationId,
          'buyerId': buyerId,
          'sellerId': widget.sellerId,
          'sellerName': widget.sellerName,
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'buyerUnreadCount': 0,
          'sellerUnreadCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final messageReference =
          _messagesCollection.doc();

      final batch = _firestore.batch();

      batch.set(
        messageReference,
        {
          'senderId': buyerId,
          'receiverId': widget.sellerId,
          'message': message,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        _conversationReference,
        {
          'buyerId': buyerId,
          'sellerId': widget.sellerId,
          'sellerName': widget.sellerName,
          'lastMessage': message,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'sellerUnreadCount':
              FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      _messageController.clear();

      await Future<void>.delayed(
        const Duration(milliseconds: 100),
      );

      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message could not be sent: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) {
      return '';
    }

    final date = value.toDate();

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  Widget _messageBubble(
    Map<String, dynamic> data,
  ) {
    final buyerId = _buyerId;

    final senderId = data['senderId'];

    final isMine =
        buyerId != null && senderId == buyerId;

    final message =
        data['message']?.toString() ?? '';

    final time =
        _formatTime(data['createdAt']);

    final isRead =
        data['isRead'] == true;

    return Align(
      alignment:
          isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(
          left: 12,
          right: 12,
          top: 5,
          bottom: 5,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.redAccent
              : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(
              isMine ? 16 : 4,
            ),
            bottomRight: Radius.circular(
              isMine ? 4 : 16,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMine
                    ? Colors.white
                    : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: TextStyle(
                      color: isMine
                          ? Colors.white70
                          : Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                if (isMine) ...[
                  const SizedBox(width: 5),
                  Icon(
                    isRead
                        ? Icons.done_all
                        : Icons.done,
                    size: 15,
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

  Widget _messageInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          10,
          8,
          10,
          8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) {
                  _sendMessage();
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                heroTag: null,
                elevation: 1,
                backgroundColor:
                    Colors.redAccent,
                onPressed:
                    _isSending ? null : _sendMessage,
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buyerId = _buyerId;

    if (buyerId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Please login to use chat.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.sellerName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Seller',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _messageStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Unable to load messages.',
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final documents =
                    snapshot.data?.docs ?? [];

                WidgetsBinding.instance
                    .addPostFrameCallback((_) {
                  _markMessagesAsRead();
                });

                if (documents.isEmpty) {
                  return Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration:
                                BoxDecoration(
                              color: Colors.redAccent
                                  .withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_outlined,
                              size: 40,
                              color:
                                  Colors.redAccent,
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          const Text(
                            'Start a conversation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            'Send a message to ${widget.sellerName}.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: Colors
                                  .grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller:
                      _scrollController,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  itemCount: documents.length,
                  itemBuilder:
                      (context, index) {
                    final data =
                        documents[index].data();

                    return _messageBubble(data);
                  },
                );
              },
            ),
          ),
          _messageInput(),
        ],
      ),
    );
  }
}
