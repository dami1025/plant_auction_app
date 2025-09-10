import 'package:auction_demo/screens/constants.dart';
import 'package:flutter/material.dart';

Footer buildFooter(BuildContext context) {
  return Footer(
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
      ],
    ),