// lib/screens/calendario_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Para formatar a data
import 'package:ec_mobile/theme/app_colors.dart'; 
import 'package:ec_mobile/widgets/app_drawer.dart';
// ignore: unused_import
import 'dart:convert';
// ignore: unused_import
import 'package:http/http.dart' as http;

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mapa de eventos que será preenchido pela API
  Map<DateTime, List<String>> _events = {}; 
  bool _isLoading = true; // Para mostrar "Carregando..."
  String _errorMessage = ''; // Para mostrar erros

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents(); // Chama a API assim que a tela abre
  }

  // Função que chama sua API PHP
  Future<void> _fetchEvents() async {
    // URL para testar no CHROME (WEB)
    final url = Uri.parse('http://localhost/EC_back/api/eventos.php'); 
    
    // Lembrete: Para EMULADOR ANDROID, use:
    // final url = Uri.parse('http://10.0.2.2/EC_back/api/eventos.php');
    // Para CELULAR FÍSICO, use o IP do seu PC na rede Wi-Fi.

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Decodifica o JSON que veio do PHP
        final List<dynamic> data = jsonDecode(response.body);
        Map<DateTime, List<String>> tempEvents = {};

        // Processa cada evento do JSON
        for (var item in data) {
          // Usa os nomes EXATOS das suas colunas
          String titulo = item['titulo']; 
          DateTime dataEvento = DateTime.parse(item['data_evento']); 
          
          DateTime dataUtc = DateTime.utc(dataEvento.year, dataEvento.month, dataEvento.day);

          // Agrupa os eventos por dia no mapa
          if (tempEvents[dataUtc] == null) {
            tempEvents[dataUtc] = [];
          }
          tempEvents[dataUtc]!.add(titulo);
        }

        // Atualiza a tela com os eventos da API
        setState(() {
          _events = tempEvents;
          _isLoading = false;
        });

      } else {
        // Se a API retornar um erro (404, 500, etc.)
        setState(() {
          _errorMessage = 'Falha ao carregar eventos (Erro HTTP ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Se houver erro de conexão (sem internet, URL errada, XAMPP desligado)
      print('Erro ao buscar eventos: $e'); // Mostra o erro detalhado no console de debug
      setState(() {
        _errorMessage = 'Erro de conexão. Verifique o XAMPP, a URL e sua internet.';
        _isLoading = false;
      });
    }
  }

  // Função auxiliar do calendário (lê o mapa _events)
  List<String> _getEventsForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _events[dayUtc] ?? [];
  }

  // Constrói a interface da tela
  @override
  Widget build(BuildContext context) {
    final String selectedDayTitle = _selectedDay != null
        ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDay!)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Eventos'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentPage: 'Calendário'),
      
      // Lida com os estados de Carregando, Erro ou Sucesso
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostra "Carregando..."
          : _errorMessage.isNotEmpty
              ? Center( // Mostra a mensagem de erro
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ) 
              : SingleChildScrollView( // Mostra o conteúdo principal
                  child: Column(
                    children: [
                      _buildCalendar(), // O calendário em si
                      const SizedBox(height: 24),
                      // A caixa de eventos (só mostra se um dia foi selecionado)
                      if (_selectedDay != null) 
                        _buildEventList(selectedDayTitle), 
                    ],
                  ),
                ),
    );
  }

  // A função que constrói o widget TableCalendar (corrigida)
  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        locale: 'pt_BR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        eventLoader: _getEventsForDay, // Usa os dados da API pra puxar evento (via _events)
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay; 
          });
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
        // Builders para customizar a aparência dos dias
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            return Container(); // Sem pontinhos
          },
          defaultBuilder: (context, day, focusedDay) {
            final hasEvent = _getEventsForDay(day).isNotEmpty;
            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(color: hasEvent ? AppColors.accent : Colors.white),
              ),
            );
          },
          outsideBuilder: (context, day, focusedDay) {
            final hasEvent = _getEventsForDay(day).isNotEmpty;
            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(color: hasEvent ? AppColors.accent.withOpacity(0.5) : Colors.white.withOpacity(0.3)),
              ),
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final hasEvent = _getEventsForDay(day).isNotEmpty;
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight, // Fundo cinza claro
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: hasEvent ? AppColors.accent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
          selectedBuilder: (context, day, focusedDay) {
            final hasEvent = _getEventsForDay(day).isNotEmpty;
            return Container(
              decoration: BoxDecoration(
                color: Colors.transparent, // Fundo transparente
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent, width: 2), // Borda vermelha
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: hasEvent ? AppColors.accent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        ),
        // Estilos gerais do calendário
        calendarStyle: CalendarStyle(
          weekendTextStyle: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  // A função que constrói a caixa "Eventos de DD/MM/AAAA"
  Widget _buildEventList(String title) {
    // Busca os eventos para o dia selecionado (já vieram da API)
    final selectedEvents = _getEventsForDay(_selectedDay!); 
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eventos de $title',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Mostra a lista de eventos ou a mensagem "Nenhum evento"
          if (selectedEvents.isEmpty)
            const Text(
              'Nenhum evento para este dia.',
              style: TextStyle(color: AppColors.secondaryText),
            )
          else
            // Cria um Text() para cada evento na lista
            ...selectedEvents.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text("• $event", style: const TextStyle(fontSize: 16)),
            )).toList(),
        ],
      ),
    );
  }
}
// --- FIM DA CLASSE QUE VAMOS SUBSTITUIR --- 