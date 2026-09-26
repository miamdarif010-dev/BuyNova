import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'login_page.dart';
import 'cart_page.dart';
import 'watch_earn_page.dart';
import 'user_profile_page.dart';

class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({super.key});

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _sortVideos(
    List<QueryDocumentSnapshot> docs,
  ) {
    final sorted = List<QueryDocumentSnapshot>.from(docs);

    sorted.sort((a, b) {
      final aData = a.data();
      final bData = b.data();

      final aTimestamp = aData['createdAt'];
      final bTimestamp = bData['createdAt'];

      DateTime? aDate;
      DateTime? bDate;

      if (aTimestamp is Timestamp) {
        aDate = aTimestamp.toDate();
      }

      if (bTimestamp is Timestamp) {
        bDate = bTimestamp.toDate();
      }

      if (aDate == null && bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return bDate.compareTo(aDate);
    });

    return sorted;
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sellerVideos')
            .where(
              'status',
              isEqualTo: 'published',
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load videos.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }

          final rawDocs = snapshot.data?.docs ?? [];

          if (rawDocs.isEmpty) {
            return const Center(
              child: Text(
                'No videos available yet.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            );
          }

          final docs = _sortVideos(rawDocs);

          if (_currentPage >= docs.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              final newIndex = docs.isEmpty ? 0 : docs.length - 1;

              if (_currentPage != newIndex) {
                setState(() {
                  _currentPage = newIndex;
                });
              }
            });
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: docs.length,
                onPageChanged: (index) {
                  if (!mounted) return;

                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();

                  return _ReelsVideoItem(
                    key: ValueKey(doc.id),
                    videoId: doc.id,
                    data: data,
                    isActive: index == _currentPage,
                    onLoginRequired: _openLogin,
                  );
                },
              ),
              Positioned(
                top: 8,
                left: 10,
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WatchEarnPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 19,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Earn',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: SafeArea(
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReelsVideoItem extends StatefulWidget {
  final String videoId;
  final Map<String, dynamic> data;
  final bool isActive;
  final VoidCallback onLoginRequired;

  const _ReelsVideoItem({
    super.key,
    required this.videoId,
    required this.data,
    required this.isActive,
    required this.onLoginRequired,
  });

  @override
  State<_ReelsVideoItem> createState() => _ReelsVideoItemState();
}

class _ReelsVideoItemState extends State<_ReelsVideoItem> {
  VideoPlayerController? _controller;

  Timer? _viewTimer;

  bool _isLoading = true;
  bool _hasError = false;
  bool _isLiked = false;
  bool _isSharing = false;

  int _likeCount = 0;
  int _commentCount = 0;
  int _shareCount = 0;
  int _viewCount = 0;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String get sellerId {
    final seller = widget.data['sellerId']?.toString().trim();

    if (seller != null && seller.isNotEmpty) {
      return seller;
    }

    final user = widget.data['userId']?.toString().trim();

    if (user != null && user.isNotEmpty) {
      return user;
    }

    return '';
  }

  String get sellerName {
    final name = widget.data['sellerName']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final name2 = widget.data['userName']?.toString().trim();

    if (name2 != null && name2.isNotEmpty) {
      return name2;
    }

    return 'BuyNova User';
  }

  String get sellerProfileImageUrl {
    final values = [
      widget.data['sellerProfileImageUrl'],
      widget.data['profileImageUrl'],
      widget.data['userProfileImageUrl'],
    ];

    for (final value in values) {
      final url = value?.toString().trim();

      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    return '';
  }

  @override
  void initState() {
    super.initState();

    _likeCount = _toInt(widget.data['likeCount']);
    _commentCount = _toInt(widget.data['commentCount']);
    _shareCount = _toInt(widget.data['shareCount']);
    _viewCount = _toInt(widget.data['viewCount']);

    _loadVideo();
    _checkLikeStatus();
  }

  @override
  void didUpdateWidget(covariant _ReelsVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _playVideo();
        _startViewTimer();
      } else {
        _pauseVideo();
        _viewTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadVideo() async {
    final url = widget.data['videoUrl']?.toString().trim() ?? '';

    if (url.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      await controller.initialize();

      controller.setLooping(true);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isLoading = false;
      });

      if (widget.isActive) {
        await controller.play();
        _startViewTimer();
      }
    } catch (e) {
      debugPrint('Video load error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _playVideo() async {
    final controller = _controller;

    if (controller == null) return;

    if (!controller.value.isInitialized) return;

    try {
      await controller.play();
    } catch (e) {
      debugPrint('Video play error: $e');
    }
  }

  Future<void> _pauseVideo() async {
    final controller = _controller;

    if (controller == null) return;

    if (!controller.value.isInitialized) return;

    try {
      await controller.pause();
    } catch (e) {
      debugPrint('Video pause error: $e');
    }
  }

  void _startViewTimer() {
    _viewTimer?.cancel();

    _viewTimer = Timer(
      const Duration(seconds: 3),
      _registerView,
    );
  }

  Future<void> _registerView() async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      final viewRef = FirebaseFirestore.instance
          .collection('sellerVideos')
          .doc(widget.videoId)
          .collection('views')
          .doc(user.uid);

      final viewSnapshot = await viewRef.get();

      if (viewSnapshot.exists) {
        return;
      }

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final videoRef = FirebaseFirestore.instance
              .collection('sellerVideos')
              .doc(widget.videoId);

          final videoSnapshot = await transaction.get(videoRef);

          if (!videoSnapshot.exists) {
            return;
          }

          final data = videoSnapshot.data();

          final currentCount = _toInt(
            data?['viewCount'],
          );

          transaction.set(viewRef, {
            'userId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          transaction.update(videoRef, {
            'viewCount': currentCount + 1,
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _viewCount++;
      });
    } catch (e) {
      debugPrint('View error: $e');
    }
  }

  Future<void> _checkLikeStatus() async {
    final user = currentUser;

    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sellerVideos')
          .doc(widget.videoId)
          .collection('likes')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        _isLiked = snapshot.exists;
      });
    } catch (e) {
      debugPrint('Like status error: $e');
    }
  }

  Future<void> _toggleLike() async {
    final user = currentUser;

    if (user == null) {
      widget.onLoginRequired();
      return;
    }

    final likeRef = FirebaseFirestore.instance
        .collection('sellerVideos')
        .doc(widget.videoId)
        .collection('likes')
        .doc(user.uid);

    final videoRef = FirebaseFirestore.instance
        .collection('sellerVideos')
        .doc(widget.videoId);

    try {
      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final likeSnapshot = await transaction.get(likeRef);
          final videoSnapshot = await transaction.get(videoRef);

          if (!videoSnapshot.exists) return;

          final data = videoSnapshot.data();

          int count = _toInt(
            data?['likeCount'],
          );

          if (likeSnapshot.exists) {
            transaction.delete(likeRef);

            if (count > 0) {
              count--;
            }
          } else {
            transaction.set(likeRef, {
              'userId': user.uid,
              'createdAt': FieldValue.serverTimestamp(),
            });

            count++;
          }

          transaction.update(videoRef, {
            'likeCount': count,
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _isLiked = !_isLiked;

        if (_isLiked) {
          _likeCount++;
        } else if (_likeCount > 0) {
          _likeCount--;
        }
      });
    } catch (e) {
      debugPrint('Like error: $e');
    }
  }

  Future<void> _openComments() async {
    final user = currentUser;

    if (user == null) {
      widget.onLoginRequired();
      return;
    }

    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SizedBox(
              height: 500,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('sellerVideos')
                          .doc(widget.videoId)
                          .collection('comments')
                          .orderBy(
                            'createdAt',
                            descending: false,
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Could not load comments.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No comments yet.',
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data();

                            final name =
                                data['userName']?.toString() ?? 'User';

                            final text =
                                data['text']?.toString() ?? '';

                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(text),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      6,
                      12,
                      12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            final text = controller.text.trim();

                            if (text.isEmpty) return;

                            try {
                              final commentRef =
                                  FirebaseFirestore.instance
                                      .collection('sellerVideos')
                                      .doc(widget.videoId)
                                      .collection('comments')
                                      .doc();

                              await commentRef.set({
                                'userId': user.uid,
                                'userName':
                                    user.displayName ?? 'BuyNova User',
                                'text': text,
                                'createdAt':
                                    FieldValue.serverTimestamp(),
                              });

                              final videoRef =
                                  FirebaseFirestore.instance
                                      .collection('sellerVideos')
                                      .doc(widget.videoId);

                              await videoRef.update({
                                'commentCount':
                                    FieldValue.increment(1),
                              });

                              controller.clear();

                              if (mounted) {
                                setState(() {
                                  _commentCount++;
                                });
                              }
                            } catch (e) {
                              debugPrint(
                                'Comment error: $e',
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.send,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();
  }

  Future<void> _shareVideo() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final url =
          widget.data['videoUrl']?.toString() ?? '';

      final caption =
          widget.data['caption']?.toString() ?? '';

      await Share.share(
        caption.isEmpty
            ? url
            : '$caption\n\n$url',
      );

      try {
        await FirebaseFirestore.instance
            .collection('sellerVideos')
            .doc(widget.videoId)
            .update({
          'shareCount': FieldValue.increment(1),
        });

        if (mounted) {
          setState(() {
            _shareCount++;
          });
        }
      } catch (e) {
        debugPrint('Share count error: $e');
      }
    } catch (e) {
      debugPrint('Share error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _openSellerProfile() {
    if (sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller profile ID is not available.',
          ),
        ),
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserProfilePage(
          userId: sellerId,
          initialName: sellerName,
          initialProfileImageUrl: sellerProfileImageUrl,
        ),
      ),
    );
  }

  void _openProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CartPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    final caption =
        widget.data['caption']?.toString() ?? '';

    final productName =
        widget.data['productName']?.toString() ?? '';

    final productPrice =
        widget.data['productPrice']?.toString() ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),

        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),

        if (_hasError)
          const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 55,
            ),
          ),

        if (controller != null &&
            controller.value.isInitialized)
          GestureDetector(
            onTap: () {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }

              setState(() {});
            },
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              height: 320,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: 60,
          left: 15,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WatchEarnPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 18,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Earn',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          right: 12,
          bottom: 22,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionButton(
                  icon: _isLiked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: _likeCount.toString(),
                  color: _isLiked
                      ? Colors.red
                      : Colors.white,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 14),
                _actionButton(
                  icon: Icons.comment,
                  label: _commentCount.toString(),
                  onTap: _openComments,
                ),
                const SizedBox(height: 14),
                _actionButton(
                  icon: Icons.share,
                  label: _shareCount.toString(),
                  onTap: _isSharing ? () {} : _shareVideo,
                ),
                const SizedBox(height: 14),
                _actionButton(
                  icon: Icons.visibility,
                  label: _viewCount.toString(),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),

        Positioned(
          left: 15,
          right: 80,
          bottom: 22,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _openSellerProfile,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage:
                            sellerProfileImageUrl.isNotEmpty
                                ? NetworkImage(
                                    sellerProfileImageUrl,
                                  )
                                : null,
                        child: sellerProfileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                if (productName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _openProduct,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shopping_bag,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              productPrice.isEmpty
                                  ? productName
                                  : '$productName • $productPrice',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
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
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 27,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
