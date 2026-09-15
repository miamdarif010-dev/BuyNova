import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'login_page.dart';
import 'cart_page.dart';
import 'add_seller_video_page.dart';

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

  // =========================================================
  // LOGIN
  // =========================================================

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  // =========================================================
  // POST VIDEO
  // =========================================================

  void _openPostVideo() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _openLogin();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddSellerVideoPage(),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('sellerVideos')
            .where(
              'status',
              isEqualTo: 'published',
            )
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Stack(
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Videos could not be loaded.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                _topButtons(),
              ],
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

          final videos = snapshot.data?.docs ?? [];

          if (videos.isEmpty) {
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.video_library_outlined,
                        color: Colors.white54,
                        size: 70,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'No videos yet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _openPostVideo,
                        icon: const Icon(Icons.add),
                        label: const Text('Post Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _topButtons(),
              ],
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: videos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = videos[index].data();

                  return _ReelsVideoItem(
                    key: ValueKey(videos[index].id),
                    videoId: videos[index].id,
                    data: data,
                    isActive: index == _currentPage,
                    onLoginRequired: _openLogin,
                  );
                },
              ),
              _topButtons(),
              Positioned(
                top: 58,
                left: 20,
                child: SafeArea(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Videos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // TOP BUTTONS
  // =========================================================

  Widget _topButtons() {
    return Positioned(
      top: 45,
      right: 12,
      child: SafeArea(
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _openPostVideo,
                tooltip: 'Post Video',
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// REELS VIDEO ITEM
// ===================================================================

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
  State<_ReelsVideoItem> createState() =>
      _ReelsVideoItemState();
}

class _ReelsVideoItemState extends State<_ReelsVideoItem> {
  VideoPlayerController? _controller;

  Timer? _watchTimer;

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLiked = false;
  bool _isLoadingLike = false;

  bool _rewardClaimed = false;
  bool _rewardEligible = false;
  bool _isClaimingReward = false;

  int _watchSeconds = 0;

  static const int _requiredWatchSeconds = 10;
  static const int _rewardPoints = 5;

  int _likeCount = 0;
  int _commentCount = 0;
  int _viewCount = 0;
  int _shareCount = 0;

  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();

    _likeCount = _toInt(widget.data['likeCount']);
    _commentCount = _toInt(widget.data['commentCount']);
    _viewCount = _toInt(widget.data['viewCount']);
    _shareCount = _toInt(widget.data['shareCount']);

    _loadVideo();
    _checkLike();
    _checkReward();

    if (widget.isActive) {
      _recordView();
    }
  }

  @override
  void didUpdateWidget(
    covariant _ReelsVideoItem oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _playVideo();
      _recordView();
      _startWatchTimer();
    }

    if (!widget.isActive && oldWidget.isActive) {
      _pauseVideo();
      _stopWatchTimer();
    }
  }

  // =========================================================
  // LOAD VIDEO
  // =========================================================

  Future<void> _loadVideo() async {
    final videoUrl =
        widget.data['videoUrl']?.toString() ?? '';

    if (videoUrl.isEmpty) {
      return;
    }

    try {
      final controller =
          VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      _controller = controller;

      await controller.initialize();
      await controller.setLooping(true);

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      if (widget.isActive) {
        await controller.play();

        if (mounted) {
          setState(() {
            _isPlaying = true;
          });

          _startWatchTimer();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  // =========================================================
  // PLAY
  // =========================================================

  Future<void> _playVideo() async {
    final controller = _controller;

    if (controller == null || !_isInitialized) {
      return;
    }

    try {
      await controller.play();

      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }

      _startWatchTimer();
    } catch (_) {}
  }

  // =========================================================
  // PAUSE
  // =========================================================

  Future<void> _pauseVideo() async {
    final controller = _controller;

    if (controller == null) return;

    try {
      await controller.pause();

      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }

      _stopWatchTimer();
    } catch (_) {}
  }

  // =========================================================
  // PLAY / PAUSE
  // =========================================================

  Future<void> _togglePlayPause() async {
    final controller = _controller;

    if (controller == null || !_isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await _pauseVideo();
    } else {
      await _playVideo();
    }
  }

  // =========================================================
  // WATCH TIMER
  // =========================================================

  void _startWatchTimer() {
    if (_rewardClaimed || _rewardEligible) {
      return;
    }

    if (!widget.isActive) {
      return;
    }

    if (_watchTimer != null) {
      return;
    }

    _watchTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        final controller = _controller;

        if (!mounted ||
            !widget.isActive ||
            controller == null ||
            !controller.value.isPlaying) {
          return;
        }

        if (_watchSeconds >= _requiredWatchSeconds) {
          _stopWatchTimer();

          if (mounted) {
            setState(() {
              _rewardEligible = true;
            });
          }

          return;
        }

        setState(() {
          _watchSeconds++;
        });

        if (_watchSeconds >= _requiredWatchSeconds) {
          _stopWatchTimer();

          if (mounted) {
            setState(() {
              _rewardEligible = true;
            });
          }
        }
      },
    );
  }

  void _stopWatchTimer() {
    _watchTimer?.cancel();
    _watchTimer = null;
  }

  // =========================================================
  // CHECK EXISTING REWARD
  // =========================================================

  Future<void> _checkReward() async {
    final user = currentUser;

    if (user == null) return;

    try {
      final rewardDoc = await FirebaseFirestore.instance
          .collection('sellerVideos')
          .doc(widget.videoId)
          .collection('rewards')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (rewardDoc.exists) {
        setState(() {
          _rewardClaimed = true;
          _rewardEligible = false;
        });
      }
    } catch (_) {}
  }

  // =========================================================
  // CLAIM REWARD
  // =========================================================

  Future<void> _claimReward() async {
    final user = currentUser;

    if (user == null) {
      widget.onLoginRequired();
      return;
    }

    if (!_rewardEligible ||
        _rewardClaimed ||
        _isClaimingReward) {
      return;
    }

    setState(() {
      _isClaimingReward = true;
    });

    final firestore =
        FirebaseFirestore.instance;

    final userRef =
        firestore.collection('users').doc(user.uid);

    final rewardRef = firestore
        .collection('sellerVideos')
        .doc(widget.videoId)
        .collection('rewards')
        .doc(user.uid);

    final transactionRef = userRef
        .collection('walletTransactions')
        .doc();

    try {
      await firestore.runTransaction(
        (transaction) async {
          final rewardSnapshot =
              await transaction.get(rewardRef);

          if (rewardSnapshot.exists) {
            throw Exception('ALREADY_REWARDED');
          }

          final userSnapshot =
              await transaction.get(userRef);

          final userData =
              userSnapshot.data() ?? {};

          final currentPoints =
              _toInt(userData['pointsBalance']);

          final lifetimePoints =
              _toInt(userData['lifetimePoints']);

          transaction.set(
            rewardRef,
            {
              'userId': user.uid,
              'videoId': widget.videoId,
              'points': _rewardPoints,
              'watchSeconds': _watchSeconds,
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.set(
            transactionRef,
            {
              'type': 'watch_and_earn',
              'points': _rewardPoints,
              'source': 'video_watch',
              'referenceId': widget.videoId,
              'status': 'earned',
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.set(
            userRef,
            {
              'pointsBalance':
                  currentPoints + _rewardPoints,
              'lifetimePoints':
                  lifetimePoints + _rewardPoints,
            },
            SetOptions(merge: true),
          );
        },
      );

      if (!mounted) return;

      setState(() {
        _rewardClaimed = true;
        _rewardEligible = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🎉 You earned 5 Points!',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message =
          e.toString().contains('ALREADY_REWARDED')
              ? 'You already earned the reward for this video.'
              : 'Reward could not be added. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClaimingReward = false;
        });
      }
    }
  }

  // =========================================================
  // CHECK LIKE
  // =========================================================

  Future<void> _checkLike() async {
    final user = currentUser;

    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('sellerVideos')
          .doc(widget.videoId)
          .collection('likes')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      setState(() {
        _isLiked = doc.exists;
      });
    } catch (_) {}
  }

  // =========================================================
  // LIKE
  // =========================================================

  Future<void> _toggleLike() async {
    final user = currentUser;

    if (user == null) {
      widget.onLoginRequired();
      return;
    }

    if (_isLoadingLike) return;

    setState(() {
      _isLoadingLike = true;
    });

    final videoRef =
        FirebaseFirestore.instance
            .collection('sellerVideos')
            .doc(widget.videoId);

    final likeRef =
        videoRef
            .collection('likes')
            .doc(user.uid);

    try {
      final result =
          await FirebaseFirestore.instance
              .runTransaction(
        (transaction) async {
          final likeSnapshot =
              await transaction.get(likeRef);

          final videoSnapshot =
              await transaction.get(videoRef);

          final currentLikes =
              _toInt(
            videoSnapshot.data()?['likeCount'],
          );

          if (likeSnapshot.exists) {
            transaction.delete(likeRef);

            transaction.update(
              videoRef,
              {
                'likeCount':
                    currentLikes > 0
                        ? currentLikes - 1
                        : 0,
              },
            );

            return false;
          } else {
            transaction.set(
              likeRef,
              {
                'userId': user.uid,
                'createdAt':
                    FieldValue.serverTimestamp(),
              },
            );

            transaction.update(
              videoRef,
              {
                'likeCount':
                    currentLikes + 1,
              },
            );

            return true;
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isLiked = result;

        if (result) {
          _likeCount++;
        } else if (_likeCount > 0) {
          _likeCount--;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update like'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLike = false;
        });
      }
    }
  }

  // =========================================================
  // VIEW
  // =========================================================

  Future<void> _recordView() async {
    final user = currentUser;

    if (user == null) return;

    final viewRef =
        FirebaseFirestore.instance
            .collection('sellerVideos')
            .doc(widget.videoId)
            .collection('views')
            .doc(user.uid);

    final videoRef =
        FirebaseFirestore.instance
            .collection('sellerVideos')
            .doc(widget.videoId);

    try {
      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final viewSnapshot =
              await transaction.get(viewRef);

          if (viewSnapshot.exists) {
            return;
          }

          final videoSnapshot =
              await transaction.get(videoRef);

          final currentViews =
              _toInt(
            videoSnapshot.data()?['viewCount'],
          );

          transaction.set(
            viewRef,
            {
              'userId': user.uid,
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.update(
            videoRef,
            {
              'viewCount':
                  currentViews + 1,
            },
          );
        },
      );

      if (mounted) {
        setState(() {
          _viewCount++;
        });
      }
    } catch (_) {}
  }

  // =========================================================
  // SHARE
  // =========================================================

  Future<void> _shareVideo() async {
    final videoUrl =
        widget.data['videoUrl']?.toString() ?? '';

    if (videoUrl.isEmpty) return;

    try {
      await Share.share(
        'Check out this video on BuyNova!\n\n$videoUrl',
      );

      final videoRef =
          FirebaseFirestore.instance
              .collection('sellerVideos')
              .doc(widget.videoId);

      await videoRef.update({
        'shareCount':
            FieldValue.increment(1),
      });

      if (mounted) {
        setState(() {
          _shareCount++;
        });
      }
    } catch (_) {}
  }

  // =========================================================
  // COMMENTS
  // =========================================================

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CommentsSheet(
          videoId: widget.videoId,
          onCommentAdded: () {
            if (mounted) {
              setState(() {
                _commentCount++;
              });
            }
          },
        );
      },
    );
  }

  // =========================================================
  // PRODUCT
  // =========================================================

  void _openProduct() {
    final productId =
        widget.data['productId']?.toString() ?? '';

    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No product attached to this video',
          ),
        ),
      );

      return;
    }

    final productName =
        widget.data['productName']?.toString() ??
            'Product';

    final productPrice =
        _toDouble(widget.data['productPrice']);

    final imageUrl =
        widget.data['productImageUrl']?.toString() ??
            widget.data['imageUrl']?.toString() ??
            '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
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
                Row(
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return Container(
                              width: 70,
                              height: 70,
                              color:
                                  Colors.grey.shade200,
                              child:
                                  const Icon(
                                Icons.image,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
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
                          const SizedBox(height: 5),
                          Text(
                            '₩${productPrice.toStringAsFixed(0)}',
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const CartPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.shopping_cart,
                    ),
                    label: const Text('Go to Cart'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // USER NAME
  // =========================================================

  String _sellerName() {
    return widget.data['sellerName']?.toString() ??
        widget.data['userName']?.toString() ??
        'BuyNova User';
  }

  // =========================================================
  // CAPTION
  // =========================================================

  String _caption() {
    return widget.data['caption']?.toString() ?? '';
  }

  // =========================================================
  // REWARD BUTTON
  // =========================================================

  Widget _rewardButton() {
    if (currentUser == null) {
      return GestureDetector(
        onTap: widget.onLoginRequired,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white24,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Login to Earn',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_rewardClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 19,
            ),
            SizedBox(width: 6),
            Text(
              'Reward Earned +5',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_rewardEligible) {
      return GestureDetector(
        onTap: _isClaimingReward
            ? null
            : _claimReward,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isClaimingReward)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 7),
              Text(
                _isClaimingReward
                    ? 'Adding...'
                    : 'Claim +5 Points',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final progress =
        (_watchSeconds / _requiredWatchSeconds)
            .clamp(0.0, 1.0);

    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monetization_on_outlined,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Watch & Earn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor:
                        Colors.white24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '$_watchSeconds/$_requiredWatchSeconds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _stopWatchTimer();
    _controller?.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD REELS
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
          ),

          if (controller != null &&
              _isInitialized)
            Center(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width:
                      controller.value.size.width,
                  height:
                      controller.value.size.height,
                  child:
                      VideoPlayer(controller),
                ),
              ),
            ),

          if (!_isInitialized)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          if (_isInitialized && !_isPlaying)
            const Center(
              child: CircleAvatar(
                radius: 34,
                backgroundColor:
                    Colors.black54,
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 300,
            child: IgnorePointer(
              child: Container(
                decoration:
                    const BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.bottomCenter,
                    end:
                        Alignment.topCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // =====================================================
          // WATCH & EARN
          // =====================================================

          Positioned(
            left: 16,
            bottom: 205,
            child: SafeArea(
              child: _rewardButton(),
            ),
          ),

          // =====================================================
          // USER + CAPTION + PRODUCT
          // =====================================================

          Positioned(
            left: 16,
            right: 90,
            bottom: 28,
            child: SafeArea(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 21,
                        backgroundColor:
                            Colors.white24,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '@${_sellerName()}',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_caption().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _caption(),
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ],

                  if ((widget.data['productId']
                              ?.toString()
                              .isNotEmpty ??
                          false)) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _openProduct,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_bag,
                              color: Colors.black,
                              size: 20,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                widget.data[
                                            'productName']
                                        ?.toString() ??
                                    'View Product',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color: Colors.black,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.black,
                              size: 15,
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

          // =====================================================
          // RIGHT ACTION BUTTONS
          // =====================================================

          Positioned(
            right: 12,
            bottom: 55,
            child: SafeArea(
              child: Column(
                children: [
                  _ActionButton(
                    icon: _isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: _formatCount(_likeCount),
                    iconColor: _isLiked
                        ? Colors.red
                        : Colors.white,
                    onTap: _toggleLike,
                  ),

                  const SizedBox(height: 22),

                  _ActionButton(
                    icon: Icons.comment,
                    label:
                        _formatCount(_commentCount),
                    onTap: _openComments,
                  ),

                  const SizedBox(height: 22),

                  _ActionButton(
                    icon: Icons.share,
                    label:
                        _formatCount(_shareCount),
                    onTap: _shareVideo,
                  ),

                  const SizedBox(height: 22),

                  _ActionButton(
                    icon: Icons.visibility,
                    label:
                        _formatCount(_viewCount),
                    onTap: () {},
                  ),

                  const SizedBox(height: 22),

                  _ActionButton(
                    icon: Icons.shopping_cart,
                    label: 'Buy',
                    onTap: _openProduct,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INT
  // =========================================================

  static int _toInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // DOUBLE
  // =========================================================

  static double _toDouble(dynamic value) {
    if (value is double) return value;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // FORMAT COUNT
  // =========================================================

  static String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toString();
  }
}

// ===================================================================
// ACTION BUTTON
// ===================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration:
                const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
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

// ===================================================================
// COMMENTS SHEET
// ===================================================================

class _CommentsSheet extends StatefulWidget {
  final String videoId;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({
    required this.videoId,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsSheet> createState() =>
      _CommentsSheetState();
}

class _CommentsSheetState
    extends State<_CommentsSheet> {
  final TextEditingController
      _commentController =
      TextEditingController();

  bool _sending = false;

  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  // =========================================================
  // SEND COMMENT
  // =========================================================

  Future<void> _sendComment() async {
    final user = currentUser;

    if (user == null) {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );

      return;
    }

    final text =
        _commentController.text.trim();

    if (text.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    final videoRef =
        FirebaseFirestore.instance
            .collection('sellerVideos')
            .doc(widget.videoId);

    final commentRef =
        videoRef.collection('comments').doc();

    try {
      await FirebaseFirestore.instance
          .runTransaction(
        (transaction) async {
          final videoSnapshot =
              await transaction.get(videoRef);

          final currentComments =
              _toInt(
            videoSnapshot.data()?[
                'commentCount'],
          );

          transaction.set(
            commentRef,
            {
              'userId': user.uid,
              'userName':
                  user.displayName ??
                      user.email ??
                      'BuyNova User',
              'text': text,
              'createdAt':
                  FieldValue.serverTimestamp(),
            },
          );

          transaction.update(
            videoRef,
            {
              'commentCount':
                  currentComments + 1,
            },
          );
        },
      );

      _commentController.clear();

      widget.onCommentAdded();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text('Comment added'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content:
                Text('Could not add comment'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD COMMENTS
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Container(
      height:
          MediaQuery.of(context).size.height *
              0.72,
      padding: EdgeInsets.only(
        bottom: bottomInset,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius:
                  BorderRadius.circular(10),
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
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance
                      .collection(
                          'sellerVideos')
                      .doc(widget.videoId)
                      .collection('comments')
                      .orderBy(
                        'createdAt',
                        descending: true,
                      )
                      .snapshots(),
              builder:
                  (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                final comments =
                    snapshot.data?.docs ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: comments.length,
                  itemBuilder:
                      (context, index) {
                    final data =
                        comments[index].data();

                    final name =
                        data['userName']
                                ?.toString() ??
                            'BuyNova User';

                    final text =
                        data['text']
                                ?.toString() ??
                            '';

                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 9,
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            child: Icon(
                              Icons.person,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  name,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(text),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              12,
              8,
              12,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _commentController,
                    maxLength: 500,
                    decoration:
                        InputDecoration(
                      hintText:
                          'Write a comment...',
                      counterText: '',
                      filled: true,
                      fillColor:
                          Colors.grey.shade100,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          25,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                CircleAvatar(
                  radius: 24,
                  child: IconButton(
                    onPressed:
                        _sending
                            ? null
                            : _sendComment,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INT
  // =========================================================

  static int _toInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
