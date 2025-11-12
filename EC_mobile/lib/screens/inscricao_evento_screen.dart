// lib/screens/inscricao_evento_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:ec_mobile/providers/user_provider.dart';
import 'package:ec_mobile/screens/login_screen.dart'; // Para o caso do usuário não estar logado
import 'package:shared_preferences/shared_preferences.dart'; // <-- IMPORT NECESSÁRIO

class InscricaoEventoScreen extends StatefulWidget {
  final int eventId;
  const InscricaoEventoScreen({super.key, required this.eventId});

  @override
  State<InscricaoEventoScreen> createState() => _InscricaoEventoScreenState();
}

class _InscricaoEventoScreenState extends State<InscricaoEventoScreen> {
  final String _serverUrl = 'https://tccfrontback.onrender.com'; 

  late Future<Map<String, dynamic>> _futureEventDetails;
  bool _isRegistering = false; 

  // --- 1. ADICIONE ESTAS VARIÁVEIS ---
  bool _estaInscrito = false;
  bool _isCanceling = false;
  // ---------------------------------

  @override
  void initState() {
    super.initState();
    _futureEventDetails = _fetchEventDetails();
  }

  // --- 2. SUBSTITUA ESTA FUNÇÃO ---
  Future<Map<String, dynamic>> _fetchEventDetails() async {
    // Pega o usuário ATUAL (se estiver logado)
    final user = Provider.of<UserProvider>(context, listen: false).user;
    
    // Constrói a URL base
    String urlString = '$_serverUrl/api/eventos.php?id=${widget.eventId}';
    
    // (NOVO!) Se o usuário estiver logado, adiciona ele na URL
    if (user != null) {
      urlString += '&user_id=${user.id}';
    }
    
    final url = Uri.parse(urlString);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // (NOVO!) Atualiza o estado de "inscrito"
        setState(() {
          _estaInscrito = data['usuario_esta_inscrito'] ?? false;
        });
        
        return data;
      } else {
        throw Exception('Falha ao carregar dados do evento');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
  // --- FIM DA MUDANÇA 2 ---

  // (Função _realizarInscricao - modificada para atualizar o estado)
  Future<void> _realizarInscricao() async {
    setState(() { _isRegistering = true; });

    final user = Provider.of<UserProvider>(context, listen: false).user;

    if (user == null) {
      _showFeedbackSnackbar('Você precisa estar logado para se inscrever.', isError: true);
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      setState(() { _isRegistering = false; });
      return;
    }
    
    if (user.role != 'aluno') {
      _showFeedbackSnackbar('Apenas alunos podem se inscrever em eventos.', isError: true);
      setState(() { _isRegistering = false; });
      return;
    }

    try {
      final url = Uri.parse('$_serverUrl/api/registrar_participacao.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_aluno': user.id.toString(), 
          'id_evento': widget.eventId.toString(),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) { 
        _showFeedbackSnackbar(responseData['message'] ?? 'Inscrição realizada com sucesso!', isError: false);
        
        // --- ATUALIZA O ESTADO DA TELA ---
        setState(() {
          _estaInscrito = true;
        });
        _futureEventDetails = _fetchEventDetails(); // Recarrega os dados (contagem, etc)
        // ---------------------------------

      } else {
        _showFeedbackSnackbar(responseData['message'] ?? 'Erro ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showFeedbackSnackbar('Erro de conexão ao tentar se inscrever.', isError: true);
    } finally {
      if (mounted) {
        setState(() { _isRegistering = false; });
      }
    }
  }

  // --- 3. ADICIONE A FUNÇÃO DE CANCELAR ---
  Future<void> _cancelarInscricao() async {
    setState(() { _isCanceling = true; });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      _showFeedbackSnackbar('Erro: Token não encontrado.', isError: true);
      setState(() { _isCanceling = false; });
      return;
    }

    try {
      final url = Uri.parse('$_serverUrl/api/cancelar_participacao.php');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id_evento': widget.eventId.toString(),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _showFeedbackSnackbar(responseData['message'] ?? 'Inscrição cancelada!', isError: false);
        // Atualiza o estado da tela
        setState(() {
          _estaInscrito = false;
        });
        // Recarrega os detalhes (para atualizar a contagem de vagas)
        _futureEventDetails = _fetchEventDetails();
      } else {
        _showFeedbackSnackbar(responseData['message'] ?? 'Erro ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showFeedbackSnackbar('Erro de conexão ao cancelar.', isError: true);
    } finally {
      if (mounted) {
        setState(() { _isCanceling = false; });
      }
    }
  }
  // --- FIM DA MUDANÇA 3 ---

  // --- 4. SUBSTITUA A FUNÇÃO _buildEventContent ---
  Widget _buildEventContent(Map<String, dynamic> event) {
    final String? imageUrl = event['imagem_url'];
    // --- CORREÇÃO DA URL DA IMAGEM ---
    final String? fullImageUrl = imageUrl != null ? '$_serverUrl$imageUrl' : null;
    // ---------------------------------
    final bool hasInscricao = (event['inscricao'] == '1' || event['inscricao'] == 1);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (fullImageUrl != null)
              ? Image.network(
                  fullImageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['titulo'] ?? 'Evento sem título',
                  style: const TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  _formatApiDate(event['data_evento'] ?? ''),
                ),
                const SizedBox(height: 12),

                if(hasInscricao)
                _buildInfoRow(
                  Icons.people_outline,
                  _formatVagas(event['max_participantes'], event['inscritos_count']),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: AppColors.secondaryText, height: 0.5),
                ),

                Text(
                  'Sobre o Evento',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  event['descricao'] ?? 'Descrição indisponível.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.secondaryText,
                    height: 1.6,
                  ),
                ),

                // --- ADIÇÃO DO BOTÃO "CANCELAR" ---
                if (_estaInscrito) // Só mostra se o usuário ESTÁ inscrito
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isCanceling ? null : _cancelarInscricao,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent, // Vermelho
                          side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isCanceling
                            ? CircularProgressIndicator(color: AppColors.accent)
                            : const Text(
                                'Cancelar Inscrição',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                // ---------------------------------
                
                const SizedBox(height: 100), 
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- FIM DA MUDANÇA 4 ---

  // ... (funções _buildImagePlaceholder, _buildInfoRow, _formatVagas, _formatApiDate - sem mudanças) ...
  Widget _buildImagePlaceholder() {
    return Image.asset(
      'assets/images/ec-eventos.png', // <-- Sua imagem padrão
      height: 250,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondaryText, size: 18),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatVagas(dynamic max, dynamic current) {
    final int maxVagas = int.tryParse(max.toString() ?? '0') ?? 0;
    final int inscritos = int.tryParse(current.toString() ?? '0') ?? 0;

    if (maxVagas > 0) {
      return '$inscritos / $maxVagas vagas preenchidas';
    }
    
    return 'Vagas ilimitadas ($inscritos inscritos)';
  }

  String _formatApiDate(String apiDate) {
    try {
      final DateTime parsedDate = DateTime.parse(apiDate);
      return DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(parsedDate);
    } catch (e) {
      return apiDate;
    }
  }

  // --- 5. SUBSTITUA A FUNÇÃO _buildStickyButton ---
  Widget _buildStickyButton(Map<String, dynamic> event) {
    final bool hasInscricao = (event['inscricao'] == '1' || event['inscricao'] == 1);

    if (!hasInscricao) {
      return const SizedBox.shrink(); 
    }

    final int maxVagas = int.tryParse(event['max_participantes'].toString() ?? '0') ?? 0;
    final int inscritos = int.tryParse(event['inscritos_count'].toString() ?? '0') ?? 0;
    final bool isLotado = (maxVagas > 0) && (inscritos >= maxVagas);
    
    String buttonText;
    bool isDisabled;

    if (isLotado && !_estaInscrito) {
      buttonText = 'Inscrições Esgotadas';
      isDisabled = true;
    } else if (_estaInscrito) { 
      buttonText = 'Inscrito'; 
      isDisabled = true; 
    } else {
      buttonText = 'Inscrever-se';
      isDisabled = false;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.secondaryText.withOpacity(0.2), width: 0.5)),
      ),
      child: ElevatedButton(
        onPressed: (_isRegistering || isDisabled) ? null : _realizarInscricao,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDisabled ? Colors.grey[700] : AppColors.accent.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isRegistering
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                buttonText, 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
  // --- FIM DA MUDANÇA 5 ---

  // ... (função _showFeedbackSnackbar e build() - sem mudanças) ...
  void _showFeedbackSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Evento'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _futureEventDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar evento: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            return _buildEventContent(snapshot.data!);
          }
          return const Center(child: Text('Evento não encontrado.'));
        },
      ),
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
        future: _futureEventDetails,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildStickyButton(snapshot.data!);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}