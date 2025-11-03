// lib/screens/inscricao_evento_screen.dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ec_mobile/theme/app_colors.dart'; // Verifique o caminho
import 'package:provider/provider.dart';
import 'package:ec_mobile/providers/user_provider.dart';

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
  final String _imageBaseUrl = 'http://192.168.15.174/EC_back'; // Ajuste se necessário

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  // Busca os detalhes do evento específico na API
  Future<void> _fetchEventDetails() async {
    // URL que busca um evento por ID
    final url = Uri.parse('http://192.168.15.174/EC_back/api/eventos.php?id=${widget.eventId}');
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

  // Dentro da classe _InscricaoEventoScreenState

  // --- Função para registrar a inscrição (VERSÃO COMPLETA) ---
  Future<void> _registerForEvent() async {
    setState(() { _isRegistering = true; _errorMessage = ''; });

    // 1. Pegar o ID do usuário logado (do Provider)
    // 'listen: false' é usado dentro de funções
    final user = Provider.of<UserProvider>(context, listen: false).user;

    // 2. Verificar se o usuário está logado
    if (user == null) {
      _showFeedbackSnackbar('Você precisa estar logado para se inscrever.', isError: true);
      setState(() { _isRegistering = false; });
      // TODO: Opcional - Navegar para a tela de login
      // Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      return; // Para a execução
    }

    // 3. URL da API que acabamos de criar
    final url = Uri.parse('http://192.168.15.174/EC_back/api/registrar_participacao.php');
    // (Lembre-se das URLs de Emulador/Celular Físico)

    try {
      // 4. Enviar os IDs para a API
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({ // Envia os IDs como JSON
          'id_aluno': user.id, // ID do aluno logado!
          'id_evento': widget.eventId, // ID do evento atual
        }),
      );

      // 5. Decodifica a resposta da API
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // 6. Verifica a resposta (Sucesso ou Erro da API)
      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['status'] == 'success') {
          // SUCESSO!
          _showFeedbackSnackbar(responseData['message'] ?? 'Inscrição realizada!', isError: false);
          // TODO: Mudar o botão para "Inscrito"
      } else {
          // ERRO (ex: "Já inscrito", "Vagas esgotadas", etc.)
          _showFeedbackSnackbar(responseData['message'] ?? 'Erro ${response.statusCode}: Não foi possível registrar.', isError: true);
      }
    } catch (e) {
      // 7. Erro de Conexão (XAMPP desligado, etc.)
      print('Erro ao registrar participação: $e');
      _showFeedbackSnackbar('Erro de conexão ao tentar registrar.', isError: true);
    } finally {
      // 8. Para o "loading" do botão
      setState(() { _isRegistering = false; });
    }
  }

  // Função auxiliar para mostrar feedback (Snackbar) - (Verifique se ela já existe)
   void _showFeedbackSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Função auxiliar para mostrar feedback (Snackbar)

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
              ? Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center)))
              : _eventDetails == null
                  ? const Center(child: Text('Não foi possível carregar os detalhes.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Título ---
                          Text(
                            _eventDetails!['titulo'] ?? 'Evento sem título',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryText),
                          ),
                          const SizedBox(height: 16),

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
                          const SizedBox(height: 30),

                          // --- Imagem ou Placeholder ---
                Container(
                    width: double.infinity,
                    height: 320, // Altura fixa para a imagem
                    decoration: BoxDecoration(
                      color: AppColors.surface, // Cor de fundo caso a imagem falhe
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect( // Para forçar as bordas arredondadas na imagem
                      borderRadius: BorderRadius.circular(8),
                      child: fullImageUrl != null
                        ? Image.network( // 1. Tenta carregar a imagem da API
                            fullImageUrl,
                            fit: BoxFit.cover, // Cobre todo o espaço do container
                            // Mostra um "Carregando..." enquanto a imagem da rede baixa
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child; // Imagem carregada
                              return const Center(child: CircularProgressIndicator());
                            },
                            // Se a imagem da API falhar (ex: 404), mostra a imagem padrão
                            errorBuilder: (context, error, stackTrace) {
                              print("Erro ao carregar imagem da rede: $error. Usando imagem padrão.");
                              return Image.asset(
                                'assets/images/tcc-stock.png',fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/tcc-stock.png',
                            fit: BoxFit.cover, // Cobre todo o espaço
                          ),
                    ),
                  ),
                          const SizedBox(height: 30),

                          // --- Divisor ---
                          const Divider(color: AppColors.secondaryText, thickness: 0.5),
                          const SizedBox(height: 25),

                          // --- Descrição ---
                          Text(
                            _eventDetails!['descricao'] ?? 'Descrição não disponível.',
                            style: const TextStyle(fontSize: 16, height: 1.6, color: AppColors.primaryText), // Mudado para primaryText
                          ),
                          const SizedBox(height: 60),

                          // --- Botão de Inscrição ---
                          if (permiteInscricao)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isRegistering ? null : _registerForEvent, // Chama a função de registro
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent, // Sua cor vermelha
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
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