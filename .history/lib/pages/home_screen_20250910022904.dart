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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedItem;

  void _onItemSelected(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    setState(() {
      _selectedItem = doc;
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemsCollectionProvider);

    return Scaffold(
      appBar: buildAppBar(context),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No items found'));
          }

          // Ensure selection is in sync
          _selectedItem ??= items.first;
          try {
            _selectedItem =
                items.firstWhere((item) => item.id == _selectedItem?.id);
          } catch (_) {
            _selectedItem = items.first;
          }

          final selectedData = _selectedItem!.data();

          return SingleChildScrollView(
            child: Column(
              children: [
                PlantImagesList(
                  docId: _selectedItem!.id,
                  folderName: selectedData['storageFolder'] ?? '',
                ),
                BuildItemList(
                  selectedItem: _selectedItem!,
                  allItems: items,
                  onItemSelected: _onItemSelected,
                ),
                BuildDescriptionBox(itemData: selectedData),
                PlaceBidButton(docId: _selectedItem!.id),
                FavoriteButton(docId: _selectedItem!.id),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: buildFooter(context), // ✅ moved here
    );
  }
}
