import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'video_player_page.dart';

class MyVideosPage extends StatelessWidget {
  const MyVideosPage({super.key});

  Future<void> _deleteVideo(BuildContext context, String videoId, String caption) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text(
          caption.isNotEmpty ? 'Delete "$caption"?' : 'Delete this video?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('sellerVideos').doc(videoId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Videos'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: uid == null
          ? const Center(child: Text('Please login first'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sellerVideos')
                  .where('sellerId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('You haven\'t posted any videos yet'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final caption = data['caption']?.toString() ?? '';
                    final videoUrl = data['videoUrl']?.toString() ?? '';
                    final sellerName = data['sellerName']?.toString() ?? 'Seller';
                    final likeCount = (data['likeCount'] is num)
                        ? (data['likeCount'] as num).toInt()
                        : 0;
                    final productName = data['productName']?.toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.black87,
                          child: Icon(Icons.play_arrow, color: Colors.white),
                        ),
                        title: Text(
                          caption.isEmpty ? '(No caption)' : caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          productName != null
                              ? 'Linked: $productName â€¢ â¤ $likeCount'
                              : 'â¤ $likeCount',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerPage(
                                videoUrl: videoUrl,
                                caption: caption,
                                sellerName: sellerName,
                              ),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteVideo(context, doc.id, caption),
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
