import 'package:flutter/material.dart';
import '../models/category.dart';
import '../screens/product_list_screen.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // عند الضغط على التصنيف، انتقل لشاشة تعرض منتجات هذا التصنيف
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ProductListScreen(categoryId: category.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // خلفية شفافة أو بيضاء خفيفة
          // إطار (border) فقط
          border: Border.all(color: Colors.grey, width: 1),
          // حواف دائرية
          borderRadius: BorderRadius.circular(15),
        ),
        // محتوى البطاقة: صف يضم الصورة + اسم التصنيف
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // صورة التصنيف
            if (category.image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  category.image,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

            const SizedBox(width: 8),

            // اسم التصنيف
            Flexible(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
