import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:myapp/features/map/view/map_screen.dart'; // Importe a tela do mapa

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;
  final ValueNotifier<List<Map<String, dynamic>>> commentsNotifier;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.commentsNotifier,
  });

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late bool _isFavorite;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  String _generateUniqueEventId(Map<String, dynamic> event) {
    final dataId = event['data_id']?.toString() ?? '';
    final eventDate = event['event_date']?.toString() ?? '';
    final notes = event['notes']?.toString() ?? '';
    final combined = '$dataId-$eventDate-$notes';
    return sha1.convert(utf8.encode(combined)).toString();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Data indisponível';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  void _addComment(BuildContext context, String eventId) {
    if (_commentController.text.trim().isNotEmpty) {
      _firestoreService.addComment(
          eventId, _commentController.text, widget.event);
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onFavoriteChanged(_isFavorite);
  }

  void _showEventOnMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(eventos: [widget.event]), // Passa uma lista com apenas o evento atual
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventId = widget.event['unique_id'] ?? _generateUniqueEventId(widget.event);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Evento',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white, // Adicionada esta linha para forçar a cor branca dos ícones
        backgroundColor: const Color(0xFF000080),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border, // Mantém a cor da estrela âmbar
              color: _isFavorite ? Colors.amber : Colors.white, // Define a cor da estrela não favoritada como branca
              size: 30,
            ),
            tooltip: _isFavorite
                ? 'Remover dos Favoritos'
                : 'Adicionar aos Favoritos',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event['event_type'] ?? 'Tipo de evento não disponível',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Data: ${widget.event['event_date'] ?? 'Data indisponível'}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'País: ${widget.event['country'] ?? 'País não disponível'}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Fonte: ${widget.event['source'] ?? 'Fonte não disponível'}',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const Divider(height: 32),
            Text(
              'Descrição do Conflito:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.event['notes'] ?? 'Sem descrição.',
              style: const TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
             const SizedBox(height: 20), // Espaço entre a descrição e o botão
             SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map), // Ícone de mapa
                label: const Text('Ver no Mapa',
                    style: TextStyle(fontSize: 18)),
                onPressed: _showEventOnMap, // Chama a nova função
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF000080), // Cor do botão
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            const Divider(height: 32),
            Text(
              'Comentários',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Adicionar um comentário...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF000080)),
                  onPressed: () => _addComment(context, eventId),
                  tooltip: 'Salvar Comentário',
                ),
              ],
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: widget.commentsNotifier,
              builder: (context, comments, child) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Nenhum comentário adicionado ainda.'),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final commentId = comment['id'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        title: Text(comment['text'] ?? 'Comentário vazio'),
                        subtitle: Text(
                          'Por: ${comment['author'] ?? 'Anônimo'} em ${_formatTimestamp(comment['timestamp'] as Timestamp?)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _firestoreService.deleteComment(
                              eventId, commentId),
                          tooltip: 'Excluir Comentário',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
