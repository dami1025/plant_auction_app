// ✅ State provider for the selected item
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// connects Firestore with UI reactively using Riverpod.
// Collection reference
final itemsCollection = FirebaseFirestore.instance.collection('items');

// Provider for getting all items from the collection
final itemsCollectionProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return itemsCollection.snapshots().map((snapshot) {
    print('Firestore snapshot received: ${snapshot.docs.length} items');
    print('From cache: ${snapshot.metadata.isFromCache}');
    return snapshot.docs;
  });
});



// Provider for getting a single item by document ID (family provider)
final itemProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
  (ref, docId) {
    return itemsCollection.doc(docId).snapshots();
  },
);

// Holds the currently selected item, automatically syncing with items list
class SelectedItemNotifier extends StateNotifier<QueryDocumentSnapshot<Map<String, dynamic>>?> {
  final Ref ref;

  SelectedItemNotifier(this.ref) : super(null) {
    ref.listen<AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>(
      itemsCollectionProvider,
      (previous, next) {
        next.whenData((items) {
          print('Items updated: ${items.length}');
          if (items.isNotEmpty) {
            if (state == null) {
              // No selection, select first
              print('Selecting first item: ${items.first.id}');
              state = items.first;
            } else {
              // Try to find the currently selected item in the new list
              final currentId = state!.id;
              final updatedItem = items.firstWhere(
                (item) => item.id == currentId,
                orElse: () => items.first,
              );
              
              // Always update the state with the fresh document snapshot
              print('Updating selected item: ${updatedItem.id}');
              state = updatedItem;
            }
          } else {
            state = null;
          }
        });
      },
    );
  }

  void selectItem(QueryDocumentSnapshot<Map<String, dynamic>> item) {
    state = item;
  }
}

// Provider for the selected item
final selectedItemProvider =
    StateNotifierProvider.autoDispose<SelectedItemNotifier, QueryDocumentSnapshot<Map<String, dynamic>>?>(
  (ref) => SelectedItemNotifier(ref),
);

//itemsCollectionProvider listens to Firestore → gets all items.

//selectedItemIdProvider stores which item the user clicked on.

//itemProvider(selectedItemId) listens to that item reactively.