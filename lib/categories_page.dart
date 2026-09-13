import 'package:flutter/material.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  int _selectedIndex = 0;

  // NOTE: this list and order must stay identical to the
  // `categories` list in home_page.dart.
  final List<String> categories = const [
    'All',
    'Phones',
    'Laptops',
    'Watches',
    'Earbuds',
    'Cameras',
    'Fashion',
    'Shoes',
    'Bags',
    'Beauty',
    'Sports',
    'Toys',
    'Grocery',
  ];

  final Map<String, IconData> _icons = const {
    'All': Icons.apps,
    'Phones': Icons.smartphone,
    'Laptops': Icons.laptop_mac,
    'Watches': Icons.watch,
    'Earbuds': Icons.headphones,
    'Cameras': Icons.camera_alt,
    'Fashion': Icons.checkroom,
    'Shoes': Icons.hiking,
    'Bags': Icons.shopping_bag_outlined,
    'Beauty': Icons.spa_outlined,
    'Sports': Icons.sports_soccer,
    'Toys': Icons.toys_outlined,
    'Grocery': Icons.local_grocery_store_outlined,
  };

  final Map<String, Color> _colors = const {
    'All': Colors.redAccent,
    'Phones': Colors.blue,
    'Laptops': Colors.indigo,
    'Watches': Colors.teal,
    'Earbuds': Colors.purple,
    'Cameras': Colors.brown,
    'Fashion': Colors.deepOrange,
    'Shoes': Colors.brown,
    'Bags': Colors.deepPurple,
    'Beauty': Colors.pinkAccent,
    'Sports': Colors.green,
    'Toys': Colors.orange,
    'Grocery': Colors.lightGreen,
  };

  void _selectCategory(String name) {
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final selected = categories[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.redAccent,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Shop by category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: Row(
              children: [
                // LEFT SIDEBAR â€” exact same list/order as home_page.dart
                Container(
                  width: 110,
                  color: Colors.grey.shade100,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedIndex;
                      final name = categories[index];

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? Colors.redAccent : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.redAccent : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // RIGHT SIDE â€” selected category tile
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.8,
                      children: [
                        InkWell(
                          onTap: () => _selectCategory(selected),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor:
                                    (_colors[selected] ?? Colors.grey).withValues(alpha: 0.15),
                                child: Icon(
                                  _icons[selected] ?? Icons.category_outlined,
                                  color: _colors[selected] ?? Colors.grey,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selected,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
