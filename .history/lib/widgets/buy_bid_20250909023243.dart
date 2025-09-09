import 'package:auction_demo/component/data/firestore.dart';
import 'package:auction_demo/component/data/riverpod.dart';
import 'package:auction_demo/screens/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:auction_demo/screens/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auction_demo/component/data/riverpod.dart';

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
        final bidderCount = data?['bidderCount'] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showBidDialog(context),
                child: const Text(
                  "Place Bid",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Current Price: \$${currentPrice.toStringAsFixed(2)} | Bids: $bidderCount",
                style: const TextStyle(fontSize: 16),
              ),
            ],
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

  void _showBidDialog(BuildContext context) {
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
              hintText: "Enter bid amount",
              errorText: errorText,
              prefixText: "\$",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final bid = double.tryParse(controller.text.trim());
                if (bid == null || bid <= 0) {
                  setState(() => errorText = "Enter a valid amount");
                  return;
                }

                final docRef =
                    FirebaseFirestore.instance.collection('items').doc(docId);

                print('Attempting bid on $docId: $bid');

                try {
                  // Use transaction to get latest price & increment safely
                  await FirebaseFirestore.instance.runTransaction((txn) async {
                    final snapshot = await txn.get(docRef);
                    if (!snapshot.exists) throw Exception("Item does not exist");

                    final currentPrice =
                        (snapshot['price'] ?? 0).toDouble();
                    if (bid <= currentPrice) throw Exception(
                        "Bid too low. Current price is \$${currentPrice.toStringAsFixed(2)}");

                    txn.update(docRef, {
                      'price': bid,
                      'bidderCount': FieldValue.increment(1),
                    });
                  });

                  print("Bid successful on $docId");

                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Bid placed: \$${bid.toStringAsFixed(2)}"),
                      backgroundColor: kPrimaryColor,
                    ),
                  );
                } catch (e) {
                  print("Bid failed: $e");
                  if (!ctx.mounted) return;
                  setState(() => errorText = e.toString());
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
