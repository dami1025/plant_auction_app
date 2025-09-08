import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ---------------------------
/// Bid Session State & Notifier
/// ---------------------------
enum BidSessionStatus { notStarted, active, ended, canceled }

class BidSessionState {
  final BidSessionStatus status;
  final DateTime? sessionStartTime;
  final DateTime? sessionEndTime;
  final DateTime? lastBidTime;

  const BidSessionState({
    required this.status,
    this.sessionStartTime,
    this.sessionEndTime,
    this.lastBidTime,
  });

  BidSessionState copyWith({
    BidSessionStatus? status,
    DateTime? sessionStartTime,
    DateTime? sessionEndTime,
    DateTime? lastBidTime,
  }) {
    return BidSessionState(
      status: status ?? this.status,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      sessionEndTime: sessionEndTime ?? this.sessionEndTime,
      lastBidTime: lastBidTime ?? this.lastBidTime,
    );
  }
}

class BidSessionNotifier extends StateNotifier<BidSessionState> {
  final String docId;
  Timer? _bidTimer;
  StreamSubscription<DocumentSnapshot>? _subscription;

  static const Duration _bidExtensionDuration = Duration(seconds: 60);
  static const Duration _autoCancelDuration = Duration(minutes: 2);

  bool _hasActivated = false;
  DateTime? _lastStartTime;
  String? _lastStatus;

  BidSessionNotifier(this.docId)
      : super(const BidSessionState(status: BidSessionStatus.notStarted)) {
    _listenToBidUpdates();
  }

  @override
  void dispose() {
    _bidTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  void _activateSession(DateTime? lastBid) {
    if (_hasActivated) return;
    _hasActivated = true;

    final now = DateTime.now();
    state = state.copyWith(
      status: BidSessionStatus.active,
      sessionStartTime: now,
      lastBidTime: lastBid,
    );

    _updateFirestoreStatus('active');

    // Determine end time
    final endTime = lastBid != null
        ? lastBid.add(_bidExtensionDuration)
        : now.add(_autoCancelDuration);

    _setTimer(endTime);
  }

  void _setTimer(DateTime targetEndTime) {
    _bidTimer?.cancel();
    state = state.copyWith(sessionEndTime: targetEndTime);

    final remaining = targetEndTime.difference(DateTime.now());
    if (remaining.isNegative) {
      endOrCancelSession();
      return;
    }

    _bidTimer = Timer(remaining, endOrCancelSession);
  }

  void endOrCancelSession() {
    if (state.lastBidTime == null) {
      _cancelSession();
    } else {
      _endSession();
    }
  }

  void _cancelSession() {
    state = state.copyWith(status: BidSessionStatus.canceled);
    _updateFirestoreStatus('canceled');
    _hasActivated = false;
  }

  void _endSession() {
    state = state.copyWith(status: BidSessionStatus.ended);
    _updateFirestoreStatus('ended');
    _hasActivated = false;
  }

  void _updateFirestoreStatus(String status) {
    final data = <String, dynamic>{'bidSessionStatus': status};
    if (status == 'ended' || status == 'canceled') {
      data['bidEndTime'] = Timestamp.fromDate(DateTime.now());
    }

    FirebaseFirestore.instance
        .collection('item1') 
        .doc(docId)
        .update(data)
        .then((_) => print('Updated bidSessionStatus: $status'))
        .catchError((e) => print('Error updating bid session: $e'));
  }

  void _listenToBidUpdates() {
    _subscription = FirebaseFirestore.instance
        .collection('item1')
        .doc(docId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final newStartTime = (data['bidStartTime'] as Timestamp?)?.toDate();
      final lastBidTime = (data['lastBidTime'] as Timestamp?)?.toDate();
      final sessionStatus = data['bidSessionStatus'] as String?;

      // Only update if status actually changed
      if (sessionStatus != null && sessionStatus != _lastStatus) {
        _lastStatus = sessionStatus;
        final newStatus = _mapStatusString(sessionStatus);
        if (newStatus != state.status) {
          state = state.copyWith(status: newStatus);
          if (newStatus == BidSessionStatus.ended ||
              newStatus == BidSessionStatus.canceled) {
            _bidTimer?.cancel();
            _hasActivated = false;
          }
        }
      }

      // Only activate session if new start time appears
      if (newStartTime != null && newStartTime != _lastStartTime) {
        _lastStartTime = newStartTime;
        if (!_hasActivated) {
          _activateSession(lastBidTime);
        }
      }

      // Extend session for new bids
      if (lastBidTime != null &&
          (state.lastBidTime == null || lastBidTime.isAfter(state.lastBidTime!)) &&
          state.status == BidSessionStatus.active) {
        state = state.copyWith(lastBidTime: lastBidTime);
        _setTimer(lastBidTime.add(_bidExtensionDuration));
      }
    });
  }

  BidSessionStatus _mapStatusString(String status) {
    switch (status) {
      case 'active':
        return BidSessionStatus.active;
      case 'ended':
        return BidSessionStatus.ended;
      case 'canceled':
        return BidSessionStatus.canceled;
      default:
        return BidSessionStatus.notStarted;
    }
  }
}

/// ---------------------------
/// Riverpod provider
/// ---------------------------
final bidSessionProvider =
    StateNotifierProvider.family<BidSessionNotifier, BidSessionState, String>(
        (ref, docId) => BidSessionNotifier(docId));
