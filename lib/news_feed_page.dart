import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'login_page.dart';
import 'cart_page.dart';

class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({super.key});

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'News Feed',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sellerVideos')
            .where('status', isEqualTo: 'published')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load feed',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            );
          }

          final docs =
              snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No videos yet',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: docs.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final doc = docs[index];

              final data =
                  doc.data() as Map<String, dynamic>;

              return _FeedVideoItem(
                key: ValueKey(doc.id),
                videoId: doc.id,
                data: data,
                isActive:
                    index == _currentPage,
              );
            },
          );
        },
      ),
    );
  }
}

// =============================================================
// FEED VIDEO ITEM
// =============================================================

class _FeedVideoItem extends StatefulWidget {
  final String videoId;
  final Map<String, dynamic> data;
  final bool isActive;

  const _FeedVideoItem({
    super.key,
    required this.videoId,
    required this.data,
    required this.isActive,
  });

  @override
  State<_FeedVideoItem> createState() =>
      _FeedVideoItemState();
}

class _FeedVideoItemState
    extends State<_FeedVideoItem> {
  VideoPlayerController? _controller;

  bool _isInitialized = false;
  bool _hasError = false;

  // Prevent duplicate view count during
  // this widget/session.
  bool _viewRecorded = false;

  String? get _uid =>
      FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>
      get _videoRef {
    return FirebaseFirestore.instance
        .collection('sellerVideos')
        .doc(widget.videoId);
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(
    covariant _FeedVideoItem oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (_controller == null) return;

    if (widget.isActive) {
      if (!_controller!.value.isPlaying) {
        _controller!.play();
      }

      _recordView();
    } else {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      }
    }
  }

  // =========================================================
  // INITIALIZE VIDEO
  // =========================================================

  Future<void> _initializeVideo() async {
    final videoUrl =
        widget.data['videoUrl']?.toString() ?? '';

    if (videoUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
      return;
    }

    try {
      final controller =
          VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      await controller.initialize();

      controller.setLooping(true);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });

      if (widget.isActive) {
        controller.play();
        _recordView();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
    }
  }

  // =========================================================
  // RECORD VIEW
  // =========================================================

  Future<void> _recordView() async {
    if (_viewRecorded) return;

    _viewRecorded = true;

    try {
      final uid = _uid;

      // Logged-in user:
      // store individual view to prevent
      // repeated views for the same video.
      if (uid != null) {
        final viewRef = _videoRef
            .collection('views')
            .doc(uid);

        final viewDoc =
            await viewRef.get();

        if (viewDoc.exists) return;

        await FirebaseFirestore.instance
            .runTransaction((transaction) async {
          final freshView =
              await transaction.get(viewRef);

          if (freshView.exists) return;

          transaction.set(
            viewRef,
            {
              'userId': uid,
              'viewedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.update(
            _videoRef,
            {
              'viewCount':
                  FieldValue.increment(1),
            },
          );
        });
      } else {
        // For guest users, record only once
        // during this widget lifetime.
        await _videoRef.update({
          'viewCount':
              FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint(
        'View recording error: $e',
      );
    }
  }

  // =========================================================
  // PLAY / PAUSE
  // =========================================================

  void _togglePlayPause() {
    if (_controller == null) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  // =========================================================
  // LIKE / UNLIKE
  // =========================================================

  Future<void> _toggleLike() async {
    final uid = _uid;

    if (uid == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginPage(),
        ),
      );
      return;
    }

    final likeRef = _videoRef
        .collection('likes')
        .doc(uid);

    try {
      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final likeDoc =
            await transaction.get(likeRef);

        if (likeDoc.exists) {
          transaction.delete(likeRef);

          transaction.update(
            _videoRef,
            {
              'likeCount':
                  FieldValue.increment(-1),
            },
          );
        } else {
          transaction.set(
            likeRef,
            {
              'userId': uid,
              'likedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.update(
            _videoRef,
            {
              'likeCount':
                  FieldValue.increment(1),
            },
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not update like: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // COMMENTS
  // =========================================================

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return _CommentsSheet(
          videoId: widget.videoId,
        );
      },
    );
  }

  // =========================================================
  // SHARE
  // =========================================================

  Future<void> _shareVideo() async {
    final videoUrl =
        widget.data['videoUrl']
                ?.toString() ??
            '';

    final caption =
        widget.data['caption']
                ?.toString() ??
            '';

    try {
      await Share.share(
        '$caption\n\n'
        'Check this out on BuyNova:\n'
        '$videoUrl',
      );

      await _videoRef.update({
        'shareCount':
            FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint(
        'Share error: $e',
      );
    }
  }

  // =========================================================
  // PRODUCT
  // =========================================================

  Future<void> _viewProduct() async {
    final productName =
        widget.data['productName']
            ?.toString();

    final productId =
        widget.data['productId']
            ?.toString();

    final productPrice =
        widget.data['productPrice'] is num
            ? (widget.data['productPrice']
                    as num)
                .toDouble()
            : 0.0;

    if (productName == null ||
        productName.isEmpty ||
        productId == null ||
        productId.isEmpty) {
      return;
    }

    final imageUrl =
        widget.data['productImageUrl']
            ?.toString();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '₩${productPrice.toStringAsFixed(0)}',
                style:
                    const TextStyle(
                  color:
                      Colors.redAccent,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width:
                    double.infinity,
                height: 48,
                child:
                    ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.redAccent,
                    foregroundColor:
                        Colors.white,
                  ),
                  icon: const Icon(
                    Icons
                        .shopping_cart_outlined,
                  ),
                  label:
                      const Text(
                    'Add to Cart',
                  ),
                  onPressed: () async {
                    final uid =
                        _uid;

                    if (uid == null) {
                      Navigator.pop(
                        context,
                      );

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const LoginPage(),
                        ),
                      );

                      return;
                    }

                    await CartService.addItem(
                      id: productId,
                      name: productName,
                      price: productPrice,
                      imageUrl:
                          imageUrl,
                    );

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pop(
                      context,
                    );

                    ScaffoldMessenger.of(
                            context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          '$productName added to cart',
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width:
                    double.infinity,
                height: 48,
                child:
                    OutlinedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const CartPage(),
                      ),
                    );
                  },
                  child:
                      const Text(
                    'Go to Cart',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final sellerName =
        widget.data['sellerName']
                ?.toString() ??
            'Seller';

    final sellerCode =
        widget.data['sellerCode']
                ?.toString();

    final caption =
        widget.data['caption']
                ?.toString() ??
            '';

    final productName =
        widget.data['productName']
            ?.toString();

    final productPrice =
        widget.data['productPrice'] is num
            ? (widget.data['productPrice']
                    as num)
                .toDouble()
            : null;

    final likeCount =
        widget.data['likeCount'] is num
            ? (widget.data['likeCount']
                    as num)
                .toInt()
            : 0;

    final viewCount =
        widget.data['viewCount'] is num
            ? (widget.data['viewCount']
                    as num)
                .toInt()
            : 0;

    final commentCount =
        widget.data['commentCount'] is num
            ? (widget.data['commentCount']
                    as num)
                .toInt()
            : 0;

    final shareCount =
        widget.data['shareCount'] is num
            ? (widget.data['shareCount']
                    as num)
                .toInt()
            : 0;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        color: Colors.black,
        width:
            double.infinity,
        height:
            double.infinity,
        child: Stack(
          alignment:
              Alignment.center,
          children: [
            // ===================================================
            // VIDEO
            // ===================================================

            if (_hasError)
              const Icon(
                Icons.broken_image,
                color:
                    Colors.white54,
                size: 60,
              )
            else if (_isInitialized &&
                _controller != null)
              FittedBox(
                fit:
                    BoxFit.cover,
                child: SizedBox(
                  width:
                      _controller!
                          .value
                          .size
                          .width,
                  height:
                      _controller!
                          .value
                          .size
                          .height,
                  child:
                      VideoPlayer(
                    _controller!,
                  ),
                ),
              )
            else
              const CircularProgressIndicator(
                color: Colors.white,
              ),

            // ===================================================
            // PLAY ICON
            // ===================================================

            if (_isInitialized &&
                _controller != null &&
                !_controller!
                    .value
                    .isPlaying)
              const Icon(
                Icons.play_arrow,
                color:
                    Colors.white70,
                size: 70,
              ),

            // ===================================================
            // BOTTOM LEFT
            // ===================================================

            Positioned(
              left: 16,
              right: 90,
              bottom: 30,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    sellerName,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (sellerCode !=
                          null &&
                      sellerCode
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Seller ID: $sellerCode',
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],

                  if (caption
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      caption,
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  ],

                  if (productName !=
                          null &&
                      productPrice !=
                          null) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    GestureDetector(
                      onTap:
                          _viewProduct,
                      child:
                          Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal:
                              14,
                          vertical: 8,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize
                                  .min,
                          children: [
                            const Icon(
                              Icons
                                  .shopping_bag_outlined,
                              size: 16,
                              color:
                                  Colors.redAccent,
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Text(
                              'View Product · '
                              '₩${productPrice.toStringAsFixed(0)}',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.black87,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize:
                                    12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ===================================================
            // RIGHT SIDE ACTIONS
            // ===================================================

            Positioned(
              right: 12,
              bottom: 30,
              child: Column(
                children: [
                  // =================================================
                  // VIEW COUNT
                  // =================================================

                  Column(
                    children: [
                      const Icon(
                        Icons
                            .visibility_outlined,
                        color:
                            Colors.white,
                        size: 27,
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        '$viewCount',
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =================================================
                  // LIKE
                  // =================================================

                  StreamBuilder<
                      DocumentSnapshot>(
                    stream: _uid == null
                        ? null
                        : _videoRef
                            .collection(
                                'likes')
                            .doc(_uid)
                            .snapshots(),
                    builder:
                        (context,
                            likeSnapshot) {
                      final isLiked =
                          likeSnapshot
                                  .data
                                  ?.exists ??
                              false;

                      return Column(
                        children: [
                          IconButton(
                            onPressed:
                                _toggleLike,
                            icon:
                                Icon(
                              isLiked
                                  ? Icons
                                      .favorite
                                  : Icons
                                      .favorite_border,
                              color: isLiked
                                  ? Colors
                                      .redAccent
                                  : Colors
                                      .white,
                              size: 30,
                            ),
                          ),
                          Text(
                            '$likeCount',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // =================================================
                  // COMMENTS
                  // =================================================

                  IconButton(
                    onPressed:
                        _openComments,
                    icon:
                        const Icon(
                      Icons
                          .mode_comment_outlined,
                      color:
                          Colors.white,
                      size: 28,
                    ),
                  ),

                  Text(
                    '$commentCount',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =================================================
                  // SHARE
                  // =================================================

                  IconButton(
                    onPressed:
                        _shareVideo,
                    icon:
                        const Icon(
                      Icons
                          .share_outlined,
                      color:
                          Colors.white,
                      size: 26,
                    ),
                  ),

                  Text(
                    '$shareCount',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// COMMENTS SHEET
// =============================================================

class _CommentsSheet
    extends StatefulWidget {
  final String videoId;

  const _CommentsSheet({
    required this.videoId,
  });

  @override
  State<_CommentsSheet> createState() =>
      _CommentsSheetState();
}

class _CommentsSheetState
    extends State<_CommentsSheet> {
  final _commentController =
      TextEditingController();

  bool _isSending = false;

  DocumentReference<Map<String, dynamic>>
      get _videoRef {
    return FirebaseFirestore.instance
        .collection('sellerVideos')
        .doc(widget.videoId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // =========================================================
  // SEND COMMENT
  // =========================================================

  Future<void> _sendComment() async {
    final text =
        _commentController.text.trim();

    if (text.isEmpty) return;

    if (text.length > 500) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Comment must be 500 characters or less.',
          ),
        ),
      );
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pop(context);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const LoginPage(),
        ),
      );

      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      String userName =
          user.email ?? 'User';

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final name =
          userDoc.data()?['name']
              ?.toString();

      if (name != null &&
          name.isNotEmpty) {
        userName = name;
      }

      final commentRef =
          _videoRef
              .collection('comments')
              .doc();

      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        transaction.set(
          commentRef,
          {
            'text': text,
            'userId': user.uid,
            'userName': userName,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );

        transaction.update(
          _videoRef,
          {
            'commentCount':
                FieldValue.increment(1),
          },
        );
      });

      _commentController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not send comment: $e',
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

  // =========================================================
  // BUILD COMMENTS
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context)
            .viewInsets
            .bottom,
      ),
      child: SizedBox(
        height:
            MediaQuery.of(context)
                    .size
                    .height *
                0.6,
        child: Column(
          children: [
            const Padding(
              padding:
                  EdgeInsets.all(16),
              child: Text(
                'Comments',
                style:
                    TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot>(
                stream:
                    _videoRef
                        .collection(
                            'comments')
                        .orderBy(
                          'createdAt',
                          descending:
                              true,
                        )
                        .snapshots(),
                builder:
                    (context,
                        snapshot) {
                  if (snapshot
                      .hasError) {
                    return const Center(
                      child: Text(
                        'Failed to load comments',
                      ),
                    );
                  }

                  if (snapshot
                          .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  final docs =
                      snapshot.data
                              ?.docs ??
                          [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No comments yet',
                      ),
                    );
                  }

                  return ListView
                      .builder(
                    itemCount:
                        docs.length,
                    itemBuilder:
                        (context,
                            index) {
                      final data =
                          docs[index]
                                  .data()
                              as Map<String,
                                  dynamic>;

                      return ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons.person,
                            size: 18,
                          ),
                        ),
                        title:
                            Text(
                          data['userName']
                                  ?.toString() ??
                              'User',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle:
                            Text(
                          data['text']
                                  ?.toString() ??
                              '',
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child:
                        TextField(
                      controller:
                          _commentController,
                      maxLength: 500,
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Add a comment...',
                        border:
                            OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets
                                .symmetric(
                          horizontal:
                              12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _isSending
                            ? null
                            : _sendComment,
                    icon:
                        const Icon(
                      Icons.send,
                      color:
                          Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
