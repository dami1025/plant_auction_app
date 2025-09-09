import 'package:auction_demo/screens/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class BuildItemList extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> selectedItem;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> allItems;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onItemSelected;

  const BuildItemList({
    super.key,
    required this.selectedItem,
    required this.allItems,
    required this.onItemSelected,
  });

  static const double _imageSize = 40;
  static const double _iconSize = 20;
  static const double _loadingIndicatorSize = 15;
  static const double _loadingStrokeWidth = 2;

  @override
  Widget build(BuildContext context) {
    final data = selectedItem.data();
    final title = data['title'] ?? 'No Title';
    final price = data['price']?.toString() ?? '0';
    final favoriteCount = data['favoriteCount'] ?? 0;

    return Column(
      children: [
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

              // Price + Favorites
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceSection(price),
                  _buildFavoriteSection(favoriteCount),
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
            ],
          ),
        ),

        if (allItems.length > 1) ...[
          const SizedBox(height: 20),
          _buildItemSelector(),
        ],
      ],
    );
  }

  Widget _buildPriceSection(String price) {
    return Row(
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
            color: Colors.black87,
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
    );
  }

  Widget _buildFavoriteSection(int favoriteCount) {
    return Row(
      children: [
        const Icon(Icons.favorite, color: kPrimaryColor, size: 30),
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
    );
  }

  Widget _buildItemSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Other Items:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? kPrimaryColor : Colors.grey[300]!,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: _imageSize,
                        height: _imageSize,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
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
    );
  }

  Widget _buildItemImage(Map<String, dynamic> itemData, bool isSelected) {
    final storageFolder = itemData['storageFolder'] as String?;
    if (storageFolder == null || storageFolder.isEmpty) {
      return _buildPlaceholderContainer(isSelected);
    }

    return FutureBuilder<String?>(
      future: _getFirstImageUrl(storageFolder),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContainer(isSelected);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildPlaceholderContainer(isSelected);
        }
        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          width: _imageSize,
          height: _imageSize,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderContainer(isSelected);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingContainer(isSelected);
          },
        );
      },
    );
  }

  Future<String?> _getFirstImageUrl(String folderPath) async {
    try {
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child(folderPath);
      final listResult = await ref.listAll();

      if (listResult.items.isEmpty) return null;

      listResult.items.sort((a, b) => a.name.compareTo(b.name));
      final firstImageRef = listResult.items.first;
      return await firstImageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Error getting first image URL: $e');
      return null;
    }
  }

  Widget _buildPlaceholderContainer(bool isSelected) {
    return Container(
      width: _imageSize,
      height: _imageSize,
      color: Colors.grey[400],
      child: Icon(
        Icons.image_not_supported,
        color: isSelected ? Colors.white : Colors.grey[600],
        size: _iconSize,
      ),
    );
  }

  Widget _buildLoadingContainer(bool isSelected) {
    return Container(
      width: _imageSize,
      height: _imageSize,
      color: Colors.grey[300],
      child: Center(
        child: SizedBox(
          width: _loadingIndicatorSize,
          height: _loadingIndicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: _loadingStrokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(
              isSelected ? Colors.white : kPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
