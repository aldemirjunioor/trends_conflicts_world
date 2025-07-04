import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/event_detail/view/event_detail_screen.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, ValueNotifier<List<Map<String, dynamic>>>> _commentsNotifiers = {};

  String _generateUniqueEventId(Map<String, dynamic> event) {
    final dataId = event['data_id']?.toString() ?? '';
    final eventDate = event['event_date']?.toString() ?? '';
    final notes = event['notes']?.toString() ?? '';
    final combined = '$dataId-$eventDate-$notes';
    return sha1.convert(utf8.encode(combined)).toString();
  }

  void _goToEventDetail(BuildContext context, Map<String, dynamic> event) {
    final eventId = event['unique_id'] ?? _generateUniqueEventId(event);
    
    if (!_commentsNotifiers.containsKey(eventId)) {
      _commentsNotifiers[eventId] = ValueNotifier([]);
      _firestoreService.getComments(eventId).listen((snapshot) {
        final comments = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        if (mounted && _commentsNotifiers.containsKey(eventId)) {
          _commentsNotifiers[eventId]?.value = comments;
        }
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(
          event: event,
          isFavorite: true, 
          onFavoriteChanged: (isFavorite) {
            _firestoreService.setFavoriteStatus(eventId, !isFavorite, event);
          },
          commentsNotifier: _commentsNotifiers[eventId]!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var notifier in _commentsNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Watchlist',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF000080),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getWatchlist(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Sua watchlist está vazia.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final events = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index].data() as Map<String, dynamic>;
              // Ensure the unique ID is available for interactions
              final eventId = event['unique_id'] ?? _generateUniqueEventId(event);

              return GestureDetector(
                onTap: () => _goToEventDetail(context, event),
                child: Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['event_type'] ?? 'Tipo de evento não disponível',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF000080),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Data: ${event['event_date'] ?? 'Data não disponível'}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestoreService.getComments(eventId),
                          builder: (context, commentSnapshot) {
                            if (commentSnapshot.hasData && commentSnapshot.data!.docs.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.comment, size: 16, color: Colors.grey[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${commentSnapshot.data!.docs.length} comentário(s)',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
