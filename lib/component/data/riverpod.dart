import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Collection reference
final itemsCollection = FirebaseFirestore.instance.collection('item1');

// Provider for getting all items from the collection
final itemsCollectionProvider = StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return itemsCollection.snapshots().map((snapshot) => snapshot.docs);
});

// Provider for getting a single item by document ID (family provider)
final itemProvider = StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
  (ref, docId) {
    return itemsCollection.doc(docId).snapshots();
  },
);

// If you have a FirestoreService class, you can also use it like this:
// class FirestoreService {
//   final CollectionReference<Map<String, dynamic>> itemsCollection = 
//       FirebaseFirestore.instance.collection('item1');
// }
// 
// final firestoreServiceProvider = Provider((ref) => FirestoreService());
// 
// final itemsCollectionProvider = StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
//   final service = ref.watch(firestoreServiceProvider);
//   return service.itemsCollection.snapshots().map((snapshot) => snapshot.docs);
// });
