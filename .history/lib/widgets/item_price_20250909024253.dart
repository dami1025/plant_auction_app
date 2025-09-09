import 'package:auction_demo/component/countdown_timer.dart';
import 'package:auction_demo/component/data/riverpod.dart';
import 'package:auction_demo/screens/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class BuildItemList extends ConsumerWidget {
  final String selectedItemId;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>)
      onItemSelected;

  const BuildItemList({
    super.key,
    required this.selectedItemId,
    required this.onItemSelected,
  });

  static const double _imageSize = 40;
  static const double _iconSize = 20;
  static const double _loadingIndicatorSize = 15;
  static const double _loadingStrokeWidth = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItemAsync = ref.watch(itemProvider(selectedItemId));
    final allItemsAsync = ref.watch(itemsCollectionProvider);

    return selectedItemAsync.when(
      data: (selectedSnapshot) {
        final selectedData = selectedSnapshot.data();
    if (selectedData == null) return const Text('Item not found');

    final title = selectedData['title'] ?? 'No Title';
    final price = (selectedData['price'] ?? 0).toDouble();   // numeric
    final bidderCount = (selectedData['bidderCount'] ?? 0);   // numeric
    final favoriteCount = (selectedData['favoriteCount'] ?? 0); // numeric
    final endTimestamp = selectedData['endTime'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Price + Best Offer + Favorite count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
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
            ),

            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "+ Shipping will be determined",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
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
            ),

            const SizedBox(height: 20),
            // Other items horizontal list
            allItemsAsync.when(
              data: (allItems) {
                if (allItems.length <= 1) return const SizedBox.shrink();

                return Padding(
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
                            final isSelected = item.id == selectedItemId;

                            return GestureDetector(
                              onTap: () => onItemSelected(item),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? kPrimaryColor : Colors.grey[200],
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
                                    width: _imageSize,
                                    height: _imageSize,
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
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error loading items: $err'),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading item: $err'),
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
      print('Error getting first image URL: $e');
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
