
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../widgets/category_card.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  // Sample categories data
  List<Category> get _categories => [
    Category(id: 1, name: "Smartphones", image: "https://picsum.photos/200"),
    Category(id: 2, name: "Laptops", image: "https://picsum.photos/201"),
    Category(id: 3, name: "Tablets", image: "https://picsum.photos/202"),
    Category(id: 4, name: "Accessories", image: "https://picsum.photos/203"),
    Category(id: 5, name: "Wearables", image: "https://picsum.photos/204"),
    Category(id: 6, name: "Audio", image: "https://picsum.photos/205"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            return CategoryCard(category: _categories[index]);
          },
        ),
      ),
    );
  }
}
