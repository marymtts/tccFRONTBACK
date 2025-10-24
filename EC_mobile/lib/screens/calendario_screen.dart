// lib/screens/calendario_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Para formatar a data
import 'package:ec_mobile/theme/app_colors.dart'; // Mude para mobilegemini2
import 'package:ec_mobile/widgets/app_drawer.dart'; // Mude para mobilegemini2

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  // Variáveis para controlar o estado do calendário
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Vamos criar um mapa de eventos (mock) para o pontinho roxo
  // A chave é o dia (UTC) e o valor é uma lista de strings (eventos)
  final Map<DateTime, List<String>> _events = {
    DateTime.utc(2025, 10, 5): ['Palestra de IA'],
    DateTime.utc(2025, 10, 22): ['Hackathon - Dia 1', 'Palestra - Dia 2'],
    DateTime.utc(2025, 10, 23): ['Hackathon - Dia 2'],
    DateTime.utc(2025, 10, 24): ['Hackathon - Final'],
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // Seleciona o dia de hoje por padrão
  }
  
  // Função para pegar os eventos de um dia específico
  List<String> _getEventsForDay(DateTime day) {
    // table_calendar usa datas UTC, então normalizamos
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _events[dayUtc] ?? []; // Retorna os eventos do dia ou uma lista vazia
  }

  @override
  Widget build(BuildContext context) {
    // Formata o título da caixa de eventos
    final String selectedDayTitle = DateFormat('dd/MM/yyyy', 'pt_BR').format(_selectedDay!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Eventos'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentPage: 'Calendário'),
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            // O WIDGET DO CALENDÁRIO
            _buildCalendar(),
            
            const SizedBox(height: 24),
            
            // A SEÇÃO "EVENTOS DO DIA"
            _buildEventList(selectedDayTitle),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES DA TELA ---

// lib/screens/calendario_screen.dart

  // O Calendário
  // lib/screens/calendario_screen.dart

  // O Calendário
  // lib/screens/calendario_screen.dart

  // O Calendário (VERSÃO 3 - A PROVA DE BUGS)
  // lib/screens/calendario_screen.dart

  // O Calendário (VERSÃO 5 - CORRIGINDO OS BUILDERS)
  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        // Configurações Básicas
        locale: 'pt_BR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,

        headerStyle: HeaderStyle(
          formatButtonVisible: false, // <-- ESTA LINHA ESCONDE O BOTÃO
          titleCentered: true,
          titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
        
        eventLoader: _getEventsForDay,
        
        // Gerenciamento de Seleção
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay; 
          });
        },
        
        // ▼▼▼ AQUI ESTÃO AS CORREÇÕES ▼▼▼
        calendarBuilders: CalendarBuilders(
          
          // CORREÇÃO 1: Remove os "pontinhos fantasmas"
          markerBuilder: (context, day, events) {
            // Retorna um widget vazio para não desenhar nada
            return Container();
          },
          
          // Builder para os dias normais
          defaultBuilder: (context, day, focusedDay) {
            final hasEvent = _getEventsForDay(day).isNotEmpty;
            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(color: hasEvent ? AppColors.accent : Colors.white),
              ),
            );
          },
          
          // Builder para os dias fora do mês
          outsideBuilder: (context, day, focusedDay) {
            final hasEvent = _getEventsForDay(day).isNotEmpty;
            return Center(
              child: Text(
                '${day.day}',
                style: TextStyle(color: hasEvent ? AppColors.accent.withOpacity(0.5) : Colors.white.withOpacity(0.3)),
              ),
            );
          },
          
          // CORREÇÃO 2a: Adiciona o fundo cinza AO BUILDER
          todayBuilder: (context, day, focusedDay) {
            final hasEvent = _getEventsForDay(day).isNotEmpty;
            return Container(
              // Adicionamos a decoração (fundo cinza) AQUI
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
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
          
          // CORREÇÃO 2b: Adiciona a borda AO BUILDER
          selectedBuilder: (context, day, focusedDay) {
            final hasEvent = _getEventsForDay(day).isNotEmpty;
            return Container(
              // Adicionamos a decoração (borda vermelha) AQUI
              decoration: BoxDecoration(
                color: Colors.transparent, // Fundo transparente
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent, width: 2), // A borda
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

        // ESTILIZAÇÃO (Agora está mais limpo)
        calendarStyle: CalendarStyle(
          // As decorações de 'today' e 'selected' foram REMOVIDAS daqui
          // pois agora são controladas 100% pelos builders acima.

          // Estilo padrão para texto (afeta fins de semana, etc.)
          weekendTextStyle: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  // FUNÇÃO AUXILIAR PARA O BUILDER (Adicione esta função junto)

  // A Lista de Eventos
  Widget _buildEventList(String title) {
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
          
          // Se não houver eventos, mostra a mensagem
          if (selectedEvents.isEmpty)
            const Text(
              'Nenhum evento para este dia.',
              style: TextStyle(color: AppColors.secondaryText),
            )
          else
            // Se houver eventos, lista eles
            ...selectedEvents.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text("• $event", style: const TextStyle(fontSize: 16)),
            )),
        ],
      ),
    );
  }
}