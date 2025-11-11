// lib/screens/admin_ver_inscritos_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para o token

// Modelo para o usuário inscrito
class Inscrito {
  final int id;
  final String nome;
  final String? ra;
  final String email;
  final bool checkIn; // Vamos ver quem já fez check-in!

  Inscrito({
    required this.id,
    required this.nome,
    this.ra,
    required this.email,
    required this.checkIn,
  });

  factory Inscrito.fromJson(Map<String, dynamic> json) {
    return Inscrito(
      id: int.parse(json['id'].toString()),
      nome: json['nome'],
      ra: json['ra']?.toString(),
      email: json['email'],
      checkIn: json['check_in'] == '1', // Converte '1' para true
    );
  }
}

class AdminVerInscritosScreen extends StatefulWidget {
  final int eventoId;
  final String eventoTitulo;

  const AdminVerInscritosScreen({
    super.key, 
    required this.eventoId,
    required this.eventoTitulo
  });

  @override
  State<AdminVerInscritosScreen> createState() => _AdminVerInscritosScreenState();
}

class _AdminVerInscritosScreenState extends State<AdminVerInscritosScreen> {
  late Future<List<Inscrito>> _futureInscritos;

  @override
  void initState() {
    super.initState();
    _futureInscritos = _fetchInscritos();
  }

  Future<List<Inscrito>> _fetchInscritos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Token de admin não encontrado');
    }

    // Chama a NOVA API que vamos criar
    final response = await http.get(
      // ATENÇÃO: Use o IP da sua rede (192.168...) ou '10.0.2.2' (emulador)
      Uri.parse('https://tccfrontback.onrender.com/api/get_inscritos_evento.php?id_evento=${widget.eventoId}'),
      headers: {
        'Authorization': 'Bearer $token', // Envia o token de admin
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Inscrito.fromJson(json)).toList();
    } else {
      // Tenta decodificar a mensagem de erro da API
      final responseBody = json.decode(response.body);
      throw Exception('Falha ao carregar inscritos: ${responseBody['message']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inscritos em "${widget.eventoTitulo}"'),
        backgroundColor: AppColors.surface,
      ),
      body: FutureBuilder<List<Inscrito>>(
        future: _futureInscritos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final inscritos = snapshot.data!;
            if (inscritos.isEmpty) {
              return Center(child: Text('Nenhum aluno inscrito neste evento.'));
            }

            return ListView.builder(
              itemCount: inscritos.length,
              itemBuilder: (context, index) {
                final inscrito = inscritos[index];
                return ListTile(
                  title: Text(inscrito.nome),
                  subtitle: Text(inscrito.ra ?? inscrito.email),
                  // Ícone de check-in (BÔNUS!)
                  trailing: inscrito.checkIn
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.circle_outlined, color: Colors.grey),
                );
              },
            );
          }
          return Center(child: Text('Carregando...'));
        },
      ),
    );
  }
}