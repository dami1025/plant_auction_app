import 'package:auction_demo/screens/constants.dart';
import 'package:flutter/material.dart';

class BuildDescriptionBox extends StatelessWidget {
  final Map<String, dynamic> itemData; // single item's data

  const BuildDescriptionBox({super.key, required this.itemData});

  @override
  Widget build(BuildContext context) {
    final description = itemData['description'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16), // inner padding
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 223, 244, 228),
          border: Border.all(color: kPrimaryColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}