// lib/screens/inscricao_evento_screen.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ec_mobile/theme/app_colors.dart'; // Verifique o caminho

class InscricaoEventoScreen extends StatefulWidget {
  final int eventId; // Recebe o ID do evento

  const InscricaoEventoScreen({super.key, required this.eventId});

  @override
  State<InscricaoEventoScreen> createState() => _InscricaoEventoScreenState();
}

class _InscricaoEventoScreenState extends State<InscricaoEventoScreen> {
  Map<String, dynamic>? _eventDetails; // Guarda os detalhes do evento (Map em vez de List)
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isRegistering = false; // Estado de loading para o botão de inscrição

  // !!! SIMULAÇÃO DO ALUNO LOGADO !!!
  final int _studentId = 123; // Exemplo - Pegue o ID real no futuro

  // URL base para construir o caminho completo das imagens
  final String _imageBaseUrl = 'http://localhost/EC_back'; // Ajuste se necessário

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  // Busca os detalhes do evento específico na API
  Future<void> _fetchEventDetails() async {
    // URL que busca um evento por ID
    final url = Uri.parse('http://localhost/EC_back/api/eventos.php?id=${widget.eventId}');
    // (Lembre-se das URLs de Emulador/Celular Físico)

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final decodedBody = jsonDecode(response.body);
          // Verifica se a API retornou um objeto (Map) e não uma lista
          if (decodedBody is Map<String, dynamic>) {
            setState(() {
              _eventDetails = decodedBody;
              _isLoading = false;
            });
          } else {
            // Se a API retornou uma lista [ ] ou outro formato inesperado
            print('API retornou um formato inesperado: $decodedBody');
            setState(() {
              _errorMessage = 'Evento não encontrado ou formato de resposta inválido.';
              _isLoading = false;
            });
          }
        } else {
           setState(() {
            _errorMessage = 'Evento não encontrado (resposta vazia).';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
         setState(() {
          _errorMessage = 'Evento não encontrado (Erro 404).';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Falha ao carregar detalhes (Erro HTTP ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao buscar detalhes do evento: $e');
      setState(() {
        _errorMessage = 'Erro de conexão ao buscar detalhes.';
        _isLoading = false;
      });
    }
  }

  // --- Função para registrar a inscrição (CHAMARÁ A NOVA API) ---
  Future<void> _registerForEvent() async {
    setState(() { _isRegistering = true; _errorMessage = ''; });

    // URL do NOVO endpoint PHP para registrar participação
    final url = Uri.parse('http://localhost/EC_back/api/registrar_participacao.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_aluno': _studentId, // ID do aluno (simulado)
          'id_evento': widget.eventId, // ID do evento atual
        }),
      );

      // Sempre tente decodificar, mesmo em caso de erro, pois a API pode mandar uma mensagem
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['status'] == 'success') {
          _showFeedbackSnackbar(responseData['message'] ?? 'Inscrição realizada!', isError: false);
          // 
          // setState(() { _jaInscrito = true; }); // Exemplo
      } else {
          // Usa a mensagem de erro da API ou uma padrão
          _showFeedbackSnackbar(responseData['message'] ?? 'Erro ${response.statusCode}: Não foi possível registrar.', isError: true);
      }
    } catch (e) {
      print('Erro ao registrar participação: $e');
      _showFeedbackSnackbar('Erro de conexão ao tentar registrar.', isError: true);
    } finally {
      setState(() { _isRegistering = false; });
    }
  }

  // Função auxiliar para mostrar feedback (Snackbar)
   void _showFeedbackSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Função auxiliar para formatar a data
  String _formatApiDate(String? apiDate) {
     if (apiDate == null) return 'Data indisponível';
    try {
      final DateTime parsedDate = DateTime.parse(apiDate);
      return DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(parsedDate);
    } catch (e) {
      return apiDate;
    }
  }

  // --- Construção da Interface ---
  @override
  Widget build(BuildContext context) {
    // Define a URL da imagem (ou null se não houver)
    String? imageUrlPath = _eventDetails?['imagem_url'];
    String? fullImageUrl = (imageUrlPath != null && imageUrlPath.isNotEmpty)
                         ? _imageBaseUrl + imageUrlPath // Constrói a URL completa
                         : null;

    bool permiteInscricao = (_eventDetails?['inscricao'] ?? 0) == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_eventDetails?['titulo'] ?? 'Inscrição'), // Título dinâmico
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center)))
              : _eventDetails == null
                  ? const Center(child: Text('Não foi possível carregar os detalhes.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Título ---
                          Text(
                            _eventDetails!['titulo'] ?? 'Evento sem título',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryText),
                          ),
                          const SizedBox(height: 15),

                          // --- Data ---
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.secondaryText),
                              const SizedBox(width: 8),
                              Text(
                                _formatApiDate(_eventDetails!['data_evento']),
                                style: const TextStyle(fontSize: 16, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          // --- Imagem ou Placeholder ---
                          Container(
                            width: double.infinity,
                            height: 200, // Altura fixa para a imagem/placeholder
                            decoration: BoxDecoration(
                              color: AppColors.surface, // Cor de fundo para o placeholder
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect( // Para arredondar a imagem
                              borderRadius: BorderRadius.circular(8),
                              child: fullImageUrl != null
                                ? Image.network( // Carrega a imagem da API
                                    fullImageUrl,
                                    fit: BoxFit.cover, // Cobre o espaço disponível
                                    // Mostra um loading enquanto a imagem carrega
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    // Mostra um ícone de erro se a imagem falhar
                                    errorBuilder: (context, error, stackTrace) {
                                      print("Erro ao carregar imagem: $error");
                                      return const Center(child: Icon(Icons.broken_image, color: AppColors.secondaryText, size: 50));
                                    },
                                  )
                                : const Center( // Placeholder se não houver imagem
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'Anexo de uma foto opcional, ou então a foto automática que iremos ver ainda',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppColors.secondaryText),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // --- Divisor ---
                          const Divider(color: AppColors.secondaryText, thickness: 0.5),
                          const SizedBox(height: 25),

                          // --- Descrição ---
                          Text(
                            _eventDetails!['descricao'] ?? 'Descrição não disponível.',
                            style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.primaryText), // Mudado para primaryText
                          ),
                          const SizedBox(height: 40),

                          // --- Botão de Inscrição ---
                          if (permiteInscricao)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isRegistering ? null : _registerForEvent, // Chama a função de registro
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent, // Sua cor vermelha
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isRegistering // Mostra loading ou texto
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Inscrever-se', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          if (!permiteInscricao) // Mensagem se não houver inscrição
                            const Center(
                              child: Text(
                                'Este evento não requer inscrição.',
                                style: TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic, fontSize: 16),
                              ),
                            ),
                          const SizedBox(height: 20), // Espaço extra no final
                        ],
                      ),
                    ),
    );
  }
}