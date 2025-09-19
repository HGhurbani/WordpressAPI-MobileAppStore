import 'package:flutter/material.dart';
import '../models/category.dart';
import '../screens/product_list_screen.dart';

class HomeCategoryCard extends StatelessWidget {
  final Category category;

  const HomeCategoryCard({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ProductListScreen(
              categoryId: category.id,
              showCashOnly: true,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0x446FE0DA), // ← تم تغيير اللون هنا إلى الفيروزي
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.network(
                  category.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image, size: 40, color: Colors.white);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A2543), // اسم التصنيف بلون الهوية الأزرق الداكن
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
