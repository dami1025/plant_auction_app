import 'package:auction_demo/component/data/riverpod.dart';
import 'package:auction_demo/pages/appbar.dart';
import 'package:auction_demo/pages/footer.dart';
import 'package:auction_demo/widgets/buy_bid.dart';
import 'package:auction_demo/widgets/item_des.dart';
import 'package:auction_demo/widgets/item_price.dart';
import 'package:auction_demo/widgets/plant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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
          if (items.isEmpty) return const Center(child: Text('No items found'));

          final selected = selectedItem ?? items.first;
          final selectedData = selected.data();

          return SingleChildScrollView(
            child: Column(
              children: [
                PlantImagesList(
                  docId: selected.id,
                  folderName: selectedData['storageFolder'] ?? '',
                ),
                BuildItemList(
                  selectedItem: selected,
                  allItems: items,
                  onItemSelected: (doc) {
                    ref.read(selectedItemProvider.notifier).selectItem(doc);
                  },
                ),
                BuildDescriptionBox(itemData: selectedData),
                PlaceBidButton(docId: selected.id),
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
