import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/features/auth/controller/auth_controller.dart';
import 'package:myapp/features/auth/view/auth_screen.dart';
import 'package:myapp/features/event_detail/view/event_detail_screen.dart';
import 'package:myapp/features/home/widgets/event_card.dart';
import 'package:myapp/features/watchlist/view/watchlist_screen.dart';
import 'package:myapp/services/acled_api_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:crypto/crypto.dart';
import '../../map/view/map_screen.dart'; // Importe a tela do mapa
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AcledApiService _apiService = AcledApiService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = false;
  List<dynamic> _searchResults = [];
  String? _currentSearchTerm;
  final Map<String, bool> _favoriteStatus = {};
  final Map<String, ValueNotifier<List<Map<String, dynamic>>>> _commentsNotifiers = {};

  String _generateUniqueEventId(Map<String, dynamic> event) {
    final dataId = event['data_id']?.toString() ?? '';
    final eventDate = event['event_date']?.toString() ?? '';
    final notes = event['notes']?.toString() ?? '';
    final combined = '$dataId-$eventDate-$notes';
    return sha1.convert(utf8.encode(combined)).toString();
  }

  void _signOut(BuildContext context) async {
    final authController = AuthController();
    await authController.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _searchEvents() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um país ou palavra-chave para pesquisar.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _favoriteStatus.clear();
      for (var notifier in _commentsNotifiers.values) {
        notifier.dispose();
      }
      _commentsNotifiers.clear();
      _currentSearchTerm = query[0].toUpperCase() + query.substring(1).toLowerCase();
    });

    try {
      final events = await _apiService.getEvents(query: query);
      if (!mounted) return;

      for (var event in events) {
        event['unique_id'] = _generateUniqueEventId(event);
      }
      
      await _loadFavoriteStatus(events);
      _initializeCommentsNotifiers(events);

      setState(() {
        _searchResults = events;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar eventos: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFavoriteStatus(List<dynamic> events) async {
    for (var event in events) {
      final eventId = event['unique_id'];
      final isFavorite = await _firestoreService.isFavorite(eventId);
      if (mounted) {
        setState(() {
          _favoriteStatus[eventId] = isFavorite;
        });
      }
    }
  }

  void _initializeCommentsNotifiers(List<dynamic> events) {
    for (var event in events) {
      final eventId = event['unique_id'];
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
  }

  void _toggleFavorite(String eventId, bool isFavorite) {
    final event = _searchResults.firstWhere((e) => e['unique_id'] == eventId);
    _firestoreService.setFavoriteStatus(eventId, !isFavorite, event);
    if (mounted) {
      setState(() {
        _favoriteStatus[eventId] = !isFavorite;
      });
    }
  }

  void _goToWatchlist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WatchlistScreen()),
    );
  }
  
  void _goToEventDetail(Map<String, dynamic> event) {
    final eventId = event['unique_id'];
    final isFavorite = _favoriteStatus[eventId] ?? false;
    final commentsNotifier = _commentsNotifiers[eventId]!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(
          event: event,
          isFavorite: isFavorite,
          onFavoriteChanged: (isFav) => _toggleFavorite(eventId, isFav),
          commentsNotifier: commentsNotifier,
        ),
      ),
    );
  }

  void _showEventsOnMap() {
    if (_searchResults.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Realize uma busca primeiro para visualizar eventos no mapa.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
       return;
    }
     Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen(eventos: _searchResults)), // Passa a lista de eventos
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var notifier in _commentsNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Usuário';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trends Conflicts World',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF000080),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _signOut(context),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo(a), $displayName!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Encontre eventos de conflitos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Digite o nome do país ou palavra-chave',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide:
                            const BorderSide(color: Color(0xFF000080), width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _searchEvents(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Pesquisar Eventos',
                          style: TextStyle(fontSize: 18)),
                      onPressed: _searchEvents,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF000080),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                   SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map), // Ícone de mapa
                      label: const Text('Mostrar Eventos no Mapa',
                          style: TextStyle(fontSize: 18)),
                      onPressed: _showEventsOnMap, // Chama a nova função
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF000080), // Mesma cor do botão de busca
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.star),
                      label: const Text('Minha Watchlist',
                          style: TextStyle(fontSize: 18)),
                      onPressed: _goToWatchlist,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF242444),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                  if (_currentSearchTerm != null) ...[
                     const SizedBox(height: 24),
                     Text(
                      'Resultados para: $_currentSearchTerm',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                     ),
                     const Divider(),
                  ]
                ],
              ),
            ),
          ),
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _searchResults.isEmpty && _currentSearchTerm != null
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Nenhum evento encontrado para "$_currentSearchTerm".'),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = _searchResults[index];
                          final eventId = event['unique_id'];
                          final isFavorite = _favoriteStatus[eventId] ?? false;
                          
                          return Padding(
                             key: ValueKey(eventId),
                             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                             child: EventCard(
                              event: event,
                              isFavorite: isFavorite,
                              onFavoriteChanged: (isFav) => _toggleFavorite(eventId, isFav),
                              onTap: () => _goToEventDetail(event),
                            ),
                          );
                        },
                        childCount: _searchResults.length,
                      ),
                    ),
        ],
      ),
    );
  }
}
