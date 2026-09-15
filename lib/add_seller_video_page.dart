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
  State<AddSellerVideoPage> createState() =>
      _AddSellerVideoPageState();
}

class _AddSellerVideoPageState
    extends State<AddSellerVideoPage> {
  // =========================================================
  // CLOUDINARY
  // =========================================================

  static const String _cloudName = 'riassg6d';
  static const String _uploadPreset = 'buynova_products';

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController _captionController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();

  // =========================================================
  // STATE
  // =========================================================

  File? _videoFile;

  VideoPlayerController? _videoController;

  bool _uploading = false;

  double _uploadProgress = 0;

  String? _selectedProductId;
  String? _selectedProductName;
  double? _selectedProductPrice;
  String? _selectedProductImage;

  List<Map<String, dynamic>> _myProducts = [];

  bool _loadingProducts = true;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadMyProducts();
  }

  // =========================================================
  // LOAD PRODUCTS
  // =========================================================

  Future<void> _loadMyProducts() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingProducts = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();

        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _myProducts = products;
        _loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingProducts = false;
      });
    }
  }

  // =========================================================
  // PICK VIDEO
  // =========================================================

  Future<void> _pickVideo() async {
    try {
      final XFile? picked = await _picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (picked == null) return;

      final file = File(picked.path);

      final controller =
          VideoPlayerController.file(file);

      await controller.initialize();

      final duration = controller.value.duration;

      await controller.dispose();

      // Maximum 90 seconds
      if (duration.inSeconds > 90) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Video must be 90 seconds or less.',
            ),
          ),
        );

        return;
      }

      if (!mounted) return;

      await _videoController?.dispose();

      final previewController =
          VideoPlayerController.file(file);

      await previewController.initialize();

      await previewController.setLooping(true);

      setState(() {
        _videoFile = file;
        _videoController = previewController;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not select video: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // SELECT PRODUCT
  // =========================================================

  void _selectProduct(
    Map<String, dynamic>? product,
  ) {
    if (product == null) {
      setState(() {
        _selectedProductId = null;
        _selectedProductName = null;
        _selectedProductPrice = null;
        _selectedProductImage = null;
      });

      return;
    }

    setState(() {
      _selectedProductId =
          product['id']?.toString();

      _selectedProductName =
          product['name']?.toString();

      _selectedProductPrice =
          _toDouble(product['price']);

      _selectedProductImage =
          product['imageUrl']?.toString();
    });
  }

  // =========================================================
  // UPLOAD VIDEO
  // =========================================================

  Future<String?> _uploadVideoToCloudinary(
    File file,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/video/upload',
      );

      final request =
          http.MultipartRequest('POST', url);

      request.fields['upload_preset'] =
          _uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      final streamedResponse = await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data =
          jsonDecode(response.body);

      return data['secure_url']?.toString();
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // GET USER NAME
  // =========================================================

  Future<String> _getUserName(
    User user,
  ) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final data = snapshot.data();

      final name =
          data?['name']?.toString();

      if (name != null &&
          name.trim().isNotEmpty) {
        return name.trim();
      }
    } catch (_) {}

    return user.displayName ??
        user.email ??
        'BuyNova User';
  }

  // =========================================================
  // POST VIDEO
  // =========================================================

  Future<void> _postVideo() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login before posting a video.',
          ),
        ),
      );

      return;
    }

    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a video first.',
          ),
        ),
      );

      return;
    }

    if (_uploading) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.1;
    });

    try {
      // -------------------------------------------------------
      // USER NAME
      // -------------------------------------------------------

      final userName =
          await _getUserName(user);

      if (!mounted) return;

      setState(() {
        _uploadProgress = 0.2;
      });

      // -------------------------------------------------------
      // CLOUDINARY UPLOAD
      // -------------------------------------------------------

      final videoUrl =
          await _uploadVideoToCloudinary(
        _videoFile!,
      );

      if (videoUrl == null ||
          videoUrl.isEmpty) {
        throw Exception(
          'Video upload failed.',
        );
      }

      if (!mounted) return;

      setState(() {
        _uploadProgress = 0.75;
      });

      // -------------------------------------------------------
      // FIRESTORE DATA
      // -------------------------------------------------------

      final videoData =
          <String, dynamic>{
        'videoUrl': videoUrl,

        'caption':
            _captionController.text.trim(),

        // IMPORTANT:
        // All authenticated users can post.
        'userId': user.uid,

        // Keep sellerId for compatibility
        // with existing video/feed code.
        'sellerId': user.uid,

        'sellerName': userName,

        'userName': userName,

        'sellerEmail':
            user.email ?? '',

        'userEmail':
            user.email ?? '',

        // Public immediately
        'status': 'published',

        // No admin approval
        'moderationStatus': 'none',

        'rewardEligible': false,

        // Engagement counters
        'viewCount': 0,
        'likeCount': 0,
        'commentCount': 0,
        'shareCount': 0,

        // Product information
        'productId':
            _selectedProductId ?? '',

        'productName':
            _selectedProductName ?? '',

        'productPrice':
            _selectedProductPrice ?? 0,

        'productImageUrl':
            _selectedProductImage ?? '',

        'createdAt':
            FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('sellerVideos')
          .add(videoData);

      if (!mounted) return;

      setState(() {
        _uploadProgress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Video posted successfully!',
          ),
        ),
      );

      // -------------------------------------------------------
      // CLEAR PAGE
      // -------------------------------------------------------

      _captionController.clear();

      await _videoController?.dispose();

      setState(() {
        _videoFile = null;
        _videoController = null;

        _selectedProductId = null;
        _selectedProductName = null;
        _selectedProductPrice = null;
        _selectedProductImage = null;

        _uploading = false;
        _uploadProgress = 0;
      });

      // Return to previous page
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _uploading = false;
        _uploadProgress = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not post video: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // REMOVE VIDEO
  // =========================================================

  void _removeSelectedVideo() async {
    await _videoController?.dispose();

    if (!mounted) return;

    setState(() {
      _videoFile = null;
      _videoController = null;
    });
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post Video',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =================================================
              // VIDEO SELECTOR
              // =================================================

              const Text(
                'Video',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (_videoFile == null)
                GestureDetector(
                  onTap: _uploading
                      ? null
                      : _pickVideo,
                  child: Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.grey.shade400,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_library,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Select Video',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Maximum 90 seconds',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(18),
                      child: Container(
                        width: double.infinity,
                        height: 420,
                        color: Colors.black,
                        child: _videoController !=
                                    null &&
                                _videoController!
                                    .value
                                    .isInitialized
                            ? Center(
                                child: AspectRatio(
                                  aspectRatio:
                                      _videoController!
                                          .value
                                          .aspectRatio,
                                  child: VideoPlayer(
                                    _videoController!,
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

                    if (!_uploading)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor:
                              Colors.black54,
                          child: IconButton(
                            onPressed:
                                _removeSelectedVideo,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: const Text(
                          'Up to 90 seconds',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 22),

              // =================================================
              // CAPTION
              // =================================================

              const Text(
                'Caption',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _captionController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText:
                      'Write something about your video...',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // =================================================
              // PRODUCT
              // =================================================

              const Text(
                'Attach Product',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Optional. You can post a video without a product.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 10),

              if (_loadingProducts)
                const Center(
                  child:
                      CircularProgressIndicator(),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade400,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedProductId,
                      hint: const Text(
                        'No product selected',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            'No product',
                          ),
                        ),
                        ..._myProducts.map(
                          (product) {
                            return DropdownMenuItem<
                                String>(
                              value:
                                  product['id']
                                      ?.toString(),
                              child: Text(
                                product['name']
                                        ?.toString() ??
                                    'Product',
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            );
                          },
                        ),
                      ],
                      onChanged: _uploading
                          ? null
                          : (value) {
                              if (value == null) {
                                _selectProduct(
                                  null,
                                );
                                return;
                              }

                              final product =
                                  _myProducts
                                      .firstWhere(
                                (item) =>
                                    item['id']
                                        ?.toString() ==
                                    value,
                              );

                              _selectProduct(
                                product,
                              );
                            },
                    ),
                  ),
                ),

              // =================================================
              // SELECTED PRODUCT
              // =================================================

              if (_selectedProductId != null) ...[
                const SizedBox(height: 14),

                Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      if (_selectedProductImage !=
                              null &&
                          _selectedProductImage!
                              .isNotEmpty)
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          child: Image.network(
                            _selectedProductImage!,
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) {
                              return Container(
                                width: 65,
                                height: 65,
                                color: Colors.grey
                                    .shade300,
                                child:
                                    const Icon(
                                  Icons.image,
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: 65,
                          height: 65,
                          decoration:
                              BoxDecoration(
                            color: Colors.grey
                                .shade300,
                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: const Icon(
                            Icons.shopping_bag,
                          ),
                        ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              _selectedProductName ??
                                  'Product',
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              '₩${(_selectedProductPrice ?? 0).toStringAsFixed(0)}',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: _uploading
                            ? null
                            : () =>
                                _selectProduct(
                                  null,
                                ),
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // =================================================
              // INFO
              // =================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Anyone with a BuyNova account can post videos. Videos are published immediately and can be viewed from the Videos/Reels section.',
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // UPLOAD PROGRESS
              // =================================================

              if (_uploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress > 0
                      ? _uploadProgress
                      : null,
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Uploading... '
                    '${(_uploadProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              // =================================================
              // POST BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _uploading
                      ? null
                      : _postVideo,
                  icon: _uploading
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
                          Icons.upload,
                        ),
                  label: Text(
                    _uploading
                        ? 'Posting Video...'
                        : 'Post Video',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
