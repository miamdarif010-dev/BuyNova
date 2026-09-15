import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class AddSellerVideoPage extends StatefulWidget {
  const AddSellerVideoPage({super.key});

  @override
  State<AddSellerVideoPage> createState() => _AddSellerVideoPageState();
}

class _AddSellerVideoPageState extends State<AddSellerVideoPage> {
  final _captionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  File? _pickedVideo;
  VideoPlayerController? _previewController;

  String? _selectedProductId;
  String? _selectedProductName;
  double? _selectedProductPrice;

  bool _isUploading = false;

  // =========================================================
  // CLOUDINARY SETTINGS
  // =========================================================

  static const String _cloudName = 'riassg6d';
  static const String _uploadPreset = 'buynova_products';

  @override
  void dispose() {
    _captionController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  // =========================================================
  // PICK VIDEO
  // =========================================================

  Future<void> _pickVideo() async {
    if (_isUploading) return;

    try {
      final XFile? picked = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 90),
      );

      if (picked == null) return;

      final file = File(picked.path);

      _previewController?.dispose();

      final controller = VideoPlayerController.file(file);

      await controller.initialize();

      controller.setLooping(true);
      controller.play();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _pickedVideo = file;
        _previewController = controller;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select video: $e'),
        ),
      );
    }
  }

  // =========================================================
  // PICK SELLER PRODUCT
  // =========================================================

  Future<void> _pickProduct() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: uid)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have no products yet'),
          ),
        );
        return;
      }

      final selected =
          await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: snapshot.docs.map((doc) {
                final data = doc.data();

                final name =
                    data['name']?.toString() ?? 'Unnamed';

                final price = data['price'] is num
                    ? (data['price'] as num).toDouble()
                    : 0.0;

                return ListTile(
                  leading: const Icon(
                    Icons.inventory_2_outlined,
                  ),
                  title: Text(name),
                  subtitle: Text(
                    '₩${price.toStringAsFixed(0)}',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      {
                        'id': doc.id,
                        'name': name,
                        'price': price,
                      },
                    );
                  },
                );
              }).toList(),
            ),
          );
        },
      );

      if (!mounted || selected == null) return;

      setState(() {
        _selectedProductId = selected['id'] as String;
        _selectedProductName = selected['name'] as String;
        _selectedProductPrice =
            selected['price'] as double;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load products: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // CHECK SELLER APPROVAL
  // =========================================================

  Future<Map<String, dynamic>> _getApprovedSellerData(
    User user,
  ) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception(
        'Your user profile was not found.',
      );
    }

    final data = userDoc.data() ?? {};

    final sellerStatus =
        data['sellerStatus']?.toString() ?? 'none';

    if (sellerStatus != 'approved') {
      throw Exception(
        'Only approved sellers can post videos.',
      );
    }

    return data;
  }

  // =========================================================
  // UPLOAD VIDEO
  // =========================================================

  Future<void> _uploadVideo() async {
    if (_isUploading) return;

    if (_pickedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a video first',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login first.',
          ),
        ),
      );
      return;
    }

    final caption = _captionController.text.trim();

    if (caption.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Caption must be 500 characters or less.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // =====================================================
      // VERIFY SELLER APPROVAL AGAIN BEFORE UPLOAD
      // =====================================================

      final sellerData =
          await _getApprovedSellerData(user);

      final sellerName =
          (sellerData['name']?.toString().trim().isNotEmpty ??
                  false)
              ? sellerData['name'].toString()
              : (user.email ?? 'Seller');

      final sellerCode =
          sellerData['sellerCode']?.toString();

      // =====================================================
      // CLOUDINARY UPLOAD
      // =====================================================

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/'
        '$_cloudName/video/upload',
      );

      final request =
          http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] =
          _uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _pickedVideo!.path,
        ),
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Cloudinary upload failed: '
          '${response.statusCode}',
        );
      }

      final Map<String, dynamic> result =
          jsonDecode(response.body);

      final secureUrl =
          result['secure_url']?.toString();

      if (secureUrl == null ||
          secureUrl.isEmpty) {
        throw Exception(
          'Cloudinary did not return a video URL.',
        );
      }

      // =====================================================
      // SAVE VIDEO TO FIRESTORE
      // =====================================================

      await FirebaseFirestore.instance
          .collection('sellerVideos')
          .add({
        'videoUrl': secureUrl,

        'caption': caption,

        // Seller identity
        'sellerId': user.uid,
        'sellerCode': sellerCode,
        'sellerName': sellerName,
        'sellerEmail': user.email,

        // Product
        'productId': _selectedProductId,
        'productName': _selectedProductName,
        'productPrice': _selectedProductPrice,

        // Social counters
        'viewCount': 0,
        'likeCount': 0,
        'commentCount': 0,
        'shareCount': 0,

        // Publishing
        'status': 'published',

        // IMPORTANT:
        // Rewards must NOT be granted directly
        // by the Flutter client.
        'rewardEligible': false,

        // Future moderation / earning system
        'moderationStatus': 'pending',

        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Video posted successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Video'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // =================================================
              // VIDEO PICKER
              // =================================================

              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child:
                      (_previewController != null &&
                              _previewController!
                                  .value
                                  .isInitialized)
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                              child: AspectRatio(
                                aspectRatio:
                                    _previewController!
                                        .value
                                        .aspectRatio,
                                child: VideoPlayer(
                                  _previewController!,
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons
                                      .video_call_outlined,
                                  size: 48,
                                  color:
                                      Colors.white70,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to select a video',
                                  style: TextStyle(
                                    color:
                                        Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 16),

              // =================================================
              // CAPTION
              // =================================================

              TextField(
                controller: _captionController,
                maxLines: 3,
                maxLength: 500,
                decoration:
                    const InputDecoration(
                  labelText: 'Caption',
                  hintText:
                      'Write something about this video...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // =================================================
              // PRODUCT
              // =================================================

              OutlinedButton.icon(
                onPressed:
                    _isUploading
                        ? null
                        : _pickProduct,
                icon: const Icon(
                  Icons.link,
                ),
                label: Text(
                  _selectedProductName == null
                      ? 'Link a Product (optional)'
                      : 'Linked: '
                          '$_selectedProductName',
                ),
              ),

              const SizedBox(height: 24),

              // =================================================
              // POST
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading
                      ? null
                      : _uploadVideo,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.redAccent,
                    foregroundColor:
                        Colors.white,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Post Video',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
