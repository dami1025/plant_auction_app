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


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Listen to items stream and update selectedItemProvider only when items change
    ref.listen<AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>(
      itemsCollectionProvider,
      (previous, next) {
        next.whenData((items) {
          if (items.isNotEmpty) {
            final currentSelected = ref.read(selectedItemProvider);
            // Update only if current selection is null or no longer in the list
            if (currentSelected == null ||
                !items.any((item) => item.id == currentSelected.id)) {
              ref.read(selectedItemProvider.notifier).state = items.first;
            }
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsCollectionProvider);
    final selectedItem = ref.watch(selectedItemProvider);

    return Scaffold(
      appBar: buildAppBar(context),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('No items found'));

          // Use selectedItem, fallback to first if null (should be rare now)
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
                    ref.read(selectedItemProvider.notifier).state = doc;
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
