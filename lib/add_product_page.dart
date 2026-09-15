import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  File? _pickedImage;
  String? _uploadedImageUrl;

  bool _isUploadingPhoto = false;
  bool _isUploading = false;
  bool _isCheckingSeller = true;
  bool _isApprovedSeller = false;

  String? _sellerCode;

  // =========================================================
  // CLOUDINARY SETTINGS
  // =========================================================

  static const String _cloudName = 'riassg6d';
  static const String _uploadPreset = 'buynova_products';

  @override
  void initState() {
    super.initState();
    _checkSellerApproval();
  }

  // =========================================================
  // CHECK SELLER APPROVAL
  // =========================================================

  Future<void> _checkSellerApproval() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isApprovedSeller = false;
        _isCheckingSeller = false;
      });

      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snapshot.data();

      final sellerStatus = data?['sellerStatus']?.toString();
      final sellerCode = data?['sellerCode']?.toString();

      if (!mounted) return;

      setState(() {
        _isApprovedSeller = sellerStatus == 'approved';
        _sellerCode = sellerCode;
        _isCheckingSeller = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isApprovedSeller = false;
        _isCheckingSeller = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not check seller status: $e'),
        ),
      );
    }
  }

  // =========================================================
  // PICK IMAGE
  // =========================================================

  Future<void> _pickImage() async {
    if (!_isApprovedSeller) {
      _showSellerMessage();
      return;
    }

    if (_isUploadingPhoto || _isUploading) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (picked == null) return;

      await _uploadToCloudinary(File(picked.path));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select photo: $e'),
        ),
      );
    }
  }

  // =========================================================
  // CLOUDINARY UPLOAD
  // =========================================================

  Future<void> _uploadToCloudinary(File imageFile) async {
    setState(() {
      _pickedImage = imageFile;
      _isUploadingPhoto = true;
    });

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      request.fields['upload_preset'] = _uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Cloudinary upload failed: '
          '${response.statusCode}\n${response.body}',
        );
      }

      final Map<String, dynamic> result =
          jsonDecode(response.body);

      final String? secureUrl =
          result['secure_url']?.toString();

      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception(
          'Cloudinary did not return an image URL.',
        );
      }

      if (!mounted) return;

      setState(() {
        _uploadedImageUrl = secureUrl;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photo upload failed: $e',
          ),
        ),
      );

      setState(() {
        _pickedImage = null;
        _uploadedImageUrl = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  // =========================================================
  // SELLER MESSAGE
  // =========================================================

  void _showSellerMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Only approved sellers can add products.',
        ),
      ),
    );
  }

  // =========================================================
  // UPLOAD PRODUCT
  // =========================================================

  Future<void> _uploadProduct() async {
    if (!_isApprovedSeller) {
      _showSellerMessage();
      return;
    }

    final title = _titleController.text.trim();

    final priceText = _priceController.text.trim();

    final price = double.tryParse(priceText);

    final description =
        _descriptionController.text.trim();

    final category =
        _categoryController.text.trim();

    if (title.isEmpty ||
        price == null ||
        price <= 0 ||
        description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter product name, valid price and description.',
          ),
        ),
      );

      return;
    }

    if (_isUploadingPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait until the photo upload finishes.',
          ),
        ),
      );

      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

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

    if (_sellerCode == null ||
        _sellerCode!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller ID is missing. Please contact BuyNova Admin.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userSnapshot.data();

      final sellerStatus =
          userData?['sellerStatus']?.toString();

      final sellerCode =
          userData?['sellerCode']?.toString();

      if (sellerStatus != 'approved') {
        throw Exception(
          'Your seller account is not approved.',
        );
      }

      if (sellerCode == null ||
          sellerCode.trim().isEmpty) {
        throw Exception(
          'Seller ID is missing.',
        );
      }

      // =====================================================
      // CREATE PRODUCT
      // =====================================================

      await FirebaseFirestore.instance
          .collection('products')
          .add({
        'name': title,
        'price': price,
        'description': description,

        // Cloudinary image
        'imageUrl': _uploadedImageUrl ?? '',

        // Category
        'category': category.isNotEmpty
            ? category
            : 'General',

        // Seller information
        'sellerId': user.uid,
        'sellerCode': sellerCode,
        'sellerEmail': user.email ?? '',
        'sellerApproved': true,

        // Product status
        'active': true,
        'status': 'active',

        // Product information
        'rating': 5,
        'reviewCount': 0,
        'stock': 10,

        // Future marketplace fields
        'views': 0,
        'salesCount': 0,

        // Timestamp
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Clear fields
      _titleController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _categoryController.clear();

      setState(() {
        _pickedImage = null;
        _uploadedImageUrl = null;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product uploaded successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $e',
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
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();

    super.dispose();
  }

  // =========================================================
  // SELLER NOT APPROVED PAGE
  // =========================================================

  Widget _sellerNotApprovedView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 80,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 20),
            const Text(
              'Seller Approval Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Only approved BuyNova sellers can add products.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _checkSellerApproval,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Check Again',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Product',
        ),
      ),
      body: _isCheckingSeller
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : !_isApprovedSeller
              ? _sellerNotApprovedView()
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // =================================================
                        // SELLER INFO
                        // =================================================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_rounded,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Approved Seller',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Seller ID: ${_sellerCode ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey
                                            .shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // =================================================
                        // IMAGE PICKER
                        // =================================================

                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_pickedImage != null)
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    child: Image.file(
                                      _pickedImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 180,
                                    ),
                                  )
                                else
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons
                                            .add_a_photo_outlined,
                                        size: 40,
                                        color:
                                            Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to pick product image',
                                        style: TextStyle(
                                          color: Colors
                                              .grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_isUploadingPhoto)
                                  Container(
                                    decoration:
                                        BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius:
                                          BorderRadius.circular(
                                        10,
                                      ),
                                    ),
                                    child: const Center(
                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // =================================================
                        // PRODUCT NAME
                        // =================================================

                        TextField(
                          controller: _titleController,
                          textInputAction:
                              TextInputAction.next,
                          decoration:
                              const InputDecoration(
                            labelText: 'Product Name',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =================================================
                        // PRICE
                        // =================================================

                        TextField(
                          controller: _priceController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration:
                              const InputDecoration(
                            labelText: 'Price (₩)',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =================================================
                        // CATEGORY
                        // =================================================

                        TextField(
                          controller: _categoryController,
                          textInputAction:
                              TextInputAction.next,
                          decoration:
                              const InputDecoration(
                            labelText: 'Category',
                            hintText:
                                'Example: Men, Women, Electronics',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =================================================
                        // DESCRIPTION
                        // =================================================

                        TextField(
                          controller:
                              _descriptionController,
                          maxLines: 3,
                          maxLength: 1000,
                          decoration:
                              const InputDecoration(
                            labelText: 'Description',
                            border:
                                OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // =================================================
                        // UPLOAD BUTTON
                        // =================================================

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                (_isUploading ||
                                        _isUploadingPhoto)
                                    ? null
                                    : _uploadProduct,
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
                                    'Upload Product',
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}
