// lib/screens/admin_controle_selecionar_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ec_mobile/theme/app_colors.dart';
// IMPORTA A NOVA TELA QUE VAMOS CRIAR NO PASSO 3
import 'package:ec_mobile/screens/admin_ver_inscritos_screen.dart'; 
import 'package:intl/intl.dart';

// (Modelo simples de Evento)
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

class AdminControleSelecionarScreen extends StatefulWidget {
  const AdminControleSelecionarScreen({super.key});

  @override
  State<AdminControleSelecionarScreen> createState() => _AdminControleSelecionarScreenState();
}

class _AdminControleSelecionarScreenState extends State<AdminControleSelecionarScreen> {
  late Future<List<Evento>> _futureEventos;

  @override
  void initState() {
    super.initState();
    _futureEventos = _fetchEventos();
  }

  // Busca os eventos (já usando o IP da sua rede e a API correta)
  Future<List<Evento>> _fetchEventos() async {
    final response = await http.get(
      // ATENÇÃO: Use o IP da sua rede (192.168...) ou '10.0.2.2' (emulador)
      Uri.parse('http://192.168.15.174/EC_back/api/get_proximos_eventos.php')
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Evento.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar eventos da API');
    }
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy \'às\' HH:mm').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Evento (Controle)'),
        backgroundColor: AppColors.surface,
      ),
      body: FutureBuilder<List<Evento>>(
        future: _futureEventos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar eventos: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final eventos = snapshot.data!;
            if (eventos.isEmpty) {
              return Center(child: Text('Nenhum evento encontrado.'));
            }

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
                    // ----- A MUDANÇA ESTÁ AQUI -----
                    // Navega para a tela de "Ver Inscritos"
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminVerInscritosScreen(
                          eventoId: evento.id,
                          eventoTitulo: evento.titulo, // Passa o título tbm
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
          return Center(child: Text('Nenhum evento para gerenciar.'));
        },
      ),
    );
  }
}