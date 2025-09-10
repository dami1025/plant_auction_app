// ✅ State provider for the selected item
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// connects Firestore with UI reactively using Riverpod.
// Collection reference
final itemsCollection = FirebaseFirestore.instance.collection('items');

// Provider for getting all items from the collection
final itemsCollectionProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return itemsCollection.snapshots(includeMetadataChanges: true).map((snapshot) => snapshot.docs);
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
    // Listen to the items collection
    ref.listen<AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>(
      itemsCollectionProvider,
      (previous, next) {
        next.whenData((items) {
          if (items.isNotEmpty) {
            // If current selection is null or no longer exists, select first item
            if (state == null || !items.any((item) => item.id == state!.id)) {
              state = items.first;
            }
          } else {
            state = null;
          }
        });
      },
    );
  }

  // Optional: allow manual selection
  void selectItem(QueryDocumentSnapshot<Map<String, dynamic>> item) {
    state = item;
  }
}

// Provider for the selected item
final selectedItemProvider =
    StateNotifierProvider<SelectedItemNotifier, QueryDocumentSnapshot<Map<String, dynamic>>?>(
  (ref) => SelectedItemNotifier(ref),
);

//itemsCollectionProvider listens to Firestore → gets all items.

//selectedItemIdProvider stores which item the user clicked on.

//itemProvider(selectedItemId) listens to that item reactively.