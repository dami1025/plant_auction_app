// ✅ State provider for the selected item
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedItemProvider = StateProvider<
    QueryDocumentSnapshot<Map<String, dynamic>>?>((ref) => null);