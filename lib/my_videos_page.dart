import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'video_player_page.dart';
import 'add_seller_video_page.dart';

class MyVideosPage extends StatelessWidget {
  const MyVideosPage({super.key});

  Future<void> _deleteVideo(
    BuildContext context,
    String videoId,
    String caption,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text(
          caption.isNotEmpty
              ? 'Delete "$caption"?'
              : 'Delete this video?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('sellerVideos')
          .doc(videoId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video deleted successfully'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete video: $e'),
          ),
        );
      }
    }
  }

  void _openAddVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddSellerVideoPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Videos'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,

        // + button inside My Videos
        actions: [
          IconButton(
            tooltip: 'Add Video',
            icon: const Icon(Icons.add),
            onPressed: () => _openAddVideo(context),
          ),
        ],
      ),

      body: uid == null
          ? const Center(
              child: Text('Please login first'),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sellerVideos')
                  .where('sellerId', isEqualTo: uid)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to load your videos.\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.video_library_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'You haven\'t posted any videos yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          onPressed: () => _openAddVideo(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,

                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                        doc.data() as Map<String, dynamic>;

                    final caption =
                        data['caption']?.toString() ?? '';

                    final videoUrl =
                        data['videoUrl']?.toString() ?? '';

                    final sellerName =
                        data['sellerName']?.toString() ?? 'Seller';

                    final likeCount =
                        data['likeCount'] is num
                            ? (data['likeCount'] as num).toInt()
                            : 0;

                    final viewCount =
                        data['viewCount'] is num
                            ? (data['viewCount'] as num).toInt()
                            : 0;

                    final productName =
                        data['productName']?.toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                      ),

                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.black87,
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),

                        title: Text(
                          caption.isEmpty
                              ? '(No caption)'
                              : caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        subtitle: Text(
                          productName != null &&
                                  productName.isNotEmpty
                              ? 'Linked: $productName • '
                                  '♥ $likeCount • '
                                  'Views $viewCount'
                              : '♥ $likeCount • '
                                  'Views $viewCount',
                        ),

                        onTap: videoUrl.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VideoPlayerPage(
                                      videoUrl: videoUrl,
                                      caption: caption,
                                      sellerName: sellerName,
                                    ),
                                  ),
                                );
                              },

                        trailing: IconButton(
                          tooltip: 'Delete Video',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteVideo(
                            context,
                            doc.id,
                            caption,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
