import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<String> _categories = [
    'All', 'Women', 'Men', 'Home', 'Sports', 'Kids', 'Jewelry'
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'title': 'Multi-Function Automatic Food Sealer Vacuum Sealing Machine...',
      'image': 'https://picsum.photos/200/200?random=1',
      'rating': '5.0',
      'reviews': '249',
      'price': '₩25,757',
      'sold': '6.2K+ sold',
      'tag': 'TOP RATED in Kitchen Appliances',
    },
    {
      'title': 'Phone Case - Luxury Matte Translucent Protective Cover...',
      'image': 'https://picsum.photos/200/200?random=2',
      'rating': '4.9',
      'reviews': '1.2K',
      'price': '₩3,078',
      'sold': '1.5K+ sold',
      'tag': 'Only 2 left',
      'brand': 'PUGB',
    },
    {
      'title': '10PCS Men Boxer Briefs Set Comfortable Breathable Cotton...',
      'image': 'https://picsum.photos/200/200?random=3',
      'rating': '4.8',
      'reviews': '850',
      'price': '₩12,400',
      'sold': '3.1K+ sold',
      'tag': 'BEST-SELLING ITEM',
    },
    {
      'title': 'Cooking Oil Bottle Set Premium Quality Healthy Option...',
      'image': 'https://picsum.photos/200/200?random=4',
      'rating': '4.7',
      'reviews': '927',
      'price': '₩18,500',
      'sold': '800+ sold',
      'tag': 'Local (Domestic Shipping)',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ১. সার্চ বার
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'squishy toy',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: () {},
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ২. ক্যাটাগরি মেনু
                SizedBox(
                  height: 35,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final isSelected = index == 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Column(
                          children: [
                            Text(
                              _categories[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.black : Colors.grey[700],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                height: 3,
                                width: 20,
                                color: Colors.black,
                              )
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ৩. ফ্রি শিপিং ব্যানার
                Container(
                  color: const Color(0xFFFFF3E0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Free shipping special for you',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text('Exclusive offer >', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),

                // ৪. প্রোডাক্ট গ্রিড
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final item = _products[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                child: Image.network(
                                  item['image'],
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAlignment: CrossAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 12, color: Colors.black),
                                      const Icon(Icons.star, size: 12, color: Colors.black),
                                      const Icon(Icons.star, size: 12, color: Colors.black),
                                      const Icon(Icons.star, size: 12, color: Colors.black),
                                      const Icon(Icons.star, size: 12, color: Colors.black),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['reviews'],
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (item.containsKey('tag'))
                                    Text(
                                      item['tag'],
                                      style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAlignment.start,
                                        children: [
                                          Text(
                                            item['price'],
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '🔥 ${item['sold']}',
                                            style: const TextStyle(fontSize: 10, color: Colors.brown),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.black),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: const Icon(Icons.add_shopping_cart, size: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // ৫. সাইন-ইন ভাসমান বার
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.85),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sign in for the best experience',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text('Sign in', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ৬. বটম নেভিগেশন বার
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF326295),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'You'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
        ],
      ),
    );
  }
}
