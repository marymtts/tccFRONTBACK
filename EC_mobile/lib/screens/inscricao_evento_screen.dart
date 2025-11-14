// lib/screens/inscricao_evento_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:ec_mobile/providers/user_provider.dart';
import 'package:ec_mobile/screens/login_screen.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 

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
  bool _estaInscrito = false;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _futureEventDetails = _fetchEventDetails();
  }

  Future<Map<String, dynamic>> _fetchEventDetails() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    
    String urlString = '$_serverUrl/api/eventos.php?id=${widget.eventId}';
    
    if (user != null) {
      urlString += '&user_id=${user.id}';
    }
    
    final url = Uri.parse(urlString);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
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
        setState(() {
          _estaInscrito = true;
        });
        _futureEventDetails = _fetchEventDetails(); // Recarrega para atualizar a contagem
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
        setState(() {
          _estaInscrito = false;
        });
        _futureEventDetails = _fetchEventDetails(); // Recarrega para atualizar a contagem
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

  // --- FUNÇÃO DE LAYOUT PRINCIPAL (ATUALIZADA) ---
  Widget _buildEventContent(Map<String, dynamic> event) {
    final String? imageUrl = event['imagem_url'];
    final String? fullImageUrl = imageUrl != null ? '$_serverUrl$imageUrl' : null;
    final bool hasInscricao = (event['inscricao'] == '1' || event['inscricao'] == 1);
    
    // Converte os dados para a barra de progresso
    final int maxVagas = int.tryParse(event['max_participantes'].toString() ?? '0') ?? 0;
    final int inscritos = int.tryParse(event['inscritos_count'].toString() ?? '0') ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- IMAGEM HEADER (MAIS ALTA) ---
          (fullImageUrl != null)
              ? Image.network(
                  fullImageUrl,
                  height: 300, // <-- AUMENTAMOS A ALTURA
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),

          // --- SEÇÃO DE CONTEÚDO (REDESENHADA) ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  event['titulo'] ?? 'Evento sem título',
                  style: const TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 30), // Mais espaço

                // --- TÍTULO DA SEÇÃO (da inspiração) ---
                Text(
                  'Informações do Evento',
                  style: const TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 24),
                
                // --- Bloco de Data (Novo) ---
                _buildInfoBlock(
                  icon: Icons.calendar_today_outlined,
                  label: 'Data',
                  value: _formatApiDate(event['data_evento'] ?? ''),
                ),
                const SizedBox(height: 24),

                // --- NOVO BLOCO DE HORÁRIO ---
                _buildInfoBlock(
                  icon: Icons.access_time_outlined,
                  label: 'Horário',
                  value: _formatApiTime(event['hora_evento']), // <-- MUDE AQUI
                ),
                const SizedBox(height: 24),

                

                // --- Bloco de Vagas (Novo) ---
                if(hasInscricao) ...[
                  _buildInfoBlock(
                    icon: Icons.people_outline,
                    label: 'Vagas',
                    value: _formatVagas(event['max_participantes'], event['inscritos_count']),
                  ),
                  const SizedBox(height: 12),
                  // --- Barra de Progresso (Nova) ---
                  _buildProgressBar(inscritos, maxVagas),
                ],
                
                // Divisor sutil
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0), // Mais espaço
                  child: Divider(color: AppColors.secondaryText, height: 0.5),
                ),

                // Descrição
                Text(
                  'Sobre o Evento',
                  style: const TextStyle(
                    fontSize: 20, // Título maior
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

                // Botão "Cancelar Inscrição"
                if (_estaInscrito) 
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0), 
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
                
                const SizedBox(height: 100), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET AUXILIAR (NOVO) - Inspirado no seu print ---
  Widget _buildInfoBlock({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Alinha pelo topo
      children: [
        Icon(icon, color: AppColors.secondaryText, size: 24), // Ícone um pouco maior
        const SizedBox(width: 16),
        
        Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 16, // Label menor
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 16, // Valor maior
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ),
      ],
    );
  }

  // --- WIDGET AUXILIAR (NOVO) - A Barra de Progresso ---
  Widget _buildProgressBar(int inscritos, int maxVagas) {
    // Só mostra a barra se houver vagas limitadas
    if (maxVagas == 0) return const SizedBox.shrink(); 
    
    // Calcula a porcentagem
    double percentage = 0.0;
    if (maxVagas > 0) {
      percentage = (inscritos / maxVagas).clamp(0.0, 1.0);
    }
    
    return Container(
      height: 8, // Altura da barra
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: AppColors.surface, // Fundo cinza escuro da barra
      ),
      child: LinearProgressIndicator(
        value: percentage, // O preenchimento
        backgroundColor: AppColors.surface, // Cor de fundo
        color: AppColors.accent, // Cor do progresso (vermelho)
      ),
    );
  }

  // --- FUNÇÃO AUXILIAR (ATUALIZADA) - Texto de Vagas ---
  String _formatVagas(dynamic max, dynamic current) {
    final int maxVagas = int.tryParse(max.toString() ?? '0') ?? 0;
    final int inscritos = int.tryParse(current.toString() ?? '0') ?? 0;

    if (maxVagas > 0) {
      return '$inscritos / $maxVagas inscritos'; // Novo texto
    }
    
    return '$inscritos inscritos (Ilimitado)'; // Novo texto
  }

  // (O resto do seu código _buildImagePlaceholder, _formatApiDate, _buildStickyButton, 
  // _showFeedbackSnackbar, e build() continua o MESMO de antes)
  
  Widget _buildImagePlaceholder() {
    return Image.asset(
      'assets/images/ec-eventos.png', 
      height: 280, // <-- AUMENTAMOS A ALTURA
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  String _formatApiDate(String apiDate) {
    try {
      final DateTime parsedDate = DateTime.parse(apiDate);
      return DateFormat('EEEE, dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(parsedDate); // Formato mais completo
    } catch (e) {
      return apiDate;
    }
    
  }

  String _formatApiTime(String? apiTime) { // <-- Mudei para String? (pode ser nulo)
    if (apiTime == null) return "--:--"; // Retorna se a hora for nula
    try {
      // O banco envia "19:00:00". Precisamos de um DateTime "falso" para formatar.
      final DateTime parsedTime = DateFormat('HH:mm:ss').parse(apiTime);
      return DateFormat('HH:mm', 'pt_BR').format(parsedTime); // Formato "19:00"
    } catch (e) {
      return apiTime; // Retorna a string crua se falhar
    }
  }

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
      // 1. O container da "barra" (fundo escuro, borda)
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.secondaryText.withOpacity(0.2), width: 0.5)),
      ),
      child: Container( 
        // 2. O NOVO container do "botão" (para o gradiente)
        decoration: BoxDecoration(
          // Aplica o gradiente SOMENTE se o botão estiver ATIVO
          gradient: isDisabled 
              ? null // Sem gradiente se desabilitado
              : const LinearGradient(
                  colors: [AppColors.accentOrange, AppColors.accent], // Dourado
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          // Cor sólida CINZA se estiver DESABILITADO
          color: isDisabled ? Colors.grey[700] : null, 
          borderRadius: BorderRadius.circular(8),
          boxShadow: isDisabled ? [] : [ // Sombra só se estiver ATIVO
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          // 3. O ElevatedButton agora é TRANSPARENTE
          onPressed: (_isRegistering || isDisabled) ? null : _realizarInscricao,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, // <-- ESSENCIAL
            shadowColor: Colors.transparent, // <-- ESSENCIAL
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isRegistering
              // 4. O Spinner agora é PRETO (para o fundo dourado)
              ? const CircularProgressIndicator(color: AppColors.background)
              // 5. O Texto agora é PRETO (para o fundo dourado)
              : Text(
                  buttonText, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    // Cor do texto dinâmica
                    color: isDisabled ? AppColors.secondaryText : AppColors.primaryText,
                  ),
                ),
        ),
      ),
    );
  }

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