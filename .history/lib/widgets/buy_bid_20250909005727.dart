import 'package:auction_demo/component/data/riverpod.dart';
import 'package:auction_demo/screens/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceBidButton extends ConsumerWidget {
  final String docId;

  const PlaceBidButton({super.key, required this.docId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showBidDialog(context, ref),
            child: Text(
              "Place Bid",
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kBackgroundColor),
            ),
          ),
        ));
  }

  void _showBidDialog(BuildContext context, WidgetRef ref) async {
    final doc =
        await FirebaseFirestore.instance.collection('items').doc(docId).get();
    final currentPrice = (doc.data()?['price'] ?? 0).toDouble();
    final controller = TextEditingController();
    String? errorText;

    await showDialog(
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
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final bid = double.tryParse(controller.text.trim());
                if (bid == null || bid <= currentPrice) {
                  setState(() => errorText =
                      "Bid must be higher than \$${currentPrice.toStringAsFixed(2)}");
                  return;
                }
                try {
                  await FirebaseFirestore.instance
                      .collection('items')
                      .doc(docId)
                      .update({
                    'price': bid,
                    'bidderCount': FieldValue.increment(1),
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Bid placed successfully!"),
                        backgroundColor: kPrimaryColor),
                  );
                } catch (e) {
                  setState(() => errorText = "Failed to place bid. Try again.");
                }
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

class FavoriteButton extends ConsumerWidget {
  final String docId;

  const FavoriteButton({super.key, required this.docId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemProvider(docId));

    return item.when(
      data: (doc) {
        final favoriteCount = doc.data()?['favoriteCount'] ?? 0;

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
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('items')
                      .doc(docId)
                      .update({'favoriteCount': FieldValue.increment(1)});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Added to favorites!"),
                      backgroundColor: kPrimaryColor,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to add to favorites. Try again."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
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
        child: Text(
          'Error loading favorites: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}
