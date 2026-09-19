import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'my_orders_page.dart';
import 'address_book_page.dart';

class CheckoutItem {
  final String productId;
  final String productName;
  final double price;
  final String? imageUrl;
  final int quantity;

  const CheckoutItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.imageUrl,
    required this.quantity,
  });

  double get total => price * quantity;
}

class CheckoutPage extends StatefulWidget {
  final List<CheckoutItem> items;

  final String? productId;
  final String? productName;
  final double? price;
  final String? imageUrl;
  final int? quantity;

  final bool clearCartOnSuccess;

  const CheckoutPage({
    super.key,
    this.items = const [],
    this.productId,
    this.productName,
    this.price,
    this.imageUrl,
    this.quantity,
    this.clearCartOnSuccess = false,
  });

  List<CheckoutItem> get checkoutItems {
    if (items.isNotEmpty) {
      return items;
    }

    if (productId != null &&
        productName != null &&
        price != null &&
        quantity != null) {
      return [
        CheckoutItem(
          productId: productId!,
          productName: productName!,
          price: price!,
          imageUrl: imageUrl,
          quantity: quantity!,
        ),
      ];
    }

    return const [];
  }

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _couponController =
      TextEditingController();

  bool _placingOrder = false;
  bool _loadingAddresses = true;
  bool _checkingCoupon = false;

  String _paymentMethod = 'Cash on Delivery';

  static const double deliveryFee = 3000;

  List<Map<String, dynamic>> _savedAddresses = [];

  String? _selectedAddressId;

  // =========================================================
  // COUPON
  // =========================================================

  Map<String, dynamic>? _appliedCoupon;

  double _discountAmount = 0;

  String? get _couponCode {
    final code = _couponController.text.trim().toUpperCase();

    if (code.isEmpty) {
      return null;
    }

    return code;
  }

  // =========================================================
  // SUBTOTAL
  // =========================================================

  double get subtotal {
    double total = 0;

    for (final item in widget.checkoutItems) {
      total += item.total;
    }

    return total;
  }

  // =========================================================
  // TOTAL QUANTITY
  // =========================================================

  int get totalQuantity {
    int quantity = 0;

    for (final item in widget.checkoutItems) {
      quantity += item.quantity;
    }

    return quantity;
  }

  // =========================================================
  // DISCOUNT
  // =========================================================

  double get discountAmount {
    if (_appliedCoupon == null) {
      return 0;
    }

    return _discountAmount;
  }

  // =========================================================
  // GRAND TOTAL
  // =========================================================

  double get grandTotal {
    final total = subtotal + deliveryFee - discountAmount;

    if (total < 0) {
      return 0;
    }

    return total;
  }

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadUserInformation();
    _loadSavedAddresses();
  }

  // =========================================================
  // LOAD USER INFORMATION
  // =========================================================

  Future<void> _loadUserInformation() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final data = snapshot.data();

      if (data != null) {
        _nameController.text =
            data['name']?.toString() ?? '';

        _phoneController.text =
            data['phone']?.toString() ?? '';
      }
    } catch (_) {
      // Keep checkout usable.
    }
  }

  // =========================================================
  // LOAD SAVED ADDRESSES
  // =========================================================

  Future<void> _loadSavedAddresses() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingAddresses = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .get();

      final addresses = snapshot.docs.map((document) {
        final data = document.data();

        return {
          'id': document.id,
          'name': data['name']?.toString() ?? '',
          'phone': data['phone']?.toString() ?? '',
          'address': data['address']?.toString() ?? '',
          'isDefault': data['isDefault'] == true,
        };
      }).toList();

      addresses.sort((a, b) {
        final aDefault = a['isDefault'] == true;
        final bDefault = b['isDefault'] == true;

        if (aDefault && !bDefault) {
          return -1;
        }

        if (!aDefault && bDefault) {
          return 1;
        }

        return 0;
      });

      if (!mounted) return;

      setState(() {
        _savedAddresses = addresses;
        _loadingAddresses = false;
      });

      if (addresses.isNotEmpty) {
        Map<String, dynamic>? defaultAddress;

        for (final address in addresses) {
          if (address['isDefault'] == true) {
            defaultAddress = address;
            break;
          }
        }

        defaultAddress ??= addresses.first;

        _selectSavedAddress(defaultAddress);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingAddresses = false;
      });
    }
  }

  // =========================================================
  // SELECT SAVED ADDRESS
  // =========================================================

  void _selectSavedAddress(
    Map<String, dynamic> address,
  ) {
    if (!mounted) return;

    setState(() {
      _selectedAddressId =
          address['id']?.toString();

      _nameController.text =
          address['name']?.toString() ?? '';

      _phoneController.text =
          address['phone']?.toString() ?? '';

      _addressController.text =
          address['address']?.toString() ?? '';
    });
  }

  // =========================================================
  // SELECT ADDRESS BY ID
  // =========================================================

  void _selectAddressById(String? addressId) {
    if (addressId == null) return;

    for (final address in _savedAddresses) {
      if (address['id']?.toString() == addressId) {
        _selectSavedAddress(address);
        return;
      }
    }
  }

  // =========================================================
  // OPEN ADDRESS BOOK
  // =========================================================

  Future<void> _openAddressBook() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressBookPage(),
      ),
    );

    if (!mounted) return;

    await _loadSavedAddresses();
  }

  // =========================================================
  // USE MANUAL ADDRESS
  // =========================================================

  void _useManualAddress() {
    setState(() {
      _selectedAddressId = null;
    });
  }

  // =========================================================
  // CLEAR CART
  // =========================================================

  Future<void> _clearCart(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }

    await batch.commit();
  }

  // =========================================================
  // VALIDATE FORM
  // =========================================================

  bool _validateForm() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        'Please enter your full name.',
      );
      return false;
    }

    if (phone.isEmpty) {
      _showMessage(
        'Please enter your phone number.',
      );
      return false;
    }

    if (address.isEmpty) {
      _showMessage(
        'Please enter your delivery address.',
      );
      return false;
    }

    if (phone.length < 7) {
      _showMessage(
        'Please enter a valid phone number.',
      );
      return false;
    }

    if (widget.checkoutItems.isEmpty) {
      _showMessage(
        'No products selected.',
      );
      return false;
    }

    return true;
  }

  // =========================================================
  // CHECK COUPON
  // =========================================================

  Future<void> _checkCoupon() async {
    if (_checkingCoupon) return;

    final code = _couponController.text.trim().toUpperCase();

    if (code.isEmpty) {
      _showMessage(
        'Please enter a coupon code.',
      );
      return;
    }

    if (subtotal <= 0) {
      _showMessage(
        'Your order subtotal is invalid.',
      );
      return;
    }

    setState(() {
      _checkingCoupon = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where(
            'code',
            isEqualTo: code,
          )
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _removeCoupon(showMessage: false);

        _showMessage(
          'Invalid coupon code.',
        );
        return;
      }

      final data = snapshot.docs.first.data();

      final isActive = data['isActive'] == true;

      if (!isActive) {
        _removeCoupon(showMessage: false);

        _showMessage(
          'This coupon is not active.',
        );
        return;
      }

      // =====================================================
      // EXPIRY CHECK
      // =====================================================

      final expiresAtValue = data['expiresAt'];

      DateTime? expiresAt;

      if (expiresAtValue is Timestamp) {
        expiresAt = expiresAtValue.toDate();
      } else if (expiresAtValue is DateTime) {
        expiresAt = expiresAtValue;
      }

      if (expiresAt != null &&
          DateTime.now().isAfter(expiresAt)) {
        _removeCoupon(showMessage: false);

        _showMessage(
          'This coupon has expired.',
        );
        return;
      }

      // =====================================================
      // MINIMUM ORDER CHECK
      // =====================================================

      final minimumOrder =
          _toDouble(data['minimumOrder']);

      if (minimumOrder > 0 &&
          subtotal < minimumOrder) {
        _removeCoupon(showMessage: false);

        _showMessage(
          'Minimum order for this coupon is '
          '₩${minimumOrder.toStringAsFixed(0)}.',
        );
        return;
      }

      // =====================================================
      // DISCOUNT TYPE
      // =====================================================

      final discountType =
          data['discountType']?.toString().toLowerCase() ??
              'percentage';

      final discountValue =
          _toDouble(data['discountValue']);

      if (discountValue <= 0) {
        _removeCoupon(showMessage: false);

        _showMessage(
          'This coupon has no valid discount.',
        );
        return;
      }

      double calculatedDiscount = 0;

      if (discountType == 'percentage') {
        calculatedDiscount =
            subtotal * discountValue / 100;

        final maximumDiscount =
            _toDouble(data['maximumDiscount']);

        if (maximumDiscount > 0 &&
            calculatedDiscount > maximumDiscount) {
          calculatedDiscount = maximumDiscount;
        }
      } else {
        calculatedDiscount = discountValue;
      }

      if (calculatedDiscount > subtotal) {
        calculatedDiscount = subtotal;
      }

      if (calculatedDiscount <= 0) {
        _removeCoupon(showMessage: false);

        _showMessage(
          'This coupon cannot be applied.',
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _appliedCoupon = {
          ...data,
          'id': snapshot.docs.first.id,
          'code': code,
        };

        _discountAmount = calculatedDiscount;
      });

      _showMessage(
        'Coupon applied successfully.',
      );
    } catch (e) {
      _showMessage(
        'Could not check coupon.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingCoupon = false;
        });
      }
    }
  }

  // =========================================================
  // REMOVE COUPON
  // =========================================================

  void _removeCoupon({
    bool showMessage = true,
  }) {
    if (!mounted) return;

    setState(() {
      _appliedCoupon = null;
      _discountAmount = 0;
    });

    if (showMessage) {
      _showMessage(
        'Coupon removed.',
      );
    }
  }

  // =========================================================
  // DOUBLE CONVERTER
  // =========================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // =========================================================
  // GET SELLER INFORMATION
  // =========================================================

  Future<Map<String, dynamic>?> _getProductSellerData(
    String productId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();

      if (data == null) {
        return null;
      }

      final sellerId =
          data['sellerId']?.toString();

      if (sellerId == null || sellerId.isEmpty) {
        return null;
      }

      return {
        'sellerId': sellerId,
        'sellerCode':
            data['sellerCode']?.toString() ?? '',
        'sellerEmail':
            data['sellerEmail']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // PLACE ORDER
  // =========================================================

  Future<void> _placeOrder() async {
    if (_placingOrder) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login before placing an order.',
      );
      return;
    }

    if (!_validateForm()) return;

    setState(() {
      _placingOrder = true;
    });

    try {
      // =====================================================
      // STEP 1
      // RECHECK COUPON BEFORE ORDER
      // =====================================================

      if (_couponCode != null &&
          _appliedCoupon != null) {
        await _checkCoupon();

        if (_appliedCoupon == null) {
          return;
        }
      }

      // =====================================================
      // STEP 2
      // FIND SELLER FOR EVERY PRODUCT
      // =====================================================

      final Map<String, Map<String, dynamic>>
          sellerInformation = {};

      for (final item in widget.checkoutItems) {
        final sellerData =
            await _getProductSellerData(
          item.productId,
        );

        if (sellerData == null) {
          throw Exception(
            'Seller information not found for '
            '${item.productName}.',
          );
        }

        sellerInformation[item.productId] =
            sellerData;
      }

      // =====================================================
      // STEP 3
      // MAIN ORDER
      // =====================================================

      final firestore =
          FirebaseFirestore.instance;

      final orderRef =
          firestore.collection('orders').doc();

      final itemsData =
          widget.checkoutItems.map((item) {
        final sellerData =
            sellerInformation[item.productId]!;

        return {
          'productId': item.productId,
          'productName': item.productName,
          'imageUrl': item.imageUrl ?? '',
          'price': item.price,
          'quantity': item.quantity,
          'total': item.total,
          'sellerId':
              sellerData['sellerId'],
          'sellerCode':
              sellerData['sellerCode'],
          'sellerEmail':
              sellerData['sellerEmail'],
        };
      }).toList();

      // =====================================================
      // STEP 4
      // GROUP PRODUCTS BY SELLER
      // =====================================================

      final Map<String, List<CheckoutItem>>
          sellerItems = {};

      final Map<String, Map<String, dynamic>>
          sellerDataMap = {};

      for (final item in widget.checkoutItems) {
        final sellerData =
            sellerInformation[item.productId]!;

        final sellerId =
            sellerData['sellerId'].toString();

        sellerItems.putIfAbsent(
          sellerId,
          () => [],
        );

        sellerItems[sellerId]!.add(item);

        sellerDataMap[sellerId] =
            sellerData;
      }

      // =====================================================
      // STEP 5
      // CREATE FIRESTORE BATCH
      // =====================================================

      final batch =
          firestore.batch();

      // =====================================================
      // COUPON DATA
      // =====================================================

      final couponData = _appliedCoupon;

      final savedCouponCode =
          couponData?['code']?.toString() ?? '';

      // =====================================================
      // MAIN CUSTOMER ORDER
      // =====================================================

      batch.set(
        orderRef,
        {
          'orderId': orderRef.id,
          'userId': user.uid,
          'userEmail': user.email ?? '',
          'customerName':
              _nameController.text.trim(),
          'phone':
              _phoneController.text.trim(),
          'address':
              _addressController.text.trim(),
          'addressId':
              _selectedAddressId ?? '',
          'items': itemsData,
          'itemCount':
              widget.checkoutItems.length,
          'totalQuantity':
              totalQuantity,
          'subtotal':
              subtotal,
          'deliveryFee':
              deliveryFee,
          'discount':
              discountAmount,
          'couponCode':
              savedCouponCode,
          'total':
              grandTotal,
          'paymentMethod':
              _paymentMethod,
          'paymentStatus':
              'pending',
          'orderStatus':
              'placed',
          'createdAt':
              FieldValue.serverTimestamp(),
        },
      );

      // =====================================================
      // SELLER ORDERS
      // =====================================================

      for (final sellerEntry
          in sellerItems.entries) {
        final sellerId =
            sellerEntry.key;

        final sellerProducts =
            sellerEntry.value;

        final sellerInfo =
            sellerDataMap[sellerId]!;

        double sellerSubtotal = 0;
        int sellerQuantity = 0;

        final List<Map<String, dynamic>>
            sellerItemsData = [];

        for (final item
            in sellerProducts) {
          sellerSubtotal += item.total;
          sellerQuantity += item.quantity;

          sellerItemsData.add({
            'productId':
                item.productId,
            'productName':
                item.productName,
            'imageUrl':
                item.imageUrl ?? '',
            'price':
                item.price,
            'quantity':
                item.quantity,
            'total':
                item.total,
          });
        }

        // ===================================================
        // UNIQUE SELLER ORDER DOCUMENT
        // ===================================================

        final sellerOrderRef =
            firestore
                .collection('seller_orders')
                .doc();

        batch.set(
          sellerOrderRef,
          {
            'sellerOrderId':
                sellerOrderRef.id,
            'orderId':
                orderRef.id,
            'customerId':
                user.uid,
            'customerEmail':
                user.email ?? '',
            'customerName':
                _nameController.text.trim(),
            'phone':
                _phoneController.text.trim(),
            'address':
                _addressController.text.trim(),
            'addressId':
                _selectedAddressId ?? '',
            'sellerId':
                sellerId,
            'sellerCode':
                sellerInfo['sellerCode'] ?? '',
            'sellerEmail':
                sellerInfo['sellerEmail'] ?? '',
            'items':
                sellerItemsData,
            'itemCount':
                sellerProducts.length,
            'totalQuantity':
                sellerQuantity,
            'sellerSubtotal':
                sellerSubtotal,
            'couponCode':
                savedCouponCode,
            'paymentMethod':
                _paymentMethod,
            'paymentStatus':
                'pending',
            'orderStatus':
                'placed',
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      // =====================================================
      // STEP 6
      // SAVE EVERYTHING
      // =====================================================

      await batch.commit();

      // =====================================================
      // STEP 7
      // CLEAR CART
      // =====================================================

      if (widget.clearCartOnSuccess) {
        await _clearCart(user.uid);
      }

      if (!mounted) return;

      // =====================================================
      // SUCCESS DIALOG
      // =====================================================

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text('Order Placed'),
              ],
            ),
            content: Text(
              'Your order has been placed successfully.\n\n'
              'Order ID:\n${orderRef.id}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child:
                    const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // =====================================================
      // GO TO MY ORDERS
      // =====================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MyOrdersPage(),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not place order.\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _placingOrder = false;
        });
      }
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // PRODUCT IMAGE
  // =========================================================

  Widget _productImage(
    CheckoutItem item,
  ) {
    final imageUrl =
        item.imageUrl ?? '';

    if (imageUrl.isEmpty) {
      return Container(
        width: 75,
        height: 75,
        decoration:
            BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 35,
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: 75,
        height: 75,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: 75,
            height: 75,
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.image_outlined,
              color: Colors.grey,
              size: 35,
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // PRODUCT CARD
  // =========================================================

  Widget _productCard(
    CheckoutItem item,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      elevation: 1,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _productImage(item),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    '₩${item.price.toStringAsFixed(0)} × ${item.quantity}',
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    '₩${item.total.toStringAsFixed(0)}',
                    style:
                        const TextStyle(
                      color:
                          Colors.redAccent,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
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
  // ADDRESS CARD
  // =========================================================

  Widget _addressBookCard() {
    if (_loadingAddresses) {
      return Card(
        elevation: 0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
          side: BorderSide(
            color:
                Colors.grey.shade300,
          ),
        ),
        child: const Padding(
          padding:
              EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Loading saved addresses...',
              ),
            ],
          ),
        ),
      );
    }

    if (_savedAddresses.isEmpty) {
      return Card(
        elevation: 0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
          side: BorderSide(
            color:
                Colors.grey.shade300,
          ),
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color:
                        Colors.redAccent,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No saved address',
                      style:
                          TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'You can add an address to your Address Book for faster checkout.',
                style: TextStyle(
                  color:
                      Colors.grey.shade700,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              OutlinedButton.icon(
                onPressed:
                    _openAddressBook,
                icon: const Icon(
                  Icons.add_location_alt_outlined,
                ),
                label: const Text(
                  'Add Address',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
        side: BorderSide(
          color:
              Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(12),
        child: Column(
          children: [
            RadioGroup<String>(
              groupValue:
                  _selectedAddressId,
              onChanged:
                  _selectAddressById,
              child: Column(
                children: [
                  for (final address
                      in _savedAddresses)
                    _savedAddressTile(address),
                ],
              ),
            ),

            const Divider(
              height: 20,
            ),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed:
                        _openAddressBook,
                    icon: const Icon(
                      Icons.manage_accounts_outlined,
                    ),
                    label: const Text(
                      'Manage Addresses',
                    ),
                  ),
                ),

                Expanded(
                  child: TextButton.icon(
                    onPressed:
                        _useManualAddress,
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    label: const Text(
                      'Enter Manually',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SAVED ADDRESS TILE
  // =========================================================

  Widget _savedAddressTile(
    Map<String, dynamic> address,
  ) {
    final addressId =
        address['id']?.toString() ?? '';

    final isSelected =
        _selectedAddressId == addressId;

    final isDefault =
        address['isDefault'] == true;

    final name =
        address['name']?.toString() ?? '';

    final phone =
        address['phone']?.toString() ?? '';

    final fullAddress =
        address['address']?.toString() ?? '';

    return InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: () {
        _selectSavedAddress(address);
      },
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 8,
        ),
        padding:
            const EdgeInsets.all(12),
        decoration:
            BoxDecoration(
          color: isSelected
              ? Colors.redAccent
                  .withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.redAccent
                : Colors.grey.shade300,
            width:
                isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Radio<String>(
              value: addressId,
              activeColor:
                  Colors.redAccent,
            ),

            const SizedBox(width: 4),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name.isEmpty
                              ? 'Saved Address'
                              : name,
                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      if (isDefault) ...[
                        const SizedBox(
                          width: 7,
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .green
                                .withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child:
                              const Text(
                            'Default',
                            style:
                                TextStyle(
                              color:
                                  Colors.green,
                              fontSize:
                                  11,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (phone.isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      phone,
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  if (fullAddress.isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      fullAddress,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // COUPON CARD
  // =========================================================

  Widget _couponCard() {
    final applied = _appliedCoupon != null;

    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
        side: BorderSide(
          color:
              Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Coupon',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                if (applied)
                  TextButton(
                    onPressed:
                        _placingOrder
                            ? null
                            : () => _removeCoupon(),
                    child:
                        const Text(
                      'Remove',
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            if (applied)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration:
                    BoxDecoration(
                  color: Colors.green
                      .withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green
                        .withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _couponCode ?? '',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Colors.green,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'You saved ₩${discountAmount.toStringAsFixed(0)}',
                            style:
                                const TextStyle(
                              color:
                                  Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          _couponController,
                      textCapitalization:
                          TextCapitalization.characters,
                      enabled:
                          !_checkingCoupon &&
                              !_placingOrder,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Enter coupon code',
                        prefixIcon:
                            const Icon(
                          Icons.confirmation_number_outlined,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (_appliedCoupon != null) {
                          _removeCoupon(
                            showMessage: false,
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _checkingCoupon ||
                                  _placingOrder
                              ? null
                              : _checkCoupon,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.redAccent,
                        foregroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      child:
                          _checkingCoupon
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Apply',
                                ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SUMMARY ROW
  // =========================================================

  Widget _summaryRow(
    String title,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: bold
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final items =
        widget.checkoutItems;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Colors.redAccent,
        foregroundColor:
            Colors.white,
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: items.isEmpty
          ? const Center(
              child: Text(
                'No products selected.',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey,
                ),
              ),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                120,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Items',
                    style:
                        TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  ...items.map(
                    (item) =>
                        _productCard(item),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Delivery Information',
                    style:
                        TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'Saved Addresses',
                    style:
                        TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  _addressBookCard(),

                  const SizedBox(
                    height: 14,
                  ),

                  TextField(
                    controller:
                        _nameController,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Full Name',
                      hintText:
                          'Enter your full name',
                      prefixIcon:
                          const Icon(
                        Icons.person,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextField(
                    controller:
                        _phoneController,
                    keyboardType:
                        TextInputType.phone,
                    textInputAction:
                        TextInputAction.next,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Phone Number',
                      hintText:
                          'Enter your phone number',
                      prefixIcon:
                          const Icon(
                        Icons.phone,
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextField(
                    controller:
                        _addressController,
                    keyboardType:
                        TextInputType
                            .streetAddress,
                    maxLines: 3,
                    decoration:
                        InputDecoration(
                      labelText:
                          'Delivery Address',
                      hintText:
                          'Enter your complete delivery address',
                      prefixIcon:
                          const Padding(
                        padding:
                            EdgeInsets.only(
                          bottom: 45,
                        ),
                        child: Icon(
                          Icons
                              .location_on,
                        ),
                      ),
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Payment Method',
                    style:
                        TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Card(
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                      side: BorderSide(
                        color: Colors
                            .grey
                            .shade300,
                      ),
                    ),
                    child:
                        RadioGroup<String>(
                      groupValue:
                          _paymentMethod,
                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setState(() {
                          _paymentMethod =
                              value;
                        });
                      },
                      child:
                          const RadioListTile<
                              String>(
                        value:
                            'Cash on Delivery',
                        title: Text(
                          'Cash on Delivery',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                        subtitle:
                            Text(
                          'Pay when your order arrives',
                        ),
                        secondary:
                            Icon(
                          Icons
                              .payments_outlined,
                          color:
                              Colors.redAccent,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _couponCard(),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Order Summary',
                    style:
                        TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Card(
                    child:
                        Padding(
                      padding:
                          const EdgeInsets
                              .all(
                        16,
                      ),
                      child:
                          Column(
                        children: [
                          _summaryRow(
                            'Products',
                            '${items.length}',
                          ),

                          _summaryRow(
                            'Total Quantity',
                            '$totalQuantity',
                          ),

                          _summaryRow(
                            'Subtotal',
                            '₩${subtotal.toStringAsFixed(0)}',
                          ),

                          _summaryRow(
                            'Delivery Fee',
                            '₩${deliveryFee.toStringAsFixed(0)}',
                          ),

                          if (discountAmount > 0)
                            _summaryRow(
                              'Coupon Discount',
                              '-₩${discountAmount.toStringAsFixed(0)}',
                              valueColor:
                                  Colors.green,
                            ),

                          const Divider(
                            height: 20,
                          ),

                          _summaryRow(
                            'Total',
                            '₩${grandTotal.toStringAsFixed(0)}',
                            bold:
                                true,
                            valueColor:
                                Colors
                                    .redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

      // =========================================================
      // PLACE ORDER BUTTON
      // =========================================================

      bottomNavigationBar:
          items.isEmpty
              ? null
              : SafeArea(
                  child:
                      Container(
                    padding:
                        const EdgeInsets
                            .all(
                      12,
                    ),
                    decoration:
                        const BoxDecoration(
                      color:
                          Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black12,
                          blurRadius:
                              8,
                          offset:
                              Offset(
                            0,
                            -2,
                          ),
                        ),
                      ],
                    ),
                    child:
                        SizedBox(
                      width:
                          double.infinity,
                      height:
                          54,
                      child:
                          ElevatedButton(
                        onPressed:
                            _placingOrder
                                ? null
                                : _placeOrder,
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              Colors
                                  .redAccent,
                          foregroundColor:
                              Colors.white,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                        child:
                            _placingOrder
                                ? const SizedBox(
                                    width:
                                        25,
                                    height:
                                        25,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.5,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Place Order • ₩${grandTotal.toStringAsFixed(0)}',
                                    style:
                                        const TextStyle(
                                      fontSize:
                                          16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                      ),
                    ),
                  ),
                ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponController.dispose();

    super.dispose();
  }
}
