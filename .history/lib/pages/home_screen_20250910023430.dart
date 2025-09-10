import 'package:auction_demo/component/data/riverpod.dart';
import 'package:auction_demo/pages/appbar.dart';
import 'package:auction_demo/pages/footer.dart';
import 'package:auction_demo/widgets/buy_bid.dart';
import 'package:auction_demo/widgets/item_des.dart';
import 'package:auction_demo/widgets/item_price.dart';
import 'package:auction_demo/widgets/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemsCollectionProvider);
    final selectedItem = ref.watch(selectedItemProvider);

    return Scaffold(
      appBar: buildAppBar(context),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No items found'));
          }

          // Ensure selected item is synced
          final selected =
              selectedItem ?? items.first; // fallback to first item

          // Sync provider if needed
          if (selectedItem == null ||
              !items.any((item) => item.id == selected.id)) {
            ref.read(selectedItemProvider.notifier).state = items.first;
          }

          final selectedData = selected.data();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Plant images
                PlantImagesList(
                  docId: selected.id,
                  folderName: selectedData['storageFolder'] ?? '',
                ),

                // Display selected item (with item switcher)
                BuildItemList(
                  selectedItem: selected,
                  allItems: items,
                  onItemSelected: (doc) {
                    ref.read(selectedItemProvider.notifier).state = doc;
                  },
                ),

                // Description
                BuildDescriptionBox(itemData: selectedData),

                // Place bid (live current price)
                PlaceBidButton(docId: selected.id),

                // Favorite (live favorite count)
                FavoriteButton(docId: selected.id),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: buildFooter(context),
    );
  }
}
