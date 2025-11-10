// lib/screens/meus_eventos_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ec_mobile/providers/user_provider.dart'; // Para pegar o ID do aluno
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:ec_mobile/screens/inscricao_evento_screen.dart'; // Para navegar para os detalhes
import 'package:ec_mobile/widgets/custom_app_bar.dart'; // Novo import

class MeusEventosScreen extends StatefulWidget {
  const MeusEventosScreen({super.key});

  @override
  State<MeusEventosScreen> createState() => _MeusEventosScreenState();
}

class _MeusEventosScreenState extends State<MeusEventosScreen> {
  List<dynamic> _myEvents = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMyEvents();
  }

  Future<void> _fetchMyEvents() async {
    // 1. Pega o usuário logado do Provider
    final user = Provider.of<UserProvider>(context, listen: false).user;

    if (user == null) {
      setState(() {
        _errorMessage = "Você precisa estar logado para ver seus eventos.";
        _isLoading = false;
      });
      return;
    }

    // 2. Pega o ID do aluno logado
    final int alunoId = user.id;

    // 3. Chama a NOVA API com o ID do aluno
    final url = Uri.parse('http://192.168.15.174/EC_back/api/get_meus_eventos.php?id_aluno=$alunoId');
    // (Lembre-se das URLs de Emulador/Celular Físico)

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _myEvents = data;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
         // Se a API retornou "Nenhum evento encontrado"
         setState(() {
          _myEvents = []; // Garante que a lista está vazia
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Falha ao carregar seus eventos (Erro ${response.statusCode})';
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

  // Função auxiliar para formatar a data
  String _formatApiDate(String apiDate) {
    try {
      final DateTime parsedDate = DateTime.parse(apiDate);
      return DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(parsedDate);
    } catch (e) {
      return apiDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Eventos Inscritos'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _myEvents.isEmpty // Verifica se a lista está vazia
                  ? const Center(
                      child: Text(
                        'Você ainda não se inscreveu em nenhum evento.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                      ),
                    )
                  // USA O MESMO ESTILO DE LISTA DA TELA 'PROXIMOS EVENTOS'
                  : ListView.builder( 
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _myEvents.length,
                      itemBuilder: (context, index) {
                        final event = _myEvents[index];
                        final int? eventId = event['id'];
                        
                        // Não há mais botão "Inscrever-se",
                        // talvez um botão "Ver Detalhes" ou "Cancelar Inscrição"?
                        // Por enquanto, faremos o card inteiro ser clicável para ver os detalhes.

                        return InkWell(
                          onTap: eventId == null ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InscricaoEventoScreen(eventId: eventId),
                              ),
                            );
                          },
                          child: Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 12.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // Usamos um ListTile simples aqui, mas você pode usar
                            // o ExpansionTile se preferir
                            child: ListTile(
                               contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                               title: Text(
                                event['titulo'] ?? 'Evento sem título',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _formatApiDate(event['data_evento'] ?? ''),
                                  style: const TextStyle(color: AppColors.secondaryText),
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.secondaryText),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}