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
        title: const Text('News Feed', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sellerVideos')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Failed to load feed', style: TextStyle(color: Colors.white)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No videos yet', style: TextStyle(color: Colors.white70)),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: docs.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _FeedVideoItem(
                videoId: doc.id,
                data: data,
                isActive: index == _currentPage,
              );
            },
          );
        },
      ),
    );
  }
}

class _FeedVideoItem extends StatefulWidget {
  final String videoId;
  final Map<String, dynamic> data;
  final bool isActive;

  const _FeedVideoItem({
    required this.videoId,
    required this.data,
    required this.isActive,
  });

  @override
  State<_FeedVideoItem> createState() => _FeedVideoItemState();
}

class _FeedVideoItemState extends State<_FeedVideoItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant _FeedVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null) return;

    if (widget.isActive && !_controller!.value.isPlaying) {
      _controller!.play();
    } else if (!widget.isActive && _controller!.value.isPlaying) {
      _controller!.pause();
    }
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.data['videoUrl']?.toString() ?? '';
    if (videoUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();
      controller.setLooping(true);

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });

      if (widget.isActive) {
        controller.play();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
    });
  }

  Future<void> _toggleLike() async {
    final uid = _uid;
    if (uid == null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }

    final likeRef = FirebaseFirestore.instance
        .collection('sellerVideos')
        .doc(widget.videoId)
        .collection('likes')
        .doc(uid);

    final videoRef = FirebaseFirestore.instance.collection('sellerVideos').doc(widget.videoId);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();
      await videoRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      await videoRef.update({'likeCount': FieldValue.increment(1)});
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _CommentsSheet(videoId: widget.videoId),
    );
  }

  void _shareVideo() {
    final videoUrl = widget.data['videoUrl']?.toString() ?? '';
    final caption = widget.data['caption']?.toString() ?? '';
    Share.share('$caption\n\nCheck this out on BuyNova: $videoUrl');
  }

  Future<void> _viewProduct() async {
    final productName = widget.data['productName']?.toString();
    final productPrice = (widget.data['productPrice'] is num)
        ? (widget.data['productPrice'] as num).toDouble()
        : 0.0;
    final productId = widget.data['productId']?.toString();

    if (productName == null || productId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                productName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${productPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Add to Cart'),
                  onPressed: () async {
                    final uid = _uid;
                    if (uid == null) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                      return;
                    }

                    await CartService.addItem(
                      id: productId,
                      name: productName,
                      price: productPrice,
                      imageUrl: null,
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$productName added to cart')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CartPage()),
                    );
                  },
                  child: const Text('Go to Cart'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellerName = widget.data['sellerName']?.toString() ?? 'Seller';
    final caption = widget.data['caption']?.toString() ?? '';
    final productName = widget.data['productName']?.toString();
    final productPrice = (widget.data['productPrice'] is num)
        ? (widget.data['productPrice'] as num).toDouble()
        : null;
    final likeCount =
        (widget.data['likeCount'] is num) ? (widget.data['likeCount'] as num).toInt() : 0;

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_hasError)
              const Icon(Icons.broken_image, color: Colors.white54, size: 60)
            else if (_isInitialized && _controller != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              const CircularProgressIndicator(color: Colors.white),

            if (_isInitialized && _controller != null && !_controller!.value.isPlaying)
              const Icon(Icons.play_arrow, color: Colors.white70, size: 70),

            // Bottom-left: seller name + caption + product
            Positioned(
              left: 16,
              right: 90,
              bottom: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sellerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (caption.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (productName != null && productPrice != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _viewProduct,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_bag_outlined,
                                size: 16, color: Colors.redAccent),
                            const SizedBox(width: 6),
                            Text(
                              'View Product Â· \$${productPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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

            // Right side: like / comment / share
            Positioned(
              right: 12,
              bottom: 30,
              child: Column(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: _uid == null
                        ? null
                        : FirebaseFirestore.instance
                            .collection('sellerVideos')
                            .doc(widget.videoId)
                            .collection('likes')
                            .doc(_uid)
                            .snapshots(),
                    builder: (context, likeSnapshot) {
                      final isLiked = likeSnapshot.data?.exists ?? false;

                      return Column(
                        children: [
                          IconButton(
                            onPressed: _toggleLike,
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.redAccent : Colors.white,
                              size: 30,
                            ),
                          ),
                          Text('$likeCount', style: const TextStyle(color: Colors.white)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: _openComments,
                    icon: const Icon(Icons.mode_comment_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    onPressed: _shareVideo,
                    icon: const Icon(Icons.share_outlined, color: Colors.white, size: 26),
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

class _CommentsSheet extends StatefulWidget {
  final String videoId;

  const _CommentsSheet({required this.videoId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }

    setState(() => _isSending = true);

    try {
      String userName = user.email ?? 'User';
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final name = userDoc.data()?['name']?.toString();
      if (name != null && name.isNotEmpty) userName = name;

      await FirebaseFirestore.instance
          .collection('sellerVideos')
          .doc(widget.videoId)
          .collection('comments')
          .add({
        'text': text,
        'userId': user.uid,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sellerVideos')
                    .doc(widget.videoId)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(child: Text('No comments yet'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person, size: 18)),
                        title: Text(
                          data['userName']?.toString() ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(data['text']?.toString() ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSending ? null : _sendComment,
                    icon: const Icon(Icons.send, color: Colors.redAccent),
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
