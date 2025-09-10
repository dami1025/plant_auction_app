import 'package:auction_demo/screens/constants.dart';
import 'package:flutter/material.dart';

BottomAppBar buildFooter(BuildContext context) {
  return BottomAppBar(
    backgroundColor: kPrimaryColor,
    elevation: 0,
    automaticallyImplyLeading: false,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [       
        Text(
          'Duong Tran',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const Icon(
          Icons.copyright,
          color: kPrimaryColor,
          size: 30,
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
  )
}