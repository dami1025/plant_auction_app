// ✅ State provider for the selected item
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedItemProvider = StateProvider<
    QueryDocumentSnapshot<Map<String, dynamic>>?>((ref) => null);