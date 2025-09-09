import 'package:auction_demo/component/data/firestore.dart';
import 'package:auction_demo/component/data/riverpod.dart';
import 'package:auction_demo/screens/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceBidContainer extends ConsumerWidget {
  final String docId;

  const PlaceBidContainer({super.key, required this.docId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemProvider(docId));

    return itemAsync.when(
      data: (doc) {
        final data = doc.data();
        final currentPrice = (data?['price'] ?? 0).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showBidDialog(context, ref, currentPrice),
              child: const Text(
                "Place Bid",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kBackgroundColor,
                ),
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
      error: (err, stack) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: Text(
            "Error loading item: $err",
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  void _showBidDialog(BuildContext context, WidgetRef ref, double currentPrice) {
    final FirestoreService firestoreService = FirestoreService();
    final TextEditingController controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Enter your bid"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Bid > \$price.toStringAsFixed(2)",
              errorText: errorText,
              prefixText: "\$",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                final bid = double.tryParse(text);

                if (bid == null || bid <= 0) {
                  setState(() => errorText = "Please enter a valid amount");
                  return;
                }
                if (bid <= currentPrice) {
                  setState(() => errorText =
                      "Bid must be higher than \${currentPrice.toStringAsFixed(2)}");
                  return;
                }

                try {
                  // Update Firestore
                  final docRef = firestoreService.itemsCollection.doc(docId);
                  await docRef.update({
                    'price': bid,
                    'bidderCount': FieldValue.increment(1),
                  });

                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Bid placed successfully!"),
                        backgroundColor: kPrimaryColor,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => errorText = "Failed to place bid. Try again.");
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Dispose controller after dialog is completely closed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    });
  }
}

class AddFavoriteContainer extends ConsumerWidget {
  final String docId;

  const AddFavoriteContainer({super.key, required this.docId});

  Future<void> _incrementFavorite(BuildContext context) async {
    try {
      final firestoreService = FirestoreService();
      await firestoreService.itemsCollection.doc(docId).update({
        'favoriteCount': FieldValue.increment(1),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to favorites!"),
            backgroundColor: kPrimaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to add to favorites. Try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemProvider(docId));

    return itemAsync.when(
      data: (doc) {
        final data = doc.data();
        final favoriteCount = data?['favoriteCount'] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 235, 248, 238),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _incrementFavorite(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: kPrimaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "Add to Favorite",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
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
          alignment: Alignment.center,
          child: Text(
            'Error loading favorites: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}