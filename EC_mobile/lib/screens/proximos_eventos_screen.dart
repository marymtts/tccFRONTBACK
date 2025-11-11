import 'package:ec_mobile/widgets/custom_app_bar.dart'; // Novo import
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ec_mobile/screens/inscricao_evento_screen.dart';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:ec_mobile/providers/user_provider.dart';
import 'package:ec_mobile/screens/editar_evento_screen.dart'; 

class ProximosEventosScreen extends StatefulWidget {
  const ProximosEventosScreen({super.key});

  @override
  State<ProximosEventosScreen> createState() => _ProximosEventosScreenState();
}

class _ProximosEventosScreenState extends State<ProximosEventosScreen> {
  List<dynamic> _upcomingEvents = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // --- MUDANÇA: Defina a URL do seu servidor aqui ---
  // (Lembre-se: 10.0.2.2 para emulador, 192.168... para celular físico)
  final String _serverUrl = 'https://tccfrontback.onrender.com'; 
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchUpcomingEvents();
  }

  Future<void> _fetchUpcomingEvents() async {
    final url = Uri.parse('$_serverUrl/api/get_proximos_eventos.php');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _upcomingEvents = data;
          _isLoading = false;
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

  String _formatApiDate(String apiDate) {
    try {
      final DateTime parsedDate = DateTime.parse(apiDate);
      // Mudei o formato para ficar mais limpo no card
      return DateFormat('dd MMM yyyy', 'pt_BR').format(parsedDate).toUpperCase();
    } catch (e) {
      return apiDate;
    }
  }

  // --- NOVA FUNÇÃO: Placeholder (AGORA USANDO A IMAGEM PADRÃO) ---
Widget _buildImagePlaceholder() {
  return Image.asset(
    'assets/images/ec-eventos.png', // <-- O caminho para sua imagem padrão
    height: 180,
    width: double.infinity,
    fit: BoxFit.cover, // Garante que a imagem cubra o espaço do card
  );
}
  // -------------------------------------------------------------

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
              : _upcomingEvents.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum evento futuro encontrado.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _upcomingEvents.length,
                      // --- MUDANÇA COMPLETA NO ITEMBUILDER ---
                      itemBuilder: (context, index) {
                        final event = _upcomingEvents[index];
                        final int? eventId = event['id'];
                        final String? imageUrl = event['imagem_url'];
                        final String? fullImageUrl = imageUrl != null ? '$_serverUrl$imageUrl' : null;

                        // Este Card substitui o ExpansionTile
                        return Card(
                          clipBehavior: Clip.antiAlias, // Corta a imagem para ter borda arredondada
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 20.0), // Espaçamento maior
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              
                              // --- 1. A IMAGEM ---
                              (fullImageUrl != null)
                                ? Image.network(
                                    fullImageUrl,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    // Placeholder enquanto carrega
                                    loadingBuilder: (context, child, progress) {
                                      return progress == null
                                          ? child
                                          : Container(
                                              height: 180,
                                              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                                            );
                                    },
                                    // O que mostrar se a imagem falhar (link quebrado)
                                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                                  )
                                : _buildImagePlaceholder(), // Placeholder se a imagem for nula

                              // --- 2. O CONTEÚDO DE TEXTO ---
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Data (com sua cor de destaque)
                                    Text(
                                      _formatApiDate(event['data_evento'] ?? ''),
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accent), // Usei seu ACCENT
                                    ),
                                    const SizedBox(height: 10),
                                    // Título
                                    Text(
                                      event['titulo'] ?? 'Evento sem título',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryText),
                                    ),
                                    const SizedBox(height: 10),
                                    // Descrição (limitada a 3 linhas)
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
                              
                              // --- 3. OS BOTÕES ---
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column( // Usei Column para os botões ficarem um sobre o outro
                                  children: [
                                    // Botão "Editar" (Só para Admins)
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
                                            );
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
                                    
                                    if (isAdmin) const SizedBox(height: 8), // Espaçador
                                    
                                    // Botão "Saiba mais" (Para Todos)
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
    );
  }
}