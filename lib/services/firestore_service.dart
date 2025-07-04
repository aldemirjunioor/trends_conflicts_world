import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _eventsCollection =>
      _db.collection('users').doc(_userId).collection('tracked_events');

  Future<bool> isFavorite(String eventId) async {
    if (_userId == null) return false;
    final doc = await _eventsCollection.doc(eventId).get();
    if (!doc.exists) return false;
    return (doc.data() as Map<String, dynamic>)['is_favorite'] ?? false;
  }

  // This method now correctly handles both creating and updating.
  Future<void> setFavoriteStatus(String eventId, bool isFavorite, Map<String, dynamic> eventData) async {
    if (_userId == null) return;
    
    final docRef = _eventsCollection.doc(eventId);
    final doc = await docRef.get();

    if (!doc.exists) {
      // If the document is brand new, set it with the favorite status.
      await docRef.set({
        ...eventData,
        'is_favorite': isFavorite, // Set the initial favorite status
      });
    } else {
      // If it exists, just update the favorite status field.
      await docRef.update({'is_favorite': isFavorite});
    }
  }

  Stream<DocumentSnapshot> getEventData(String eventId) {
    if (_userId == null) return const Stream.empty();
    return _eventsCollection.doc(eventId).snapshots();
  }
  
  Stream<QuerySnapshot> getWatchlist() {
    if (_userId == null) return const Stream.empty();
    return _eventsCollection.where('is_favorite', isEqualTo: true).snapshots();
  }
  
  Future<void> addComment(String eventId, String commentText, Map<String, dynamic> eventData) async {
    if (_userId == null || commentText.trim().isEmpty) return;
    
    final docRef = _eventsCollection.doc(eventId);
    final doc = await docRef.get();

    // If the event document doesn't exist, create it but ensure is_favorite is false.
    if (!doc.exists) {
       await docRef.set({
        ...eventData,
        'is_favorite': false, // Default to not favorite when adding a comment first
      });
    }

    await docRef.collection('comments').add({
      'text': commentText.trim(),
      'author': _auth.currentUser?.displayName ?? 'Usuário Anônimo',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  Stream<QuerySnapshot> getComments(String eventId) {
     if (_userId == null) return const Stream.empty();
     return _eventsCollection.doc(eventId).collection('comments').orderBy('timestamp', descending: true).snapshots();
  }
  
  Future<void> deleteComment(String eventId, String commentId) async {
    if (_userId == null) return;
    await _eventsCollection.doc(eventId).collection('comments').doc(commentId).delete();
  }
}
