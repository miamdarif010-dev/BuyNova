import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class CartService {
static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

static CollectionReference<Map<String, dynamic>>? get _cartRef {
final uid = _uid;
if (uid == null) return null;
return FirebaseFirestore.instance
.collection('users')
.doc(uid)
.collection('cart');
}

static Stream<QuerySnapshot<Map<String, dynamic>>>? get stream {
return _cartRef?.orderBy('addedAt', descending: false).snapshots();
}

static Future<void> addItem({
required String id,
required String name,
required double price,
String? imageUrl,
}) async {
final ref = _cartRef;
if (ref == null) return;

final docRef = ref.doc(id);  
final doc = await docRef.get();  

if (doc.exists) {  
  await docRef.update({'quantity': FieldValue.increment(1)});  
} else {  
  await docRef.set({  
    'name': name,  
    'price': price,  
    'imageUrl': imageUrl,  
    'quantity': 1,  
    'addedAt': FieldValue.serverTimestamp(),  
  });  
}

}

static Future<void> removeItem(String id) async {
await _cartRef?.doc(id).delete();
}

static Future<void> increaseQuantity(String id) async {
await _cartRef?.doc(id).update({'quantity': FieldValue.increment(1)});
}

static Future<void> decreaseQuantity(String id, int currentQuantity) async {
final ref = _cartRef;
if (ref == null) return;

if (currentQuantity > 1) {  
  await ref.doc(id).update({'quantity': FieldValue.increment(-1)});  
} else {  
  await ref.doc(id).delete();  
}

}

static const double deliveryFeeAmount = 3000;
}

class CartPage extends StatefulWidget {
const CartPage({super.key});

@override
State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
void _checkout() {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Checkout coming soon'),
behavior: SnackBarBehavior.floating,
),
);
}

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;

if (user == null) {  
  return Scaffold(  
    appBar: AppBar(  
      title: const Text('My Cart'),  
      centerTitle: true,  
      backgroundColor: Colors.redAccent,  
      foregroundColor: Colors.white,  
    ),  
    body: Center(  
      child: Padding(  
        padding: const EdgeInsets.all(30),  
        child: Column(  
          mainAxisAlignment: MainAxisAlignment.center,  
          children: [  
            Icon(Icons.lock_outline, size: 70, color: Colors.grey.shade400),  
            const SizedBox(height: 20),  
            const Text(  
              'Please login to view your cart',  
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),  
              textAlign: TextAlign.center,  
            ),  
            const SizedBox(height: 20),  
            ElevatedButton(  
              style: ElevatedButton.styleFrom(  
                backgroundColor: Colors.redAccent,  
                foregroundColor: Colors.white,  
              ),  
              onPressed: () {  
                Navigator.push(  
                  context,  
                  MaterialPageRoute(builder: (context) => const LoginPage()),  
                );  
              },  
              child: const Text('Login'),  
            ),  
          ],  
        ),  
      ),  
    ),  
  );  
}  

return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(  
  stream: CartService.stream,  
  builder: (context, snapshot) {  
    final docs = snapshot.data?.docs ?? [];  

    double subtotal = 0;  
    int itemCount = 0;  
    for (final doc in docs) {  
      final data = doc.data();  
      final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;  
      final qty = (data['quantity'] is num) ? (data['quantity'] as num).toInt() : 1;  
      subtotal += price * qty;  
      itemCount += qty;  
    }  

    final deliveryFee = docs.isEmpty ? 0.0 : CartService.deliveryFeeAmount;  
    final total = subtotal + deliveryFee;  

    return Scaffold(  
      appBar: AppBar(  
        title: Text(  
          'My Cart ($itemCount)',  
          style: const TextStyle(fontWeight: FontWeight.bold),  
        ),  
        centerTitle: true,  
        backgroundColor: Colors.redAccent,  
        foregroundColor: Colors.white,  
      ),  
      body: snapshot.connectionState == ConnectionState.waiting  
          ? const Center(child: CircularProgressIndicator())  
          : docs.isEmpty  
              ? _emptyCart(context)  
              : Column(  
                  children: [  
                    Expanded(  
                      child: ListView.builder(  
                        padding: const EdgeInsets.all(12),  
                        itemCount: docs.length,  
                        itemBuilder: (context, index) {  
                          final doc = docs[index];  
                          final data = doc.data();  
                          return _cartItemCard(doc.id, data);  
                        },  
                      ),  
                    ),  
                    _priceSummary(subtotal, deliveryFee, total),  
                  ],  
                ),  
    );  
  },  
);

}

Widget _cartItemCard(String id, Map<String, dynamic> data) {
final name = data['name']?.toString() ?? 'Product';
final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;
final quantity = (data['quantity'] is num) ? (data['quantity'] as num).toInt() : 1;
final imageUrl = data['imageUrl']?.toString();

return Card(  
  margin: const EdgeInsets.only(bottom: 10),  
  elevation: 1,  
  child: Padding(  
    padding: const EdgeInsets.all(10),  
    child: Row(  
      crossAxisAlignment: CrossAxisAlignment.start,  
      children: [  
        Container(  
          width: 85,  
          height: 85,  
          decoration: BoxDecoration(  
            color: Colors.grey.shade200,  
            borderRadius: BorderRadius.circular(10),  
          ),  
          child: imageUrl != null && imageUrl.isNotEmpty  
              ? ClipRRect(  
                  borderRadius: BorderRadius.circular(10),  
                  child: Image.network(  
                    imageUrl,  
                    fit: BoxFit.cover,  
                    errorBuilder: (context, error, stackTrace) {  
                      return const Icon(Icons.image, size: 40, color: Colors.grey);  
                    },  
                  ),  
                )  
              : const Icon(Icons.image, size: 40, color: Colors.grey),  
        ),  
        const SizedBox(width: 12),  
        Expanded(  
          child: Column(  
            crossAxisAlignment: CrossAxisAlignment.start,  
            children: [  
              Text(  
                name,  
                maxLines: 2,  
                overflow: TextOverflow.ellipsis,  
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),  
              ),  
              const SizedBox(height: 6),  
              Text(  
                '\$${price.toStringAsFixed(2)}',  
                style: const TextStyle(  
                  color: Colors.redAccent,  
                  fontSize: 16,  
                  fontWeight: FontWeight.bold,  
                ),  
              ),  
              const SizedBox(height: 8),  
              Row(  
                children: [  
                  InkWell(  
                    onTap: () => CartService.decreaseQuantity(id, quantity),  
                    borderRadius: BorderRadius.circular(6),  
                    child: Container(  
                      width: 30,  
                      height: 30,  
                      decoration: BoxDecoration(  
                        border: Border.all(color: Colors.grey.shade300),  
                        borderRadius: BorderRadius.circular(6),  
                      ),  
                      child: const Icon(Icons.remove, size: 18),  
                    ),  
                  ),  
                  SizedBox(  
                    width: 38,  
                    child: Center(  
                      child: Text(  
                        '$quantity',  
                        style: const TextStyle(fontWeight: FontWeight.bold),  
                      ),  
                    ),  
                  ),  
                  InkWell(  
                    onTap: () => CartService.increaseQuantity(id),  
                    borderRadius: BorderRadius.circular(6),  
                    child: Container(  
                      width: 30,  
                      height: 30,  
                      decoration: BoxDecoration(  
                        border: Border.all(color: Colors.grey.shade300),  
                        borderRadius: BorderRadius.circular(6),  
                      ),  
                      child: const Icon(Icons.add, size: 18),  
                    ),  
                  ),  
                  const Spacer(),  
                  IconButton(  
                    onPressed: () => CartService.removeItem(id),  
                    icon: const Icon(Icons.delete_outline, color: Colors.red),  
                    tooltip: 'Remove',  
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

Widget _priceSummary(double subtotal, double deliveryFee, double total) {
return Container(
padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
decoration: BoxDecoration(
color: Colors.white,
boxShadow: [
BoxShadow(
color: Colors.black.withValues(alpha: 0.08),
blurRadius: 8,
offset: const Offset(0, -2),
),
],
),
child: Column(
children: [
_priceRow('Subtotal', '$${subtotal.toStringAsFixed(2)}'),
const SizedBox(height: 8),
_priceRow('Delivery Fee', '$${deliveryFee.toStringAsFixed(2)}'),
const Divider(height: 20),
_priceRow('Total', '$${total.toStringAsFixed(2)}', bold: true),
const SizedBox(height: 14),
SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton(
onPressed: _checkout,
style: ElevatedButton.styleFrom(
backgroundColor: Colors.redAccent,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
),
child: const Text(
'Proceed to Checkout',
style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
),
),
],
),
);
}

Widget _priceRow(String title, String value, {bool bold = false}) {
return Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
title,
style: TextStyle(
fontSize: bold ? 18 : 15,
fontWeight: bold ? FontWeight.bold : FontWeight.normal,
),
),
Text(
value,
style: TextStyle(
fontSize: bold ? 18 : 15,
fontWeight: bold ? FontWeight.bold : FontWeight.w600,
color: bold ? Colors.redAccent : null,
),
),
],
);
}

Widget _emptyCart(BuildContext context) {
return Center(
child: Padding(
padding: const EdgeInsets.all(30),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.shopping_cart_outlined, size: 90, color: Colors.grey.shade400),
const SizedBox(height: 20),
const Text(
'Your Cart is Empty',
style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),
Text(
'Add products to your cart and they will appear here.',
textAlign: TextAlign.center,
style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
),
const SizedBox(height: 25),
ElevatedButton(
onPressed: () => Navigator.pop(context),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.redAccent,
foregroundColor: Colors.white,
),
child: const Text('Continue Shopping'),
),
],
),
),
);
}
}
