import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CountdownText extends StatefulWidget {
  final Timestamp endTime;
  const CountdownText({super.key, required this.endTime});

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endTime.toDate().difference(DateTime.now());

    // update every minute (no need for every second if you only want d/h/m)
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        _remaining = widget.endTime.toDate().difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    return "${days}d ${hours}h ${minutes}m ";
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) {
      return const Text("Auction Ended!");
    }
    return Text(
      _formatRemaining(_remaining),
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
