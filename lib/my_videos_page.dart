import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'add_seller_video_page.dart';
import 'video_player_page.dart';

class MyVideosPage extends StatefulWidget {
  const MyVideosPage({super.key});

  @override
  State<MyVideosPage> createState() => _MyVideosPageState();
}

class _MyVideosPageState extends State<MyVideosPage> {
  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  // Cap how many videos load at once. Raise this or add real
  // pagination later if a seller regularly posts more than this.
  static const int _videoLimit = 100;

  // Tracks video IDs currently being deleted, so the delete
  // button can be disabled and a double-tap can't open two
  // confirmation dialogs or fire two deletes for the same video.
  final Set<String> _deletingIds = {};

  // =========================================================
  // OPEN ADD VIDEO
  // =========================================================

  Future<void> _openAddVideo() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddSellerVideoPage(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // DELETE CLOUDINARY MEDIA (best-effort, server-side)
  // =========================================================
  //
  // Cloudinary deletion requires a signed request (API secret),
  // which must never live in the client app. This calls a
  // Firebase Cloud Function ("deleteCloudinaryVideo") that holds
  // the credentials and performs the actual deletion. If that
  // function isn't deployed yet, or the call fails, we still
  // proceed to delete the Firestore document below rather than
  // blocking the user â€” but the underlying files may be left
  // behind on Cloudinary until the function exists.

  Future<void> _deleteCloudinaryMedia({
    required String videoUrl,
    required String thumbnailUrl,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('deleteCloudinaryVideo')
          .call(<String, dynamic>{
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
      });
    } catch (e) {
      // Non-fatal: log only. The Firestore document delete below
      // still proceeds so the video disappears from the app even
      // if the Cloudinary cleanup function is missing or fails.
      debugPrint('Cloudinary cleanup failed: $e');
    }
  }

  // =========================================================
  // DELETE VIDEO
  // =========================================================

  Future<void> _deleteVideo(
    String videoId,
  ) async {
    final user = currentUser;

    if (user == null) return;

    // Prevent double-tap: ignore if this video is already
    // being deleted.
    if (_deletingIds.contains(videoId)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Video',
          ),
          content: const Text(
            'Are you sure you want to delete this video?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Re-check in case the dialog was somehow triggered twice
    // before the first confirmation resolved.
    if (_deletingIds.contains(videoId)) return;

    setState(() {
      _deletingIds.add(videoId);
    });

    try {
      final videoRef = FirebaseFirestore.instance
          .collection('sellerVideos')
          .doc(videoId);

      final videoDoc = await videoRef.get();

      if (!videoDoc.exists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Video no longer exists.',
            ),
          ),
        );

        setState(() {
          _deletingIds.remove(videoId);
        });

        return;
      }

      final data = videoDoc.data();

      // =====================================================
      // OWNER SECURITY CHECK
      // =====================================================

      final ownerId =
          (data?['userId'] ?? '').toString();

      final sellerId =
          (data?['sellerId'] ?? '').toString();

      if (ownerId != user.uid &&
          sellerId != user.uid) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You can only delete your own videos.',
            ),
          ),
        );

        setState(() {
          _deletingIds.remove(videoId);
        });

        return;
      }

      final videoUrl =
          (data?['videoUrl'] ?? '').toString();

      final thumbnailUrl =
          (data?['thumbnailUrl'] ?? '').toString();

      // Clean up the Cloudinary files first (best-effort), then
      // remove the Firestore record.
      if (videoUrl.isNotEmpty) {
        await _deleteCloudinaryMedia(
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
        );
      }

      await videoRef.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Video deleted successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _deletingIds.remove(videoId);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deletingIds.remove(videoId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete video: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // OPEN VIDEO
  // =========================================================

  void _openVideo(
    Map<String, dynamic> data,
  ) {
    final videoUrl =
        (data['videoUrl'] ?? '').toString();

    if (videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Video URL is not available.',
          ),
        ),
      );

      return;
    }

    final sellerName =
        (data['userName'] ??
                data['sellerName'] ??
                'BuyNova User')
            .toString();

    final caption =
        (data['caption'] ?? '').toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(
          videoUrl: videoUrl,
          sellerName: sellerName,
          caption: caption,
        ),
      ),
    );
  }

  // =========================================================
  // VIDEO QUERY
  // =========================================================
  //
  // NOTE: this where() + orderBy() combination requires a
  // Firestore composite index (userId ASC, createdAt DESC).
  // If it isn't created yet, Firestore returns an error the
  // first time this runs, with a link in the error message to
  // auto-create it in the Firebase Console â€” this is expected
  // and not a code bug.

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _myVideosStream() {
    final user = currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('sellerVideos')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(_videoLimit)
        .snapshots();
  }

  // =========================================================
  // VIDEO CARD
  // =========================================================

  Widget _videoCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
  ) {
    final data = doc.data();

    final videoUrl =
        (data['videoUrl'] ?? '').toString();

    final thumbnailUrl =
        (data['thumbnailUrl'] ?? '').toString();

    final caption =
        (data['caption'] ?? '').toString();

    final status =
        (data['status'] ?? 'published')
            .toString();

    // =======================================================
    // IMPORTANT:
    // New video system uses viewCount / likeCount.
    // Old videos may still use views / likes.
    // We support BOTH.
    // =======================================================

    final views = _toInt(
      data['viewCount'] ??
          data['views'],
    );

    final likes = _toInt(
      data['likeCount'] ??
          data['likes'],
    );

    final isDeleting = _deletingIds.contains(doc.id);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (videoUrl.isEmpty || isDeleting)
            ? null
            : () {
                _openVideo(data);
              },
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // VIDEO PREVIEW
            // =================================================

            AspectRatio(
              aspectRatio: 9 / 16,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnailUrl.isNotEmpty)
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _videoPlaceholder();
                      },
                    )
                  else
                    _videoPlaceholder(),

                  // PLAY BUTTON

                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration:
                          const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black54,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),

                  // STATUS

                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.black54,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        status,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // DELETE BUTTON

                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color:
                          Colors.black54,
                      shape:
                          const CircleBorder(),
                      child: isDeleting
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: () {
                                _deleteVideo(
                                  doc.id,
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                              tooltip:
                                  'Delete video',
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // VIDEO INFORMATION
            // =================================================

            Padding(
              padding:
                  const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  if (caption.isNotEmpty)
                    Text(
                      caption,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                  const SizedBox(
                    height: 10,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 18,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Text(
                        '$views views',
                      ),

                      const SizedBox(
                        width: 18,
                      ),

                      const Icon(
                        Icons.favorite_border,
                        size: 18,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Text(
                        '$likes likes',
                      ),

                      const Spacer(),

                      const Icon(
                        Icons.play_circle_outline,
                        size: 18,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      const Text(
                        'Watch',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PLACEHOLDER
  // =========================================================

  Widget _videoPlaceholder() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(
          Icons.video_library_outlined,
          size: 60,
          color: Colors.grey,
        ),
      ),
    );
  }

  // =========================================================
  // INT CONVERTER
  // =========================================================

  int _toInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 70,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 72,
              color: Colors.grey,
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'No Videos Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Upload your first BuyNova video '
              'and it will appear here and in the '
              'main Videos feed.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            ElevatedButton.icon(
              onPressed:
                  _openAddVideo,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Upload Video',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Videos',
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Please log in to view your videos.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Videos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
                _openAddVideo,
            icon: const Icon(
              Icons.add,
            ),
            tooltip:
                'Upload Video',
          ),
        ],
      ),

      // =======================================================
      // UPLOAD BUTTON
      // =======================================================

      floatingActionButton:
          FloatingActionButton(
        onPressed:
            _openAddVideo,
        child: const Icon(
          Icons.add,
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream:
            _myVideosStream(),
        builder:
            (context, snapshot) {
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
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 55,
                      color: Colors.redAccent,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'Could not load your videos.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      '${snapshot.error}',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label: const Text(
                        'Retry',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ??
                  [];

          if (docs.isEmpty) {
            return _emptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                90,
              ),
              itemCount:
                  docs.length,
              itemBuilder:
                  (context, index) {
                return _videoCard(
                  docs[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
