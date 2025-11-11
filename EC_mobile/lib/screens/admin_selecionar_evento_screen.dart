// lib/screens/admin_selecionar_evento_screen.dart
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:ec_mobile/screens/scanner_screen.dart'; // Importa o scanner
import 'package:intl/intl.dart';

// (Modelo simples de Evento, pode usar o seu se tiver)
class Evento {
  final int id;
  final String titulo;
  final DateTime dataEvento;

  Evento({required this.id, required this.titulo, required this.dataEvento});

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: int.parse(json['id'].toString()),
      titulo: json['titulo'],
      dataEvento: DateTime.parse(json['data_evento']),
    );
  }
}

class AdminSelecionarEventoScreen extends StatefulWidget {
  const AdminSelecionarEventoScreen({super.key});

  @override
  State<AdminSelecionarEventoScreen> createState() => _AdminSelecionarEventoScreenState();
}

class _AdminSelecionarEventoScreenState extends State<AdminSelecionarEventoScreen> {
  late Future<List<Evento>> _futureEventos;

  @override
  void initState() {
    super.initState();
    _futureEventos = _fetchEventos();
  }

  // Função para buscar os eventos da sua API
  Future<List<Evento>> _fetchEventos() async {
    // ATENÇÃO: Lembre-se de trocar 'localhost' por '10.0.2.2' se estiver no emulador Android
    final response = await http.get(
      Uri.parse('https://tccfrontback.onrender.com/api/get_proximos_eventos.php')
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Evento.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar eventos da API');
    }
  }

  // Função para formatar a data
  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy \'às\' HH:mm').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Evento'),
        backgroundColor: AppColors.surface,
      ),
      body: FutureBuilder<List<Evento>>(
        future: _futureEventos,
        builder: (context, snapshot) {
          // Se estiver carregando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // Se der erro
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar eventos: ${snapshot.error}'));
          }
          // Se os dados chegarem
          if (snapshot.hasData) {
            final eventos = snapshot.data!;
            if (eventos.isEmpty) {
              return Center(child: Text('Nenhum evento encontrado.'));
            }

            // Constrói a lista
            return ListView.builder(
              itemCount: eventos.length,
              itemBuilder: (context, index) {
                final evento = eventos[index];
                return ListTile(
                  title: Text(evento.titulo),
                  subtitle: Text(_formatarData(evento.dataEvento)),
                  leading: Icon(Icons.event_note, color: AppColors.accent),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // ----- AQUI ESTÁ A MÁGICA -----
                    // Navega para o Scanner PASSANDO O ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScannerScreen(eventoId: evento.id),
                      ),
                    );
                  },
                );
              },
            );
          }
          // Default
          return Center(child: Text('Nenhum evento para validar.'));
        },
      ),
    );
  }
}