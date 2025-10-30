
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ec_mobile/screens/inscricao_evento_screen.dart';

import 'package:ec_mobile/theme/app_colors.dart';
// Importe o AppDrawer se for usá-lo
// import 'package:ec_mobile/widgets/app_drawer.dart'; 

class ProximosEventosScreen extends StatefulWidget {
  const ProximosEventosScreen({super.key});

  @override
  State<ProximosEventosScreen> createState() => _ProximosEventosScreenState();
}

class _ProximosEventosScreenState extends State<ProximosEventosScreen> {
  List<dynamic> _upcomingEvents = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUpcomingEvents();
  }

  Future<void> _fetchUpcomingEvents() async {
    // !!! URL DO NOVO ENDPOINT PHP !!!
    final url = Uri.parse('http://localhost/EC_back/api/get_proximos_eventos.php');
    // (Lembre-se das URLs de Emulador/Celular Físico)

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

  // Função auxiliar para formatar a data (similar à da HomeScreen)
  String _formatApiDate(String apiDate) {
    try {
      final DateTime parsedDate = DateTime.parse(apiDate);
      return DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(parsedDate); // Formato mais completo
    } catch (e) {
      return apiDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximos Eventos'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      // drawer: const AppDrawer(currentPage: 'Agenda'), // Opcional
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center( /* ... mostrar erro ... */ )
              : _upcomingEvents.isEmpty // Verifica se a lista está vazia
                  ? const Center(
                      child: Text(
                        'Nenhum evento futuro encontrado.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
                      ),
                    )
                  : // ... dentro do Widget build() de _ProximosEventosScreenState
         // ... dentro do Widget build() de _ProximosEventosScreenState
   ListView.builder(
    padding: const EdgeInsets.all(16.0),
    itemCount: _upcomingEvents.length,
   // Dentro do seu ListView.builder
itemBuilder: (context, index) {
  final event = _upcomingEvents[index];
  final bool hasInscricao = (event['inscricao'] ?? 0) == 1;
  final int? eventId = event['id']; // Pegamos o ID para o botão

  // NÃO HÁ MAIS INKWELL AQUI. O return começa direto com o Card.
  return Card(
    color: AppColors.surface,
    margin: const EdgeInsets.only(bottom: 12.0),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        // --- SOLUÇÃO 1: DEIXAR O CARD MAIS ALTO ---
        // Adicionamos padding vertical ao título do card "fechado"
        tilePadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        
        // O título (cabeçalho do card)
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['titulo'] ?? 'Evento sem título',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText),
            ),
            const SizedBox(height: 5),
            Text(
              _formatApiDate(event['data_evento'] ?? ''),
              style: const TextStyle(
                  fontSize: 14, color: AppColors.secondaryText),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.accent,
        ),
        
        // O conteúdo que aparece ao expandir
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['descricao'] ?? 'Descrição indisponível.',
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                      height: 1.5),
                ),
                if (hasInscricao) // Só mostra o botão se tiver inscrição
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // --- SOLUÇÃO 2: BOTÃO NAVEGA ---
                        onPressed: eventId == null ? null : () {
                          // A LÓGICA DE NAVEGAÇÃO VEM PARA CÁ
                          print('Botão "Inscrever-se" clicado para ID: $eventId');
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
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Inscrever-se',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
},
  ),
// ... o resto do código ...,
// ... o resto do código ...,
    );
  }
}