import 'package:flutter/material.dart';
import '../models/category.dart';
import '../screens/product_list_screen.dart';

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
            builder: (ctx) => ProductListScreen(categoryId: category.id),
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
                    ? Image.network(
                  category.image,
                  fit: BoxFit.contain, // Ensures the image covers the entire space
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF6FE0DA), // Use accent color for loader
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200, // Light grey background on error
                      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey), // More specific error icon
                    );
                  },
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