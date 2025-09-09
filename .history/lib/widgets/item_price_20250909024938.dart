import 'dart:async';

import 'package:auction_demo/component/countdown_timer.dart';
import 'package:auction_demo/component/data/bidTimer.dart';
import 'package:auction_demo/screens/constants.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Riverpod provider
final bidSessionProvider = StateNotifierProvider.family
    <BidSessionNotifier, BidSessionState, String>(
        (ref, docId) => BidSessionNotifier(docId));

class BuildItemList extends ConsumerWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> selectedItem;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> allItems;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onItemSelected;

  const BuildItemList({
    super.key,
    required this.selectedItem,
    required this.allItems,
    required this.onItemSelected,
  });

  // Constants
  static const double _imageSize = 40;
  static const double _iconSize = 20;
  static const double _loadingIndicatorSize = 15;
  static const double _loadingStrokeWidth = 2;
  static const double _titleFontSize = 24;
  static const double _priceFontSize = 25;
  static const double _favoriteIconSize = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = selectedItem.data();
    final itemDetails = _ItemDetails.fromData(data);
    final bidSessionState = ref.watch(bidSessionProvider(selectedItem.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
          child: _ItemDetailsSection(
            itemDetails: itemDetails,
            bidSessionState: bidSessionState,
            selectedItemId: selectedItem.id,
            ref: ref,
          ),
        ),
        if (allItems.length > 1) ...[
          const SizedBox(height: 20),
          _ItemSelector(
            allItems: allItems,
            selectedItem: selectedItem,
            onItemSelected: onItemSelected,
          ),
        ],
      ],
    );
  }
}

// Data class to hold item details
class _ItemDetails {
  final String title;
  final String price;
  final DateTime? endTime;
  final String bidderCount;
  final int favoriteCount;

  const _ItemDetails({
    required this.title,
    required this.price,
    required this.endTime,
    required this.bidderCount,
    required this.favoriteCount,
  });

  factory _ItemDetails.fromData(Map<String, dynamic> data) {
    DateTime? endTime;
    final endTimestamp = data['endTime'];
    
    if (endTimestamp != null) {
      if (endTimestamp is Timestamp) {
        endTime = endTimestamp.toDate();
      } else if (endTimestamp is DateTime) {
        endTime = endTimestamp;
      }
    }

    return _ItemDetails(
      title: data['title'] ?? 'No Title',
      price: data['price']?.toString() ?? '0',
      endTime: endTime,
      bidderCount: data['bidderCount']?.toString() ?? '0',
      favoriteCount: data['favoriteCount'] ?? 0,
    );
  }
}

// Widget for the main item details section
class _ItemDetailsSection extends StatelessWidget {
  final _ItemDetails itemDetails;
  final BidSessionState bidSessionState;
  final String selectedItemId;
  final WidgetRef ref;

  const _ItemDetailsSection({
    required this.itemDetails,
    required this.bidSessionState,
    required this.selectedItemId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          itemDetails.title,
          style: const TextStyle(
            fontSize: BuildItemList._titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _BidSessionStatusChip(
          bidSessionState: bidSessionState,
          selectedItemId: selectedItemId,
          ref: ref,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PriceSection(price: itemDetails.price),
            _FavoriteSection(favoriteCount: itemDetails.favoriteCount),
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
        _BidCountdownSection(
          bidderCount: itemDetails.bidderCount,
          endTime: itemDetails.endTime,
        ),
      ],
    );
  }
}

// Bid session status management
class _BidSessionStatusHelper {
  static Color getColor(BidSessionStatus status) {
    switch (status) {
      case BidSessionStatus.notStarted:
        return Colors.orange;
      case BidSessionStatus.active:
        return Colors.green;
      case BidSessionStatus.ended:
        return Colors.red;
      case BidSessionStatus.canceled:
        return Colors.grey;
    }
  }

  static String getText(BidSessionStatus status) {
    switch (status) {
      case BidSessionStatus.notStarted:
        return 'Bid session starts soon';
      case BidSessionStatus.active:
        return 'Bid session active';
      case BidSessionStatus.ended:
        return 'Bid session ended';
      case BidSessionStatus.canceled:
        return 'Bid session canceled';
    }
  }
}

class _BidSessionStatusChip extends StatelessWidget {
  final BidSessionState bidSessionState;
  final String selectedItemId;
  final WidgetRef ref;

  const _BidSessionStatusChip({
    required this.bidSessionState,
    required this.selectedItemId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final color = _BidSessionStatusHelper.getColor(bidSessionState.status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, color: color, size: 16),
          const SizedBox(width: 4),
          _buildStatusContent(),
        ],
      ),
    );
  }

  Widget _buildStatusContent() {
    final status = bidSessionState.status;
    final color = _BidSessionStatusHelper.getColor(status);

    if (status == BidSessionStatus.active && bidSessionState.sessionEndTime != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Bid session ends in ', style: TextStyle(fontWeight: FontWeight.w500)),
          BidSessionCountdown(
            endTime: bidSessionState.sessionEndTime!,
            textColor: color,
            fontWeight: FontWeight.bold,
            onCountdownEnd: () {
              ref.read(bidSessionProvider(selectedItemId).notifier).endOrCancelSession();
            },
          ),
        ],
      );
    }

    return Text(
      _BidSessionStatusHelper.getText(status),
      style: TextStyle(color: color, fontWeight: FontWeight.w500),
    );
  }
}

class _PriceSection extends StatelessWidget {
  final String price;

  const _PriceSection({required this.price});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "\$$price",
          style: const TextStyle(
            fontSize: BuildItemList._priceFontSize,
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
            fontSize: BuildItemList._priceFontSize,
            color: kPrimaryColor,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FavoriteSection extends StatelessWidget {
  final int favoriteCount;

  const _FavoriteSection({required this.favoriteCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.favorite,
          color: kPrimaryColor,
          size: BuildItemList._favoriteIconSize,
        ),
        const SizedBox(width: 4),
        Text(
          favoriteCount.toString(),
          style: const TextStyle(
            fontSize: BuildItemList._favoriteIconSize,
            color: kPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BidCountdownSection extends StatelessWidget {
  final String bidderCount;
  final DateTime? endTime;

  const _BidCountdownSection({
    required this.bidderCount,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        if (endTime != null) CountdownText(endTime: endTime!),
      ],
    );
  }
}

class _ItemSelector extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> allItems;
  final QueryDocumentSnapshot<Map<String, dynamic>> selectedItem;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>) onItemSelected;

  const _ItemSelector({
    required this.allItems,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
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
                final isSelected = item.id == selectedItem.id;
                return _ItemSelectorTile(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onItemSelected(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSelectorTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ItemSelectorTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            width: BuildItemList._imageSize,
            height: BuildItemList._imageSize,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: _ItemImage(
              itemData: item.data(),
              isSelected: isSelected,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemImage extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final bool isSelected;

  const _ItemImage({
    required this.itemData,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final storageFolder = itemData['storageFolder'] as String?;

    if (storageFolder == null || storageFolder.isEmpty) {
      return _buildPlaceholder();
    }

    return FutureBuilder<String?>(
      future: _getFirstImageUrl(storageFolder),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildPlaceholder();
        }

        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          width: BuildItemList._imageSize,
          height: BuildItemList._imageSize,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            return loadingProgress == null ? child : _buildLoading();
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
      return await listResult.items.first.getDownloadURL();
    } catch (e) {
      debugPrint('Error getting first image URL: $e');
      return null;
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: BuildItemList._imageSize,
      height: BuildItemList._imageSize,
      color: Colors.grey[400],
      child: Icon(
        Icons.image_not_supported,
        color: isSelected ? Colors.white : Colors.grey[600],
        size: BuildItemList._iconSize,
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: BuildItemList._imageSize,
      height: BuildItemList._imageSize,
      color: Colors.grey[300],
      child: Center(
        child: SizedBox(
          width: BuildItemList._loadingIndicatorSize,
          height: BuildItemList._loadingIndicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: BuildItemList._loadingStrokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(
              isSelected ? Colors.white : kPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }
}