// ================= FIRESTORE SERVICE =================

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference itemsCollection =
      FirebaseFirestore.instance.collection('item1');

  Stream<QuerySnapshot> getItemsStream() {
    return itemsCollection.snapshots();
  }
}

// Make sure you're using the same instance
final firestoreService = FirestoreService();