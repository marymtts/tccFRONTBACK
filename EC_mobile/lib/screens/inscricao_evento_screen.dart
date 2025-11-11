// lib/screens/inscricao_evento_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:ec_mobile/providers/user_provider.dart';
import 'package:ec_mobile/screens/login_screen.dart'; // Para o caso do usuário não estar logado

class InscricaoEventoScreen extends StatefulWidget {
  final int eventId;
  const InscricaoEventoScreen({super.key, required this.eventId});

  @override
  State<InscricaoEventoScreen> createState() => _InscricaoEventoScreenState();
}

class _InscricaoEventoScreenState extends State<InscricaoEventoScreen> {
  // --- MUDANÇA: URL do Servidor (use seu IP) ---
  final String _serverUrl = 'https://tccfrontback.onrender.com'; 

  late Future<Map<String, dynamic>> _futureEventDetails;
  bool _isRegistering = false; // Controla o loading do botão

  @override
  void initState() {
    super.initState();
    _futureEventDetails = _fetchEventDetails();
  }

  // 1. FUNÇÃO PARA BUSCAR OS DETALHES DO EVENTO
  Future<Map<String, dynamic>> _fetchEventDetails() async {
    final url = Uri.parse('$_serverUrl/api/eventos.php?id=${widget.eventId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Falha ao carregar dados do evento');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  // 2. FUNÇÃO PARA REALIZAR A INSCRIÇÃO
  Future<void> _realizarInscricao() async {
    setState(() { _isRegistering = true; });

    // Pega o usuário logado
    final user = Provider.of<UserProvider>(context, listen: false).user;

    // --- Verificação 1: Está logado? ---
    if (user == null) {
      _showFeedbackSnackbar('Você precisa estar logado para se inscrever.', isError: true);
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      setState(() { _isRegistering = false; });
      return;
    }
    
    // --- Verificação 2: É um aluno? ---
    if (user.role != 'aluno') {
      _showFeedbackSnackbar('Apenas alunos podem se inscrever em eventos.', isError: true);
      setState(() { _isRegistering = false; });
      return;
    }

    // Tenta realizar a inscrição
    try {
      final url = Uri.parse('$_serverUrl/api/registrar_participacao.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_aluno': user.id.toString(), // Envia o ID do aluno
          'id_evento': widget.eventId.toString(), // Envia o ID do evento
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) { // 201 Created
        _showFeedbackSnackbar(responseData['message'] ?? 'Inscrição realizada com sucesso!', isError: false);
        // Opcional: Voltar para a tela anterior
        Navigator.pop(context);
      } else {
        // Mostra o erro da API (ex: "Você já está inscrito")
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

  // 3. FUNÇÕES AUXILIARES DE LAYOUT (A MÁGICA ACONTECE AQUI)

  // -- O NOVO LAYOUT DO CONTEÚDO --
  Widget _buildEventContent(Map<String, dynamic> event) {
    final String? imageUrl = event['imagem_url'];
    final String? fullImageUrl = imageUrl != null ? '$_serverUrl/EC_back$imageUrl' : null;
    final bool hasInscricao = (event['inscricao'] == '1' || event['inscricao'] == 1);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- IMAGEM HEADER ---
          (fullImageUrl != null)
            ? Image.network(
                fullImageUrl,
                height: 250, // Imagem maior
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
              )
            : _buildImagePlaceholder(), // Placeholder (com tcc-stock.png)

          // --- SEÇÃO DE CONTEÚDO (com padding) ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  event['titulo'] ?? 'Evento sem título',
                  style: const TextStyle(
                    fontSize: 26, // Título grande e impactante
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Data (agora estilizada)
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  _formatApiDate(event['data_evento'] ?? ''),
                ),
                const SizedBox(height: 12),

                // Vagas (se tiver)
                if(hasInscricao)
                _buildInfoRow(
                  Icons.people_outline,
                  // --- MUDE ESTA LINHA ---
                  // _formatVagas(event['max_participantes']), // (Versão antiga)
                  _formatVagas(event['max_participantes'], event['inscritos_count']), // (Nova versão)
                ),
                  
                // Divisor sutil
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Divider(color: AppColors.secondaryText, height: 0.5),
                ),

                // Descrição (agora bem formatada)
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
                    height: 1.6, // ESSENCIAL para legibilidade
                  ),
                ),
                
                // Espaço extra no final para o botão flutuante não cobrir
                const SizedBox(height: 100), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Placeholder (usando sua tcc-stock.png) --
  Widget _buildImagePlaceholder() {
    return Image.asset(
      'assets/images/ec-eventos.png', // <-- Sua imagem padrão
      height: 250,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  // -- Helper para a linha de Data e Vagas --
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

  // -- Helper para formatar o texto de Vagas --
  String _formatVagas(dynamic max, dynamic current) {
    // Converte os valores para números
    final int maxVagas = int.tryParse(max.toString() ?? '0') ?? 0;
    final int inscritos = int.tryParse(current.toString() ?? '0') ?? 0;

    if (maxVagas > 0) {
      // Ex: "15 / 100 vagas preenchidas"
      return '$inscritos / $maxVagas vagas preenchidas';
    }
    
    // Se for ilimitado, ainda é bom mostrar quantos já se inscreveram
    // Ex: "Vagas ilimitadas (15 inscritos)"
    return 'Vagas ilimitadas ($inscritos inscritos)';
  }

  // -- Helper para formatar a data --
  String _formatApiDate(String apiDate) {
    try {
      final DateTime parsedDate = DateTime.parse(apiDate);
      return DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(parsedDate);
    } catch (e) {
      return apiDate;
    }
  }

  // ... dentro da _InscricaoEventoScreenState

  // --- O NOVO BOTÃO FLUTUANTE (com lógica de "Esgotado") ---
  Widget _buildStickyButton(Map<String, dynamic> event) {
    final bool hasInscricao = (event['inscricao'] == '1' || event['inscricao'] == 1);

    // Se o evento for "Aberto ao Público", não mostra o botão.
    if (!hasInscricao) {
      return const SizedBox.shrink(); // Retorna um widget vazio
    }

    // --- NOVA LÓGICA DE VAGAS ---
    final int maxVagas = int.tryParse(event['max_participantes'].toString() ?? '0') ?? 0;
    final int inscritos = int.tryParse(event['inscritos_count'].toString() ?? '0') ?? 0;
    // O evento está lotado SE maxVagas > 0 E inscritos >= maxVagas
    final bool isLotado = (maxVagas > 0) && (inscritos >= maxVagas);
    // ----------------------------
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.secondaryText.withOpacity(0.2), width: 0.5)),
      ),
      child: ElevatedButton(
        // Desabilita o botão se estiver registrando OU se estiver lotado
        onPressed: (_isRegistering || isLotado) ? null : _realizarInscricao,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          // Cor do botão desabilitado (se estiver lotado)
          disabledBackgroundColor: isLotado ? Colors.grey[700] : AppColors.accent.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isRegistering
            ? const CircularProgressIndicator(color: Colors.white)
            // Muda o texto do botão se estiver lotado
            : Text(
                isLotado ? 'Inscrições Esgotadas' : 'Inscrever-se',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // Função de Feedback
  void _showFeedbackSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // 4. O SCAFFOLD PRINCIPAL
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
            // Se carregou, constrói o conteúdo
            return _buildEventContent(snapshot.data!);
          }
          return const Center(child: Text('Evento não encontrado.'));
        },
      ),
      // --- O BOTÃO FLUTUANTE VAI AQUI ---
      bottomNavigationBar: FutureBuilder<Map<String, dynamic>>(
        future: _futureEventDetails,
        builder: (context, snapshot) {
          // Só mostra o botão se os dados do evento carregaram
          if (snapshot.hasData) {
            return _buildStickyButton(snapshot.data!);
          }
          return const SizedBox.shrink(); // Vazio enquanto carrega
        },
      ),
    );
  }
}