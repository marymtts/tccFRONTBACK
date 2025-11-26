// lib/screens/proximos_eventos_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ec_mobile/screens/inscricao_evento_screen.dart';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:ec_mobile/providers/user_provider.dart';
import 'package:ec_mobile/screens/editar_evento_screen.dart';
import 'package:flutter/foundation.dart'; // Para Uint8List

class ProximosEventosScreen extends StatefulWidget {
  const ProximosEventosScreen({super.key});

  @override
  State<ProximosEventosScreen> createState() => _ProximosEventosScreenState();
}

class _ProximosEventosScreenState extends State<ProximosEventosScreen> {
  // --- 1. MUDANÇA: URL do Servidor (use seu IP) ---
  final String _serverUrl = 'https://tccfrontback.onrender.com'; 

  // --- 2. NOVAS VARIÁVEIS DE ESTADO PARA A BUSCA ---
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allEvents = []; // Guarda TODOS os eventos vindos da API
  List<dynamic> _filteredEvents = []; // Guarda os eventos que batem com a busca
  // ------------------------------------------------

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUpcomingEvents(); // Isso continua igual

    // --- 3. ADICIONA O "OUVINTE" DA BUSCA ---
    _searchController.addListener(_filterEvents);
    // -----------------------------------------
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterEvents); // Limpa o ouvinte
    _searchController.dispose(); // Limpa o controller
    super.dispose();
  }

  // --- 4. ATUALIZA A FUNÇÃO DE BUSCAR EVENTOS ---
  Future<void> _fetchUpcomingEvents() async {
    final url = Uri.parse('$_serverUrl/api/get_proximos_eventos.php');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          // --- POPULA AS NOVAS LISTAS ---
          _allEvents = data;
          _filteredEvents = data; // No início, a lista filtrada é a lista completa
          _isLoading = false;
          // -----------------------------
        });
      } else {
        setState(() {
          _errorMessage = 'Falha ao carregar eventos (Erro ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        _errorMessage = 'Erro de conexão. Verifique o XAMPP e a URL.';
        _isLoading = false;
      });
    }
  }
  // --- FIM DA MUDANÇA 4 ---

  // --- 5. ADICIONA A FUNÇÃO DE FILTRAGEM ---
  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        // Pega o título do evento
        final titleLower = (event['titulo'] as String).toLowerCase();
        // Verifica se o título contém o texto da busca
        return titleLower.contains(query);
      }).toList();
    });
  }
  // --- FIM DA MUDANÇA 5 ---


  String _formatApiDate(String apiDate) {
    try {
      final DateTime parsedDate = DateTime.parse(apiDate);
      return DateFormat('dd MMM yyyy', 'pt_BR').format(parsedDate).toUpperCase();
    } catch (e) {
      return apiDate;
    }
  }

  Widget _buildImagePlaceholder() {
    return Image.asset(
      'assets/images/ec-eventos.png', // <-- Sua imagem padrão
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  // --- 6. ATUALIZA O MÉTODO BUILD ---
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final bool isAdmin = (user?.role == 'admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximos Eventos'),
        backgroundColor: AppColors.surface,
        elevation: 0,
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
          
          // --- A LISTA DE EVENTOS ---
          Expanded( // Faz a lista ocupar o resto da tela
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
                    : _allEvents.isEmpty // Verifica se a lista original está vazia
                        ? const Center(
                            child: Text(
                              'Nenhum evento futuro encontrado.',
                              style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                            ),
                          )
                        // Verifica se a lista FILTRADA está vazia
                        : _filteredEvents.isEmpty 
                            ? Center(
                                child: Text(
                                  'Nenhum evento encontrado com "${_searchController.text}".',
                                  style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                                ),
                              )
                            // Se tudo certo, mostra a lista
                            : ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: _filteredEvents.length, // <-- MUDOU
                                itemBuilder: (context, index) {
                                  final event = _filteredEvents[index]; // <-- MUDOU
                                  final int? eventId = event['id'];
                                  final String? imageUrl = event['imagem_url'];
                                  final String? fullImageUrl = imageUrl != null ? '$_serverUrl$imageUrl' : null;

                                  // O Card (seu código de Card continua igual)
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    color: AppColors.surface,
                                    margin: const EdgeInsets.only(bottom: 20.0),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        
                                        Builder(
                                      builder: (context) {
                                        final String? imageString = event['imagem_url']; // Pega o valor do banco

                                        // 1. Se for nulo ou vazio, mostra placeholder
                                        if (imageString == null || imageString.isEmpty) {
                                          return _buildImagePlaceholder(); 
                                        }

                                        // 2. Se for URL antiga (começa com http ou /uploads) - Mantém compatibilidade
                                        if (imageString.startsWith('http') || imageString.startsWith('/')) {
                                          final url = imageString.startsWith('/') 
                                              ? '$_serverUrl$imageString' // Adiciona seu dominio se começar com /
                                              : imageString;
                                          return Image.network(
                                            url,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(),
                                          );
                                        }

                                        // 3. Se for Base64 (Novo formato do Render)
                                        try {
                                          // O PHP manda algo como "data:image/png;base64,iVBORw..."
                                          // Precisamos pegar só a parte depois da vírgula
                                          final String base64String = imageString.contains(',') 
                                              ? imageString.split(',').last 
                                              : imageString;
                                          
                                          return Image.memory(
                                            base64Decode(base64String), // Decodifica o texto para imagem
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(),
                                          );
                                        } catch (e) {
                                          return _buildImagePlaceholder();
                                        }
                                      },
                                    ),
                                    // --- FIM DA NOVA LÓGICA DE IMAGEM ---

                                        // O Conteúdo de Texto
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _formatApiDate(event['data_evento'] ?? ''),
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.accent),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                event['titulo'] ?? 'Evento sem título',
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primaryText),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                event['descricao'] ?? 'Descrição indisponível.',
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors.secondaryText,
                                                    height: 1.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Os Botões
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                          child: Column(
                                            children: [
                                              if (isAdmin)
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: OutlinedButton(
                                                    onPressed: eventId == null ? null : () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => EditarEventoScreen(eventId: eventId),
                                                        ),
                                                      ).then((_) {
                                                        // --- O SEGREDO ESTÁ AQUI ---
                                                        // O comando .then() é executado EXATAMENTE quando você volta
                                                        setState(() {
                                                          _isLoading = true; // Mostra o carregando rapidinho
                                                        });
                                                        _fetchUpcomingEvents(); // Busca os dados novos no banco
                                                      });
                                                    },
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: AppColors.secondaryText,
                                                      side: BorderSide(color: AppColors.secondaryText.withOpacity(0.5)),
                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    child: const Text('Editar Evento'),
                                                  ),
                                                ),
                                              
                                              if (isAdmin) const SizedBox(height: 8), 
                                              
                                              SizedBox( 
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: eventId == null ? null : () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => InscricaoEventoScreen(eventId: eventId),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.accent,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Saiba mais',
                                                    style: TextStyle(fontSize: 16),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }
}