import 'package:auction_demo/screens/constants.dart';
import 'package:flutter/material.dart';

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: kPrimaryColor,
    elevation: 0,
    automaticallyImplyLeading: false,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Item',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    ),
    leading: IconButton(
      icon: const Icon(Icons.menu),
      color: kTextColor,
      onPressed: () {},
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.shopping_cart),
        color: kTextColor,
        onPressed: () {},
      ),
    ],
  );
}