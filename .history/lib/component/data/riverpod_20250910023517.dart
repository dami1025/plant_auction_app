// ✅ State provider for the selected item
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// connects Firestore with UI reactively using Riverpod.
// Collection reference
final itemsCollection = FirebaseFirestore.instance.collection('items');

// Provider for getting all items from the collection
final itemsCollectionProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return itemsCollection.snapshots().map((snapshot) => snapshot.docs);
});

// Provider for getting a single item by document ID (family provider)
final itemProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
  (ref, docId) {
    return itemsCollection.doc(docId).snapshots();
  },
);

// ✅ State provider for the selected item
final selectedItemProvider = StateProvider<
    QueryDocumentSnapshot<Map<String, dynamic>>?>((ref) => null);