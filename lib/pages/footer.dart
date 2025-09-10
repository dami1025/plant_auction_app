import 'package:auction_demo/screens/constants.dart';
import 'package:flutter/material.dart';

BottomAppBar buildFooter(BuildContext context) {
  return BottomAppBar(
    color: kPrimaryColor,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Duong Tran',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.copyright,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '2025',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ),
  );
}
