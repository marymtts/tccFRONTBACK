// lib/screens/admin_controle_selecionar_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:ec_mobile/screens/admin_ver_inscritos_screen.dart'; 
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Import para o estilo da busca

// (O modelo de Evento continua o mesmo)
class Evento {
  final int id;
  final String titulo;
  final DateTime dataEvento;

  Evento({required this.id, required this.titulo, required this.dataEvento});

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: int.parse(json['id'].toString()),
      titulo: json['titulo'],
      dataEvento: DateTime.parse(json['data_evento']),
    );
  }
}

class AdminControleSelecionarScreen extends StatefulWidget {
  const AdminControleSelecionarScreen({super.key});

  @override
  State<AdminControleSelecionarScreen> createState() => _AdminControleSelecionarScreenState();
}

class _AdminControleSelecionarScreenState extends State<AdminControleSelecionarScreen> {
  late Future<List<Evento>> _futureEventos;

  // --- 1. NOVAS VARIÁVEIS DE ESTADO PARA A BUSCA ---
  final TextEditingController _searchController = TextEditingController();
  List<Evento> _allEvents = []; // Guarda TODOS os eventos vindos da API
  List<Evento> _filteredEvents = []; // Guarda os eventos que batem com a busca
  // ------------------------------------------------

  @override
  void initState() {
    super.initState();
    _futureEventos = _fetchEventos();
    
    // --- 2. ADICIONA O "OUVINTE" DA BUSCA ---
    // (Chama a função _filterEvents toda vez que o admin digita)
    _searchController.addListener(_filterEvents);
    // -----------------------------------------
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterEvents); // Limpa o ouvinte
    _searchController.dispose(); // Limpa o controller
    super.dispose();
  }

  // --- 3. ATUALIZA A FUNÇÃO DE BUSCAR EVENTOS ---
  Future<List<Evento>> _fetchEventos() async {
    // (Sua URL do Render)
    final response = await http.get(
      Uri.parse('https://tccfrontback.onrender.com/api/get_proximos_eventos.php')
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      List<Evento> events = jsonList.map((json) => Evento.fromJson(json)).toList();

      // --- POPULA AS NOVAS LISTAS ---
      setState(() {
        _allEvents = events;
        _filteredEvents = events; // No início, a lista filtrada é a lista completa
      });
      // -----------------------------
      
      return events; // O FutureBuilder ainda precisa disso
    } else {
      throw Exception('Falha ao carregar eventos da API');
    }
  }
  // --- FIM DA MUDANÇA 3 ---

  // --- 4. ADICIONA A FUNÇÃO DE FILTRAGEM ---
  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        final titleLower = event.titulo.toLowerCase();
        return titleLower.contains(query);
      }).toList();
    });
  }
  // --- FIM DA MUDANÇA 4 ---

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy \'às\' HH:mm', 'pt_BR').format(data);
  }

  // --- 5. ATUALIZA O MÉTODO BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Evento (Controle)'),
        backgroundColor: AppColors.surface,
      ),
      // O body agora é uma Column para ter a busca + a lista
      body: Column(
        children: [
          
          // --- A BARRA DE BUSCA ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                hintText: 'Buscar pelo nome do evento...',
                hintStyle: TextStyle(color: AppColors.secondaryText),
                prefixIcon: Icon(Icons.search, color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ),
          
          // --- A LISTA DE EVENTOS (com FutureBuilder) ---
          Expanded( // Faz a lista ocupar o resto da tela
            child: FutureBuilder<List<Evento>>(
              future: _futureEventos,
              builder: (context, snapshot) {
                // Enquanto carrega, mostra o spinner
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                // Se deu erro na API
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar eventos: ${snapshot.error}'));
                }
                
                // Se a API retornou, mas a busca não achou nada
                if (_filteredEvents.isEmpty && _allEvents.isNotEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum evento encontrado com "${_searchController.text}".',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  );
                }

                // Se não há eventos de forma alguma
                if (_allEvents.isEmpty) {
                  return Center(child: Text('Nenhum evento encontrado.'));
                }

                // Se deu tudo certo, mostra a LISTA FILTRADA
                return ListView.builder(
                  itemCount: _filteredEvents.length, // <-- MUDOU
                  itemBuilder: (context, index) {
                    final evento = _filteredEvents[index]; // <-- MUDOU
                    return ListTile(
                      title: Text(evento.titulo, style: TextStyle(color: AppColors.primaryText)),
                      subtitle: Text(_formatarData(evento.dataEvento), style: TextStyle(color: AppColors.secondaryText)),
                      leading: Icon(Icons.event_note, color: AppColors.accent),
                      trailing: Icon(Icons.arrow_forward_ios, color: AppColors.secondaryText),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminVerInscritosScreen(
                              eventoId: evento.id,
                              eventoTitulo: evento.titulo,
                              
                            ),
                            
                          ),
                          
                        );
                        
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  // --- FIM DA MUDANÇA 5 ---
}