
import 'package:auction_demo/pages/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'component/data/firebase_options.dart';

import 'screens/constants.dart'; // should contain AuctionGalleryPage


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Plant Auction App',
    theme: ThemeData(
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: kBackgroundColor,
      textTheme: TextTheme(
      bodyLarge: TextStyle(color: kTextColor),
      bodyMedium: TextStyle(color: kTextColor),
      bodySmall: TextStyle(color: kTextColor),
      ), 
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
    home: const HomeScreen(),
  );
}

}