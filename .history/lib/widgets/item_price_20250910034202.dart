import 'dart:async';
import 'package:auction_demo/component/countdown_timer.dart';
import 'package:auction_demo/component/data/riverpod.dart';
import 'package:auction_demo/screens/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Bidding Session State Management
enum BiddingSessionStatus {
  notStarted,
  active,
  ended,
  cancelled,
}

class BiddingSessionState {
  final BiddingSessionStatus status;
  final DateTime? sessionEndTime;
  final DateTime? startTime;
  final int bidCount;
  final DateTime? lastBidTime;

  const BiddingSessionState({
    required this.status,
    this.sessionEndTime,
    this.startTime,
    required this.bidCount,
    this.lastBidTime,
  });

  BiddingSessionState copyWith({
    BiddingSessionStatus? status,
    DateTime? sessionEndTime,
    DateTime? startTime,
    int? bidCount,
    DateTime? lastBidTime,
  }) {
    return BiddingSessionState(
      status: status ?? this.status,
      sessionEndTime: sessionEndTime,
      startTime: startTime ?? this.startTime,
      bidCount: bidCount ?? this.bidCount,
      lastBidTime: lastBidTime ?? this.lastBidTime,
    );
  }
}



  class BiddingSessionNotifier extends StateNotifier<BiddingSessionState> {
  final String itemId;
  Timer? _sessionTimer;
  StreamSubscription? _firestoreSubscription;

  BiddingSessionNotifier(this.itemId)
      : super(const BiddingSessionState(
          status: BiddingSessionStatus.notStarted,
          bidCount: 0,
        )) {
    _initializeSession();
  }

  void _initializeSession() {
    
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('items')
        .doc(itemId)
        .snapshots()
        .listen(_handleFirestoreUpdate);
  }

  void _handleFirestoreUpdate(DocumentSnapshot doc) {
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final startTime = _parseDateTime(data['bidStartTime']);
    final bidCount = data['bidderCount'] ?? 0;
    final lastBidTime = _parseDateTime(data['lastBidTime']);

    if (startTime == null) return;

    final now = DateTime.now();

    if (now.isBefore(startTime)) {
      // Session not started yet
      state = state.copyWith(
        status: BiddingSessionStatus.notStarted,
        startTime: startTime,
        bidCount: bidCount,
        lastBidTime: lastBidTime,
      );
      return;
    }

    // Session started
    if (bidCount == 0) {
      // 0 bids → 2-minute timer
      final endTime = startTime.add(const Duration(minutes: 2));
      state = state.copyWith(
        status: BiddingSessionStatus.active,
        sessionEndTime: endTime,
        startTime: startTime,
        bidCount: bidCount,
        lastBidTime: lastBidTime,
      );
      _startTimer(endTime, _cancelSession);
    } else {
      // ≥1 bid → 60-second timer from last bid
      final lastBid = lastBidTime ?? startTime;
      final endTime = lastBid.add(const Duration(seconds: 60));
      state = state.copyWith(
        status: BiddingSessionStatus.active,
        sessionEndTime: endTime,
        startTime: startTime,
        bidCount: bidCount,
        lastBidTime: lastBidTime,
      );
      _startTimer(endTime, _endSession);
    }
  }

  DateTime? _parseDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }

  void _resetSessionTimer() {
    _sessionTimer?.cancel();

    if (state.bidCount == 0) {
      // still no bids → 2-minute cancel timer
      final endTime = DateTime.now().add(const Duration(minutes: 2));
      state = state.copyWith(sessionEndTime: endTime);
      _startTimer(endTime, _cancelSession);
    } else {
      // has bids → 60-second end timer
      final endTime = DateTime.now().add(const Duration(seconds: 60));
      state = state.copyWith(sessionEndTime: endTime);
      _startTimer(endTime, _endSession);
    }
  }

  void _startTimer(DateTime endTime, VoidCallback onTimeout) {
    _sessionTimer?.cancel();
    final duration = endTime.difference(DateTime.now());
    if (duration.isNegative) {
      onTimeout();
      return;
    }
    _sessionTimer = Timer(duration, onTimeout);
  }

  void _cancelSession() {
    _sessionTimer?.cancel();
    state = state.copyWith(status: BiddingSessionStatus.cancelled);
    _updateFirestoreStatus('cancelled');
  }

  void _endSession() {
    _sessionTimer?.cancel();
    state = state.copyWith(status: BiddingSessionStatus.ended);
    _updateFirestoreStatus('ended');
  }

  void _updateFirestoreStatus(String status) {
    itemsCollection
        .doc(itemId)
        .update({'sessionStatus': status}).catchError((error) {
      print('Error updating session status: $error');
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}


// Riverpod Provider
final biddingSessionProvider = StateNotifierProvider.family
    <BiddingSessionNotifier, BiddingSessionState, String>(
  (ref, itemId) => BiddingSessionNotifier(itemId),
);

// Updated BuildItemList Widget
class BuildItemList extends ConsumerWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> selectedItem;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> allItems;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>>)
      onItemSelected;

  const BuildItemList({
    super.key,
    required this.selectedItem,
    required this.allItems,
    required this.onItemSelected,
  });

  // Constants for styling
  static const double _imageSize = 40;
  static const double _iconSize = 20;
  static const double _loadingIndicatorSize = 15;
  static const double _loadingStrokeWidth = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = selectedItem.data();
    final title = data['title'] ?? 'No Title';
    final price = data['price']?.toString() ?? '0';
    final endTimestamp = data['endTime'];
    final bidderCount = data['bidderCount']?.toString() ?? '0';
    final favoriteCount = data['favoriteCount'] ?? 0;

    // Watch bidding session state
    final biddingSessionState = ref.watch(biddingSessionProvider(selectedItem.id));

    return Column(
      children: [
        // Display the selected item
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 15, right: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Bidding Session Status Chip
              _buildBiddingSessionChip(biddingSessionState),
              const SizedBox(height: 8),

              // Price + Best Offer + Favorite count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPriceSection(price),
                  _buildFavoriteSection(favoriteCount),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                "+ Shipping will be determined",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 4),
              // Bid count + bullet + countdown
              _buildBidCountdownSection(bidderCount, endTimestamp, biddingSessionState),
            ],
          ),
        ),

        // Optional: Add a section to switch between items
        if (allItems.length > 1) ...[
          const SizedBox(height: 20),
          _buildItemSelector(),
        ],
      ],
    );
  }

  Widget _buildBiddingSessionChip(BiddingSessionState sessionState) {
    Color chipColor;
    String chipText;
    Widget? countdownWidget;

    switch (sessionState.status) {
      case BiddingSessionStatus.notStarted:
        chipColor = Colors.orange;
        chipText = 'Bidding starts soon';
        break;
      case BiddingSessionStatus.active:
        chipColor = Colors.green;
        chipText = 'Live Bidding';
        if (sessionState.sessionEndTime != null) {
          countdownWidget = Text(
            ' • Ends in ',
            style: TextStyle(color: chipColor, fontSize: 12),
          );
        }
        break;
      case BiddingSessionStatus.ended:
        chipColor = Colors.blue;
        chipText = 'Bidding Ended';
        break;
      case BiddingSessionStatus.cancelled:
        chipColor = Colors.red;
        chipText = 'Bidding Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sessionState.status == BiddingSessionStatus.active
                ? Icons.gavel
                : Icons.access_time,
            size: 16,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (countdownWidget != null) countdownWidget,
          if (sessionState.sessionEndTime != null && sessionState.status == BiddingSessionStatus.active)
            SessionCountdown(
              endTime: sessionState.sessionEndTime!,
              textColor: chipColor,
            ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(String price) {
    return Row(
      children: [
        Text(
          "\$$price",
          style: const TextStyle(
            fontSize: 25,
            color: kPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "or",
          style: TextStyle(
            fontSize: 20,
            color: Color.fromARGB(255, 10, 11, 10),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "Best Offer",
          style: TextStyle(
            fontSize: 25,
            color: kPrimaryColor,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteSection(int favoriteCount) {
    return Row(
      children: [
        const Icon(
          Icons.favorite,
          color: kPrimaryColor,
          size: 30,
        ),
        const SizedBox(width: 4),
        Text(
          favoriteCount.toString(),
          style: const TextStyle(
            fontSize: 30,
            color: kPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBidCountdownSection(
    String bidderCount, 
    dynamic endTimestamp, 
    BiddingSessionState sessionState
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "$bidderCount bid${int.parse(bidderCount) == 1 ? '' : 's'}",
              style: const TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 13, 13, 13),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 4),
            const Text("•", style: TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            const Text("Ends in ", style: TextStyle(fontSize: 16)),
            if (endTimestamp != null) CountdownText(endTime: endTimestamp),
          ],
        ),
        if (sessionState.status == BiddingSessionStatus.active && sessionState.bidCount == 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "⚠️ Session will be cancelled in 2 minutes without bids",
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Other Items:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allItems.length,
              itemBuilder: (context, index) {
                final item = allItems[index];
                final itemData = item.data();
                final isSelected = item.id == selectedItem.id;

                return GestureDetector(
                  onTap: () => onItemSelected(item),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? kPrimaryColor
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: _imageSize,
                        height: _imageSize,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _buildItemImage(itemData, isSelected),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(Map<String, dynamic> itemData, bool isSelected) {
    final storageFolder = itemData['storageFolder'] as String?;

    if (storageFolder == null || storageFolder.isEmpty) {
      return _buildPlaceholderContainer(isSelected);
    }

    return FutureBuilder<String?>(
      future: _getFirstImageUrl(storageFolder),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContainer(isSelected);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildPlaceholderContainer(isSelected);
        }

        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          width: _imageSize,
          height: _imageSize,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderContainer(isSelected);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingContainer(isSelected);
          },
        );
      },
    );
  }

  Future<String?> _getFirstImageUrl(String folderPath) async {
    try {
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child(folderPath);
      
      // List all items in the folder
      final listResult = await ref.listAll();
      
      if (listResult.items.isEmpty) {
        return null;
      }
      
      // Sort items by name to get consistent "first" image
      listResult.items.sort((a, b) => a.name.compareTo(b.name));
      
      // Get download URL for the first image
      final firstImageRef = listResult.items.first;
      return await firstImageRef.getDownloadURL();
    } catch (e) {
      print('Error getting first image URL: $e');
      return null;
    }
  }

  Widget _buildPlaceholderContainer(bool isSelected) {
    return Container(
      width: _imageSize,
      height: _imageSize,
      color: Colors.grey[400],
      child: Icon(
        Icons.image_not_supported,
        color: isSelected ? Colors.white : Colors.grey[600],
        size: _iconSize,
      ),
    );
  }

  Widget _buildLoadingContainer(bool isSelected) {
    return Container(
      width: _imageSize,
      height: _imageSize,
      color: Colors.grey[300],
      child: Center(
        child: SizedBox(
          width: _loadingIndicatorSize,
          height: _loadingIndicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: _loadingStrokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(
              isSelected ? Colors.white : kPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Countdown Widget for Bidding Session
class SessionCountdown extends StatefulWidget {
  final DateTime endTime;
  final Color textColor;

  const SessionCountdown({
    Key? key,
    required this.endTime,
    required this.textColor,
  }) : super(key: key);

  @override
  State<SessionCountdown> createState() => _SessionCountdownState();
}

class _SessionCountdownState extends State<SessionCountdown> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final remaining = widget.endTime.difference(now);
    
    if (remaining.isNegative) {
      setState(() => _remainingTime = Duration.zero);
      _timer?.cancel();
    } else {
      setState(() => _remainingTime = remaining);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remainingTime == Duration.zero) {
      return Text(
        '0s',
        style: TextStyle(
          color: widget.textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    
    return Text(
      minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s',
      style: TextStyle(
        color: widget.textColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
}