import 'package:auction_demo/component/data/riverpod.dart';
import 'package:auction_demo/pages/appbar.dart';
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

          // Initial selection or sync with latest stream
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
                // Plant images
                PlantImagesList(
                  docId: _selectedItem!.id,
                  folderName: selectedData['storageFolder'] ?? '',
                ),

                // Display selected item (with optional item switcher)
                BuildItemList(
                  selectedItem: _selectedItem!,
                  allItems: items,
                  onItemSelected: (doc) {
                    _onItemSelected(doc);
                  },
                ),

                // Description
                BuildDescriptionBox(itemData: selectedData),

                // Place bid (live current price)
                PlaceBidButton(
                  docId: _selectedItem!.id,
                ),

                // Favorite (live favorite count)
                FavoriteButton(
                  docId: _selectedItem!.id,
                ),
              ],
            ),
          )
      ),footer:;
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}