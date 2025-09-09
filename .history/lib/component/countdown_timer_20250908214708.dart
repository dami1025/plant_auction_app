import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// CountdownText shows a simple auction countdown (days/hours/minutes)
class CountdownText extends StatefulWidget {
  final dynamic endTime; // Timestamp or DateTime
  const CountdownText({super.key, required this.endTime});

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  late Timer _timer;
  late DateTime _endTime;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _convertEndTime();
    _updateRemaining();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(_updateRemaining);
    });
  }

  void _convertEndTime() {
    if (widget.endTime is Timestamp) {
      _endTime = (widget.endTime as Timestamp).toDate();
    } else if (widget.endTime is DateTime) {
      _endTime = widget.endTime;
    } else {
      throw Exception('CountdownText: endTime must be Timestamp or DateTime');
    }
  }

  void _updateRemaining() {
    _remaining = _endTime.difference(DateTime.now());
  }

  @override
  void didUpdateWidget(covariant CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTime != widget.endTime) {
      _convertEndTime();
      _updateRemaining();
    }
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
    return "${days}d ${hours}h ${minutes}m";
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
