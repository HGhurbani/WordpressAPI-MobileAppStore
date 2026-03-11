import 'package:flutter/material.dart';
import '../models/category.dart';
import '../screens/product_list_screen.dart';
import 'app_cached_image.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4, // Increased elevation for more depth and premium feel
      shadowColor: Colors.grey.withOpacity(0.3), // Softened shadow color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18), // Slightly more rounded corners
      ),
      clipBehavior: Clip.antiAlias, // Ensures content is clipped to the rounded corners
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ProductListScreen(
              categoryId: category.id,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(18), // Match card's border radius
        splashColor: const Color(0x336FE0DA), // Softer splash effect
        highlightColor: const Color(0x116FE0DA), // Subtle highlight on press
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Category Image Section ---
            Expanded(
              child: AspectRatio( // Maintain aspect ratio for image
                aspectRatio: 1.0, // Ensures image is square within its space
                child: category.image.isNotEmpty
                    ? AppCachedImage(
                        url: category.image,
                        fit: BoxFit.contain,
                        placeholderBackground: Colors.grey.shade200,
                        errorWidget: Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.category, size: 50, color: Colors.grey), // Fallback icon
                ),
              ),
            ),
            // --- Category Name Section ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), // Adjusted padding
              decoration: const BoxDecoration(
                color: Color(0xFF6FE0DA), // Dark blue background for text
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18), // Match card's border radius
                ),
              ),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14, // Slightly smaller font for better fit
                  fontWeight: FontWeight.w600, // Medium bold
                  color: Color(0xFF1A2543) // White text for contrast on dark background
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}