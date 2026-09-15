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

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  void _openPostVideo() {
    if (currentUser == null) {
      _openLogin();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddSellerVideoPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
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
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Could not load videos.\n\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.video_library_outlined,
                          color: Colors.white,
                          size: 70,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'No videos yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Be the first to post a video!',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _openPostVideo,
                          icon: const Icon(Icons.add),
                          label: const Text('Post Video'),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _topButton(
                      icon: Icons.close,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              );
            }

            return Stack(
              children: [
                PageView.builder(
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

                    return _ReelsVideoItem(
                      key: ValueKey(doc.id),
                      videoId: doc.id,
                      data: data,
                      isActive:
                          index == _currentPage,
                      onLoginRequired:
                          _openLogin,
                    );
                  },
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      _topButton(
                        icon: Icons.add,
                        onPressed: _openPostVideo,
                      ),
                      const SizedBox(width: 8),
                      _topButton(
                        icon: Icons.close,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ============================================================
// REELS VIDEO ITEM
// ============================================================

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

class _ReelsVideoItemState
    extends State<_ReelsVideoItem> {
  VideoPlayerController? _controller;

  Timer? _watchTimer;

  bool _isInitialized = false;
  bool _isPlaying = false;

  bool _isLiked = false;
  bool _isLoadingLike = false;

  bool _rewardClaimed = false;
  bool _rewardEligible = false;
  bool _isClaimingReward = false;

  bool _viewRecorded = false;

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

    _likeCount =
        _toInt(widget.data['likeCount']);

    _commentCount =
        _toInt(widget.data['commentCount']);

    _viewCount =
        _toInt(widget.data['viewCount']);

    _shareCount =
        _toInt(widget.data['shareCount']);

    _loadVideo();
    _checkLike();
    _checkReward();
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ==========================================================
  // LOAD VIDEO
  // ==========================================================

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

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _isInitialized = true;
      });

      if (widget.isActive) {
        await controller.play();

        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
        }

        _recordView();
        _startWatchTimer();
      }
    } catch (e) {
      debugPrint(
        'Video loading error: $e',
      );
    }
  }

  // ==========================================================
  // UPDATE ACTIVE VIDEO
  // ==========================================================

  @override
  void didUpdateWidget(
    covariant _ReelsVideoItem oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _playVideo();
      } else {
        _pauseVideo();
      }
    }
  }

  // ==========================================================
  // PLAY
  // ==========================================================

  Future<void> _playVideo() async {
    final controller = _controller;

    if (controller == null ||
        !_isInitialized) {
      return;
    }

    try {
      await controller.play();

      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }

      if (!_viewRecorded) {
        _recordView();
      }

      _startWatchTimer();
    } catch (e) {
      debugPrint(
        'Play error: $e',
      );
    }
  }

  // ==========================================================
  // PAUSE
  // ==========================================================

  Future<void> _pauseVideo() async {
    _stopWatchTimer();

    final controller = _controller;

    if (controller == null) {
      return;
    }

    try {
      await controller.pause();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  // ==========================================================
  // PLAY / PAUSE
  // ==========================================================

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  // ==========================================================
  // WATCH TIMER
  // ==========================================================

  void _startWatchTimer() {
    if (!_rewardEligible) {
      return;
    }

    if (_rewardClaimed) {
      return;
    }

    if (!widget.isActive) {
      return;
    }

    if (!_isPlaying) {
      return;
    }

    if (_watchTimer != null) {
      return;
    }

    _watchTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          _watchTimer = null;
          return;
        }

        if (!widget.isActive ||
            !_isPlaying ||
            _rewardClaimed) {
          timer.cancel();
          _watchTimer = null;
          return;
        }

        if (_watchSeconds <
            _requiredWatchSeconds) {
          setState(() {
            _watchSeconds++;
          });
        }

        if (_watchSeconds >=
            _requiredWatchSeconds) {
          timer.cancel();
          _watchTimer = null;

          if (mounted) {
            setState(() {});
          }
        }
      },
    );
  }

  void _stopWatchTimer() {
    _watchTimer?.cancel();
    _watchTimer = null;
  }

  // ==========================================================
  // REWARD CHECK
  // ==========================================================

  Future<void> _checkReward() async {
    _rewardEligible =
        widget.data['rewardEligible'] == true;

    final user = currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    try {
      final claimDoc =
          await FirebaseFirestore.instance
              .collection('watchRewardClaims')
              .doc(
                '${user.uid}_${widget.videoId}',
              )
              .get();

      if (!mounted) {
        return;
      }

      setState(() {
        _rewardClaimed =
            claimDoc.exists;
      });
    } catch (e) {
      debugPrint(
        'Reward check error: $e',
      );

      if (mounted) {
        setState(() {
          _rewardClaimed = false;
        });
      }
    }

    if (_rewardEligible &&
        !_rewardClaimed &&
        widget.isActive &&
        _isPlaying) {
      _startWatchTimer();
    }
  }

  // ==========================================================
  // CLAIM REWARD
  // ==========================================================

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

    if (_watchSeconds <
        _requiredWatchSeconds) {
      return;
    }

    setState(() {
      _isClaimingReward = true;
    });

    try {
      final claimId =
          '${user.uid}_${widget.videoId}';

      final claimRef =
          FirebaseFirestore.instance
              .collection('watchRewardClaims')
              .doc(claimId);

      final existingClaim =
          await claimRef.get();

      if (existingClaim.exists) {
        if (mounted) {
          setState(() {
            _rewardClaimed = true;
          });

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'You already submitted this reward.',
              ),
            ),
          );
        }

        return;
      }

      await claimRef.set({
        'userId': user.uid,
        'videoId': widget.videoId,
        'status': 'pending',
        'source': 'watch_video',
        'watchSeconds': _watchSeconds,
        'requiredSeconds':
            _requiredWatchSeconds,
        'rewardPoints': _rewardPoints,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _rewardClaimed = true;
      });

      _stopWatchTimer();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '🎉 Reward claim submitted! It will be verified.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint(
        'Reward claim error: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Could not submit reward. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClaimingReward = false;
        });
      }
    }
  }

  // ==========================================================
  // CHECK LIKE
  // ==========================================================

  Future<void> _checkLike() async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('sellerVideos')
              .doc(widget.videoId)
              .collection('likes')
              .doc(user.uid)
              .get();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLiked = doc.exists;
      });
    } catch (e) {
      debugPrint(
        'Like check error: $e',
      );
    }
  }

  // ==========================================================
  // LIKE
  // ==========================================================

  Future<void> _toggleLike() async {
    final user = currentUser;

    if (user == null) {
      widget.onLoginRequired();
      return;
    }

    if (_isLoadingLike) {
      return;
    }

    setState(() {
      _isLoadingLike = true;
    });

    final likeRef =
        FirebaseFirestore.instance
            .collection('sellerVideos')
            .doc(widget.videoId)
            .collection('likes')
            .doc(user.uid);

    final videoRef =
        FirebaseFirestore.instance
            .collection('sellerVideos')
            .doc(widget.videoId);

    try {
      await FirebaseFirestore.instance
          .runTransaction(
        (transaction) async {
          final likeDoc =
              await transaction.get(likeRef);

          final videoDoc =
              await transaction.get(videoRef);

          final currentLikes =
              _toInt(
            videoDoc.data()?['likeCount'],
          );

          if (likeDoc.exists) {
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
          }
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLiked = !_isLiked;

        if (_isLiked) {
          _likeCount++;
        } else if (_likeCount > 0) {
          _likeCount--;
        }
      });
    } catch (e) {
      debugPrint(
        'Like error: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update like.',
            ),
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

  // ==========================================================
  // VIEW
  // ==========================================================

  Future<void> _recordView() async {
    if (_viewRecorded) {
      return;
    }

    final user = currentUser;

    if (user == null) {
      return;
    }

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
      final existing =
          await viewRef.get();

      if (existing.exists) {
        _viewRecorded = true;
        return;
      }

      await FirebaseFirestore.instance
          .runTransaction(
        (transaction) async {
          final currentVideo =
              await transaction.get(videoRef);

          final currentViews =
              _toInt(
            currentVideo.data()?['viewCount'],
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

      _viewRecorded = true;

      if (mounted) {
        setState(() {
          _viewCount++;
        });
      }
    } catch (e) {
      debugPrint(
        'View error: $e',
      );
    }
  }

  // ==========================================================
  // SHARE
  // ==========================================================

  Future<void> _shareVideo() async {
    try {
      final videoUrl =
          widget.data['videoUrl']?.toString() ??
              '';

      await Share.share(
        videoUrl.isNotEmpty
            ? 'Check out this BuyNova video:\n$videoUrl'
            : 'Check out this video on BuyNova!',
      );

      final videoRef =
          FirebaseFirestore.instance
              .collection('sellerVideos')
              .doc(widget.videoId);

      await FirebaseFirestore.instance
          .runTransaction(
        (transaction) async {
          final doc =
              await transaction.get(videoRef);

          final currentShares =
              _toInt(
            doc.data()?['shareCount'],
          );

          transaction.update(
            videoRef,
            {
              'shareCount':
                  currentShares + 1,
            },
          );
        },
      );

      if (mounted) {
        setState(() {
          _shareCount++;
        });
      }
    } catch (e) {
      debugPrint(
        'Share error: $e',
      );
    }
  }

  // ==========================================================
  // COMMENTS
  // ==========================================================

  Future<void> _showComments() async {
    final user = currentUser;

    final controller =
        TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder:
              (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(context)
                        .viewInsets
                        .bottom,
              ),
              child: SizedBox(
                height:
                    MediaQuery.of(context)
                            .size
                            .height *
                        0.75,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 45,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color: Colors.grey,
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child:
                          StreamBuilder<
                              QuerySnapshot>(
                        stream:
                            FirebaseFirestore
                                .instance
                                .collection(
                                  'sellerVideos',
                                )
                                .doc(
                                  widget.videoId,
                                )
                                .collection(
                                  'comments',
                                )
                                .orderBy(
                                  'createdAt',
                                  descending:
                                      true,
                                )
                                .snapshots(),
                        builder:
                            (context, snapshot) {
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
                                'No comments yet.',
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount:
                                docs.length,
                            itemBuilder:
                                (context, index) {
                              final data =
                                  docs[index]
                                          .data()
                                      as Map<String,
                                          dynamic>;

                              final name =
                                  data['userName']
                                          ?.toString() ??
                                      'User';

                              final text =
                                  data['text']
                                          ?.toString() ??
                                      '';

                              return ListTile(
                                leading:
                                    const CircleAvatar(
                                  child: Icon(
                                    Icons.person,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                subtitle:
                                    Text(text),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    if (user == null)
                      Padding(
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        child: SizedBox(
                          width:
                              double.infinity,
                          child:
                              ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              );
                              widget
                                  .onLoginRequired();
                            },
                            child: const Text(
                              'Login to comment',
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          12,
                          4,
                          12,
                          12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller:
                                    controller,
                                maxLines: 3,
                                minLines: 1,
                                decoration:
                                    const InputDecoration(
                                  hintText:
                                      'Write a comment...',
                                  border:
                                      OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            IconButton(
                              onPressed: () async {
                                final text =
                                    controller
                                        .text
                                        .trim();

                                if (text.isEmpty) {
                                  return;
                                }

                                try {
                                  final userDoc =
                                      await FirebaseFirestore
                                          .instance
                                          .collection(
                                            'users',
                                          )
                                          .doc(
                                            user.uid,
                                          )
                                          .get();

                                  final userData =
                                      userDoc.data() ??
                                          {};

                                  final userName =
                                      userData[
                                                  'name']
                                              ?.toString() ??
                                          user.displayName ??
                                          'User';

                                  final commentsRef =
                                      FirebaseFirestore
                                          .instance
                                          .collection(
                                            'sellerVideos',
                                          )
                                          .doc(
                                            widget.videoId,
                                          )
                                          .collection(
                                            'comments',
                                          );

                                  await commentsRef
                                      .add({
                                    'userId':
                                        user.uid,
                                    'userName':
                                        userName,
                                    'userEmail':
                                        user.email,
                                    'text': text,
                                    'createdAt':
                                        FieldValue
                                            .serverTimestamp(),
                                  });

                                  await FirebaseFirestore
                                      .instance
                                      .collection(
                                        'sellerVideos',
                                      )
                                      .doc(
                                        widget
                                            .videoId,
                                      )
                                      .update({
                                    'commentCount':
                                        FieldValue
                                            .increment(
                                      1,
                                    ),
                                  });

                                  controller.clear();

                                  if (mounted) {
                                    setState(
                                      () {
                                        _commentCount++;
                                      },
                                    );
                                  }

                                  setSheetState(
                                    () {},
                                  );
                                } catch (e) {
                                  debugPrint(
                                    'Comment error: $e',
                                  );
                                }
                              },
                              icon:
                                  const Icon(
                                Icons.send,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  // ==========================================================
  // PRODUCT
  // ==========================================================

  void _openProduct() {
    final productId =
        widget.data['productId']?.toString() ??
            '';

    if (productId.isEmpty) {
      return;
    }

    // CartPage does not have productId/productName
    // parameters, so open the normal CartPage.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartPage(),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _stopWatchTimer();
    _controller?.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final sellerName =
        widget.data['sellerName']?.toString() ??
            widget.data['userName']?.toString() ??
            'BuyNova User';

    final caption =
        widget.data['caption']?.toString() ??
            '';

    final productId =
        widget.data['productId']?.toString() ??
            '';

    final productName =
        widget.data['productName']?.toString() ??
            '';

    final productPrice =
        widget.data['productPrice'];

    final productImage =
        widget.data['productImageUrl']
                ?.toString() ??
            '';

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            color: Colors.black,
            child: _isInitialized &&
                    _controller != null
                ? Center(
                    child: AspectRatio(
                      aspectRatio: _controller!
                          .value
                          .aspectRatio,
                      child: VideoPlayer(
                        _controller!,
                      ),
                    ),
                  )
                : const Center(
                    child:
                        CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        // ========================================================
        // PLAY ICON
        // ========================================================

        if (_isInitialized &&
            !_isPlaying)
          const Center(
            child: Icon(
              Icons.play_circle_fill,
              color: Colors.white70,
              size: 80,
            ),
          ),

        // ========================================================
        // BOTTOM GRADIENT
        // ========================================================

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 280,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:
                      Alignment.bottomCenter,
                  end:
                      Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(
                      alpha: 0.85,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ========================================================
        // REWARD BUTTON
        // ========================================================

        Positioned(
          top: 60,
          left: 15,
          child: _rewardButton(),
        ),

        // ========================================================
        // RIGHT ACTION BUTTONS
        // ========================================================

        Positioned(
          right: 12,
          bottom: 130,
          child: Column(
            children: [
              _actionButton(
                icon: _isLiked
                    ? Icons.favorite
                    : Icons.favorite_border,
                label: '$_likeCount',
                iconColor: _isLiked
                    ? Colors.red
                    : Colors.white,
                onPressed: _toggleLike,
              ),
              const SizedBox(height: 18),
              _actionButton(
                icon: Icons.comment,
                label: '$_commentCount',
                onPressed:
                    _showComments,
              ),
              const SizedBox(height: 18),
              _actionButton(
                icon: Icons.share,
                label: '$_shareCount',
                onPressed:
                    _shareVideo,
              ),
              const SizedBox(height: 18),
              _actionButton(
                icon: Icons.visibility,
                label: '$_viewCount',
                onPressed: () {},
              ),
            ],
          ),
        ),

        // ========================================================
        // BOTTOM INFORMATION
        // ========================================================

        Positioned(
          left: 15,
          right: 75,
          bottom: 25,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 19,
                    child: Icon(
                      Icons.person,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sellerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              if (caption.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  caption,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],

              // ==================================================
              // PRODUCT
              // ==================================================

              if (productId.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _openProduct,
                  child: Container(
                    padding:
                        const EdgeInsets.all(9),
                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.15,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        if (productImage
                            .isNotEmpty)
                          ClipRRect(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              6,
                            ),
                            child: Image.network(
                              productImage,
                              width: 45,
                              height: 45,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const Icon(
                                  Icons.image,
                                  color:
                                      Colors.white,
                                  size: 40,
                                );
                              },
                            ),
                          )
                        else
                          const Icon(
                            Icons.shopping_bag,
                            color:
                                Colors.white,
                          ),
                        const SizedBox(
                          width: 10,
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                productName
                                        .isNotEmpty
                                    ? productName
                                    : 'View Product',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              if (productPrice !=
                                  null)
                                Text(
                                  '₩${_toInt(productPrice)}',
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color:
                              Colors.white,
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
      ],
    );
  }

  // ==========================================================
  // ACTION BUTTON
  // ==========================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 27,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // REWARD BUTTON
  // ==========================================================

  Widget _rewardButton() {
    if (!_rewardEligible) {
      return const SizedBox.shrink();
    }

    if (_rewardClaimed) {
      return Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius:
              BorderRadius.circular(25),
        ),
        child: const Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.greenAccent,
              size: 20,
            ),
            SizedBox(width: 6),
            Text(
              'Claim Submitted',
              style: TextStyle(
                color: Colors.white,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_watchSeconds >=
        _requiredWatchSeconds) {
      return ElevatedButton.icon(
        onPressed: _isClaimingReward
            ? null
            : _claimReward,
        icon: _isClaimingReward
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.card_giftcard,
              ),
        label: Text(
          'Claim +$_rewardPoints',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Colors.green,
          foregroundColor:
              Colors.white,
        ),
      );
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius:
            BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '$_watchSeconds/'
            '$_requiredWatchSeconds sec',
            style: const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
