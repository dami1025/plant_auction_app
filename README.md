# Auction Demo

This is a Flutter + Firebase auction demo project.

## Setup

1. Install Flutter SDK.
2. Run `flutter pub get`.
3. Set up Firebase and run `flutterfire configure`.
4. Replace `lib/auction_page.dart` and `lib/providers.dart` with the full code from ChatGPT instructions.
5. Seed an item in Firestore (see instructions in ChatGPT).
6. Run with `flutter run`.

## Note
This zip includes placeholder files for auction_page.dart and providers.dart. Replace them with the full logic provided in the ChatGPT messages.

## App Flow Chart
```
+-------------------+
|       User        |
+-------------------+
        |
        v
+-------------------+
|  Opens Item Page  |
+-------------------+
        |
        v
+-------------------+
| BuildItemList UI  |
| (ConsumerWidget)  |
+-------------------+
        |
        v
+--------------------------+
| Watches BiddingSession   |
| Provider (Riverpod)      |
+--------------------------+
        |
        v
+--------------------------+
| Display Item Info        |
| - Title, Price           |
| - Favorites              |
| - Countdown Timer        |
| - Bid Button             |
+--------------------------+
        |
        v
+----------------------------+
| User Taps "Place Bid"      |
+----------------------------+
        |
        v
+----------------------------+
| Show Bid Dialog            |
| - Validate bid > current   |
| - Loading Indicator        |
+----------------------------+
        |
        v
+----------------------------+
| Update Firestore           |
| - price                   |
| - bidderCount             |
| - lastBidTime             |
| - sessionStatus           |
+----------------------------+
        |
        v
+----------------------------+
| BiddingSessionNotifier     |
| - Listens to Firestore     |
| - Updates session state    |
|   (notStarted, active,     |
|    ended, cancelled)       |
| - Starts timers (2-min /  |
|   60-sec)                  |
+----------------------------+
        |
        v
+----------------------------+
| UI Auto Rebuild            |
| - Update Bid Button state  |
| - Countdown Timer          |
| - Bidding Status Chip      |
+----------------------------+
        |
        v
+----------------------------+
| User taps "Favorite"       |
+----------------------------+
        |
        v
+----------------------------+
| Update Firestore           |
| - favoriteCount            |
| - isFavorited              |
+----------------------------+
        |
        v
+----------------------------+
| UI Auto Rebuild            |
| - Favorite Button state    |
+----------------------------+
```
## Data Flow
```
User Interaction
   │
   ├─ Tap Place Bid / Favorite
   │       │
   │       ▼
   │   PlaceBidButton / FavoriteButton (ConsumerWidget)
   │       │
   │       └─ Reads biddingSessionProvider / itemProvider
   │       │
   │       ▼
   │   _showBidDialog / _toggleFavorite
   │       │
   │       └─ Firestore update:
   │           - price, bidderCount, lastBidTime
   │           - favoriteCount, isFavorited
   │
   ▼
BiddingSessionNotifier (StateNotifier)
   │
   ├─ Watches Firestore doc for changes
   │
   ├─ Determines session state:
   │     - Not Started
   │     - Active (0 bids → 2-min timer / ≥1 bid → 60-sec timer)
   │     - Ended
   │     - Cancelled
   │
   └─ Updates state and optionally Firestore sessionStatus

Items Collection (Firestore)
   │
   ├─ Stores per-item data:
   │     - title, price, description
   │     - bidStartTime, lastBidTime, bidderCount
   │     - favoriteCount, storageFolder, sessionStatus
   │
   └─ Provides snapshots for real-time updates

UI Widgets
   │
   ├─ BuildItemList (ConsumerWidget)
   │     ├─ Watches biddingSessionProvider
   │     ├─ Displays:
   │     │     - Title, price, favorites, bids
   │     │     - Countdown timers (CountdownText / SessionCountdown)
   │     │     - Bidding status chips
   │     │     - Image slider (via FutureBuilder + Firebase Storage)
   │
   ├─ BuildDescriptionBox
   │     └─ Displays item description
   │
   └─ PlaceBidButton / FavoriteButton
         └─ Interacts with Firestore through StateNotifier or Future updates

Countdown Timers
   │
   ├─ CountdownText → general auction countdown (days/hours/min)
   └─ SessionCountdown / BidSessionCountdown → precise countdown (min/sec) for active sessions
         └─ Updates UI every second via Timer
```
