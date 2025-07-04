import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:myapp/services/acled_api_service.dart'; // Importar o serviço da API

class MapScreen extends StatefulWidget {
 final List<dynamic> eventos; // Lista de eventos a ser exibida (pode estar vazia)

 const MapScreen({super.key, required this.eventos});

 @override
 _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
 final Set<Marker> _markers = {}; // Conjunto de marcadores
 bool _isLoading = true; // Estado para indicar carregamento
 List<dynamic> _eventsToDisplay = []; // Lista de eventos a serem exibidos no mapa

 final AcledApiService _apiService = AcledApiService(); // Instância do serviço da API

  final LatLng _center = const LatLng(0, 0); // Posição inicial do mapa

 @override
 void initState() {
    super.initState();
    if (widget.eventos.isEmpty) {
      // Se a lista de eventos recebida estiver vazia, busca todos os eventos
      _fetchAllEvents();
    } else {
      // Caso contrário, usa a lista de eventos recebida
      _eventsToDisplay = widget.eventos;
      _isLoading = false; // Não está carregando se já recebeu os eventos
    }
  }

 void _onMapCreated(GoogleMapController controller) {
 mapController = controller;
    // Adiciona os marcadores somente após o mapa ser criado e os eventos carregados
    if (!_isLoading) {
      _addEventMarkers(_eventsToDisplay);
    }
  }

  void _addEventMarkers(List<dynamic> events) {
    _markers.clear();

    for (var event in events) {
      if (event.containsKey('latitude') && event.containsKey('longitude')) {
        try {
          final double latitude = double.parse(event['latitude'].toString());
          final double longitude = double.parse(event['longitude'].toString());
          final String title = event['event_type'] ?? 'Evento'; // Use o tipo de evento ou um título padrão
          final String snippet = event['notes'] ?? 'Sem descrição.'; // Use as notas ou uma descrição padrão

          final marker = Marker(
            markerId: MarkerId(event['unique_id'].toString()), // Use um ID único para o marcador
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(
              title: title,
              snippet: snippet,
            ),
          );

          _markers.add(marker);
        } catch (e) {
          print('Erro ao processar as coordenadas do evento: ${event['unique_id']} - $e');
        }
      }
    }

    setState(() {});
  }

  void _fetchAllEvents() async {
    try {
      setState(() {
        _isLoading = true; // Começa o carregamento
      });
      // Passing an empty string as query, assuming the API might return all events
      // if the query parameter is empty or not provided. Adjust if your API requires a different approach.
      final allEvents = await _apiService.getEvents(query: '');
      if (!mounted) return;

      _eventsToDisplay = allEvents;
      _addEventMarkers(_eventsToDisplay); // Adiciona marcadores dos eventos carregados
    } catch (e) {
      if (!mounted) return;
      print('Erro ao buscar todos os eventos: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar todos os eventos: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Finaliza o carregamento
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
 title: const Text('Eventos no Mapa', style: TextStyle(color: Colors.white)),
 backgroundColor: const Color(0xFF000080),
 foregroundColor: Colors.white, // Adicionada esta linha para mudar a cor dos ícones (incluindo a seta de voltar)
      ),
 body: _isLoading
          ? const Center( // Exibe um indicador enquanto carrega
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 2.0,
              ),
              markers: _markers,
        ),
    );
  }
}