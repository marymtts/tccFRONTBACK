// lib/screens/admin_ver_inscritos_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

// O modelo "Inscrito" continua o mesmo (ele já lê o check_in)
class Inscrito {
  final int id;
  final String nome;
  final String? ra;
  final String email;
  final bool checkIn; 

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
      nome: json['nome'] as String,
      ra: json['ra']?.toString(), 
      email: json['email'] as String,
      checkIn: json['check_in'] == '1' || json['check_in'] == 1, // Converte '1' ou 1 para true
    );
  }
}

// --- MUDANÇA 1: A TELA AGORA USA ABAS (DefaultTabController) ---
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
  
  // Vamos usar duas listas separadas em vez de uma só
  late Future<Map<String, List<Inscrito>>> _futureInscritos;

  @override
  void initState() {
    super.initState();
    _futureInscritos = _fetchInscritos();
  }

  // --- MUDANÇA 2: A FUNÇÃO DE BUSCA AGORA SEPARA AS LISTAS ---
  Future<Map<String, List<Inscrito>>> _fetchInscritos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Token de admin não encontrado');
    }

    final response = await http.get(
      // (Verifique se está usando seu _serverUrl ou o IP correto)
      Uri.parse('https://tccfrontback.onrender.com/api/get_inscritos_evento.php?id_evento=${widget.eventoId}'),
      headers: {
        'Authorization': 'Bearer $token', 
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      List<Inscrito> allInscritos = jsonList.map((json) => Inscrito.fromJson(json)).toList();
      
      // Separa os alunos em duas listas
      List<Inscrito> presentes = allInscritos.where((aluno) => aluno.checkIn).toList();
      List<Inscrito> ausentes = allInscritos.where((aluno) => !aluno.checkIn).toList();
      
      return {
        'presentes': presentes,
        'ausentes': ausentes
      };

    } else {
      final responseBody = json.decode(response.body);
      throw Exception('Falha ao carregar inscritos: ${responseBody['message']}');
    }
  }

  // --- MUDANÇA 3: O SCAFFOLD AGORA TEM ABAS ---
  @override
  Widget build(BuildContext context) {
    return DefaultTabController( // <-- 1. Envolvemos com um TabController
      length: 2, // Duas abas: Presentes e Ausentes
      child: Scaffold(
        appBar: AppBar(
          title: Text('Controle: "${widget.eventoTitulo}"'),
          backgroundColor: AppColors.surface,
          // 2. Adicionamos a Barra de Abas
          bottom: TabBar(
            tabs: const [
              Tab(text: 'PRESENTES'),
              Tab(text: 'INSCRITOS (Não chegaram)'),
            ],
            indicatorColor: AppColors.accent, // Cor da linha (dourado)
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          ),
        ),
        body: FutureBuilder<Map<String, List<Inscrito>>>(
          future: _futureInscritos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }
            if (snapshot.hasData) {
              final List<Inscrito> presentes = snapshot.data!['presentes']!;
              final List<Inscrito> ausentes = snapshot.data!['ausentes']!;

              // 3. O Body agora é a VISÃO DAS ABAS
              return TabBarView(
                children: [
                  // --- Aba 1: Lista de Presentes ---
                  _buildInscritosList(presentes, 'Presentes', 'Nenhum aluno fez check-in ainda.'),
                  
                  // --- Aba 2: Lista de Ausentes ---
                  _buildInscritosList(ausentes, 'Ausentes', 'Todos os alunos inscritos fizeram check-in!'),
                ],
              );
            }
            return const Center(child: Text('Nenhum aluno inscrito.'));
          },
        ),
      ),
    );
  }

  // --- MUDANÇA 4: WIDGET AUXILIAR PARA CRIAR A LISTA ---
  // (Esta é a sua antiga ListView.builder, mas agora em uma função)
  Widget _buildInscritosList(List<Inscrito> lista, String tipo, String mensagemVazia) {
    if (lista.isEmpty) {
      return Center(child: Text(mensagemVazia, style: TextStyle(color: AppColors.secondaryText)));
    }
    
    // Adiciona um contador no topo da lista
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            '${lista.length} ${tipo}', // Ex: "15 Presentes"
            style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final inscrito = lista[index];
              return ListTile(
                title: Text(inscrito.nome, style: TextStyle(color: AppColors.primaryText)),
                subtitle: Text(inscrito.ra ?? inscrito.email, style: TextStyle(color: AppColors.secondaryText)),
                // O ícone de check-in (Verde para presentes, Cinza para ausentes)
                leading: Icon(
                  inscrito.checkIn ? Icons.check_circle : Icons.circle_outlined, 
                  color: inscrito.checkIn ? Colors.green : Colors.grey[700]
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}