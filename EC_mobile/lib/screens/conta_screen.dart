// lib/screens/conta_screen.dart
import 'dart:convert';
import 'package:ec_mobile/models/user.dart';
import 'package:ec_mobile/providers/user_provider.dart';
import 'package:ec_mobile/screens/editar_conta_screen.dart';
import 'package:ec_mobile/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Para o QR Code
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ec_mobile/screens/login_screen.dart'; // Para navegar no logout

class ContaScreen extends StatefulWidget {
  const ContaScreen({super.key});

  @override
  State<ContaScreen> createState() => _ContaScreenState();
}

class _ContaScreenState extends State<ContaScreen> {
  // (Removemos os controllers, pois não vamos mais editar os campos aqui)
  
  // Função de Logout (vinda do seu AppDrawer/código anterior)
  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');

    if (!mounted) return;
    Provider.of<UserProvider>(context, listen: false).clearUser();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // (Removemos a lógica de "Deletar Conta" como você pediu)

  @override
  Widget build(BuildContext context) {
    // Pega o usuário logado do provider
    final user = Provider.of<UserProvider>(context).user;

    // Se o usuário não carregou (raro, mas seguro)
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Minha Conta')),
        body: Center(child: Text('Erro: Usuário não encontrado.')),
      );
    }

    // --- ESTA É A NOVA TELA ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Conta'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Faz botões esticarem
          children: [
            
            // --- 1. O NOVO "CARTÃO DE PERFIL" ---
            _buildProfileHeader(user),
            
            const SizedBox(height: 30),

            // --- 2. O CARTÃO DE QR CODE (SÓ PARA ALUNOS) ---
            // (Um Admin não precisa de QR Code de entrada)
            if (user.role == 'aluno') ...[
              _buildQrCodeCard(user),
              const SizedBox(height: 30),
            ],

            // --- 3. BOTÃO DE SAIR ---
            // (Removemos o "Salvar Alterações" pois não há mais campos)
            OutlinedButton(
              onPressed: _logout, // Chama a função de logout
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondaryText,
                side: BorderSide(color: AppColors.secondaryText.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sair (Logout)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface, // Seu fundo de card
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Stack( 
        children: [
          // --- O CONTEÚDO ---
          // Adicionei um Alignment.center para centralizar a coluna principal
          // e o padding é para dar um respiro em volta do conteúdo.
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Align( // <--- NOVA LINHA AQUI
              alignment: Alignment.center, // <--- NOVA LINHA AQUI
              child: Column(
                children: [
                  // O Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      user.nome.isNotEmpty ? user.nome[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Nome
                  Text(
                    user.nome,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 16,
                    ),
                  ),
                  // RA (só para alunos)
                  if (user.role == 'aluno' && user.ra != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'RA: ${user.ra}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ), // <--- NOVA LINHA AQUI
          ),

          // --- O "BOTÃOZINHO" DE EDITAR ---
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.edit_outlined, color: AppColors.secondaryText, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditarContaScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET AUXILIAR: Cartão do QR Code (NOVO) ---
  Widget _buildQrCodeCard(User user) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 24.0),
        child: Column(
          children: [
            const Text(
              'Meu QR Code de Entrada',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText),
            ),
            const SizedBox(height: 24),
            // O QR Code
            Container(
              padding: const EdgeInsets.all(12), // Borda branca
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: user.id.toString(), // O QR Code contém o ID do usuário
                version: QrVersions.auto,
                size: 200.0,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Apresente este código na entrada do evento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}