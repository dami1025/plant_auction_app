import 'package:auction_demo/component/data/riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:auction_demo/data/firestore.dart';
import 'package:auction_demo/component/plant.dart';
import 'package:auction_demo/component/item_des.dart';
import 'package:auction_demo/component/item_price.dart';
import 'package:auction_demo/component/buy_bid.dart';
import 'package:auction_demo/screens/constants.dart';
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
    // If itemProvider is a StreamProvider.family, you need to provide a parameter
    // Replace 'itemsCollectionProvider' with the correct provider name that returns all items
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
                PlaceBidContainer(
                  docId: _selectedItem!.id,
                ),

                // Favorite (live favorite count)
                AddFavoriteContainer(
                  docId: _selectedItem!.id,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: kPrimaryColor,
    elevation: 0,
    automaticallyImplyLeading: false,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Item',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    ),
    leading: IconButton(
      icon: const Icon(Icons.menu),
      color: kTextColor,
      onPressed: () {},
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.shopping_cart),
        color: kTextColor,
        onPressed: () {},
      ),
    ],
  );
}