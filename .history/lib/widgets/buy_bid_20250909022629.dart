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
              onPressed: () => _showBidDialog(context, currentPrice),
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
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Text(
          "Error loading item: $err",
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  void _showBidDialog(BuildContext context, double currentPrice) {
    final controller = TextEditingController();
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
              hintText: "Bid > \$${currentPrice.toStringAsFixed(2)}",
              errorText: errorText,
              prefixText: "\$",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                controller.dispose();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final bid = double.tryParse(controller.text.trim());
                if (bid == null || bid <= currentPrice) {
                  setState(() {
                    errorText =
                        "Bid must be higher than \$${currentPrice.toStringAsFixed(2)}";
                  });
                  return;
                }

                print('Attempting to place bid on docId: $docId with amount: $bid');

                final docRef = FirebaseFirestore.instance.collection('items').doc(docId);

                try {
                  await FirebaseFirestore.instance.runTransaction((txn) async {
                    final snapshot = await txn.get(docRef);

                    if (!snapshot.exists) {
                      throw Exception("Document does not exist!");
                    }

                    final current = (snapshot['price'] ?? 0).toDouble();
                    if (bid <= current) throw Exception("Bid too low");

                    txn.update(docRef, {
                      'price': bid,
                      'bidderCount': FieldValue.increment(1),
                    });
                  });

                  print("Bid placed successfully for docId: $docId");
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Bid placed: \$${bid.toStringAsFixed(2)}"),
                        backgroundColor: kPrimaryColor,
                      ),
                    );
                  }
                } catch (e) {
                  print("Failed to place bid: $e");
                  setState(() => errorText = "Failed to place bid. $e");
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}

class AddFavoriteContainer extends ConsumerWidget {
  final String docId;

  const AddFavoriteContainer({super.key, required this.docId});

  Future<void> _incrementFavorite(BuildContext context) async {
    final docRef = FirebaseFirestore.instance.collection('items').doc(docId);

    print('Attempting to add favorite to docId: $docId');

    try {
      await docRef.update({'favoriteCount': FieldValue.increment(1)});
      print('Favorite incremented successfully for docId: $docId');

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
      print("Failed to increment favorite: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add favorite. $e"),
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
        final favoriteCount = doc.data()?['favoriteCount'] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE7F8EE),
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
                    "Add to Favorite ",
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
        child: Text(
          'Error loading favorites: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
