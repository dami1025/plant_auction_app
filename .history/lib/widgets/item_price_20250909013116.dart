import 'package:auction_demo/component/countdown_timer.dart';
import 'package:auction_demo/screens/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BuildItemList extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> selectedItem;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> allItems;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>)
      onItemSelected;

  const BuildItemList({
    super.key,
    required this.selectedItem,
    required this.allItems,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final data = selectedItem.data();
    final title = data['title'] ?? 'No Title';
    final price = data['price']?.toString() ?? '0';
    final endTimestamp = data['endTime'];
    final bidderCount = data['bidderCount']?.toString() ?? '0';
    final favoriteCount = data['favoriteCount'] ?? 0;

    return Column(
      children: [
        // Display the selected item
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Price + Best Offer + Favorite count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "\$$price",
                        style: const TextStyle(
                          fontSize: 25,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "or",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 10, 11, 10),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Best Offer",
                        style: TextStyle(
                          fontSize: 25,
                          color: kPrimaryColor,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Favorite icon + count
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: kPrimaryColor,
                        size: 30,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        favoriteCount.toString(),
                        style: const TextStyle(
                          fontSize: 30,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                "+ Shipping will be determined",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 4),
              // Bid count + bullet + countdown
              Row(
                children: [
                  Text(
                    "$bidderCount bid",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 13, 13, 13),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text("•", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  const Text("Ends in ", style: TextStyle(fontSize: 16)),
                  if (endTimestamp != null)
                    CountdownText(endTime: endTimestamp),
                ],
              ),
            ],
          ),
        ),

        // Optional: Add a section to switch between items
        if (allItems.length > 1) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Other Items:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allItems.length,
                    itemBuilder: (context, index) {
                      final item = allItems[index];
                      final itemData = item.data();
                      final isSelected = item.id == selectedItem.id;

                      return GestureDetector(
                        onTap: () => onItemSelected(item),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? kPrimaryColor : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? kPrimaryColor
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: _buildItemImage(itemData, isSelected),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemImage(Map<String, dynamic> itemData, bool isSelected) {
    final storageFolder = itemData['storageFolder'] as String?;

    if (storageFolder == null || storageFolder.isEmpty) {
      return Container(
        color: Colors.grey[400],
        child: Icon(
          Icons.image_not_supported,
          color: isSelected ? Colors.white : Colors.grey[600],
          size: 20,
        ),
      );
    }

    // Construct the first image URL
    // Assuming your images follow a pattern like: folder/image1.jpg or folder/1.jpg
    final imageUrl =
        'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/${Uri.encodeComponent(storageFolder)}%2F1.jpg?alt=media';

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: 40,
      height: 40,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[400],
          child: Icon(
            Icons.image_not_supported,
            color: isSelected ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isSelected ? Colors.white : kPrimaryColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}