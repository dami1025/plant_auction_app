import 'package:auction_demo/component/data/bidTimer.dart';
import 'package:auction_demo/component/data/firestore.dart';
import 'package:auction_demo/component/data/riverpod.dart';
import 'package:auction_demo/screens/constants.dart';
import 'package:auction_demo/widgets/item_price.dart' ;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceBidButton extends ConsumerWidget {
  final String docId;

  const PlaceBidButton({super.key, required this.docId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidSession = ref.watch(bidSessionProvider(docId));
    final isActive = bidSession.status == BidSessionStatus.active;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? kPrimaryColor : Colors.grey,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: isActive ? () => _showBidDialog(context, ref) : null,
          child: Text(
            _getButtonText(bidSession.status),
            style: const TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: kBackgroundColor
            ),
          ),
        ),
      ),
    );
  }

  String _getButtonText(BiddingSessionStatus status) {
    switch (status) {
      case BiddingSessionStatus.notStarted:
        return "Bidding Not Started";
      case BiddingSessionStatus.active:
        return "Place Bid";
      case BidSessionStatus.ended:
        return "Bidding Ended";
      case BidSessionStatus.cancelled:
        return "Bidding Cancelled";
      default:
        return "Bidding Closed";
    }
  }

  void _showBidDialog(BuildContext context, WidgetRef ref) async {
    try {
      // Use 'auctions' collection to match the bidding session system
      final doc = await FirebaseFirestore.instance
          .collection('auctions') // Changed from 'items' to 'auctions'
          .doc(docId)
          .get();
      
      if (!doc.exists) {
        _showErrorSnackBar(context, "Item not found");
        return;
      }

      final data = doc.data()!;
      final currentPrice = (data['price'] ?? 0).toDouble();
      final controller = TextEditingController();
      String? errorText;

      await showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing while processing
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text("Enter your bid"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Bid > \$${currentPrice.toStringAsFixed(2)}",
                    errorText: errorText,
                    prefixText: "\$",
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Current highest bid: \$${currentPrice.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                ),
                onPressed: () async {
                  final bid = double.tryParse(controller.text.trim());
                  if (bid == null || bid <= currentPrice) {
                    setState(() => errorText = "Bid must be higher than \$${currentPrice.toStringAsFixed(2)}");
                    return;
                  }

                  // Check for minimum bid increment (optional)
                  final minIncrement = 1.0; // Minimum $1 increment
                  if (bid < currentPrice + minIncrement) {
                    setState(() => errorText = "Minimum bid increment is \$${minIncrement.toStringAsFixed(2)}");
                    return;
                  }

                  // Clear any previous errors
                  setState(() => errorText = null);
                  
                  // Place the bid
                  await _placeBid(ctx, context, docId, bid);
                },
                child: const Text(
                  "Submit Bid",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
      controller.dispose();
    } catch (e) {
      _showErrorSnackBar(context, "Failed to load item details");
    }
  }

  Future<void> _placeBid(BuildContext dialogContext, BuildContext parentContext, String docId, double bidAmount) async {
    try {
      // Show loading indicator
      showDialog(
        context: dialogContext,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text("Placing bid..."),
            ],
          ),
        ),
      );

      // Update the auction document with new bid information
      await FirebaseFirestore.instance
          .collection('auctions') // Changed from 'items' to 'auctions'
          .doc(docId)
          .update({
        'price': bidAmount,
        'bidderCount': FieldValue.increment(1),
        'lastBidTime': FieldValue.serverTimestamp(), // Critical for session timer
        'lastBidAmount': bidAmount, // Optional: track last bid amount
        'sessionStatus': 'active', // Ensure session is marked as active
      });

      // Close loading dialog
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      
      // Close bid dialog
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();

      // Show success message
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(
            content: Text("Bid placed successfully! Your bid: \$${bidAmount.toStringAsFixed(2)}"),
            backgroundColor: kPrimaryColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      
      // Show error message
      if (parentContext.mounted) {
        _showErrorSnackBar(parentContext, "Failed to place bid. Please try again.");
      }
      
      print('Error placing bid: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class FavoriteButton extends ConsumerWidget {
  final String docId;

  const FavoriteButton({super.key, required this.docId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Updated to use 'auctions' collection
    final item = ref.watch(itemProvider(docId));

    return item.when(
      data: (doc) {
        final favoriteCount = doc.data()?['favoriteCount'] ?? 0;
        final isFavorited = doc.data()?['isFavorited'] ?? false; // Optional: track user favorites

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isFavorited 
                    ? kPrimaryColor.withOpacity(0.2)
                    : const Color.fromARGB(255, 235, 248, 238),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: kPrimaryColor,
                  width: isFavorited ? 2 : 1,
                ),
              ),
              onPressed: () => _toggleFavorite(context, docId, isFavorited),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: kPrimaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFavorited ? "Remove from Favorites" : "Add to Favorites",
                    style: const TextStyle(
                      fontSize: 20, // Slightly smaller to fit longer text
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  if (favoriteCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        favoriteCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red),
          ),
          child: Center(
            child: Text(
              'Error loading favorites',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, String docId, bool currentlyFavorited) async {
    try {
      // Updated to use 'auctions' collection
      await FirebaseFirestore.instance
          .collection('auctions') // Changed from 'items' to 'auctions'
          .doc(docId)
          .update({
        'favoriteCount': FieldValue.increment(currentlyFavorited ? -1 : 1),
        'isFavorited': !currentlyFavorited, // Optional: track user-specific favorites
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyFavorited ? "Removed from favorites!" : "Added to favorites!",
          ),
          backgroundColor: kPrimaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update favorites. Try again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      print('Error updating favorites: $e');
    }
  }
}